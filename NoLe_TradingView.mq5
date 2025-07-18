//+------------------------------------------------------------------+
//|                                                         DCA_EA.mq5 |
//|           EA quản lý DCA cho XAUUSD theo yêu cầu nhiệm vụ trên    |
//+------------------------------------------------------------------+
#property copyright "BeoNguyen"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>   // Thư viện tiện ích giao dịch (tuỳ chọn)

// Tham số đầu vào:
input ulong magicNumber = 12345; // Magic Number duy nhất cho EA
input string commentText = "MyDCA_EA";// Comment duy nhất đánh dấu lệnh của EA
input string ModeAccount = "m";// Comment duy nhất đánh dấu lệnh của EA
input double lotMultiplier = 1.5; // Hệ số nhân khối lượng DCA
input int dcaDistancePips = 50; // Khoảng cách(pip) giữa các lệnh DCA
input int maxDcaOrders = 5; // Số lệnh DCA tối đa sau lệnh đầu
input int takeProfitPips = 101; // TP nhóm(tính từ entry ban đầu)
input int stopLossPips = 20; // Khoảng thêm cho SL nhóm 

// Biến toàn cục:
ulong initialTicket = 0; // Ticket của lệnh ban đầu(đã được nhận quản lý)
double initialEntryPrice = 0; // Giá vào của lệnh ban đầu
double lastEntryPrice = 0; // Giá vào của lệnh mới nhất trong nhóm(initial hoặc DCA cuối cùng)
double initialVolume = 0; // Khối lượng lệnh ban đầu
int dcaCount = 0; // Đã mở bao nhiêu lệnh DCA
double groupTP = 0, groupSL = 0; // Mức TakeProfit và StopLoss chung của nhóm

//+------------------------------------------------------------------+
//| Hàm khởi tạo EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("EA DCA đã khởi tạo. Magic = ", magicNumber, " Comment = ", commentText);
    OpenMarketOrder("XAUUSD", ORDER_TYPE_SELL, 0.01, 999999);
    Sleep(10000);
    CloseGroupOrders(999999);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Hàm sự kiện mỗi tick - xử lý logic chính                         |
//+------------------------------------------------------------------+
void OnTick()
{

}

//+------------------------------------------------------------------+
//| Đóng toàn bộ lệnh theo magic number (lệnh thị trường + chờ)     |
//+------------------------------------------------------------------+
void CloseGroupOrders(ulong num)
{
    bool hasOrders = false;

    // ----- 1. ĐÓNG VỊ THẾ ĐANG MỞ -----
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket) || PositionGetInteger(POSITION_MAGIC) != num) 
            continue;

        hasOrders = true;

        string symbol = PositionGetString(POSITION_SYMBOL);
        double volume = PositionGetDouble(POSITION_VOLUME);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        MqlTradeRequest request;
        MqlTradeResult  result;
        ZeroMemory(request);
        ZeroMemory(result);

        request.action   = TRADE_ACTION_DEAL;
        request.symbol   = symbol;
        request.volume   = volume;
        request.position = ticket;
        request.deviation = 10;
        request.magic    = num;
        request.type_filling = ORDER_FILLING_IOC;

        // Đóng bằng lệnh đối nghịch
        request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

        bool res = OrderSend(request, result);
        if(!res || result.retcode != TRADE_RETCODE_DONE)
            PrintFormat("❌ Lỗi đóng vị thế #%I64u: %s", ticket, result.comment);
        else
            PrintFormat("✅ Đã đóng vị thế #%I64u với magic=%I64u", ticket, num);
    }

    // ----- 2. HỦY LỆNH CHỜ -----
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if(!OrderSelect(ticket) || OrderGetInteger(ORDER_MAGIC) != num)
            continue;

        hasOrders = true;
        string symbol = OrderGetString(ORDER_SYMBOL);

        MqlTradeRequest request;
        MqlTradeResult  result;
        ZeroMemory(request);
        ZeroMemory(result);

        request.action = TRADE_ACTION_REMOVE;
        request.order  = ticket;
        request.symbol = symbol;

        bool res = OrderSend(request, result);
        if(!res || result.retcode != TRADE_RETCODE_DONE)
            PrintFormat("❌ Lỗi huỷ lệnh chờ #%I64u: %s", ticket, result.comment);
        else
            PrintFormat("✅ Đã huỷ lệnh chờ #%I64u với magic=%I64u", ticket, num);
    }

    if(!hasOrders)
        PrintFormat("⚠️ Không có lệnh nào với magic = %I64u để đóng!", num);
}


//+------------------------------------------------------------------+
//| Vào lệnh thị trường trực tiếp VD:("XAUUSD", ORDER_TYPE_SELL, 0.2, 999999)
//+------------------------------------------------------------------+
bool OpenMarketOrder(string symbol, ENUM_ORDER_TYPE type, double volume, ulong magic)
{
    MqlTradeRequest request;
    MqlTradeResult  result;
    ZeroMemory(request);
    ZeroMemory(result);

    request.action   = TRADE_ACTION_DEAL;
    request.symbol   = symbol + ModeAccount;
    request.volume   = volume;
    request.type     = type;
    request.deviation = 10;
    request.magic    = magic;
    request.type_filling = ORDER_FILLING_IOC;

    // Giá khớp lệnh
    request.price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

    bool res = OrderSend(request, result);
    if(!res || result.retcode != TRADE_RETCODE_DONE)
    {
        PrintFormat("❌ Lỗi vào lệnh %s: %s", symbol, result.comment);
        return false;
    }

    PrintFormat("✅ Đã vào lệnh thị trường %s #%I64u với volume=%.2f", EnumToString(type), result.order, volume);
    return true;
}


//+------------------------------------------------------------------+
