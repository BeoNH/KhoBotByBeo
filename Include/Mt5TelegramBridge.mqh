//+------------------------------------------------------------------+
//|                                          Mt5TelegramBridge.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "CJSONValue.mqh"
#include "TelegramHandler.mqh"
#include <Trade/Trade.mqh>
#include <Arrays/List.mqh>
#include <Arrays/ArrayString.mqh>

//+------------------------------------------------------------------+
//|        Class_Message                                             |
//+------------------------------------------------------------------+
class Class_Message : public CObject{//--- Defines a class named Class_Message that inherits from CObject.
    public:
        Class_Message(); //--- Constructor declaration.
        ~Class_Message(){}; //--- Declares an empty destructor for the class.
        
        //--- Member variables to track the status of the message.
        bool              done; //--- Indicates if a message has been processed.
        long              update_id; //--- Stores the update ID from Telegram.
        long              message_id; //--- Stores the message ID.

        //--- Member variables to store sender-related information.
        long              from_id; //--- Stores the sender's ID.
        string            from_first_name; //--- Stores the sender's first name.
        string            from_last_name; //--- Stores the sender's last name.
        string            from_username; //--- Stores the sender's username.

        //--- Member variables to store chat-related information.
        long              chat_id; //--- Stores the chat ID.
        string            chat_first_name; //--- Stores the chat first name.
        string            chat_last_name; //--- Stores the chat last name.
        string            chat_username; //--- Stores the chat username.
        string            chat_type; //--- Stores the chat type.

        //--- Member variables to store message-related information.
        datetime          message_date; //--- Stores the date of the message.
        string            message_text; //--- Stores the text of the message.
};

    //+------------------------------------------------------------------+
    //|      Constructor to initialize class members                     |
    //+------------------------------------------------------------------+
    Class_Message::Class_Message(void){
    //--- Initialize the boolean 'done' to false, indicating the message is not processed.
    done = false;

    //--- Initialize message-related IDs to zero.
    update_id = 0;
    message_id = 0;

    //--- Initialize sender-related information.
    from_id = 0;
    from_first_name = NULL;
    from_last_name = NULL;
    from_username = NULL;

    //--- Initialize chat-related information.
    chat_id = 0;
    chat_first_name = NULL;
    chat_last_name = NULL;
    chat_username = NULL;
    chat_type = NULL;

    //--- Initialize the message date and text.
    message_date = 0;
    message_text = NULL;
    }

    //+------------------------------------------------------------------+
    //|        Class_Chat                                                |
    //+------------------------------------------------------------------+
    class Class_Chat : public CObject{
    public:
        Class_Chat(){}; //Khai báo constructor rỗng.
        ~Class_Chat(){}; // Hàm hủy
        long              member_id;//Lưu ID của cuộc trò chuyện.
        int               member_state;//Lưu trạng thái của cuộc trò chuyện.
        datetime          member_time;//Lưu thời gian liên quan đến cuộc trò chuyện.
        Class_Message     member_last;//Một instance của Class_Message để lưu tin nhắn cuối cùng.
        Class_Message     member_new_one;//Một instance của Class_Message để lưu tin nhắn mới.
    };

    //+------------------------------------------------------------------+
    //|   Class_Bot_EA                                                    |
    //+------------------------------------------------------------------+
    class Class_Bot_EA{
    private:
        string            member_token;         //--- Lưu token của bot.
        string            member_name;          //--- Lưu tên của bot.
        long              member_update_id;     //--- Lưu update ID cuối cùng đã được bot xử lý.
        CArrayString      member_users_filter;  //--- Mảng để lọc người dùng.
        bool              member_first_remove;  //--- Biến boolean để xác định có nên loại bỏ tin nhắn đầu tiên không.

    protected:
        CList             member_chats;         //--- Danh sách lưu các đối tượng chat.

    public:
        void Class_Bot_EA(const string bot_token="");   //--- Khai báo constructor.
        ~Class_Bot_EA(){};    //--- Khai báo destructor.
        int getChatUpdates(); //--- Khai báo hàm lấy cập nhật từ Telegram.
        void ProcessMessages(); //--- Khai báo hàm xử lý các tin nhắn đến.
    };

    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+
    void Class_Bot_EA::Class_Bot_EA(const string bot_token=""){ //--- Constructor
    member_token=NULL; //--- Khởi tạo token của bot là NULL.
    member_token=getTrimmedToken(bot_token); //--- Gán token đã loại bỏ khoảng trắng từ bot_token.
    member_name=NULL; //--- Khởi tạo tên bot là NULL.
    member_update_id=0; //--- Khởi tạo update ID cuối cùng là 0.
    member_first_remove=true; //--- Đặt cờ loại bỏ tin nhắn đầu tiên là true.
    member_chats.Clear(); //--- Xóa danh sách các đối tượng chat.
    member_users_filter.Clear(); //--- Xóa mảng lọc người dùng.
    }

    //+------------------------------------------------------------------+
    //| Lấy cập nhật từ Telegram                                         |
    //+------------------------------------------------------------------+
    int Class_Bot_EA::getChatUpdates(void){
    //--- Kiểm tra nếu token của bot là NULL
    if(member_token==NULL){
        Print("ERR: TOKEN EMPTY"); //--- In ra thông báo lỗi nếu token rỗng
        return(-1); //--- Trả về mã lỗi
    }

    string out; //--- Biến lưu phản hồi từ request
    string url=TELEGRAM_BASE_URL+"/bot"+member_token+"/getUpdates"; //--- Tạo URL cho request API Telegram
    string params="offset="+IntegerToString(member_update_id); //--- Đặt tham số offset để lấy các cập nhật sau ID đã xử lý cuối cùng

    //--- Gửi request POST để lấy cập nhật từ Telegram
    int res=postRequest(out, url, params, WEB_TIMEOUT);
    // ĐÂY LÀ CHUỖI PHẢN HỒI CHÚNG TA NHẬN ĐƯỢC // "ok":true,"result":[]}

    //--- Nếu request thành công
    if(res==0){
        //Print(out); //--- (Tùy chọn) In ra phản hồi
        
        //--- Tạo đối tượng JSON để phân tích phản hồi
        CJSONValue obj_json(NULL, jv_UNDEF);
        //--- Giải mã phản hồi JSON
        bool done=obj_json.Deserialize(out);
        //--- Nếu phân tích JSON thất bại
        // Print(done);
        if(!done){
            Print("ERR: JSON PARSING"); //--- In ra thông báo lỗi nếu phân tích thất bại
            return(-1); //--- Trả về mã lỗi
        }
        
        //--- Kiểm tra trường 'ok' trong JSON có true không
        bool ok=obj_json["ok"].ToBool();
        //--- Nếu 'ok' là false, có lỗi trong phản hồi
        if(!ok){
            Print("ERR: JSON NOT OK"); //--- In ra thông báo lỗi nếu 'ok' là false
            return(-1); //--- Trả về mã lỗi
        }
        
        //--- Tạo đối tượng message để lưu thông tin tin nhắn
        Class_Message obj_msg;
        
        //--- Lấy tổng số cập nhật trong mảng JSON 'result'
        int total=ArraySize(obj_json["result"].m_elements);
        //--- Lặp qua từng cập nhật
        for(int i=0; i<total; i++){
            //--- Lấy từng phần tử cập nhật dưới dạng đối tượng JSON
            CJSONValue obj_item=obj_json["result"].m_elements[i];
            
            //--- Trích xuất thông tin tin nhắn từ đối tượng JSON
            obj_msg.update_id=obj_item["update_id"].ToInt(); //--- Lấy update ID
            obj_msg.message_id=obj_item["message"]["message_id"].ToInt(); //--- Lấy message ID
            obj_msg.message_date=(datetime)obj_item["message"]["date"].ToInt(); //--- Lấy ngày gửi tin nhắn
            
            obj_msg.message_text=obj_item["message"]["text"].ToStr(); //--- Lấy nội dung tin nhắn
            obj_msg.message_text=decodeStringCharacters(obj_msg.message_text); //--- Giải mã các ký tự đặc biệt trong nội dung tin nhắn
            
            //--- Trích xuất thông tin người gửi từ đối tượng JSON
            obj_msg.from_id=obj_item["message"]["from"]["id"].ToInt(); //--- Lấy ID người gửi
            obj_msg.from_first_name=obj_item["message"]["from"]["first_name"].ToStr(); //--- Lấy tên người gửi
            obj_msg.from_first_name=decodeStringCharacters(obj_msg.from_first_name); //--- Giải mã tên người gửi
            obj_msg.from_last_name=obj_item["message"]["from"]["last_name"].ToStr(); //--- Lấy họ người gửi
            obj_msg.from_last_name=decodeStringCharacters(obj_msg.from_last_name); //--- Giải mã họ người gửi
            obj_msg.from_username=obj_item["message"]["from"]["username"].ToStr(); //--- Lấy username người gửi
            obj_msg.from_username=decodeStringCharacters(obj_msg.from_username); //--- Giải mã username
            
            //--- Trích xuất thông tin chat từ đối tượng JSON
            obj_msg.chat_id=obj_item["message"]["chat"]["id"].ToInt(); //--- Lấy ID chat
            obj_msg.chat_first_name=obj_item["message"]["chat"]["first_name"].ToStr(); //--- Lấy tên chat
            obj_msg.chat_first_name=decodeStringCharacters(obj_msg.chat_first_name); //--- Giải mã tên chat
            obj_msg.chat_last_name=obj_item["message"]["chat"]["last_name"].ToStr(); //--- Lấy họ chat
            obj_msg.chat_last_name=decodeStringCharacters(obj_msg.chat_last_name); //--- Giải mã họ chat
            obj_msg.chat_username=obj_item["message"]["chat"]["username"].ToStr(); //--- Lấy username chat
            obj_msg.chat_username=decodeStringCharacters(obj_msg.chat_username); //--- Giải mã username chat
            obj_msg.chat_type=obj_item["message"]["chat"]["type"].ToStr(); //--- Lấy loại chat
            
            //--- Cập nhật ID cho request tiếp theo
            member_update_id=obj_msg.update_id+1;
            
            //--- Nếu là cập nhật đầu tiên thì bỏ qua xử lý
            if(member_first_remove){
            continue;
            }

            //--- Lọc tin nhắn dựa trên username
            if(member_users_filter.Total()==0 || //--- Nếu không có bộ lọc thì xử lý tất cả tin nhắn
            (member_users_filter.Total()>0 && //--- Nếu có bộ lọc thì kiểm tra username có trong bộ lọc không
            member_users_filter.SearchLinear(obj_msg.from_username)>=0)){

            //--- Tìm chat trong danh sách các chat
            int index=-1;
            for(int j=0; j<member_chats.Total(); j++){
                Class_Chat *chat=member_chats.GetNodeAtIndex(j);
                if(chat.member_id==obj_msg.chat_id){ //--- Kiểm tra ID chat có trùng không
                    index=j;
                    break;
                }
            }

            //--- Nếu không tìm thấy chat thì thêm chat mới vào danh sách
            if(index==-1){
                member_chats.Add(new Class_Chat); //--- Thêm chat mới vào danh sách
                Class_Chat *chat=member_chats.GetLastNode();
                chat.member_id=obj_msg.chat_id; //--- Gán ID chat
                chat.member_time=TimeLocal(); //--- Gán thời gian hiện tại cho chat
                chat.member_state=0; //--- Khởi tạo trạng thái chat
                chat.member_new_one.message_text=obj_msg.message_text; //--- Gán nội dung tin nhắn mới
                chat.member_new_one.done=false; //--- Đánh dấu tin nhắn mới chưa được xử lý
            }
            //--- Nếu đã tìm thấy chat thì cập nhật tin nhắn
            else{
                Class_Chat *chat=member_chats.GetNodeAtIndex(index);
                chat.member_time=TimeLocal(); //--- Cập nhật thời gian chat
                chat.member_new_one.message_text=obj_msg.message_text; //--- Cập nhật nội dung tin nhắn
                chat.member_new_one.done=false; //--- Đánh dấu tin nhắn mới chưa được xử lý
            }
            }
            
        }
        //--- Sau lần cập nhật đầu tiên, đặt cờ về false
        member_first_remove=false;
    }
    //--- Trả về kết quả của request POST
    return(res);
    }

    //+------------------------------------------------------------------+
    //| Xử lý tin nhắn từ Telegram                                       |
    //+------------------------------------------------------------------+
    void Class_Bot_EA::ProcessMessages(void){

    //--- Định nghĩa các hằng số emoji và nút bàn phím
    #define EMOJI_UP    "\x2B06" //--- Emoji mũi tên lên
    #define EMOJI_PISTOL   "\xF52B" //--- Emoji súng lục
    #define EMOJI_CANCEL "\x274C" //--- Emoji dấu X
    #define KEYB_MAIN    "[[\"Name\"],[\"Account Info\"],[\"Quotes\"],[\"More\",\"Screenshot\",\""+EMOJI_CANCEL+"\"]]" //--- Bố cục bàn phím chính
    #define KEYB_MORE "[[\""+EMOJI_UP+"\"],[\"Buy\",\"Close\",\"Next\"]]" //--- Bố cục bàn phím thêm tùy chọn
    #define KEYB_NEXT "[[\""+EMOJI_UP+"\",\"Contact\",\"Join\",\""+EMOJI_PISTOL+"\"]]" //--- Bố cục bàn phím tùy chọn tiếp theo
    #define KEYB_SYMBOLS "[[\""+EMOJI_UP+"\",\"AUDUSDm\",\"AUDCADm\"],[\"EURJPYm\",\"EURCHFm\",\"EURUSDm\"],[\"USDCHFm\",\"USDCADm\",\""+EMOJI_PISTOL+"\"]]" //--- Bố cục bàn phím chọn symbol
    #define KEYB_PERIODS "[[\""+EMOJI_UP+"\",\"M1\",\"M15\",\"M30\"],[\""+EMOJI_CANCEL+"\",\"H1\",\"H4\",\"D1\"]]" //--- Bố cục bàn phím chọn khung thời gian

    //--- Định nghĩa mảng khung thời gian cho yêu cầu chụp màn hình
    const ENUM_TIMEFRAMES periods[] = {PERIOD_M1,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1};

    //--- Lặp qua tất cả các chat
    for(int i=0; i<member_chats.Total(); i++){
        Class_Chat *chat=member_chats.GetNodeAtIndex(i); //--- Lấy chat hiện tại
        if(!chat.member_new_one.done){ //--- Kiểm tra tin nhắn chưa được xử lý
            chat.member_new_one.done=true; //--- Đánh dấu tin nhắn đã được xử lý
            string text=chat.member_new_one.message_text; //--- Lấy nội dung tin nhắn

            //--- Xử lý lệnh dựa trên nội dung tin nhắn
                    
            //--- Nếu tin nhắn là "/start", "/help", "Start", hoặc "Help"
            if(text=="/start" || text=="/help" || text=="Start" || text=="Help"){
            chat.member_state=0; //--- Đặt lại trạng thái chat
            string message="I am a BOT \xF680 và tôi làm việc với tài khoản giao dịch Forex MT5 của bạn.\n";
            message+="Bạn có thể điều khiển tôi bằng cách gửi các lệnh sau \xF648 :\n";
            message+="\nThông tin\n";
            message+="/name - lấy tên EA\n";
            message+="/info - lấy thông tin tài khoản\n";
            message+="/quotes - lấy giá\n";
            message+="/screenshot - chụp màn hình biểu đồ\n";
            message+="\nGiao dịch\n";
            message+="/buy - mở lệnh mua\n";
            message+="/close - đóng lệnh\n";
            message+="\nTùy chọn khác\n";
            message+="/contact - liên hệ nhà phát triển\n";
            message+="/join - tham gia cộng đồng MQL5 của chúng tôi\n";
            
            //--- Gửi tin nhắn phản hồi kèm bàn phím chính
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MAIN,false,false),member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/name" hoặc "Name"
            if (text=="/name" || text=="Name"){
            string message = "Tên file EA mà tôi điều khiển là:\n";
            message += "\xF50B"+__FILE__+" Enjoy.\n";
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            }

            //--- Nếu tin nhắn là "/info" hoặc "Account Info"
            ushort MONEYBAG = 0xF4B0; //--- Định nghĩa emoji túi tiền
            string MONEYBAGcode = ShortToString(MONEYBAG); //--- Chuyển emoji sang chuỗi
            if(text=="/info" || text=="Account Info"){
            string currency=AccountInfoString(ACCOUNT_CURRENCY); //--- Lấy loại tiền tài khoản
            string message="\x2733\Số tài khoản: "+(string)AccountInfoInteger(ACCOUNT_LOGIN)+"\n";
            message+="\x23F0\Server: "+AccountInfoString(ACCOUNT_SERVER)+"\n";
            message+=MONEYBAGcode+"Số dư: "+(string)AccountInfoDouble(ACCOUNT_BALANCE)+" "+currency+"\n";
            message+="\x2705\Lợi nhuận: "+(string)AccountInfoDouble(ACCOUNT_PROFIT)+" "+currency+"\n";
            
            //--- Gửi tin nhắn phản hồi
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/quotes" hoặc "Quotes"
            if(text=="/quotes" || text=="Quotes"){
            double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); //--- Lấy giá Ask hiện tại
            double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //--- Lấy giá Bid hiện tại
            string message="\xF170 Ask: "+(string)Ask+"\n";
            message+="\xF171 Bid: "+(string)Bid+"\n";
            
            //--- Gửi tin nhắn phản hồi
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/buy" hoặc "Buy"
            if (text=="/buy" || text=="Buy"){
            CTrade obj_trade; //--- Tạo đối tượng giao dịch
            double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); //--- Lấy giá Ask hiện tại
            double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //--- Lấy giá Bid hiện tại
            obj_trade.Buy(0.01,NULL,0,Bid-300*_Point,Bid+300*_Point); //--- Mở lệnh mua
            double entry=0,sl=0,tp=0,vol=0;
            ulong ticket = obj_trade.ResultOrder(); //--- Lấy số ticket của lệnh mới
            if (ticket > 0){
                if (PositionSelectByTicket(ticket)){ //--- Chọn vị thế theo ticket
                    entry=PositionGetDouble(POSITION_PRICE_OPEN); //--- Lấy giá mở cửa
                    sl=PositionGetDouble(POSITION_SL); //--- Lấy giá dừng lỗ
                    tp=PositionGetDouble(POSITION_TP); //--- Lấy giá chốt lời
                    vol=PositionGetDouble(POSITION_VOLUME); //--- Lấy khối lượng
                }
            }
            string message="\xF340\Đã mở lệnh BUY:\n";
            message+="Ticket: "+(string)ticket+"\n";
            message+="Giá mở: "+(string)entry+"\n";
            message+="Khối lượng: "+(string)vol+"\n";
            message+="SL: "+(string)sl+"\n";
            message+="TP: "+(string)tp+"\n";
            
            //--- Gửi tin nhắn phản hồi
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/close" hoặc "Close"
            if (text=="/close" || text=="Close"){
            CTrade obj_trade; //--- Tạo đối tượng giao dịch
            int totalOpenBefore = PositionsTotal(); //--- Lấy tổng số vị thế mở trước khi đóng
            obj_trade.PositionClose(_Symbol); //--- Đóng vị thế cho symbol
            int totalOpenAfter = PositionsTotal(); //--- Lấy tổng số vị thế mở sau khi đóng
            string message="\xF62F\Đã đóng vị thế:\n";
            message+="Tổng vị thế (Trước): "+(string)totalOpenBefore+"\n";
            message+="Tổng vị thế (Sau): "+(string)totalOpenAfter+"\n";
            
            //--- Gửi tin nhắn phản hồi
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/contact" hoặc "Contact"
            if (text=="/contact" || text=="Contact"){
            string message="Liên hệ nhà phát triển qua link dưới đây:\n";
            message+="https://t.me/Forex_Algo_Trader";
            
            //--- Gửi tin nhắn liên hệ
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/join" hoặc "Join"
            if (text=="/join" || text=="Join"){
            string message="Bạn muốn tham gia cộng đồng MQL5 của chúng tôi?\n";
            message+="Chào mừng! <a href=\"https://t.me/forexalgo_trading\">Bấm vào đây</a> để tham gia.\n";
            message+="<s>Civil Engineering</s> Forex AlgoTrading\n";//gạch ngang
            message+="<pre>Đây là ví dụ code MQL5 của chúng tôi</pre>\n";//định dạng code
            message+="<u><i>Nhớ tuân thủ quy tắc cộng đồng!\xF64F\</i></u>\n";//in nghiêng, gạch chân
            message+="<b>Chúc bạn giao dịch vui vẻ!</b>\n";//in đậm
            
            //--- Gửi tin nhắn tham gia
            sendMessageToTelegram(chat.member_id,message,NULL,member_token);
            continue;
            }

            //--- Nếu tin nhắn là "more" hoặc "More"
            if (text=="more" || text=="More"){
            chat.member_state=1; //--- Cập nhật trạng thái chat để hiển thị thêm tùy chọn
            string message="Chọn thêm tùy chọn bên dưới:";
            
            //--- Gửi tin nhắn kèm bàn phím thêm tùy chọn
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MORE,false,true),member_token);
            continue;
            }

            //--- Nếu tin nhắn là emoji mũi tên lên
            if(text==EMOJI_UP){
            chat.member_state=0; //--- Đặt lại trạng thái chat
            string message="Chọn một mục menu:";
            
            //--- Gửi tin nhắn kèm bàn phím chính
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MAIN,false,false),member_token);
            continue;
            }

            //--- Nếu tin nhắn là "next" hoặc "Next"
            if(text=="next" || text=="Next"){
            chat.member_state=2; //--- Cập nhật trạng thái chat để hiển thị tùy chọn tiếp theo
            string message="Chọn thêm tùy chọn bên dưới:";
            
            //--- Gửi tin nhắn kèm bàn phím tùy chọn tiếp theo
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_NEXT,false,true),member_token);
            continue;
            }

            //--- Nếu tin nhắn là emoji súng lục
            if (text==EMOJI_PISTOL){
            if (chat.member_state==2){
                chat.member_state=1; //--- Chuyển trạng thái để hiển thị thêm tùy chọn
                string message="Chọn thêm tùy chọn bên dưới:";
                
                //--- Gửi tin nhắn kèm bàn phím thêm tùy chọn
                sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MORE,false,true),member_token);
            }
            else {
                chat.member_state=0; //--- Đặt lại trạng thái chat
                string message="Chọn một mục menu:";
                
                //--- Gửi tin nhắn kèm bàn phím chính
                sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MAIN,false,false),member_token);
            }
            continue;
            }

            //--- Nếu tin nhắn là emoji hủy
            if (text==EMOJI_CANCEL){
            chat.member_state=0; //--- Đặt lại trạng thái chat
            string message="Chọn /start hoặc /help để bắt đầu.";
            
            //--- Gửi tin nhắn hủy kèm bàn phím ẩn
            sendMessageToTelegram(chat.member_id,message,hideCustomReplyKeyboard(),member_token);
            continue;
            }

            //--- Nếu tin nhắn là "/screenshot" hoặc "Screenshot"
            static string symbol = _Symbol; //--- Symbol mặc định
            static ENUM_TIMEFRAMES period = _Period; //--- Khung thời gian mặc định
            if (text=="/screenshot" || text=="Screenshot"){
            chat.member_state = 10; //--- Đặt trạng thái yêu cầu chụp màn hình
            string message="Nhập tên symbol, ví dụ 'AUDUSDm'";
            
            //--- Gửi tin nhắn kèm bàn phím chọn symbol
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_SYMBOLS,false,false),member_token);
            continue;
            }

            //--- Xử lý trạng thái 10 (chọn symbol để chụp màn hình)
            if (chat.member_state==10){
            string user_symbol = text; //--- Lấy symbol do người dùng nhập
            if (SymbolSelect(user_symbol,true)){ //--- Kiểm tra symbol hợp lệ
                chat.member_state = 11; //--- Cập nhật trạng thái sang chọn khung thời gian
                string message = "ĐÚNG: Đã tìm thấy symbol\n";
                message += "Bây giờ hãy nhập khung thời gian, ví dụ 'H1'";
                symbol = user_symbol; //--- Cập nhật symbol
                
                //--- Gửi tin nhắn kèm bàn phím chọn khung thời gian
                sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_PERIODS,false,false),member_token);
            }
            else {
                string message = "SAI: Symbol không hợp lệ\n";
                message += "Vui lòng nhập đúng tên symbol như 'AUDUSDm' để tiếp tục.";
                
                //--- Gửi tin nhắn báo lỗi kèm bàn phím chọn symbol
                sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_SYMBOLS,false,false),member_token);
            }
            continue;
            }

            //--- Xử lý trạng thái 11 (chọn khung thời gian để chụp màn hình)
            if (chat.member_state==11){
            bool found=false; //--- Cờ kiểm tra khung thời gian hợp lệ
            int total=ArraySize(periods); //--- Lấy số lượng khung thời gian đã định nghĩa
            for(int k=0; k<total; k++){
                string str_tf=StringSubstr(EnumToString(periods[k]),7); //--- Chuyển enum khung thời gian sang chuỗi
                if(StringCompare(str_tf,text,false)==0){ //--- Kiểm tra khung thời gian có khớp không
                    ENUM_TIMEFRAMES user_period=periods[k]; //--- Gán khung thời gian người dùng chọn
                    period = user_period; //--- Cập nhật khung thời gian
                    found=true;
                    break;
                }
            }
            if (found){
                string message = "ĐÚNG: Khung thời gian hợp lệ\n";
                message += "Bắt đầu gửi ảnh chụp màn hình \xF60E";
                
                //--- Gửi tin nhắn xác nhận kèm bàn phím chọn khung thời gian
                sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_PERIODS,false,false),member_token);
                string caption = "Ảnh chụp Symbol: "+symbol+
                                " ("+EnumToString(ENUM_TIMEFRAMES(period))+
                                ") @ Thời gian: "+TimeToString(TimeCurrent());
                
                //--- Gửi ảnh chụp màn hình lên Telegram
                sendScreenshotToTelegram(chat.member_id,symbol,period,caption,member_token);
            }
            else {
                string message = "SAI: Khung thời gian không hợp lệ\n";
                message += "Vui lòng nhập đúng khung thời gian như 'H1' để tiếp tục.";
                
                //--- Gửi tin nhắn báo lỗi kèm bàn phím chọn khung thời gian
                sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_PERIODS,false,false),member_token);
            }
            continue;
            }

        }
    }
}