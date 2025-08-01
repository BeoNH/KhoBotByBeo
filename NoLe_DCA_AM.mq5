//+------------------------------------------------------------------+
//|                                                  DCA_Master_EA.mq5 |
//|                EA DCA nâng cao - Nhận nuôi lệnh thủ công            |
//|                                       Copyright 2025, BeoNguyen.   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, BeoNguyen."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "EA DCA tự động nhận nuôi các lệnh thủ công và tạo chuỗi DCA"

// Include các file cần thiết
#include "Include/TradeUtils.mqh"
#include "Include/DCA_Core.mqh"

//+------------------------------------------------------------------+
//| Tham số đầu vào                                                  |
//+------------------------------------------------------------------+
input group "=== Cài đặt DCA ==="
input string bot_name = "NoLe1_DCA";         // Tên bot
input double distance_pips = 0.8;            // Khoảng cách giữa các lệnh (pips)
input double volume_multiplier = 1.4;        // Hệ số nhân khối lượng
input int max_dca_orders = 10;               // Số lượng lệnh tối đa (không tính lệnh gốc)
input double takeProfitPips = 3.5;           // TP nhóm (từ L0)
input double stopLossPips = 2.5;             // SL nhóm (từ L-cuối)

input group "=== Cài đặt khác ==="
input bool enable_info_panel = true;               // Hiển thị panel thông tin
input bool enable_debug_log = false;               // Bật log debug chi tiết
input int status_update_seconds = 10;              // Cập nhật status sau X giây

//+------------------------------------------------------------------+
//| Biến toàn cục                                                    |
//+------------------------------------------------------------------+
DCAManager * g_dca_manager;                         // Đối tượng quản lý DCA chính
datetime g_last_status_update = 0;                 // Thời gian cập nhật status cuối
int g_last_chain_count = 0;                       // Số chuỗi DCA lần kiểm tra trước

//+------------------------------------------------------------------+
//| Hàm khởi tạo EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
{   
   // Khởi tạo DCA Manager
   g_dca_manager = new DCAManager();
   if(g_dca_manager == NULL)
   {
      MessageBox("❌ Không thể khởi tạo DCA Manager!");
      return INIT_FAILED;
   }
   
   // Cấu hình DCA Manager
   g_dca_manager.Initialize(bot_name, distance_pips, volume_multiplier, max_dca_orders, takeProfitPips, stopLossPips);
   
   // Tạo giao diện nếu được bật
   if(enable_info_panel)
   {
      CreateInfoPanel();
   }
   
   // Log khởi tạo thành công
   PrintFormat("✅ %s EA đã khởi tạo thành công trên %s", bot_name, _Symbol);
   PrintFormat("   📊 Multiplier: %.2f | Max DCA: %d", 
                  volume_multiplier, max_dca_orders);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Hàm dọn dẹp khi tắt EA                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Xóa DCA Manager
   if(g_dca_manager != NULL)
   {
      delete g_dca_manager;
      g_dca_manager = NULL;
   }
   
   // Xóa các đối tượng giao diện
   if(enable_info_panel)
   {
      RemoveInfoPanel();
   }
   
   PrintFormat("🔄 %s EA đã được dừng. Lý do: %s", bot_name, GetDeinitReasonText(reason));
}

//+------------------------------------------------------------------+
//| Hàm sự kiện mỗi tick - Logic chính                               |
//+------------------------------------------------------------------+
void OnTick()
{
   // Kiểm tra DCA Manager
   if(g_dca_manager == NULL) return;
   
   // Chạy logic DCA chính
   g_dca_manager.OnTick();
   
   // Cập nhật thông tin định kỳ
   if(enable_info_panel && TimeCurrent() - g_last_status_update >= status_update_seconds)
   {
      UpdateInfoPanel();
      g_last_status_update = TimeCurrent();
   }
   
   // Debug log định kỳ
   if(enable_debug_log)
   {
      int current_chains = g_dca_manager.GetActiveChainCount();
      if(current_chains != g_last_chain_count)
      {
         g_dca_manager.PrintStatus();
         g_last_chain_count = current_chains;
      }
   }
}

//+------------------------------------------------------------------+
//| Xử lý sự kiện trên biểu đồ                                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Nút debug positions
      // if(sparam == "btn_debug_positions")
      // {
      //       DebugPrintAllPositions();
      //       ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      // }
   }
}

//+------------------------------------------------------------------+
//| Tạo panel thông tin                                              |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
   int y_start = 30;
   int line_height = 20;
   int y = y_start;
   
   // Tiêu đề
   CreateLabel("lbl_title", StringFormat("%s - DCA Manager", bot_name), 10, y, clrLime, 12, true);
   y += line_height + 5;
   
   // Thông tin cơ bản
   CreateLabel("lbl_symbol", "Symbol: " + _Symbol, 10, y, clrWhite, 9); y += line_height;
   CreateLabel("lbl_distance", "Distance: " + DoubleToString(distance_pips*100, 0) + " pips", 10, y, clrWhite, 9); y += line_height;
   CreateLabel("lbl_multiplier", "Multiplier: " + DoubleToString(volume_multiplier, 2), 10, y, clrWhite, 9); y += line_height;
   CreateLabel("lbl_max_dca", "Max DCA: " + IntegerToString(max_dca_orders), 10, y, clrWhite, 9); y += line_height;
   
   y += 10;
   
   // Trạng thái hoạt động
   CreateLabel("lbl_status_title", "=== Trạng thái ===", 10, y, clrYellow, 10, true); y += line_height;
   CreateLabel("lbl_active_chains", "Chuỗi DCA: 0", 10, y, clrWhite, 9); y += line_height;
   
   y += 10;
   
   // Nút debug
   // CreateButton("btn_debug_positions", "Debug Positions", 10, y, 150, 25); y += 30;
   // CreateButton("btn_dca_status", "DCA Status", 10, y, 150, 25);
}

//+------------------------------------------------------------------+
//| Cập nhật panel thông tin                                         |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
   if(g_dca_manager == NULL) return;
   
   int active_chains = g_dca_manager.GetActiveChainCount();
   
   ObjectSetString(0, "lbl_active_chains", OBJPROP_TEXT, "Chuỗi DCA: " + IntegerToString(active_chains));
   ObjectSetString(0, "lbl_last_update", OBJPROP_TEXT, "Cập nhật: " + TimeToString(TimeCurrent(), TIME_SECONDS));
   
   // Đổi màu dựa trên trạng thái
   color chain_color = (active_chains > 0) ? clrLime : clrSilver;
   ObjectSetInteger(0, "lbl_active_chains", OBJPROP_COLOR, chain_color);
}

//+------------------------------------------------------------------+
//| Xóa panel thông tin                                              |
//+------------------------------------------------------------------+
void RemoveInfoPanel()
{
   ObjectDelete(0, "lbl_title");
   ObjectDelete(0, "lbl_symbol");
   ObjectDelete(0, "lbl_distance");
   ObjectDelete(0, "lbl_multiplier");
   ObjectDelete(0, "lbl_max_dca");
   ObjectDelete(0, "lbl_status_title");
   ObjectDelete(0, "lbl_active_chains");
   ObjectDelete(0, "lbl_last_update");
   ObjectDelete(0, "btn_debug_positions");
   ObjectDelete(0, "btn_dca_status");
}

//+------------------------------------------------------------------+
//| Tạo label text                                                   |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr = clrWhite, int font_size = 9, bool bold = false)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
}

//+------------------------------------------------------------------+
//| Tạo button                                                       |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width = 100, int height = 20)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrSilver);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Lấy text mô tả lý do deinit                                     |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM: return "EA được dừng thủ công";
      case REASON_REMOVE: return "EA bị xóa khỏi biểu đồ";
      case REASON_RECOMPILE: return "EA được compile lại";
      case REASON_CHARTCHANGE: return "Thay đổi symbol hoặc timeframe";
      case REASON_CHARTCLOSE: return "Biểu đồ bị đóng";
      case REASON_PARAMETERS: return "Thay đổi tham số đầu vào";
      case REASON_ACCOUNT: return "Thay đổi tài khoản";
      case REASON_TEMPLATE: return "Template mới được áp dụng";
      case REASON_INITFAILED: return "OnInit() trả về lỗi";
      case REASON_CLOSE: return "Terminal đóng";
      default: return "Lý do không xác định";
   }
}