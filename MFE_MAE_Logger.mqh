//+------------------------------------------------------------------+
//|  MFE_MAE_Logger.mqh                                              |
//|  Passive MFE / MAE + SL-modification diagnostic logger          |
//|  MQL4 only. Zero impact on trade logic — reads only, writes CSV. |
//|                                                                  |
//|  Outputs two files in MQL4/Files/:                               |
//|    MFE_MAE_TradeLog.csv  — one row per closed trade              |
//|    TrailingStopLog.csv   — one row per SL modification           |
//+------------------------------------------------------------------+
#ifndef MFE_MAE_LOGGER_MQH
#define MFE_MAE_LOGGER_MQH

// Increase if running more than 20 concurrent open positions.
#ifndef ML_MAX_TICKETS
   #define ML_MAX_TICKETS 20
#endif

//+------------------------------------------------------------------+
//| Per-trade tracking record                                        |
//+------------------------------------------------------------------+
struct ML_Record
{
   bool     active;
   int      ticket;
   string   symbol;
   int      orderType;     // OP_BUY or OP_SELL
   datetime openTime;
   double   openPrice;
   double   lots;
   double   slInitial;     // SL at first detection (may be 0 if no SL at open)
   double   tpInitial;     // TP at first detection (may be 0)
   double   ptSize;        // MarketInfo MODE_POINT for this symbol
   double   ptValPerLot;   // USD value of one point per lot
   double   slPts;         // initial SL distance in points (0 = no SL)
   double   slUSD;         // initial risk in USD at full lot size (0 = no SL)
   double   mfePts;        // max favorable excursion, points (always >= 0)
   double   mfeUSD;        // max favorable excursion, USD
   double   maePts;        // max adverse excursion, points (always >= 0)
   double   maeUSD;        // max adverse excursion, USD
};

static ML_Record g_ml_rec[ML_MAX_TICKETS];
static int       g_ml_count    = 0;
static int       g_ml_trade_fh = INVALID_HANDLE;
static int       g_ml_trail_fh = INVALID_HANDLE;
static bool      g_ml_ready    = false;

//+------------------------------------------------------------------+
//| Internal helpers                                                  |
//+------------------------------------------------------------------+

double ML_PointSize(string sym)
{
   return MarketInfo(sym, MODE_POINT);
}

// USD value of a one-point move per lot (works for forex, metals, indices).
double ML_PointValPerLot(string sym)
{
   double tickSz  = MarketInfo(sym, MODE_TICKSIZE);
   double tickVal = MarketInfo(sym, MODE_TICKVALUE);
   double ptSz    = MarketInfo(sym, MODE_POINT);
   if(tickSz < 1e-10) return 0;
   return tickVal * (ptSz / tickSz);
}

string ML_TimeStr(datetime t)
{
   return TimeToString(t, TIME_DATE|TIME_SECONDS);
}

// Returns slot index for a ticket, or -1 if not tracked.
int ML_Find(int ticket)
{
   for(int i = 0; i < g_ml_count; i++)
      if(g_ml_rec[i].active && g_ml_rec[i].ticket == ticket)
         return i;
   return -1;
}

// Allocates a slot (reuses inactive slots first). Returns index or -1 if full.
int ML_Alloc(int ticket)
{
   for(int i = 0; i < g_ml_count; i++)
   {
      if(!g_ml_rec[i].active)
      {
         g_ml_rec[i].ticket = ticket;
         g_ml_rec[i].active = true;
         return i;
      }
   }
   if(g_ml_count >= ML_MAX_TICKETS)
   {
      Print("MFE_MAE_Logger: slot table full (ML_MAX_TICKETS=", ML_MAX_TICKETS,
            "). Increase the constant to track more concurrent positions.");
      return -1;
   }
   g_ml_rec[g_ml_count].ticket = ticket;
   g_ml_rec[g_ml_count].active = true;
   return g_ml_count++;
}

// Populate a record from the currently selected order (call after OrderSelect succeeds).
void ML_TrackNew(int idx)
{
   string sym = OrderSymbol();
   double ptSz  = ML_PointSize(sym);
   double ptVal = ML_PointValPerLot(sym);

   g_ml_rec[idx].symbol      = sym;
   g_ml_rec[idx].orderType   = OrderType();
   g_ml_rec[idx].openTime    = OrderOpenTime();
   g_ml_rec[idx].openPrice   = OrderOpenPrice();
   g_ml_rec[idx].lots        = OrderLots();
   g_ml_rec[idx].slInitial   = OrderStopLoss();
   g_ml_rec[idx].tpInitial   = OrderTakeProfit();
   g_ml_rec[idx].ptSize      = ptSz;
   g_ml_rec[idx].ptValPerLot = ptVal;
   g_ml_rec[idx].mfePts      = 0;
   g_ml_rec[idx].mfeUSD      = 0;
   g_ml_rec[idx].maePts      = 0;
   g_ml_rec[idx].maeUSD      = 0;

   if(OrderStopLoss() > 0 && ptSz > 0)
   {
      g_ml_rec[idx].slPts = MathAbs(OrderOpenPrice() - OrderStopLoss()) / ptSz;
      g_ml_rec[idx].slUSD = g_ml_rec[idx].slPts * ptVal * OrderLots();
   }
   else
   {
      g_ml_rec[idx].slPts = 0;
      g_ml_rec[idx].slUSD = 0;
   }
}

// Update MFE/MAE for one active tracked record.
// Uses both current tick price AND current bar H/L so backtest (Open Prices Only)
// captures intrabar excursions rather than only bar-open prices.
void ML_UpdateRecord(int idx)
{
   bool   isBuy     = (g_ml_rec[idx].orderType == OP_BUY);
   string sym       = g_ml_rec[idx].symbol;
   double openPrice = g_ml_rec[idx].openPrice;
   double ptSz      = g_ml_rec[idx].ptSize;
   double ptVal     = g_ml_rec[idx].ptValPerLot;
   double lots      = g_ml_rec[idx].lots;

   // --- tick-level price (accurate in live; = bar open in Open-Prices-Only tester)
   double tickPrice = isBuy ? MarketInfo(sym, MODE_BID) : MarketInfo(sym, MODE_ASK);

   // --- bar H/L for index 0 (compensates for Open-Prices-Only mode in backtests)
   double barHigh = iHigh(sym, 0, 0);
   double barLow  = iLow(sym, 0, 0);

   // Candidates: current tick, bar high, bar low
   double favPrice, advPrice;
   if(isBuy)
   {
      favPrice = MathMax(tickPrice, barHigh);  // highest reachable this bar
      advPrice = MathMin(tickPrice, barLow);   // lowest reachable this bar
   }
   else
   {
      favPrice = MathMin(tickPrice, barLow);   // lowest = most favourable for sell
      advPrice = MathMax(tickPrice, barHigh);  // highest = most adverse for sell
   }

   // Excursion in points (positive = in-favour, negative = adverse)
   double excFavPts = isBuy ? (favPrice - openPrice) / ptSz
                            : (openPrice - favPrice) / ptSz;
   double excAdvPts = isBuy ? (advPrice - openPrice) / ptSz
                            : (openPrice - advPrice) / ptSz;  // will be <= 0

   if(excFavPts > g_ml_rec[idx].mfePts)
   {
      g_ml_rec[idx].mfePts = excFavPts;
      g_ml_rec[idx].mfeUSD = excFavPts * ptVal * lots;
   }
   if(-excAdvPts > g_ml_rec[idx].maePts)
   {
      g_ml_rec[idx].maePts = -excAdvPts;
      g_ml_rec[idx].maeUSD = -excAdvPts * ptVal * lots;
   }
}

// Classify an exit based on close price vs SL/TP at time of close.
// 'sl' here is the SL stored in the order at closure (may be trailed SL, not original).
string ML_ExitReason(double closePrice, double sl, double tp, bool isBuy, double ptSz)
{
   double tol = 3.0 * ptSz;  // 3-point slippage tolerance
   if(tp > 0 && MathAbs(closePrice - tp) <= tol)  return "TP";
   if(sl > 0 && MathAbs(closePrice - sl) <= tol)  return "SL_OR_TRAIL";
   return "MANUAL_OR_OTHER";
}

// Write one completed trade row to the trade log CSV.
void ML_LogClosed(int idx, double closePrice, datetime closeTime,
                  double profitUSD, double slAtClose, double tpAtClose)
{
   if(g_ml_trade_fh == INVALID_HANDLE) return;

   bool   isBuy  = (g_ml_rec[idx].orderType == OP_BUY);
   string sym    = g_ml_rec[idx].symbol;
   int    digits = (int)MarketInfo(sym, MODE_DIGITS);
   double ptSz   = g_ml_rec[idx].ptSize;
   double ptVal  = g_ml_rec[idx].ptValPerLot;
   double lots   = g_ml_rec[idx].lots;
   double slUSD  = g_ml_rec[idx].slUSD;

   double profitPts = isBuy ? (closePrice - g_ml_rec[idx].openPrice) / ptSz
                            : (g_ml_rec[idx].openPrice - closePrice) / ptSz;

   double rMult = (slUSD > 0) ? profitUSD / slUSD : 0;
   double mfR   = (slUSD > 0) ? g_ml_rec[idx].mfeUSD / slUSD : 0;
   double maR   = (slUSD > 0) ? g_ml_rec[idx].maeUSD / slUSD : 0;

   string exitReason = ML_ExitReason(closePrice, slAtClose, tpAtClose, isBuy, ptSz);

   FileWrite(g_ml_trade_fh,
      IntegerToString(g_ml_rec[idx].ticket),
      sym,
      (isBuy ? "BUY" : "SELL"),
      ML_TimeStr(g_ml_rec[idx].openTime),
      DoubleToString(g_ml_rec[idx].openPrice, digits),
      ML_TimeStr(closeTime),
      DoubleToString(closePrice, digits),
      DoubleToString(lots, 2),
      DoubleToString(g_ml_rec[idx].slInitial, digits),
      DoubleToString(g_ml_rec[idx].tpInitial, digits),
      exitReason,
      DoubleToString(profitUSD, 2),
      DoubleToString(profitPts, 1),
      DoubleToString(rMult, 3),
      DoubleToString(g_ml_rec[idx].mfeUSD, 2),
      DoubleToString(g_ml_rec[idx].mfePts, 1),
      DoubleToString(mfR, 3),
      DoubleToString(g_ml_rec[idx].maeUSD, 2),
      DoubleToString(g_ml_rec[idx].maePts, 1),
      DoubleToString(maR, 3));
   FileFlush(g_ml_trade_fh);
}

// Open a CSV in append mode. Writes header only when the file is newly created.
int ML_OpenCSV(string fileName, string header)
{
   bool isNew = !FileIsExist(fileName);
   int  fh    = FileOpen(fileName, FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_READ, ',');
   if(fh == INVALID_HANDLE)
   {
      Print("MFE_MAE_Logger: cannot open '", fileName, "' err=", GetLastError());
      return INVALID_HANDLE;
   }
   if(isNew)
      FileWrite(fh, header);   // header on first line of new file
   else
      FileSeek(fh, 0, SEEK_END);  // position at end so writes append
   return fh;
}

//+------------------------------------------------------------------+
//| PUBLIC API                                                        |
//+------------------------------------------------------------------+

// Call once inside OnInit().
void MFE_MAE_Init(string tradeLog = "MFE_MAE_TradeLog.csv",
                  string trailLog = "TrailingStopLog.csv")
{
   g_ml_count = 0;
   for(int i = 0; i < ML_MAX_TICKETS; i++)
   {
      g_ml_rec[i].active = false;
      g_ml_rec[i].ticket = 0;
      g_ml_rec[i].mfePts = 0; g_ml_rec[i].mfeUSD = 0;
      g_ml_rec[i].maePts = 0; g_ml_rec[i].maeUSD = 0;
   }

   g_ml_trade_fh = ML_OpenCSV(tradeLog,
      "Ticket,Symbol,Type,OpenTime,OpenPrice,CloseTime,ClosePrice,"
      "Lots,SL_Initial,TP_Initial,ExitReason,"
      "ProfitUSD,ProfitPts,R_Multiple,"
      "MaxFavorableUSD,MaxFavorablePts,MaxFavorable_R,"
      "MaxAdverseUSD,MaxAdversePts,MaxAdverse_R");

   g_ml_trail_fh = ML_OpenCSV(trailLog,
      "Ticket,Timestamp,ModifyType,OldSL,NewSL,CurrentPrice,UnrealizedR_AtMove");

   if(g_ml_trade_fh == INVALID_HANDLE || g_ml_trail_fh == INVALID_HANDLE)
   {
      if(g_ml_trade_fh != INVALID_HANDLE) { FileClose(g_ml_trade_fh); g_ml_trade_fh = INVALID_HANDLE; }
      if(g_ml_trail_fh != INVALID_HANDLE) { FileClose(g_ml_trail_fh); g_ml_trail_fh = INVALID_HANDLE; }
      Print("MFE_MAE_Logger: init failed — logging disabled.");
      return;
   }

   g_ml_ready = true;
   Print("MFE_MAE_Logger: ready. TradeLog=", tradeLog, "  TrailLog=", trailLog);
}

// Call at the TOP of OnTick(), before any EA trade logic.
void MFE_MAE_OnTick()
{
   if(!g_ml_ready) return;

   // 1. Detect trades that have closed since the last tick.
   for(int i = 0; i < g_ml_count; i++)
   {
      if(!g_ml_rec[i].active) continue;
      if(OrderSelect(g_ml_rec[i].ticket, SELECT_BY_TICKET, MODE_TRADES)) continue; // still open

      // No longer in MODE_TRADES — fetch close details from history.
      if(OrderSelect(g_ml_rec[i].ticket, SELECT_BY_TICKET, MODE_HISTORY))
      {
         ML_LogClosed(i,
            OrderClosePrice(),
            OrderCloseTime(),
            OrderProfit() + OrderSwap() + OrderCommission(),
            OrderStopLoss(),      // SL at close (trailed SL if trail was active)
            OrderTakeProfit());
      }
      g_ml_rec[i].active = false;
   }

   // 2. Scan all open market orders; register any not yet tracked.
   //    Handles EA restart mid-session — rediscovers existing open trades.
   //    NOTE: slInitial for rediscovered trades reflects the SL at restart time,
   //    not the original SL at open (MT4 does not store that natively).
   int total = OrdersTotal();
   for(int j = 0; j < total; j++)
   {
      if(!OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;  // skip pending orders

      int ticket = OrderTicket();
      if(ML_Find(ticket) >= 0) continue;  // already tracked

      int idx = ML_Alloc(ticket);
      if(idx < 0) continue;               // slot table full
      ML_TrackNew(idx);
   }

   // 3. Update MFE/MAE for every active open trade.
   for(int k = 0; k < g_ml_count; k++)
      if(g_ml_rec[k].active)
         ML_UpdateRecord(k);
}

// Call this AFTER every successful OrderModify that moves a stop loss.
// modifyType: pass "TRAIL" for trailing stop moves, "BE" for break-even moves.
void MFE_MAE_LogTrailModify(int ticket, double oldSL, double newSL,
                             double currentPrice, string modifyType = "TRAIL")
{
   if(!g_ml_ready || g_ml_trail_fh == INVALID_HANDLE) return;

   // Determine unrealised R at the moment the SL is being moved.
   double unrealizedR = 0;
   int idx = ML_Find(ticket);
   if(idx >= 0 && g_ml_rec[idx].slUSD > 0)
   {
      bool   isBuy     = (g_ml_rec[idx].orderType == OP_BUY);
      double openPrice = g_ml_rec[idx].openPrice;
      double ptSz      = g_ml_rec[idx].ptSize;
      double ptVal     = g_ml_rec[idx].ptValPerLot;
      double lots      = g_ml_rec[idx].lots;
      double excPts    = isBuy ? (currentPrice - openPrice) / ptSz
                               : (openPrice - currentPrice) / ptSz;
      unrealizedR = (excPts * ptVal * lots) / g_ml_rec[idx].slUSD;
   }

   string sym    = (idx >= 0) ? g_ml_rec[idx].symbol : Symbol();
   int    digits = (int)MarketInfo(sym, MODE_DIGITS);

   FileWrite(g_ml_trail_fh,
      IntegerToString(ticket),
      ML_TimeStr(TimeCurrent()),
      modifyType,
      DoubleToString(oldSL, digits),
      DoubleToString(newSL, digits),
      DoubleToString(currentPrice, digits),
      DoubleToString(unrealizedR, 3));
   FileFlush(g_ml_trail_fh);
}

// Call inside OnDeinit().
void MFE_MAE_OnDeinit()
{
   if(g_ml_trade_fh != INVALID_HANDLE) { FileClose(g_ml_trade_fh); g_ml_trade_fh = INVALID_HANDLE; }
   if(g_ml_trail_fh != INVALID_HANDLE) { FileClose(g_ml_trail_fh); g_ml_trail_fh = INVALID_HANDLE; }
   g_ml_ready = false;
}

#endif // MFE_MAE_LOGGER_MQH
