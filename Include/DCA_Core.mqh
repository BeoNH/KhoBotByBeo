//+------------------------------------------------------------------+
//|                                                     DCA_Core.mqh |
//|                                       Copyright 2025, BeoNguyen. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, BeoNguyen."
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Cấu trúc quản lý một chuỗi DCA                                   |
//+------------------------------------------------------------------+
struct DCAChain
{
    ulong initial_ticket;        // Ticket của lệnh gốc
    double initial_price;        // Giá vào của lệnh gốc  
    double initial_volume;       // Khối lượng lệnh gốc
    double initial_tp;           // Take Profit của lệnh gốc
    double initial_sl;           // Stop Loss của lệnh gốc
    int order_count;             // Số lượng lệnh trong chuỗi
    ENUM_ORDER_TYPE order_type;  // Loại lệnh (BUY/SELL)
    double next_entry_price;     // Giá để vào lệnh DCA tiếp theo
    bool is_active;              // Trạng thái hoạt động của chuỗi
};

//+------------------------------------------------------------------+
//| Lớp quản lý DCA chính                                            |
//+------------------------------------------------------------------+
class DCAManager
{
private:
    DCAChain m_chains[];         // Mảng các chuỗi DCA
    CTrade m_trade;              // Đối tượng trade
    int m_chain_count;           // Số lượng chuỗi đang quản lý
    
    // Tham số cấu hình
    string m_bot_name;
    double m_distance_pips;
    double m_volume_multiplier;   
    int m_max_dca_orders;
    double m_takeProfitPips;
    double m_stopLossPips;

public:
    //--- Constructor
    DCAManager() : m_chain_count(0) 
    {
        ArrayResize(m_chains, 0);
        m_trade.SetExpertMagicNumber(0);
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(_Symbol);
        m_trade.SetDeviationInPoints(10);
    }
    
    //--- Khởi tạo tham số
    void Initialize(string i_bot_name, double i_distance_pips, double i_volume_multiplier, int i_max_dca_orders, double i_takeProfitPips, double i_stopLossPips)
    {
        m_bot_name = i_bot_name;
        m_distance_pips = i_distance_pips;
        m_volume_multiplier = i_volume_multiplier;
        m_max_dca_orders = i_max_dca_orders;
        m_takeProfitPips = i_takeProfitPips;
        m_stopLossPips = i_stopLossPips;

        PrintFormat("✅ DCAManager được khởi tạo: Bot=%s, Distance=%d pips, Multiplier=%.2f, MaxOrders=%d",
                    i_bot_name, i_distance_pips, i_volume_multiplier, i_max_dca_orders);
    }
    
    //--- Hàm chính được gọi trong OnTick()
    void OnTick()
    {
        CheckForNewMasterOrders();
        ManageActiveDCAChains();
        CleanupInactiveChains();
    }
    
    //--- Tìm kiếm lệnh gốc mới
    void CheckForNewMasterOrders()
    {
        for(int i = 0; i < PositionsTotal(); i++)
        {    
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            long magic = PositionGetInteger(POSITION_MAGIC);
            string comment = PositionGetString(POSITION_COMMENT);
            
            // Kiểm tra điều kiện lệnh gốc: magic = 0 và comment rỗng hoặc không chứa bot name
            if(magic == 0 && (StringLen(comment) == 0 || StringFind(comment, m_bot_name) == -1))
            {
                // Kiểm tra xem lệnh này đã được quản lý chưa
                if(!IsTicketAlreadyManaged(ticket))
                {
                    CreateNewDCAChain(ticket);
                }
            }
        }
    }
    
    //--- Quản lý các chuỗi DCA đang hoạt động
    void ManageActiveDCAChains()
    {
        for(int i = 0; i < m_chain_count; i++)
        {
            if(!m_chains[i].is_active) continue;
            
            // Kiểm tra xem lệnh gốc còn tồn tại không
            if(!PositionSelectByTicket(m_chains[i].initial_ticket))
            {
                PrintFormat("⚠️ Lệnh gốc #%I64u đã bị đóng. Ngừng quản lý chuỗi DCA.", m_chains[i].initial_ticket);
                CloseAllDCAOrdersOfChain(m_chains[i].initial_ticket);
                m_chains[i].is_active = false;
                continue;
            }
            
            CheckForNewDCAEntry(i);
        }
    }
    
    //--- Kiểm tra điều kiện vào lệnh DCA mới
    void CheckForNewDCAEntry(int chain_index)
    {
        if(chain_index >= m_chain_count) return;
        
        DCAChain chain = m_chains[chain_index];
        
        // Kiểm tra giới hạn số lệnh DCA
        if(chain.order_count >= m_max_dca_orders + 1) return;
        
        // Lấy giá hiện tại
        MqlTick tick;
        if(!SymbolInfoTick(_Symbol, tick)) return;
        
        double current_price = (chain.order_type == ORDER_TYPE_BUY) ? tick.ask : tick.bid;
        
        // Tính toán giá vào lệnh DCA tiếp theo nếu chưa có
        if(chain.next_entry_price == 0)
        {
            CalculateNextEntryPrice(chain_index);
        }
        
        // Kiểm tra điều kiện giá
        bool should_enter = false;
        if(chain.order_type == ORDER_TYPE_BUY && current_price <= chain.next_entry_price)
            should_enter = true;
        else if(chain.order_type == ORDER_TYPE_SELL && current_price >= chain.next_entry_price)
            should_enter = true;
            
        if(should_enter)
        {
            PlaceNewDCAOrder(chain_index);
        }
    }
    
    //--- Tính toán giá vào lệnh DCA tiếp theo
    void CalculateNextEntryPrice(int chain_index)
    {
        if(chain_index >= m_chain_count) return;
        
        DCAChain chain = m_chains[chain_index];
        
        double distance_points = m_distance_pips * _Point * chain.order_count;
        if(chain.order_type == ORDER_TYPE_BUY)
        {
            chain.next_entry_price = chain.initial_price - distance_points;
        }
        else
        {
            chain.next_entry_price = chain.initial_price + distance_points;
        }
    }
    
    //--- Đặt lệnh DCA mới
    void PlaceNewDCAOrder(int chain_index)
    {
        if(chain_index >= m_chain_count) return;
        
        DCAChain chain = m_chains[chain_index];
        
        // Tính khối lượng lệnh mới        
        double new_volume = NormalizeDouble(chain.initial_volume * MathPow(m_volume_multiplier, chain.order_count), 2);
        
        // Chuẩn bị tham số lệnh
        ENUM_ORDER_TYPE order_type = chain.order_type;
        double price = (order_type == ORDER_TYPE_BUY) ? 
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                        SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        string comment = StringFormat("%s - L%d", m_bot_name, chain.order_count);
        
        // Đặt lệnh với magic number = initial_ticket
        m_trade.SetExpertMagicNumber(chain.initial_ticket);
        
        bool result = false;
        if(order_type == ORDER_TYPE_BUY)
        {
            result = m_trade.Buy(new_volume, _Symbol, price, chain.initial_sl, chain.initial_tp, comment);
        }
        else
        {
            result = m_trade.Sell(new_volume, _Symbol, price, chain.initial_sl, chain.initial_tp, comment);
        }
        
        if(result)
        {
            chain.order_count++;
            chain.next_entry_price = 0;
            
            PrintFormat("✅ Đã đặt lệnh DCA #%d cho chuỗi #%I64u: Volume=%.2f, Price=%.5f", 
                        chain.order_count, chain.initial_ticket, new_volume, price);
        }
        else
        {
            PrintFormat("❌ Lỗi đặt lệnh DCA cho chuỗi #%I64u: %s", 
                        chain.initial_ticket, m_trade.ResultComment());  
        }
    }
    
    //--- Tạo chuỗi DCA mới
    void CreateNewDCAChain(ulong ticket)
    {
        if(!PositionSelectByTicket(ticket)) return;
        
        // Thêm vào mảng quản lý
        ArrayResize(m_chains, m_chain_count + 1);

        // tính TP và SL
        double current_tp = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                        PositionGetDouble(POSITION_PRICE_OPEN) + m_takeProfitPips: 
                        PositionGetDouble(POSITION_PRICE_OPEN) - m_takeProfitPips;
        double current_sl = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                        PositionGetDouble(POSITION_PRICE_OPEN) - (m_stopLossPips + m_distance_pips * m_max_dca_orders):
                        PositionGetDouble(POSITION_PRICE_OPEN) + (m_stopLossPips + m_distance_pips * m_max_dca_orders);
        m_trade.PositionModify(ticket, current_sl, current_tp);
        
        DCAChain new_chain = m_chains[m_chain_count];
        new_chain.initial_ticket = ticket;
        new_chain.initial_price = PositionGetDouble(POSITION_PRICE_OPEN);
        new_chain.initial_volume = PositionGetDouble(POSITION_VOLUME);
        new_chain.initial_tp = current_tp;
        new_chain.initial_sl = current_sl;
        new_chain.order_count = 1;
        new_chain.order_type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        new_chain.next_entry_price = 0;
        new_chain.is_active = true;
        
        m_chains[m_chain_count] = new_chain;
        m_chain_count++;
        
        PrintFormat("🎯 Đã nhận quản lý lệnh gốc #%I64u: %s, Price=%.5f", 
                    ticket, 
                    (new_chain.order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL",
                    new_chain.initial_price);
    }

    //--- Đóng tất cả lệnh DCA của chuỗi
    void CloseAllDCAOrdersOfChain(ulong magicNumber)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong magic = PositionGetInteger(POSITION_MAGIC);
            ulong ticket = PositionGetInteger(POSITION_TICKET);

            if(magic == magicNumber)
            {
                m_trade.PositionClose(ticket);
            }
        }
    }
    
    //--- Kiểm tra bộ lệnh đã được quản lý
    bool IsTicketAlreadyManaged(ulong ticket)
    {
        for(int i = 0; i < m_chain_count; i++)
        {
            if(m_chains[i].initial_ticket == ticket)
                return true;
        }
        return false;
    }
    
    //--- Dọn dẹp các chuỗi không hoạt động
    void CleanupInactiveChains()
    {
        // Dọn dẹp các chuỗi không hoạt động để tiết kiệm bộ nhớ
        for(int i = m_chain_count - 1; i >= 0; i--)
        {
            if(!m_chains[i].is_active)
            {
                // Xóa phần tử khỏi mảng
                for(int j = i; j < m_chain_count - 1; j++)
                {
                    m_chains[j] = m_chains[j + 1];
                }
                ArrayResize(m_chains, m_chain_count - 1);
                m_chain_count--;
            }
        }
    }
    
    //--- Thông tin debug
    void PrintStatus()
    {
        PrintFormat("📈 DCA Manager Status: Đang quản lý %d chuỗi DCA", m_chain_count);
        for(int i = 0; i < m_chain_count; i++)
        {
            if(!m_chains[i].is_active) continue;
            
            PrintFormat("   Chuỗi #%I64u: %s, Orders=%d, Next Entry=%.5f", 
                        m_chains[i].initial_ticket,
                        (m_chains[i].order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL",
                        m_chains[i].order_count,
                        m_chains[i].next_entry_price);
        }
    }
    
    int GetActiveChainCount() { return m_chain_count; }
};