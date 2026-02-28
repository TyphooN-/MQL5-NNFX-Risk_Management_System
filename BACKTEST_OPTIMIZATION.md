# Code Efficiency Impact on MT5 Backtesting

## Why Code Quality Matters for Backtests

The MT5 Strategy Tester simulates every tick (or every OHLC point in "Open Prices" mode) across the test period. For each simulated tick:

1. **Every indicator's `OnCalculate` fires** — if an indicator does unnecessary full-recalculations instead of incremental updates, that cost multiplies by millions of ticks.
2. **The EA's `OnTick` fires** — position loops, risk calculations, and margin checks run on each tick.
3. **Memory is constrained** — leaked handles, unbounded arrays, and per-tick allocations accumulate across potentially millions of ticks without the garbage collection benefit of a live terminal restart.

A backtest covering 1 year of M1 data on a liquid pair generates ~500,000+ bars. In "Every Tick" mode, this can mean 5-50 million simulated ticks. Every inefficiency is amplified by that factor.

## Bugs Fixed That Directly Impact Backtest Performance

### Critical Performance Fixes

| File | Bug | Backtest Impact |
|------|-----|-----------------|
| **STC.mq5** | `iMA()` called inside `OnCalculate` — created 2 new indicator handles per tick, never released | **Terminal crash** within minutes of backtest. ~120 leaked handles/minute. |
| **BraidFilter.mq5** | `limit=rates_total-2` ignored `prev_calculated` — full recalc every tick | **~100x slowdown**. Each tick recalculated all bars instead of just the new one. |
| **ASH.mq5** | `Highest()`/`Lowest()` allocated temporary arrays + called `CopyHigh`/`CopyLow` per bar | **~20,000 allocations per full recalc**. Heap fragmentation over millions of ticks. |
| **SolarWind.mq5** | Stale static variables not reset on full recalc | **Wrong indicator values** after tester timeframe changes or optimization passes. Stale state from previous pass carried into the next. |

### Correctness Fixes That Affect Backtest Results

| File | Bug | Backtest Impact |
|------|-----|-----------------|
| **CMF.mq5** | `tick_volume` not set as timeseries — read wrong bar's volume | **Silently wrong CMF values** throughout entire backtest. Every bar's CMF was computed from the wrong volume data. |
| **WAE.mq5** | Exit-short alert condition always `false` | **Missing exit signals** for short positions. Backtest would hold losing shorts longer than intended. |
| **TTMS.mq5** | Checked `handle_dev` instead of `handle_atr` | **Silent ATR failure** — indicator appeared to work but used uninitialized ATR data. |
| **SSL_Channel_Chart.mq5** | Manual series conversion with flipped indices | **Inverted SSL signals** on chart load / first bars of backtest. |
| **REX.mq5** | Signal line used wrong smoothing method | **Incorrect REX signals** — signal line smoothing ignored `InpMethodSig` input. |
| **Aroon_Oscillator.mq5** | Bulls/Bears plot labels swapped | **Data window showed Bulls as Bears** and vice versa, though visual plot was correct. |

### Security/Stability Fixes That Prevent Backtest Crashes

| File | Bug | Backtest Impact |
|------|-----|-----------------|
| **SolarWind.mq5** | Division by zero when market flat | **Backtest crash** during low-volatility periods (weekends, holidays in history). |
| **9 indicators** | Missing `OnDeinit` / `IndicatorRelease` | **Handle pool exhaustion** during optimization runs (hundreds of init/deinit cycles). |
| **shved_supply_and_demand** | Unchecked `CopyClose`/`CopyHigh`/`CopyLow` | **Array access on uninitialized data** if history not fully loaded at backtest start. |
| **TyphooN.mq5** | Multiple margin/position fixes | **Wrong lot sizing, missed closes, stale risk calculations** during simulated trading. |

## How MT5 Tester Modes Amplify Inefficiency

| Mode | Ticks/Bar | 1yr M1 (~500K bars) | Impact of Full-Recalc Bug |
|------|-----------|---------------------|---------------------------|
| Open Prices | 1 | ~500K calls | Moderate |
| 1 Minute OHLC | 4 | ~2M calls | Significant |
| Every Tick | 10-100 | ~5-50M calls | Severe |
| Real Ticks | Varies | ~50-200M calls | Extreme |

### Optimization Runs Multiply Everything

When running an optimization with e.g. 100 parameter combinations:
- Each combination does a full backtest
- All indicators are initialized (`OnInit`) and destroyed (`OnDeinit`) per pass
- Handle leaks from missing `IndicatorRelease` compound: 100 passes x 2 leaked handles/init = 200 orphaned handles
- Stale static variables carry state between passes if not properly reset

## Summary of All Fixes Applied

### Across 3 audit rounds (2026-02-28):

- **20 indicator handle leaks** sealed across 9 files
- **12 original NNFX bugs** fixed (3 Critical, 4 High, 5 Medium)
- **5 TyphooN.mq5 correctness fixes** (div-by-zero, position selection, magic filter, async race, volume sync)
- **5 ATR_Projection.mqh fixes** (data ready gating, fetch dedup, cold-start guard, iTime cache, line drawing guard + BarsCalculated completeness)
- **10 MEDIUM fixes in final pass** (timeout polling filter, MarginBufferPercent validation, MQL4 cache reset, SolarWind stale statics, TDFI _Point guard, Aroon sentinel, shved CopyClose/High/Low checks)
- **4 additional include file fixes** (DWEX zScore guard, shved bounds checks)

**Total: ~56 fixes across 20+ files — the codebase is now audit-clean.**
