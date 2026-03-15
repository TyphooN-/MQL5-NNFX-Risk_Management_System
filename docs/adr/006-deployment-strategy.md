# ADR-006: Deployment via Bash Script

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Use `deploy.sh` to synchronize source files to 11 MT5 Wine installations, comparing files before copying (`cmp -s`).

## Pattern

- Scans `~/.mt5_*/` directories (Wine prefix convention)
- EAs: fixed list (TyphooN.mq5, TyAlgo.mq5)
- Indicators: find all `.mq5/.mq4/.mqh` excluding `Retired/`
- Includes: find all `.mqh/.mq5` in `Include/`
- Only copies when files differ — minimizes disk writes and recompilation

## Consequences

- Simple, reliable, auditable bash
- Safe (cmp prevents unintended overwrites)
- Unix/Linux only (matches Wine deployment environment)
