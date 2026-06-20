# ICT Validated SMC v1.6 EA — Settings Reference

**EA Version**: v2.00 (MQL4 port of Pine v1.6)
**Broker**: IC Markets Global — XAUUSD
**Updated**: 2026-06-20

---

## VALIDATED DEFAULT SETTINGS (BT6 — 2026-06-20)

These settings are now the EA defaults. They produced the best validated results across 6 backtests on XAUUSD M15.

**Backtest period**: 2025-10-09 → 2026-06-09 (8 months) | $10,000 deposit | Open-prices-only
**Result**: 793 trades | **59.52% win rate** | **$11,635 net profit** | **7.14% absolute drawdown** | PF 1.25
**FTMO status**: Passes total drawdown (7.14% < 10% limit). Enable CB + news filter for daily DD protection.
**Overall grade**: **B+**

| Parameter | Validated Value | Why |
|-----------|----------------|-----|
| `RequireCISD` | `true` | Biggest single improvement — added CISD confirmation, pushed win rate to 59.52% |
| `RequireHTFAlign` | `false` | HTF alignment not required; gives more trades with same win rate |
| `MinSignalScore` | `4` | Pine v1.6 default — sufficient with CISD filter active |
| `RiskMode` | `RM_BALANCE` | Balance-based risk; stable lot sizing for FTMO |
| `RiskPercent` | `1.0` | 1% per trade — FTMO-safe; absolute DD stayed at 7.14% |
| `UseTrailingStop` | `true` | Essential — transforms avg win from $47 to $121 |
| `TrailingStartPts` | `4000` | Activate trail after 400 pts (XAUUSD $4.00 move) |
| `TrailingDistancePts` | `2000` | Keep SL 200 pts behind price |
| `TrailingStepPts` | `400` | Move SL in 40-pt increments |
| `UseRMultipleBE` | `true` | Move SL to BE at 1R — protects partial profits |
| `UsePartialClose` | `true` | 50% at 1R, then BE, then 50% of remainder at 2R |

---

## QUICK SETUP CHECKLIST

BT6 defaults are already correct for signal quality and risk. Before going live, only these 3 steps are needed:

| # | Action | Input | Set To | Status |
|---|--------|-------|--------|--------|
| 1 | Confirm risk mode | `RiskMode` | `RM_BALANCE` | **Default ✓** |
| 2 | Confirm risk per trade | `RiskPercent` | `1.0` | **Default ✓** |
| 3 | Enable circuit-breaker | `UseCircuitBreaker` | `true` | Change from default |
| 4 | Enable news filter | `UseNewsFilter` | `true` | Change from default |
| 5 | Enable ECN mode | `ECNMode` | `true` (IC Markets Raw Spread) | Change from default |
| 6 | Confirm kill-switch | `EnableTrading` | `true` | **Default ✓** |

---

## S1 — MARKET STRUCTURE

Controls swing detection (Pine: structGroup).

| Input | Default | Description |
|-------|---------|-------------|
| `SwingLength` | `10` | Pivot lookback for external (major) swings. Higher = fewer, larger swings. **Do not change** — matched to Pine v1.6. |
| `InternalLength` | `5` | Pivot lookback for internal (minor) swings. **Do not change** — matched to Pine v1.6. |
| `ShowSwings` | `true` | Draw swing high/low dots on chart. Display only. |
| `ShowStructure` | `true` | Draw BOS/CHoCH labels. Display only. |
| `ShowInternalStructure` | `false` | Draw internal BOS/CHoCH. Display only. |
| `RequireBodyClose` | `false` | Require candle body (not wick) to break structure. Pine default = false. |

**Recommendation**: Leave all defaults. SwingLength and InternalLength are parity-locked.

---

## S2 — HIGHER TIMEFRAME (HTF)

| Input | Default | Description |
|-------|---------|-------------|
| `UseHTF` | `true` | Enable HTF structure analysis. Required for `RequireHTFAlign`. |
| `HTFTimeframe` | `PERIOD_H4` | HTF used for structure and signal alignment. H4 = default. |
| `HTFSwingLength` | `10` | Pivot lookback on HTF chart. |
| `ShowHTFStructure` | `true` | Draw HTF BOS/CHoCH. Display only. |

**Recommendation**: Keep H4. H1 is untested. M30 as chart TF + H4 as HTF is the validated combination.

---

## S3 — ORDER BLOCKS

| Input | Default | Description |
|-------|---------|-------------|
| `ShowOB` | `true` | Draw OB boxes on chart. |
| `OBMaxCount` | `5` | Max active OBs tracked per direction. |
| `RequireSweep` | `true` | OB only valid if liquidity sweep preceded it. Pine default. |
| `RequireDisplacement` | `true` | OB only valid if displacement candle followed. Pine default. |
| `ShowMitigatedOB` | `false` | Show OBs after price has entered them. Display only. |

**Recommendation**: Leave defaults — all matched and parity-locked.

---

## S3b — BREAKER BLOCKS

| Input | Default | Description |
|-------|---------|-------------|
| `ShowBreakers` | `true` | Draw breaker block boxes. Display only. |
| `BreakerMaxCount` | `5` | Max breakers tracked per direction. |

---

## S4 — FAIR VALUE GAPS (FVG)

| Input | Default | Description |
|-------|---------|-------------|
| `ShowFVG` | `true` | Draw FVG boxes. Display only. |
| `FVGMaxCount` | `5` | Max FVGs tracked per direction. |
| `FVGMinATRMult` | `1.0` | Minimum FVG size as ATR multiple. 0 = accept all gaps. |
| `ShowCE` | `true` | Show FVG equilibrium level. Display only. |
| `ShowMitigatedFVG` | `false` | Show already-filled FVGs. Display only. |
| `ShowIFVG` | `true` | Show Inverted FVGs. |
| `IFVGScorePoints` | `1` | Score weight assigned to IFVG confluence. |

---

## S4b — LIQUIDITY

| Input | Default | Description |
|-------|---------|-------------|
| `ShowLiquidity` | `true` | Draw liquidity levels. Display only. |
| `ShowEQHL` | `true` | Show equal highs/lows. Display only. |
| `EQTolerancePct` | `0.15` | How close levels must be to count as equal (%). |
| `ShowSweeps` | `true` | Draw sweep markers. Display only. |
| `SweepRequireWickReject` | `false` | Only call it a sweep if price wicks through and rejects. |

---

## S4c — BALANCED PRICE RANGE (BPR)

| Input | Default | Description |
|-------|---------|-------------|
| `ShowBPR` | `true` | Draw BPR overlapping FVG+OB zones. Display only. |

---

## S4d — INDUCEMENT (IDM)

| Input | Default | Description |
|-------|---------|-------------|
| `ShowIDM` | `true` | Draw inducement levels. Display only. |
| `IDMMaxCount` | `5` | Max IDM levels tracked per direction. |

---

## S5 — PREMIUM / DISCOUNT

| Input | Default | Description |
|-------|---------|-------------|
| `ShowPD` | `true` | Draw premium/discount range. Display only. |
| `ShowEQ` | `true` | Draw equilibrium line. Display only. |

---

## S6 — SESSION LEVELS

| Input | Default | Description |
|-------|---------|-------------|
| `ShowSessionLevels` | `true` | Draw session open/high/low levels. Display only. |
| `ShowPDHL` | `true` | Previous day high/low. Display only. |
| `ShowPWHL` | `true` | Previous week high/low. Display only. |

---

## S7 — KILLZONES & TIME

Critical for ICT method timing.

| Input | Default | Description |
|-------|---------|-------------|
| `ShowKZ` | `true` | Draw killzone shading on chart. |
| `UseICMarketsAutoOffset` | `true` | Auto GMT+2/+3 offset based on IC Markets DST calendar. **Keep true on IC Markets.** |
| `BrokerGMTOffset` | `0` | Manual GMT offset hours. Only used when `UseICMarketsAutoOffset=false`. |
| `UseAutoNYDST` | `true` | Auto-detect US DST for NY killzone timing. **Keep true.** |
| `NYUTCOffsetHours` | `4` | Manual NY UTC offset. Only used when `UseAutoNYDST=false`. |
| `KZAsian` | `false` | Show/detect Asian session killzone (00:00–04:00 NY). |
| `KZLondon` | `true` | London killzone (02:00–05:00 NY). |
| `KZNYAM` | `true` | NY AM killzone (07:00–10:00 NY). Primary entry window. |
| `KZNYPM` | `false` | NY PM killzone (13:30–16:00 NY). |
| `KZTransparency` | `92` | Transparency of killzone shading (0=solid, 100=invisible). |

**Recommendation**: Leave `UseICMarketsAutoOffset=true` and `UseAutoNYDST=true`. These are tested and parity-locked for IC Markets.

---

## S8 — OTE (Optimal Trade Entry)

| Input | Default | Description |
|-------|---------|-------------|
| `ShowOTE` | `true` | Draw OTE Fibonacci zones. Display only. |
| `OTEFibHigh` | `0.786` | Upper OTE fib level (Pine default 78.6%). |
| `OTEFibLow` | `0.618` | Lower OTE fib level (Pine default 61.8%). |
| `ShowOTEFibs` | `true` | Draw individual fib lines. Display only. |
| `OTEMaxCount` | `3` | Max OTE zones tracked per direction. |

---

## S9 — SIGNAL GENERATION

Core signal filter settings. Matched to Pine v1.6.

| Input | Default | Description |
|-------|---------|-------------|
| `EnableSignals` | `true` | Master switch for signal detection. |
| `MinSignalScore` | `4` | Minimum confluence score (out of 11) to fire a signal. Pine v1.6 default = 4. |
| `RequireHTFAlign` | `false` | Signal only fires if HTF structure agrees with direction. BT6 validated: false gives more trades with same win rate. |
| `RequireKillzone` | `false` | Signal only fires during active killzone window. |
| `RequireCISD` | `true` | Require Change In State of Delivery confirmation. **Key filter — do not disable.** Pushed win rate from 54% to 59.52%. |
| `ShowSigSL` | `true` | Draw signal SL on chart. Display only. |
| `ShowSigTP` | `true` | Draw signal TP on chart. Display only. |
| `SignalCooldownBars` | `10` | Bars to wait after a signal before another can fire. Pine default = 10. |
| `PineExactSignals` | `true` | v1.6 mode: use Pine's exact SL/TP, no buffer, allow na TP. Keep true for parity. |

**Recommendation**: Only raise `MinSignalScore` (to 5–6) if you want higher quality signals with fewer trades.

---

## S10 — CONFLUENCE SCORING

| Input | Default | Description |
|-------|---------|-------------|
| `ShowConfluence` | `true` | Show confluence score on OBs. Display only. |
| `MinOBDisplayScore` | `3` | Minimum score for an OB to be shown on chart. |

---

## S11 — EA RUNTIME

Debug logging options. Leave off for live trading.

| Input | Default | Description |
|-------|---------|-------------|
| `BootstrapMaxBars` | `0` | Max history bars to load on attach. `0` = full history. |
| `DebugStructure` | `true` | Log BOS/CHoCH events to Experts tab. Useful for monitoring. |
| `DebugZones` | `false` | Log OB/FVG/Breaker events. Only enable for debugging. |
| `DebugZoneAudit` | `false` | Dump all zones on attach for parity comparison. Dev tool only. |
| `DebugLogClosedBars` | `false` | Log every bar's signal score. Dev tool only. |
| `DebugCooldownRejects` | `false` | Log signals blocked by cooldown. Dev tool only. |
| `DebugNews` | `false` | Log news fetch/parse detail. Dev tool only. |

---

## S11b — CHART DISPLAY & ALERTS

| Input | Default | Description |
|-------|---------|-------------|
| `ShowChartDrawings` | `true` | Master switch for all chart objects (OBs, FVGs, etc.). |
| `DrawingMode` | `DM_MINIMAL` | `DM_MINIMAL` = key zones only; `DM_FULL` = all drawings. |
| `ShowInfoPanel` | `true` | Show the info panel (top-left). |
| `PanelLayout` | `PL_PINE` | `PL_PINE` = 2-column table (matches Pine). `PL_COMPACT` = dark rows. |
| `CompactPanel` | `false` | Show one-liner via Comment() instead of full panel. |
| `EnableAlerts` | `true` | MT4 Alert() popup on new signal. |
| `EnablePushNotify` | `false` | Push notification to MT4 mobile app on signal. |

---

## S12 — TRADE EXECUTION

The most important section for live trading.

| Input | Default | Recommended | Description |
|-------|---------|-------------|-------------|
| `EnableTrading` | `true` | `true` | Master kill-switch. Set `false` for signals-only mode. |
| `AllowLong` | `true` | `true` | Allow buy trades. |
| `AllowShort` | `true` | `true` | Allow sell trades. |
| `LotSize` | `0.02` | — | Fixed lot size (used when `RiskMode=RM_FIXED`). |
| `RiskMode` | `RM_BALANCE` | `RM_BALANCE` | Position sizing mode. `RM_BALANCE` = risk % of balance (FTMO recommended). `RM_FIXED` = fixed lots. |
| `RiskPercent` | `1.0` | `1.0` | % of balance risked per trade. 1% is FTMO-safe; BT6 produced 7.14% absolute DD at this level. |
| `MagicNumber` | `20260615` | Keep default | Identifies EA's orders. Don't change if you have open trades. |
| `MaxSpreadPoints` | `50` | `50` | Block trades if spread exceeds this. 50 pts = 0.5 pip on XAUUSD. |
| `Slippage` | `30` | `30` | Max allowed slippage in points. |
| `ECNMode` | `false` | **`true`** | IC Markets Raw Spread: sends order without SL/TP then attaches them via OrderModify. Required for ECN/NDD accounts to avoid "invalid stops" error. |
| `MaxPositionsPerDirection` | `1` | `1` (FTMO) | Max open trades per direction. 0 = unlimited. For FTMO keep at 1–2. |
| `UseSignalSLTP` | `true` | `true` | Use Pine signal's SL/TP levels. Keep true. |
| `SLBufferPoints` | `0` | `0` | Extra points added beyond signal SL. 0 = exact Pine SL. |
| `RequireTP` | `false` | `false` | Block trade if signal has no TP. Pine can fire with na TP. |
| `FallbackTP_RR` | `2.0` | `2.0` | If no TP from signal, compute TP at this RR. e.g. 2.0 = 2:1. |
| `UseBreakEven` | `false` | — | Points-based break-even. Use `UseRMultipleBE` instead (S16). |
| `BreakEvenTriggerPts` | `150` | — | Profit in points before points-BE activates. |
| `BreakEvenLockPts` | `10` | — | SL locks this many points beyond entry at BE. |
| `UseTrailingStop` | `true` | `true` | Points-based trailing stop. **Keep enabled** — transformed avg win from $47 to $121 in BT6. |
| `TrailingStartPts` | `4000` | `4000` | Profit in points before trail activates. 4000 pts = $4.00 move on XAUUSD. |
| `TrailingDistancePts` | `2000` | `2000` | Trail keeps SL this far behind price. 2000 pts = $2.00 below current price. |
| `TrailingStepPts` | `400` | `400` | Min SL movement per step. 400 pts = $0.40 — prevents micro-moves. |

---

## S13 — NEWS FILTER

Blocks new entries around high-impact news events. Uses ForexFactory XML feed.

| Input | Default | FTMO Live | Description |
|-------|---------|-----------|-------------|
| `UseNewsFilter` | `false` | **`true`** | Master switch. Enable for live trading. |
| `BlockRedNews` | `true` | `true` | Block during high-impact (red) events — NFP, FOMC, CPI, etc. |
| `BlockOrangeNews` | `false` | `false` | Block during medium-impact (orange) events. |
| `NewsMinutesBefore` | `15` | `15` | Start blocking this many minutes before event time. |
| `NewsMinutesAfter` | `15` | `15` | Keep blocking this many minutes after event. |
| `NewsCloseOpenTrades` | `false` | `false` | **Keep false** — existing trades run to their own SL/TP; only new entries are blocked. |
| `NewsOnlyUSD` | `true` | `true` | XAUUSD: only filter USD-tagged news events. |
| `NewsCalendarURL` | FF XML URL | Keep default | ForexFactory weekly calendar feed. Whitelist in MT4: Tools → Options → Expert Advisors → Allow WebRequest. |
| `NewsRefreshMinutes` | `60` | `60` | Re-download the news calendar every N minutes. |

**MT4 Setup Required**: Go to **Tools → Options → Expert Advisors → Allow WebRequest for listed URLs** and add `https://nfs.faireconomy.media`.

---

## S14 — RISK CIRCUIT-BREAKER

Halts trading if daily or total drawdown limits are breached. Pre-configured for FTMO rules.

| Input | Default | FTMO Live | Description |
|-------|---------|-----------|-------------|
| `UseCircuitBreaker` | `false` | **`true`** | Master switch. Enable for live trading. |
| `CB_UsePercentOfBal` | `true` | `true` | Use % of day-start balance as the daily limit. |
| `CB_MaxDailyLossPct` | `4.5` | `4.5` | Halt if daily realized + floating loss exceeds this %. FTMO limit is 5%; 4.5% gives safety margin. |
| `CB_MaxDailyLossMoney` | `0` | `0` | Fixed money daily loss limit. Only used when `CB_UsePercentOfBal=false`. |
| `CB_UseEquityStop` | `true` | `true` | Also monitor floating equity drop during the day. |
| `CB_EquityStopPct` | `4.5` | `4.5` | Halt if equity drops 4.5% from day-start balance. Catches open trade drawdown. |
| `CB_FlattenOnTrip` | `false` | `false` | **Keep false** — existing trades run to their own SL/TP when breaker trips; only new entries are blocked. Set `true` only if you want immediate market-close of all positions. |
| `CB_HaltUntilNextDay` | `true` | `true` | Stay halted until broker midnight. |
| `CB_MaxTotalLossPct` | `9.0` | `9.0` | **Permanent halt** if equity ever drops this % from the balance at EA start. FTMO max drawdown is 10%; 9% gives safety margin. Latches permanently — no new entries until EA is re-attached. |
| `CB_ResetInitialBalance` | `false` | `false` | Set `true` once to reset the total-drawdown baseline (e.g. starting a new FTMO phase). Then set back to `false`. |

**How it works:**
- Daily loss = realised closed P&L + open floating P&L for the broker day
- Total drawdown = drop from balance recorded when EA was first attached
- The total-DD baseline survives terminal restarts (stored in MT4 GlobalVariables)

---

## S15 — TRADING HOURS

Gates entry to specific broker-time windows. Optional — IC Markets killzones in S7 are the primary time filter.

| Input | Default | Description |
|-------|---------|-------------|
| `UseTradingHours` | `false` | Master switch. `false` = trade any time; `true` = use the day windows below. |
| `TH_Monday` | `"8-22"` | Allowed hours on Monday in broker server time. Format: `"8-22"` or `"8-10,14-16"`. Empty = no trading. |
| `TH_Tuesday` | `"8-22"` | |
| `TH_Wednesday` | `"8-22"` | |
| `TH_Thursday` | `"8-22"` | |
| `TH_Friday` | `"8-22"` | |
| `TH_Saturday` | `""` | Empty = closed. |
| `TH_Sunday` | `""` | Empty = closed. |
| `UseEODFlatten` | `false` | Flatten all open positions at EOD time and optionally block new entries. |
| `EODFlattenTime` | `"22:30"` | Broker time at which EOD flatten fires. |
| `EODBlockAfterFlatten` | `true` | After flatten, block new entries until next broker day. |

---

## S16 — ADVANCED EXITS (R-Multiple BE & Partials)

R-based scaling — preferred over the points-based S12 options.

| Input | Default | Description |
|-------|---------|-------------|
| `UseRMultipleBE` | `true` | Move SL to break-even when trade reaches a profit target in R. |
| `BE_AtR` | `1.0` | Move SL to BE when profit ≥ 1.0 × R (i.e. 1:1 risk reached). |
| `BE_LockR` | `0.0` | Lock SL this many R beyond entry (0 = exact BE, 0.1 = 0.1R above entry). |
| `UsePartialClose` | `true` | Master switch for partial position scaling. |
| `Partial1_AtR` | `1.0` | Take first partial close when profit ≥ 1.0 × R. |
| `Partial1_Pct` | `50` | Close 50% of current position at Partial 1. |
| `Partial1_ThenBE` | `true` | After Partial 1, move remaining SL to break-even. |
| `Partial2_AtR` | `2.0` | Take second partial when profit ≥ 2.0 × R. |
| `Partial2_Pct` | `50` | Close 50% of remaining position at Partial 2. |
| `MinPartialLots` | `0.01` | Never close/leave a remainder below broker minimum lot. |

**Default partial plan:**
1. At 1R → close 50%, move SL to BE
2. At 2R → close 50% of remainder
3. Runner continues to signal TP or until SL/BE hit

---

## FTMO CHALLENGE SETUP — RECOMMENDED SETTINGS SUMMARY

Most settings are already correct (BT6 defaults). Only these need to be changed before going live:

```
// Already set correctly by default (BT6 validated):
RiskMode               = RM_BALANCE   // ✓ default
RiskPercent            = 1.0          // ✓ default — 1% per trade
RequireCISD            = true         // ✓ default
UseTrailingStop        = true         // ✓ default
TrailingStartPts       = 4000         // ✓ default
TrailingDistancePts    = 2000         // ✓ default
TrailingStepPts        = 400          // ✓ default

// Enable these before live / FTMO (off by default — safety):
ECNMode                = true         // IC Markets Raw Spread account
UseNewsFilter          = true         // FTMO rule compliance
UseCircuitBreaker      = true         // FTMO rule compliance
CB_MaxDailyLossPct     = 4.5          // FTMO 5% daily; 4.5% safety margin
CB_MaxTotalLossPct     = 9.0          // FTMO 10% max DD; 9% safety margin
CB_FlattenOnTrip       = false        // let existing trades run to SL/TP

// Reset DD baseline at start of each FTMO phase:
// CB_ResetInitialBalance = true  → save → immediately back to false
```

---

## SETTINGS THAT SHOULD NOT BE CHANGED

These are parity-locked to Pine v1.6. Changing them breaks the signal match with TradingView:

- `SwingLength` = 10
- `InternalLength` = 5
- `HTFSwingLength` = 10
- `MinSignalScore` = 4 (raise only if you want fewer trades, not for parity)
- `SignalCooldownBars` = 10
- `PineExactSignals` = true
- `OTEFibHigh` = 0.786
- `OTEFibLow` = 0.618
- `UseICMarketsAutoOffset` = true
- `UseAutoNYDST` = true
