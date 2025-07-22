//+------------------------------------------------------------------+
//|                                                   TradeUtils.mqh |
//|                                       Copyright 2025, BeoNguyen. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, BeoNguyen."
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>

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
    request.symbol   = symbol;
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