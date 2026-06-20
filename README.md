# ICT Validated SMC v1.6 — MT4 LIVE

Focused workspace for the MT4 Expert Advisor only.

```
ICT_Validated_SMC_v1.6_MT4_LIVE/
  MT4_LIVE/          ← edit & compile here
  Archive/           ← old EAs, MT5, indicator (ignore)
  Backup/            ← snapshots (ignore)
```

## Active files

| File | Role |
|------|------|
| `MT4_LIVE/ICT_Validated_SMC_v1.6_EA_LIVE.mq4` | **Authoritative MT4 EA** (v1.66) |
| `MT4_LIVE/ICT_Validated_SMC_v1.6.pine` | Pine Script v1.6 reference |
| `MT4_LIVE/ICT_Validated_SMC_v1.6_EA_LIVE.ex4` | Compiled output (after F7) |

## Compile

MetaEditor → open `MT4_LIVE/ICT_Validated_SMC_v1.6_EA_LIVE.mq4` → **F7**

```powershell
$src = "C:\Users\Ndumiso\Downloads\ICT_Validated_SMC_v1.6_MT4_LIVE\MT4_LIVE\ICT_Validated_SMC_v1.6_EA_LIVE.mq4"
& "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\metaeditor.exe" /compile:"$src" /log
```

## MT4 Experts folder (IC Markets)

`%APPDATA%\MetaQuotes\Terminal\34CCFFBCF44DF3B286F0ABD3E99B9869\MQL4\Experts`

Copy `.mq4` + `.ex4` after compile, or compile from that path.

## Do not use on chart

Old builds in `Archive/` — especially `ICT_Validated_SMC_EA`, `v1.6_EA`, v1.4.

---

## Validated Backtest Record

All tests: GOLD# (XAUUSD), M15, IC Markets, $10,000 initial deposit, 2025-10-09 → 2026-06-09 (8 months), open-prices-only model.

| # | Key Change | Trades | Win Rate | Net Profit | Max DD (equity) | Abs DD | PF | Grade |
|---|-----------|--------|----------|------------|-----------------|--------|----|-------|
| BT1 | Default (no trail, fixed 0.02 lot) | ~218 | ~72% | ~$1,758 | — | — | ~1.04 | D+ |
| BT2 | Trail 4000/2000/400, fixed 0.02 lot | ~325 | ~54% | ~$9,791 | ~33.89% | — | — | C+ |
| BT3 | +RequireHTFAlign=true, MinScore=5 | fewer | ~54% | ~$15,454 | — | — | — | C+ |
| BT4 | +RequireCISD=true, 1.5% risk | 793 | 59.52% | $21,402 | 16.84% | — | 1.24 | B |
| **BT5** | Same as BT4 (confirmed settings) | **793** | **59.52%** | **$21,402** | **16.84%** | — | **1.24** | **B** |
| **BT6** | Risk 1.5% → 1.0% (FTMO target) | **793** | **59.52%** | **$11,635** | **11.17%** | **$714 (7.14%)** | **1.25** | **B+** |

### BT6 Grade Card — Current Default Settings

> BT6 is the configuration now embedded as EA defaults.

| Category | Result | Grade | Notes |
|----------|--------|-------|-------|
| Win Rate | 59.52% | A- | Achieved the 60% target; balanced: Long 59.3% / Short 59.7% |
| Net Profit | $11,635 on $10k | A- | 116% in 8 months; note open-prices-only inflates returns |
| Profit Factor | 1.25 | C+ | Acceptable; > 1.5 = good, > 2.0 = excellent |
| FTMO Abs DD | $714 (7.14%) | A | Lowest equity from $10k start = $9,286 — FTMO floor is $9,000 |
| FTMO Daily DD | Not breached (in test) | B | Max 7 consec. losses = $1,455 — CB not active in backtest |
| Avg RR | 0.85:1 ($121 win / $143 loss) | C+ | Below 1:1; win rate carries profitability |
| Largest Win | $2,299 | A | Trailing stop capturing big runners |
| Max Consec. Losses | 7 (-$1,455 total) | B- | Spread over time; enable CB for live protection |
| Directional Balance | Long 59.3% / Short 59.7% | A | No directional bias; strategy works both ways |

**Overall BT6 Grade: B+**

FTMO-compliant on total drawdown. Win rate at target. Primary risk: avg loss > avg win (0.85:1 RR) means profitability depends on win rate staying above ~55%. Enable `UseCircuitBreaker=true` and `UseNewsFilter=true` before live/funded use.

### BT6 Complete Settings Record (2026-06-20)

Use this as a checklist when setting up the EA in MT4. Work through each tab top to bottom.

---

#### S1 — Market Structure

| Parameter | Value | Note |
|-----------|-------|------|
| SwingLength | **10** | Do not change — parity locked |
| InternalLength | **5** | Do not change — parity locked |
| ShowSwings | true | Display only |
| ShowStructure | true | Display only |
| ShowInternalStructure | false | |
| RequireBodyClose | false | |

---

#### S2 — Higher Timeframe

| Parameter | Value | Note |
|-----------|-------|------|
| UseHTF | **true** | |
| HTFTimeframe | **4 Hours** | Primary alignment reference |
| HTFSwingLength | **10** | |
| ShowHTFStructure | true | Display only |

---

#### S3 — Order Blocks

| Parameter | Value | Note |
|-----------|-------|------|
| ShowOB | true | |
| OBMaxCount | **5** | |
| RequireSweep | **true** | OB only valid after liquidity sweep |
| RequireDisplacement | **true** | OB only valid with displacement candle |
| ShowMitigatedOB | false | |

---

#### S3b — Breaker Blocks

| Parameter | Value | Note |
|-----------|-------|------|
| ShowBreakers | true | |
| BreakerMaxCount | **5** | |

---

#### S4 — Fair Value Gaps

| Parameter | Value | Note |
|-----------|-------|------|
| ShowFVG | true | |
| FVGMaxCount | **5** | |
| FVGMinATRMult | **1.0** | Minimum gap size vs ATR |
| ShowCE | true | Display only |
| ShowMitigatedFVG | false | |
| ShowIFVG | true | |
| IFVGScorePoints | **1** | |

---

#### S4b — Liquidity

| Parameter | Value | Note |
|-----------|-------|------|
| ShowLiquidity | true | |
| ShowEQHL | true | |
| EQTolerancePct | **0.15** | |
| ShowSweeps | true | |
| SweepRequireWickReject | false | |

---

#### S4c — Balanced Price Range

| Parameter | Value | Note |
|-----------|-------|------|
| ShowBPR | true | |

---

#### S4d — Inducement (IDM)

| Parameter | Value | Note |
|-----------|-------|------|
| ShowIDM | true | |
| IDMMaxCount | **5** | |

---

#### S5 — Premium / Discount

| Parameter | Value | Note |
|-----------|-------|------|
| ShowPD | true | Display only |
| ShowEQ | true | Display only |

---

#### S6 — Session Levels

| Parameter | Value | Note |
|-----------|-------|------|
| ShowSessionLevels | true | |
| ShowPDHL | true | |
| ShowPWHL | true | |

---

#### S7 — Killzones & Time

| Parameter | Value | Note |
|-----------|-------|------|
| ShowKZ | true | |
| UseICMarketsAutoOffset | **true** | Keep true on IC Markets — auto GMT+2/+3 |
| BrokerGMTOffset | 0 | Only used if auto offset is off |
| UseAutoNYDST | **true** | Keep true — auto US daylight saving |
| NYUTCOffsetHours | 4 | Only used if auto DST is off |
| KZAsian | **false** | Asian session not used |
| KZLondon | **true** | London killzone active |
| KZNYAM | **true** | NY AM killzone active — primary entry window |
| KZNYPM | **false** | NY PM not used |
| KZTransparency | 92 | |

---

#### S8 — OTE

| Parameter | Value | Note |
|-----------|-------|------|
| ShowOTE | true | |
| OTEFibHigh | **0.786** | Do not change — parity locked |
| OTEFibLow | **0.618** | Do not change — parity locked |
| ShowOTEFibs | true | Display only |
| OTEMaxCount | **3** | |

---

#### S9 — Signal Generation

| Parameter | Value | Note |
|-----------|-------|------|
| EnableSignals | **true** | |
| MinSignalScore | **4** | Minimum confluence score out of 11 |
| RequireHTFAlign | **false** | BT6 validated: false gives more trades, same win rate |
| RequireKillzone | **false** | |
| RequireCISD | **true** | KEY FILTER — single biggest improvement, pushed win rate to 59.52% |
| ShowSigSL | true | Display only |
| ShowSigTP | true | Display only |
| SignalCooldownBars | **10** | Do not change — parity locked |
| PineExactSignals | **true** | Keep true — uses Pine exact SL/TP |

---

#### S10 — Confluence Scoring

| Parameter | Value | Note |
|-----------|-------|------|
| ShowConfluence | true | Display only |
| MinOBDisplayScore | **3** | |

---

#### S11 — EA Runtime

| Parameter | Value | Note |
|-----------|-------|------|
| BootstrapMaxBars | **0** | 0 = load full history |
| DebugStructure | true | Logs BOS/CHoCH to Experts tab |
| DebugZones | false | Leave off for live trading |
| DebugZoneAudit | false | |
| DebugLogClosedBars | false | |
| DebugCooldownRejects | false | |
| DebugNews | false | |

---

#### S11b — Display & Alerts

| Parameter | Value | Note |
|-----------|-------|------|
| ShowChartDrawings | true | |
| DrawingMode | **signals, SL/TP, structure breaks** | DM_MINIMAL |
| ShowInfoPanel | true | |
| PanelLayout | **two-column Pine v1.6 table** | PL_PINE |
| CompactPanel | false | |
| EnableAlerts | true | MT4 popup on signal |
| EnablePushNotify | false | Enable if using MT4 mobile app |

---

#### S12 — Trade Execution

| Parameter | Value | Note |
|-----------|-------|------|
| EnableTrading | **true** | Set false for signals-only mode |
| AllowLong | **true** | |
| AllowShort | **true** | |
| LotSize | 0.02 | Fallback only — not used when RiskMode = RM_BALANCE |
| RiskMode | **RM_BALANCE** | Risk % of account balance |
| RiskPercent | **1.0** | 1% per trade — FTMO safe |
| MaxLotCap | 0.00 | 0 = no cap |
| AllowEquityMode | false | |
| MagicNumber | 20260615 | Auto-derived — do not change with open trades |
| MaxSpreadPoints | **50** | Blocks trades if spread is too wide |
| Slippage | **30** | |
| ECNMode | false | **Set true for IC Markets Raw Spread (live)** |
| MaxPositionsPerDirection | **1** | |
| UseSignalSLTP | **true** | |
| SLBufferPoints | **0** | Exact Pine SL, no buffer |
| RequireTP | **false** | Allow signals without TP |
| FallbackTP_RR | **2.0** | If no swing TP: 2:1 RR fallback |
| UseBreakEven | **false** | Points-based BE off — use S16 R-multiple instead |
| BreakEvenTriggerPts | 150 | Inactive since UseBreakEven = false |
| BreakEvenLockPts | 10 | Inactive since UseBreakEven = false |
| UseTrailingStop | **true** | Essential — transformed avg win from $47 to $121 |
| TrailingStartPts | **4000** | Activate trail after 400 pts profit ($4.00 on XAUUSD) |
| TrailingDistancePts | **2000** | Keep SL 200 pts ($2.00) behind price |
| TrailingStepPts | **400** | Move SL in 40-pt ($0.40) increments |

---

#### S13 — News Filter

| Parameter | Value | Note |
|-----------|-------|------|
| UseNewsFilter | **false** | **Set true for live / FTMO** |
| BlockRedNews | true | NFP, FOMC, CPI etc. blocked when filter is on |
| BlockOrangeNews | false | |
| NewsMinutesBefore | **15** | |
| NewsMinutesAfter | **15** | |
| NewsCloseOpenTrades | **false** | Existing trades run to their own SL/TP |
| NewsOnlyUSD | **true** | XAUUSD: USD events only |
| NewsCalendarURL | https://nfs.faireconomy.media/ff_calendar_thisweek.xml | Whitelist in MT4 options |
| NewsRefreshMinutes | **60** | |

---

#### S14 — Risk Circuit-Breaker

| Parameter | Value | Note |
|-----------|-------|------|
| UseCircuitBreaker | **false** | **Set true for live / FTMO** |
| CB_UsePercentOfBal | true | % of day-start balance |
| CB_MaxDailyLossPct | **4.5** | Halts at 4.5% daily loss (FTMO limit is 5%) |
| CB_MaxDailyLossMoney | 0 | Inactive — using % mode |
| CB_UseEquityStop | true | Also monitors floating equity |
| CB_EquityStopPct | **4.5** | Halts if equity drops 4.5% intraday |
| CB_FlattenOnTrip | **false** | Existing trades run to SL/TP when CB trips |
| CB_HaltUntilNextDay | true | Stay halted until broker midnight |
| CB_MaxTotalLossPct | **9.0** | Permanent halt at 9% total DD (FTMO limit is 10%) |
| CB_ResetInitialBalance | false | Set true once at start of new FTMO phase, then back to false |

---

#### S14b — Daily Profit Lock

| Parameter | Value | Note |
|-----------|-------|------|
| UseDailyProfitLock | false | Optional — enable to protect daily gains |
| DailyProfitLockPct | 2.0 | Stop new entries once daily P&L hits 2% |

---

#### S15 — Trading Hours

| Parameter | Value | Note |
|-----------|-------|------|
| UseTradingHours | **false** | Killzones in S7 handle timing — this gate not needed |
| TH_Monday | 8-22 | Inactive since UseTradingHours = false |
| TH_Tuesday | 8-22 | |
| TH_Wednesday | 8-22 | |
| TH_Thursday | 8-22 | |
| TH_Friday | 8-22 | |
| TH_Saturday | (empty) | Closed |
| TH_Sunday | (empty) | Closed |
| UseEODFlatten | false | |
| EODFlattenTime | 22:30 | |
| EODBlockAfterFlatten | true | |

---

#### S16 — Advanced Exits

| Parameter | Value | Note |
|-----------|-------|------|
| UseRMultipleBE | **true** | Move SL to BE at 1R profit |
| BE_AtR | **1.0** | Trigger BE when profit = 1× initial risk |
| BE_LockR | **0.0** | Exact break-even (no extra lock-in) |
| UsePartialClose | **true** | Scale out in two stages |
| Partial1_AtR | **1.0** | First partial close at 1R |
| Partial1_Pct | **50** | Close 50% of position at Partial 1 |
| Partial1_ThenBE | **true** | Move SL to BE after Partial 1 fires |
| Partial2_AtR | **2.0** | Second partial close at 2R |
| Partial2_Pct | **50** | Close 50% of remainder at Partial 2 |
| MinPartialLots | **0.01** | Never leave a fragment below broker minimum lot |

---

#### S17 — Trade Journal

| Parameter | Value | Note |
|-----------|-------|------|
| UseTradeJournal | **true** | Logs each closed trade to CSV |
| JournalFileName | ICT_SMC_Journal.csv | File saved in MQL4/Files/ |

---

#### S18 — Safety Gates

| Parameter | Value | Note |
|-----------|-------|------|
| UseMaxTradesPerDay | false | Enable to cap daily trade count |
| MaxTradesPerDay | 3 | Inactive since UseMaxTradesPerDay = false |
| UseMaxConsecLosses | false | Enable to halt after losing streak |
| MaxConsecLosses | 3 | Inactive since UseMaxConsecLosses = false |
| UseFridayCutoff | false | Enable to block Friday late entries |
| FridayCutoffTime | 20:00 | Inactive since UseFridayCutoff = false |
