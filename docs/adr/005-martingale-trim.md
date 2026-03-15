# ADR-005: Forward-Looking TRIM (v1.420)

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Use forward-looking margin math to compute exact max safe lots for hedge trimming, making it mathematically impossible to overshoot the TRIM threshold.

## Context

v1.415 bug: At net 0 (ML 999%), formula `min(headroom-1, 1.0)` tried to close ALL hedge lots → crashed ML into PROTECT cascade → destroyed position.

## v1.420 Formula

```
maxMargin = equity / (threshold / 100)
availableRoom = maxMargin - currentMargin
maxSafeLots = floor(availableRoom / marginPerLot)
```

Uses `OrderCalcMargin()` to query broker for margin per lot. Each hedge close increases net → increases margin → lowers ML. The formula computes exactly how many lots can be closed before ML reaches threshold.

## Leverage-Dependent Settings

| Leverage | TRIM | PROTECT | Dead Zone | Rationale |
|---|---|---|---|---|
| 1:1 (crypto) | 65-66% | 56-60% | 6-10% | 1% price = ~1% ML |
| 5:1 (CFD) | 80% | 56% | 24% | 1% price = ~3% ML |

## Key Metrics

- **Margin Level (ML)**: What broker displays — only meaningful during active trimming
- **Spread Tolerance** (`equity / gross`): The REAL overnight safety metric

## Consequences

- Mathematically impossible to overshoot threshold
- Proven in live trading (5 spread-spike events, EA logic correct every time)
- Position sizing ($2.00/lot minimum spread tolerance) remains the critical safety gate
