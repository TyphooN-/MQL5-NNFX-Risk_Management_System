# TyAlgo NNFX Confluence EA -- Comprehensive Backtesting Plan

**EA Version**: TyAlgo v2.108
**Date**: March 2026

---

## Table of Contents
- [1. Test Environment Setup](#1-test-environment-setup)
- [2. Phase 1 -- Individual Slot Testing](#2-phase-1----individual-slot-testing)
- [3. Phase 2 -- Slot Combination Testing](#3-phase-2----slot-combination-testing)
- [4. Phase 3 -- Parameter Optimization](#4-phase-3----parameter-optimization)
- [5. Phase 4 -- Robustness Testing](#5-phase-4----robustness-testing)
- [6. Key Metrics to Track](#6-key-metrics-to-track)
- [7. Practical MT5 Strategy Tester Notes](#7-practical-mt5-strategy-tester-notes)
- [8. Recommended Test Combinations](#8-recommended-test-combinations----priority-order)
- [9. Testing Checklist and Record-Keeping](#9-testing-checklist-and-record-keeping)
- [10. Decision Criteria for Live Deployment](#10-decision-criteria-for-live-deployment)

---

## 1. Test Environment Setup

### 1.1 MT5 Strategy Tester Configuration

**Tester Mode Selection**:
- **Open Prices Only (M1 OHLC)**: Use for all Phase 1, 2, and 3 testing. TyAlgo evaluates signals only on `NewBar()` (the first tick of each new bar), so Open Prices mode captures the EA's actual decision points with ~100x less computation than Every Tick mode.
- **Every Tick based on real ticks**: Use only in Phase 3 (SL/TP final validation) and Phase 4 (robustness) where intra-bar fill quality and spread simulation matter.

**Deposit and Leverage**:
- Initial deposit: $10,000 USD (standardized across all tests for comparability)
- Leverage: 1:100 for forex, 1:1 for crypto
- Account currency: USD

**Execution**:
- Slippage: 10 points (realistic for forex majors on ECN)
- Commission: Match your broker (typical: $7/lot round-trip for forex ECN)

### 1.2 Required History Data

Download full history for all test symbols before beginning:
- **Minimum**: 5 years (2021-01-01 to 2026-01-01)
- **In-sample period**: 2021-01-01 to 2024-06-30 (3.5 years)
- **Out-of-sample period**: 2024-07-01 to 2026-01-01 (1.5 years)

Ensure history is available for **all timeframes** referenced by indicators:
- VaR module needs D1 data (at least StdDevPeriods+1 = 22 bars)
- MultiKAMA needs H1, H4, D1, W1, MN1
- MTF_MA needs M1, M5, M15, M30, H1, H4, D1, W1, MN1

### 1.3 Symbol Selection

| Tier | Symbols | Purpose |
|------|---------|---------|
| **Tier 1 -- Forex Majors** | EURUSD, GBPUSD, USDJPY, USDCHF, AUDUSD, NZDUSD, USDCAD | Primary test universe |
| **Tier 2 -- Forex Crosses** | EURJPY, GBPJPY, EURGBP, AUDNZD, CADJPY, EURAUD | Extended validation |
| **Tier 3 -- Exotics** | USDZAR, USDMXN, USDTRY, EURSEK | Phase 4 validation only |
| **Tier 4 -- Crypto** | BTCUSD, ETHUSD, SOLUSD | Separate testing (different volume behavior) |

### 1.4 Timeframe Selection

| Priority | Timeframe | Notes |
|----------|-----------|-------|
| Primary | D1 | NNFX standard; aligns with VaRTimeframe=D1 default |
| Secondary | H4 | Common NNFX alternative |
| Tertiary | H1 | Higher frequency, more trades, better statistical significance |

### 1.5 GV-Based Indicator Handling in Strategy Tester

Three indicator types communicate via GlobalVariables and **must be loaded via chart template**:
1. **MultiKAMA** -- writes `IsAbove_KAMA_{TF}_{Symbol}`
2. **EhlersFisherTransform** -- writes `FisherBias_{Symbol}_{Period}`
3. **MTF_MA** -- writes `GlobalBullPowerHTF_{Symbol}` and `GlobalBearPowerHTF_{Symbol}`

**Template setup**:
1. Open a chart with the test symbol, D1 timeframe
2. Attach MultiKAMA, EhlersFisherTransform, and MTF_MA indicators
3. Save as `tester.tpl` in `MQL5/Profiles/Templates/`
4. In Strategy Tester, reference this template

**iCustom-based slots do NOT need chart templates** -- the EA creates handles internally. These include: BL_SSMOOTHER, CF_EBSW, CF_DEC_OSC, CF_ROOF, CF_ARSI, VL_BETTER_VOL, EX_ARSI_FISCHER.

**Recommendation**: Prefer iCustom-based indicators in Phase 1/2 for easier batch testing. Test GV-based indicators in dedicated runs with appropriate templates.

---

## 2. Phase 1 -- Individual Slot Testing

**Objective**: Establish baseline performance of each indicator in each slot, with all other slots disabled (set to NONE).

**Duration**: In-sample period only (2021-01-01 to 2024-06-30)

**Fixed parameters for all Phase 1 tests**:
```
ATR_Period      = 14
SL_ATR_Multi    = 1.5
TP_ATR_Multi    = 1.0
RiskVaRPercent  = 1.0
VaRTimeframe    = D1
StdDevPeriods   = 21
VaRConfidence   = 0.95
MaxSpreadATRPct = 50.0
MagicNumber     = 42
```

**Symbols**: All Tier 1 forex majors | **Timeframe**: D1

### 2.1 Baseline Slot Tests

All other slots: `Confirm1=CF_NONE, Confirm2=CF_NONE, Volume=VL_NONE, Exit=EX_NONE`

| Test ID | BaselineType | Params | Signal Logic | Template? |
|---------|-------------|--------|--------------|-----------|
| BL-1a | BL_KAMA | BL_KAMA_TF=D1 | Price > KAMA = buy, < KAMA = sell | YES |
| BL-1b | BL_KAMA | BL_KAMA_TF=W1 | Same, weekly KAMA. Fewer, higher-conviction signals | YES |
| BL-1c | BL_KAMA | BL_KAMA_TF=H4 | Same, 4-hour KAMA. More responsive | YES |
| BL-2 | BL_SSMOOTHER | defaults | Close > SSmoother = buy, < = sell | NO |

### 2.2 Confirmation Slot Tests

All other slots: `Baseline=BL_NONE, Confirm2=CF_NONE, Volume=VL_NONE, Exit=EX_NONE`

| Test ID | Confirm1Type | Signal Logic | Template? |
|---------|-------------|--------------|-----------|
| CF-1 | CF_FISHER | Fisher > 0 = buy, < 0 = sell | YES |
| CF-2a | CF_MTF_MA | BullPower >= 10 AND BearPower < 10 = buy (and vice versa) | YES |
| CF-2b | CF_MTF_MA | Same with thresholds = 15 | YES |
| CF-2c | CF_MTF_MA | Same with thresholds = 5 | YES |
| CF-3 | CF_EBSW | EBSW > 0 = buy, < 0 = sell | NO |
| CF-4 | CF_DEC_OSC | DecOsc > 0 = buy, < 0 = sell | NO |
| CF-5 | CF_ROOF | Result > Signal = buy, < Signal = sell | NO |
| CF-6 | CF_ARSI | ARSI > 0.7 = buy, < 0.3 = sell, else neutral | NO |

**CF_ARSI note**: The wide 0.3-0.7 neutral zone produces fewer signals but higher conviction. Expect the lowest trade count.

### 2.3 Volume Slot Tests

Volume slots require a directional signal to function. Use BL_SSMOOTHER as a fixed baseline, then compare volume ON vs OFF:

| Test ID | VolumeType | Baseline | Template? |
|---------|-----------|----------|-----------|
| VL-0 | VL_NONE | BL_SSMOOTHER | NO (control) |
| VL-1 | VL_BETTER_VOL | BL_SSMOOTHER | NO |

**Evaluate**: Win rate improvement, profit factor improvement, percentage of entries blocked.

### 2.4 Exit Slot Tests

Use BL_SSMOOTHER + CF_EBSW as fixed entry, then compare exit strategies:

| Test ID | ExitType | Template? |
|---------|---------|-----------|
| EX-0 | EX_NONE | NO (control -- SL/TP only) |
| EX-1 | EX_FISHER | YES |
| EX-2 | EX_ARSI_FISCHER | NO |

**Exit behavior**: Exits fire independently of confluence, spread, and volume. They both protect profits and potentially cut winners short.

---

## 3. Phase 2 -- Slot Combination Testing

**Objective**: Combine best-performing indicators from Phase 1 into full NNFX configurations.

**Duration**: In-sample period (2021-01-01 to 2024-06-30)

**Symbols**: Start with EURUSD, GBPUSD, USDJPY; expand to all Tier 1 if promising.

### 3.1 Ranking Phase 1 Results

Before constructing combinations, filter Phase 1 results:
1. **Profit Factor** > 1.3 (minimum threshold)
2. **Max Drawdown** < 25%
3. **Total Trades** > 50 (statistical significance)
4. **Sharpe Ratio** > 0.5

### 3.2 Signal Decorrelation Rules

- **Baseline, C1, and C2 should use different indicator families** to avoid correlated signals
- **Ehlers family correlation warning**: CF_EBSW, CF_DEC_OSC, CF_ROOF, and CF_ARSI all share the `EhlersCommon.mqh` dominant cycle engine. Avoid pairing two Ehlers indicators in C1+C2. Pair one Ehlers with CF_FISHER or CF_MTF_MA instead.

### 3.3 Combination Matrix

| Combo | Baseline | Confirm 1 | Confirm 2 | Volume | Exit | Rationale |
|-------|---------|-----------|-----------|--------|------|-----------|
| **COMBO-1** | BL_KAMA (D1) | CF_FISHER | CF_EBSW | VL_BETTER_VOL | EX_ARSI_FISCHER | Classic NNFX: adaptive MA + momentum + cycle + volume + cycle exit |
| **COMBO-2** | BL_SSMOOTHER | CF_FISHER | CF_EBSW | VL_BETTER_VOL | EX_ARSI_FISCHER | Ehlers baseline variant; iCustom-only (no template needed except Fisher) |
| **COMBO-3** | BL_KAMA (D1) | CF_MTF_MA | CF_EBSW | VL_BETTER_VOL | EX_FISHER | Multi-TF trend + cycle; heaviest template |
| **COMBO-4** | BL_KAMA (D1) | CF_FISHER | CF_ROOF | VL_BETTER_VOL | EX_ARSI_FISCHER | Fisher + Roofing Filter |
| **COMBO-5** | BL_SSMOOTHER | CF_DEC_OSC | CF_FISHER | VL_BETTER_VOL | EX_ARSI_FISCHER | Ehlers entry + Fisher confirm |
| **COMBO-6** | BL_KAMA (W1) | CF_ARSI | CF_FISHER | VL_BETTER_VOL | EX_FISHER | High-conviction "sniper" config |
| **COMBO-7** | BL_KAMA (W1) | CF_EBSW | CF_MTF_MA | VL_BETTER_VOL | EX_ARSI_FISCHER | Weekly baseline, longer-term trends |
| **COMBO-8** | BL_SSMOOTHER | CF_ROOF | CF_MTF_MA | VL_BETTER_VOL | EX_FISHER | Roofing + multi-TF, no Fisher confirm |
| **COMBO-9** | BL_KAMA (D1) | CF_FISHER | CF_NONE | VL_BETTER_VOL | EX_ARSI_FISCHER | Minimal: baseline + single confirm + volume + exit |
| **COMBO-10** | BL_KAMA (D1) | CF_EBSW | CF_NONE | VL_NONE | EX_NONE | Ultra-minimal diagnostic test |

### 3.4 Template Groups (for batch efficiency)

| Group | Template Required | Combos |
|-------|------------------|--------|
| A (iCustom only) | None | COMBO-2, COMBO-5 (partially) |
| B (MultiKAMA) | MultiKAMA on chart | COMBO-9, COMBO-10 |
| C (MultiKAMA + Fisher) | MultiKAMA + EhlersFisherTransform | COMBO-1, COMBO-4, COMBO-6 |
| D (Full template) | MultiKAMA + EhlersFisherTransform + MTF_MA | COMBO-3, COMBO-7, COMBO-8 |

### 3.5 Combination Test Protocol

For each combination:
1. Run on EURUSD D1 first
2. If Profit Factor > 1.2 and Trades > 30, expand to remaining Tier 1 pairs
3. Record all metrics from Section 6
4. Rank by composite score: weighted sum of Sharpe, PF, Win Rate, Max DD

---

## 4. Phase 3 -- Parameter Optimization

**Objective**: For the top 3 combinations from Phase 2, optimize key parameters.

**Duration**: In-sample period (2021-01-01 to 2024-06-30)

**Mode**: MT5 Genetic Algorithm optimization

### 4.1 EA-Level Parameters

| Parameter | Default | Range | Step | Notes |
|-----------|---------|-------|------|-------|
| ATR_Period | 14 | 7-21 | 1 | ATR lookback for SL/TP |
| SL_ATR_Multi | 1.5 | 1.0-3.0 | 0.25 | Stop loss distance |
| TP_ATR_Multi | 1.0 | 0.5-2.0 | 0.25 | Take profit distance |
| RiskVaRPercent | 1.0 | 0.5-2.0 | 0.25 | VaR position sizing aggressiveness |
| MaxSpreadATRPct | 50.0 | 0, 25, 50, 75, 100 | 25 | Spread filter strictness |

**Estimated combinations**: 15 x 9 x 7 x 7 x 5 = 33,075 per symbol. Genetic algorithm samples ~500-2000.

### 4.2 MTF_MA Threshold Optimization

| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| C1_MTF_MinBullHTF | 10 | 5-25 | 5 |
| C1_MTF_MinBearHTF | 10 | 5-25 | 5 |
| C2_MTF_MinBullHTF | 10 | 5-25 | 5 |
| C2_MTF_MinBearHTF | 10 | 5-25 | 5 |

### 4.3 KAMA Timeframe Selection

Exhaustively test (small parameter space):
- PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1

### 4.4 Indicator-Specific Parameter Limitation

iCustom handles in TyAlgo are created with **default indicator parameters** (no forwarding of custom params). To test indicator-specific parameters, either:
1. Recompile indicators with different defaults as separate `.ex5` files
2. Use CUSTOM_GV slots with modified indicator versions
3. Modify TyAlgo to forward indicator parameters (future development)

### 4.5 Optimization Criterion

Use **Maximum Sharpe Ratio** from built-in criteria, or if OnTester() is added:
```
Custom = Sharpe * sqrt(Trades) * (1 - MaxDrawdown/InitialDeposit)
```

---

## 5. Phase 4 -- Robustness Testing

### 5.1 Out-of-Sample Validation

Run top 3 parameter sets on out-of-sample period (2024-07-01 to 2026-01-01) with **no parameter changes**.

**Pass criteria**:
- Profit Factor > 1.0
- Sharpe does not degrade > 50% from in-sample
- Max drawdown < 150% of in-sample max
- Win rate within 10pp of in-sample

### 5.2 Walk-Forward Analysis

| Window | Optimization Period | Validation Period |
|--------|-------------------|-------------------|
| WF-1 | 2021-01 to 2022-06 | 2022-07 to 2022-12 |
| WF-2 | 2021-07 to 2023-01 | 2023-01 to 2023-06 |
| WF-3 | 2022-01 to 2023-06 | 2023-07 to 2023-12 |
| WF-4 | 2022-07 to 2024-01 | 2024-01 to 2024-06 |
| WF-5 | 2023-01 to 2024-06 | 2024-07 to 2024-12 |
| WF-6 | 2023-07 to 2025-01 | 2025-01 to 2025-06 |

**Walk-forward efficiency** = (Avg validation Sharpe) / (Avg optimization Sharpe). Ratio > 0.5 indicates robust, non-overfit system.

### 5.3 Multi-Symbol Validation

Run final parameter set across all Tier 1, 2, and 3 symbols without per-symbol tuning.

**Pass criteria**:
- At least 70% of Tier 1 pairs profitable
- At least 50% of Tier 2 pairs profitable
- Average profit factor > 1.1

### 5.4 Monte Carlo Analysis

MT5 lacks built-in Monte Carlo. Options:
1. Export trade list, shuffle order 1000x in Python/Excel, compute drawdown distributions
2. Use third-party tools (Quant Analyzer, SQX) that accept MT5 HTML reports

**Target**: 95th percentile worst-case drawdown < 30%

### 5.5 Regime Testing

| Regime | Period | Characteristics |
|--------|--------|-----------------|
| COVID crash | 2020-02 to 2020-06 | Extreme volatility, USD strength |
| 2022 rate hikes | 2022-03 to 2022-12 | Strong trending USD |
| 2023 ranging | 2023-01 to 2023-12 | Rangebound majors |
| 2024-25 mixed | 2024-01 to 2025-06 | Geopolitical uncertainty |

NNFX systems are designed for trending conditions. Verify the system does not hemorrhage money during ranging markets.

---

## 6. Key Metrics to Track

### 6.1 Primary Metrics

| Metric | Target | Notes |
|--------|--------|-------|
| **Net Profit** | > $0 | Final balance - initial deposit |
| **Profit Factor** | > 1.3 | Gross profit / Gross loss |
| **Sharpe Ratio** | > 0.5 | Annualized: mean daily return / StdDev * sqrt(252) |
| **Max Drawdown %** | < 20% | Largest peak-to-trough equity decline |
| **Total Trades** | > 50 | Statistical significance |
| **Win Rate %** | > 40% | NNFX systems target 40-55% |

### 6.2 Secondary Metrics

| Metric | Target |
|--------|--------|
| Recovery Factor | > 2.0 (net profit / max drawdown) |
| Avg Win / Avg Loss | > 1.5 |
| Max Consecutive Losses | < 10 |
| Average Trade Duration | Document (1-20 bars typical on D1) |
| Monthly Return StdDev | Lower is better |
| Time in Market % | Document |

### 6.3 VaR-Specific Metrics

| Metric | Notes |
|--------|-------|
| Average Position Size (lots) | Should scale with equity growth |
| VaR Breach Count | Times daily P/L exceeded VaR estimate |
| VaR Efficiency | (Actual max daily loss) / (Predicted daily VaR) -- should be < 1.0 |

### 6.4 Signal Quality Metrics

| Metric | Notes |
|--------|-------|
| Entries Blocked by Spread | Bars where consensus existed but spread too wide |
| Entries Blocked by Volume | Bars where consensus existed but volume failed |
| Entries Blocked by Neutral | Bars where one or more active slots returned 0 |
| Exit-Triggered Closes | Positions closed by exit slot vs SL/TP |

---

## 7. Practical MT5 Strategy Tester Notes

### 7.1 Tester Mode by Phase

| Phase | Mode | Rationale |
|-------|------|-----------|
| Phase 1 | Open Prices Only | EA is bar-open-only. ~100x faster. Identical results. |
| Phase 2 | Open Prices Only | Speed critical for 10 combos x 7 pairs. |
| Phase 3 | Open Prices Only | Genetic optimization needs speed. |
| Phase 3 (SL/TP validation) | Every Tick (real ticks) | Validate fill quality. |
| Phase 4 (robustness) | Every Tick (real ticks) | Most realistic execution model. |

### 7.2 Chart Template Setup

1. Open chart on test symbol, D1 timeframe
2. Add indicators: MultiKAMA (Period=10, Fast=2, Slow=30), EhlersFisherTransform (Period=32), MTF_MA (defaults)
3. Save template as `tester.tpl` in `MQL5/Profiles/Templates/`
4. Reference in Strategy Tester settings

**GV naming is symbol-qualified**: All GV names include `_Symbol`, so template indicators and EA automatically match in the tester.

### 7.3 Optimization Settings

- **Slow complete algorithm**: For < 5,000 combinations (exhaustive grid)
- **Fast genetic algorithm**: For larger spaces. Criterion: Maximum Sharpe Ratio

### 7.4 Known Tester Considerations

1. **GV persistence**: GVs persist between optimization passes. Indicator deinit functions clean up, but verify between sessions.
2. **Handle pool**: All handle leaks have been fixed (see `BACKTEST_OPTIMIZATION.md`). Monitor memory during long optimizations.
3. **VaR cache**: 5-minute cache refreshes correctly with simulated time.
4. **Filling mode**: Ensure symbol execution mode matches your broker.

---

## 8. Recommended Test Combinations -- Priority Order

### 8.1 COMBO-1: The Classic NNFX Stack (test first)
```
Baseline  = BL_KAMA (D1)
Confirm1  = CF_FISHER
Confirm2  = CF_EBSW
Volume    = VL_BETTER_VOL
Exit      = EX_ARSI_FISCHER
```
**Rationale**: Maximum decorrelation. KAMA (trend-following) + Fisher (momentum) + EBSW (cycle) + BetterVolume (volume) + ARSI Fischer (cycle-reversal). No two slots share an analytical approach.

**Template**: MultiKAMA + EhlersFisherTransform

### 8.2 COMBO-2: All-iCustom Stack (easiest to batch test)
```
Baseline  = BL_SSMOOTHER
Confirm1  = CF_EBSW
Confirm2  = CF_ROOF
Volume    = VL_BETTER_VOL
Exit      = EX_ARSI_FISCHER
```
**Rationale**: No template needed. But all entry signals from Ehlers family -- test for correlation impact.

**Template**: None

### 8.3 COMBO-3: Multi-TF Trend + Ehlers Cycle
```
Baseline  = BL_KAMA (D1)
Confirm1  = CF_MTF_MA (MinBull=10, MinBear=10)
Confirm2  = CF_EBSW
Volume    = VL_BETTER_VOL
Exit      = EX_FISHER
```
**Rationale**: Three-layer trend+cycle+momentum. Heaviest template but unique multi-TF consensus.

**Template**: MultiKAMA + MTF_MA + EhlersFisherTransform

### 8.4 COMBO-6: High-Conviction Sniper
```
Baseline  = BL_KAMA (W1)
Confirm1  = CF_ARSI
Confirm2  = CF_FISHER
Volume    = VL_BETTER_VOL
Exit      = EX_FISHER
```
**Rationale**: Weekly baseline + ARSI wide neutral zone = very few, high-quality trades. Expect 20-40 trades/year. Needs extended test periods.

**Template**: MultiKAMA + EhlersFisherTransform

### 8.5 COMBO-10: Minimal Diagnostic (baseline benchmark)
```
Baseline  = BL_KAMA (D1)
Confirm1  = CF_EBSW
Confirm2  = CF_NONE
Volume    = VL_NONE
Exit      = EX_NONE
```
**Rationale**: If baseline + single confirmation can't produce positive expectancy, adding more filters won't help. Diagnostic test.

**Template**: MultiKAMA

---

## 9. Testing Checklist and Record-Keeping

### 9.1 Pre-Test Checklist

- [ ] History data downloaded for all symbols and timeframes
- [ ] All `.ex5` indicator files compiled in correct directories
- [ ] Chart template saved with required indicators (if using GV-based slots)
- [ ] Strategy Tester deposit, leverage, and commission match target broker
- [ ] Exact EA input parameters recorded in spreadsheet before starting

### 9.2 Results Spreadsheet Columns

| Column | Description |
|--------|-------------|
| Test ID | e.g., BL-1a, COMBO-1, OPT-1a |
| Phase | 1, 2, 3, or 4 |
| Symbol | EURUSD, etc. |
| Timeframe | D1, H4, H1 |
| Test Period | Start -- End dates |
| Tester Mode | Open Prices / Every Tick |
| Baseline | BL_NONE / BL_KAMA(D1) / BL_SSMOOTHER |
| Confirm1 | CF_NONE / CF_FISHER / CF_EBSW / ... |
| Confirm2 | CF_NONE / ... |
| Volume | VL_NONE / VL_BETTER_VOL |
| Exit | EX_NONE / EX_FISHER / EX_ARSI_FISCHER |
| ATR_Period | 14 |
| SL_ATR_Multi | 1.5 |
| TP_ATR_Multi | 1.0 |
| RiskVaRPercent | 1.0 |
| MaxSpreadATRPct | 50.0 |
| Net Profit | $ |
| Profit Factor | ratio |
| Sharpe Ratio | annualized |
| Max Drawdown % | % |
| Total Trades | count |
| Win Rate % | % |
| Recovery Factor | ratio |
| Avg Win / Avg Loss | ratio |
| Max Consec Losses | count |
| Notes | Observations |

### 9.3 Estimated Time Investment

| Phase | Runs | Time/Run (D1, 3.5yr, Open Prices) | Total |
|-------|------|-----------------------------------|-------|
| Phase 1 | ~12 tests x 7 pairs = 84 | ~2 min | ~3 hrs |
| Phase 2 | ~10 combos x 7 pairs = 70 | ~2 min | ~2.5 hrs |
| Phase 3 | ~3 combos x 7 pairs, genetic | ~30 min/opt | ~10 hrs |
| Phase 4 | ~3 combos x 20 pairs x 2 periods | ~3 min (ET) | ~6 hrs |
| **Total** | | | **~21.5 hrs** |

With 8 CPU cores (parallel tester agents), genetic optimization drops to ~1.5 hrs/combo.

---

## 10. Decision Criteria for Live Deployment

A configuration is viable for live deployment when **ALL** of the following are met:

1. **In-sample Profit Factor > 1.3** across at least 5 of 7 Tier 1 pairs
2. **Out-of-sample Profit Factor > 1.0** (profitable)
3. **Walk-forward efficiency > 0.5** (validation Sharpe >= 50% of optimization Sharpe)
4. **Max drawdown < 20%** in both in-sample and out-of-sample
5. **Total trades > 50** in the in-sample period
6. **Monte Carlo 95th percentile max drawdown < 30%**
7. **No single month with > 10% loss** in either period
8. **Profitable on >= 60% of symbols tested**

If no configuration meets all criteria, the system requires further development (indicator parameter tuning, new indicator integration via CUSTOM_GV, or slot logic refinements) before live deployment.
