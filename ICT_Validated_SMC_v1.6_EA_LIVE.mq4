//+------------------------------------------------------------------+
//|                         ICT_Validated_SMC_v1.6_EA_LIVE.mq4       |
//|         Port of ICT Validated SMC v1.6 (Pine Script)             |
//|         Authoritative reference: ICT_Validated_SMC_v1.6.pine       |
//|         LIVE build: drawing, alerts, signals, trade management   |
//|         v1.93: DebugCooldownRejects diagnostic logging only      |
//|         v1.94: IC Markets seasonal GMT+2/+3 auto-offset for      |
//|         killzone/NY-time conversion (BarTimeToUtc). No signal/   |
//|         scoring/cooldown logic changed.                          |
//+------------------------------------------------------------------+
#property copyright "ICT Validated SMC v1.6 EA LIVE"
#property link      ""
#property version   "1.94"
#property strict

//--- array capacity (Pine caps referenced in comments)
#define MAX_SWINGS          100
#define MAX_INTERNAL_SWINGS 80
#define MAX_STRUCTURE_BREAKS 50
#define MAX_OBS             30
#define MAX_FVGS             30
#define MAX_IFVGS            20
#define MAX_OTES             15
#define MAX_BREAKERS         20
#define MAX_BPRS             10
#define MAX_IDMS             20
#define MAX_SWP_DRAWS        50
#define MAX_SIG_DRAWS        50

#define BRK_NONE 0
#define BRK_BOS  1
#define BRK_CHOCH 2

#define PFX "ICTV_"

#ifndef ANCHOR_UPPER_LEFT
   #define ANCHOR_UPPER_LEFT 0
#endif
#ifndef ANCHOR_LOWER_LEFT
   #define ANCHOR_LOWER_LEFT 0
#endif
#ifndef ANCHOR_UPPER
   #define ANCHOR_UPPER 0
#endif
#ifndef ANCHOR_LOWER
   #define ANCHOR_LOWER 0
#endif
#ifndef ANCHOR_LEFT
   #define ANCHOR_LEFT 0
#endif

enum ENUM_DRAWING_MODE
  {
   DM_OFF     = 0,  // no chart objects
   DM_MINIMAL = 1,  // signals, SL/TP, structure breaks only
   DM_FULL    = 2   // all zone drawings
  };

enum ENUM_PANEL_LAYOUT
  {
   PL_COMPACT = 0,  // single-line rows + dark background (default)
   PL_PINE    = 1   // two-column Pine v1.6 table
  };

#define PANEL_ROWS       31
#define COMPACT_PANEL_ROWS 10

//+------------------------------------------------------------------+
//| INPUTS �" Market Structure (Pine: structGroup)                    |
//+------------------------------------------------------------------+
input string   S1_Structure           = "=== MARKET STRUCTURE ===";
input int      SwingLength            = 10;    // Pine: swingLen
input int      InternalLength         = 5;     // Pine: internalLen
input bool     ShowSwings             = true;  // Pine: showSwings (display only)
input bool     ShowStructure          = true;  // Pine: showStructure (display only)
input bool     ShowInternalStructure  = false;// Pine: showInternalStructure
input bool     RequireBodyClose       = false; // Pine: requireBodyClose

//+------------------------------------------------------------------+
//| INPUTS �" Higher Timeframe (Pine: htfGroup)                       |
//+------------------------------------------------------------------+
input string   S2_HTF                 = "=== HIGHER TIMEFRAME ===";
input bool     UseHTF                 = true;
input ENUM_TIMEFRAMES HTFTimeframe    = PERIOD_H4;  // Pine: htfTimeframe default "240"
input int      HTFSwingLength         = 10;
input bool     ShowHTFStructure       = true;  // display only

//+------------------------------------------------------------------+
//| INPUTS �" Order Blocks (Pine: obGroup)                            |
//+------------------------------------------------------------------+
input string   S3_OB                  = "=== ORDER BLOCKS ===";
input bool     ShowOB                 = true;
input int      OBMaxCount             = 5;
input bool     RequireSweep           = true;
input bool     RequireDisplacement    = true;
input bool     ShowMitigatedOB        = false; // Pine: showMitigated

//+------------------------------------------------------------------+
//| INPUTS �" Breaker Blocks (Pine: brkGroup)                         |
//+------------------------------------------------------------------+
input string   S3b_Breakers           = "=== BREAKER BLOCKS ===";
input bool     ShowBreakers           = true;
input int      BreakerMaxCount        = 5;

//+------------------------------------------------------------------+
//| INPUTS �" Fair Value Gaps (Pine: fvgGroup)                        |
//+------------------------------------------------------------------+
input string   S4_FVG                 = "=== FAIR VALUE GAPS ===";
input bool     ShowFVG                = true;
input int      FVGMaxCount            = 5;
input double   FVGMinATRMult          = 1.0;
input bool     ShowCE                 = true;   // display only
input bool     ShowMitigatedFVG       = false;
input bool     ShowIFVG               = true;
input int      IFVGScorePoints        = 1;     // reserved for signal phase

//+------------------------------------------------------------------+
//| INPUTS �" Balanced Price Range (Pine: bprGroup)                   |
//+------------------------------------------------------------------+
input string   S4c_BPR                = "=== BALANCED PRICE RANGE ===";
input bool     ShowBPR                = true;

//+------------------------------------------------------------------+
//| INPUTS �" Liquidity (Pine: liqGroup)                              |
//+------------------------------------------------------------------+
input string   S4b_Liq                = "=== LIQUIDITY ===";
input bool     ShowLiquidity          = true;
input bool     ShowEQHL               = true;
input double   EQTolerancePct         = 0.15;  // Pine: eqTolerance
input bool     ShowSweeps             = true;
input bool     SweepRequireWickReject = false;

//+------------------------------------------------------------------+
//| INPUTS �" Inducement / IDM (Pine: idmGroup)                       |
//+------------------------------------------------------------------+
input string   S4d_IDM                = "=== INDUCEMENT (IDM) ===";
input bool     ShowIDM                = true;
input int      IDMMaxCount            = 5;

//+------------------------------------------------------------------+
//| INPUTS �" Premium / Discount (Pine: pdGroup)                      |
//+------------------------------------------------------------------+
input string   S5_PD                  = "=== PREMIUM / DISCOUNT ===";
input bool     ShowPD                 = true;    // display only
input bool     ShowEQ                 = true;    // display only

//+------------------------------------------------------------------+
//| INPUTS �" Session Levels (Pine: slGroup)                          |
//+------------------------------------------------------------------+
input string   S6_Session             = "=== SESSION LEVELS ===";
input bool     ShowSessionLevels      = true;
input bool     ShowPDHL               = true;
input bool     ShowPWHL               = true;

//+------------------------------------------------------------------+
//| INPUTS - Killzones (Pine: kzGroup "Killzones & Time")            |
//+------------------------------------------------------------------+
input string   S7_KZ                  = "=== Killzones & Time ===";
input bool     ShowKZ                 = true;    // Show Killzones
input bool     UseICMarketsAutoOffset = true;    // auto GMT+2/+3 per IC Markets DST calendar
input int      BrokerGMTOffset        = 0;       // manual hrs when UseICMarketsAutoOffset=false; 0=TimeGMT delta
input bool     UseAutoNYDST           = true;    // Pine: hour(time, "America/New_York") auto DST
input int      NYUTCOffsetHours       = 4;       // Manual NY UTC offset when UseAutoNYDST=false
input bool     KZAsian                = false;   // Pine: kzAsian default false
input bool     KZLondon               = true;    // Pine: kzLondon default true
input bool     KZNYAM                 = true;    // Pine: kzNYAM default true
input bool     KZNYPM                 = false;   // Pine: kzNYPM default false
input int      KZTransparency         = 92;      // Pine: kzTransparency default 92

//+------------------------------------------------------------------+
//| INPUTS �" OTE (Pine: oteGroup)                                    |
//+------------------------------------------------------------------+
input string   S8_OTE                 = "=== OTE ===";
input bool     ShowOTE                = true;
input double   OTEFibHigh             = 0.786;
input double   OTEFibLow              = 0.618;
input bool     ShowOTEFibs            = true;    // display only
input int      OTEMaxCount            = 3;

//+------------------------------------------------------------------+
//| INPUTS �" Signal Generation (Pine: sigGroup)                      |
//+------------------------------------------------------------------+
input string   S9_Signals             = "=== SIGNAL GENERATION ===";
input bool     EnableSignals          = true;
input int      MinSignalScore         = 4;       // Pine: minSigScore (max 8 in v1.6)
input bool     RequireHTFAlign        = true;   // Pine: requireHTFAlign (default true)
input bool     RequireKillzone        = false;  // Pine: requireKZActive
input bool     RequireCISD            = false;
input bool     ShowSigSL              = true;    // display only
input bool     ShowSigTP              = true;    // display only
input int      SignalCooldownBars     = 10;     // Pine: sigCooldown (default 10)
input bool     PineExactSignals       = true;   // v1.6 SL/TP: no buffer, no RR fallback, allow na TP

//+------------------------------------------------------------------+
//| INPUTS �" Confluence Scoring (Pine: confGroup)                    |
//+------------------------------------------------------------------+
input string   S10_Confluence         = "=== CONFLUENCE SCORING ===";
input bool     ShowConfluence         = true;    // display only
input int      MinOBDisplayScore      = 3;       // Pine: minScore

//+------------------------------------------------------------------+
//| INPUTS �" EA runtime                                              |
//+------------------------------------------------------------------+
input string   S11_Runtime            = "=== EA RUNTIME ===";
input int      BootstrapMaxBars       = 0;       // 0 = full history
input bool     DebugStructure         = true;    // log BOS/CHoCH on Experts tab
input bool     DebugZones             = false;   // log OB/FVG/IFVG/Breaker/BPR events
input bool     DebugZoneAudit         = false;   // on attach: dump all zones for TV parity compare
input bool     DebugLogClosedBars     = false;   // log each closed bar L/S score state
input bool     DebugCooldownRejects   = false;   // log signals that clear score/HTF but fail cooldown
input bool     DebugNews              = false;   // log news fetch/parse diagnostics

//+------------------------------------------------------------------+
//| INPUTS �" Chart display & alerts                                  |
//+------------------------------------------------------------------+
input string   S11b_Display           = "=== CHART DISPLAY & ALERTS ===";
input bool     ShowChartDrawings      = true;    // master switch for all ObjectCreate
input ENUM_DRAWING_MODE DrawingMode   = DM_MINIMAL;
input bool     ShowInfoPanel          = true;    // chart panel (top-left)
input ENUM_PANEL_LAYOUT PanelLayout   = PL_PINE;    // Compact = dark bg rows; Pine = 2-col table
input bool     CompactPanel           = false;   // Comment() one-liner (overrides panel layout)
input bool     EnableAlerts           = true;    // MT4 Alert() popup
input bool     EnablePushNotify       = false;   // SendNotification() to mobile
input bool     AlertPartialClose      = false;  // alert/push when a partial close fires (P1 or P2)
input bool     ShowDailyPnL           = true;   // show today's realised+floating P&L and CB headroom on panel
input bool     ShowMultiPairInfo      = false;  // show total open positions across all symbols with this MagicNumber

//+------------------------------------------------------------------+
//| INPUTS �" Trade execution (EA)                                    |
//+------------------------------------------------------------------+
input string   S12_Trade              = "=== TRADE EXECUTION ===";
input bool     EnableTrading          = true;   // Kill-switch: false = signals only, no orders
input bool     AllowLong              = true;
input bool     AllowShort             = true;
input double   LotSize                = 0.02;
input bool     UseRiskPercent         = false;
input double   RiskPercent            = 1.0;   // % of balance risked per trade
input int      MagicNumber            = 20260615;
input int      MaxSpreadPoints        = 50;    // 0 = disabled
input int      Slippage               = 30;
input bool     ECNMode                = false;  // IC Markets Raw/ECN: sends order without SL/TP then attaches them via OrderModify immediately after
input int      MaxPositionsPerDirection = 1;    // max open trades per direction (0 = unlimited)
input bool     UseSignalSLTP          = true;
input double   SLBufferPoints         = 0;       // 0 = Pine exact SL; >0 widens SL away from entry
input bool     RequireTP              = false;   // Pine fires signal even when TP is na
input double   FallbackTP_RR          = 2.0;   // if no swing TP beyond entry
input bool     UseBreakEven           = false;
input double   BreakEvenTriggerPts    = 150;   // profit points before BE
input double   BreakEvenLockPts       = 10;    // SL locked this many points above/below entry
input bool     UseTrailingStop        = false;
input double   TrailingStartPts       = 200;   // profit points before trail activates
input double   TrailingDistancePts    = 100;   // trail distance behind price
input double   TrailingStepPts        = 20;    // min SL move increment

//+------------------------------------------------------------------+
//| INPUTS � News filter                                             |
//+------------------------------------------------------------------+
input string   S13_News               = "=== NEWS FILTER ===";
input bool     UseNewsFilter          = false;  // master switch � enable when live trading
input bool     BlockRedNews           = true;   // block entries during high-impact news (red � NFP, FOMC, CPI etc.)
input bool     BlockOrangeNews        = false;  // block entries during medium-impact news (orange)
input int      NewsMinutesBefore      = 15;     // halt new entries this many minutes before the event
input int      NewsMinutesAfter       = 15;     // keep entries halted this many minutes after the event
input bool     NewsCloseOpenTrades    = false;  // keep false � existing trades run to their own SL/TP; only new entries are blocked during news
input bool     NewsOnlyUSD            = true;   // XAUUSD: filter USD news only (ignore non-USD events)
input string   NewsCalendarURL        = "https://nfs.faireconomy.media/ff_calendar_thisweek.xml";
input int      NewsRefreshMinutes     = 60;     // re-download the calendar this often (minutes)

//+------------------------------------------------------------------+
//| INPUTS � Risk circuit-breaker                                    |
//+------------------------------------------------------------------+
input string   S14_Risk               = "=== RISK CIRCUIT-BREAKER ===";
input bool     UseCircuitBreaker      = false;   // master switch � enable when live trading
input bool     CB_UsePercentOfBal     = true;    // true = % of day-start balance; false = money
input double   CB_MaxDailyLossPct     = 4.5;     // FTMO: 5% daily limit; 4.5% gives safety margin
input double   CB_MaxDailyLossMoney   = 0;       // used when CB_UsePercentOfBal=false (account currency)
input bool     CB_UseEquityStop       = true;    // halt on floating equity drawdown too
input double   CB_EquityStopPct       = 4.5;     // halt if equity drops 4.5% from day-start balance
input bool     CB_FlattenOnTrip       = false;   // keep false � existing trades run to their own SL/TP; only new entries are blocked
input bool     CB_HaltUntilNextDay    = true;    // stay halted rest of broker day
input double   CB_MaxTotalLossPct     = 9.0;     // halt permanently if equity drops this % from EA-start balance (0 = disabled); FTMO max drawdown is 10%, 9% gives safety margin
input bool     CB_ResetInitialBalance = false;   // set true once to reset the total-DD baseline to current balance (e.g. starting a new challenge phase), then set back to false

//+------------------------------------------------------------------+
//| INPUTS � Trading hours (broker server time, NOT NY)              |
//+------------------------------------------------------------------+
input string   S15_Hours              = "=== TRADING HOURS (broker time) ===";
input bool     UseTradingHours        = false;    // master switch for the time-window gate
input string   TH_Monday              = "8-22";  // empty = no trading that day; "8-10,14:30-15:30"
input string   TH_Tuesday             = "8-22";
input string   TH_Wednesday           = "8-22";
input string   TH_Thursday            = "8-22";
input string   TH_Friday              = "8-22";
input string   TH_Saturday            = "";      // empty = closed
input string   TH_Sunday              = "";      // empty = closed
input bool     UseEODFlatten          = false;   // master switch for end-of-day flatten+stop
input string   EODFlattenTime         = "22:30"; // broker time; flatten + optional entry block after
input bool     EODBlockAfterFlatten   = true;    // after EOD time, also block new entries till next day

//+------------------------------------------------------------------+
//| INPUTS � Advanced exits (R-multiple BE / partials)               |
//+------------------------------------------------------------------+
input string   S16_Exits              = "=== ADVANCED EXITS (BE / PARTIALS) ===";
input bool     UseRMultipleBE         = true;  // move SL to BE at an R multiple (separate from points BE)
input double   BE_AtR                 = 1.0;    // move to BE when profit >= this * R
input double   BE_LockR               = 0.0;    // lock this * R beyond entry (0 = exact BE)
input bool     UsePartialClose        = true;  // master switch for partial scaling
input double   Partial1_AtR           = 1.0;    // take first partial at this * R
input double   Partial1_Pct           = 50;     // % of CURRENT position lots to close at target 1
input bool     Partial1_ThenBE        = true;   // after partial 1, move remainder SL to break-even
input double   Partial2_AtR           = 2.0;    // take second partial at this * R (0 = disabled)
input double   Partial2_Pct           = 50;     // % of remaining lots to close at target 2
input double   MinPartialLots         = 0.01;   // never close/leave a remainder below broker minlot

//+------------------------------------------------------------------+
//| INPUTS - Trade Journal                                           |
//+------------------------------------------------------------------+
input string   S17_Journal            = "=== TRADE JOURNAL ===";
input bool     UseTradeJournal        = false;  // log each closed trade to CSV in MQL4/Files/
input string   JournalFileName        = "ICT_SMC_Journal.csv";

//+------------------------------------------------------------------+
//| STRUCTS �" Pine type equivalents                                  |
//+------------------------------------------------------------------+
struct SMC_Swing
  {
   datetime     time;
   double       price;
   bool         isHigh;
   int          barIdx;     // Pine Swing.idx / bar_index at pivot bar
   int          drawId;
  };

struct SMC_StructureBreak
  {
   datetime     time;
   double       price;
   int          breakType;   // BRK_BOS / BRK_CHOCH
   bool         isBullish;
   string       level;       // "swing" or "internal"
   bool         hasDisplacement;
   int          drawId;
  };

struct SMC_OrderBlock
  {
   datetime     time;
   datetime     endTime;
   double       top;
   double       bottom;
   bool         bullish;
   bool         hasSweep;
   bool         hasDisplacement;
   bool         mitigated;
   int          score;
   bool         inKillzone;
   bool         inCorrectZone;
   int          drawId;
  };

struct SMC_Breaker
  {
   datetime     originTime;
   datetime     createdTime;  // audit / display
   int          formedBarIdx; // g_barCounter at creation (Pine createdIdx / bar_index)
   double       top;
   double       bottom;
   bool         bullish;
   int          origScore;
   bool         retested;
   bool         mitigated;
   int          drawId;
  };

struct SMC_OTE
  {
   datetime     time;
   double       legHigh;
   double       legLow;
   double       zoneTop;
   double       zoneBottom;
   double       fib50;
   bool         bullish;
   bool         triggered;
   bool         invalidated;
   bool         hasOBOverlap;
   bool         hasFVGOverlap;
   int          drawId;
  };

struct SMC_FVG
  {
   datetime     time;
   double       top;
   double       bottom;
   bool         bullish;
   double       displacementATR;
   bool         mitigated;
   bool         inKillzone;
   int          drawId;
  };

struct SMC_IFVG
  {
   datetime     time;
   int          formedBarIdx; // g_barCounter at spawn (Pine idx / bar_index)
   double       top;
   double       bottom;
   bool         bullish;
   bool         retested;
   bool         mitigated;
   int          drawId;
  };

struct SMC_BPR
  {
   datetime     time;
   double       top;
   double       bottom;
   bool         mitigated;
   int          drawId;
  };

struct SMC_Inducement
  {
   datetime     time;
   double       price;
   bool         bullish;
   bool         triggered;
   datetime     triggerTime;
   int          triggerBar;   // g_barCounter at sweep (20-bar expiry)
   bool         expired;
   int          drawId;
  };

//+------------------------------------------------------------------+
//| GLOBALS �" swing structure state (Pine v1.6)                      |
//+------------------------------------------------------------------+
SMC_Swing           g_swings[MAX_SWINGS];
int                 g_swingCount = 0;

SMC_Swing           g_internalSwings[MAX_INTERNAL_SWINGS];
int                 g_internalSwingCount = 0;

SMC_StructureBreak  g_structureBreaks[MAX_STRUCTURE_BREAKS];
int                 g_structureBreakCount = 0;

SMC_StructureBreak  g_internalBreaks[MAX_STRUCTURE_BREAKS];
int                 g_internalBreakCount = 0;

// Zone arrays �" dynamic (ArrayResize), trimmed to Pine input caps
SMC_OrderBlock      g_obs[];
int                 g_obCount = 0;
SMC_FVG             g_fvgs[];
int                 g_fvgCount = 0;
SMC_IFVG            g_ifvgs[];
int                 g_ifvgCount = 0;
SMC_OTE             g_otes[];
int                 g_oteCount = 0;
SMC_Breaker         g_breakers[];
int                 g_breakerCount = 0;
SMC_BPR             g_bprs[];
int                 g_bprCount = 0;
SMC_Inducement      g_idms[];
int                 g_idmCount = 0;

// Swing structure (v1.6 real-time model)
bool                g_swingBullish = true;
double              g_lastSwingHigh = 0;
double              g_lastSwingLow = 0;
datetime            g_lastSwingHighTime = 0;
datetime            g_lastSwingLowTime = 0;
bool                g_swingHighBroken = false;
bool                g_swingLowBroken = false;

// Internal structure (v1.6 real-time model)
bool                g_internalBullish = true;
double              g_lastInternalHigh = 0;
double              g_lastInternalLow = 0;
datetime            g_lastInternalHighTime = 0;
datetime            g_lastInternalLowTime = 0;
bool                g_internalHighBroken = false;
bool                g_internalLowBroken = false;

// HTF structure (v1.6 real-time �" direct iHigh/iLow/iClose on HTFTimeframe)
bool                g_htfBullish = true;
double              g_htfLastHigh = 0;
double              g_htfLastLow = 0;
datetime            g_htfLastHighTime = 0;
datetime            g_htfLastLowTime = 0;
bool                g_htfHighBroken = false;
bool                g_htfLowBroken = false;
string              g_htfLastBreakStr = "---";
datetime            g_htfLastProcessedBarTime = 0;
int                 g_htfLastProcessedShift = -1;

// Premium / discount + session levels
double              g_pdHigh = 0, g_pdLow = 0;
double              g_pwHigh = 0, g_pwLow = 0;
double              g_pdEquilibrium = 0;
string              g_pdZoneStr = "---";
string              g_kzSessionStr = "Off-Session";
bool                g_inKillzoneNow = false;

// Runtime
datetime            g_lastBarTime = 0;
int                 g_barCounter = 0;
string              g_lastSwingBreakStr = "---";
string              g_lastInternalBreakStr = "---";

// CISD state
double              g_lastBearishOpen = 0;
double              g_lastBullishOpen = 0;
bool                g_hasBearishOpen = false;
bool                g_hasBullishOpen = false;

// Signal / trade state
int                 g_lastLongShift = -1;
int                 g_lastShortShift = -1;
int                 g_lastLongBarCounter = -1000000;
int                 g_lastShortBarCounter = -1000000;
string              g_lastSignalDir = "NONE";
double              g_lastSignalSL = 0;
double              g_lastSignalTP = 0;
int                 g_lastSignalScore = 0;
int                 g_lastSignalShift = -1;
int                 g_lastSignalBarCounter = -1;
int                 g_lastDiagLongScore = 0;
int                 g_lastDiagShortScore = 0;

// Drawing + alerts
int                 g_drawCounter = 0;
int                 g_eqDrawCount = 0;
int                 g_swpDrawSeq = 0;
int                 g_swpDrawIds[MAX_SWP_DRAWS];
int                 g_swpDrawIdCount = 0;
int                 g_sigDrawSeq = 0;
int                 g_sigDrawIds[MAX_SIG_DRAWS];
int                 g_sigDrawIdCount = 0;
int                 g_alertBarBullCHOCH = -1;
int                 g_alertBarBearCHOCH = -1;
int                 g_alertBarBullBOS = -1;
int                 g_alertBarBearBOS = -1;
int                 g_alertBarBullOB = -1;
int                 g_alertBarBearOB = -1;
int                 g_alertBarHiBullOB = -1;
int                 g_alertBarHiBearOB = -1;
int                 g_alertBarBullBrk = -1;
int                 g_alertBarBearBrk = -1;
int                 g_alertBarIDM = -1;
int                 g_alertBarBullIFVG = -1;
int                 g_alertBarBearIFVG = -1;
int                 g_alertBarLongSig = -1;
int                 g_alertBarShortSig = -1;
bool                g_lastBullOBThisBar = false;
bool                g_lastBearOBThisBar = false;
int                 g_lastBullOBScore = 0;
int                 g_lastBearOBScore = 0;
bool                g_bootstrapping = false;

// News filter (no persistent block flag � blackout derived live each call)
struct NewsEvent
  {
   datetime     t;
   int          impact;   // 2=High, 1=Medium
   string       ccy;
  };

NewsEvent           g_newsEvents[];
int                 g_newsEventCount = 0;
datetime            g_newsLastFetch  = 0;

// Circuit-breaker (day-start re-baselines on broker day rollover and on mid-day attach)
double              g_cbDayStartBalance = 0;
string              g_cbCurrentDay      = "";
bool                g_cbTrippedToday    = false;
double              g_cbCachedRealizedPnL = 0;
int                 g_cbLastHistTotal     = -1;
string              g_cbCachedDay         = "";
double              g_cbInitialBalance    = 0;    // balance at EA attach � baseline for total drawdown check
bool                g_cbTotalTripped      = false; // latched permanently when CB_MaxTotalLossPct is breached; re-attach EA to reset
int                 g_journalLastHistTotal = -1;  // trade journal: history count at last scan

// Trading hours � EOD flatten throttle only (broker server time via TimeCurrent())
string              g_thEodFlattenedDay = "";

// Advanced exits � partial state (MQL4 OrderModify cannot update comment after partial close)
struct PartialState
  {
   int      ticket;
   double   sl0;
   double   lots0;
   bool     p1Done;
   bool     p2Done;
  };

PartialState        g_partials[];
int                 g_partialCount = 0;

//+------------------------------------------------------------------+
//| Utility                                                          |
//+------------------------------------------------------------------+
string TimeframeToString(int tf)
  {
   switch(tf)
     {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
      default:         return(IntegerToString(tf));
     }
  }

string PanelHTFLabel(int tf)
  {
   if(tf == PERIOD_D1)  return("1D");
   if(tf == PERIOD_W1)  return("1W");
   if(tf == PERIOD_MN1) return("1M");
   return(TimeframeToString(tf));
  }

string BreakTypeToString(int t)
  {
   if(t == BRK_BOS)  return("BOS");
   if(t == BRK_CHOCH) return("CHoCH");
   return("none");
  }

bool IsNewBar()
  {
   datetime t = iTime(Symbol(), Period(), 0);
   if(t == g_lastBarTime)
      return(false);
   g_lastBarTime = t;
   return(true);
  }

// Pine panel KZ uses hour(time, "America/New_York") on the chart bar � not wall clock
datetime ChartBarTime()
  {
   return(iTime(Symbol(), Period(), 0));
  }

// Pine bar_index: g_barCounter = forming bar (bars 0..g_barCounter-1 closed)
int PineBarIndex()
  {
   return(g_barCounter);
  }

// Pine bar_index of the bar just processed in ProcessClosedBar (confirmed close)
int ClosedBarPineIndex()
  {
   return(g_barCounter - 1);
  }

// Moment after chart bar `shift` closes (= open of shift-1); matches Pine barstate.isconfirmed
datetime ClosedBarAsOf(int shift)
  {
   if(shift > 0)
      return(iTime(Symbol(), Period(), shift - 1));
   return(ChartBarTime());
  }

// Pine request.security on slow charts: HTF confirms through TimeCurrent(), not chart bar 0 open
datetime HTFSyncAsOf(datetime chartCloseAsOf)
  {
   if(g_bootstrapping)
      return(chartCloseAsOf);
   return(TimeCurrent());
  }

int TfPeriodSeconds(ENUM_TIMEFRAMES tf)
  {
   if(tf == PERIOD_M1)   return(60);
   if(tf == PERIOD_M5)   return(300);
   if(tf == PERIOD_M15)  return(900);
   if(tf == PERIOD_M30)  return(1800);
   if(tf == PERIOD_H1)   return(3600);
   if(tf == PERIOD_H4)   return(14400);
   if(tf == PERIOD_D1)   return(86400);
   if(tf == PERIOD_W1)   return(604800);
   if(tf == PERIOD_MN1)  return(2592000);
   return((int)tf * 60);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| CHART DRAWING & ALERTS (ported from ICT_Validated_SMC_Indicator) |
//+------------------------------------------------------------------+
int ChartPeriodSeconds()
  { return(TfPeriodSeconds((ENUM_TIMEFRAMES)Period())); }

bool DrawingsEnabled()
  { return(!g_bootstrapping && ShowChartDrawings && DrawingMode != DM_OFF); }

bool DrawingsFull()
  { return(!g_bootstrapping && ShowChartDrawings && DrawingMode == DM_FULL); }

bool DrawingsMinimalOrFull()
  { return(!g_bootstrapping && ShowChartDrawings && DrawingMode != DM_OFF); }

int NextDrawId()
  { return(++g_drawCounter); }

void DelObj(string name)
  { if(ObjectFind(0, name) >= 0) ObjectDelete(0, name); }

void DelPrefix(string pfx)
  {
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
     {
      string nm = ObjectName(i);
      if(StringFind(nm, pfx, 0) == 0)
         ObjectDelete(nm);
     }
  }

void DelDrawPair(string pfx, int drawId)
  {
   DelObj(pfx + IntegerToString(drawId));
  }

datetime FutureTime(int barsAhead)
  { return(iTime(Symbol(), Period(), 0) + barsAhead * ChartPeriodSeconds()); }

void DrawRect(string name, datetime t1, double top,
              datetime t2, double bottom,
              color col, bool back, bool dashed)
  {
   if(!DrawingsEnabled()) return;
   DelObj(name);
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, top, t2, bottom);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FILL, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_STYLE, dashed ? STYLE_DASH : STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
  }

void SetRectRight(string name, datetime t2)
  {
   if(ObjectFind(0, name) >= 0)
      ObjectMove(0, name, 1, t2, ObjectGetDouble(0, name, OBJPROP_PRICE2, 0));
  }

void DrawLine(string name, datetime t1, double p1,
              datetime t2, double p2,
              color col, int width, bool dashed, bool rayRight)
  {
   if(!DrawingsEnabled()) return;
   DelObj(name);
   ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, dashed ? STYLE_DASH : STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, rayRight);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
  }

void DrawHorizLine(string name, datetime t1, datetime t2, double price,
                   color col, int width, bool dashed, bool rayRight)
  { DrawLine(name, t1, price, t2, price, col, width, dashed, rayRight); }

void DrawText(string name, datetime t, double price,
              string txt, color col, int sz, int anchor)
  {
   if(!DrawingsEnabled()) return;
   DelObj(name);
   ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, sz);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
  }

void PanelCell(string name, int x, int y, int corner, int anchor,
               string txt, color col, int sz)
  {
   if(!ShowInfoPanel || CompactPanel) return;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, sz);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
  }

void PanelRow(int row, int xL, int xR, int y0, int dy, int corner, int fsz,
              string lbl, string val, color lblCol, color valCol)
  {
   int y = y0 + row * dy;
   PanelCell(PFX + "PNL_L_" + IntegerToString(row), xL, y, corner,
             ANCHOR_LEFT_UPPER, lbl, lblCol, fsz);
   if(val != "")
      PanelCell(PFX + "PNL_R_" + IntegerToString(row), xR, y, corner,
                ANCHOR_RIGHT_UPPER, val, valCol, fsz);
   else
      DelObj(PFX + "PNL_R_" + IntegerToString(row));
  }

void PanelLabel(string name, int x, int y, int corner,
                string txt, color col, int sz)
  {
   PanelCell(name, x, y, corner,
             corner == CORNER_LEFT_UPPER ? ANCHOR_LEFT_UPPER : ANCHOR_RIGHT_UPPER,
             txt, col, sz);
  }

void PanelBackground(int x, int y, int w, int h, int corner)
  {
   if(!ShowInfoPanel || CompactPanel) return;
   string name = PFX + "PNL_BG";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'0,0,0');
   ObjectSetInteger(0, name, OBJPROP_COLOR, C'40,40,40');
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
  }

void FireAlertOnce(int &lastBarTracker, string msg)
  {
   if(lastBarTracker == g_barCounter) return;
   lastBarTracker = g_barCounter;
   if(g_bootstrapping) return;
   if(EnableAlerts && !IsTesting()) Alert(msg);
   if(EnablePushNotify && !IsTesting()) SendNotification(msg);
  }

void FireStructureAlert(bool isBull, int brkType)
  {
   string msg;
   if(brkType == BRK_CHOCH)
      msg = isBull ? "ICT-V: Bullish Change of Character detected"
                   : "ICT-V: Bearish Change of Character detected";
   else
      msg = isBull ? "ICT-V: Bullish Break of Structure"
                   : "ICT-V: Bearish Break of Structure";
   if(brkType == BRK_CHOCH)
     {
      if(isBull) FireAlertOnce(g_alertBarBullCHOCH, msg);
      else       FireAlertOnce(g_alertBarBearCHOCH, msg);
     }
   else
     {
      if(isBull) FireAlertOnce(g_alertBarBullBOS, msg);
      else       FireAlertOnce(g_alertBarBearBOS, msg);
     }
  }

void DrawSwingMark(SMC_Swing &sw)
  {
   if(!DrawingsFull() || !ShowSwings) return;
   string nm = PFX + "SW_" + IntegerToString(sw.drawId);
   double offset = GetATR(0) * 0.5;
   DrawText(nm, sw.time,
            sw.isHigh ? sw.price + offset : sw.price - offset,
            sw.isHigh ? "v" : "^",
            sw.isHigh ? clrTomato : clrLimeGreen, 9,
            sw.isHigh ? ANCHOR_UPPER : ANCHOR_LOWER);
  }

void DrawOB(SMC_OrderBlock &ob)
  {
   if(!DrawingsFull() || !ShowOB) return;
   string nm  = PFX + "OB_"  + IntegerToString(ob.drawId);
   string nml = PFX + "OBL_" + IntegerToString(ob.drawId);
   datetime t2 = FutureTime(30);
   color col = ob.mitigated ? clrSilver : (ob.bullish ? clrCornflowerBlue : clrOrange);
   if(ob.mitigated && !ShowMitigatedOB) { DelObj(nm); DelObj(nml); return; }
   DrawRect(nm, ob.time, ob.top, t2, ob.bottom, col, true, false);
   int stars = ob.score >= 7 ? 5 : ob.score >= 5 ? 4 : ob.score >= 4 ? 3 : ob.score >= 3 ? 2 : 1;
   string ss = "";
   for(int i = 0; i < stars; i++) ss += "*";
   DrawText(nml, ob.time, ob.bullish ? ob.bottom - GetATR(0)*0.3 : ob.top + GetATR(0)*0.3,
            (ob.bullish ? "BullOB " : "BearOB ") + ss + " [" + IntegerToString(ob.score) + "]",
            col, 7, ob.bullish ? ANCHOR_UPPER_LEFT : ANCHOR_LOWER_LEFT);
  }

void RemoveOBDraw(int drawId)
  {
   DelObj(PFX + "OB_"  + IntegerToString(drawId));
   DelObj(PFX + "OBL_" + IntegerToString(drawId));
  }

void DrawFVGZone(SMC_FVG &f)
  {
   if(!DrawingsFull() || !ShowFVG) return;
   string nm   = PFX + "FVG_"   + IntegerToString(f.drawId);
   string nmce = PFX + "FVGCE_" + IntegerToString(f.drawId);
   datetime t2 = FutureTime(30);
   color col = f.mitigated ? clrSilver : (f.bullish ? clrMediumSeaGreen : clrCrimson);
   if(f.mitigated && !ShowMitigatedFVG) { DelObj(nm); DelObj(nmce); return; }
   DrawRect(nm, f.time, f.top, t2, f.bottom, col, true, false);
   if(ShowCE && !f.mitigated)
     {
      double ce = (f.top + f.bottom) / 2.0;
      DrawHorizLine(nmce, f.time, t2, ce, col, 1, true, false);
     }
  }

void DrawIFVGZone(SMC_IFVG &iv)
  {
   if(!DrawingsFull() || !ShowIFVG) return;
   string nm  = PFX + "IFVG_"  + IntegerToString(iv.drawId);
   string nml = PFX + "IFVGL_" + IntegerToString(iv.drawId);
   if(iv.mitigated) { DelObj(nm); DelObj(nml); return; }
   datetime t2 = FutureTime(30);
   DrawRect(nm, iv.time, iv.top, t2, iv.bottom, clrGold, true, true);
   DrawText(nml, iv.time, iv.bullish ? iv.bottom - GetATR(0)*0.2 : iv.top + GetATR(0)*0.2,
            iv.bullish ? "IFVG ^" : "IFVG v", clrGold, 7,
            iv.bullish ? ANCHOR_UPPER_LEFT : ANCHOR_LOWER_LEFT);
  }

void DrawBPRZone(SMC_BPR &bp)
  {
   if(!DrawingsFull() || !ShowBPR) return;
   string nm  = PFX + "BPR_"  + IntegerToString(bp.drawId);
   string nml = PFX + "BPRL_" + IntegerToString(bp.drawId);
   if(bp.mitigated) { DelObj(nm); DelObj(nml); return; }
   datetime t2 = FutureTime(30);
   DrawRect(nm, bp.time, bp.top, t2, bp.bottom, clrOrchid, true, false);
   DrawText(nml, bp.time, bp.top + GetATR(0)*0.2, "BPR", clrOrchid, 7, ANCHOR_LOWER_LEFT);
  }

void DrawBreakerZone(SMC_Breaker &b)
  {
   if(!DrawingsFull() || !ShowBreakers) return;
   string nm  = PFX + "BRK_"  + IntegerToString(b.drawId);
   string nml = PFX + "BRKL_" + IntegerToString(b.drawId);
   if(b.mitigated) { DelObj(nm); DelObj(nml); return; }
   datetime t2 = FutureTime(30);
   color col = b.bullish ? clrSpringGreen : clrDarkOrange;
   datetime t1 = b.createdTime > 0 ? b.createdTime : b.originTime;
   DrawRect(nm, t1, b.top, t2, b.bottom, col, true, true);
   DrawText(nml, b.createdTime > 0 ? b.createdTime : b.originTime,
            b.bullish ? b.bottom - GetATR(0)*0.3 : b.top + GetATR(0)*0.3,
            b.bullish ? "BRK ^" : "BRK v", col, 7,
            b.bullish ? ANCHOR_UPPER_LEFT : ANCHOR_LOWER_LEFT);
  }

void DrawOTEZone(SMC_OTE &ote)
  {
   if(!DrawingsFull() || !ShowOTE) return;
   string nm  = PFX + "OTE_"  + IntegerToString(ote.drawId);
   string nml = PFX + "OTEL_" + IntegerToString(ote.drawId);
   string f50 = PFX + "OTEF50_" + IntegerToString(ote.drawId);
   if(ote.invalidated) { DelObj(nm); DelObj(nml); DelObj(f50); return; }
   datetime t2 = FutureTime(30);
   color col = ote.bullish ? clrCyan : clrMediumOrchid;
   string lbl = "OTE";
   if(ote.hasOBOverlap && ote.hasFVGOverlap) lbl = "OTE + OB + FVG";
   else if(ote.hasOBOverlap) lbl = "OTE + OB";
   else if(ote.hasFVGOverlap) lbl = "OTE + FVG";
   DrawRect(nm, ote.time, ote.zoneTop, t2, ote.zoneBottom, col, true, true);
   if(ShowOTEFibs)
      DrawHorizLine(f50, ote.time, t2, ote.fib50, col, 1, true, false);
   DrawText(nml, ote.time, ote.bullish ? ote.zoneBottom - GetATR(0)*0.3 : ote.zoneTop + GetATR(0)*0.3,
            lbl, col, 7, ote.bullish ? ANCHOR_UPPER_LEFT : ANCHOR_LOWER_LEFT);
  }

void DrawStructureMark(SMC_StructureBreak &sb)
  {
   if(!DrawingsMinimalOrFull() || !ShowStructure) return;
   if(DrawingMode == DM_MINIMAL || DrawingMode == DM_FULL)
     {
      string nm  = PFX + "SB_"  + IntegerToString(sb.drawId);
      string nml = PFX + "SBL_" + IntegerToString(sb.drawId);
      color col = sb.isBullish ? clrLimeGreen : clrRed;
      datetime t1 = sb.time - 30 * ChartPeriodSeconds();
      bool isBOS = (sb.breakType == BRK_BOS);
      DrawLine(nm, t1, sb.price, sb.time, sb.price, col, 1, !isBOS, false);
      string lbl = BreakTypeToString(sb.breakType) + (sb.isBullish ? " ^" : " v");
      DrawText(nml, sb.time, sb.price, lbl, col, 8, ANCHOR_LEFT);
     }
  }

void DrawIDMMark(SMC_Inducement &idm)
  {
   if(!DrawingsFull() || !ShowIDM) return;
   string nm  = PFX + "IDM_"  + IntegerToString(idm.drawId);
   string nml = PFX + "IDML_" + IntegerToString(idm.drawId);
   color col = idm.triggered ? clrOrangeRed : clrDarkOrange;
   datetime t2 = idm.triggered ? idm.triggerTime + 5 * ChartPeriodSeconds() : FutureTime(15);
   DrawHorizLine(nm, idm.time, t2, idm.price, col, 1, true, false);
   DrawText(nml, idm.time, idm.price, idm.triggered ? "IDM!" : "IDM", col, 7,
            idm.bullish ? ANCHOR_UPPER_LEFT : ANCHOR_LOWER_LEFT);
  }

void DrawSessionLevelsChart()
  {
   if(!DrawingsFull()) return;
   datetime t1 = iTime(Symbol(), Period(), 0) - 60 * ChartPeriodSeconds();
   datetime t2 = FutureTime(20);
   if((ShowSessionLevels || ShowPDHL) && g_pdHigh > 0)
     {
      DrawHorizLine(PFX + "PDH", t1, t2, g_pdHigh, clrDodgerBlue, 1, true, false);
      DrawText(PFX + "PDHL", t2, g_pdHigh, "PDH", clrDodgerBlue, 7, ANCHOR_LEFT);
      DrawHorizLine(PFX + "PDL", t1, t2, g_pdLow, clrDodgerBlue, 1, true, false);
      DrawText(PFX + "PDLL", t2, g_pdLow, "PDL", clrDodgerBlue, 7, ANCHOR_LEFT);
     }
   if((ShowSessionLevels || ShowPWHL) && g_pwHigh > 0)
     {
      DrawHorizLine(PFX + "PWH", t1, t2, g_pwHigh, clrOrchid, 2, true, false);
      DrawText(PFX + "PWHL", t2, g_pwHigh, "PWH", clrOrchid, 7, ANCHOR_LEFT);
      DrawHorizLine(PFX + "PWL", t1, t2, g_pwLow, clrOrchid, 2, true, false);
      DrawText(PFX + "PWLL", t2, g_pwLow, "PWL", clrOrchid, 7, ANCHOR_LEFT);
     }
  }

void DrawHTFLevelsChart()
  {
   if(!DrawingsFull() || !UseHTF || !ShowHTFStructure) return;
   if(g_htfLastHigh <= 0 || g_htfLastLow <= 0) return;
   datetime t1 = iTime(Symbol(), Period(), 0) - 60 * ChartPeriodSeconds();
   datetime t2 = FutureTime(15);
   DrawHorizLine(PFX + "HTFH", t1, t2, g_htfLastHigh, clrCrimson, 2, true, false);
   DrawText(PFX + "HTFHL", t2, g_htfLastHigh, "HTF High", clrCrimson, 7, ANCHOR_LEFT);
   DrawHorizLine(PFX + "HTFL", t1, t2, g_htfLastLow, clrLimeGreen, 2, true, false);
   DrawText(PFX + "HTFLL", t2, g_htfLastLow, "HTF Low", clrLimeGreen, 7, ANCHOR_LEFT);
  }

void DrawPDZonesChart()
  {
   if(!DrawingsFull() || !ShowPD || g_lastSwingHigh <= 0 || g_lastSwingLow <= 0) return;
   double eq = (g_lastSwingHigh + g_lastSwingLow) / 2.0;
   datetime t1 = iTime(Symbol(), Period(), 0) - 40 * ChartPeriodSeconds();
   datetime t2 = FutureTime(10);
   DrawRect(PFX + "PD_PREM", t1, g_lastSwingHigh, t2, eq, clrPaleVioletRed, true, false);
   DrawRect(PFX + "PD_DISC", t1, eq, t2, g_lastSwingLow, clrMediumSeaGreen, true, false);
   if(ShowEQ)
     {
      DrawHorizLine(PFX + "PD_EQ", t1, t2, eq, clrSilver, 1, true, false);
      DrawText(PFX + "PD_EQL", t2, eq, "EQ", clrSilver, 7, ANCHOR_LEFT);
     }
  }

void CapEQDrawings()
  {
   while(g_eqDrawCount > 20)
     {
      DelObj(PFX + "EQH_" + IntegerToString(g_eqDrawCount));
      DelObj(PFX + "EQHL_" + IntegerToString(g_eqDrawCount));
      DelObj(PFX + "EQL_" + IntegerToString(g_eqDrawCount));
      DelObj(PFX + "EQLL_" + IntegerToString(g_eqDrawCount));
      g_eqDrawCount--;
     }
  }

void DrawEQHLChart(int shift)
  {
   if(!DrawingsFull() || !ShowLiquidity || !ShowEQHL || g_swingCount < 4) return;
   int sz = g_swingCount;
   int minI = MathMax(sz - 8, 1);
   for(int i = sz - 1; i >= minI; i--)
     {
      if(g_swings[i].isHigh)
        {
         for(int j = i - 1; j >= MathMax(i - 6, 0); j--)
           {
            if(g_swings[j].isHigh && g_swings[j].time != g_swings[i].time)
              {
               double pct = MathAbs(g_swings[i].price - g_swings[j].price) / g_swings[i].price * 100.0;
               if(pct <= EQTolerancePct && g_swings[i].time == iTime(Symbol(), Period(), shift + SwingLength))
                 {
                  g_eqDrawCount++;
                  CapEQDrawings();
                  string nm  = PFX + "EQH_" + IntegerToString(g_eqDrawCount);
                  string nml = PFX + "EQHL_" + IntegerToString(g_eqDrawCount);
                  DrawHorizLine(nm, g_swings[j].time, FutureTime(10), g_swings[j].price, clrGold, 1, true, false);
                  DrawText(nml, FutureTime(10), g_swings[j].price, "EQH", clrGold, 7, ANCHOR_LEFT);
                 }
               break;
              }
           }
        }
      else
        {
         for(int j = i - 1; j >= MathMax(i - 6, 0); j--)
           {
            if(!g_swings[j].isHigh && g_swings[j].time != g_swings[i].time)
              {
               double pct = MathAbs(g_swings[i].price - g_swings[j].price) / g_swings[i].price * 100.0;
               if(pct <= EQTolerancePct && g_swings[i].time == iTime(Symbol(), Period(), shift + SwingLength))
                 {
                  g_eqDrawCount++;
                  CapEQDrawings();
                  string nm  = PFX + "EQL_" + IntegerToString(g_eqDrawCount);
                  string nml = PFX + "EQLL_" + IntegerToString(g_eqDrawCount);
                  DrawHorizLine(nm, g_swings[j].time, FutureTime(10), g_swings[j].price, clrGold, 1, true, false);
                  DrawText(nml, FutureTime(10), g_swings[j].price, "EQL", clrGold, 7, ANCHOR_LEFT);
                 }
               break;
              }
           }
        }
     }
  }

void DeleteSignalDrawObjects(int drawId)
  {
   DelObj(PFX + "SIG_" + IntegerToString(drawId));
   DelObj(PFX + "SIG_SL_" + IntegerToString(drawId));
   DelObj(PFX + "SIG_SL_" + IntegerToString(drawId) + "L");
   DelObj(PFX + "SIG_TP_" + IntegerToString(drawId));
   DelObj(PFX + "SIG_TP_" + IntegerToString(drawId) + "L");
  }

void ShiftLeftSweepDraw()
  {
   if(g_swpDrawIdCount <= 0)
      return;
   DelObj(PFX + "SWP_" + IntegerToString(g_swpDrawIds[0]));
   for(int i = 0; i < g_swpDrawIdCount - 1; i++)
      g_swpDrawIds[i] = g_swpDrawIds[i + 1];
   g_swpDrawIdCount--;
  }

void ShiftLeftSignalDraw()
  {
   if(g_sigDrawIdCount <= 0)
      return;
   DeleteSignalDrawObjects(g_sigDrawIds[0]);
   for(int i = 0; i < g_sigDrawIdCount - 1; i++)
      g_sigDrawIds[i] = g_sigDrawIds[i + 1];
   g_sigDrawIdCount--;
  }

int AllocSweepDrawId()
  {
   if(g_swpDrawIdCount >= MAX_SWP_DRAWS)
      ShiftLeftSweepDraw();
   g_swpDrawSeq++;
   g_swpDrawIds[g_swpDrawIdCount++] = g_swpDrawSeq;
   return(g_swpDrawSeq);
  }

int AllocSignalDrawId()
  {
   if(g_sigDrawIdCount >= MAX_SIG_DRAWS)
      ShiftLeftSignalDraw();
   g_sigDrawSeq++;
   g_sigDrawIds[g_sigDrawIdCount++] = g_sigDrawSeq;
   return(g_sigDrawSeq);
  }

void DrawSweepMark(int shift)
  {
   if(!DrawingsFull() || !ShowLiquidity || !ShowSweeps || g_swingCount < 2) return;

   double prevBody = MathAbs(iClose(Symbol(), Period(), shift + 1) - iOpen(Symbol(), Period(), shift + 1));
   double prevUpperWick = iHigh(Symbol(), Period(), shift + 1) -
                          MathMax(iOpen(Symbol(), Period(), shift + 1), iClose(Symbol(), Period(), shift + 1));
   double prevLowerWick = MathMin(iOpen(Symbol(), Period(), shift + 1), iClose(Symbol(), Period(), shift + 1)) -
                          iLow(Symbol(), Period(), shift + 1);
   double atr = GetATR(shift);
   bool prevHadUpperReject = prevUpperWick > MathMax(prevBody, atr * 0.1);
   bool prevHadLowerReject = prevLowerWick > MathMax(prevBody, atr * 0.1);

   for(int j = g_swingCount - 1; j >= MathMax(0, g_swingCount - 10); j--)
     {
      if(g_swings[j].time >= iTime(Symbol(), Period(), shift)) continue;
      if(g_swings[j].isHigh)
        {
         if(iHigh(Symbol(), Period(), shift) > g_swings[j].price &&
            iClose(Symbol(), Period(), shift) < g_swings[j].price)
           {
            if(SweepRequireWickReject && !prevHadUpperReject)
               break;
            int swpId = AllocSweepDrawId();
            string nm = PFX + "SWP_" + IntegerToString(swpId);
            DrawText(nm, iTime(Symbol(), Period(), shift), iHigh(Symbol(), Period(), shift),
                     "!", clrGold, 10, ANCHOR_LOWER);
            break;
           }
        }
      else
        {
         if(iLow(Symbol(), Period(), shift) < g_swings[j].price &&
            iClose(Symbol(), Period(), shift) > g_swings[j].price)
           {
            if(SweepRequireWickReject && !prevHadLowerReject)
               break;
            int swpId = AllocSweepDrawId();
            string nm = PFX + "SWP_" + IntegerToString(swpId);
            DrawText(nm, iTime(Symbol(), Period(), shift), iLow(Symbol(), Period(), shift),
                     "!", clrGold, 10, ANCHOR_UPPER);
            break;
           }
        }
     }
  }

void DrawSLTP(int shift, bool isBuy, double sl, double tp, int sigDrawId)
  {
   if(!DrawingsMinimalOrFull()) return;
   datetime t = iTime(Symbol(), Period(), shift);
   datetime t2 = FutureTime(8);
   string slnm = PFX + "SIG_SL_" + IntegerToString(sigDrawId);
   string tpnm = PFX + "SIG_TP_" + IntegerToString(sigDrawId);
   if(ShowSigSL && sl > 0)
     {
      DrawHorizLine(slnm, t, t2, sl, clrRed, 1, true, false);
      DrawText(slnm + "L", t2, sl, "SL", clrRed, 7, ANCHOR_LEFT);
     }
   if(ShowSigTP && tp > 0)
     {
      DrawHorizLine(tpnm, t, t2, tp, clrLimeGreen, 1, true, false);
      DrawText(tpnm + "L", t2, tp, "TP", clrLimeGreen, 7, ANCHOR_LEFT);
     }
  }

void DrawSignalArrow(int shift, bool isBuy, int sigDrawId)
  {
   if(!DrawingsMinimalOrFull()) return;
   string nm = PFX + "SIG_" + IntegerToString(sigDrawId);
   double atr = GetATR(shift);
   if(isBuy)
      DrawText(nm, iTime(Symbol(), Period(), shift), iLow(Symbol(), Period(), shift) - atr * 0.5,
               "^", clrLimeGreen, 12, ANCHOR_UPPER);
   else
      DrawText(nm, iTime(Symbol(), Period(), shift), iHigh(Symbol(), Period(), shift) + atr * 0.5,
               "v", clrRed, 12, ANCHOR_LOWER);
  }

void ExtendActiveZones()
  {
   if(!DrawingsEnabled()) return;
   datetime t2 = FutureTime(30);
   for(int i = 0; i < g_obCount; i++)
      if(!g_obs[i].mitigated || ShowMitigatedOB)
         SetRectRight(PFX + "OB_" + IntegerToString(g_obs[i].drawId), t2);
   for(int i = 0; i < g_fvgCount; i++)
      if(!g_fvgs[i].mitigated || ShowMitigatedFVG)
         SetRectRight(PFX + "FVG_" + IntegerToString(g_fvgs[i].drawId), t2);
   for(int i = 0; i < g_ifvgCount; i++)
      if(!g_ifvgs[i].mitigated)
         SetRectRight(PFX + "IFVG_" + IntegerToString(g_ifvgs[i].drawId), t2);
   for(int i = 0; i < g_oteCount; i++)
      if(!g_otes[i].invalidated)
         SetRectRight(PFX + "OTE_" + IntegerToString(g_otes[i].drawId), t2);
   for(int i = 0; i < g_breakerCount; i++)
      if(!g_breakers[i].mitigated)
         SetRectRight(PFX + "BRK_" + IntegerToString(g_breakers[i].drawId), t2);
   for(int i = 0; i < g_bprCount; i++)
      if(!g_bprs[i].mitigated)
         SetRectRight(PFX + "BPR_" + IntegerToString(g_bprs[i].drawId), t2);
   for(int i = 0; i < g_idmCount; i++)
     {
      if(!g_idms[i].expired && ObjectFind(0, PFX + "IDM_" + IntegerToString(g_idms[i].drawId)) >= 0)
         ObjectMove(0, PFX + "IDM_" + IntegerToString(g_idms[i].drawId), 1, t2, g_idms[i].price);
     }
  }

void RedrawAllZonesFromArrays()
  {
   if(!DrawingsFull()) return;
   for(int i = 0; i < g_obCount; i++) DrawOB(g_obs[i]);
   for(int i = 0; i < g_fvgCount; i++) DrawFVGZone(g_fvgs[i]);
   for(int i = 0; i < g_ifvgCount; i++) DrawIFVGZone(g_ifvgs[i]);
   for(int i = 0; i < g_oteCount; i++) DrawOTEZone(g_otes[i]);
   for(int i = 0; i < g_breakerCount; i++) DrawBreakerZone(g_breakers[i]);
   for(int i = 0; i < g_bprCount; i++) DrawBPRZone(g_bprs[i]);
   for(int i = 0; i < g_idmCount; i++)
      if(!g_idms[i].expired) DrawIDMMark(g_idms[i]);
   for(int i = 0; i < g_structureBreakCount; i++)
      DrawStructureMark(g_structureBreaks[i]);
  }

void ProcessChartDisplay(int shift)
  {
   if(!DrawingsEnabled()) return;
   ExtendActiveZones();
   if(DrawingsFull())
     {
      DrawHTFLevelsChart();
      DrawPDZonesChart();
      DrawSessionLevelsChart();
      DrawEQHLChart(shift);
      DrawSweepMark(shift);
     }
  }

void FireBarEventAlerts()
  {
   if(g_lastBullOBThisBar)
     {
      FireAlertOnce(g_alertBarBullOB, "ICT-V: Validated Bullish Order Block detected - check confluence score");
      if(g_lastBullOBScore >= 5)
         FireAlertOnce(g_alertBarHiBullOB, "ICT-V: High-confluence Bullish OB (5+ score) - strong setup");
     }
   if(g_lastBearOBThisBar)
     {
      FireAlertOnce(g_alertBarBearOB, "ICT-V: Validated Bearish Order Block detected - check confluence score");
      if(g_lastBearOBScore >= 5)
         FireAlertOnce(g_alertBarHiBearOB, "ICT-V: High-confluence Bearish OB (5+ score) - strong setup");
     }
   g_lastBullOBThisBar = false;
   g_lastBearOBThisBar = false;
  }

//+------------------------------------------------------------------+
//| Pivot detection � equivalent to ta.pivothigh / ta.pivotlow        |
//+------------------------------------------------------------------+
bool IsPivotHigh(string sym, ENUM_TIMEFRAMES tf, int shift, int len)
  {
   if(shift < len || iBars(sym, tf) < shift + len + 2)
      return(false);
   double p = iHigh(sym, tf, shift);
   for(int i = 1; i <= len; i++)
     {
      // Pine ta.pivothigh: neighbors must be strictly lower (ties reject pivot)
      if(iHigh(sym, tf, shift + i) >= p)
         return(false);
      if(iHigh(sym, tf, shift - i) >= p)
         return(false);
     }
   return(true);
  }

bool IsPivotLow(string sym, ENUM_TIMEFRAMES tf, int shift, int len)
  {
   if(shift < len || iBars(sym, tf) < shift + len + 2)
      return(false);
   double p = iLow(sym, tf, shift);
   for(int i = 1; i <= len; i++)
     {
      // Pine ta.pivotlow: neighbors must be strictly higher (ties reject pivot)
      if(iLow(sym, tf, shift + i) <= p)
         return(false);
      if(iLow(sym, tf, shift - i) <= p)
         return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Array helpers                                                    |
//+------------------------------------------------------------------+
void AddSwing(SMC_Swing &sw)
  {
   if(g_swingCount >= MAX_SWINGS)
     {
      for(int i = 0; i < MAX_SWINGS - 1; i++)
         g_swings[i] = g_swings[i + 1];
      g_swingCount = MAX_SWINGS - 1;
     }
   g_swings[g_swingCount++] = sw;
  }

void AddInternalSwing(SMC_Swing &sw)
  {
   if(g_internalSwingCount >= MAX_INTERNAL_SWINGS)
     {
      for(int i = 0; i < MAX_INTERNAL_SWINGS - 1; i++)
         g_internalSwings[i] = g_internalSwings[i + 1];
      g_internalSwingCount = MAX_INTERNAL_SWINGS - 1;
     }
   g_internalSwings[g_internalSwingCount++] = sw;
  }

void AddStructureBreak(SMC_StructureBreak &brk, bool internal)
  {
   if(internal)
     {
      if(g_internalBreakCount >= MAX_STRUCTURE_BREAKS)
        {
         DelObj(PFX + "SB_" + IntegerToString(g_internalBreaks[0].drawId));
         DelObj(PFX + "SBL_" + IntegerToString(g_internalBreaks[0].drawId));
         for(int i = 0; i < MAX_STRUCTURE_BREAKS - 1; i++)
            g_internalBreaks[i] = g_internalBreaks[i + 1];
         g_internalBreakCount = MAX_STRUCTURE_BREAKS - 1;
        }
      g_internalBreaks[g_internalBreakCount++] = brk;
     }
   else
     {
      if(g_structureBreakCount >= MAX_STRUCTURE_BREAKS)
        {
         DelObj(PFX + "SB_" + IntegerToString(g_structureBreaks[0].drawId));
         DelObj(PFX + "SBL_" + IntegerToString(g_structureBreaks[0].drawId));
         for(int i = 0; i < MAX_STRUCTURE_BREAKS - 1; i++)
            g_structureBreaks[i] = g_structureBreaks[i + 1];
         g_structureBreakCount = MAX_STRUCTURE_BREAKS - 1;
        }
      g_structureBreaks[g_structureBreakCount++] = brk;
     }
  }

//+------------------------------------------------------------------+
//| Premium / discount, ATR, killzone, HTF                           |
//+------------------------------------------------------------------+
double BarTrueRange(int shift)
  {
   if(shift + 1 >= Bars)
      return(0);
   double h = iHigh(Symbol(), Period(), shift);
   double l = iLow(Symbol(), Period(), shift);
   double pc = iClose(Symbol(), Period(), shift + 1);
   return(MathMax(h - l, MathMax(MathAbs(h - pc), MathAbs(l - pc))));
  }

// Pine ta.atr(14) � Wilder RMA (seed SMA then smooth toward bar 0)
double PineATR(int shift)
  {
   int period = 14;
   if(Bars < shift + period + 1)
      return(0);

   int oldest = Bars - 1;
   if(oldest < shift + period - 1)
      return(0);

   int seedEnd = oldest - period + 1;
   double sum = 0;
   for(int i = oldest; i >= seedEnd; i--)
      sum += BarTrueRange(i);
   double atr = sum / period;

   for(int i = seedEnd - 1; i >= shift; i--)
      atr = (atr * (period - 1) + BarTrueRange(i)) / period;

   return(atr);
  }

// Pine ta.atr(14) at shift � PineATR Wilder replay (H4 borderline); iATR fallback on warmup
double FVGDisplacementATR(int shift)
  {
   double pa = PineATR(shift);
   if(pa > 0)
      return(pa);
   return(iATR(Symbol(), Period(), 14, shift));
  }

bool FVGPriceBelow(double close, double level)
  {
   return(NormalizeDouble(close, Digits) < NormalizeDouble(level, Digits));
  }

bool FVGPriceAbove(double close, double level)
  {
   return(NormalizeDouble(close, Digits) > NormalizeDouble(level, Digits));
  }

double GetATR(int shift)
  {
   return(iATR(Symbol(), Period(), 14, shift));
  }

bool IsPremium(double price, double rh, double rl)
  {
   return(price > (rh + rl) / 2.0);
  }

bool IsDiscount(double price, double rh, double rl)
  {
   return(price < (rh + rl) / 2.0);
  }

bool IsLeapYear(int year)
  {
   return((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0));
  }

int DaysInYear(int year)
  {
   return(IsLeapYear(year) ? 366 : 365);
  }

// Pine: hour(time, "America/New_York") � US Eastern with automatic DST when enabled
int FindNthWeekday(int year, int month, int dow, int n)
  {
   int count = 0;
   for(int d = 1; d <= 31; d++)
     {
      datetime probe = StringToTime(StringFormat("%04d.%02d.%02d", year, month, d));
      if(probe <= 0)
         break;
      MqlDateTime dt;
      TimeToStruct(probe, dt);
      if(dt.mon != month)
         break;
      if(dt.day_of_week == dow)
        {
         count++;
         if(count == n)
            return(d);
        }
     }
   return(-1);
  }

// IC Markets MT4 server: GMT+2 standard, GMT+3 from 2nd Sunday March through 1st Sunday November
int ICMarketsBrokerUtcOffsetHours(datetime brokerTimeApprox)
  {
   MqlDateTime dt;
   TimeToStruct(brokerTimeApprox, dt);
   int y = dt.year;

   int march2Sun = FindNthWeekday(y, 3, 0, 2);
   int nov1Sun   = FindNthWeekday(y, 11, 0, 1);
   if(march2Sun < 1 || nov1Sun < 1)
      return(2);

   datetime springBoundary = StringToTime(StringFormat("%04d.%02d.%02d 00:00", y, 3, march2Sun));
   datetime autumnBoundary = StringToTime(StringFormat("%04d.%02d.%02d 00:00", y, 11, nov1Sun));

   if(brokerTimeApprox >= springBoundary && brokerTimeApprox < autumnBoundary)
      return(3);
   return(2);
  }

// Pine hour(time,"America/New_York"): convert broker bar time to UTC before NY session math
datetime BarTimeToUtc(datetime t)
  {
   if(UseICMarketsAutoOffset)
     {
      int offHrs = ICMarketsBrokerUtcOffsetHours(t);
      return(t - offHrs * 3600);
     }
   if(BrokerGMTOffset != 0)
      return(t - BrokerGMTOffset * 3600);
   return(t);
  }

// EA modules comparing to TimeCurrent() � broker wall clock vs UTC
int ServerUtcOffsetSeconds()
  {
   if(UseICMarketsAutoOffset)
      return(ICMarketsBrokerUtcOffsetHours(TimeCurrent()) * 3600);
   if(BrokerGMTOffset != 0)
      return(BrokerGMTOffset * 3600);
   return((int)(TimeCurrent() - TimeGMT()));
  }

datetime UtcFromYMDHM(int year, int month, int day, int hour, int minute)
  {
   MqlDateTime st;
   st.year = year;
   st.mon  = month;
   st.day  = day;
   st.hour = hour;
   st.min  = minute;
   st.sec  = 0;
   datetime probe = StructToTime(st);
   if(probe <= 0)
      return(0);
   return(probe - (TimeCurrent() - TimeGMT()));
  }

bool IsUSEasternDST(datetime utc)
  {
   if(!UseAutoNYDST)
      return(NYUTCOffsetHours == 4);
   MqlDateTime dt;
   TimeToStruct(utc, dt);  // utc is already UTC � no offset needed; TimeGMT() is unreliable in tester
   int y = dt.year;
   int march2Sun = FindNthWeekday(y, 3, 0, 2);
   int nov1Sun   = FindNthWeekday(y, 11, 0, 1);
   if(march2Sun < 1 || nov1Sun < 1)
      return(false);
   datetime dstStart = UtcFromYMDHM(y, 3, march2Sun, 7, 0);
   datetime dstEnd   = UtcFromYMDHM(y, 11, nov1Sun, 6, 0);
   if(dstStart <= 0 || dstEnd <= 0)
      return(false);
   return(utc >= dstStart && utc < dstEnd);
  }

int GetNYSEasternOffsetHours(datetime utc)
  {
   if(!UseAutoNYDST)
      return(NYUTCOffsetHours);
   return(IsUSEasternDST(utc) ? 4 : 5);
  }

// London 02:00-05:00 | NY AM 08:30-11:00 | NY PM 13:00-16:00 | Asian 20:00+
int NYTimeCode(datetime t)
  {
   datetime utc = BarTimeToUtc(t);
   int utcSec = (int)(utc % 86400);
   if(utcSec < 0)
      utcSec += 86400;
   int nyOffset = GetNYSEasternOffsetHours(utc);
   int nyMinTotal = utcSec / 60 - nyOffset * 60;
   while(nyMinTotal < 0)
      nyMinTotal += 1440;
   while(nyMinTotal >= 1440)
      nyMinTotal -= 1440;
   return((nyMinTotal / 60) * 100 + (nyMinTotal % 60));
  }

bool IsInKillzone(datetime t)
  {
   int ny = NYTimeCode(t);
   bool asian  = KZAsian  && (ny >= 2000);
   bool london = KZLondon && (ny >= 200 && ny < 500);
   bool nyam   = KZNYAM   && (ny >= 830 && ny < 1100);
   bool nypm   = KZNYPM   && (ny >= 1300 && ny < 1600);
   return(asian || london || nyam || nypm);
  }

string GetKZSessionName(datetime t)
  {
   int ny = NYTimeCode(t);
   if(KZNYAM && ny >= 830 && ny < 1100)
      return("NY AM");
   if(KZLondon && ny >= 200 && ny < 500)
      return("London");
   if(KZNYPM && ny >= 1300 && ny < 1600)
      return("NY PM");
   if(KZAsian && ny >= 2000)
      return("Asian");
   return("Off-Session");
  }

void UpdatePremiumDiscount(int shift)
  {
   if(g_lastSwingHigh <= 0 || g_lastSwingLow <= 0)
     {
      g_pdEquilibrium = 0;
      g_pdZoneStr = "---";
      return;
     }
   g_pdEquilibrium = (g_lastSwingHigh + g_lastSwingLow) / 2.0;
   int useShift = (shift > 0) ? shift : 0;
   double price = iClose(Symbol(), Period(), useShift);
   if(IsPremium(price, g_lastSwingHigh, g_lastSwingLow))
      g_pdZoneStr = "PREMIUM";
   else
      g_pdZoneStr = "DISCOUNT";
  }

void UpdateSessionLevels()
  {
   if(ShowSessionLevels || ShowPDHL)
     {
      g_pdHigh = iHigh(Symbol(), PERIOD_D1, 1);
      g_pdLow  = iLow(Symbol(),  PERIOD_D1, 1);
     }
   if(ShowSessionLevels || ShowPWHL)
     {
      g_pwHigh = iHigh(Symbol(), PERIOD_W1, 1);
      g_pwLow  = iLow(Symbol(),  PERIOD_W1, 1);
     }
  }

void UpdateKillzoneState(datetime t)
  {
   g_inKillzoneNow = IsInKillzone(t);
   g_kzSessionStr = GetKZSessionName(t);
  }

// Pine request.security on chart TF == HTF TF: htfStructure tracks same bar closes as swingBullish
bool HTFStructureBullish()
  {
   if(!UseHTF)
      return(g_swingBullish);
   if(Period() == HTFTimeframe && HTFSwingLength == SwingLength)
      return(g_swingBullish);
   return(g_htfBullish);
  }

bool HTFAligned(bool setupBullish)
  {
   if(!UseHTF)
      return(true);
   bool htfBull = HTFStructureBullish();
   return((setupBullish && htfBull) || (!setupBullish && !htfBull));
  }

//+------------------------------------------------------------------+
//| HTF v1.6 �" incremental real-time structure (iHigh/iLow/iClose)     |
//+------------------------------------------------------------------+
void ResetHTFState()
  {
   g_htfBullish = true;
   g_htfLastHigh = 0;
   g_htfLastLow = 0;
   g_htfLastHighTime = 0;
   g_htfLastLowTime = 0;
   g_htfHighBroken = false;
   g_htfLowBroken = false;
   g_htfLastBreakStr = "---";
   g_htfLastProcessedBarTime = 0;
   g_htfLastProcessedShift = -1;
  }

void ProcessHTFClosedBar(int htfShift)
  {
   string sym = Symbol();
   ENUM_TIMEFRAMES tf = HTFTimeframe;

   int pivShift = htfShift + HTFSwingLength;

   if(IsPivotHigh(sym, tf, pivShift, HTFSwingLength))
     {
      g_htfLastHigh = iHigh(sym, tf, pivShift);
      g_htfLastHighTime = iTime(sym, tf, pivShift);
      g_htfHighBroken = false;
     }
   if(IsPivotLow(sym, tf, pivShift, HTFSwingLength))
     {
      g_htfLastLow = iLow(sym, tf, pivShift);
      g_htfLastLowTime = iTime(sym, tf, pivShift);
      g_htfLowBroken = false;
     }

   double close = iClose(sym, tf, htfShift);
   double high  = iHigh(sym, tf, htfShift);
   double low   = iLow(sym, tf, htfShift);
   double open  = iOpen(sym, tf, htfShift);
   double srcHigh = RequireBodyClose ? close : high;
   double srcLow  = RequireBodyClose ? close : low;

   bool brokeHigh = (g_htfLastHigh > 0 && !g_htfHighBroken && srcHigh > g_htfLastHigh);
   bool brokeLow  = (g_htfLastLow > 0 && !g_htfLowBroken && srcLow < g_htfLastLow);

   if(brokeHigh && brokeLow)
     {
      if(close >= open)
         brokeLow = false;
      else
         brokeHigh = false;
     }

   if(brokeHigh)
     {
      g_htfLastBreakStr = g_htfBullish ? "BOS ^" : "CHoCH ^";
      g_htfBullish = true;
      g_htfHighBroken = true;
      if(DebugStructure)
         Print("ICT-V HTF ", g_htfLastBreakStr, " @ ", DoubleToStr(g_htfLastHigh, Digits));
     }
   if(brokeLow)
     {
      g_htfLastBreakStr = g_htfBullish ? "CHoCH v" : "BOS v";
      g_htfBullish = false;
      g_htfLowBroken = true;
      if(DebugStructure)
         Print("ICT-V HTF ", g_htfLastBreakStr, " @ ", DoubleToStr(g_htfLastLow, Digits));
     }
  }

// Process HTF bars chronologically up to chart-bar time (incremental: bootstrap + live)
void SyncHTFToTime(datetime asOf)
  {
   if(!UseHTF)
      return;

   string sym = Symbol();
   ENUM_TIMEFRAMES tf = HTFTimeframe;
   int bars = iBars(sym, tf);
   if(bars < HTFSwingLength * 2 + 5)
      return;

   int oldestShift = bars - HTFSwingLength - 2;

   // Cursor = last processed HTF bar time (ResetHTFState once before bootstrap loop)
   int startShift = oldestShift;

   if(g_htfLastProcessedBarTime > 0)
     {
      int lastShift = iBarShift(sym, tf, g_htfLastProcessedBarTime, false);
      if(lastShift >= 0)
         startShift = (lastShift > 0) ? lastShift - 1 : oldestShift;
     }

   if(startShift < 1)
      startShift = 1;
   if(startShift > oldestShift)
      startShift = oldestShift;

   for(int shift = startShift; shift >= 1; shift--)
     {
      datetime t = iTime(sym, tf, shift);
      if(t > asOf)
         continue;
      // Pine request.security(..., lookahead=barmerge.lookahead_off): confirmed HTF bars only
      datetime htfNextOpen = iTime(sym, tf, shift - 1);
      if(htfNextOpen > asOf)
         continue;
      if(g_htfLastProcessedBarTime > 0 && t <= g_htfLastProcessedBarTime)
         continue;

      ProcessHTFClosedBar(shift);
      g_htfLastProcessedBarTime = t;
      g_htfLastProcessedShift = shift;
     }
  }

// Full HTF replay from scratch � matches Pine request.security final state on attach
void ReplayHTFToNow()
  {
   if(!UseHTF)
      return;
   ResetHTFState();
   SyncHTFToTime(TimeCurrent());
  }

//+------------------------------------------------------------------+
//| Dynamic zone array helpers (Pine prune caps)                       |
//+------------------------------------------------------------------+
void ShiftLeftOB()
  {
   if(g_obCount <= 0)
      return;
   RemoveOBDraw(g_obs[0].drawId);
   if(g_obCount <= 1)
     {
      g_obCount = 0;
      ArrayResize(g_obs, 0);
      return;
     }
   for(int i = 0; i < g_obCount - 1; i++)
      g_obs[i] = g_obs[i + 1];
   g_obCount--;
   ArrayResize(g_obs, g_obCount);
  }

void TrimOBArray()
  {
   int cap = MathMax(OBMaxCount, 1) * 3;
   while(g_obCount > cap)
      ShiftLeftOB();
  }

void AddOB(SMC_OrderBlock &ob)
  {
   g_obCount++;
   ArrayResize(g_obs, g_obCount);
   g_obs[g_obCount - 1] = ob;
  }

void ShiftLeftFVG()
  {
   if(g_fvgCount <= 0)
      return;
   DelObj(PFX + "FVG_" + IntegerToString(g_fvgs[0].drawId));
   DelObj(PFX + "FVGCE_" + IntegerToString(g_fvgs[0].drawId));
   if(g_fvgCount <= 1)
     {
      g_fvgCount = 0;
      ArrayResize(g_fvgs, 0);
      return;
     }
   for(int i = 0; i < g_fvgCount - 1; i++)
      g_fvgs[i] = g_fvgs[i + 1];
   g_fvgCount--;
   ArrayResize(g_fvgs, g_fvgCount);
  }

void TrimFVGArray()
  {
   int cap = MathMax(FVGMaxCount, 1) * 3;
   while(g_fvgCount > cap)
      ShiftLeftFVG();
  }

void AddFVG(SMC_FVG &f)
  {
   g_fvgCount++;
   ArrayResize(g_fvgs, g_fvgCount);
   g_fvgs[g_fvgCount - 1] = f;
  }

void ShiftLeftIFVG()
  {
   if(g_ifvgCount <= 0)
      return;
   DelObj(PFX + "IFVG_" + IntegerToString(g_ifvgs[0].drawId));
   DelObj(PFX + "IFVGL_" + IntegerToString(g_ifvgs[0].drawId));
   if(g_ifvgCount <= 1)
     {
      g_ifvgCount = 0;
      ArrayResize(g_ifvgs, 0);
      return;
     }
   for(int i = 0; i < g_ifvgCount - 1; i++)
      g_ifvgs[i] = g_ifvgs[i + 1];
   g_ifvgCount--;
   ArrayResize(g_ifvgs, g_ifvgCount);
  }

void TrimIFVGArray()
  {
   int cap = MathMax(FVGMaxCount, 1) * 2;
   while(g_ifvgCount > cap)
      ShiftLeftIFVG();
  }

void AddIFVG(SMC_IFVG &iv)
  {
   g_ifvgCount++;
   ArrayResize(g_ifvgs, g_ifvgCount);
   g_ifvgs[g_ifvgCount - 1] = iv;
  }

void ShiftLeftBreaker()
  {
   if(g_breakerCount <= 0)
      return;
   DelObj(PFX + "BRK_" + IntegerToString(g_breakers[0].drawId));
   DelObj(PFX + "BRKL_" + IntegerToString(g_breakers[0].drawId));
   if(g_breakerCount <= 1)
     {
      g_breakerCount = 0;
      ArrayResize(g_breakers, 0);
      return;
     }
   for(int i = 0; i < g_breakerCount - 1; i++)
      g_breakers[i] = g_breakers[i + 1];
   g_breakerCount--;
   ArrayResize(g_breakers, g_breakerCount);
  }

void TrimBreakerArray()
  {
   int cap = MathMax(BreakerMaxCount, 1) * 2;
   while(g_breakerCount > cap)
      ShiftLeftBreaker();
  }

void AddBreaker(SMC_Breaker &b)
  {
   g_breakerCount++;
   ArrayResize(g_breakers, g_breakerCount);
   g_breakers[g_breakerCount - 1] = b;
  }

void ShiftLeftBPR()
  {
   if(g_bprCount <= 0)
      return;
   DelObj(PFX + "BPR_" + IntegerToString(g_bprs[0].drawId));
   DelObj(PFX + "BPRL_" + IntegerToString(g_bprs[0].drawId));
   if(g_bprCount <= 1)
     {
      g_bprCount = 0;
      ArrayResize(g_bprs, 0);
      return;
     }
   for(int i = 0; i < g_bprCount - 1; i++)
      g_bprs[i] = g_bprs[i + 1];
   g_bprCount--;
   ArrayResize(g_bprs, g_bprCount);
  }

void AddBPR(SMC_BPR &bp)
  {
   g_bprCount++;
   ArrayResize(g_bprs, g_bprCount);
   g_bprs[g_bprCount - 1] = bp;
  }

bool BPROverlapExists(double top, double bottom)
  {
   // Pine parity: math.abs(existing.top - overlapTop) < 1 (absolute price, not Point)
   for(int k = g_bprCount - 1; k >= MathMax(0, g_bprCount - 5); k--)
     {
      if(MathAbs(g_bprs[k].top - top) < 1.0 &&
         MathAbs(g_bprs[k].bottom - bottom) < 1.0)
         return(true);
     }
   return(false);
  }

void TrimBPRArray()
  {
   while(g_bprCount > 5)
      ShiftLeftBPR();
  }

void ShiftLeftOTE()
  {
   if(g_oteCount <= 0)
      return;
   DelObj(PFX + "OTE_" + IntegerToString(g_otes[0].drawId));
   DelObj(PFX + "OTEL_" + IntegerToString(g_otes[0].drawId));
   DelObj(PFX + "OTEF50_" + IntegerToString(g_otes[0].drawId));
   if(g_oteCount <= 1)
     {
      g_oteCount = 0;
      ArrayResize(g_otes, 0);
      return;
     }
   for(int i = 0; i < g_oteCount - 1; i++)
      g_otes[i] = g_otes[i + 1];
   g_oteCount--;
   ArrayResize(g_otes, g_oteCount);
  }

void TrimOTEArray()
  {
   int cap = MathMax(OTEMaxCount, 1) * 2;
   while(g_oteCount > cap)
      ShiftLeftOTE();
  }

void AddOTE(SMC_OTE &o)
  {
   g_oteCount++;
   ArrayResize(g_otes, g_oteCount);
   g_otes[g_oteCount - 1] = o;
  }

void ShiftLeftIDM()
  {
   if(g_idmCount <= 0)
      return;
   DelObj(PFX + "IDM_" + IntegerToString(g_idms[0].drawId));
   DelObj(PFX + "IDML_" + IntegerToString(g_idms[0].drawId));
   if(g_idmCount <= 1)
     {
      g_idmCount = 0;
      ArrayResize(g_idms, 0);
      return;
     }
   for(int i = 0; i < g_idmCount - 1; i++)
      g_idms[i] = g_idms[i + 1];
   g_idmCount--;
   ArrayResize(g_idms, g_idmCount);
  }

void TrimIDMArray()
  {
   int cap = MathMax(IDMMaxCount, 1) * 2;
   while(g_idmCount > cap)
      ShiftLeftIDM();
  }

void AddIDM(SMC_Inducement &idm)
  {
   g_idmCount++;
   ArrayResize(g_idms, g_idmCount);
   g_idms[g_idmCount - 1] = idm;
  }

string OTELabelFromFlags(bool obOverlap, bool fvgOverlap)
  {
   if(obOverlap && fvgOverlap)
      return("OTE + OB + FVG");
   if(obOverlap)
      return("OTE + OB");
   if(fvgOverlap)
      return("OTE + FVG");
   return("OTE");
  }

// v1.6 OTE: leg from opposing swing to break-bar extreme (always tracked)
void CreateOTEZone(bool brkBull, int shift, datetime barTime)
  {
   double legH = 0;
   double legL = 0;

   if(brkBull)
     {
      legH = iHigh(Symbol(), Period(), shift);
      legL = g_lastSwingLow;
     }
   else
     {
      legH = g_lastSwingHigh;
      legL = iLow(Symbol(), Period(), shift);
     }

   if(legH <= 0 || legL <= 0 || legH <= legL)
      return;

   double legRange = legH - legL;
   SMC_OTE ote;
   ote.time = barTime;
   ote.legHigh = legH;
   ote.legLow = legL;
   ote.triggered = false;
   ote.invalidated = false;
   ote.hasOBOverlap = false;
   ote.hasFVGOverlap = false;

   if(brkBull)
     {
      ote.bullish = true;
      ote.zoneTop = legH - legRange * OTEFibLow;
      ote.zoneBottom = legH - legRange * OTEFibHigh;
      ote.fib50 = legH - legRange * 0.5;
     }
   else
     {
      ote.bullish = false;
      ote.zoneBottom = legL + legRange * OTEFibLow;
      ote.zoneTop = legL + legRange * OTEFibHigh;
      ote.fib50 = legL + legRange * 0.5;
     }

   for(int j = g_obCount - 1; j >= MathMax(0, g_obCount - 10); j--)
     {
      if(g_obs[j].mitigated)
         continue;
      if(ote.bullish && !g_obs[j].bullish)
         continue;
      if(!ote.bullish && g_obs[j].bullish)
         continue;
      if(g_obs[j].top >= ote.zoneBottom && g_obs[j].bottom <= ote.zoneTop)
        {
         ote.hasOBOverlap = true;
         break;
        }
     }

   for(int j = g_fvgCount - 1; j >= MathMax(0, g_fvgCount - 10); j--)
     {
      if(g_fvgs[j].mitigated)
         continue;
      if(ote.bullish && !g_fvgs[j].bullish)
         continue;
      if(!ote.bullish && g_fvgs[j].bullish)
         continue;
      if(g_fvgs[j].top >= ote.zoneBottom && g_fvgs[j].bottom <= ote.zoneTop)
        {
         ote.hasFVGOverlap = true;
         break;
        }
     }

   ote.drawId = NextDrawId();
   AddOTE(ote);
   DrawOTEZone(g_otes[g_oteCount - 1]);

   if(DebugZones)
      Print("ICT-V ", OTELabelFromFlags(ote.hasOBOverlap, ote.hasFVGOverlap),
            " ", (brkBull ? "BULL" : "BEAR"),
            " [", DoubleToStr(ote.zoneBottom, Digits), "-", DoubleToStr(ote.zoneTop, Digits), "]");
  }

//+------------------------------------------------------------------+
//| IDM �" internal swing inducement (Pine idmGroup)                  |
//+------------------------------------------------------------------+
void TryCreateIDM(int pivotShift, bool isHighPivot)
  {
   if(!ShowIDM)
      return;

   string sym = Symbol();
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();
   double price = isHighPivot ? iHigh(sym, tf, pivotShift) : iLow(sym, tf, pivotShift);
   datetime t = iTime(sym, tf, pivotShift);

   if(!isHighPivot && g_swingBullish)
     {
      if(g_lastSwingLow > 0 && MathAbs(price - g_lastSwingLow) / price * 100.0 < 0.1)
         return;

      SMC_Inducement idm;
      idm.time = t;
      idm.price = price;
      idm.bullish = true;
      idm.triggered = false;
      idm.triggerTime = 0;
      idm.triggerBar = 0;
      idm.expired = false;
      idm.drawId = NextDrawId();
      AddIDM(idm);
      DrawIDMMark(g_idms[g_idmCount - 1]);

      if(DebugZones)
         Print("ICT-V IDM BULL @ ", DoubleToStr(price, Digits));
     }

   if(isHighPivot && !g_swingBullish)
     {
      if(g_lastSwingHigh > 0 && MathAbs(price - g_lastSwingHigh) / price * 100.0 < 0.1)
         return;

      SMC_Inducement idm;
      idm.time = t;
      idm.price = price;
      idm.bullish = false;
      idm.triggered = false;
      idm.triggerTime = 0;
      idm.triggerBar = 0;
      idm.expired = false;
      idm.drawId = NextDrawId();
      AddIDM(idm);
      DrawIDMMark(g_idms[g_idmCount - 1]);

      if(DebugZones)
         Print("ICT-V IDM BEAR @ ", DoubleToStr(price, Digits));
     }
  }

void UpdateIDMLifecycle(int shift)
  {
   if(!ShowIDM || g_idmCount <= 0)
      return;

   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);
   datetime barTime = iTime(Symbol(), Period(), shift);

   for(int i = g_idmCount - 1; i >= 0; i--)
     {
      if(g_idms[i].expired)
         continue;

      if(!g_idms[i].triggered)
        {
         if(g_idms[i].bullish && !g_swingBullish)
           {
            g_idms[i].expired = true;
            continue;
           }
         if(!g_idms[i].bullish && g_swingBullish)
           {
            g_idms[i].expired = true;
            continue;
           }

         if(g_idms[i].bullish)
           {
            if(low < g_idms[i].price && close > g_idms[i].price)
              {
               g_idms[i].triggered = true;
               g_idms[i].triggerTime = barTime;
               g_idms[i].triggerBar = ClosedBarPineIndex();
               DrawIDMMark(g_idms[i]);
               FireAlertOnce(g_alertBarIDM,
                  "ICT-V: Inducement level swept - internal swing taken out while higher structure holds");
               if(DebugZones)
                  Print("ICT-V IDM BULL swept @ ", DoubleToStr(g_idms[i].price, Digits));
              }
           }
         else
           {
            if(high > g_idms[i].price && close < g_idms[i].price)
              {
               g_idms[i].triggered = true;
               g_idms[i].triggerTime = barTime;
               g_idms[i].triggerBar = ClosedBarPineIndex();
               DrawIDMMark(g_idms[i]);
               FireAlertOnce(g_alertBarIDM,
                  "ICT-V: Inducement level swept - internal swing taken out while higher structure holds");
               if(DebugZones)
                  Print("ICT-V IDM BEAR swept @ ", DoubleToStr(g_idms[i].price, Digits));
              }
           }
        }

      if(g_idms[i].triggered && !g_idms[i].expired)
        {
         if(ClosedBarPineIndex() - g_idms[i].triggerBar > 20)
            g_idms[i].expired = true;
        }

      if(g_idms[i].expired)
        {
         for(int k = i; k < g_idmCount - 1; k++)
            g_idms[k] = g_idms[k + 1];
         g_idmCount--;
         ArrayResize(g_idms, g_idmCount);
        }
     }
  }

int CountActiveOTEs()
  {
   int n = 0;
   for(int i = 0; i < g_oteCount; i++)
      if(!g_otes[i].invalidated)
         n++;
   return(n);
  }

int CountActiveIDMs()
  {
   int n = 0;
   int triggered = 0;
   for(int i = 0; i < g_idmCount; i++)
     {
      if(!g_idms[i].expired)
        {
         n++;
         if(g_idms[i].triggered)
            triggered++;
        }
     }
   return(n);
  }

int CountTriggeredIDMs()
  {
   int n = 0;
   for(int i = 0; i < g_idmCount; i++)
      if(!g_idms[i].expired && g_idms[i].triggered)
         n++;
   return(n);
  }

bool HasTripleOTEOverlap()
  {
   for(int i = 0; i < g_oteCount; i++)
     {
      if(!g_otes[i].invalidated && g_otes[i].hasOBOverlap && g_otes[i].hasFVGOverlap)
         return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| Order Block validation (Pine v1.6 �" detection NOT gated by ShowOB)|
//+------------------------------------------------------------------+
bool HasBullOBDisp(int obShift, int candleOffset)
  {
   if(candleOffset < 3)
      return(false);
   int maxJ = MathMin(candleOffset - 2, 5);
   for(int j = 0; j <= maxJ; j++)
     {
      // Pine: low[candleOffset - j - 2] > high[candleOffset - j]
      if(iLow(Symbol(), Period(), obShift - j - 2) > iHigh(Symbol(), Period(), obShift - j))
         return(true);
     }
   return(false);
  }

bool HasBearOBDisp(int obShift, int candleOffset)
  {
   if(candleOffset < 3)
      return(false);
   int maxJ = MathMin(candleOffset - 2, 5);
   for(int j = 0; j <= maxJ; j++)
     {
      // Pine: high[candleOffset - j - 2] < low[candleOffset - j]
      if(iHigh(Symbol(), Period(), obShift - j - 2) < iLow(Symbol(), Period(), obShift - j))
         return(true);
     }
   return(false);
  }

bool HasOBSweep(bool bullish, int obBarIdx, double obHigh, double obLow)
  {
   for(int j = g_swingCount - 1; j >= MathMax(0, g_swingCount - 10); j--)
     {
      // Pine: sp.idx < obBar (strictly before OB candle)
      if(g_swings[j].barIdx <= 0 || g_swings[j].barIdx >= obBarIdx)
         continue;
      if(bullish && !g_swings[j].isHigh && obLow < g_swings[j].price)
         return(true);
      if(!bullish && g_swings[j].isHigh && obHigh > g_swings[j].price)
         return(true);
     }
   return(false);
  }

void TryCreateOBFromSwing(SMC_Swing &sw, int procShift)
  {
   // Pine: latest.idx == bar_index - swingLen on pivot confirm bar only
   int expectIdx = ClosedBarPineIndex() - SwingLength;
   if(sw.barIdx != expectIdx)
      return;

   // Pine: obBar = latest.idx; candleOffset = bar_index - obBar
   int obShift = procShift + SwingLength;
   if(obShift >= Bars)
      return;
   int candleOffset = ClosedBarPineIndex() - sw.barIdx;
   if(candleOffset <= 0 || candleOffset >= 500)
      return;

   double obHigh = iHigh(Symbol(), Period(), obShift);
   double obLow  = iLow(Symbol(), Period(), obShift);
   int obBarIdx = sw.barIdx;

   if(!sw.isHigh)
     {
      if(iClose(Symbol(), Period(), obShift) >= iOpen(Symbol(), Period(), obShift))
         return;

      bool hasSweep = HasOBSweep(true, obBarIdx, obHigh, obLow);
      bool hasDisp  = HasBullOBDisp(obShift, candleOffset);
      bool sweepOK  = !RequireSweep || hasSweep;
      bool dispOK   = !RequireDisplacement || hasDisp;
      if(!sweepOK || !dispOK)
         return;

      // Pine parity: isInKillzone() on pivot confirmation bar, not OB candle time
      bool inKZ = IsInKillzone(iTime(Symbol(), Period(), procShift));
      bool inZone = true;
      if(g_lastSwingHigh > 0 && g_lastSwingLow > 0)
         inZone = IsDiscount(obLow, g_lastSwingHigh, g_lastSwingLow);

      int score = 0;
      if(hasSweep)
         score += 2;
      if(hasDisp)
         score += 2;
      if(inKZ)
         score += 1;
      if(inZone)
         score += 1;
      if(HTFAligned(true))
         score += 2;
      if(score < MinOBDisplayScore)
         return;

      SMC_OrderBlock ob;
      ob.time = sw.time;
      ob.endTime = sw.time;
      ob.top = obHigh;
      ob.bottom = obLow;
      ob.bullish = true;
      ob.hasSweep = hasSweep;
      ob.hasDisplacement = hasDisp;
      ob.mitigated = false;
      ob.score = score;
      ob.inKillzone = inKZ;
      ob.inCorrectZone = inZone;
      ob.drawId = NextDrawId();
      AddOB(ob);
      DrawOB(g_obs[g_obCount - 1]);
      g_lastBullOBThisBar = true;
      g_lastBullOBScore = score;

      if(DebugZones)
         Print("ICT-V OB BULL score=", score, " @ ", DoubleToStr(obLow, Digits));
     }
   else
     {
      if(iClose(Symbol(), Period(), obShift) <= iOpen(Symbol(), Period(), obShift))
         return;

      bool hasSweep = HasOBSweep(false, obBarIdx, obHigh, obLow);
      bool hasDisp  = HasBearOBDisp(obShift, candleOffset);
      bool sweepOK  = !RequireSweep || hasSweep;
      bool dispOK   = !RequireDisplacement || hasDisp;
      if(!sweepOK || !dispOK)
         return;

      // Pine parity: isInKillzone() on pivot confirmation bar, not OB candle time
      bool inKZ = IsInKillzone(iTime(Symbol(), Period(), procShift));
      bool inZone = true;
      if(g_lastSwingHigh > 0 && g_lastSwingLow > 0)
         inZone = IsPremium(obHigh, g_lastSwingHigh, g_lastSwingLow);

      int score = 0;
      if(hasSweep)
         score += 2;
      if(hasDisp)
         score += 2;
      if(inKZ)
         score += 1;
      if(inZone)
         score += 1;
      if(HTFAligned(false))
         score += 2;
      if(score < MinOBDisplayScore)
         return;

      SMC_OrderBlock ob;
      ob.time = sw.time;
      ob.endTime = sw.time;
      ob.top = obHigh;
      ob.bottom = obLow;
      ob.bullish = false;
      ob.hasSweep = hasSweep;
      ob.hasDisplacement = hasDisp;
      ob.mitigated = false;
      ob.score = score;
      ob.inKillzone = inKZ;
      ob.inCorrectZone = inZone;
      ob.drawId = NextDrawId();
      AddOB(ob);
      DrawOB(g_obs[g_obCount - 1]);
      g_lastBearOBThisBar = true;
      g_lastBearOBScore = score;

      if(DebugZones)
         Print("ICT-V OB BEAR score=", score, " @ ", DoubleToStr(obHigh, Digits));
     }
  }

// FIX v1.6: check last TWO pivots �" same-bar high+low both processed
void DetectOrderBlocks(int shift)
  {
   if(g_swingCount < 2)
      return;

   int startK = MathMax(0, g_swingCount - 2);

   int expectIdx = ClosedBarPineIndex() - SwingLength;

   for(int k = startK; k < g_swingCount; k++)
     {
      // Pine: latest.idx == bar_index - swingLen (bar index only � no time filter)
      if(g_swings[k].barIdx != expectIdx)
         continue;
      TryCreateOBFromSwing(g_swings[k], shift);
     }
  }

//+------------------------------------------------------------------+
//| FVG detection �" always tracked; ShowFVG is display-only (v1.5)   |
//+------------------------------------------------------------------+
void DetectFVG(int shift)
  {
   if(shift + 2 >= Bars)
      return;

   double atr = FVGDisplacementATR(shift + 1);
   double midOpen  = iOpen(Symbol(), Period(), shift + 1);
   double midClose = iClose(Symbol(), Period(), shift + 1);
   double midSize  = MathAbs(midClose - midOpen);
   // Pine line 857-858: isDisplacement = midCandleSize >= atrVal[1] * fvgMinATRMult
   bool isDisplacement = (atr > 0 && midSize >= atr * FVGMinATRMult);

   datetime barTime = iTime(Symbol(), Period(), shift);
   bool inKZ = IsInKillzone(barTime);
   double dispATR = (atr > 0) ? midSize / atr : 0;

   // Bullish FVG: low > high[2] (Pine bullFVG_top=low, bullFVG_bot=high[2])
   double bullTop = iLow(Symbol(), Period(), shift);
   double bullBot = iHigh(Symbol(), Period(), shift + 2);
   if(bullBot < bullTop && isDisplacement && midClose > midOpen)
     {
      SMC_FVG f;
      f.time = iTime(Symbol(), Period(), shift + 1);
      f.top = bullTop;
      f.bottom = bullBot;
      f.bullish = true;
      f.displacementATR = dispATR;
      f.mitigated = false;
      f.inKillzone = inKZ;
      f.drawId = NextDrawId();
      AddFVG(f);
      DrawFVGZone(g_fvgs[g_fvgCount - 1]);

      if(DebugZones)
         Print("ICT-V FVG BULL ", DoubleToStr(bullBot, Digits), "-", DoubleToStr(bullTop, Digits));
     }

   // Bearish FVG: high < low[2] (Pine bearFVG_top=low[2], bearFVG_bot=high)
   double bearTop = iLow(Symbol(), Period(), shift + 2);
   double bearBot = iHigh(Symbol(), Period(), shift);
   if(bearTop > bearBot && isDisplacement && midClose < midOpen)
     {
      SMC_FVG f;
      f.time = iTime(Symbol(), Period(), shift + 1);
      f.top = bearTop;
      f.bottom = bearBot;
      f.bullish = false;
      f.displacementATR = dispATR;
      f.mitigated = false;
      f.inKillzone = inKZ;
      f.drawId = NextDrawId();
      AddFVG(f);
      DrawFVGZone(g_fvgs[g_fvgCount - 1]);

      if(DebugZones)
         Print("ICT-V FVG BEAR ", DoubleToStr(bearBot, Digits), "-", DoubleToStr(bearTop, Digits));
     }
  }

//+------------------------------------------------------------------+
//| BPR �" overlap of opposite FVGs (FIX: inner loop lower bound = 1) |
//+------------------------------------------------------------------+
void DetectBPR(int shift)
  {
   datetime barTime = iTime(Symbol(), Period(), shift);

   if(ShowBPR && g_fvgCount >= 2)
     {
      int startI = g_fvgCount - 1;
      int minI = MathMax(g_fvgCount - 8, 1);

      for(int i = startI; i >= minI; i--)
        {
         if(g_fvgs[i].mitigated)
            continue;

         int minJ = MathMax(i - 6, 0);
         for(int j = i - 1; j >= minJ; j--)
           {
            if(g_fvgs[j].mitigated)
               continue;
            if(g_fvgs[i].bullish == g_fvgs[j].bullish)
               continue;

            double overlapTop = MathMin(g_fvgs[i].top, g_fvgs[j].top);
            double overlapBot = MathMax(g_fvgs[i].bottom, g_fvgs[j].bottom);
            if(overlapTop <= overlapBot)
               continue;

            if(BPROverlapExists(overlapTop, overlapBot))
               break;

            SMC_BPR bp;
            bp.time = barTime;
            bp.top = overlapTop;
            bp.bottom = overlapBot;
            bp.mitigated = false;
            bp.drawId = NextDrawId();
            AddBPR(bp);
            DrawBPRZone(g_bprs[g_bprCount - 1]);

            if(DebugZones)
               Print("ICT-V BPR ", DoubleToStr(overlapBot, Digits), "-", DoubleToStr(overlapTop, Digits));
            break;
           }
        }
     }

   // Pine: BPR mitigation always runs when pool non-empty (not gated on showBPR)
   double close = iClose(Symbol(), Period(), shift);
   for(int i = 0; i < g_bprCount; i++)
     {
      if(g_bprs[i].mitigated)
         continue;
      double range = g_bprs[i].top - g_bprs[i].bottom;
      if(close > g_bprs[i].top + range || close < g_bprs[i].bottom - range)
        {
         g_bprs[i].mitigated = true;
         DrawBPRZone(g_bprs[i]);
        }
     }
  }

//+------------------------------------------------------------------+
//| Pine BREAKER BLOCK MANAGEMENT � after all OB?breaker spawns      |
//+------------------------------------------------------------------+
void ProcessBreakerLifecycle(int shift)
  {
   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);
   int barIdx = ClosedBarPineIndex();

   // Pine BREAKER BLOCK MANAGEMENT � single if / else-if (retest guard on createdIdx only)
   for(int i = g_breakerCount - 1; i >= 0; i--)
     {
      if(g_breakers[i].mitigated)
         continue;

      bool priceInZone = (high >= g_breakers[i].bottom && low <= g_breakers[i].top);

      if(priceInZone && !g_breakers[i].retested && barIdx > g_breakers[i].formedBarIdx)
        {
         g_breakers[i].retested = true;
         DrawBreakerZone(g_breakers[i]);
        }
      else if(g_breakers[i].retested)
        {
         if(g_breakers[i].bullish && close < g_breakers[i].bottom)
           {
            g_breakers[i].mitigated = true;
            DrawBreakerZone(g_breakers[i]);
           }
         else if(!g_breakers[i].bullish && close > g_breakers[i].top)
           {
            g_breakers[i].mitigated = true;
            DrawBreakerZone(g_breakers[i]);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Zone lifecycle � FVG mitigation / IFVG (v1.6 fixes)              |
//+------------------------------------------------------------------+
void UpdateFVGIFVGLifecycle(int shift)
  {
   double close = iClose(Symbol(), Period(), shift);
   datetime barTime = iTime(Symbol(), Period(), shift);

   // FVG mitigation -> IFVG spawn (Pine: newest first)
   for(int i = g_fvgCount - 1; i >= 0; i--)
     {
      if(g_fvgs[i].mitigated)
         continue;

      // Pine FVG mit: raw close (v1.92 � normalized mit kept FVGs alive ? spurious short + cooldown slip)
      if(g_fvgs[i].bullish && close < g_fvgs[i].bottom)
        {
         g_fvgs[i].mitigated = true;
         DrawFVGZone(g_fvgs[i]);
         // Pine: IFVG pool push when showIFVG (breaker-style: Add always, draw gated)
         if(ShowIFVG)
           {
            SMC_IFVG iv;
            iv.time = barTime;
            iv.formedBarIdx = ClosedBarPineIndex();
            iv.top = g_fvgs[i].top;
            iv.bottom = g_fvgs[i].bottom;
            iv.bullish = false;
            iv.retested = false;
            iv.mitigated = false;
            iv.drawId = NextDrawId();
            AddIFVG(iv);
            if(DrawingsFull())
               DrawIFVGZone(g_ifvgs[g_ifvgCount - 1]);
            FireAlertOnce(g_alertBarBearIFVG,
               "ICT-V: Bearish Inversion FVG formed - old bullish FVG flipped to resistance");
            if(DebugZones)
               Print("ICT-V IFVG BEAR spawned barIdx=", iv.formedBarIdx);
           }
        }
      else if(!g_fvgs[i].bullish && close > g_fvgs[i].top)
        {
         g_fvgs[i].mitigated = true;
         DrawFVGZone(g_fvgs[i]);
         if(ShowIFVG)
           {
            SMC_IFVG iv;
            iv.time = barTime;
            iv.formedBarIdx = ClosedBarPineIndex();
            iv.top = g_fvgs[i].top;
            iv.bottom = g_fvgs[i].bottom;
            iv.bullish = true;
            iv.retested = false;
            iv.mitigated = false;
            iv.drawId = NextDrawId();
            AddIFVG(iv);
            if(DrawingsFull())
               DrawIFVGZone(g_ifvgs[g_ifvgCount - 1]);
            FireAlertOnce(g_alertBarBullIFVG,
               "ICT-V: Bullish Inversion FVG formed - old bearish FVG flipped to support");
            if(DebugZones)
               Print("ICT-V IFVG BULL spawned barIdx=", iv.formedBarIdx);
           }
        }
     }

   // Pine: trim FVG pool at end of mit/spawn block (fvgMaxCount * 3)
   TrimFVGArray();
  }

// Pine IFVG MANAGEMENT section � after all IFVG spawns on this bar
void ProcessIFVGLifecycle(int shift)
  {
   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);
   int barIdx = ClosedBarPineIndex();

   // Pine IFVG MANAGEMENT � single if / else-if (retest guard on idx only; Pine lines 959-978)
   for(int i = g_ifvgCount - 1; i >= 0; i--)
     {
      if(g_ifvgs[i].mitigated)
         continue;

      bool priceInZone = (high >= g_ifvgs[i].bottom && low <= g_ifvgs[i].top);

      if(priceInZone && !g_ifvgs[i].retested && barIdx > g_ifvgs[i].formedBarIdx)
        {
         g_ifvgs[i].retested = true;
         DrawIFVGZone(g_ifvgs[i]);
        }
      else if(g_ifvgs[i].retested && barIdx > g_ifvgs[i].formedBarIdx)
        {
         if(g_ifvgs[i].bullish && close < g_ifvgs[i].bottom)
           {
            g_ifvgs[i].mitigated = true;
            DrawIFVGZone(g_ifvgs[i]);
           }
         else if(!g_ifvgs[i].bullish && close > g_ifvgs[i].top)
           {
            g_ifvgs[i].mitigated = true;
            DrawIFVGZone(g_ifvgs[i]);
           }
        }
     }

   // Pine: trim IFVG pool at end of IFVG MANAGEMENT (fvgMaxCount * 2)
   TrimIFVGArray();
  }

void UpdateOBBreakerOTEBPRLifecycle(int shift)
  {
   double close = iClose(Symbol(), Period(), shift);
   datetime barTime = iTime(Symbol(), Period(), shift);

   // OB mitigation → breaker (always tracked; ShowBreakers is display-only)
   for(int i = g_obCount - 1; i >= 0; i--)
     {
      if(g_obs[i].mitigated)
         continue;

      if(g_obs[i].bullish && close < g_obs[i].bottom)
        {
         g_obs[i].mitigated = true;
         DrawOB(g_obs[i]);
         SMC_Breaker brk;
         brk.originTime = g_obs[i].time;
         brk.createdTime = barTime;
         brk.formedBarIdx = ClosedBarPineIndex();
         brk.top = g_obs[i].top;
         brk.bottom = g_obs[i].bottom;
         brk.bullish = false;
         brk.origScore = g_obs[i].score;
         brk.retested = false;
         brk.mitigated = false;
         brk.drawId = NextDrawId();
         AddBreaker(brk);
         DrawBreakerZone(g_breakers[g_breakerCount - 1]);
         FireAlertOnce(g_alertBarBearBrk,
            "ICT-V: Bearish Breaker Block formed - failed bullish OB flipped to resistance");
         if(DebugZones)
            Print("ICT-V Breaker BEAR from bull OB");
        }
      else if(!g_obs[i].bullish && close > g_obs[i].top)
        {
         g_obs[i].mitigated = true;
         DrawOB(g_obs[i]);
         SMC_Breaker brk;
         brk.originTime = g_obs[i].time;
         brk.createdTime = barTime;
         brk.formedBarIdx = ClosedBarPineIndex();
         brk.top = g_obs[i].top;
         brk.bottom = g_obs[i].bottom;
         brk.bullish = true;
         brk.origScore = g_obs[i].score;
         brk.retested = false;
         brk.mitigated = false;
         brk.drawId = NextDrawId();
         AddBreaker(brk);
         DrawBreakerZone(g_breakers[g_breakerCount - 1]);
         FireAlertOnce(g_alertBarBullBrk,
            "ICT-V: Bullish Breaker Block formed - failed bearish OB flipped to support");
         if(DebugZones)
            Print("ICT-V Breaker BULL from bear OB");
        }
     }

   // Pine: trim OB pool at end of OB mit/spawn block (obMaxCount * 3) � before breaker mgmt
  }

// Pine OTE ZONE MANAGEMENT � after BREAKER BLOCK MANAGEMENT
void ProcessOTELifecycle(int shift)
  {
   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);

   for(int i = g_oteCount - 1; i >= 0; i--)
     {
      if(g_otes[i].invalidated)
         continue;

      if(g_otes[i].bullish)
        {
         if(low <= g_otes[i].zoneTop && close > g_otes[i].zoneBottom && !g_otes[i].triggered)
            g_otes[i].triggered = true;
         if(close < g_otes[i].legLow)
           {
            g_otes[i].invalidated = true;
            DrawOTEZone(g_otes[i]);
           }
        }
      else
        {
         if(high >= g_otes[i].zoneBottom && close < g_otes[i].zoneTop && !g_otes[i].triggered)
            g_otes[i].triggered = true;
         if(close > g_otes[i].legHigh)
           {
            g_otes[i].invalidated = true;
            DrawOTEZone(g_otes[i]);
           }
        }
     }

   // Pine OTE ZONE MANAGEMENT � trim at end of block (oteMaxCount * 2)
   TrimOTEArray();
  }

int CountActiveOBs()
  {
   int n = 0;
   for(int i = 0; i < g_obCount; i++)
      if(!g_obs[i].mitigated)
         n++;
   return(n);
  }

int CountActiveFVGs()
  {
   int n = 0;
   for(int i = 0; i < g_fvgCount; i++)
      if(!g_fvgs[i].mitigated)
         n++;
   return(n);
  }

int CountActiveIFVGs()
  {
   int n = 0;
   for(int i = 0; i < g_ifvgCount; i++)
      if(!g_ifvgs[i].mitigated)
         n++;
   return(n);
  }

int CountActiveBreakers()
  {
   int n = 0;
   for(int i = 0; i < g_breakerCount; i++)
      if(!g_breakers[i].mitigated)
         n++;
   return(n);
  }

int CountActiveBPRs()
  {
   int n = 0;
   for(int i = 0; i < g_bprCount; i++)
      if(!g_bprs[i].mitigated)
         n++;
   return(n);
  }

void LogZoneAudit()
  {
   if(!DebugZoneAudit)
      return;

   Print("========== ICT-V ZONE AUDIT (compare to TradingView panel) ==========");
   Print("Symbol=", Symbol(), " TF=", TimeframeToString(Period()),
         " broker=", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   Print("COUNTS active: OBs=", CountActiveOBs(),
         " Breakers=", CountActiveBreakers(),
         " OTEs=", CountActiveOTEs(),
         " FVGs=", CountActiveFVGs(),
         " IFVGs=", CountActiveIFVGs(),
         " BPRs=", CountActiveBPRs());

   Print("--- ORDER BLOCKS (all in pool; mitigated=Y means became breaker candidate) ---");
   for(int i = 0; i < g_obCount; i++)
     {
      string st = g_obs[i].mitigated ? "mitigated=Y" : "ACTIVE";
      Print("  OB[", i, "] ", (g_obs[i].bullish ? "BULL" : "BEAR"),
            " formed=", TimeToString(g_obs[i].time, TIME_DATE|TIME_MINUTES),
            " top=", DoubleToString(g_obs[i].top, Digits),
            " bot=", DoubleToString(g_obs[i].bottom, Digits),
            " score=", g_obs[i].score,
            " ", st,
            " sweep=", (g_obs[i].hasSweep ? "Y" : "N"),
            " disp=", (g_obs[i].hasDisplacement ? "Y" : "N"),
            " inKZ=", (g_obs[i].inKillzone ? "Y" : "N"));
     }
   if(g_obCount == 0)
      Print("  (none)");

   Print("--- BREAKERS ---");
   for(int i = 0; i < g_breakerCount; i++)
     {
      string st = g_breakers[i].mitigated ? "mitigated=Y" : "ACTIVE";
      Print("  BRK[", i, "] ", (g_breakers[i].bullish ? "BULL" : "BEAR"),
            " obTime=", TimeToString(g_breakers[i].originTime, TIME_DATE|TIME_MINUTES),
            " created=", TimeToString(g_breakers[i].createdTime, TIME_DATE|TIME_MINUTES),
            " barIdx=", g_breakers[i].formedBarIdx,
            " top=", DoubleToString(g_breakers[i].top, Digits),
            " bot=", DoubleToString(g_breakers[i].bottom, Digits),
            " retested=", (g_breakers[i].retested ? "Y" : "N"),
            " ", st);
     }
   if(g_breakerCount == 0)
      Print("  (none)");

   Print("--- OTE ZONES ---");
   for(int i = 0; i < g_oteCount; i++)
     {
      string st = g_otes[i].invalidated ? "invalidated=Y" : "ACTIVE";
      Print("  OTE[", i, "] ", (g_otes[i].bullish ? "BULL" : "BEAR"),
            " time=", TimeToString(g_otes[i].time, TIME_DATE|TIME_MINUTES),
            " zTop=", DoubleToString(g_otes[i].zoneTop, Digits),
            " zBot=", DoubleToString(g_otes[i].zoneBottom, Digits),
            " trig=", (g_otes[i].triggered ? "Y" : "N"),
            " ", st);
     }
   if(g_oteCount == 0)
      Print("  (none)");

   Print("--- FVGs ---");
   for(int i = 0; i < g_fvgCount; i++)
     {
      string st = g_fvgs[i].mitigated ? "mitigated=Y" : "ACTIVE";
      Print("  FVG[", i, "] ", (g_fvgs[i].bullish ? "BULL" : "BEAR"),
            " time=", TimeToString(g_fvgs[i].time, TIME_DATE|TIME_MINUTES),
            " top=", DoubleToString(g_fvgs[i].top, Digits),
            " bot=", DoubleToString(g_fvgs[i].bottom, Digits),
            " ", st);
     }
   if(g_fvgCount == 0)
      Print("  (none)");

   Print("--- IFVGs ---");
   for(int i = 0; i < g_ifvgCount; i++)
     {
      string st = g_ifvgs[i].mitigated ? "mitigated=Y" : "ACTIVE";
      Print("  IFVG[", i, "] ", (g_ifvgs[i].bullish ? "BULL" : "BEAR"),
            " time=", TimeToString(g_ifvgs[i].time, TIME_DATE|TIME_MINUTES),
            " barIdx=", g_ifvgs[i].formedBarIdx,
            " top=", DoubleToString(g_ifvgs[i].top, Digits),
            " bot=", DoubleToString(g_ifvgs[i].bottom, Digits),
            " retested=", (g_ifvgs[i].retested ? "Y" : "N"),
            " ", st);
     }
   if(g_ifvgCount == 0)
      Print("  (none)");

   Print("========== END ZONE AUDIT � match formed/created times to TV OB/FVG boxes ==========");
  }

int BestOBScore()
  {
   int best = 0;
   for(int i = 0; i < g_obCount; i++)
     {
      if(!g_obs[i].mitigated && g_obs[i].score > best)
         best = g_obs[i].score;
     }
   return(best);
  }

string DashBreakText(string brk)
  {
   string s = brk;
   if(StringFind(s, " ^") >= 0)
      StringReplace(s, " ^", " ^");
   else if(StringFind(s, " v") >= 0)
      StringReplace(s, " v", " v");
   return(s);
  }

string BestOBStarString(int score)
  {
   int stars = score >= 7 ? 5 : score >= 5 ? 4 : score >= 4 ? 3 : score >= 3 ? 2 : score > 0 ? 1 : 0;
   if(stars <= 0)
      return("---");
   string s = "";
   for(int i = 0; i < 5; i++)
      s += (i < stars) ? "*" : " ";
   return(s);
  }

color BestOBStarColor(int score)
  {
   int stars = score >= 7 ? 5 : score >= 5 ? 4 : score >= 4 ? 3 : score >= 3 ? 2 : score > 0 ? 1 : 0;
   if(stars >= 4) return(clrLimeGreen);
   if(stars >= 3) return(clrGold);
   if(stars >= 1) return(clrTomato);
   return(clrSilver);
  }

string SignalBarsAgoText()
  {
   if(g_lastSignalBarCounter < 0)
      return("");
   // Pine panel (islast): barsAgo = bar_index - lastSigBar
   int barsAgo = PineBarIndex() - g_lastSignalBarCounter;
   if(barsAgo <= 0)
      return(" (NOW)");
   return(" (" + IntegerToString(barsAgo) + " bars ago)");
  }

//+------------------------------------------------------------------+
//| CISD �" Change in State of Delivery (Pine sigGroup)               |
//+------------------------------------------------------------------+
void UpdateCISD(int shift)
  {
   double o = iOpen(Symbol(), Period(), shift);
   double c = iClose(Symbol(), Period(), shift);
   if(c < o)
     {
      g_lastBearishOpen = o;
      g_hasBearishOpen = true;
     }
   if(c > o)
     {
      g_lastBullishOpen = o;
      g_hasBullishOpen = true;
     }
  }

bool BullishCISD(int shift)
  {
   if(!g_hasBearishOpen)
      return(false);
   return(iClose(Symbol(), Period(), shift) > g_lastBearishOpen);
  }

bool BearishCISD(int shift)
  {
   if(!g_hasBullishOpen)
      return(false);
   return(iClose(Symbol(), Period(), shift) < g_lastBullishOpen);
  }

//+------------------------------------------------------------------+
//| Pine v1.6 signal TP � nearest swing pivot beyond close            |
//+------------------------------------------------------------------+
double PineSignalTP(bool isBuy, double close, int maxBarIdx = -1)
  {
   if(maxBarIdx < 0)
      maxBarIdx = ClosedBarPineIndex();

   double best = 0;
   for(int j = g_swingCount - 1; j >= MathMax(0, g_swingCount - 20); j--)
     {
      // Only pivots confirmed on or before the signal bar (Pine pool state at bar close)
      if(g_swings[j].barIdx > maxBarIdx)
         continue;
      if(isBuy && g_swings[j].isHigh && g_swings[j].price > close)
        {
         if(best == 0 || g_swings[j].price < best)
            best = g_swings[j].price;
        }
      if(!isBuy && !g_swings[j].isHigh && g_swings[j].price < close)
        {
         if(best == 0 || g_swings[j].price > best)
            best = g_swings[j].price;
        }
     }
   return(best);
  }

//+------------------------------------------------------------------+
//| Signal engine � Pine scoring max 11, separate long/short SL/TP   |
//+------------------------------------------------------------------+
bool EvaluateLongSignal(int shift, double &sl, double &tp, int &score)
  {
   sl = 0;
   tp = 0;
   score = 0;

   double close = iClose(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);
   bool atOB = false, atFVG = false, atOTE = false, atBrk = false;
   double bestSL = 0;

   for(int i = g_obCount - 1; i >= MathMax(0, g_obCount - 10); i--)
     {
      if(g_obs[i].mitigated || !g_obs[i].bullish)
         continue;
      // Pine signal touch: raw high/low/close (not normalized � v1.91 H4 bar parity)
      if(low <= g_obs[i].top && close > g_obs[i].bottom)
        {
         atOB = true;
         bestSL = (bestSL == 0) ? g_obs[i].bottom : MathMin(bestSL, g_obs[i].bottom);
         break;
        }
     }

   for(int i = g_fvgCount - 1; i >= MathMax(0, g_fvgCount - 10); i--)
     {
      if(g_fvgs[i].mitigated || !g_fvgs[i].bullish)
         continue;
      if(low <= g_fvgs[i].top && close > g_fvgs[i].bottom)
        {
         atFVG = true;
         if(bestSL == 0)
            bestSL = g_fvgs[i].bottom;
         break;
        }
     }

   for(int i = g_oteCount - 1; i >= MathMax(0, g_oteCount - 5); i--)
     {
      if(g_otes[i].invalidated || !g_otes[i].bullish)
         continue;
      if(low <= g_otes[i].zoneTop && close > g_otes[i].zoneBottom)
        {
         atOTE = true;
         if(bestSL == 0)
            bestSL = g_otes[i].legLow;
         break;
        }
     }

   for(int i = g_breakerCount - 1; i >= MathMax(0, g_breakerCount - 5); i--)
     {
      if(g_breakers[i].mitigated || !g_breakers[i].bullish || g_breakers[i].retested)
         continue;
      if(low <= g_breakers[i].top && close > g_breakers[i].bottom)
        {
         atBrk = true;
         if(bestSL == 0)
            bestSL = g_breakers[i].bottom;
         break;
        }
     }

   bool touching = atOB || atFVG || atOTE || atBrk;
   if(!touching)
      return(false);

   bool longHTF = HTFAligned(true);
   bool longKZ = g_inKillzoneNow;
   bool longDiscount = (g_lastSwingHigh > 0 && g_lastSwingLow > 0) ?
                       IsDiscount(close, g_lastSwingHigh, g_lastSwingLow) : false;
   bool longStruct = g_swingBullish;
   bool bullCISD = BullishCISD(shift);

   if(atOB)
      score += 2;
   if(atFVG)
      score += 1;
   if(atOTE)
      score += 2;
   if(atBrk)
      score += 1;
   if(longHTF)
      score += 1;
   if(longKZ)
      score += 1;
   if(longDiscount)
      score += 1;
   if(longStruct)
      score += 1;
   if(bullCISD)
      score += 1;

   if(score < MinSignalScore)
      return(false);
   if(RequireHTFAlign && !longHTF)
      return(false);
   if(RequireKillzone && !longKZ)
      return(false);
   if(RequireCISD && !bullCISD)
      return(false);

   // Pine: longSignal only true when cooldown satisfied (lines 1618-1620)
   bool longCooldownOK = (g_lastLongBarCounter < 0 ||
      (ClosedBarPineIndex() - g_lastLongBarCounter) >= SignalCooldownBars);
   if(DebugCooldownRejects && !longCooldownOK)
     {
      Print("ICT-V COOLDOWN-BLOCKED LONG candidate barIdx=", ClosedBarPineIndex(),
            " time=", TimeToString(iTime(Symbol(), Period(), shift), TIME_DATE | TIME_MINUTES),
            " score=", score,
            " lastLongBarCounter=", g_lastLongBarCounter,
            " diff=", (ClosedBarPineIndex() - g_lastLongBarCounter),
            " cooldownReq=", SignalCooldownBars);
     }
   if(!longCooldownOK)
      return(false);

   sl = bestSL;
   if(sl > 0 && sl >= close)
      sl = 0;
   tp = PineSignalTP(true, close, ClosedBarPineIndex());
   return(true);
  }

bool EvaluateShortSignal(int shift, double &sl, double &tp, int &score)
  {
   sl = 0;
   tp = 0;
   score = 0;

   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   bool atOB = false, atFVG = false, atOTE = false, atBrk = false;
   double bestSL = 0;

   for(int i = g_obCount - 1; i >= MathMax(0, g_obCount - 10); i--)
     {
      if(g_obs[i].mitigated || g_obs[i].bullish)
         continue;
      // Pine signal touch: raw high/close (not normalized � v1.91 H4 bar parity)
      if(high >= g_obs[i].bottom && close < g_obs[i].top)
        {
         atOB = true;
         bestSL = (bestSL == 0) ? g_obs[i].top : MathMax(bestSL, g_obs[i].top);
         break;
        }
     }

   for(int i = g_fvgCount - 1; i >= MathMax(0, g_fvgCount - 10); i--)
     {
      if(g_fvgs[i].mitigated || g_fvgs[i].bullish)
         continue;
      if(high >= g_fvgs[i].bottom && close < g_fvgs[i].top)
        {
         atFVG = true;
         if(bestSL == 0)
            bestSL = g_fvgs[i].top;
         break;
        }
     }

   for(int i = g_oteCount - 1; i >= MathMax(0, g_oteCount - 5); i--)
     {
      if(g_otes[i].invalidated || g_otes[i].bullish)
         continue;
      if(high >= g_otes[i].zoneBottom && close < g_otes[i].zoneTop)
        {
         atOTE = true;
         if(bestSL == 0)
            bestSL = g_otes[i].legHigh;
         break;
        }
     }

   for(int i = g_breakerCount - 1; i >= MathMax(0, g_breakerCount - 5); i--)
     {
      if(g_breakers[i].mitigated || g_breakers[i].bullish || g_breakers[i].retested)
         continue;
      if(high >= g_breakers[i].bottom && close < g_breakers[i].top)
        {
         atBrk = true;
         if(bestSL == 0)
            bestSL = g_breakers[i].top;
         break;
        }
     }

   bool touching = atOB || atFVG || atOTE || atBrk;
   if(!touching)
      return(false);

   bool shortHTF = HTFAligned(false);
   bool shortKZ = g_inKillzoneNow;
   bool shortPremium = (g_lastSwingHigh > 0 && g_lastSwingLow > 0) ?
                       IsPremium(close, g_lastSwingHigh, g_lastSwingLow) : false;
   bool shortStruct = !g_swingBullish;
   bool bearCISD = BearishCISD(shift);

   if(atOB)
      score += 2;
   if(atFVG)
      score += 1;
   if(atOTE)
      score += 2;
   if(atBrk)
      score += 1;
   if(shortHTF)
      score += 1;
   if(shortKZ)
      score += 1;
   if(shortPremium)
      score += 1;
   if(shortStruct)
      score += 1;
   if(bearCISD)
      score += 1;

   if(score < MinSignalScore)
      return(false);
   if(RequireHTFAlign && !shortHTF)
      return(false);
   if(RequireKillzone && !shortKZ)
      return(false);
   if(RequireCISD && !bearCISD)
      return(false);

   // Pine: shortSignal only true when cooldown satisfied (lines 1716-1718)
   bool shortCooldownOK = (g_lastShortBarCounter < 0 ||
      (ClosedBarPineIndex() - g_lastShortBarCounter) >= SignalCooldownBars);
   if(DebugCooldownRejects && !shortCooldownOK)
     {
      Print("ICT-V COOLDOWN-BLOCKED SHORT candidate barIdx=", ClosedBarPineIndex(),
            " time=", TimeToString(iTime(Symbol(), Period(), shift), TIME_DATE | TIME_MINUTES),
            " score=", score,
            " lastShortBarCounter=", g_lastShortBarCounter,
            " diff=", (ClosedBarPineIndex() - g_lastShortBarCounter),
            " cooldownReq=", SignalCooldownBars);
     }
   if(!shortCooldownOK)
      return(false);

   sl = bestSL;
   if(sl > 0 && sl <= close)
      sl = 0;
   tp = PineSignalTP(false, close, ClosedBarPineIndex());
   return(true);
  }

void LogClosedBarDiagnostics(int shift, bool longSignal, int longScore,
                             bool shortSignal, int shortScore)
  {
   if(!DebugLogClosedBars)
      return;
   string longState = longSignal ? "SIGNAL" : (IntegerToString(longScore) + "/" +
                        IntegerToString(MinSignalScore));
   string shortState = shortSignal ? "SIGNAL" : (IntegerToString(shortScore) + "/" +
                         IntegerToString(MinSignalScore));
   Print("ICT-V BAR ", Symbol(), " ", TimeframeToString(Period()),
         " closed ", TimeToString(iTime(Symbol(), Period(), shift), TIME_DATE|TIME_MINUTES),
         " | L=", longState, " S=", shortState,
         " | structure=", (g_swingBullish ? "BULL" : "BEAR"),
         " HTF=", (UseHTF ? (g_htfBullish ? "BULL" : "BEAR") : "OFF"),
         " KZ=", (IsInKillzone(iTime(Symbol(), Period(), shift)) ? "ACTIVE" : "off"),
         " zone=", g_pdZoneStr);
  }

//+------------------------------------------------------------------+
//| News filter � self-contained (fail-safe when feed unavailable)    |
//+------------------------------------------------------------------+
string NewsTagValue(string block, string tag)
  {
   string openTag = "<" + tag + ">";
   string closeTag = "</" + tag + ">";
   int s = StringFind(block, openTag);
   if(s < 0)
      return("");
   s += StringLen(openTag);
   int e = StringFind(block, closeTag, s);
   if(e < 0)
      return("");
   string val = StringSubstr(block, s, e - s);
   int cdataStart = StringFind(val, "<![CDATA[");
   if(cdataStart >= 0)
     {
      cdataStart += 9;
      int cdataEnd = StringFind(val, "]]>", cdataStart);
      if(cdataEnd > cdataStart)
         val = StringSubstr(val, cdataStart, cdataEnd - cdataStart);
     }
   StringTrimLeft(val);
   StringTrimRight(val);
   return(val);
  }

int NewsParseImpactLevel(string impactStr)
  {
   string s = impactStr;
   StringToLower(s);
   if(StringFind(s, "high") >= 0)
      return(2);
   if(StringFind(s, "medium") >= 0 || StringFind(s, "moderate") >= 0)
      return(1);
   return(0);
  }

bool NewsImpactBlocks(int impactLevel)
  {
   if(impactLevel >= 2 && BlockRedNews)
      return(true);
   if(impactLevel == 1 && BlockOrangeNews)
      return(true);
   return(false);
  }

bool NewsCurrencyBlocks(string ccy)
  {
   if(!NewsOnlyUSD)
      return(true);
   return(ccy == "USD");
  }

datetime NewsParseUtcEventTime(string dateStr, string timeStr)
  {
   string tl = timeStr;
   StringToLower(tl);
   if(StringLen(tl) == 0)
      return(0);
   if(StringFind(tl, "all day") >= 0)
      return(0);
   if(StringFind(tl, "tentative") >= 0)
      return(0);
   if(StringFind(tl, "day 1") >= 0 || StringFind(tl, "day 2") >= 0 || StringFind(tl, "day 3") >= 0)
      return(0);

   string dateParts[];
   if(StringSplit(dateStr, '-', dateParts) != 3)
      return(0);
   int month = (int)StringToInteger(dateParts[0]);
   int day   = (int)StringToInteger(dateParts[1]);
   int year  = (int)StringToInteger(dateParts[2]);
   if(month < 1 || month > 12 || day < 1 || day > 31 || year < 2000)
      return(0);

   bool isPM = (StringFind(tl, "pm") >= 0);
   bool isAM = (StringFind(tl, "am") >= 0);
   StringReplace(tl, "am", "");
   StringReplace(tl, "pm", "");
   StringTrimLeft(tl);
   StringTrimRight(tl);

   int colon = StringFind(tl, ":");
   if(colon < 0)
      return(0);
   int hour = (int)StringToInteger(StringSubstr(tl, 0, colon));
   int minute = (int)StringToInteger(StringSubstr(tl, colon + 1));
   if(hour < 0 || hour > 23 || minute < 0 || minute > 59)
      return(0);
   if(isPM && hour < 12)
      hour += 12;
   if(isAM && hour == 12)
      hour = 0;

   string dtStr = StringFormat("%04d.%02d.%02d %02d:%02d", year, month, day, hour, minute);
   datetime utcT = StrToTime(dtStr);
   if(utcT <= 0)
      return(0);
   return(utcT);
  }

void FetchNewsCalendar()
  {
   if(IsTesting()) return;  // WebRequest not supported in strategy tester
   ArrayResize(g_newsEvents, 0);
   g_newsEventCount = 0;

   char post[];
   char result[];
   string resultHeaders;
   ArrayResize(post, 0);
   ArrayResize(result, 0);

   ResetLastError();
   int httpCode = WebRequest("GET", NewsCalendarURL, "", "", 5000, post, 0, result, resultHeaders);
   g_newsLastFetch = TimeCurrent();

   if(httpCode != 200 || ArraySize(result) <= 0)
     {
      Print("ICT-V news: fetch failed err=", GetLastError(), " http=", httpCode,
            " filter inactive this cycle");
      return;
     }

   string body = CharArrayToString(result);
   if(StringLen(body) < 20)
     {
      Print("ICT-V news: fetch failed err=", GetLastError(), " http=", httpCode,
            " filter inactive this cycle");
      return;
     }

   int pos = 0;
   while(true)
     {
      int start = StringFind(body, "<event>", pos);
      if(start < 0)
         break;
      int end = StringFind(body, "</event>", start);
      if(end < 0)
         break;
      string block = StringSubstr(body, start, end - start + 8);

      string title = NewsTagValue(block, "title");
      string country = NewsTagValue(block, "country");
      string currency = NewsTagValue(block, "currency");
      string impactStr = NewsTagValue(block, "impact");
      string dateStr = NewsTagValue(block, "date");
      string timeStr = NewsTagValue(block, "time");

      static bool s_loggedRawOnce = false;
      if(DebugNews && !s_loggedRawOnce)
        {
         Print("ICT-V news RAW first event: date='", dateStr, "' time='", timeStr,
               "' title='", title, "'");
         s_loggedRawOnce = true;
        }

      string ccy = country;
      if(StringLen(ccy) == 0)
         ccy = currency;
      if(StringLen(ccy) > 3)
         ccy = StringSubstr(ccy, 0, 3);

      int impactLevel = NewsParseImpactLevel(impactStr);
      if(!NewsImpactBlocks(impactLevel))
        {
         pos = end + 8;
         continue;
        }
      if(!NewsCurrencyBlocks(ccy))
        {
         pos = end + 8;
         continue;
        }

      datetime utcT = NewsParseUtcEventTime(dateStr, timeStr);
      if(utcT <= 0)
        {
         pos = end + 8;
         continue;
        }

      NewsEvent ev;
      ev.t = utcT + ServerUtcOffsetSeconds();
      ev.impact = impactLevel;
      ev.ccy = ccy;

      g_newsEventCount++;
      ArrayResize(g_newsEvents, g_newsEventCount);
      g_newsEvents[g_newsEventCount - 1] = ev;

      if(DebugNews)
         Print("ICT-V news event: raw_feed=", TimeToString(utcT, TIME_DATE|TIME_MINUTES),
               " -> broker=", TimeToString(ev.t, TIME_DATE|TIME_MINUTES),
               " offset_hrs=", DoubleToString(ServerUtcOffsetSeconds()/3600.0, 1),
               " ccy=", ev.ccy, " impact=", ev.impact);

      pos = end + 8;
     }

   Print("ICT-V news: loaded ", g_newsEventCount, " blocking event(s)");
   if(DebugNews)
      Print("ICT-V news: parsed ", g_newsEventCount, " blocking events; broker now=",
            TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
            " GMT now=", TimeToString(TimeGMT(), TIME_DATE|TIME_MINUTES));
  }

bool IsNewsBlackout(datetime now)
  {
   if(!UseNewsFilter)
      return(false);
   if(g_newsEventCount <= 0)
      return(false);

   int beforeSec = NewsMinutesBefore * 60;
   int afterSec = NewsMinutesAfter * 60;
   for(int i = 0; i < g_newsEventCount; i++)
     {
      datetime t = g_newsEvents[i].t;
      if(now >= t - beforeSec && now <= t + afterSec)
         return(true);
     }
   return(false);
  }

void MaybeRefreshNews()
  {
   if(!UseNewsFilter)
      return;
   if(g_newsLastFetch == 0 || TimeCurrent() - g_newsLastFetch >= NewsRefreshMinutes * 60)
      FetchNewsCalendar();
  }

//+------------------------------------------------------------------+
//| Order execution + management                                     |
//+------------------------------------------------------------------+
bool IsOurOrder()
  {
   return(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber);
  }

int CountOpenTrades(int orderType)
  {
   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(!IsOurOrder())
         continue;
      if(orderType < 0 || OrderType() == orderType)
         n++;
     }
   return(n);
  }

void CloseAllOurTrades(string reason = "flatten")
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(!IsOurOrder())
         continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;
      if(IsTradeContextBusy())
        {
         Print("ICT-V ", reason, " skipped #", OrderTicket(), ": trade context busy");
         continue;
        }
      RefreshRates();
      double price = (OrderType() == OP_BUY) ? Bid : Ask;
      if(!OrderClose(OrderTicket(), OrderLots(), price, Slippage, clrNONE))
         Print("ICT-V ", reason, " close failed #", OrderTicket(), " err=", GetLastError());
      else
         Print("ICT-V ", reason, " closed #", OrderTicket());
     }
  }

//+------------------------------------------------------------------+
//| Risk circuit-breaker � daily loss / equity halt (stateless switch) |
//+------------------------------------------------------------------+
void CB_UpdateDay()
  {
   // Re-baselines on attach mid-day too: day-start = balance at first call of broker day (or attach)
   string dayKey = TimeToString(TimeCurrent(), TIME_DATE);
   if(dayKey != g_cbCurrentDay)
     {
      g_cbCurrentDay = dayKey;
      g_cbDayStartBalance = AccountBalance();
      g_cbTrippedToday = false;
     }
  }

double CB_DailyRealizedPnL()
  {
   string dayKey = g_cbCurrentDay;
   double pnl = 0;
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderMagicNumber() != MagicNumber)
         continue;
      if(OrderSymbol() != Symbol())
         continue;
      if(TimeToString(OrderCloseTime(), TIME_DATE) != dayKey)
         continue;
      pnl += OrderProfit() + OrderSwap() + OrderCommission();
     }
   return(pnl);
  }

double CB_DailyRealizedPnL_Cached()
  {
   string dayKey = g_cbCurrentDay;
   int histTotal = OrdersHistoryTotal();
   if(histTotal != g_cbLastHistTotal || dayKey != g_cbCachedDay)
     {
      g_cbCachedRealizedPnL = CB_DailyRealizedPnL();
      g_cbLastHistTotal = histTotal;
      g_cbCachedDay = dayKey;
     }
   return(g_cbCachedRealizedPnL);
  }

bool CB_IsTripped()
  {
   static bool     s_wasTripped = false;
   static datetime s_lastPrintBar = 0;

   if(!UseCircuitBreaker)
     {
      g_cbTrippedToday = false;
      return(false);
     }

   // Total drawdown check � permanent halt, does not reset on day rollover
   if(CB_MaxTotalLossPct > 0 && g_cbInitialBalance > 0)
     {
      double totalLossPct = (g_cbInitialBalance - AccountEquity()) / g_cbInitialBalance * 100.0;
      if(totalLossPct >= CB_MaxTotalLossPct)
        {
         if(!g_cbTotalTripped)
           {
            g_cbTotalTripped = true;
            Print("ICT-V circuit-breaker TOTAL DRAWDOWN TRIPPED: loss=", DoubleToString(totalLossPct, 2),
                  "% initialBal=", DoubleToString(g_cbInitialBalance, 2),
                  " equity=", DoubleToString(AccountEquity(), 2),
                  " (EA permanently halted � re-attach to reset)");
            if(CB_FlattenOnTrip)
               CloseAllOurTrades("total-DD breaker");
           }
         return(true);
        }
     }

   CB_UpdateDay();

   if(CB_HaltUntilNextDay && g_cbTrippedToday)
     {
      s_wasTripped = true;
      return(true);
     }

   double dailyPnL = CB_DailyRealizedPnL_Cached();
   double lossLimit = 0;
   if(CB_UsePercentOfBal)
      lossLimit = g_cbDayStartBalance * CB_MaxDailyLossPct / 100.0;
   else
      lossLimit = CB_MaxDailyLossMoney;

   bool tripped = false;
   if(lossLimit > 0 && (-dailyPnL) >= lossLimit)
      tripped = true;

   if(!tripped && CB_UseEquityStop)
     {
      double equityFloor = g_cbDayStartBalance * (1.0 - CB_EquityStopPct / 100.0);
      if(AccountEquity() <= equityFloor)
         tripped = true;
     }

   if(!tripped)
     {
      s_wasTripped = false;
      return(false);
     }

   bool newlyTripped = !s_wasTripped;

   if(CB_HaltUntilNextDay)
     {
      if(!g_cbTrippedToday)
        {
         g_cbTrippedToday = true;
         Print("ICT-V circuit-breaker TRIPPED: dailyPnL=", DoubleToString(dailyPnL, 2),
               " equity=", DoubleToString(AccountEquity(), 2),
               " dayStartBal=", DoubleToString(g_cbDayStartBalance, 2),
               " (new entries halted)");
        }
     }
   else
     {
      datetime barT = iTime(Symbol(), Period(), 0);
      if(barT != s_lastPrintBar)
        {
         Print("ICT-V circuit-breaker TRIPPED: dailyPnL=", DoubleToString(dailyPnL, 2),
               " equity=", DoubleToString(AccountEquity(), 2),
               " dayStartBal=", DoubleToString(g_cbDayStartBalance, 2),
               " (new entries halted)");
         s_lastPrintBar = barT;
        }
     }

   if(CB_FlattenOnTrip && newlyTripped)
      CloseAllOurTrades("circuit-breaker");

   s_wasTripped = true;
   return(true);
  }

//+------------------------------------------------------------------+
//| Trading hours / EOD � all times are BROKER SERVER TIME           |
//| (TimeCurrent / TimeHour / TimeMinute), NOT NY killzone time.     |
//+------------------------------------------------------------------+
int TH_BrokerMinOfDay()
  {
   return(TimeHour(TimeCurrent()) * 60 + TimeMinute(TimeCurrent()));
  }

string TH_DayString(int dayOfWeek)
  {
   switch(dayOfWeek)
     {
      case 0:  return(TH_Sunday);
      case 1:  return(TH_Monday);
      case 2:  return(TH_Tuesday);
      case 3:  return(TH_Wednesday);
      case 4:  return(TH_Thursday);
      case 5:  return(TH_Friday);
      case 6:  return(TH_Saturday);
      default: return("");
     }
  }

bool TH_ParseTimeToken(string s, int &minOut)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   if(StringLen(s) == 0)
      return(false);

   int colon = StringFind(s, ":");
   int hour = 0;
   int minute = 0;
   if(colon < 0)
     {
      hour = (int)StringToInteger(s);
      minute = 0;
     }
   else
     {
      hour = (int)StringToInteger(StringSubstr(s, 0, colon));
      minute = (int)StringToInteger(StringSubstr(s, colon + 1));
     }

   if(hour < 0 || hour > 23 || minute < 0 || minute > 59)
      return(false);

   minOut = hour * 60 + minute;
   return(true);
  }

bool TH_ParseWindowContains(string windows, int nowMin, bool &parseError)
  {
   parseError = false;
   string trimmed = windows;
   StringTrimLeft(trimmed);
   StringTrimRight(trimmed);
   if(StringLen(trimmed) == 0)
      return(false);

   string parts[];
   int n = StringSplit(trimmed, ',', parts);
   if(n <= 0)
     {
      parseError = true;
      return(false);
     }

   for(int i = 0; i < n; i++)
     {
      string win = parts[i];
      StringTrimLeft(win);
      StringTrimRight(win);
      if(StringLen(win) == 0)
         continue;

      int dash = StringFind(win, "-");
      if(dash < 0)
        {
         parseError = true;
         continue;
        }

      string startStr = StringSubstr(win, 0, dash);
      string endStr = StringSubstr(win, dash + 1);
      int startMin = 0;
      int endMin = 0;
      if(!TH_ParseTimeToken(startStr, startMin) || !TH_ParseTimeToken(endStr, endMin))
        {
         parseError = true;
         continue;
        }

      if(startMin >= endMin)
        {
         parseError = true;
         continue;
        }

      if(nowMin >= startMin && nowMin < endMin)
         return(true);
     }
   return(false);
  }

bool TH_EntryAllowed()
  {
   if(!UseTradingHours)
      return(true);

   string dayStr = TH_DayString(DayOfWeek());
   StringTrimLeft(dayStr);
   StringTrimRight(dayStr);
   if(StringLen(dayStr) == 0)
      return(false);

   bool parseError = false;
   bool inWin = TH_ParseWindowContains(dayStr, TH_BrokerMinOfDay(), parseError);

   if(parseError)
     {
      static string s_warnedDayStr = "";
      if(dayStr != s_warnedDayStr)
        {
         Print("ICT-V trading hours: malformed window '", dayStr,
               "' � fail-safe ALLOW for today");
         s_warnedDayStr = dayStr;
        }
      return(true);
     }

   return(inWin);
  }

bool TH_ParseEODMinutes(int &eodMin)
  {
   return(TH_ParseTimeToken(EODFlattenTime, eodMin));
  }

void TH_HandleEOD()
  {
   if(!UseEODFlatten)
      return;

   int eodMin = 0;
   if(!TH_ParseEODMinutes(eodMin))
     {
      static bool s_warnedEOD = false;
      if(!s_warnedEOD)
        {
         Print("ICT-V EOD: malformed EODFlattenTime '", EODFlattenTime, "'");
         s_warnedEOD = true;
        }
      return;
     }

   string currentDayKey = TimeToString(TimeCurrent(), TIME_DATE);
   if(TH_BrokerMinOfDay() >= eodMin && g_thEodFlattenedDay != currentDayKey)
     {
      CloseAllOurTrades("EOD flatten");
      g_thEodFlattenedDay = currentDayKey;
      Print("ICT-V EOD flatten executed at broker ", EODFlattenTime,
            " day=", currentDayKey);
     }
  }

bool TH_PostEODBlock()
  {
   if(!UseEODFlatten || !EODBlockAfterFlatten)
      return(false);

   int eodMin = 0;
   if(!TH_ParseEODMinutes(eodMin))
      return(false);

   return(TH_BrokerMinOfDay() >= eodMin);
  }

double CalcLotSize(double slPrice, bool isBuy)
  {
   if(!UseRiskPercent || slPrice <= 0)
      return(LotSize);

   double entry = isBuy ? Ask : Bid;
   double slDist = MathAbs(entry - slPrice);
   if(slDist <= 0)
      return(LotSize);

   double tickVal = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   if(tickSize <= 0 || tickVal <= 0)
      return(LotSize);

   double riskMoney = AccountBalance() * RiskPercent / 100.0;
   double lots = riskMoney / (slDist / tickSize * tickVal);

   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);
   lots = MathFloor(lots / step) * step;
   if(lots < minLot)
      lots = minLot;
   if(lots > maxLot)
      lots = maxLot;
   return(NormalizeDouble(lots, 2));
  }

bool SpreadOK()
  {
   if(MaxSpreadPoints <= 0)
      return(true);
   return((int)MarketInfo(Symbol(), MODE_SPREAD) <= MaxSpreadPoints);
  }

bool OpenTrade(bool isBuy, double sl, double tp, int score)
  {
   if(g_bootstrapping || !EnableTrading)
      return(false);
   if(!IsTradeAllowed())
     { Print("ICT-V trade skipped: auto trading is disabled in MT4 toolbar"); return(false); }
   if(IsTradeContextBusy())
     { Print("ICT-V trade skipped: trade context busy"); return(false); }

   if(MaxPositionsPerDirection > 0)
     {
      if(isBuy && CountOpenTrades(OP_BUY) >= MaxPositionsPerDirection)
         return(false);
      if(!isBuy && CountOpenTrades(OP_SELL) >= MaxPositionsPerDirection)
         return(false);
     }

   if(UseSignalSLTP && sl <= 0)
     {
      Print("ICT-V trade skipped: valid signal but no SL");
      return(false);
     }

   if(!SpreadOK())
     {
      Print("ICT-V trade skipped: spread ", (int)MarketInfo(Symbol(), MODE_SPREAD),
            " > max ", MaxSpreadPoints);
      return(false);
     }

   double price = isBuy ? Ask : Bid;

   if(!PineExactSignals && UseSignalSLTP && sl > 0 && tp <= 0 && FallbackTP_RR > 0)
     {
      double risk = MathAbs(price - sl);
      if(risk > 0)
         tp = isBuy ? price + risk * FallbackTP_RR : price - risk * FallbackTP_RR;
     }

   if(RequireTP && UseSignalSLTP && tp <= 0)
     {
      Print("ICT-V trade blocked: no valid TP");
      return(false);
     }

   bool useSL = (sl > 0);
   bool useTP = (tp > 0);
   if(useTP)
     {
      if(isBuy && tp <= price)
         useTP = false;
      else if(!isBuy && tp >= price)
         useTP = false;
      if(RequireTP && !useTP)
        {
         Print("ICT-V trade blocked: TP on wrong side of entry");
         return(false);
        }
     }

   if(useSL)
     {
      if(SLBufferPoints > 0 && !PineExactSignals)
         sl = NormalizeDouble(sl - (isBuy ? SLBufferPoints : -SLBufferPoints) * Point, Digits);
      else
         sl = NormalizeDouble(sl, Digits);
     }
   if(useTP)
      tp = NormalizeDouble(tp, Digits);

   double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   if(useSL)
     {
      if(isBuy && price - sl < stopLevel)
         sl = NormalizeDouble(price - stopLevel - Point, Digits);
      else if(!isBuy && sl - price < stopLevel)
         sl = NormalizeDouble(price + stopLevel + Point, Digits);
     }
   if(useTP)
     {
      if(isBuy && tp - price < stopLevel)
         tp = NormalizeDouble(price + stopLevel + Point, Digits);
      else if(!isBuy && price - tp < stopLevel)
         tp = NormalizeDouble(price - stopLevel - Point, Digits);
     }

   double lots = CalcLotSize(useSL ? sl : 0, isBuy);

   int type = isBuy ? OP_BUY : OP_SELL;
   string cmt = StringFormat("ICT-V score=%d/11 sl0=%s lots0=%s",
                             score,
                             DoubleToString(useSL ? sl : 0.0, Digits),
                             DoubleToString(lots, 2));

   if(AccountFreeMarginCheck(Symbol(), type, lots) < 0)
     { Print("ICT-V trade skipped: insufficient free margin=", DoubleToString(AccountFreeMargin(), 2)); return(false); }
   RefreshRates();
   price = isBuy ? Ask : Bid;
   int ticket = -1;
   for(int attempt = 1; attempt <= 3 && ticket < 0; attempt++)
     {
      if(attempt > 1) { RefreshRates(); price = isBuy ? Ask : Bid; }
      ticket = OrderSend(Symbol(), type, lots, price, Slippage,
                         ECNMode ? 0 : (useSL ? sl : 0),
                         ECNMode ? 0 : (useTP ? tp : 0),
                         cmt, MagicNumber, 0, isBuy ? clrGreen : clrRed);
      if(ticket < 0)
        {
         int err = GetLastError();
         Print("ICT-V OrderSend attempt ", attempt, "/3 err=", err,
               " ", (isBuy ? "BUY" : "SELL"), " lots=", lots, " SL=", sl, " TP=", tp);
         if(err != 138 && err != 136 && err != 4 && err != 128 && err != 146) break;
         Sleep(100);
        }
     }
   if(ticket < 0) return(false);
   if(ECNMode && (useSL || useTP))
     {
      if(OrderSelect(ticket, SELECT_BY_TICKET))
         if(!OrderModify(ticket, OrderOpenPrice(), useSL ? sl : 0, useTP ? tp : 0, 0, clrNONE))
            Print("ICT-V ECN SL/TP modify failed #", ticket, " err=", GetLastError());
     }
   Print("ICT-V OPEN ", (isBuy ? "BUY" : "SELL"), " #", ticket,
         " score=", score, "/11 lots=", lots, " SL=", sl, " TP=", tp);
   return(true);
  }

//+------------------------------------------------------------------+
//| Advanced exits � R from sl0 in comment; partials via g_partials[] |
//| (MT4 partial close keeps same ticket/comment; OrderModify cannot |
//|  change comment, so partial stage tracked in g_partials[] + lots0 |
//|  in comment for restart inference)                                |
//+------------------------------------------------------------------+
int Ex_LotDigits()
  {
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(step <= 0)
      return(2);
   if(step >= 1.0)
      return(0);
   if(step >= 0.1)
      return(1);
   return(2);
  }

bool Ex_ParseTagDouble(string cmt, string tag, double &valOut)
  {
   int p = StringFind(cmt, tag);
   if(p < 0)
      return(false);
   p += StringLen(tag);
   int end = StringLen(cmt);
   int sp = StringFind(cmt, " ", p);
   if(sp > p)
      end = sp;
   valOut = StringToDouble(StringSubstr(cmt, p, end - p));
   return(valOut > 0);
  }

bool Ex_ParseEntryMeta(string cmt, double &sl0, double &lots0)
  {
   sl0 = 0;
   lots0 = 0;
   bool okSl = Ex_ParseTagDouble(cmt, "sl0=", sl0);
   Ex_ParseTagDouble(cmt, "lots0=", lots0);
   return(okSl);
  }

int Ex_FindPartialIdx(int ticket)
  {
   for(int i = 0; i < g_partialCount; i++)
      if(g_partials[i].ticket == ticket)
         return(i);
   return(-1);
  }

void Ex_ReconcilePartialStates()
  {
   if(!UsePartialClose)
      return;

   bool open[];
   ArrayResize(open, g_partialCount);
   for(int i = 0; i < g_partialCount; i++)
      open[i] = false;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(!IsOurOrder())
         continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;
      int idx = Ex_FindPartialIdx(OrderTicket());
      if(idx >= 0)
         open[idx] = true;
     }

   for(int i = g_partialCount - 1; i >= 0; i--)
     {
      if(!open[i])
        {
         for(int j = i; j < g_partialCount - 1; j++)
            g_partials[j] = g_partials[j + 1];
         g_partialCount--;
         ArrayResize(g_partials, g_partialCount);
         ArrayResize(open, g_partialCount);
         for(int k = i; k < g_partialCount; k++)
            open[k] = true;
        }
     }
  }

PartialState Ex_GetOrCreatePartialState(int ticket, string cmt, double curLots)
  {
   PartialState empty;
   empty.ticket = 0;
   empty.sl0 = 0;
   empty.lots0 = 0;
   empty.p1Done = false;
   empty.p2Done = false;

   int idx = Ex_FindPartialIdx(ticket);
   if(idx >= 0)
      return(g_partials[idx]);

   double sl0 = 0;
   double lots0 = 0;
   if(!Ex_ParseEntryMeta(cmt, sl0, lots0))
      return(empty);

   PartialState st;
   st.ticket = ticket;
   st.sl0 = sl0;
   st.lots0 = (lots0 > 0 ? lots0 : curLots);
   st.p1Done = false;
   st.p2Done = false;

   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(Partial1_AtR > 0 && Partial1_Pct > 0)
     {
      double afterP1 = st.lots0 * (1.0 - Partial1_Pct / 100.0);
      if(curLots <= afterP1 + step * 0.5)
         st.p1Done = true;
     }
   if(st.p1Done && Partial2_AtR > 0 && Partial2_Pct > 0)
     {
      double afterP1 = st.lots0 * (1.0 - Partial1_Pct / 100.0);
      double afterP2 = afterP1 * (1.0 - Partial2_Pct / 100.0);
      if(curLots <= afterP2 + step * 0.5)
         st.p2Done = true;
     }
   if(curLots <= minLot + step * 0.1)
      st.p2Done = true;

   g_partialCount++;
   ArrayResize(g_partials, g_partialCount);
   g_partials[g_partialCount - 1] = st;
   return(st);
  }

void Ex_SavePartialState(PartialState &st)
  {
   int idx = Ex_FindPartialIdx(st.ticket);
   if(idx >= 0)
      g_partials[idx] = st;
  }

bool Ex_ClampPartialLots(double curLots, double pct, double &lotsToClose)
  {
   double minLot = MathMax(MinPartialLots, MarketInfo(Symbol(), MODE_MINLOT));
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   int lotDig = Ex_LotDigits();

   lotsToClose = NormalizeDouble(curLots * pct / 100.0, lotDig);
   if(lotsToClose < minLot)
      lotsToClose = minLot;

   double remainder = NormalizeDouble(curLots - lotsToClose, lotDig);
   if(remainder > 0 && remainder < minLot)
     {
      lotsToClose = NormalizeDouble(curLots - minLot, lotDig);
      remainder = minLot;
     }

   if(lotsToClose < minLot || lotsToClose >= curLots)
      return(false);
   if(remainder > 0 && remainder < minLot)
      return(false);

   return(true);
  }

bool Ex_TryPartialClose(int ticket, bool isBuy, double lotsToClose, string label)
  {
   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return(false);

   double price = isBuy ? Bid : Ask;
   if(!OrderClose(ticket, lotsToClose, price, Slippage, clrNONE))
     {
      Print("ICT-V partial ", label, " failed #", ticket, " err=", GetLastError());
      return(false);
     }

   Print("ICT-V partial ", label, " closed #", ticket, " lots=", lotsToClose);
   return(true);
  }

bool Ex_TryMoveSL(int ticket, bool isBuy, double entry, double targetSL,
                  double curTP, double stopLevel, double price)
  {
   targetSL = NormalizeDouble(targetSL, Digits);
   if(targetSL <= 0)
      return(false);
   if(isBuy && targetSL >= price - stopLevel)
      return(false);
   if(!isBuy && targetSL <= price + stopLevel)
      return(false);

   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return(false);
   double curSL = OrderStopLoss();
   if(isBuy && curSL > 0 && targetSL <= curSL)
      return(false);
   if(!isBuy && curSL > 0 && targetSL >= curSL)
      return(false);

   if(!OrderModify(ticket, entry, targetSL, curTP, 0, clrNONE))
     {
      Print("ICT-V SL modify failed #", ticket, " err=", GetLastError());
      return(false);
     }
   return(true);
  }

void Ex_HandlePartials(int ticket, bool isBuy, double entry, double price,
                       double R, double profitR, double stopLevel)
  {
   if(!UsePartialClose || R <= 0)
      return;

   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return;

   PartialState st = Ex_GetOrCreatePartialState(ticket, OrderComment(), OrderLots());
   if(st.ticket <= 0)
      return;

   double curLots = OrderLots();
   double curSL = OrderStopLoss();
   double curTP = OrderTakeProfit();
   int lotDig = Ex_LotDigits();

   if(!st.p1Done && Partial1_AtR > 0 && profitR >= Partial1_AtR)
     {
      double lotsToClose = 0;
      if(!Ex_ClampPartialLots(curLots, Partial1_Pct, lotsToClose))
        {
         static int s_warnP1Ticket = -1;
         if(s_warnP1Ticket != ticket)
           {
            Print("ICT-V partial1 skipped #", ticket, ": invalid lot split (minlot/step)");
            s_warnP1Ticket = ticket;
           }
        }
      else if(Ex_TryPartialClose(ticket, isBuy, lotsToClose, "P1"))
        {
         st.p1Done = true;
         Ex_SavePartialState(st);
         if(AlertPartialClose)
           {
            string msg = StringFormat("ICT-V PARTIAL P1 closed %.2f lots #%d @ %.5f", lotsToClose, ticket, price);
            Print(msg);
            if(!IsTesting()) { if(EnableAlerts) Alert(msg); if(EnablePushNotify) SendNotification(msg); }
           }
         if(Partial1_ThenBE)
           {
            double beSL = isBuy ? entry + BE_LockR * R : entry - BE_LockR * R;
            Ex_TryMoveSL(ticket, isBuy, entry, beSL, curTP, stopLevel, price);
           }
        }
     }

   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return;
   curLots = OrderLots();

   if(st.p1Done && !st.p2Done && Partial2_AtR > 0 && profitR >= Partial2_AtR)
     {
      double lotsToClose = 0;
      if(!Ex_ClampPartialLots(curLots, Partial2_Pct, lotsToClose))
        {
         static int s_warnP2Ticket = -1;
         if(s_warnP2Ticket != ticket)
           {
            Print("ICT-V partial2 skipped #", ticket, ": invalid lot split (minlot/step)");
            s_warnP2Ticket = ticket;
           }
        }
      else if(Ex_TryPartialClose(ticket, isBuy, lotsToClose, "P2"))
        {
         st.p2Done = true;
         Ex_SavePartialState(st);
         if(AlertPartialClose)
           {
            string msg = StringFormat("ICT-V PARTIAL P2 closed %.2f lots #%d @ %.5f", lotsToClose, ticket, price);
            Print(msg);
            if(!IsTesting()) { if(EnableAlerts) Alert(msg); if(EnablePushNotify) SendNotification(msg); }
           }
        }
     }
  }

void ManageOpenTrades()
  {
   double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   Ex_ReconcilePartialStates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(!IsOurOrder())
         continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;

      bool isBuy = (OrderType() == OP_BUY);
      double entry = OrderOpenPrice();
      double curSL = OrderStopLoss();
      double curTP = OrderTakeProfit();
      double price = isBuy ? Bid : Ask;
      double profitPts = isBuy ? (price - entry) / Point : (entry - price) / Point;

      double sl0 = 0;
      double lots0 = 0;
      int psIdx = Ex_FindPartialIdx(OrderTicket());
      if(psIdx >= 0)
        {
         sl0   = g_partials[psIdx].sl0;
         lots0 = g_partials[psIdx].lots0;
        }
      else
         Ex_ParseEntryMeta(OrderComment(), sl0, lots0);
      double R = 0;
      if(sl0 > 0)
         R = MathAbs(entry - sl0);
      double profitR = 0;
      if(R > 0)
         profitR = isBuy ? (price - entry) / R : (entry - price) / R;

      if(UsePartialClose && R > 0)
         Ex_HandlePartials(OrderTicket(), isBuy, entry, price, R, profitR, stopLevel);

      if(!OrderSelect(OrderTicket(), SELECT_BY_TICKET))
         continue;
      entry = OrderOpenPrice();
      curSL = OrderStopLoss();
      curTP = OrderTakeProfit();
      price = isBuy ? Bid : Ask;
      profitPts = isBuy ? (price - entry) / Point : (entry - price) / Point;

      double newSL = curSL;

      if(UseBreakEven && profitPts >= BreakEvenTriggerPts)
        {
         double beSL = isBuy ? entry + BreakEvenLockPts * Point
                             : entry - BreakEvenLockPts * Point;
         beSL = NormalizeDouble(beSL, Digits);
         if(isBuy && (beSL > newSL || newSL == 0))
            newSL = beSL;
         if(!isBuy && (newSL == 0 || beSL < newSL))
            newSL = beSL;
        }

      if(UseRMultipleBE && R > 0 && profitR >= BE_AtR)
        {
         double rBeSL = isBuy ? entry + BE_LockR * R : entry - BE_LockR * R;
         rBeSL = NormalizeDouble(rBeSL, Digits);
         if(isBuy && (rBeSL > newSL || newSL == 0))
            newSL = rBeSL;
         if(!isBuy && (newSL == 0 || rBeSL < newSL))
            newSL = rBeSL;
        }

      if(UseTrailingStop && profitPts >= TrailingStartPts)
        {
         double trailSL = isBuy ? price - TrailingDistancePts * Point
                              : price + TrailingDistancePts * Point;
         trailSL = NormalizeDouble(trailSL, Digits);
         if(isBuy)
           {
            if(trailSL > newSL && trailSL < price - stopLevel)
               newSL = trailSL;
           }
         else
           {
            if((newSL == 0 || trailSL < newSL) && trailSL > price + stopLevel)
               newSL = trailSL;
           }
        }

      if(newSL != curSL && newSL > 0)
        {
         if(isBuy && newSL >= price - stopLevel)
            continue;
         if(!isBuy && newSL <= price + stopLevel)
            continue;
         if(curSL > 0 && MathAbs(newSL - curSL) < TrailingStepPts * Point)
            continue;

         if(!OrderModify(OrderTicket(), entry, newSL, curTP, 0, clrNONE))
            Print("ICT-V OrderModify failed #", OrderTicket(), " err=", GetLastError());
        }
     }
  }

void RecordSignalFire(bool isLong, int shift, double sl, double tp, int score)
  {
   // Bootstrap replays oldest->newest; reject bars already superseded by a newer signal
   if(g_lastSignalBarCounter >= 0 && ClosedBarPineIndex() < g_lastSignalBarCounter)
      return;

   if(DebugCooldownRejects)
      Print("ICT-V SIGNAL RECORDED ", (isLong ? "LONG" : "SHORT"),
            " barIdx=", ClosedBarPineIndex(),
            " prevLastLongBarCounter=", g_lastLongBarCounter,
            " prevLastShortBarCounter=", g_lastShortBarCounter);

   g_lastSignalDir = isLong ? "LONG" : "SHORT";
   g_lastSignalSL = sl;
   g_lastSignalTP = tp;
   g_lastSignalScore = score;
   g_lastSignalShift = shift;
   g_lastSignalBarCounter = ClosedBarPineIndex();
   if(isLong)
     {
      g_lastLongShift = shift;
      g_lastLongBarCounter = ClosedBarPineIndex();
     }
   else
     {
      g_lastShortShift = shift;
      g_lastShortBarCounter = ClosedBarPineIndex();
     }
  }

void EvaluateAndTrade(int shift)
  {
   double slLong = 0, tpLong = 0, slShort = 0, tpShort = 0;
   int longScore = 0, shortScore = 0;

   bool longSignal = EvaluateLongSignal(shift, slLong, tpLong, longScore);
   bool shortSignal = EvaluateShortSignal(shift, slShort, tpShort, shortScore);

   g_lastDiagLongScore = longScore;
   g_lastDiagShortScore = shortScore;

   if(DebugLogClosedBars)
      LogClosedBarDiagnostics(shift, longSignal, longScore, shortSignal, shortScore);

   if(!EnableSignals)
      return;

   bool newsEntryBlock = (UseNewsFilter && IsNewsBlackout(iTime(Symbol(), Period(), shift)));
   bool cbBlock = CB_IsTripped();
   bool hoursBlock = (!TH_EntryAllowed()) || TH_PostEODBlock();

   // Pine parity: long evaluated first (cooldown), short second; same-bar panel = last writer (SHORT)
   if(longSignal)
     {
      bool longCooldownOK = (g_lastLongBarCounter < 0 ||
         (ClosedBarPineIndex() - g_lastLongBarCounter) >= SignalCooldownBars);
      if(longCooldownOK)
        {
         if(!shortSignal)
            RecordSignalFire(true, shift, slLong, tpLong, longScore);
         else
           {
            g_lastLongShift = shift;
            g_lastLongBarCounter = ClosedBarPineIndex();
           }
         if(!g_bootstrapping)
           {
            int sigDrawId = AllocSignalDrawId();
            DrawSignalArrow(shift, true, sigDrawId);
            DrawSLTP(shift, true, slLong, tpLong, sigDrawId);
            FireAlertOnce(g_alertBarLongSig,
               "ICT-V: Validated LONG signal - check panel for confluence score");
           }
         if(AllowLong && !newsEntryBlock && !cbBlock && !hoursBlock)
            OpenTrade(true, UseSignalSLTP ? slLong : 0, UseSignalSLTP ? tpLong : 0, longScore);
        }
     }

   if(shortSignal)
     {
      bool shortCooldownOK = (g_lastShortBarCounter < 0 ||
         (ClosedBarPineIndex() - g_lastShortBarCounter) >= SignalCooldownBars);
      if(shortCooldownOK)
        {
         RecordSignalFire(false, shift, slShort, tpShort, shortScore);
         if(!g_bootstrapping)
           {
            int sigDrawId = AllocSignalDrawId();
            DrawSignalArrow(shift, false, sigDrawId);
            DrawSLTP(shift, false, slShort, tpShort, sigDrawId);
            FireAlertOnce(g_alertBarShortSig,
               "ICT-V: Validated SHORT signal - check panel for confluence score");
           }
         if(AllowShort && !newsEntryBlock && !cbBlock && !hoursBlock)
            OpenTrade(false, UseSignalSLTP ? slShort : 0, UseSignalSLTP ? tpShort : 0, shortScore);
        }
     }
  }

//+------------------------------------------------------------------+
//| v1.6: pivot confirm only establishes levels + resets broken flags|
//+------------------------------------------------------------------+
void ProcessSwingPivotConfirm(int pivotShift)
  {
   string sym = Symbol();
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

   if(IsPivotHigh(sym, tf, pivotShift, SwingLength))
     {
      SMC_Swing sw;
      sw.time = iTime(sym, tf, pivotShift);
      sw.price = iHigh(sym, tf, pivotShift);
      sw.isHigh = true;
      sw.barIdx = ClosedBarPineIndex() - SwingLength;
      sw.drawId = NextDrawId();
      AddSwing(sw);
      DrawSwingMark(g_swings[g_swingCount - 1]);

      g_lastSwingHigh = sw.price;
      g_lastSwingHighTime = sw.time;
      g_swingHighBroken = false;

      if(DebugStructure)
         Print("ICT-V v1.6 pivot HIGH @ ", DoubleToStr(sw.price, Digits),
               " time=", TimeToString(sw.time, TIME_DATE|TIME_MINUTES));
     }

   if(IsPivotLow(sym, tf, pivotShift, SwingLength))
     {
      SMC_Swing sw;
      sw.time = iTime(sym, tf, pivotShift);
      sw.price = iLow(sym, tf, pivotShift);
      sw.isHigh = false;
      sw.barIdx = ClosedBarPineIndex() - SwingLength;
      sw.drawId = NextDrawId();
      AddSwing(sw);
      DrawSwingMark(g_swings[g_swingCount - 1]);

      g_lastSwingLow = sw.price;
      g_lastSwingLowTime = sw.time;
      g_swingLowBroken = false;

      if(DebugStructure)
         Print("ICT-V v1.6 pivot LOW @ ", DoubleToStr(sw.price, Digits),
               " time=", TimeToString(sw.time, TIME_DATE|TIME_MINUTES));
     }
  }

void ProcessInternalPivotConfirm(int pivotShift, bool &confirmHigh, bool &confirmLow)
  {
   confirmHigh = false;
   confirmLow = false;

   string sym = Symbol();
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();

   if(IsPivotHigh(sym, tf, pivotShift, InternalLength))
     {
      SMC_Swing sw;
      sw.time = iTime(sym, tf, pivotShift);
      sw.price = iHigh(sym, tf, pivotShift);
      sw.isHigh = true;
      sw.barIdx = ClosedBarPineIndex() - InternalLength;
      AddInternalSwing(sw);

      g_lastInternalHigh = sw.price;
      g_lastInternalHighTime = sw.time;
      g_internalHighBroken = false;
      confirmHigh = true;
     }

   if(IsPivotLow(sym, tf, pivotShift, InternalLength))
     {
      SMC_Swing sw;
      sw.time = iTime(sym, tf, pivotShift);
      sw.price = iLow(sym, tf, pivotShift);
      sw.isHigh = false;
      sw.barIdx = ClosedBarPineIndex() - InternalLength;
      AddInternalSwing(sw);

      g_lastInternalLow = sw.price;
      g_lastInternalLowTime = sw.time;
      g_internalLowBroken = false;
      confirmLow = true;
     }
  }

// Pine parity: IDM uses swingBullish after real-time structure on this bar
void ProcessInternalIDMAfterStructure(int pivotShift, bool confirmHigh, bool confirmLow)
  {
   if(confirmHigh)
      TryCreateIDM(pivotShift, true);
   if(confirmLow)
      TryCreateIDM(pivotShift, false);
  }

//+------------------------------------------------------------------+
//| v1.6: real-time BOS/CHoCH on bar where price crosses level        |
//+------------------------------------------------------------------+
void ProcessRealtimeSwingStructure(int shift)
  {
   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);
   double open  = iOpen(Symbol(), Period(), shift);

   double srcHigh = RequireBodyClose ? close : high;
   double srcLow  = RequireBodyClose ? close : low;

   bool brokeHigh = (g_lastSwingHigh > 0 && !g_swingHighBroken && srcHigh > g_lastSwingHigh);
   bool brokeLow  = (g_lastSwingLow > 0 && !g_swingLowBroken && srcLow < g_lastSwingLow);

   // Outside bar �" resolve in direction of close (Pine v1.6)
   if(brokeHigh && brokeLow)
     {
      if(close >= open)
         brokeLow = false;
      else
         brokeHigh = false;
     }

   datetime barTime = iTime(Symbol(), Period(), shift);

   if(brokeHigh)
     {
      int brkType = g_swingBullish ? BRK_BOS : BRK_CHOCH;
      bool brkBull = true;

      SMC_StructureBreak brk;
      brk.time = barTime;
      brk.price = g_lastSwingHigh;
      brk.breakType = brkType;
      brk.isBullish = brkBull;
      brk.level = "swing";
      brk.hasDisplacement = false;
      brk.drawId = NextDrawId();
      AddStructureBreak(brk, false);
      DrawStructureMark(g_structureBreaks[g_structureBreakCount - 1]);
      FireStructureAlert(true, brkType);

      g_swingBullish = true;
      g_swingHighBroken = true;
      g_lastSwingBreakStr = BreakTypeToString(brkType) + " ^";

      CreateOTEZone(true, shift, barTime);

      if(DebugStructure)
         Print("ICT-V v1.6 SWING ", BreakTypeToString(brkType), " BULL @ ",
               DoubleToStr(g_lastSwingHigh, Digits),
               " bar=", TimeToString(barTime, TIME_DATE|TIME_MINUTES));
     }

   if(brokeLow)
     {
      int brkType = g_swingBullish ? BRK_CHOCH : BRK_BOS;
      bool brkBull = false;

      SMC_StructureBreak brk;
      brk.time = barTime;
      brk.price = g_lastSwingLow;
      brk.breakType = brkType;
      brk.isBullish = brkBull;
      brk.level = "swing";
      brk.hasDisplacement = false;
      brk.drawId = NextDrawId();
      AddStructureBreak(brk, false);
      DrawStructureMark(g_structureBreaks[g_structureBreakCount - 1]);
      FireStructureAlert(false, brkType);

      g_swingBullish = false;
      g_swingLowBroken = true;
      g_lastSwingBreakStr = BreakTypeToString(brkType) + " v";

      CreateOTEZone(false, shift, barTime);

      if(DebugStructure)
         Print("ICT-V v1.6 SWING ", BreakTypeToString(brkType), " BEAR @ ",
               DoubleToStr(g_lastSwingLow, Digits),
               " bar=", TimeToString(barTime, TIME_DATE|TIME_MINUTES));
     }
  }

void ProcessRealtimeInternalStructure(int shift)
  {
   if(!ShowInternalStructure)
      return;

   double close = iClose(Symbol(), Period(), shift);
   double high  = iHigh(Symbol(), Period(), shift);
   double low   = iLow(Symbol(), Period(), shift);
   double open  = iOpen(Symbol(), Period(), shift);

   double srcHigh = RequireBodyClose ? close : high;
   double srcLow  = RequireBodyClose ? close : low;

   bool brokeHigh = (g_lastInternalHigh > 0 && !g_internalHighBroken && srcHigh > g_lastInternalHigh);
   bool brokeLow  = (g_lastInternalLow > 0 && !g_internalLowBroken && srcLow < g_lastInternalLow);

   if(brokeHigh && brokeLow)
     {
      if(close >= open)
         brokeLow = false;
      else
         brokeHigh = false;
     }

   datetime barTime = iTime(Symbol(), Period(), shift);

   if(brokeHigh)
     {
      int brkType = g_internalBullish ? BRK_BOS : BRK_CHOCH;

      SMC_StructureBreak brk;
      brk.time = barTime;
      brk.price = g_lastInternalHigh;
      brk.breakType = brkType;
      brk.isBullish = true;
      brk.level = "internal";
      brk.hasDisplacement = false;
      AddStructureBreak(brk, true);

      g_internalBullish = true;
      g_internalHighBroken = true;
      g_lastInternalBreakStr = BreakTypeToString(brkType) + " ^";

      if(DebugStructure)
         Print("ICT-V v1.6 INTERNAL ", BreakTypeToString(brkType), " BULL");
     }

   if(brokeLow)
     {
      int brkType = g_internalBullish ? BRK_CHOCH : BRK_BOS;

      SMC_StructureBreak brk;
      brk.time = barTime;
      brk.price = g_lastInternalLow;
      brk.breakType = brkType;
      brk.isBullish = false;
      brk.level = "internal";
      brk.hasDisplacement = false;
      AddStructureBreak(brk, true);

      g_internalBullish = false;
      g_internalLowBroken = true;
      g_lastInternalBreakStr = BreakTypeToString(brkType) + " v";

      if(DebugStructure)
         Print("ICT-V v1.6 INTERNAL ", BreakTypeToString(brkType), " BEAR");
     }
  }

//+------------------------------------------------------------------+
//| Process one closed bar � mirrors Pine v1.6 barstate.isconfirmed  |
//+------------------------------------------------------------------+
void ProcessClosedBar(int shift)
  {
   datetime barTime = iTime(Symbol(), Period(), shift);

   // Pine request.security HTF at bar close (lookahead_off), not bar open
   if(UseHTF)
      SyncHTFToTime(HTFSyncAsOf(ClosedBarAsOf(shift)));

   // Swing / internal pivot confirm
   int swingPivotShift = shift + SwingLength;
   ProcessSwingPivotConfirm(swingPivotShift);

   int internalPivotShift = shift + InternalLength;
   bool intHighConfirm = false;
   bool intLowConfirm = false;
   ProcessInternalPivotConfirm(internalPivotShift, intHighConfirm, intLowConfirm);

   // Real-time swing + internal structure (BOS/CHoCH + OTE spawn)
   ProcessRealtimeSwingStructure(shift);
   ProcessRealtimeInternalStructure(shift);

   // IDM create (after swingBullish) + lifecycle
   ProcessInternalIDMAfterStructure(internalPivotShift, intHighConfirm, intLowConfirm);
   UpdateIDMLifecycle(shift);
   TrimIDMArray();

   // FVG detect ? FVG mit/IFVG spawn ? IFVG mgmt ? BPR ? OB ? breaker/OTE
   DetectFVG(shift);
   UpdateFVGIFVGLifecycle(shift);
   ProcessIFVGLifecycle(shift);
   DetectBPR(shift);
   TrimBPRArray();
   DetectOrderBlocks(shift);
   UpdateOBBreakerOTEBPRLifecycle(shift);
   TrimOBArray();
   ProcessBreakerLifecycle(shift);
   TrimBreakerArray();
   ProcessOTELifecycle(shift);

   // Session / P-D / killzone for panel + signal scoring (Pine: currentlyInKZ before CISD/signals)
   UpdateSessionLevels();
   UpdatePremiumDiscount(shift);
   UpdateKillzoneState(barTime);

   // CISD then signals � same order as Pine lines 1501�1543
   UpdateCISD(shift);
   EvaluateAndTrade(shift);

   FireBarEventAlerts();
   ProcessChartDisplay(shift);
  }

//+------------------------------------------------------------------+
//| Bootstrap historical bars                                        |
//+------------------------------------------------------------------+
void BootstrapHistory()
  {
   g_bootstrapping = true;
   g_swingCount = 0;
   g_internalSwingCount = 0;
   g_structureBreakCount = 0;
   g_internalBreakCount = 0;
   g_barCounter = 0;

   g_swingBullish = true;
   g_lastSwingHigh = 0;
   g_lastSwingLow = 0;
   g_swingHighBroken = false;
   g_swingLowBroken = false;

   g_internalBullish = true;
   g_lastInternalHigh = 0;
   g_lastInternalLow = 0;
   g_internalHighBroken = false;
   g_internalLowBroken = false;

   g_obCount = 0;
   g_fvgCount = 0;
   g_ifvgCount = 0;
   g_oteCount = 0;
   g_idmCount = 0;
   g_breakerCount = 0;
   g_bprCount = 0;
   ArrayResize(g_obs, 0);
   ArrayResize(g_fvgs, 0);
   ArrayResize(g_ifvgs, 0);
   ArrayResize(g_otes, 0);
   ArrayResize(g_idms, 0);
   ArrayResize(g_breakers, 0);
   ArrayResize(g_bprs, 0);

   ResetHTFState();

   g_lastLongShift = -1;
   g_lastShortShift = -1;
   g_lastLongBarCounter = -1000000;
   g_lastShortBarCounter = -1000000;
   g_hasBearishOpen = false;
   g_hasBullishOpen = false;
   g_lastSignalDir = "NONE";
   g_lastSignalShift = -1;
   g_lastSignalBarCounter = -1;

   int avail = Bars - SwingLength - 3;
   int limit = (BootstrapMaxBars > 0) ? MathMin(avail, BootstrapMaxBars) : avail;
   if(limit < 2)
      limit = 2;

   for(int shift = limit; shift >= 1; shift--)
     {
      g_barCounter++;
      ProcessClosedBar(shift);
     }

   // Full HTF replay to forming bar � fixes D1/W1 HTF break label vs Pine security
   ReplayHTFToNow();

   UpdateSessionLevels();
   UpdatePremiumDiscount(1);
   UpdateKillzoneState(ChartBarTime());
   g_bootstrapping = false;

   // Pine keeps lastLongBar/lastShortBar through history � do NOT reset cooldown here
   g_lastLongShift  = -1;
   g_lastShortShift = -1;

   RedrawAllZonesFromArrays();
   ProcessChartDisplay(1);
   UpdateDashboard();

   Print("ICT-V v1.6 EA bootstrap: bars=", limit,
         " swings=", g_swingCount,
         " breaks=", g_structureBreakCount,
         " OBs=", CountActiveOBs(),
         " FVGs=", CountActiveFVGs(),
         " OTEs=", CountActiveOTEs(),
         " IDMs=", CountActiveIDMs(),
         " IFVGs=", CountActiveIFVGs(),
         " Breakers=", CountActiveBreakers(),
         " BPRs=", CountActiveBPRs(),
         " structure=", (g_swingBullish ? "BULL" : "BEAR"),
         " HTF=", (UseHTF ? (g_htfBullish ? "BULL" : "BEAR") : "OFF"),
         " zone=", g_pdZoneStr);

   LogZoneAudit();
  }

void ClearDashboardObjects()
  {
   DelObj(PFX + "PNL_BG");
   for(int i = 0; i < COMPACT_PANEL_ROWS; i++)
      DelObj(PFX + "PNL_0" + IntegerToString(i));
   for(int i = 0; i < PANEL_ROWS; i++)
     {
      DelObj(PFX + "PNL_L_" + IntegerToString(i));
      DelObj(PFX + "PNL_R_" + IntegerToString(i));
     }
  }

//+------------------------------------------------------------------+
//| Dashboard                                                        |
//+------------------------------------------------------------------+
void Journal_Init()
  {
   if(!UseTradeJournal) { g_journalLastHistTotal = OrdersHistoryTotal(); return; }
   int fh = FileOpen(JournalFileName, FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_READ);
   if(fh == INVALID_HANDLE) { Print("ICT-V Journal: cannot open ", JournalFileName); return; }
   FileSeek(fh, 0, SEEK_END);
   if(FileTell(fh) == 0)
      FileWrite(fh, "Ticket,OpenTime,CloseTime,Symbol,Direction,Lots,OpenPrice,SL0,TP,ClosePrice,Score,Profit,Swap,Commission,Net,RR");
   FileClose(fh);
   g_journalLastHistTotal = OrdersHistoryTotal();
  }

void Journal_CheckNewTrades()
  {
   if(!UseTradeJournal) return;
   int histTotal = OrdersHistoryTotal();
   if(histTotal <= g_journalLastHistTotal) return;
   int fh = FileOpen(JournalFileName, FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_READ);
   if(fh == INVALID_HANDLE) { Print("ICT-V Journal: cannot open ", JournalFileName); return; }
   FileSeek(fh, 0, SEEK_END);
   for(int i = g_journalLastHistTotal; i < histTotal; i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      double sl0 = 0, lots0 = 0;
      Ex_ParseEntryMeta(OrderComment(), sl0, lots0);
      string dir = (OrderType() == OP_BUY) ? "BUY" : "SELL";
      double openPx  = OrderOpenPrice();
      double closePx = OrderClosePrice();
      double net = OrderProfit() + OrderSwap() + OrderCommission();
      double rr  = 0;
      if(sl0 > 0)
        {
         double risk = MathAbs(openPx - sl0);
         if(risk > 0)
            rr = (OrderType() == OP_BUY) ? (closePx - openPx) / risk : (openPx - closePx) / risk;
        }
      string cmt = OrderComment();
      int sp = StringFind(cmt, "score=");
      string scoreStr = "?";
      if(sp >= 0) { int ep = StringFind(cmt, "/", sp); if(ep > sp) scoreStr = StringSubstr(cmt, sp + 6, ep - sp - 6); }
      FileWrite(fh,
                IntegerToString(OrderTicket()),
                TimeToString(OrderOpenTime(),  TIME_DATE|TIME_SECONDS),
                TimeToString(OrderCloseTime(), TIME_DATE|TIME_SECONDS),
                OrderSymbol(), dir,
                DoubleToString(OrderLots(), 2),
                DoubleToString(openPx, Digits),
                sl0 > 0 ? DoubleToString(sl0, Digits) : "",
                OrderTakeProfit() > 0 ? DoubleToString(OrderTakeProfit(), Digits) : "",
                DoubleToString(closePx, Digits),
                scoreStr,
                DoubleToString(OrderProfit(), 2),
                DoubleToString(OrderSwap(), 2),
                DoubleToString(OrderCommission(), 2),
                DoubleToString(net, 2),
                DoubleToString(rr, 2));
     }
   FileClose(fh);
   g_journalLastHistTotal = histTotal;
  }

void UpdateDashboard()
  {
   if(!ShowInfoPanel && !CompactPanel)
     {
      ClearDashboardObjects();
      Comment("");
      return;
     }

   UpdatePremiumDiscount(0);
   UpdateKillzoneState(ChartBarTime());

   color cBull = clrLimeGreen, cBear = clrTomato, cGray = clrSilver;
   color cWhite = clrWhite, cAqua = clrAqua, cOrange = clrOrange;
   color cGold = clrGold, cYellow = clrYellow;

   if(CompactPanel)
     {
      ClearDashboardObjects();
      string sigStr = "NO SIGNAL";
      if(g_lastSignalDir == "LONG")
         sigStr = StringFormat("LONG %d/11", g_lastSignalScore);
      else if(g_lastSignalDir == "SHORT")
         sigStr = StringFormat("SHORT %d/11", g_lastSignalScore);
      Comment(StringFormat(
         "ICT-V v1.6 | %s | %s | %s | KZ:%s | L:%d S:%d | %s",
         g_swingBullish ? "BULL" : "BEAR",
         g_pdZoneStr,
         UseHTF ? (g_htfBullish ? "HTF BULL" : "HTF BEAR") : "HTF OFF",
         g_inKillzoneNow ? g_kzSessionStr : "OFF",
         g_lastDiagLongScore, g_lastDiagShortScore,
         sigStr
      ));
      return;
     }

   // --- Compact panel: single-line rows + solid black background ---
   if(PanelLayout == PL_COMPACT)
     {
      for(int i = 0; i < PANEL_ROWS; i++)
        {
         DelObj(PFX + "PNL_L_" + IntegerToString(i));
         DelObj(PFX + "PNL_R_" + IntegerToString(i));
        }

      int corner = CORNER_LEFT_UPPER;
      int x = 14, y0 = 22, dy = 15, fsz = 9;
      int panelW = 440, panelH = y0 + COMPACT_PANEL_ROWS * dy + 10;

      string htfAlign = "---";
      if(UseHTF)
        {
         bool aligned = (g_swingBullish && g_htfBullish) || (!g_swingBullish && !g_htfBullish);
         htfAlign = aligned ? "ALIGNED" : "COUNTER";
        }

      string cisdStr = "---";
      color cisdCol = cGray;
      if(BullishCISD(0) && BearishCISD(0))
        {
         cisdStr = "BULL+BEAR";
         cisdCol = cYellow;
        }
      else if(BullishCISD(0))
        {
         cisdStr = "BULLISH";
         cisdCol = cBull;
        }
      else if(BearishCISD(0))
        {
         cisdStr = "BEARISH";
         cisdCol = cBear;
        }

      string sigStr = "NO SIGNAL";
      color sigCol = cGray;
      if(g_lastSignalDir == "LONG" && g_lastSignalShift > 0)
        {
         sigStr = "^ LONG " + IntegerToString(g_lastSignalScore) + "/11" + SignalBarsAgoText();
         sigCol = cBull;
        }
      else if(g_lastSignalDir == "SHORT" && g_lastSignalShift > 0)
        {
         sigStr = "v SHORT " + IntegerToString(g_lastSignalScore) + "/11" + SignalBarsAgoText();
         sigCol = cBear;
        }

      string oteStr = IntegerToString(CountActiveOTEs());
      string idmStr = IntegerToString(CountActiveIDMs());

      PanelBackground(10, 10, panelW, panelH, corner);
      PanelLabel(PFX + "PNL_00", x, y0, corner,
                 "=== ICT Validated SMC v1.6 (LIVE) ===", clrAqua, fsz + 1);
      PanelLabel(PFX + "PNL_01", x, y0 + dy, corner,
                 "Trading: " + (EnableTrading ? "ON" : "OFF") +
                 "  Signals: " + (EnableSignals ? "ON" : "OFF"), cWhite, fsz);
      PanelLabel(PFX + "PNL_02", x, y0 + 2 * dy, corner,
                 "Structure: " + (g_swingBullish ? "BULLISH" : "BEARISH") +
                 "  Break: " + g_lastSwingBreakStr,
                 g_swingBullish ? cBull : cBear, fsz);
      PanelLabel(PFX + "PNL_03", x, y0 + 3 * dy, corner,
                 "HTF(" + PanelHTFLabel(HTFTimeframe) + "): " +
                 (UseHTF ? (g_htfBullish ? "BULLISH" : "BEARISH") : "OFF") +
                 "  Align: " + htfAlign,
                 UseHTF ? (g_htfBullish ? cBull : cBear) : cGray, fsz);
      PanelLabel(PFX + "PNL_04", x, y0 + 4 * dy, corner,
                 "Zone: " + g_pdZoneStr + "  CISD: " + cisdStr,
                 cisdCol == cGray ? cWhite : cisdCol, fsz);
      PanelLabel(PFX + "PNL_05", x, y0 + 5 * dy, corner,
                 "Session: " + g_kzSessionStr +
                 "  KZ: " + (g_inKillzoneNow ? "ACTIVE" : "INACTIVE"),
                 g_inKillzoneNow ? clrAqua : cGray, fsz);
      PanelLabel(PFX + "PNL_06", x, y0 + 6 * dy, corner,
                 StringFormat("Scores L=%d/11 S=%d/11 (min %d)",
                              g_lastDiagLongScore, g_lastDiagShortScore, MinSignalScore),
                 cWhite, fsz);
      PanelLabel(PFX + "PNL_07", x, y0 + 7 * dy, corner, "Signal: " + sigStr, sigCol, fsz);
      PanelLabel(PFX + "PNL_08", x, y0 + 8 * dy, corner,
                 StringFormat("OBs:%d(%d) FVGs:%d BRK:%d OTE:%s IDM:%s",
                              CountActiveOBs(), BestOBScore(), CountActiveFVGs(),
                              CountActiveBreakers(), oteStr, idmStr), cWhite, fsz);
      PanelLabel(PFX + "PNL_09", x, y0 + 9 * dy, corner,
                 StringFormat("PDH/PDL: %.5f/%.5f  PWH/PWL: %.5f/%.5f",
                              g_pdHigh, g_pdLow, g_pwHigh, g_pwLow), cGray, fsz);
      Comment("");
      ChartRedraw(0);
      return;
     }

   // --- Pine v1.6 two-column table ---
   for(int i = 0; i < COMPACT_PANEL_ROWS; i++)
      DelObj(PFX + "PNL_0" + IntegerToString(i));

   int corner = CORNER_LEFT_UPPER;
   int xL = 14, xR = 238, y0 = 18, dy = 14, fsz = 8;
   int acctRows = 0;
   if(ShowDailyPnL || ShowMultiPairInfo) acctRows++;  // separator
   if(ShowDailyPnL)       acctRows += 2;
   if(ShowMultiPairInfo)  acctRows++;
   int panelW = 248, panelH = y0 + (27 + acctRows) * dy + 10;

   // --- row values (Pine v1.6 panel) ---
   string structVal = g_swingBullish ? "BULLISH" : "BEARISH";
   color structCol = g_swingBullish ? cBull : cBear;

   string lastBrkVal = DashBreakText(g_lastSwingBreakStr);
   color lastBrkCol = (StringFind(g_lastSwingBreakStr, "^") >= 0) ? cBull : cBear;

   string htfVal = UseHTF ? (g_htfBullish ? "BULLISH" : "BEARISH") : "DISABLED";
   color htfCol = UseHTF ? (g_htfBullish ? cBull : cBear) : cGray;

   string htfBrkVal = UseHTF ? DashBreakText(g_htfLastBreakStr) : "---";
   color htfBrkCol = cGray;
   if(UseHTF)
      htfBrkCol = (StringFind(g_htfLastBreakStr, "^") >= 0) ? cBull : cBear;

   string alignVal = "---";
   color alignCol = cGray;
   if(UseHTF)
     {
      bool aligned = (g_swingBullish && g_htfBullish) || (!g_swingBullish && !g_htfBullish);
      alignVal = aligned ? "ALIGNED" : "COUNTER";
      alignCol = aligned ? cBull : cBear;
     }

   int activeOBs = CountActiveOBs();
   int activeBreakers = CountActiveBreakers();
   string oteVal = IntegerToString(CountActiveOTEs());
   color oteCol = cWhite;
   if(HasTripleOTEOverlap())
     {
      oteVal = oteVal + " *";
      oteCol = cAqua;
     }
   else if(CountActiveOTEs() == 0)
      oteCol = cGray;

   int activeFVGs = CountActiveFVGs();
   int activeIFVGs = CountActiveIFVGs();
   int activeBPRs = CountActiveBPRs();
   string bprVal = IntegerToString(activeBPRs);
   color bprCol = cGray;
   if(activeBPRs > 0)
     {
      bprVal = IntegerToString(activeBPRs) + " *";
      bprCol = clrMagenta;
     }

   string idmVal = IntegerToString(CountActiveIDMs());
   int idmTrig = CountTriggeredIDMs();
   color idmCol = cGray;
   if(CountActiveIDMs() > 0)
     {
      idmCol = cOrange;
      if(idmTrig > 0)
         idmVal = idmVal + " (" + IntegerToString(idmTrig) + " swept)";
     }

   color zoneCol = cGray;
   if(g_pdZoneStr == "PREMIUM")
      zoneCol = cBear;
   else if(g_pdZoneStr == "DISCOUNT")
      zoneCol = cBull;

   color sessionCol = g_inKillzoneNow ? cAqua : cGray;
   color kzCol = g_inKillzoneNow ? cBull : cGray;

   int bestScore = BestOBScore();
   string starStr = BestOBStarString(bestScore);
   color starCol = BestOBStarColor(bestScore);

   string sigVal = "NO SIGNAL";
   color sigCol = cGray;
   if(g_lastSignalDir == "LONG" && g_lastSignalShift > 0)
     {
      sigVal = "^ LONG " + IntegerToString(g_lastSignalScore) + "/11" + SignalBarsAgoText();
      sigCol = cBull;
     }
   else if(g_lastSignalDir == "SHORT" && g_lastSignalShift > 0)
     {
      sigVal = "v SHORT " + IntegerToString(g_lastSignalScore) + "/11" + SignalBarsAgoText();
      sigCol = cBear;
     }

   string sltpVal = "--- / ---";
   color sltpCol = cGray;
   if(g_lastSignalDir != "NONE")
     {
      string slPart = (g_lastSignalSL > 0) ? DoubleToString(g_lastSignalSL, Digits) : "---";
      string tpPart = (g_lastSignalTP > 0) ? DoubleToString(g_lastSignalTP, Digits) : "---";
      sltpVal = slPart + " / " + tpPart;
      sltpCol = cWhite;
     }

   string cisdVal = "---";
   color cisdCol = cGray;
   if(BullishCISD(0) && BearishCISD(0))
     {
      cisdVal = "BULL + BEAR";
      cisdCol = cYellow;
     }
   else if(BullishCISD(0))
     {
      cisdVal = "BULLISH";
      cisdCol = cBull;
     }
   else if(BearishCISD(0))
     {
      cisdVal = "BEARISH";
      cisdCol = cBear;
     }

   PanelBackground(10, 10, panelW, panelH, corner);

   PanelRow(0,  xL, xR, y0, dy, corner, fsz + 1, "ICT Validated SMC", "v1.6", cWhite, cGray);
   PanelRow(1,  xL, xR, y0, dy, corner, fsz, "Structure:", structVal, cGray, structCol);
   PanelRow(2,  xL, xR, y0, dy, corner, fsz, "Last Break:", lastBrkVal, cGray, lastBrkCol);
   PanelRow(3,  xL, xR, y0, dy, corner, fsz, "HTF (" + PanelHTFLabel(HTFTimeframe) + "):",
            htfVal, cGray, htfCol);
   PanelRow(4,  xL, xR, y0, dy, corner, fsz, "HTF Break:", htfBrkVal, cGray, htfBrkCol);
   PanelRow(5,  xL, xR, y0, dy, corner, fsz, "Alignment:", alignVal, cGray, alignCol);
   PanelRow(6,  xL, xR, y0, dy, corner, fsz, "Active OBs:", IntegerToString(activeOBs), cGray, cWhite);
   PanelRow(7,  xL, xR, y0, dy, corner, fsz, "Breakers:", IntegerToString(activeBreakers),
            cGray, activeBreakers > 0 ? cOrange : cWhite);
   PanelRow(8,  xL, xR, y0, dy, corner, fsz, "OTE Zones:", oteVal, cGray, oteCol);
   PanelRow(9,  xL, xR, y0, dy, corner, fsz, "Active FVGs:", IntegerToString(activeFVGs), cGray, cWhite);
   PanelRow(10, xL, xR, y0, dy, corner, fsz, "IFVGs:", IntegerToString(activeIFVGs),
            cGray, activeIFVGs > 0 ? cGold : cWhite);
   PanelRow(11, xL, xR, y0, dy, corner, fsz, "BPRs:", bprVal, cGray, bprCol);
   PanelRow(12, xL, xR, y0, dy, corner, fsz, "IDMs:", idmVal, cGray, idmCol);
   PanelRow(13, xL, xR, y0, dy, corner, fsz, "Zone:", g_pdZoneStr, cGray, zoneCol);
   PanelRow(14, xL, xR, y0, dy, corner, fsz, "Session:", g_kzSessionStr, cGray, sessionCol);
   PanelRow(15, xL, xR, y0, dy, corner, fsz, "Killzone:",
            g_inKillzoneNow ? "ACTIVE" : "INACTIVE", cGray, kzCol);

   PanelRow(16, xL, xR, y0, dy, corner, fsz, "--- VALIDATION ---", "", cAqua, cAqua);
   PanelRow(17, xL, xR, y0, dy, corner, fsz, "OB Sweep:",
            RequireSweep ? "REQUIRED" : "OPTIONAL", cGray, RequireSweep ? cBull : cYellow);
   PanelRow(18, xL, xR, y0, dy, corner, fsz, "OB Displace:",
            RequireDisplacement ? "REQUIRED" : "OPTIONAL", cGray, RequireDisplacement ? cBull : cYellow);
   PanelRow(19, xL, xR, y0, dy, corner, fsz, "HTF Check:",
            UseHTF ? PanelHTFLabel(HTFTimeframe) : "OFF", cGray, UseHTF ? cBull : cGray);
   PanelRow(20, xL, xR, y0, dy, corner, fsz, "FVG Filter:",
            DoubleToString(FVGMinATRMult, 1) + "x ATR", cGray, cWhite);
   PanelRow(21, xL, xR, y0, dy, corner, fsz, "Min Score:",
            IntegerToString(MinOBDisplayScore) + " / 8", cGray, cWhite);
   PanelRow(22, xL, xR, y0, dy, corner, fsz, "Best OB:", starStr, cGray, starCol);

   PanelRow(23, xL, xR, y0, dy, corner, fsz, "--- SIGNALS ---",
            EnableSignals ? "ON" : "OFF", cAqua, EnableSignals ? cBull : cGray);
   PanelRow(24, xL, xR, y0, dy, corner, fsz, "Signal:", sigVal, cGray, sigCol);
   PanelRow(25, xL, xR, y0, dy, corner, fsz, "SL / TP:", sltpVal, cGray, sltpCol);
   PanelRow(26, xL, xR, y0, dy, corner, fsz, "CISD:", cisdVal, cGray, cisdCol);

   if(ShowDailyPnL || ShowMultiPairInfo)
     {
      int aRow = 27;
      PanelRow(aRow++, xL, xR, y0, dy, corner, fsz, "--- ACCOUNT ---", "", cAqua, cAqua);
      if(ShowDailyPnL)
        {
         double realPnL  = CB_DailyRealizedPnL_Cached();
         double floatPnL = 0;
         for(int oi = 0; oi < OrdersTotal(); oi++)
           {
            if(!OrderSelect(oi, SELECT_BY_POS, MODE_TRADES)) continue;
            if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
               floatPnL += OrderProfit() + OrderSwap() + OrderCommission();
           }
         double totalDay = realPnL + floatPnL;
         double cbLimitMoney = CB_UsePercentOfBal
                               ? -(g_cbDayStartBalance * CB_MaxDailyLossPct / 100.0)
                               : -CB_MaxDailyLossMoney;
         double headroom = (UseCircuitBreaker && cbLimitMoney < 0) ? cbLimitMoney - totalDay : 0;
         color pnlCol = totalDay >= 0 ? cBull
                        : (cbLimitMoney < 0 && totalDay <= cbLimitMoney * 0.75 ? cBear : cOrange);
         string pnlStr = DoubleToString(totalDay, 2);
         PanelRow(aRow++, xL, xR, y0, dy, corner, fsz, "Day P&L:", pnlStr, cGray, pnlCol);
         string cbStr = !UseCircuitBreaker ? "CB OFF"
                        : (g_cbTotalTripped ? "TOTAL DD HALT"
                           : (g_cbTrippedToday ? "DAILY HALT"
                              : StringFormat("Hdroom: %.2f", headroom)));
         color cbStrCol = !UseCircuitBreaker ? cGray
                          : (g_cbTotalTripped || g_cbTrippedToday ? cBear : cBull);
         PanelRow(aRow++, xL, xR, y0, dy, corner, fsz, "CB Status:", cbStr, cGray, cbStrCol);
        }
      if(ShowMultiPairInfo)
        {
         int allMagic = 0;
         for(int oi = 0; oi < OrdersTotal(); oi++)
           {
            if(!OrderSelect(oi, SELECT_BY_POS, MODE_TRADES)) continue;
            if(OrderMagicNumber() == MagicNumber) allMagic++;
           }
         PanelRow(aRow, xL, xR, y0, dy, corner, fsz,
                  "All Magic:", IntegerToString(allMagic) + " open", cGray,
                  allMagic > 0 ? cWhite : cGray);
        }
     }

   Comment("");
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(SwingLength < 3 || InternalLength < 2 || HTFSwingLength < 3)
     {
      Print("SwingLength>=3, InternalLength>=2, HTFSwingLength>=3 required");
      return(INIT_PARAMETERS_INCORRECT);
     }

   BootstrapHistory();
   CB_UpdateDay();
   string gvKey = StringFormat("ICTV_InitBal_%d_%s", AccountNumber(), Symbol());
   if(CB_ResetInitialBalance || !GlobalVariableCheck(gvKey))
     {
      g_cbInitialBalance = AccountBalance();
      GlobalVariableSet(gvKey, g_cbInitialBalance);
      if(CB_ResetInitialBalance)
         Print("ICT-V circuit-breaker: initial balance RESET to ", DoubleToString(g_cbInitialBalance, 2));
     }
   else
      g_cbInitialBalance = GlobalVariableGet(gvKey);
   Journal_Init();
   Print("ICT-V circuit-breaker: day-start balance=", DoubleToString(g_cbDayStartBalance, 2),
         " broker day=", g_cbCurrentDay);
   Print("ICT-V trading hours: today='", TH_DayString(DayOfWeek()),
         "' entryAllowed=", (TH_EntryAllowed() ? "YES" : "NO"),
         " (broker time)");
   g_lastBarTime = iTime(Symbol(), Period(), 0);
   UpdateDashboard();

   if(UseNewsFilter)
     {
      FetchNewsCalendar();
      Print("ICT-V news: ", g_newsEventCount,
            " blocking event(s) loaded. Whitelist URL in Tools>Options>Expert Advisors>Allow WebRequest: ",
            NewsCalendarURL);
     }

   datetime now = TimeCurrent();
   int nyNow = NYTimeCode(now);

   // Ground truth: all platform clocks in one OnInit snapshot (no PC timezone inference)
   datetime tGmt    = TimeGMT();
   datetime tBroker = TimeCurrent();
   datetime tLocal  = TimeLocal();
   int offsetSec = (int)(tBroker - tGmt);
   Print("ICT-V TIME GROUND TRUTH | TimeGMT=", TimeToString(tGmt, TIME_DATE|TIME_SECONDS),
         " | TimeCurrent=", TimeToString(tBroker, TIME_DATE|TIME_SECONDS),
         " | TimeLocal=", TimeToString(tLocal, TIME_DATE|TIME_SECONDS),
         " | offset_sec=", offsetSec,
         " | offset_hrs=", DoubleToString(offsetSec / 3600.0, 2),
         " | BrokerGMTOffset input=", BrokerGMTOffset,
         " | ServerUtcOffsetSeconds=", ServerUtcOffsetSeconds());

   Print("ICT Validated SMC v1.6 EA v1.77 � LIVE trading ready.");
   Print("v1.77: Fix OB detection � use Pine candleOffset<500 not obShift>500 (full bootstrap pool)");
   Print("Pine parity: MinSigScore=", MinSignalScore, " HTFAlign=", RequireHTFAlign,
         " SigCooldown=", SignalCooldownBars, " MinOBScore=", MinOBDisplayScore,
         " AutoNYDST=", (UseAutoNYDST ? "ON" : "OFF"));
   Print("HTF structure: ", PanelHTFLabel(HTFTimeframe),
         " (PERIOD_", IntegerToString(HTFTimeframe), ")");
   Print("ICT-V broker offset: ", (UseICMarketsAutoOffset ? "IC Markets auto" : "manual"),
         " resolved=", (UseICMarketsAutoOffset ? ICMarketsBrokerUtcOffsetHours(TimeCurrent()) : BrokerGMTOffset),
         "h (raw ServerUtcOffsetSeconds()=", ServerUtcOffsetSeconds(), ")");
   Print("Killzone clock: broker=", TimeToString(now, TIME_DATE|TIME_MINUTES),
         " chartBar=", TimeToString(ChartBarTime(), TIME_DATE|TIME_MINUTES),
         " NY=", IntegerToString(nyNow / 100, 2, '0'), ":",
         StringFormat("%02d", nyNow % 100),
         " (UTC-", IntegerToString(GetNYSEasternOffsetHours(BarTimeToUtc(now))), ") session=",
         GetKZSessionName(now),
         " active=", (IsInKillzone(now) ? "YES" : "NO"));
   Print("KZ toggles: ShowKZ=", ShowKZ,
         " Asian=", KZAsian, " London=", KZLondon,
         " NY AM=", KZNYAM, " NY PM=", KZNYPM);
   Print("EnableTrading=", EnableTrading, " EnableSignals=", EnableSignals,
         " MinScore=", MinSignalScore, "/11 Magic=", MagicNumber);
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   DelPrefix(PFX);
   Comment("");
  }

double OnTester()
  {
   return(TesterStatistics(STAT_PROFIT_FACTOR));
  }

//+------------------------------------------------------------------+
//| Timer � display refresh only (no bar/trade logic)                |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // Intraday HTF catch-up on slow charts (D1/W1) � incremental only, no reset
   if(UseHTF && !g_bootstrapping)
      SyncHTFToTime(TimeCurrent());
   UpdateKillzoneState(ChartBarTime());
   UpdatePremiumDiscount(0);
   UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| Expert tick �" new bar only                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   MaybeRefreshNews();
   if(UseNewsFilter && NewsCloseOpenTrades && IsNewsBlackout(TimeCurrent()))
      CloseAllOurTrades();
   CB_IsTripped();   // intrabar equity-stop / flatten (entry gate also calls on new bars)
   TH_HandleEOD(); // once-per-day EOD flatten at broker time (if enabled)

   ManageOpenTrades();
   Journal_CheckNewTrades();

   if(!IsNewBar())
      return;

   g_barCounter++;

   UpdateSessionLevels();
   ProcessClosedBar(1);
   UpdatePremiumDiscount(0);
   UpdateKillzoneState(ChartBarTime());
   UpdateDashboard();
  }
//+------------------------------------------------------------------+
