//+------------------------------------------------------------------+
//|                                 TELEGRAM_MQL5_COMMANDS_PART5.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//|   BẮT ĐẦU ĐOẠN CODE JSON (TỪ DÒNG 15 ĐẾN DÒNG 737)               |
//+------------------------------------------------------------------+


#define DEBUG_PRINT false
//------------------------------------------------------------------ enum JSONValueType
enum JSONValueType {jv_UNDEF,jv_NULL,jv_BOOL,jv_INT,jv_DBL,jv_STR,jv_ARRAY,jv_OBJ};
//------------------------------------------------------------------ class CJSONValue
class CJSONValue{
   public:
      // CONSTRUCTOR
      virtual void Clear(){
         m_parent=NULL;
         m_key="";
         m_type=jv_UNDEF;
         m_bool_val=false;
         m_int_val=0;
         m_double_val=0;
         m_string_val="";
         ArrayResize(m_elements,0);
      }
      virtual bool Copy(const CJSONValue &source){
         m_key=source.m_key;
         CopyData(source);
         return true;
      }
      virtual void CopyData(const CJSONValue &source){
         m_type=source.m_type;
         m_bool_val=source.m_bool_val;
         m_int_val=source.m_int_val;
         m_double_val=source.m_double_val;
         m_string_val=source.m_string_val;
         CopyArr(source);
      }
      virtual void CopyArr(const CJSONValue &source){
         int n=ArrayResize(m_elements,ArraySize(source.m_elements));
         for(int i=0; i<n; i++){
            m_elements[i]=source.m_elements[i];
            m_elements[i].m_parent=GetPointer(this);
         }
      }

   public:
      CJSONValue        m_elements[];
      string            m_key;
      string            m_lkey;
      CJSONValue       *m_parent;
      JSONValueType     m_type;
      bool              m_bool_val;
      long              m_int_val;
      double            m_double_val;
      string            m_string_val;
      static int        code_page;

   public:
      CJSONValue(){
         Clear();
      }
      CJSONValue(CJSONValue *parent,JSONValueType type){
         Clear();
         m_type=type;
         m_parent=parent;
      }
      CJSONValue(JSONValueType type,string value){
         Clear();
         FromStr(type,value);
      }
      CJSONValue(const int intValue){
         Clear();
         m_type=jv_INT;
         m_int_val=intValue;
         m_double_val=(double)m_int_val;
         m_string_val=IntegerToString(m_int_val);
         m_bool_val=m_int_val!=0;
      }
      CJSONValue(const long longValue){
         Clear();
         m_type=jv_INT;
         m_int_val=longValue;
         m_double_val=(double)m_int_val;
         m_string_val=IntegerToString(m_int_val);
         m_bool_val=m_int_val!=0;
      }
      CJSONValue(const double doubleValue){
         Clear();
         m_type=jv_DBL;
         m_double_val=doubleValue;
         m_int_val=(long)m_double_val;
         m_string_val=DoubleToString(m_double_val);
         m_bool_val=m_int_val!=0;
      }
      CJSONValue(const bool boolValue){
         Clear();
         m_type=jv_BOOL;
         m_bool_val=boolValue;
         m_int_val=m_bool_val;
         m_double_val=m_bool_val;
         m_string_val=IntegerToString(m_int_val);
      }
      CJSONValue(const CJSONValue &other){
         Clear();
         Copy(other);
      }
      // DECONSTRUCTOR
      ~CJSONValue(){
         Clear();
      }
   
   public:
      virtual bool IsNumeric(){
         return (m_type==jv_DBL || m_type==jv_INT);
      }
      virtual CJSONValue *FindKey(string key){
         for(int i=ArraySize(m_elements)-1; i>=0; --i){
            if(m_elements[i].m_key==key){
               return GetPointer(m_elements[i]);
            }
         }
         return NULL;
      }
      virtual CJSONValue *HasKey(string key,JSONValueType type=jv_UNDEF);
      virtual CJSONValue *operator[](string key);
      virtual CJSONValue *operator[](int i);
      void operator=(const CJSONValue &value){
         Copy(value);
      }
      void operator=(const int intVal){
         m_type=jv_INT;
         m_int_val=intVal;
         m_double_val=(double)m_int_val;
         m_bool_val=m_int_val!=0;
      }
      void operator=(const long longVal){
         m_type=jv_INT;
         m_int_val=longVal;
         m_double_val=(double)m_int_val;
         m_bool_val=m_int_val!=0;
      }
      void operator=(const double doubleVal){
         m_type=jv_DBL;
         m_double_val=doubleVal;
         m_int_val=(long)m_double_val;
         m_bool_val=m_int_val!=0;
      }
      void operator=(const bool boolVal){
         m_type=jv_BOOL;
         m_bool_val=boolVal;
         m_int_val=(long)m_bool_val;
         m_double_val=(double)m_bool_val;
      }
      void operator=(string stringVal){
         m_type=(stringVal!=NULL)?jv_STR:jv_NULL;
         m_string_val=stringVal;
         m_int_val=StringToInteger(m_string_val);
         m_double_val=StringToDouble(m_string_val);
         m_bool_val=stringVal!=NULL;
      }
   
      bool operator==(const int intVal){return m_int_val==intVal;}
      bool operator==(const long longVal){return m_int_val==longVal;}
      bool operator==(const double doubleVal){return m_double_val==doubleVal;}
      bool operator==(const bool boolVal){return m_bool_val==boolVal;}
      bool operator==(string stringVal){return m_string_val==stringVal;}
      
      bool operator!=(const int intVal){return m_int_val!=intVal;}
      bool operator!=(const long longVal){return m_int_val!=longVal;}
      bool operator!=(const double doubleVal){return m_double_val!=doubleVal;}
      bool operator!=(const bool boolVal){return m_bool_val!=boolVal;}
      bool operator!=(string stringVal){return m_string_val!=stringVal;}
   
      long ToInt() const{return m_int_val;}
      double ToDbl() const{return m_double_val;}
      bool ToBool() const{return m_bool_val;}
      string ToStr(){return m_string_val;}
   
      virtual void FromStr(JSONValueType type,string stringVal){
         m_type=type;
         switch(m_type){
         case jv_BOOL:
            m_bool_val=(StringToInteger(stringVal)!=0);
            m_int_val=(long)m_bool_val;
            m_double_val=(double)m_bool_val;
            m_string_val=stringVal;
            break;
         case jv_INT:
            m_int_val=StringToInteger(stringVal);
            m_double_val=(double)m_int_val;
            m_string_val=stringVal;
            m_bool_val=m_int_val!=0;
            break;
         case jv_DBL:
            m_double_val=StringToDouble(stringVal);
            m_int_val=(long)m_double_val;
            m_string_val=stringVal;
            m_bool_val=m_int_val!=0;
            break;
         case jv_STR:
            m_string_val=Unescape(stringVal);
            m_type=(m_string_val!=NULL)?jv_STR:jv_NULL;
            m_int_val=StringToInteger(m_string_val);
            m_double_val=StringToDouble(m_string_val);
            m_bool_val=m_string_val!=NULL;
            break;
         }
      }
      virtual string GetStr(char &jsonArray[],int startIndex,int length){
         #ifdef __MQL4__
               if(length<=0) return "";
         #endif
         char temporaryArray[];
         ArrayCopy(temporaryArray,jsonArray,0,startIndex,length);
         return CharArrayToString(temporaryArray, 0, WHOLE_ARRAY, CJSONValue::code_page);
      }

      virtual void Set(const CJSONValue &value){
         if(m_type==jv_UNDEF) {m_type=jv_OBJ;}
         CopyData(value);
      }
      virtual void Set(const CJSONValue &list[]);
      virtual CJSONValue *Add(const CJSONValue &item){
         if(m_type==jv_UNDEF){m_type=jv_ARRAY;}
         return AddBase(item);
      }
      virtual CJSONValue *Add(const int intVal){
         CJSONValue item(intVal);
         return Add(item);
      }
      virtual CJSONValue *Add(const long longVal){
         CJSONValue item(longVal);
         return Add(item);
      }
      virtual CJSONValue *Add(const double doubleVal){
         CJSONValue item(doubleVal);
         return Add(item);
      }
      virtual CJSONValue *Add(const bool boolVal){
         CJSONValue item(boolVal);
         return Add(item);
      }
      virtual CJSONValue *Add(string stringVal){
         CJSONValue item(jv_STR,stringVal);
         return Add(item);
      }
      virtual CJSONValue *AddBase(const CJSONValue &item){
         int currSize=ArraySize(m_elements);
         ArrayResize(m_elements,currSize+1);
         m_elements[currSize]=item;
         m_elements[currSize].m_parent=GetPointer(this);
         return GetPointer(m_elements[currSize]);
      }
      virtual CJSONValue *New(){
         if(m_type==jv_UNDEF) {m_type=jv_ARRAY;}
         return NewBase();
      }
      virtual CJSONValue *NewBase(){
         int currSize=ArraySize(m_elements);
         ArrayResize(m_elements,currSize+1);
         return GetPointer(m_elements[currSize]);
      }
   
      virtual string    Escape(string value);
      virtual string    Unescape(string value);
   public:
      virtual void      Serialize(string &jsonString,bool format=false,bool includeComma=false);
      virtual string    Serialize(){
         string jsonString;
         Serialize(jsonString);
         return jsonString;
      }
      virtual bool      Deserialize(char &jsonArray[],int length,int &currIndex);
      virtual bool      ExtrStr(char &jsonArray[],int length,int &currIndex);
      virtual bool      Deserialize(string jsonString,int encoding=CP_ACP){
         int currIndex=0;
         Clear();
         CJSONValue::code_page=encoding;
         char charArray[];
         int length=StringToCharArray(jsonString,charArray,0,WHOLE_ARRAY,CJSONValue::code_page);
         return Deserialize(charArray,length,currIndex);
      }
      virtual bool      Deserialize(char &jsonArray[],int encoding=CP_ACP){
         int currIndex=0;
         Clear();
         CJSONValue::code_page=encoding;
         return Deserialize(jsonArray,ArraySize(jsonArray),currIndex);
      }
};

int CJSONValue::code_page=CP_ACP;

//------------------------------------------------------------------ HasKey
CJSONValue *CJSONValue::HasKey(string key,JSONValueType type){
   for(int i=0; i<ArraySize(m_elements); i++) if(m_elements[i].m_key==key){
      if(type==jv_UNDEF || type==m_elements[i].m_type){
         return GetPointer(m_elements[i]);
      }
      break;
   }
   return NULL;
}
//------------------------------------------------------------------ operator[]
CJSONValue *CJSONValue::operator[](string key){
   if(m_type==jv_UNDEF){m_type=jv_OBJ;}
   CJSONValue *value=FindKey(key);
   if(value){return value;}
   CJSONValue newValue(GetPointer(this),jv_UNDEF);
   newValue.m_key=key;
   value=Add(newValue);
   return value;
}
//------------------------------------------------------------------ operator[]
CJSONValue *CJSONValue::operator[](int i){
   if(m_type==jv_UNDEF) m_type=jv_ARRAY;
   while(i>=ArraySize(m_elements)){
      CJSONValue newElement(GetPointer(this),jv_UNDEF);
      if(CheckPointer(Add(newElement))==POINTER_INVALID){return NULL;}
   }
   return GetPointer(m_elements[i]);
}
//------------------------------------------------------------------ Set
void CJSONValue::Set(const CJSONValue &list[]){
   if(m_type==jv_UNDEF){m_type=jv_ARRAY;}
   int elementsSize=ArrayResize(m_elements,ArraySize(list));
   for(int i=0; i<elementsSize; ++i){
      m_elements[i]=list[i];
      m_elements[i].m_parent=GetPointer(this);
   }
}
//------------------------------------------------------------------ Serialize
void CJSONValue::Serialize(string &jsonString,bool key,bool includeComma){
   if(m_type==jv_UNDEF){return;}
   if(includeComma){jsonString+=",";}
   if(key){jsonString+=StringFormat("\"%s\":", m_key);}
   int elementsSize=ArraySize(m_elements);
   switch(m_type){
   case jv_NULL:
      jsonString+="null";
      break;
   case jv_BOOL:
      jsonString+=(m_bool_val?"true":"false");
      break;
   case jv_INT:
      jsonString+=IntegerToString(m_int_val);
      break;
   case jv_DBL:
      jsonString+=DoubleToString(m_double_val);
      break;
   case jv_STR:
   {
      string value=Escape(m_string_val);
      if(StringLen(value)>0){jsonString+=StringFormat("\"%s\"",value);}
      else{jsonString+="null";}
   }
   break;
   case jv_ARRAY:
      jsonString+="[";
      for(int i=0; i<elementsSize; i++){m_elements[i].Serialize(jsonString,false,i>0);}
      jsonString+="]";
      break;
   case jv_OBJ:
      jsonString+="{";
      for(int i=0; i<elementsSize; i++){m_elements[i].Serialize(jsonString,true,i>0);}
      jsonString+="}";
      break;
   }
}
//------------------------------------------------------------------ Deserialize
bool CJSONValue::Deserialize(char &jsonArray[],int length,int &currIndex){
   string validNumberChars="0123456789+-.eE";
   int startIndex=currIndex;
   for(; currIndex<length; currIndex++){
      char currChar=jsonArray[currIndex];
      if(currChar==0){break;}
      switch(currChar){
      case '\t':
      case '\r':
      case '\n':
      case ' ': // skip
         startIndex=currIndex+1;
         break;

      case '[': // the beginning of the object. create an object and take it from js
      {
         startIndex=currIndex+1;
         if(m_type!=jv_UNDEF){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));} // if the value already has a type, then this is an error
            return false;
         }
         m_type=jv_ARRAY; // set the type
         currIndex++;
         CJSONValue val(GetPointer(this),jv_UNDEF);
         while(val.Deserialize(jsonArray,length,currIndex)){
            if(val.m_type!=jv_UNDEF){Add(val);}
            if(val.m_type==jv_INT || val.m_type==jv_DBL || val.m_type==jv_ARRAY){currIndex++;}
            val.Clear();
            val.m_parent=GetPointer(this);
            if(jsonArray[currIndex]==']'){break;}
            currIndex++;
            if(currIndex>=length){
               if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
               return false;
            }
         }
         return (jsonArray[currIndex]==']' || jsonArray[currIndex]==0);
      }
      break;
      case ']':
         if(!m_parent){return false;}
         return (m_parent.m_type==jv_ARRAY); // end of array, current value must be an array

      case ':':
      {
         if(m_lkey==""){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
            return false;
         }
         CJSONValue val(GetPointer(this),jv_UNDEF);
         CJSONValue *oc=Add(val); // object type is not defined yet
         oc.m_key=m_lkey;
         m_lkey=""; // set the key name
         currIndex++;
         if(!oc.Deserialize(jsonArray,length,currIndex)){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
            return false;
         }
         break;
      }
      case ',': // value separator // value type must already be defined
         startIndex=currIndex+1;
         if(!m_parent && m_type!=jv_OBJ){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
            return false;
         }
         else if(m_parent){
            if(m_parent.m_type!=jv_ARRAY && m_parent.m_type!=jv_OBJ){
               if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
               return false;
            }
            if(m_parent.m_type==jv_ARRAY && m_type==jv_UNDEF){return true;}
         }
         break;

      // primitives can ONLY be in an array / or on their own
      case '{': // the beginning of the object. create an object and take it from js
         startIndex=currIndex+1;
         if(m_type!=jv_UNDEF){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // type error
            return false;
         }
         m_type=jv_OBJ; // set type of value
         currIndex++;
         if(!Deserialize(jsonArray,length,currIndex)){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // pull it out
            return false;
         }
         return (jsonArray[currIndex]=='}' || jsonArray[currIndex]==0);
         break;
      case '}':
         return (m_type==jv_OBJ); // end of object, current value must be object

      case 't':
      case 'T': // start true
      case 'f':
      case 'F': // start false
         if(m_type!=jv_UNDEF){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // type error
            return false;
         }
         m_type=jv_BOOL; // set type
         if(currIndex+3<length){
            if(StringCompare(GetStr(jsonArray, currIndex, 4), "true", false)==0){
               m_bool_val=true;
               currIndex+=3;
               return true;
            }
         }
         if(currIndex+4<length){
            if(StringCompare(GetStr(jsonArray, currIndex, 5), "false", false)==0){
               m_bool_val=false;
               currIndex+=4;
               return true;
            }
         }
         if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
         return false; //wrong type or end of line
         break;
      case 'n':
      case 'N': // start null
         if(m_type!=jv_UNDEF){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // type error
            return false;
         }
         m_type=jv_NULL; // set type of value
         if(currIndex+3<length){
            if(StringCompare(GetStr(jsonArray,currIndex,4),"null",false)==0){
               currIndex+=3;
               return true;
            }
         }
         if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
         return false; // not NULL or end of line
         break;

      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '-':
      case '+':
      case '.': // start of number
      {
         if(m_type!=jv_UNDEF){
            if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // type error
            return false;
         }
         bool dbl=false;// set typo of value
         int is=currIndex;
         while(jsonArray[currIndex]!=0 && currIndex<length){
            currIndex++;
            if(StringFind(validNumberChars,GetStr(jsonArray,currIndex,1))<0){break;}
            if(!dbl){dbl=(jsonArray[currIndex]=='.' || jsonArray[currIndex]=='e' || jsonArray[currIndex]=='E');}
         }
         m_string_val=GetStr(jsonArray,is,currIndex-is);
         if(dbl){
            m_type=jv_DBL;
            m_double_val=StringToDouble(m_string_val);
            m_int_val=(long)m_double_val;
            m_bool_val=m_int_val!=0;
         }
         else{
            m_type=jv_INT;   // clarified the value type
            m_int_val=StringToInteger(m_string_val);
            m_double_val=(double)m_int_val;
            m_bool_val=m_int_val!=0;
         }
         currIndex--;
         return true; // moved back a character and exited
         break;
      }
      case '\"': // start or end of line
         if(m_type==jv_OBJ){ // if the type is still undefined and the key is not set
            currIndex++;
            int is=currIndex;
            if(!ExtrStr(jsonArray,length,currIndex)){
               if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // this is the key, go to the end of line
               return false;
            }
            m_lkey=GetStr(jsonArray,is,currIndex-is);
         }
         else{
            if(m_type!=jv_UNDEF){
               if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}   // type error
               return false;
            }
            m_type=jv_STR; // set type of value
            currIndex++;
            int is=currIndex;
            if(!ExtrStr(jsonArray,length,currIndex)){
               if(DEBUG_PRINT){Print(m_key+" "+string(__LINE__));}
               return false;
            }
            FromStr(jv_STR,GetStr(jsonArray,is,currIndex-is));
            return true;
         }
         break;
      }
   }
   return true;
}
//------------------------------------------------------------------ ExtrStr
bool CJSONValue::ExtrStr(char &jsonArray[],int length,int &i){
   for(; jsonArray[i]!=0 && i<length; i++){
      char currChar=jsonArray[i];
      if(currChar=='\"') break; // end if line
      if(currChar=='\\' && i+1<length){
         i++;
         currChar=jsonArray[i];
         switch(currChar){
         case '/':
         case '\\':
         case '\"':
         case 'b':
         case 'f':
         case 'r':
         case 'n':
         case 't':
            break; // allowed
         case 'u': // \uXXXX
         {
            i++;
            for(int j=0; j<4 && i<length && jsonArray[i]!=0; j++,i++){
               if(!((jsonArray[i]>='0' && jsonArray[i]<='9') || (jsonArray[i]>='A' && jsonArray[i]<='F') || (jsonArray[i]>='a' && jsonArray[i]<='f'))){
                  if(DEBUG_PRINT){Print(m_key+" "+CharToString(jsonArray[i])+" "+string(__LINE__));}   // not hex
                  return false;
               }
            }
            i--;
            break;
         }
         default:
            break; /*{ return false; } // unresolved escaped character */
         }
      }
   }
   return true;
}
//------------------------------------------------------------------ Escape
string CJSONValue::Escape(string stringValue){
   ushort inputChars[], escapedChars[];
   int inputLength=StringToShortArray(stringValue, inputChars);
   if(ArrayResize(escapedChars, 2*inputLength)!=2*inputLength){return NULL;}
   int escapedIndex=0;
   for(int i=0; i<inputLength; i++){
      switch(inputChars[i]){
      case '\\':
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         break;
      case '"':
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='"';
         escapedIndex++;
         break;
      case '/':
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='/';
         escapedIndex++;
         break;
      case 8:
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='b';
         escapedIndex++;
         break;
      case 12:
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='f';
         escapedIndex++;
         break;
      case '\n':
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='n';
         escapedIndex++;
         break;
      case '\r':
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='r';
         escapedIndex++;
         break;
      case '\t':
         escapedChars[escapedIndex]='\\';
         escapedIndex++;
         escapedChars[escapedIndex]='t';
         escapedIndex++;
         break;
      default:
         escapedChars[escapedIndex]=inputChars[i];
         escapedIndex++;
         break;
      }
   }
   stringValue=ShortArrayToString(escapedChars,0,escapedIndex);
   return stringValue;
}
//------------------------------------------------------------------ Unescape
string CJSONValue::Unescape(string stringValue){
   ushort inputChars[], unescapedChars[];
   int inputLength=StringToShortArray(stringValue, inputChars);
   if(ArrayResize(unescapedChars, inputLength)!=inputLength){return NULL;}
   int j=0,i=0;
   while(i<inputLength){
      ushort currChar=inputChars[i];
      if(currChar=='\\' && i<inputLength-1){
         switch(inputChars[i+1]){
         case '\\':
            currChar='\\';
            i++;
            break;
         case '"':
            currChar='"';
            i++;
            break;
         case '/':
            currChar='/';
            i++;
            break;
         case 'b':
            currChar=8;
            i++;
            break;
         case 'f':
            currChar=12;
            i++;
            break;
         case 'n':
            currChar='\n';
            i++;
            break;
         case 'r':
            currChar='\r';
            i++;
            break;
         case 't':
            currChar='\t';
            i++;
            break;
         }
      }
      unescapedChars[j]=currChar;
      j++;
      i++;
   }
   stringValue=ShortArrayToString(unescapedChars,0,j);
   return stringValue;
}

//+------------------------------------------------------------------+
//|    KẾT THÚC ĐOẠN CODE JSON (TỪ DÒNG 15 ĐẾN DÒNG 737)             |
//+------------------------------------------------------------------+





#define TELEGRAM_BASE_URL  "https://api.telegram.org"
#define WEB_TIMEOUT        5000
//#define InpToken "7456439661:AAELUurPxI1jloZZl3Rt-zWHRDEvBk2venc"
#define InpToken "7456439661:AAELUurPxI1jloZZl3Rt-zWHRDEvBk2venc"

#include <Trade/Trade.mqh>
#include <Arrays/List.mqh>
#include <Arrays/ArrayString.mqh>


//+------------------------------------------------------------------+
//| Hàm gửi yêu cầu POST và nhận phản hồi                            |
//+------------------------------------------------------------------+
int postRequest(string &response, const string url, const string params,
                const int timeout=5000){
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


// HÀM GIẢI MÃ CHUỖI CHỨA KÝ TỰ ĐÃ MÃ HÓA & UNICODE
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
int getStringReplacement(string &string_var,const int start_pos,const int length,
                    const string replacement){
   string temporaryString=(start_pos==0)?"":StringSubstr(string_var,0,start_pos);
   temporaryString+=replacement;
   temporaryString+=StringSubstr(string_var,start_pos+length);
   string_var=temporaryString;
   return(StringLen(replacement));
}

//+------------------------------------------------------------------+
//|        Function to get the Trimmed Bot's Token                   |
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
//|        Function to get a Trimmed string                          |
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


// HÀM MÃ HÓA CHUỖI ĐỂ DÙNG TRONG URL
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
                const string reply_markup=NULL){
   string output; //--- Biến lưu phản hồi từ request
   string url=TELEGRAM_BASE_URL+"/bot"+getTrimmedToken(InpToken)+"/sendMessage"; //--- Tạo URL cho API Telegram

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


void sendScreenshotToTelegram(const long chat_id,string symbol, ENUM_TIMEFRAMES period,
                    string caption
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
   string URL = TELEGRAM_BASE_URL+"/bot"+InpToken+"/sendPhoto";
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

// ArrayAdd for uchar Array
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
// ArrayAdd for strings
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
}


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
      long              from_id; //--- Stores the sender’s ID.
      string            from_first_name; //--- Stores the sender’s first name.
      string            from_last_name; //--- Stores the sender’s last name.
      string            from_username; //--- Stores the sender’s username.

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
      void Class_Bot_EA();   //--- Khai báo constructor.
      ~Class_Bot_EA(){};    //--- Khai báo destructor.
      int getChatUpdates(); //--- Khai báo hàm lấy cập nhật từ Telegram.
      void ProcessMessages(); //--- Khai báo hàm xử lý các tin nhắn đến.
};


void Class_Bot_EA::Class_Bot_EA(void){ //--- Constructor
   member_token=NULL; //--- Khởi tạo token của bot là NULL.
   member_token=getTrimmedToken(InpToken); //--- Gán token đã loại bỏ khoảng trắng từ InpToken.
   member_name=NULL; //--- Khởi tạo tên bot là NULL.
   member_update_id=0; //--- Khởi tạo update ID cuối cùng là 0.
   member_first_remove=true; //--- Đặt cờ loại bỏ tin nhắn đầu tiên là true.
   member_chats.Clear(); //--- Xóa danh sách các đối tượng chat.
   member_users_filter.Clear(); //--- Xóa mảng lọc người dùng.
}
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
         
         //--- Nếu tin nhắn là "Hello"
         //if(text=="Hello"){
         //   string message="Hello world! You just sent a 'Hello' text to MQL5 and has been processed successfully.";
         //   string buttons_rows = "[[\"Hello 1\",\"Hello 2\",\"Hello 3\"]]";
         //   //--- Gửi tin nhắn phản hồi 
         //   sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(buttons_rows,false,false));
         //   continue;
         //}
                  
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
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MAIN,false,false));
            continue;
         }

         //--- Nếu tin nhắn là "/name" hoặc "Name"
         if (text=="/name" || text=="Name"){
            string message = "Tên file EA mà tôi điều khiển là:\n";
            message += "\xF50B"+__FILE__+" Enjoy.\n";
            sendMessageToTelegram(chat.member_id,message,NULL);
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
            sendMessageToTelegram(chat.member_id,message,NULL);
            continue;
         }

         //--- Nếu tin nhắn là "/quotes" hoặc "Quotes"
         if(text=="/quotes" || text=="Quotes"){
            double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); //--- Lấy giá Ask hiện tại
            double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //--- Lấy giá Bid hiện tại
            string message="\xF170 Ask: "+(string)Ask+"\n";
            message+="\xF171 Bid: "+(string)Bid+"\n";
            
            //--- Gửi tin nhắn phản hồi
            sendMessageToTelegram(chat.member_id,message,NULL);
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
            sendMessageToTelegram(chat.member_id,message,NULL);
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
            sendMessageToTelegram(chat.member_id,message,NULL);
            continue;
         }

         //--- Nếu tin nhắn là "/contact" hoặc "Contact"
         if (text=="/contact" || text=="Contact"){
            string message="Liên hệ nhà phát triển qua link dưới đây:\n";
            message+="https://t.me/Forex_Algo_Trader";
            
            //--- Gửi tin nhắn liên hệ
            sendMessageToTelegram(chat.member_id,message,NULL);
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
            sendMessageToTelegram(chat.member_id,message,NULL);
            continue;
         }

         //--- Nếu tin nhắn là "more" hoặc "More"
         if (text=="more" || text=="More"){
            chat.member_state=1; //--- Cập nhật trạng thái chat để hiển thị thêm tùy chọn
            string message="Chọn thêm tùy chọn bên dưới:";
            
            //--- Gửi tin nhắn kèm bàn phím thêm tùy chọn
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MORE,false,true));
            continue;
         }

         //--- Nếu tin nhắn là emoji mũi tên lên
         if(text==EMOJI_UP){
            chat.member_state=0; //--- Đặt lại trạng thái chat
            string message="Chọn một mục menu:";
            
            //--- Gửi tin nhắn kèm bàn phím chính
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MAIN,false,false));
            continue;
         }

         //--- Nếu tin nhắn là "next" hoặc "Next"
         if(text=="next" || text=="Next"){
            chat.member_state=2; //--- Cập nhật trạng thái chat để hiển thị tùy chọn tiếp theo
            string message="Chọn thêm tùy chọn bên dưới:";
            
            //--- Gửi tin nhắn kèm bàn phím tùy chọn tiếp theo
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_NEXT,false,true));
            continue;
         }

         //--- Nếu tin nhắn là emoji súng lục
         if (text==EMOJI_PISTOL){
            if (chat.member_state==2){
               chat.member_state=1; //--- Chuyển trạng thái để hiển thị thêm tùy chọn
               string message="Chọn thêm tùy chọn bên dưới:";
               
               //--- Gửi tin nhắn kèm bàn phím thêm tùy chọn
               sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MORE,false,true));
            }
            else {
               chat.member_state=0; //--- Đặt lại trạng thái chat
               string message="Chọn một mục menu:";
               
               //--- Gửi tin nhắn kèm bàn phím chính
               sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_MAIN,false,false));
            }
            continue;
         }

         //--- Nếu tin nhắn là emoji hủy
         if (text==EMOJI_CANCEL){
            chat.member_state=0; //--- Đặt lại trạng thái chat
            string message="Chọn /start hoặc /help để bắt đầu.";
            
            //--- Gửi tin nhắn hủy kèm bàn phím ẩn
            sendMessageToTelegram(chat.member_id,message,hideCustomReplyKeyboard());
            continue;
         }

         //--- Nếu tin nhắn là "/screenshot" hoặc "Screenshot"
         static string symbol = _Symbol; //--- Symbol mặc định
         static ENUM_TIMEFRAMES period = _Period; //--- Khung thời gian mặc định
         if (text=="/screenshot" || text=="Screenshot"){
            chat.member_state = 10; //--- Đặt trạng thái yêu cầu chụp màn hình
            string message="Nhập tên symbol, ví dụ 'AUDUSDm'";
            
            //--- Gửi tin nhắn kèm bàn phím chọn symbol
            sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
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
               sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_PERIODS,false,false));
            }
            else {
               string message = "SAI: Symbol không hợp lệ\n";
               message += "Vui lòng nhập đúng tên symbol như 'AUDUSDm' để tiếp tục.";
               
               //--- Gửi tin nhắn báo lỗi kèm bàn phím chọn symbol
               sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_SYMBOLS,false,false));
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
               sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_PERIODS,false,false));
               string caption = "Ảnh chụp Symbol: "+symbol+
                                " ("+EnumToString(ENUM_TIMEFRAMES(period))+
                                ") @ Thời gian: "+TimeToString(TimeCurrent());
               
               //--- Gửi ảnh chụp màn hình lên Telegram
               sendScreenshotToTelegram(chat.member_id,symbol,period,caption);
            }
            else {
               string message = "SAI: Khung thời gian không hợp lệ\n";
               message += "Vui lòng nhập đúng khung thời gian như 'H1' để tiếp tục.";
               
               //--- Gửi tin nhắn báo lỗi kèm bàn phím chọn khung thời gian
               sendMessageToTelegram(chat.member_id,message,customReplyKeyboardMarkup(KEYB_PERIODS,false,false));
            }
            continue;
         }

      }
   }
}






//+------------------------------------------------------------------+
//|                                              Telegram_Bot_EA.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

Class_Bot_EA obj_bot; //--- Create an instance of the Class_Bot_EA class

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   EventSetMillisecondTimer(3000); //--- Set a timer event to trigger every 3000 milliseconds (3 seconds)
   OnTimer(); //--- Call OnTimer() immediately to get the first update
   return(INIT_SUCCEEDED); //--- Return initialization success
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   EventKillTimer(); //--- Kill the timer event to stop further triggering
   ChartRedraw(); //--- Redraw the chart to reflect any changes
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){
   obj_bot.getChatUpdates(); //--- Call the function to get chat updates from Telegram
   obj_bot.ProcessMessages(); //--- Call the function to process incoming messages
}
