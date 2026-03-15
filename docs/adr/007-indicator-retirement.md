# ADR-007: Indicator Retirement Pattern

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Move obsolete indicators to `Indicators/Retired/` and exclude from deployment via `deploy.sh -prune` rather than deleting from git.

## Retired (9 indicators)

- RVOL → replaced by BetterVolume
- shved_supply_and_demand → replaced by SupplyDemand.mq5
- EhlersHilbertTransform, MOAMA → not adopted into TyAlgo
- Heiken Ashi Smoothed, MarketProfile → not in NNFX methodology
- Minions.BetterVolume → replaced by refactored version

## Consequences

- Clean deployment (only active indicators deployed)
- Git history preserved for reference
- Can revive if approach changes
