# ADR-004: Cross-Platform Support via .mqh Shared Logic

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Use a three-file pattern for cross-platform indicators: `.mq5` (MQL5 wrapper), `.mq4` (MQL4 wrapper), `.mqh` (shared logic with `#ifdef` guards).

## Rationale

- **DRY**: Logic lives in .mqh, not duplicated across platforms
- **Maintenance**: Bug fix in .mqh automatically fixes both versions
- **Coverage**: Same indicator works on MT5 and MT4

## Adoption

9 indicators use this pattern: MTF_MA, MultiKAMA, KAMA, EhlersFisherTransform, BetterVolume, SupplyDemand, ATR_Projection, PreviousCandleLevels, FakeCandle.

5 NNFX indicators have MQL4 wrappers: BraidFilter, QQE, STC, Squeeze_Break, SqueezeMomentum_LB.
