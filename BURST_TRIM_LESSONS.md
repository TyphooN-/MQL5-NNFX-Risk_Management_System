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

---

## The Wrench in the Flywheel (2026-03-18 — The Day of Nine Opens)

### What Actually Happened

The flywheel was spinning. TRIM was grinding. The position was working. And then the operator threw a wrench into it. Nine times.

**The Open MG progression in one day:**
```
Open #1: $2.42  — "aggressive but calibrated"
Open #2: $2.13  — "slightly more aggressive"
Open #3: $2.00  — "full send" — lessons learned doc said this was the limit
Open #4: $1.69  — "I couldn't resist"
Open #5: $1.67  — "John Carmack would approve"
Open #6: $1.42  — "smoke em if you got em"
Open #7: $1.337 — "LEET"
Open #8: $1.337 — "last meme to dream. I PROMISE"
Open #9: $1.337 — (4 minutes after promising not to touch anything)
```

Each Open MG:
1. Added equal longs AND shorts to the position
2. **Reset the flywheel** — net short goes back to ~0 momentarily
3. TRIM immediately fires to rebuild net → but this takes time
4. During rebuild, spread tolerance crashes → PROTECTs fire → **bias lots destroyed**
5. Net stabilizes back to approximately where it was before the open
6. Except now with fewer bias lots

**The scorecard:**
```
Starting bias (first open):  24,131 lots → $2.17M at $0
Ending bias (after 11 PROTECTs): 15,494 lots → $1.39M at $0
Bias destroyed by PROTECTs: 8,637 lots
Profit destroyed: $777,330

That's $777K of profit vaporized by throwing wrenches into a spinning flywheel.
```

### Why Each Open MG Hurt Instead of Helped

The operator's logic: "more lots = more profit." Correct in isolation. But the martingale flywheel doesn't work in isolation:

**How TRIM builds net exposure (the flywheel):**
```
SOL drops $1 → net short earns $1,284 → equity grows → TRIM has room → closes 14 longs
→ net grows to 1,298 → next $1 drop earns $1,298 → TRIM closes 15 longs
→ net grows to 1,313 → next $1 drop earns $1,313 → accelerating...
```

**What happens when you open a new MG mid-flywheel:**
```
Flywheel spinning at net 1,284...
Open MG: adds 20,000 L + 20,000 S
Net is still 1,284 (new lots cancel out)
BUT gross jumps from 31K to 71K
Spread tolerance crashes from $2.00 to $0.87
PROTECT fires: balanced close 163L + 163S → net preserved but 163 BIAS LOTS GONE
TRIM fires: closes new longs to rebuild ML
Net is back to ~1,284. Same as before the open.
Except: 163 fewer bias lots. $14,670 less profit at $0. For nothing.
```

**The new MG added zero net exposure. TRIM was going to build the same net organically. The only thing the MG added was gross exposure that triggered PROTECTs that destroyed bias.**

### The Fundamental Misunderstanding

**"More lots = more profit"** is true for NAKED positions. For the MARTINGALE:

- **More gross = lower spread tolerance = more PROTECTs = fewer bias lots**
- **TRIM builds net exposure for FREE by closing hedge longs**
- **Opening a new MG doesn't add net — it adds GROSS, which is the enemy**

The operator didn't need more lots. The EA was already adding net on every tick down. Every $1 SOL dropped, TRIM closed 14 more longs, net grew by 14. That IS the lot-adding mechanism. The flywheel IS the position builder.

Opening a new MG is like:
- Pouring more fuel into an engine that's already running at optimal RPM — it doesn't go faster, it floods
- Adding more weight to a spinning gyroscope — it doesn't spin faster, it wobbles
- Overvolting a CPU that's already at max stable clock — it doesn't benchmark higher, it crashes

### The Self-Healing

The good news: every PROTECT fire reduced gross, which improved spread tolerance, which made the next PROTECT less likely. The position self-healed:

```
After open #1:  spread tol $1.33 → PROTECTs every few minutes
After PROTECT #5: spread tol $1.55 → PROTECTs less frequent
After PROTECT #8: spread tol $1.75 → PROTECTs occasional
After PROTECT #11: spread tol $1.95 → PROTECTs rare
Current: spread tol $2.10 → PROTECTs essentially stopped
```

The PROTECTs were the cost of the wrenches. But they also cleaned up the mess the wrenches made. Each one removed gross, improved tolerance, and stabilized the position. The EA's self-healing mechanism (balanced close preserving net while reducing gross) turned a series of operator errors into a gradually improving position.

### The Lesson (For Real This Time)

**The flywheel doesn't need help. It needs time.**

| What the operator wanted | What actually helps |
|---|---|
| More bias lots | TRIM building net on every tick |
| Faster unwind | SOL dropping (not more gross) |
| Bigger profit at $0 | Fewer PROTECTs (not more MGs) |
| More aggressive position | Clean spread tolerance (not lower Open MG) |

**TRIM adds ~14 net short lots per $1 SOL drop. FOR FREE. No spread cost. No PROTECT risk. No new gross. Just pure, clean, mathematical net exposure growth.**

Opening a new MG at $1.337 to add lots is like hiring a moving company to carry your couch while you're already carrying it. They show up, grab one end, trip over the coffee table (PROTECT), break a lamp (bias lots), and you end up in the same place minus a lamp.

**The flywheel turns around now. Settings cemented. No more wrenches. QRRP.**

### Updated Recommendations

| Scenario | Open MG | Why |
|---|---|---|
| **Fresh $100K, first open** | $5.00-$8.00 | Clean passive operation from day one |
| **Position already running** | **DO NOT OPEN** | TRIM adds net for free. New MG adds gross = PROTECTs |
| **"But we're about to drop"** | **DO NOT OPEN** | The drop feeds the flywheel automatically |
| **"But I want more lots"** | **Wait for pure short, add naked** | Zero hedge overhead, zero PROTECT risk |
| **"Just one more"** | **NO** | Nine "just one mores" cost $777K in profit |
