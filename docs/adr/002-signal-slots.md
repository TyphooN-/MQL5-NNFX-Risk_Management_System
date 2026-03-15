# ADR-002: Modular Signal Slot Architecture (TyAlgo)

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Implement configurable trading signal slots (Baseline, Confirmation×2, Volume, Exit) where users swap indicators via dropdown menus or custom GlobalVariables.

## Context

TyAlgo v2.108 supports NNFX 5-signal confluence. Users must experiment with different indicator combinations without modifying code.

## Architecture

| Slot | Role | Options |
|---|---|---|
| Baseline | Trend direction | KAMA, Ehlers Supersmoother, Custom GV |
| Confirmation 1 | Entry confirmation | Fisher, MTF MA, Ehlers, Custom GV |
| Confirmation 2 | Secondary confirmation | Same options |
| Volume | Volume gate | BetterVolume, Custom GV, disabled |
| Exit | Exit trigger | Fisher reversal, Ehlers, Custom GV |

## Consensus Logic

All active directional slots must unanimously agree on direction (+1 or -1). Any neutral (0) blocks entry. Volume filter gates the entire position. Exit operates independently.

## Adding a New Indicator (4 Touch Points)

1. Add enum value to slot's enum (SignalSlots.mqh)
2. Add init case in `InitBaselineSlot()` etc.
3. Add read case in `ReadBaselineSignal()` etc.
4. Add input parameters in TyAlgo.mq5

## Consequences

- Zero-code indicator swapping via UI dropdowns
- Extensible via Custom GV contract
- Testing matrix explodes with many slot combinations
