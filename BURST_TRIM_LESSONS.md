# Burst Trim Lessons Learned (2026-03-17)

## What Happened

Opened SOLUSD MG: SHORT on a fresh $100K account at ~$94. Initial hedge was ~25K L / 25K S (Open MG $2.00/lot → 50K gross). Within one evening session, manually burst-trimmed by repeatedly:

1. Dropping TRIM to 51-53% (just above PROTECT 50.1%)
2. TRIM fires, closes hundreds of longs in bursts
3. PROTECT occasionally fires (11 times total), balanced closes reduce gross
4. Widening TRIM back to 61% between bursts for safety
5. Repeat

**Result:** Hedge reduced from ~25K to 8.2K (67% consumed) in one session at $94. Position reached a state that would normally require SOL to drop from $94 to ~$55 via passive TRIM.

## Why Burst Trimming Was Necessary

The initial Open MG of **$2.00/lot** created a position that was **too large to trim passively at reasonable settings**:

```
Open MG $2.00 → gross = $100K / $2.00 = 50,000
Per side = 25,000
Spread tolerance = $100K / 50,000 = $2.00/lot (borderline)

After TRIM fires to 61%:
  maxSafe = floor(($100K / 0.61 - $0) / $94) = 1,744 lots
  Remaining hedge = 25,000 - 1,744 = 23,256 shorts to burn through
  ML after TRIM = 61%
```

The problem: **23,256 remaining hedge lots at TRIM 61% means ML is at 61% with massive gross exposure**. Any SOL bounce of ~1% pushes into PROTECT. The dead zone is consumed by the sheer mass of the hedge.

To safely unwind 23,256 hedge lots via passive TRIM, SOL would need to drop from $94 to ~$27 — a **72% decline** before pure short. That's months of waiting with a position that's constantly one bounce away from PROTECT.

## The Root Cause: Open MG Was Too Aggressive

| Open MG | Gross | Per Side | Initial TRIM Net | Hedge Remaining | ML After TRIM | Pure Short At |
|---|---|---|---|---|---|---|
| **$2.00** | **50,000** | **25,000** | **1,744** | **23,256** | **61%** | **~$27** |
| $4.00 | 25,000 | 12,500 | 1,744 | 10,756 | 61% | ~$47 |
| $6.00 | 16,666 | 8,333 | 1,744 | 6,589 | 61% | ~$58 |
| **$8.00** | **12,500** | **6,250** | **1,744** | **4,506** | **61%** | **~$65** |
| $10.00 | 10,000 | 5,000 | 1,744 | 3,256 | 61% | ~$72 |

**At Open MG $8.00/lot:** Starting hedge is 6,250 — TRIM immediately closes 1,744, leaving only 4,506. This is comparable to where we ended up after the burst trim session (8,189). But we'd have gotten there **cleanly on open** instead of spending an evening manually babysitting 500+ trim closes.

## Recommended Settings for Next Crypto Martingale

### Position Sizing

```
Open MG = $8.00 (not $2.00)

Gross = $100K / $8.00 = 12,500
Per side = 6,250
Spread tolerance = $100K / 12,500 = $8.00/lot (4x the $2.00 minimum — deeply safe)
```

**Why $8.00:** The $2.00 rule was the **minimum for survival**. But minimum survival ≠ clean operation. At $2.00, the position is borderline — PROTECT fires on normal noise, spread tolerance is razor-thin, and the hedge is so massive it takes a 70%+ decline to unwind. At $8.00:

- Spread tolerance is $8.00/lot — **survives any crypto spread spike** (SOL worst case ~$3-5)
- Gross is 12,500 vs 50,000 — **75% less spread risk**
- Initial TRIM consumes 28% of hedge immediately (vs 7% at $2.00)
- Pure short at ~$65 vs ~$27 — **reachable in weeks, not months**
- DOGE entry trigger is reached much sooner

### TRIM / PROTECT Settings

| Setting | Old (Lessons Learned) | **Recommended** | Why |
|---|---|---|---|
| Open MG | $2.00 | **$8.00** | Clean unwind, no burst trim needed |
| TRIM | 51-61% (manual burst) | **61%** | Set and forget — passive trimming |
| PROTECT | 50.1% | **50.1%** | Tight above 50% margin call |
| Dead zone | 0.9-10.9% (varied) | **10.9%** | Covers ~11% SOL bounce at 1:1 |

### What Clean Operation Looks Like

With Open MG $8.00, TRIM 61%, PROTECT 50.1%, entry at $94:

```
Open: 6,250 L + 6,250 S, net 0, margin $0
TRIM fires: closes 1,744 shorts → net 1,744 short, ML 61%
Hedge remaining: 4,506

Position sits in dead zone. No manual intervention needed.
SOL drops → equity grows → TRIM fires automatically → net grows → flywheel compounds.

Pure short at ~$65 SOL — only $29 below entry.
No burst trimming. No babysitting. No PROTECT fires. Just passive TRIM.
```

### The Tradeoff

| | Aggressive ($2.00) | **Clean ($8.00)** |
|---|---|---|
| Bias lots | 25,000 | **6,250** |
| Pure short at | ~$27 (after burst trim: ~$55) | **~$65** |
| Profit at $0 | ~$800K (after burst trim losses) | **~$588K** |
| Return | ~9x | **~6.8x** |
| Manual intervention | Hours of babysitting | **None** |
| PROTECT fires | 11 | **0** |
| Risk of cascade | High (PM#2c territory) | **Near zero** |
| Spread safety | Borderline → improved via trim | **Safe from day one** |
| Overnight worry | Constant monitoring needed | **Set and forget** |

**The aggressive approach yields ~30% more profit but requires constant manual intervention, carries significant cascade risk, and consumed an entire evening of babysitting.** The clean approach sacrifices some upside for zero maintenance.

### Hybrid Approach: Moderate Aggression

If you want more lots than $8.00 but less chaos than $2.00:

```
Open MG = $5.00

Gross = $100K / $5.00 = 20,000
Per side = 10,000
Spread tolerance = $100K / 20,000 = $5.00/lot (safe)
Initial TRIM: 1,744 net → hedge remaining: 8,256
Pure short at: ~$52 SOL
Profit at $0: ~$735K (8.5x)
```

This gives 60% of the aggressive position's lots with none of the babysitting. Pure short at $52 instead of $27 or $65. A good middle ground.

## Summary

| Lesson | Detail |
|---|---|
| **$2.00/lot is too aggressive for crypto martingale** | Creates massive hedge that requires manual burst trimming or months of passive TRIM |
| **$8.00/lot is the clean default** | Enough lots for meaningful flywheel, small enough hedge for passive unwind |
| **$5.00/lot is the sweet spot** | Good compromise: 10K bias lots, pure short at ~$52, no babysitting |
| **Burst trimming works but is labor-intensive** | 500+ manual trim closes in one evening, constant PROTECT risk |
| **PROTECT fires are a feature, not a bug** | Each balanced close reduces gross and improves spread tolerance |
| **Set TRIM wide for overnight (61%)** | Never leave tight TRIM (51-53%) unattended — PM#2c cascade risk |
| **The dead zone must absorb normal volatility** | At 1:1 crypto, 10.9% dead zone (50.1→61%) covers ~11% SOL bounce |

**Bottom line:** Next time, use Open MG $5.00-$8.00. Open the position, set TRIM 61 / PROTECT 50.1, and walk away. The EA handles the rest. Save the evenings for research, not babysitting trim closes.
