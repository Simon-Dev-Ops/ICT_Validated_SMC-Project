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
