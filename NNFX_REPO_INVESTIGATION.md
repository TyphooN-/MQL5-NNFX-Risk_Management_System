# NNFX Open-Source Repo Investigation

Investigation of all notable open-source NNFX (No Nonsense Forex) repositories on GitHub, evaluated against the TyphooN Risk Management System (v1.405) for potential integration value.

**Verdict: None of these repos provide code worth integrating.** TyphooN is a production live-trading EA with sophisticated risk management; every repo found is either a backtesting harness, an educational template, or a trivial single-purpose indicator. The only actionable takeaways are architectural ideas (news filtering, currency exposure tracking) that would need to be implemented from scratch.

---

## Repos Investigated

| # | Repository | Stars | Purpose | Last Active | Verdict |
|---|---|---|---|---|---|
| 1 | alexcercos/AlgoMasterNNFX-V1 | 10 | Multi-pair NNFX backtester | 2024-02 | No value |
| 2 | stfl/backtestd-expert | 7 | NNFX backtesting EA + Rust CLI | 2021-06 | No value (abandoned) |
| 3 | OpenNNFX | ~7 | Educational NNFX template | ~2020 | No value (skeleton) |
| 4 | geekhead/No_Nonsense_ATR | ~3 | Single ATR indicator | ~2020 | No value (ATR_Projection far superior) |
| 5 | ~19 other NNFX-tagged repos | 0-5 | Misc forks, configs, scripts | Varies | No value |

---

## 1. alexcercos/AlgoMasterNNFX-V1

**What it is:** A multi-pair NNFX algorithm backtester for MT5 (with partial MT4 support). Tests user-configured indicator stacks across all 28 standard forex pairs simultaneously in the strategy tester. The open-source V1 is the legacy version of a commercial product (AlgoMaster NNFX on MQL5 Market).

**Architecture:**
- `AlgoMasterNNFX.mqh` — main wiring: indicator handle setup, pair iteration, event routing
- `Backtester/GenericBacktester.mqh` — abstract base: signal evaluation, state machine, virtual trade management
- `Backtester/CompleteNNFXTester.mqh` — full tester: EVZ, news, exposure, compound interest, equity curve
- `Backtester/VirtualTrades.mqh` — simulated position objects (not real trades)
- `CrossProjects/NewsImport.mqh` — ForexFactory web scraper for news event filtering
- `Other/RPN.mqh` — custom optimization formula evaluator (Reverse Polish Notation)

**Signal slots:** Baseline, C1, C2, Volume, Exit, Continuation — with 11+ read modes (zero-line cross, two-lines cross, color buffer, chart dot, etc.)

**NNFX rules:** Pullback rule, one-candle rule, bridge-too-far, baseline ATR distance gate, continuation catch-up, scale-out with trailing.

**Filters:** EVZ (Euro FX Vix from Yahoo Finance), ForexFactory news scraper, currency exposure limiter (heap-based).

| Feature | AlgoMasterNNFX | TyphooN v1.403 |
|---|---|---|
| Purpose | Backtester / optimizer | Live production EA |
| Live trading | Experimental only | Primary function |
| Risk management | ATR SL/TP (virtual) | ATR SL/TP + martingale TRIM/HARVEST/PROTECT |
| Break-even | None | Tick-rounded, ECN-safe |
| Multi-TF ATR | None | ATR_Projection (6 timeframes) |
| UI | None (tester only) | Full chart button panel |
| Cross-platform | MT5 + partial MT4 | MT5 + MT4 via .mqh |
| News filter | ForexFactory scraper | Not present |
| Currency exposure | Heap-based limiter | Not present |

**Integration value:** The ForexFactory news scraper (`CrossProjects/NewsImport.mqh`) is the only component with potential practical value — it's a tested implementation of parsing ForexFactory's weekly calendar via `WebRequest`. However, it's fragile (raw HTML parsing) and would need rewriting for production use. The currency exposure controller and RPN evaluator address problems TyphooN doesn't currently have. Everything else is backtester-specific infrastructure.

**Verdict: No code worth integrating. Architectural ideas (news filtering, exposure tracking) noted.**

---

## 2. stfl/backtestd-expert

**What it is:** An MQL5 backtesting EA designed to be driven by a companion Rust CLI tool (`backtestd`) for mass indicator screening. Built on MQL5's standard `CExpert` framework.

**Architecture:**
- `BacktestExpert.mqh` — CExpert subclass with 12-state NNFX state machine
- `AggSignal.mqh` — aggregates Baseline/C1/C2/Volume/Exit/Continue signal slots
- `CustomSignal.mqh` / `CSignalFactory` — polymorphic signal classes, any indicator loadable at runtime via filename + buffer indices + 15 params
- `TrailingAtr.mqh` — ATR trailing stop
- `MoneyFixedRiskFixedBalance.mqh` — fixed-balance risk sizing for reproducible backtests
- `DatabaseFrames.mqh` — SQLite frame storage for optimization runs

**Custom metrics:** CVaR (Conditional Value at Risk), WinRate, VaR — implemented in `OnTester()`.

**Pre-built signal classes:** ~30+ including WAE, SSL, Kijun-Sen, Aroon, COG, Chaikin, STC, AO, REX, SuperTrend, and various custom MAs.

| Feature | backtestd-expert | TyphooN v1.403 |
|---|---|---|
| Purpose | Backtesting / indicator screening | Live production EA |
| Live trading | Explicitly warned against | Primary function |
| Risk management | Basic ATR SL/TP | Full TRIM/HARVEST/PROTECT tiers |
| Break-even | Raw price (no tick rounding) | Tick-rounded, ECN-safe |
| Multi-symbol | Up to 50 symbols per instance | Per-symbol deployment |
| Platform | MT5 only | MT5 + MT4 |
| Maintenance | Abandoned (2021), 10 open issues, no license | Active (v1.403, Feb 2026) |

**Integration value:** Nothing. The code is abandoned, has no license (legally ambiguous), has known bugs (invalid stops), and lacks every live-trading safety feature TyphooN has. The CVaR/WinRate `OnTester()` calculation (~50 lines) is the only piece worth referencing if building a separate screening tool.

**Verdict: No value. Dead project.**

---

## 3. OpenNNFX

**What it is:** An educational NNFX template/skeleton. Approximately 7 stars. Provides a basic framework showing how NNFX signal slots could be structured.

**Integration value:** None. It's a teaching tool with no production-quality code. TyphooN's signal architecture is already far more mature.

**Verdict: No value. Educational skeleton only.**

---

## 4. geekhead/No_Nonsense_ATR vs ATR_Projection

This is the detailed comparison the user requested.

### No_Nonsense_ATR

A single-purpose MT4 indicator that draws daily ATR projection lines (period open +/- ATR value). Approximately 3 stars on GitHub.

**Capabilities:**
- Single timeframe: D1 only
- MT4 only (no MT5 support)
- Draws two horizontal lines: daily open + ATR, daily open - ATR
- Fixed ATR period (14)
- Basic line styling (color, width)
- No info overlay, no anomaly detection
- Recalculates every tick (no optimization)

### ATR_Projection (TyphooN's)

A production-grade multi-timeframe ATR projection indicator with cross-platform support.

**Capabilities:**
- 6 timeframes: M15, H1, H4, D1, W1, MN1 (each individually togglable)
- Cross-platform: MT5 + MT4 via `#ifdef __MQL5__`/`__MQL4__`
- Draws 12 projection lines (upper + lower per timeframe)
- Configurable ATR period
- Full line styling (style, thickness, color, background toggle)
- On-chart info overlay showing ATR values for all 6 timeframes
- Anomaly detection: text turns magenta when lower-TF ATR exceeds higher-TF ATR
- Timeframe auto-filtering: suppresses irrelevant lines based on chart timeframe
- Performance optimized:
  - Tick change detection (skips identical bid/ask ticks)
  - M15 interval batching (ATR/candle data refreshed every 15 minutes, not every tick)
  - Cached object name strings (allocated once in OnInit, not per-tick)
  - Deferred string concatenation (only rebuilds info text when values change)
  - Color change detection (only updates object color when it actually changes)

### Side-by-Side Comparison

| Feature | No_Nonsense_ATR | ATR_Projection |
|---|---|---|
| Timeframes | D1 only | M15, H1, H4, D1, W1, MN1 |
| Platform | MT4 only | MT5 + MT4 |
| Lines drawn | 2 (D1 high/low) | Up to 12 (2 per TF) |
| ATR period | Fixed 14 | Configurable |
| Info overlay | None | 6-TF ATR values on chart |
| Anomaly detection | None | Magenta color when lower > higher TF ATR |
| TF auto-filter | None | Hides irrelevant lines per chart TF |
| Line customization | Color, width | Style, thickness, color, background |
| Tick optimization | None (recalc every tick) | Bid/ask change detection + M15 batching |
| Object caching | None | Cached name strings, lazy object creation |
| String optimization | None | Deferred concat behind value-change check |
| Code size | ~50 lines | ~420 lines |
| Production readiness | Hobby project | Production-grade |

**Verdict: ATR_Projection is superior in every dimension.** No_Nonsense_ATR is a minimal D1-only prototype. ATR_Projection covers 6 timeframes, both platforms, includes anomaly detection, and has extensive per-tick performance optimization. There is nothing to gain from No_Nonsense_ATR.

---

## 5. Other NNFX-Tagged Repos on GitHub

A scan of the `nnfx` GitHub topic found ~19 repos total. The top 5 by stars are covered above. The remainder are:

- Personal config repos (indicator settings, pair lists)
- Abandoned forks of the repos above
- YouTube tutorial companion code
- Single-indicator experiments
- Non-MQL repos (Python scripts for backtesting NNFX with pandas)

None had more than 5 stars. None contained code of integration value.

---

## Architectural Ideas Worth Noting

While no code is worth importing, three architectural concepts from the NNFX ecosystem are worth considering for future TyphooN development:

1. **News event filtering** — Block entries around high-impact economic events. AlgoMasterNNFX's ForexFactory scraper demonstrates the approach (WebRequest + HTML parsing + per-currency keyword matching). Would need clean-room implementation for production use.

2. **Currency exposure tracking** — Prevent overexposure to a single currency across multiple chart instances. Relevant if TyphooN is ever deployed across many pairs simultaneously. AlgoMasterNNFX uses a heap-based limiter.

3. **EVZ (Euro FX Vix) macro filter** — Use CBOE volatility index as a regime filter. AlgoMasterNNFX scrapes Yahoo Finance for this data. Could be useful as a global risk-off signal.

These are ideas, not code. If implemented, they should be built from scratch with TyphooN's production-safety standards (tick rounding, async guards, error handling).

---

## Conclusion

TyphooN v1.403 is significantly more advanced than any open-source NNFX project found on GitHub. The open-source NNFX ecosystem consists entirely of backtesting tools and educational templates — none approach the complexity of a production live-trading EA with martingale hedging, tiered margin management, multi-timeframe ATR projection, and cross-platform support.

The project stands alone in its category.
