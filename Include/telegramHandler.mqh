//+------------------------------------------------------------------+
//|                                              TelegramHandler.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "CJSONValue.mqh"

//+------------------------------------------------------------------+
//|   TELEGRAM API HANDLER                                           |
//+------------------------------------------------------------------+

#define TELEGRAM_BASE_URL  "https://api.telegram.org"
#define WEB_TIMEOUT        5000

//+------------------------------------------------------------------+
//| Hàm giải mã chuỗi chứa ký tự đã mã hóa & Unicode                 |
//+------------------------------------------------------------------+
string decodeStringCharacters(string text){
//--- thay \n bằng ký tự ASCII tương ứng (hex 0x0A)
StringReplace(text,"\n",ShortToString(0x0A));

//--- thay thế \u0000
int highSurrogate=0; // dùng để lưu high surrogate của cặp ký tự Unicode.
int pos=StringFind(text,"\\u");
while(pos!=-1){
    string strcode=StringSubstr(text,pos,6);
    string strhex=StringSubstr(text,pos+2,4);

    StringToUpper(strhex);//Chuyển thành chữ hoa để chuẩn hóa xử lý.

    int total=StringLen(strhex);
    int result=0;
    //vòng lặp tính giá trị thập phân của số hex
    for(int i=0,k=total-1; i<total; i++,k--){
        int coef=(int)pow(2,4*k); //hệ số đại diện cho giá trị từng chữ số hex.
        ushort character=StringGetCharacter(strhex,i);
        //chuyển ký tự hex sang giá trị thập phân.
        if(character>='0' && character<='9'){result+=(character-'0')*coef;}
        if(character>='A' && character<='F'){result+=(character-'A'+10)*coef;}
    }

    if(highSurrogate!=0){//nghĩa là đã tìm thấy high surrogate trước đó
        if(result>=0xDC00 && result<=0xDFFF){//nếu result là low surrogate
            int dec=((highSurrogate-0xD800)<<10)+(result-0xDC00);//+0x10000;
            getStringReplacement(text,pos,6,ShortToString((ushort)dec));
            highSurrogate=0;
        }
        else{
            //Nếu result không phải low surrogate hợp lệ, reset haut về 0,
            //báo lỗi chuỗi.
            //--- lỗi: Byte thứ hai không hợp lệ
            highSurrogate=0;
        }
    }
    else{
        //nếu result là high surrogate, lưu lại để dùng cho cặp tiếp theo
        //và xóa high surrogate khỏi chuỗi.
        if(result>=0xD800 && result<=0xDBFF){
            highSurrogate=result;
            getStringReplacement(text,pos,6,"");
        }
        else{
            //Nếu không phải cặp surrogate, thay thế chuỗi escape bằng ký tự tương ứng.
            getStringReplacement(text,pos,6,ShortToString((ushort)result));
        }
    }
    //Cập nhật pos để tìm tiếp chuỗi Unicode escape tiếp theo.
    pos=StringFind(text,"\\u",pos);
}
return(text);
}

//+------------------------------------------------------------------+
//| Hàm thay thế chuỗi                                               |
//+------------------------------------------------------------------+
int getStringReplacement(string &string_var,const int start_pos,const int length,
                    const string replacement){
string temporaryString=(start_pos==0)?"":StringSubstr(string_var,0,start_pos);
temporaryString+=replacement;
temporaryString+=StringSubstr(string_var,start_pos+length);
string_var=temporaryString;
return(StringLen(replacement));
}

//+------------------------------------------------------------------+
//| Function to get the Trimmed Bot's Token                          |
//+------------------------------------------------------------------+
string getTrimmedToken(const string bot_token){
string token=getTrimmedString(bot_token); //--- Trim the bot_token using getTrimmedString function.
if(token==""){ //--- Check if the trimmed token is empty.
    Print("ERR: TOKEN EMPTY"); //--- Print an error message if the token is empty.
    return("NULL"); //--- Return "NULL" if the token is empty.
}
return(token); //--- Return the trimmed token.
}

//+------------------------------------------------------------------+
//| Function to get a Trimmed string                                 |
//+------------------------------------------------------------------+
string getTrimmedString(string text){
StringTrimLeft(text); //--- Remove leading whitespace from the string.
StringTrimRight(text); //--- Remove trailing whitespace from the string.
return(text); //--- Return the trimmed string.
}

//+------------------------------------------------------------------+
//| Create a custom reply keyboard markup for Telegram               |
//+------------------------------------------------------------------+
string customReplyKeyboardMarkup(const string keyboard, const bool resize,
                        const bool one_time){
// Tạo chuỗi JSON cho custom reply keyboard.
// 'keyboard' xác định bố cục bàn phím tuỳ chỉnh.
// 'resize' xác định có tự động co giãn bàn phím không.
// 'one_time' xác định bàn phím có biến mất sau khi dùng không.

// 'resize' > true: Bàn phím sẽ co giãn vừa màn hình.
// 'one_time' > true: Bàn phím sẽ biến mất sau khi người dùng sử dụng.
// 'selective' > false: Bàn phím sẽ hiển thị cho tất cả người dùng.

string result = "{" 
                "\"keyboard\": " + UrlEncode(keyboard) + ", " //--- Mã hóa và đặt bố cục bàn phím
                "\"one_time_keyboard\": " + convertBoolToString(one_time) + ", " //--- Đặt bàn phím biến mất sau khi dùng
                "\"resize_keyboard\": " + convertBoolToString(resize) + ", " //--- Đặt bàn phím tự động co giãn
                "\"selective\": false" //--- Bàn phím hiển thị cho tất cả
                "}";

return(result); //--- Trả về chuỗi JSON cho custom reply keyboard
}

//+------------------------------------------------------------------+
//| Hàm mã hóa chuỗi để dùng trong URL                               |
//+------------------------------------------------------------------+
string UrlEncode(const string text){
string result=NULL;
int length=StringLen(text);
for(int i=0; i<length; i++){
    ushort character=StringGetCharacter(text,i);
    // Kiểm tra ký tự là số, chữ cái, hoặc ký tự đặc biệt không cần mã hóa.
    if((character>=48 && character<=57) || // 0-9
            (character>=65 && character<=90) || // A-Z
            (character>=97 && character<=122) || // a-z
            (character=='!') || (character=='\'') || (character=='(') ||
            (character==')') || (character=='*') || (character=='-') ||
            (character=='.') || (character=='_') || (character=='~')
    ){
        // Thêm ký tự vào chuỗi kết quả không mã hóa.
        result+=ShortToString(character);
    }
    else{
        // Nếu là khoảng trắng, thay bằng '+'
        if(character==' '){
            result+=ShortToString('+');
        }
        else{
            uchar array[];
            int total=ShortToUtf8(character,array);
            for(int k=0; k<total; k++){
            // FORMAT SPECIFIER...
            // %% = LITERAL PERCENT SIGN
            // %02X = ACTUAL FORMAT SPECIFIER
            // 02 = resulting hexadecimal string should be padded with zeros
            //      to ensure it is at least two characters long.
            // X = the number should be converted to a hexadecimal string using
            //     uppercase letters.
            result+=StringFormat("%%%02X",array[k]);
            }
        }
    }
}
return result;
}

//+------------------------------------------------------------------+
//| Chuyển ký tự Unicode sang UTF-8                                  |
//+------------------------------------------------------------------+
int ShortToUtf8(const ushort character,uchar &output[]){
//---
if(character<0x80){
    ArrayResize(output,1);
    output[0]=(uchar)character;
    return(1);
}
//---
if(character<0x800){
    ArrayResize(output,2);
    output[0] = (uchar)((character >> 6)|0xC0);
    output[1] = (uchar)((character & 0x3F)|0x80);
    return(2);
}
//---
if(character<0xFFFF){
    if(character>=0xD800 && character<=0xDFFF){//Sai chuẩn
        ArrayResize(output,1);
        output[0]=' ';
        return(1);
    }
    else if(character>=0xE000 && character<=0xF8FF){//Emoji
        int character_int=0x10000|character;
        ArrayResize(output,4);
        output[0] = (uchar)(0xF0 | (character_int >> 18));
        output[1] = (uchar)(0x80 | ((character_int >> 12) & 0x3F));
        output[2] = (uchar)(0x80 | ((character_int >> 6) & 0x3F));
        output[3] = (uchar)(0x80 | ((character_int & 0x3F)));
        return(4);
    }
    else{
        ArrayResize(output,3);
        output[0] = (uchar)((character>>12)|0xE0);
        output[1] = (uchar)(((character>>6)&0x3F)|0x80);
        output[2] = (uchar)((character&0x3F)|0x80);
        return(3);
    }
}
ArrayResize(output,3);
output[0] = 0xEF;
output[1] = 0xBF;
output[2] = 0xBD;
return(3);
}

//+------------------------------------------------------------------+
//| Chuyển giá trị boolean thành chuỗi                              |
//+------------------------------------------------------------------+
string convertBoolToString(const bool _value){
if(_value)
    return("true"); //--- Trả về "true" nếu giá trị boolean là true
return("false"); //--- Trả về "false" nếu giá trị boolean là false
}

//+------------------------------------------------------------------+
//| Tạo JSON để ẩn custom reply keyboard                            |
//+------------------------------------------------------------------+
string hideCustomReplyKeyboard(){
return("{\"hide_keyboard\": true}"); //--- JSON để ẩn custom reply keyboard
}

//+------------------------------------------------------------------+
//| Tạo JSON để bắt buộc trả lời một tin nhắn                        |
//+------------------------------------------------------------------+
string forceReplyCustomKeyboard(){
return("{\"force_reply\": true}"); //--- JSON để bắt buộc trả lời tin nhắn
}

//+------------------------------------------------------------------+
//| Gửi tin nhắn tới Telegram                                        |
//+------------------------------------------------------------------+
int sendMessageToTelegram(const long chat_id,const string text,
                const string reply_markup=NULL,const string bot_token=""){
string output; //--- Biến lưu phản hồi từ request
string url=TELEGRAM_BASE_URL+"/bot"+getTrimmedToken(bot_token)+"/sendMessage"; //--- Tạo URL cho API Telegram

//--- Tạo tham số cho API
string params="chat_id="+IntegerToString(chat_id)+"&text="+UrlEncode(text); //--- Đặt chat ID và nội dung tin nhắn
if(reply_markup!=NULL){ //--- Nếu có reply markup
    params+="&reply_markup="+reply_markup; //--- Thêm reply markup vào tham số
}
params+="&parse_mode=HTML"; //--- Đặt chế độ parse là HTML (có thể là Markdown)
params+="&disable_web_page_preview=true"; //--- Tắt xem trước web trong tin nhắn

//--- Gửi yêu cầu POST tới API Telegram
int res=postRequest(output,url,params,WEB_TIMEOUT); //--- Gọi postRequest để gửi tin nhắn
return(res); //--- Trả về mã phản hồi từ request
}

//+------------------------------------------------------------------+
//| Gửi ảnh chụp màn hình tới Telegram                               |
//+------------------------------------------------------------------+
void sendScreenshotToTelegram(const long chat_id,string symbol, ENUM_TIMEFRAMES period,
                    string caption, const string bot_token=""
){
const string SCREENSHOT_FILE_NAME = "My ScreenShot.jpg";

long chart_id=ChartOpen(symbol,period);
ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
// update chart
int wait=60;
while(--wait>0){//decrease the value of wait by 1 before loop condition check
    if(SeriesInfoInteger(symbol,period,SERIES_SYNCHRONIZED)){
        break; // if prices up to date, terminate the loop and proceed
    }
}

ChartRedraw(chart_id);
ChartSetInteger(chart_id,CHART_SHOW_GRID,false);
ChartSetInteger(chart_id,CHART_SHOW_PERIOD_SEP,false);

if(FileIsExist(SCREENSHOT_FILE_NAME)){
    FileDelete(SCREENSHOT_FILE_NAME);
    ChartRedraw(chart_id);
}
    
ChartScreenShot(chart_id,SCREENSHOT_FILE_NAME,1366,768,ALIGN_RIGHT);
//Sleep(10000); // sleep for 10 secs to see the opened chart
ChartClose(chart_id);

// waitng 30 sec for save screenshot if not yet saved
wait=60;
while(!FileIsExist(SCREENSHOT_FILE_NAME) && --wait>0){
    Sleep(500);
}

if(!FileIsExist(SCREENSHOT_FILE_NAME)){
    Print("SPECIFIED SCREENSHOT DOES NOT EXIST. REVERTING NOW!");
    return;
}

int screenshot_Handle = FileOpen(SCREENSHOT_FILE_NAME,FILE_READ|FILE_BIN);
if(screenshot_Handle == INVALID_HANDLE){
    Print("INVALID SCREENSHOT HANDLE. REVERTING NOW!");
    return;
}

int screenshot_Handle_Size = (int)FileSize(screenshot_Handle);
uchar photoArr_Data[];
ArrayResize(photoArr_Data,screenshot_Handle_Size);
FileReadArray(screenshot_Handle,photoArr_Data,0,screenshot_Handle_Size);
FileClose(screenshot_Handle);

uchar base64[];
uchar key[];
CryptEncode(CRYPT_BASE64,photoArr_Data,key,base64);
uchar temporaryArr[1024]= {0};
ArrayCopy(temporaryArr,base64,0,0,1024);
uchar md5[];
CryptEncode(CRYPT_HASH_MD5,temporaryArr,key,md5);
string hash=NULL;//Used to store the hexadecimal representation of MD5 hash
int total=ArraySize(md5);
for(int i=0; i<total; i++){
    hash+=StringFormat("%02X",md5[i]);
}
hash=StringSubstr(hash,0,16);//truncate hash string to its first 16 characters

//--- WebRequest
string URL = TELEGRAM_BASE_URL+"/bot"+getTrimmedToken(bot_token)+"/sendPhoto";
string HEADERS = NULL;
char DATA[];
char RESULT[];
string RESULT_HEADERS = NULL;
string CAPTION = NULL;
const string METHOD = "POST";

ArrayAdd(DATA,"\r\n");
ArrayAdd(DATA,"--"+hash+"\r\n");
ArrayAdd(DATA,"Content-Disposition: form-data; name=\"chat_id\"\r\n");
ArrayAdd(DATA,"\r\n");
ArrayAdd(DATA,IntegerToString(chat_id));
ArrayAdd(DATA,"\r\n");

CAPTION = caption;
if(StringLen(CAPTION) > 0){
    ArrayAdd(DATA,"--"+hash+"\r\n");
    ArrayAdd(DATA,"Content-Disposition: form-data; name=\"caption\"\r\n");
    ArrayAdd(DATA,"\r\n");
    ArrayAdd(DATA,CAPTION);
    ArrayAdd(DATA,"\r\n");
}

ArrayAdd(DATA,"--"+hash+"\r\n");
ArrayAdd(DATA,"Content-Disposition: form-data; name=\"photo\"; filename=\"Upload_ScreenShot.jpg\"\r\n");
ArrayAdd(DATA,"\r\n");
ArrayAdd(DATA,photoArr_Data);
ArrayAdd(DATA,"\r\n");
ArrayAdd(DATA,"--"+hash+"--\r\n");

HEADERS = "Content-Type: multipart/form-data; boundary="+hash+"\r\n";

int res_WebReq = WebRequest(METHOD,URL,HEADERS,WEB_TIMEOUT,DATA,RESULT,RESULT_HEADERS);

if(res_WebReq == 200){
    //ArrayPrint(RESULT);
    string result = CharArrayToString(RESULT,0,WHOLE_ARRAY,CP_UTF8);
    Print(result);
    Print("SUCCESS SENDING THE SCREENSHOT TO TELEGRAM");
}
else{
    if(res_WebReq == -1){
        string result = CharArrayToString(RESULT,0,WHOLE_ARRAY,CP_UTF8);
        Print(result);
        Print("ERROR",_LastError," IN WEBREQUEST");
        if (_LastError == 4014){
            Print("API URL NOT LISTED. PLEASE ADD/ALLOW IT IN TERMINAL");
            return;
        }
    }
    else{
        string result = CharArrayToString(RESULT,0,WHOLE_ARRAY,CP_UTF8);
        Print(result);
        Print("UNEXPECTED ERROR: ",_LastError);
        return;
    }
}
}

//+------------------------------------------------------------------+
//| ArrayAdd for uchar Array                                         |
//+------------------------------------------------------------------+
void ArrayAdd(uchar &destinationArr[],const uchar &sourceArr[]){
int sourceArr_size=ArraySize(sourceArr);//get size of source array
if(sourceArr_size==0){
    return;//if source array is empty, exit the function
}
int destinationArr_size=ArraySize(destinationArr);
//resize destination array to fit new data
ArrayResize(destinationArr,destinationArr_size+sourceArr_size,500);
// Copy the source array to the end of the destination array.
ArrayCopy(destinationArr,sourceArr,destinationArr_size,0,sourceArr_size);
}

//+------------------------------------------------------------------+
//| ArrayAdd for strings                                             |
//+------------------------------------------------------------------+
void ArrayAdd(char &destinationArr[],const string text){
int length = StringLen(text);// get the length of the input text
if(length > 0){
    uchar sourceArr[]; //define an array to hold the UTF-8 encoded characters
    for(int i=0; i<length; i++){
        // Get the character code of the current character
        ushort character = StringGetCharacter(text,i);
        uchar array[];//define an array to hold the UTF-8 encoded character
        //Convert the character to UTF-8 & get size of the encoded character
        int total = ShortToUtf8(character,array);
        
        //Print("text @ ",i," > "text); // @ "B", IN ASCII TABLE = 66 (CHARACTER)
        //Print("character = ",character);
        //ArrayPrint(array);
        //Print("bytes = ",total) // bytes of the character
        
        int sourceArr_size = ArraySize(sourceArr);
        //Resize the source array to accommodate the new character
        ArrayResize(sourceArr,sourceArr_size+total);
        //Copy the encoded character to the source array
        ArrayCopy(sourceArr,array,sourceArr_size,0,total);
    }
    //Append the source array to the destination array
    ArrayAdd(destinationArr,sourceArr);
}
}àm gửi yêu cầu POST và nhận phản hồi                            |
//+------------------------------------------------------------------+
int postRequest(string &response, const string url, const string params,const int timeout=5000)
{
char data[]; //--- Mảng lưu dữ liệu sẽ gửi trong request
int data_size=StringLen(params); //--- Lấy độ dài tham số
StringToCharArray(params, data, 0, data_size); //--- Chuyển chuỗi tham số thành mảng ký tự

uchar result[]; //--- Mảng lưu dữ liệu phản hồi
string result_headers; //--- Biến lưu header phản hồi

//--- Gửi yêu cầu POST tới URL với tham số và timeout cho trước
int response_code=WebRequest("POST", url, NULL, NULL, timeout, data, data_size, result, result_headers);
if(response_code==200){ //--- Nếu mã phản hồi là 200 (OK)
    //--- Xóa Byte Order Mark (BOM) nếu có
    int start_index=0; //--- Khởi tạo chỉ số bắt đầu cho phản hồi
    int size=ArraySize(result); //--- Lấy kích thước mảng dữ liệu phản hồi
    // Lặp qua 8 byte đầu của mảng 'result' hoặc toàn bộ nếu nhỏ hơn
    for(int i=0; i<fmin(size,8); i++){
        // Kiểm tra byte hiện tại có phải BOM không
        if(result[i]==0xef || result[i]==0xbb || result[i]==0xbf){
            // Đặt 'start_index' là byte sau BOM
            start_index=i+1;
        }
        else {break;}
    }
    //--- Chuyển dữ liệu phản hồi từ mảng ký tự sang chuỗi, bỏ qua BOM
    response=CharArrayToString(result, start_index, WHOLE_ARRAY, CP_UTF8);
    //Print(response); //--- Có thể in phản hồi để debug

    return(0); //--- Trả về 0 báo thành công
}
else{
    if(response_code==-1){ //--- Nếu có lỗi với WebRequest
        return(_LastError); //--- Trả về mã lỗi cuối cùng
    }
    else{
        //--- Xử lý lỗi HTTP
        if(response_code>=100 && response_code<=511){
            response=CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8); //--- Chuyển kết quả thành chuỗi
            Print(response); //--- In phản hồi để debug
            Print("ERR: HTTP"); //--- In thông báo lỗi HTTP
            return(-1); //--- Trả về -1 báo lỗi HTTP
        }
        return(response_code); //--- Trả về mã phản hồi cho lỗi khác
    }
}
return(0); //--- Trả về 0 nếu có lỗi không xác định
}

//+------------------------------------------------------------------+
//| H