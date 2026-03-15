# ADR-003: Separate VaR Module (DWEX Portfolio Risk Man)

**Status:** Accepted
**Date:** 2026-03-15

## Decision

Extract Value at Risk calculation into a standalone reusable library (`DWEX Portfolio Risk Man.mqh` v1.06).

## Context

Both TyphooN (manual) and TyAlgo (algo) EAs need VaR-based position sizing. The calculation is math-heavy, requires caching, and is performance-critical on batch symbol updates.

## Key Design: v1.06 Optimizations

- **Inline StdDev**: Dropped `#include <Math\Stat\Math.mqh>` (heavy dependency) — inlined 5-line standard deviation
- **Reusable work arrays**: `m_returns[]` and `m_dailyReturns[]` pre-allocated in constructor, reused per call
- **Doubling cache growth**: Array resize with 256 initial → doubles on growth (not +1 with reserve 16)
- **`ReserveCache(size)`**: Callers (ExportSymbols) can pre-allocate for known symbol count

## Consequences

- Modular, testable, reusable across both EAs
- Institutional-grade (Darwinex-endorsed methodology)
- v1.06 eliminates heap churn for batch processing (ExportSymbols across 500+ symbols)
