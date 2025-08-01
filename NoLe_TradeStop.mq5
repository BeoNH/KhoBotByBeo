//+------------------------------------------------------------------+
//|                                    SimpleTelegramTradingEA.mq5 |
//|                        Copyright 2025, Telegram Trading EA      |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Telegram Trading EA"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "EA đơn giản kết nối Telegram Bot với định dạng: BUY - XAU - M1"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Input parameters
input group "=== TELEGRAM BOT SETTINGS ==="
input string InpBotToken = "8023905175:AAE3bk7X92_l0StJ1aTDAQTsCh3c6G9x8aI";                    // Bot Token từ BotFather
input string InpChatID = "-1002474487754";                      // Chat ID để nhận tín hiệu
input int InpCheckInterval = 2;                   // Kiểm tra tin nhắn mỗi X giây

input group "=== TRADING SETTINGS ==="
input double InpLotSize = 0.01;                   // Lot size mặc định
input double InpInitialSL = 50.0;                 // Stop Loss ban đầu (points)
input double InpTrailingStep = 10.0;              // Bước di chuyển trailing (points)
input string InpCommentFilter = "TelegramBot";    // Comment để nhận diện lệnh
input bool InpEnableTrailing = true;              // Bật trailing stop

//--- Constants
#define TELEGRAM_BASE_URL "https://api.telegram.org"
#define WEB_TIMEOUT 5000

//--- Global variables
CTrade trade;
CPositionInfo positionInfo;
long lastUpdateID = 0;
bool firstRemove = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // Kiểm tra thông số đầu vào
    if(InpBotToken == "" || InpChatID == "") {
        Alert("Vui lòng nhập Bot Token và Chat ID!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Thiết lập trade object
    trade.SetExpertMagicNumber(0); // Không sử dụng magic number
    trade.SetDeviationInPoints(10);
    
    Print("Simple Telegram Trading EA đã khởi động!");
    Print("Comment Filter: ", InpCommentFilter);
    
    // Tạo timer để kiểm tra tin nhắn định kỳ
    EventSetTimer(InpCheckInterval);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    Print("Simple Telegram Trading EA đã dừng!");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Quản lý trailing stop cho các lệnh có comment phù hợp
    if(InpEnableTrailing) {
        ManageTrailingStop();
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    // Kiểm tra tin nhắn mới từ Telegram
    CheckTelegramMessages();
}

//+------------------------------------------------------------------+
//| Gửi POST request và nhận response                               |
//+------------------------------------------------------------------+
int PostRequest(string &response, const string url, const string params, const int timeout = 5000) {
    char data[];
    int data_size = StringLen(params);
    StringToCharArray(params, data, 0, data_size);
    
    uchar result[];
    string result_headers;
    
    int response_code = WebRequest("POST", url, NULL, NULL, timeout, data, data_size, result, result_headers);
    
    if(response_code == 200) {
        // Loại bỏ BOM nếu có
        int start_index = 0;
        int size = ArraySize(result);
        for(int i = 0; i < MathMin(size, 8); i++) {
            if(result[i] == 0xef || result[i] == 0xbb || result[i] == 0xbf) {
                start_index = i + 1;
            } else {
                break;
            }
        }
        
        response = CharArrayToString(result, start_index, WHOLE_ARRAY, CP_UTF8);
        return 0;
    }
    
    if(response_code == -1) {
        return GetLastError();
    }
    
    response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    return response_code;
}

//+------------------------------------------------------------------+
//| Trim token                                                       |
//+------------------------------------------------------------------+
string GetTrimmedToken(const string bot_token) {
    string token = bot_token;
    StringTrimLeft(token);
    StringTrimRight(token);
    
    if(token == "") {
        Print("ERR: TOKEN EMPTY");
        return "NULL";
    }
    return token;
}

//+------------------------------------------------------------------+
//| Kiểm tra tin nhắn từ Telegram Bot                               |
//+------------------------------------------------------------------+
void CheckTelegramMessages() {
    string token = GetTrimmedToken(InpBotToken);
    if(token == "NULL") return;
    
    string url = TELEGRAM_BASE_URL + "/bot" + token + "/getUpdates";
    string params = "offset=" + IntegerToString(lastUpdateID);
    
    string response;
    int res = PostRequest(response, url, params, WEB_TIMEOUT);
    
    if(res == 0) {
        ProcessTelegramResponse(response);
    } else {
        Print("Lỗi kết nối Telegram API: ", res);
    }
}

//+------------------------------------------------------------------+
//| Xử lý phản hồi từ Telegram (JSON parsing đơn giản)            |
//+------------------------------------------------------------------+
void ProcessTelegramResponse(string response) {
    // Kiểm tra "ok":true
    if(StringFind(response, "\"ok\":true") == -1) return;
    
    // Tìm result array
    int resultPos = StringFind(response, "\"result\":[");
    if(resultPos == -1) return;
    
    // Tìm các update
    int updatePos = StringFind(response, "\"update_id\":", resultPos);
    
    while(updatePos != -1) {
        // Tìm update_id
        int idStart = updatePos + StringLen("\"update_id\":");
        int idEnd = StringFind(response, ",", idStart);
        if(idEnd == -1) break;
        
        long updateId = StringToInteger(StringSubstr(response, idStart, idEnd - idStart));
        
        // Tìm chat_id
        int chatStart = StringFind(response, "\"chat\":{\"id\":", updatePos);
        if(chatStart == -1) break;
        
        chatStart += StringLen("\"chat\":{\"id\":");
        int chatEnd = StringFind(response, ",", chatStart);
        string chatId = StringSubstr(response, chatStart, chatEnd - chatStart);
        
        // Kiểm tra chat ID
        if(chatId == InpChatID) {
            // Tìm message text
            int textStart = StringFind(response, "\"text\":\"", updatePos);
            if(textStart != -1) {
                textStart += StringLen("\"text\":\"");
                int textEnd = StringFind(response, "\"", textStart);
                string messageText = StringSubstr(response, textStart, textEnd - textStart);
                
                // Cập nhật lastUpdateID
                lastUpdateID = updateId + 1;
                
                // Bỏ qua tin nhắn đầu tiên
                if(firstRemove) {
                    firstRemove = false;
                    break;
                }
                
                Print("Nhận tin nhắn mới: ", messageText);
                ProcessSimpleSignal(messageText);
            }
        }
        
        // Tìm update tiếp theo
        updatePos = StringFind(response, "\"update_id\":", updatePos + 1);
    }
}

//+------------------------------------------------------------------+
//| Xử lý tín hiệu đơn giản: BUY - XAU - M1                        |
//+------------------------------------------------------------------+
void ProcessSimpleSignal(string message) {
    // Loại bỏ khoảng trắng thừa và chuyển thành chữ hoa
    StringTrimLeft(message);
    StringTrimRight(message);
    StringToUpper(message);
    
    // Tách tin nhắn theo dấu "-"
    string parts[];
    int count = StringSplit(message, StringGetCharacter("-", 0), parts);
    
    if(count < 2) {
        Print("Định dạng tin nhắn không đúng. Cần: BUY - XAU - M1");
        return;
    }
    
    // Làm sạch các phần
    for(int i = 0; i < count; i++) {
        StringTrimLeft(parts[i]);
        StringTrimRight(parts[i]);
    }
    
    // Phân tích lệnh
    string orderType = parts[0];  // BUY hoặc SELL
    string symbol = (count > 1) ? parts[1] : Symbol();
    string timeframe = (count > 2) ? parts[2] : "M1";
    
    // Kiểm tra lệnh hợp lệ
    if(orderType != "BUY" && orderType != "SELL") {
        Print("Lệnh không hợp lệ: ", orderType, ". Chỉ chấp nhận BUY hoặc SELL");
        return;
    }
    
    // Thực hiện lệnh
    ExecuteSimpleOrder(orderType, symbol, timeframe);
}

//+------------------------------------------------------------------+
//| Thực hiện lệnh đơn giản                                         |
//+------------------------------------------------------------------+
void ExecuteSimpleOrder(string orderType, string symbol, string timeframe) {
    // Tạo comment với thông tin đầy đủ
    string comment = InpCommentFilter + "_" + orderType + "_" + symbol + "_" + timeframe;
    
    // Lấy giá hiện tại
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    
    if(ask == 0 || bid == 0) {
        Print("Không thể lấy giá cho symbol: ", symbol);
        return;
    }
    
    // Tính toán Stop Loss
    double stopLoss = 0;
    if(InpInitialSL > 0) {
        if(orderType == "BUY") {
            stopLoss = NormalizeDouble(ask - InpInitialSL * _Point, _Digits);
        } else {
            stopLoss = NormalizeDouble(bid + InpInitialSL * _Point, _Digits);
        }
    }
    
    // Thực hiện lệnh
    bool result = false;
    if(orderType == "BUY") {
        result = trade.Buy(InpLotSize, symbol, ask, stopLoss, 0, comment);
    } else {
        result = trade.Sell(InpLotSize, symbol, bid, stopLoss, 0, comment);
    }
    
    if(result) {
        Print("Lệnh thành công: ", orderType, " ", InpLotSize, " lots ", symbol, 
              " | SL: ", stopLoss, " | Comment: ", comment);
        
        // Gửi thông báo về Telegram
        SendTradeNotification(orderType, symbol, (orderType == "BUY") ? ask : bid, stopLoss);
    } else {
        Print("Lỗi thực hiện lệnh: ", trade.ResultRetcode(), " - ", trade.ResultComment());
    }
}

//+------------------------------------------------------------------+
//| Gửi thông báo trade về Telegram                                 |
//+------------------------------------------------------------------+
void SendTradeNotification(string orderType, string symbol, double price, double sl) {
    string token = GetTrimmedToken(InpBotToken);
    if(token == "NULL") return;
    
    string message = "✅ Lệnh " + orderType + " đã được thực hiện!\n";
    message += "📊 Symbol: " + symbol + "\n";
    message += "💰 Price: " + DoubleToString(price, _Digits) + "\n";
    message += "🛡️ Stop Loss: " + DoubleToString(sl, _Digits) + "\n";
    message += "📦 Lot: " + DoubleToString(InpLotSize, 2) + "\n";
    message += "⏰ Time: " + TimeToString(TimeCurrent());
    
    string url = TELEGRAM_BASE_URL + "/bot" + token + "/sendMessage";
    string params = "chat_id=" + InpChatID + "&text=" + UrlEncode(message) + "&parse_mode=HTML";
    
    string response;
    PostRequest(response, url, params, WEB_TIMEOUT);
}

//+------------------------------------------------------------------+
//| URL Encode function                                              |
//+------------------------------------------------------------------+
string UrlEncode(const string text) {
    string result = "";
    int length = StringLen(text);
    
    for(int i = 0; i < length; i++) {
        ushort character = StringGetCharacter(text, i);
        
        if((character >= 48 && character <= 57) ||   // 0-9
           (character >= 65 && character <= 90) ||   // A-Z
           (character >= 97 && character <= 122) ||  // a-z
           (character == '-') || (character == '_') || 
           (character == '.') || (character == '~')) {
            result += ShortToString(character);
        }
        else if(character == ' ') {
            result += "+";
        }
        else {
            result += StringFormat("%%%02X", character);
        }
    }
    return result;
}

//+------------------------------------------------------------------+
//| Quản lý trailing stop theo comment                              |
//+------------------------------------------------------------------+
void ManageTrailingStop() {
    for(int i = 0; i < PositionsTotal(); i++) {
        if(!positionInfo.SelectByIndex(i)) continue;
        
        // Kiểm tra comment có chứa filter không
        string posComment = positionInfo.Comment();
        if(StringFind(posComment, InpCommentFilter) == -1) continue;
        
        string symbol = positionInfo.Symbol();
        double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ?
            SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
        
        double entryPrice = positionInfo.PriceOpen();
        double currentSL = positionInfo.StopLoss();
        
        double newSL = CalculateTrailingSL(entryPrice, currentPrice, currentSL, positionInfo.PositionType(), symbol);
        
        // Cập nhật SL nếu cần
        if(newSL != currentSL && newSL != 0) {
            if(trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit())) {
                Print("Trailing SL cập nhật cho ", symbol, " từ ", currentSL, " thành ", newSL);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Tính toán trailing stop loss                                    |
//+------------------------------------------------------------------+
double CalculateTrailingSL(double entryPrice, double currentPrice, double currentSL, ENUM_POSITION_TYPE posType, string symbol) {
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double trailingStep = InpTrailingStep * point;
    double newSL = currentSL;
    
    if(posType == POSITION_TYPE_BUY) {
        // Tính số bước giá đã di chuyển từ entry
        double priceMove = currentPrice - entryPrice;
        if(priceMove >= trailingStep) {
            // Tính SL mới: mỗi bước di chuyển được 1 trailingStep thì kéo SL lên
            int steps = (int)(priceMove / trailingStep);
            double targetSL = entryPrice + (steps - 1) * trailingStep;
            
            // Chỉ cập nhật nếu SL mới cao hơn SL hiện tại
            if(targetSL > currentSL || currentSL == 0) {
                newSL = NormalizeDouble(targetSL, digits);
            }
        }
    }
    else { // SELL position
        // Tính số bước giá đã di chuyển từ entry
        double priceMove = entryPrice - currentPrice;
        if(priceMove >= trailingStep) {
            // Tính SL mới
            int steps = (int)(priceMove / trailingStep);
            double targetSL = entryPrice - (steps - 1) * trailingStep;
            
            // Chỉ cập nhật nếu SL mới thấp hơn SL hiện tại
            if(targetSL < currentSL || currentSL == 0) {
                newSL = NormalizeDouble(targetSL, digits);
            }
        }
    }
    
    return newSL;
}

//+------------------------------------------------------------------+