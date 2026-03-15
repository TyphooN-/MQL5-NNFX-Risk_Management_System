# ADR-008: Four Risk Mode System

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Implement 4 independent order sizing modes selectable via enum input parameter.

## Modes

| Mode | Formula | Use Case |
|---|---|---|
| **Standard** | `balance × risk% / (SL_ticks × tick_value)` | Normal trading, % risk per trade |
| **Fixed** | `FixedLots × FixedOrdersToPlace` | Scaling in, pyramiding |
| **Dynamic** | `(balance - minBalance) / lossesToMin / (SL_ticks × tick_value)` | Drawdown-aware sizing |
| **VaR** | `(equity × VaR%) / VaR_per_lot` or `notional / VaR_per_lot` | Institutional risk management |

## Additional Features

- **Break-even detection**: If existing position at break-even, reduce new position risk by `AdditionalRiskRatio`
- **Margin buffer**: Reserve `MarginBufferPercent` of balance from usable margin
- **Max risk cap**: Standard mode capped at `MaxRisk%`

## Consequences

- Type-safe enum selection via dropdown
- All 4 implementations coexist in single EA
- User can switch modes without recompilation
