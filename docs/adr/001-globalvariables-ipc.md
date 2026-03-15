# ADR-001: GlobalVariables as Inter-Process Communication

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Use MT5 GlobalVariables as the IPC mechanism for indicator-to-EA communication.

## Context

Multiple indicators (MultiKAMA, EhlersFisherTransform, MTF_MA, BetterVolume) run independently and need to signal to EAs (TyphooN, TyAlgo) without tight coupling.

## Rationale

- **Persistence**: GVs survive across chart windows on the same terminal
- **Decoupling**: Indicators update independently; EAs read lazily
- **Performance**: Reading a GV is faster than creating indicator handles per tick
- **Extensibility**: New indicators participate by writing to a named GV — zero EA code changes

## Pattern

```
Indicator writes:    GlobalVariableSet("FisherBias_EURUSD_240", +1.0)
EA reads:            GlobalVariableGet("FisherBias_EURUSD_240", value)
Convention:          +1=buy, -1=sell, 0=neutral (directional)
                     1=pass, 0=fail (volume filters)
```

All GV names are symbol-qualified (`_Symbol` suffix) to prevent cross-chart contamination.

## Consequences

- Simple, flexible, no handle leaks
- GV names must match exactly — typos silently fail
- In Strategy Tester, indicators must be loaded via chart template
