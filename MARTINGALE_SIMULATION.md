# Hedged Martingale Strategy & Simulation

The hedged martingale exploits net-based margin to carry massive directional exposure via a hedge that is systematically trimmed as the thesis plays out. The EA (TyphooN v1.420) manages the position automatically via forward-looking TRIM and dynamic PROTECT.

**Current plan:** Operation SOL/DOGE → $0. SOLUSD hedged martingale short, DOGE entry after SOL unwind.
**Retired:** XNGUSD CFD long — not worth martingale at current lot sizes.
**Historical:** SOLUSD crypto short (PM#1-5) — five spread-spike liquidations, lessons preserved below.

---

## Strategy Mechanics (v1.420)

### How It Works

1. **Open at maximum safe intensity** — equal lots long and short at a single base price. Net exposure ≈ 0, margin ≈ $0 (net-based margin)
2. **TRIM fires** — forward-looking formula closes hedge lots to build directional exposure. ML settles at exactly the threshold
3. **Price moves in thesis direction** — equity grows from net exposure → more TRIM room → more hedge closed → bigger net → flywheel compounds
4. **Pure directional** — once all hedge lots consumed, position is pure bias. Every tick in thesis direction is profit

### Forward-Looking TRIM (v1.420)

TRIM computes exactly how many hedge lots can be closed before ML drops to threshold — **mathematically impossible to overshoot**:

```
maxMargin = equity / (threshold / 100)
availableRoom = maxMargin - currentMargin
maxSafeLots = floor(availableRoom / marginPerLot)
```

Uses `OrderCalcMargin()` to query the broker for margin per lot — works for any instrument.

**v1.415 bug this replaced:** The old formula `min(headroom - 1, 1.0)` used current ML. At net 0 (ML 999%), it tried to close ALL hedge lots, crashing ML into PROTECT cascade. Forward-looking TRIM eliminates this entirely.

### Net-Based Margin

The broker charges margin on **net exposure only** — not gross:

- **Trimming hedges INCREASES margin** (grows net → more margin required → ML drops)
- **PROTECT balanced close preserves net** → margin unchanged
- **Position is safest when most hedged** (low net = low margin)
- **Spread affects equity on gross** — spread tolerance = equity / gross lots

### PROTECT (Dynamic Balanced Close)

Below the PROTECT threshold, the EA closes equal lots from both sides:

- **Dynamic sizing**: `ceil(totalHedgeLots × urgency)` where urgency = `max(1 - ML/threshold, 0.01)`
- **Preserves net bias** — balanced close doesn't change directional exposure
- **Hard floor (10%)** — below this, broker handles stop-out, EA stands down
- **Never closes bias** — directional positions are sacred in crisis

### TRIM Threshold: 1:1 Crypto

| Leverage | TRIM | PROTECT | Dead Zone | Rationale |
|---|---|---|---|---|
| **1:1 (crypto)** | **64%** | **52%** | **12%** | Each 1% price move ≈ 1% ML change. 12pt dead zone survives ~12% bounce from TRIM |

**Why 64/52:** PROTECT at 52% gives a 12-point dead zone. From TRIM at 64%, SOL can bounce ~12% before PROTECT fires. The wide buffer prevents premature balanced closes during normal crypto volatility. Note: actual safety margin from current ML depends on where TRIM left ML — at 58.1% ML, only 6.1 points remain above PROTECT.

### Entry Rules

1. **Single base price** — all positions entered at the same price. No averaging in
2. **Safe intensity at open** — gross = equity / SpreadTolerance. Never exceed this
3. **One-way ratchet** — gross only decreases from entry. Every trim reduces it permanently
4. **Adding above base only** — new hedge lots acceptable only if price pushed past entry AND spread tolerance stays above minimum

### Position Sizing

```
Spread tolerance = Equity / Gross lots

SpreadTolerance parameter = ContractSize × WorstExpectedSpread ($ per lot)
Safe gross = Equity / SpreadTolerance
Per side = Safe gross / 2
```

**ML is NOT the survival metric. Spread tolerance is.** The broker calculates margin on net, but spreads hit gross.

---

## Active: SOLUSD Hedged Martingale SHORT (Opened 2026-03-17)

### Position State (from EA log 2026-03-17 22:14)

| | Value |
|---|---|
| Account | $100K Darwinex Zero Crypto |
| SOL Price | ~$94 |
| Balance | $91,015.72 |
| Equity | $86,377.42 |
| Margin | $170,571.02 |
| ML | 50.6% (dead zone — burst trimming at 51.1%, will set 61% for overnight) |
| Long (hedge) | 9,203 |
| Short (bias) | 11,019 |
| Net Short | 1,816 |
| Gross | 20,222 |
| TRIM closes so far | 496 |
| PROTECT closes | 10 |
| Margin per lot | ~$94 (1:1 crypto) |
| Spread tolerance | $86,377 / 20,222 = **$4.27/lot** (very safe overnight) |

### EA Configuration (Overnight — set TRIM to 61 before bed)

| Parameter | Value |
|---|---|
| Mode | **MG: SHORT** |
| TRIM threshold | **61%** (set for overnight — burst at 51% during active monitoring) |
| TRIM formula | `maxSafe = floor((equity/0.61 - margin) / marginPerLot)` |
| PROTECT threshold | **50.1%** margin level |
| Dead zone | 50.1%–61% (10.9% buffer overnight) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (shorts) in crisis |
| Open MG | $2.00/lot safety rule |

**Session summary (2026-03-17):** Aggressive burst trimming session. Multiple rounds at TRIM 51-53%, widening back to 61% between bursts. 10 PROTECT balanced closes fired during tight trim windows — each one reduced gross while preserving net, then ML spikes enabled large TRIM bursts. **Hedge reduced from ~25K to 9,203 (63% consumed) in one evening.** Spread tolerance improved from $1.88 to **$4.27/lot**.

### Position Sizing

```
Shorts (bias) = 11,019
Longs (hedge) = 9,203 (after 496 TRIM closes + 10 PROTECT balanced closes)
Gross = 20,222
Net short = 1,816

Spread tolerance = $86,377 / 20,222 = $4.27/lot (very safe overnight — 2x the $2.00 rule)
```

**ML at 50.6%, TRIM at 61% for overnight.** TRIM won't fire again until SOL drops to ~$89 where equity growth pushes ML back above 61%.

### Why Aggressive Burst Trimming Changes Everything

By consuming 63% of the hedge in one session (25K → 9.2K), the position reaches pure short at a **much higher SOL price** than the original plan:

| | Original Plan (25K hedge) | After Burst Trimming (9.2K hedge) | Improvement |
|---|---|---|---|
| Hedge lots | 25,000 | **9,203** | 63% consumed at ~$94 |
| Pure short at | ~$27 SOL | **~$55 SOL** | **$28 higher** |
| DOGE entry trigger | ~$45 SOL | **~$65 SOL** | **$20 sooner** |
| Time to pure short | Months | **Weeks** | Much faster |
| Spread tolerance | $1.88/lot | **$4.27/lot** | 2.3x safer |

**The burst trimming at $94 pre-burned hedge fuel that would otherwise consume SOL drops from $94→$55.** Instead of slowly trimming 25K longs as SOL falls $67 (from $94 to $27), we burned 15.8K longs at $94 — meaning the remaining 9.2K longs get consumed in just $39 of SOL drop ($94→$55). The position reaches pure short nearly $30 sooner.

### Impact on DOGE Trade

**This is the key unlock.** With only 9.2K hedge remaining vs the original 25K:

| | Original Timeline | Accelerated Timeline |
|---|---|---|
| SOL hedge under 5K | ~$50 SOL | **~$65 SOL** |
| DOGE entry trigger | ~$45 SOL | **~$65 SOL** |
| DOGE rides from | $45 → $0 | **$65 → $0** |
| DOGE additional runway | 45 points | **65 points** |
| Earlier DOGE = more profit | — | **~44% more DOGE profit** |

**Opening DOGE 20 points higher means 44% more runway to $0.** The burst trimming tonight doesn't just accelerate SOL — it accelerates the entire Operation SOL/DOGE → $0 timeline.

### TRIM Progression to Pure Short

With TRIM 61 and PROTECT 50.1, ML is currently 50.6% — below TRIM. Only 9,203 hedge longs remaining. TRIM resumes at ~$89 SOL.

| SOL Price | Equity | Longs (Hedge) | Net Short | Gross | Spread Tol. | ML | Status |
|---|---|---|---|---|---|---|---|
| **$94 (now)** | **$86,377** | **9,203** | **1,816** | **20,222** | **$4.27** | **51%** | Dead zone — TRIM at 61% overnight |
| $89 | $95,457 | 9,203 | 1,816 | 20,222 | $4.72 | 60% | Approaching TRIM |
| $88 | $97,273 | 9,179 | 1,840 | 20,198 | $4.82 | ~61% | **TRIM resumes** |
| $80 | $111,993 | 8,370 | 2,649 | 19,389 | $5.78 | 61% | Safe |
| $70 | $138,483 | 6,762 | 4,257 | 17,781 | $7.79 | 61% | Comfortable |
| $60 | $181,053 | 3,795 | 7,224 | 14,814 | $12.22 | 61% | Very safe — **DOGE trigger** |
| **~$55** | **~$217,000** | **0** | **11,019** | **11,019** | **$19.69** | **~68%** | **PURE SHORT** |
| $50 | $272,000 | 0 | 11,019 | 11,019 | $24.69 | 49% | Printing |
| $40 | $382,000 | 0 | 11,019 | 11,019 | $34.66 | 87% | Printing |
| $20 | $602,000 | 0 | 11,019 | 11,019 | $54.63 | 273% | Locked in |
| $10 | $712,000 | 0 | 11,019 | 11,019 | $64.63 | 647% | Locked in |
| $5 | $767,000 | 0 | 11,019 | 11,019 | $69.62 | 1,393% | Locked in |
| **$0** | **$822,000** | **0** | **11,019** | **11,019** | **∞** | **∞** | **Done** |

**Pure short at ~$55** — only needs a $39 SOL drop from entry. Every $1 below $55 = **$11,019 × $1 = $11,019** profit.

### How TRIM Pacing Works

| SOL Drop | Equity Gained (from net) | Lots Trimmed | Net After | Trim Accelerates? |
|---|---|---|---|---|
| $94 → $89 | $9,080 (1,816 × $5) | 0 | 1,816 | ML still below 61% |
| $89 → $88 | $1,816 (1,816 × $1) | 24 | 1,840 | **TRIM resumes** |
| $88 → $80 | $14,720 (1,840 × $8) | 809 | 2,649 | Moderate |
| $80 → $70 | $26,490 (2,649 × $10) | 1,608 | 4,257 | Building |
| $70 → $60 | $42,570 (4,257 × $10) | 2,967 | 7,224 | Fast — **DOGE opens at ~$65** |
| $60 → $55 | $36,120 (7,224 × $5) | 3,795 (all) | 11,019 | **Complete — PURE SHORT** |

### Key Milestones

- **~$89**: TRIM resumes — ML crosses back above 61%
- **$80**: Equity $112K, net 2,649, spread tolerance $5.78 → safe
- **~$65**: Hedge under 5K → **open DOGE MG: SHORT on second account**
- **$60**: Equity $181K, net 7,224 → very safe, flywheel at peak
- **~$55**: **PURE SHORT** — all 9,203 hedge lots consumed. Equity ~$217K. 11,019 lots riding free
- **$0**: Equity **~$822,000** — total profit **~$736,000 (8.5x return on $86K)**
- **Combined with DOGE**: SOL $822K + DOGE TBD

### DOGE Entry Timing (Accelerated)

The burst trimming tonight moved the DOGE trigger **$20 higher** — from ~$45 SOL to ~$65 SOL:

- **Trigger:** SOL price ~$65 (hedge under 5K, equity ~$160K, spread tolerance $7.79 — deeply safe)
- **DOGE entry:** Fresh $100K account, MG: SHORT, TRIM 61, PROTECT 50.1, $2.00/lot
- **Why separate account:** Independent TRIM/PROTECT, no cross-margin risk
- **DOGE at $65 entry vs $45:** 44% more runway to $0 — significantly more DOGE profit

Both positions ride to $0 simultaneously. SOL provides ~$822K, DOGE adds its own flywheel profit from ~$65 (or wherever DOGE is when SOL hits $65).

### Adverse Move Safety (Overnight)

With net 1,816 at $94, equity $86,377, PROTECT at 50.1%:

| SOL Price | Bounce | Equity | ML | Status |
|---|---|---|---|---|
| $94 (now) | — | $86,377 | 50.6% | Dead zone |
| $95 | +1.1% | $84,561 | ~49% | **PROTECT fires** — balanced close |
| $97 | +3.2% | $80,929 | 45% | PROTECT firing |
| $100 | +6.4% | $75,481 | 39% | PROTECT urgent |

**PROTECT fires at ~$95 ($1 SOL bounce).** With TRIM at 61% for overnight, the 10.9% dead zone means PROTECT won't cascade — it fires once, balanced closes, ML recovers, and settles in the dead zone. Spread tolerance at $4.27/lot provides huge overnight safety margin.

### Overnight Safety

| SOL Price | Gross | Equity | Spread Tol. | Overnight? |
|---|---|---|---|---|
| **$94 (now)** | **20,222** | **$86,377** | **$4.27** | **Very safe — 2x the $2.00 rule** |
| $89 | 20,222 | $95,457 | $4.72 | Very safe |
| $80 | 19,389 | $111,993 | $5.78 | Extremely safe |

### SOLUSD Multiplier Effect

```
Standard Short:
  $86K equity → 460 SOL lots → hold → $43K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale (after burst trimming):
  $86K equity → 11,019 SOL short lots (hedged with 9,203 longs)
    → Net short: 1,816 lots — TRIM paused at 50.6% ML
    → Hedge already 63% consumed at $94 via burst trimming
    → $94 → $89:  no trims (ML below 61%)  net short: 1,816 lots
    → $89 → $80:  TRIM closes    833 longs → net short: 2,649 lots
    → $80 → $70:  TRIM closes  1,608 longs → net short: 4,257 lots
    → $70 → $60:  TRIM closes  2,967 longs → net short: 7,224 lots
    → ~$65: DOGE shorts opened on second account
    → $60 → $55:  TRIM closes  3,795 longs → net short: 11,019 lots (PURE SHORT)
    → SOL hits $0: close all        → ~$736K net profit (8.5x) plus DOGE
  [Burst trimming at $94 pre-burned 63% of hedge fuel.
   Pure short at $55 instead of $27. DOGE entry at $65 instead of $45.
   Faster unwind, earlier DOGE, more combined profit.]
```

---

## Historical: SOLUSD Crypto Account (March 2026 — PM#1-5)

Three $100K Darwinex Zero accounts, five spread-spike liquidations. The EA worked correctly every time — the accounts were destroyed by crypto's uniquely violent spread behavior. All lessons below informed current position sizing.

### SOLUSD Starting Conditions (Previous Accounts)

| | Value |
|---|---|
| Account | $100K deposit (IC Markets EU) — reduced to ~$72K after 5 spread-spike events |
| Account Equity | ~$72,000 |
| Margin Level | ~66% (at TRIM threshold) |
| Margin Call Level | 50% |
| SOL Price | ~$85 |
| Margin per lot | ~$85.48 (from OrderCalcMargin) |

### EA Configuration (Previous — v1.420)

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 66% margin level |
| TRIM formula | Forward-looking: `maxSafe = floor((equity/0.66 - margin) / marginPerLot)` |
| PROTECT threshold | 60% margin level |
| PROTECT lots | Dynamic: `ceil(totalHedgeLots × max(1 - ML/threshold, 0.01))` per tick |
| Dead zone | 60%–66% (EA does nothing) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (shorts) in crisis |

### Previous Trim Progression ($85 Entry, $72K Equity)

| SOL Price | Hedge (Long) | Net Short | Gross | Equity | ML | Spread Tol. | Status |
|---|---|---|---|---|---|---|---|
| **$85 (entry)** | **18,212** | **1,276** | **37,700** | **$72,000** | **66%** | **$1.91** | At threshold |
| $80 | 18,004 | 1,484 | 37,492 | $78,380 | 66% | $2.09 | **Overnight safe** |
| $70 | 17,470 | 2,018 | 36,958 | $93,220 | 66% | $2.52 | Safe |
| $60 | 16,624 | 2,864 | 36,112 | $113,400 | 66% | $3.14 | Comfortable |
| $50 | 15,184 | 4,304 | 34,672 | $142,040 | 66% | $4.10 | Very safe |
| $40 | 12,477 | 7,011 | 31,965 | $185,080 | 66% | $5.79 | Growing fast |
| $30 | 6,600 | 12,888 | 26,088 | $255,190 | 66% | $9.78 | Accelerating |
| **$25** | **116** | **19,372** | **19,604** | **$319,630** | **66%** | **$16.30** | Nearly pure |
| **~$25** | **0** | **19,488** | **19,488** | **$320,792** | **97%** | **$16.46** | **PURE SHORT** |
| $20 | 0 | 19,488 | 19,488 | $414,070 | 106% | $21.25 | Printing |
| $10 | 0 | 19,488 | 19,488 | $608,950 | 313% | $31.25 | Locked in |
| **$0** | **0** | **19,488** | **19,488** | **$803,830** | **∞** | **∞** | **Done** |

### Post-Mortem #1: The 57% PROTECT Disaster (2026-03-02)

#### What Happened

The first virtual account running this strategy was destroyed overnight by a cascade of PROTECT failures. Starting conditions: $57K equity, 65K L / 66K S on SOLUSD, margin hovering around 62-64%.

**Timeline:**

1. **23:15 – 03:00**: PROTECT (set at 57%) fired repeatedly as margin oscillated near the threshold. Each fire was a balanced close (10L + 10S), preserving net short. This worked correctly — margin recovered each time. But over 3 hours, 22 balanced closes consumed 220 lots from each side.

2. **03:12:20 — The crash**: A spread spike dropped margin from ~62% to **7.5% instantly**. PROTECT rapid-fired 7 more balanced closes, burning through the remaining hedge lots. Margin spiraled: 7.5% → 3.3% → 2.3% → 1.7% → 1.3% → 1.0%.

3. **03:12:23 — No hedges left**: With all longs consumed, PROTECT fell back to closing bias (shorts). It rapid-fired **53 bias closes** (530 short lots destroyed) at 1-2% margin — locking in massive losses on every close.

4. **03:19 — User re-hedges manually**: User opened ~57K lots each side to rebuild the position. But PROTECT was still active (margin below 57%), so **the EA immediately destroyed the re-hedge too** — closing the user's manually opened positions as fast as they appeared.

5. **03:22 — Account gutted**: Final state: Hedge: 0, Bias: 0, Equity: **$26,883** (down from $57K). All 130K+ lots consumed. The EA fought the user's manual intervention.

#### Root Causes

1. **No hard floor**: PROTECT kept firing at 1-2% margin where it couldn't possibly help. The broker was already force-liquidating positions — the EA just piled on.

2. **Bias-only fallback was catastrophic**: When no hedges remained, PROTECT switched to closing shorts. At 1% margin, selling 530 shorts just locked in losses — each close was worth less than the spread cost.

3. **No circuit breaker**: PROTECT fired 109 times total with no limit. It consumed every position on the account — first the hedges (balanced), then all the shorts (bias fallback), then the user's manually re-opened positions.

4. **Hedge margin netting**: In MT5 hedging mode, the broker gives reduced margin for hedged volume. The earlier PROTECT version (before balanced close) closed only longs, which **un-hedged** the shorts — each long close actually **increased** the margin requirement on remaining shorts, making margin spiral downward instead of recovering.

#### How We Fixed It

Four safeguards now prevent this from ever happening again:

**Safeguard 1 — Hard Margin Floor (10%)**
```
If margin drops below 10%, PROTECT halts entirely.
"PROTECT HALTED — broker handles stop-out. EA standing down."
```
At 1-2% margin, the situation is beyond the EA's ability to fix. Further intervention only destroys value. The broker will handle stop-out — the EA steps aside.

**Safeguard 2 — Never Close Bias**
```
If no hedges remain, PROTECT refuses to close shorts.
"PROTECT: no hedges remaining — refusing to close bias. Standing down."
```
Shorts are sacred. If all hedges are consumed, closing shorts at catastrophic margin levels just locks in losses. The position is better off letting the broker handle it than selling the core thesis at fire-sale prices.

**Safeguard 3 — Dynamic Lot Sizing (v1.420)**
```
TRIM:    maxSafe = floor((equity/0.64 - margin) / marginPerLot)  — forward-looking, can never overshoot
PROTECT: close size = ceil(totalHedgeLots × urgency), urgency = max(1 - ML/0.52, 0.01)
```
Replaces the fixed closes and circuit breaker. Forward-looking TRIM (v1.420) computes exactly how many lots can be closed before ML hits threshold — mathematically impossible to cascade into PROTECT. PROTECT urgency scales with danger level — no tuning needed.

**Safeguard 4 — Balanced Close Only**
```
PROTECT always closes equal longs + shorts. Net exposure is preserved.
No "close longs first" — that un-hedges and spirals margin.
```

### Post-Mortem #2–5 Summary

All four subsequent liquidations (PM#2 through PM#5) were caused by **spread spikes at insufficient spread tolerance** — not EA logic failures:

| PM | Date | Cause | Spread Tol. | Lesson |
|---|---|---|---|---|
| PM#2 | 2026-03-03 | Cascade from 55% PROTECT | ~$0.47 | Widened dead zone, dynamic lot sizing |
| PM#3 | 2026-03-03/04 | Overnight spread spike | $0.93 | Position 2.97x over $2.00/lot limit |
| PM#4 | 2026-03-05 | Away-from-desk liquidation | $0.89 | Same oversizing issue |
| PM#5 | 2026-03-06 | Weekend spread spike during monitoring | $1.91 | Even $1.91 wasn't enough |

**Key lesson:** Position sizing ($2.00/lot spread tolerance) is the ONLY reliable defense against spread spikes. No TRIM/PROTECT configuration can compensate for oversized positions.

### Fresh Account Safety Framework

| Rule | Value | Why |
|---|---|---|
| **Max gross** | Equity / $2.00 | Survives $2.00 overnight spread spikes |
| **Opening size** | Safe from day one | Never "open big, trim down" — the spike comes before trimming finishes |
| **PROTECT** | 52% fixed, dynamic lots | Below this, balanced close scales with urgency. 12pt dead zone from TRIM 64% |
| **TRIM** | 64% forward-looking (v1.420) | Computes max safe lots from margin math — can never cascade into PROTECT |
| **Hard floor** | 10% | Below this, broker handles it — EA intervention only makes it worse |
| **Monitor spread tolerance** | Log equity/gross daily | If tolerance drops below $2.00, stop opening new lots |
| **Weekend caution** | Reduce gross Friday or accept risk | Crypto weekend liquidity is thinner → wider spreads |

### The Paradox of Net-Based Margin

Net-based margin creates a dangerous illusion:

```
Position: 35,500 L / 36,100 S (net 300 short)
Margin:   $26,698 (net × price = 300 × $89)
ML:       126% ($33,332 / $26,698)
Spread tolerance: $33,332 / 71,600 = $0.47/lot

ML says:  "Safe — 126% is way above 50% stop-out"
Reality:  "Dead — a $0.47 spread wipe = total margin failure"
```

**ML measures net risk. Spreads hit gross.** These diverge proportionally to hedge ratio. A perfectly hedged position (net = 0) would show **infinite ML** (zero margin) while still being destroyed by a spread spike on gross.

This is why the $2.00/lot rule ignores ML entirely. The only number that matters for survival is equity divided by gross lots.

---

## Retired: XNGUSD CFD Long (March 2026)

XNGUSD was explored as a martingale candidate due to predictable CFD spread behavior. Two accounts opened (48L/41S and 53L/33S). **Retired because:**

1. Structural spread cost ($650/lot at 65 points) consumed all TRIM fuel at practical lot sizes
2. At 40/side, TRIM exhausted shorts immediately — no flywheel, just an expensive naked long
3. Martingale only adds value when the hedge provides enough fuel for gradual net building
4. Better as a standard directional trade (naked long) than a martingale

### What Was Learned

- **TRIM threshold for leveraged CFDs:** 80% TRIM / 56% PROTECT for 5:1 leverage (vs 64/54 for 1:1 crypto)
- **Contract size matters:** 10,000 MMBtu/lot means each lot is ~$30K notional at $3.00 — fewer lots = less TRIM fuel
- **Spread recovery is real:** entering at wide spread means equity recovers when liquidity returns — but the TRIM math doesn't benefit enough from this at low lot counts

### Previous XNGUSD Positions (Closed/Retired)

| Account | Position | TRIM/PROTECT | Entry | Status |
|---|---|---|---|---|
| Account 1 | 48L / 41S | 60/56 | ~$3.135 | Retired |
| Account 2 | 53L / 33S | 70/54 | ~$3.00 | Retired |

---

## Bottom Line

### Operation SOL/DOGE → $0

SOLUSD MG: SHORT opened at $94. Burst trimming consumed 67% of hedge (25K → 8.2K) at $94. 8,189 L / 10,000 S, net short 1,811. 542 trims, 11 protects. TRIM 61/PROTECT 50.1. ML 50.8%. Spread tolerance **$4.75/lot**. Pure short at **~$55** (vs original ~$27). DOGE entry accelerated to **~$65 SOL** (vs ~$45). $800K at $0.

**Key achievement:** Burst trimming at $94 pre-burned 67% of hedge fuel — pure short reached $28 sooner, DOGE entry $20 sooner. Faster unwind = more combined SOL+DOGE profit.

**Target: both to $0.**

| Milestone | SOL Price | Equity | Net Short | Status |
|---|---|---|---|---|
| Now | $94 | $88,900 | 1,831 | Dead zone, TRIM paused (ML 51.7%) |
| TRIM resumes | ~$89 | ~$98,055 | 1,831 | ML crosses 61% |
| Flywheel engaging | $70 | $138,294 | 3,239 | Building fast |
| DOGE entry trigger | $50 | ~$217,000 | ~7,125 | Open DOGE on second account |
| Pure short | ~$33 | ~$378,000 | 18,818 | All hedge consumed |
| **Target** | **$0** | **~$999,000** | **18,818** | **10.2x return** |

### Crypto Lessons (PM#1-5)

Three $100K accounts, five spread-spike liquidations. The EA logic worked perfectly every time — forward-looking TRIM, dynamic PROTECT, hard floor, bias protection all fired correctly. The accounts were destroyed by **crypto's uniquely violent spread behavior** at insufficient spread tolerance. Key lesson: the $2.00/lot rule is necessary and must be respected from day one. Even $1.91/lot tolerance was fatal (PM#5).

### Why Martingale for Crypto, Not CFD

The hedged martingale works best when:
1. **Lots are cheap** (1:1 margin = 1 lot per $1 of price) — maximizes TRIM fuel
2. **Thesis is strong** (SOL/DOGE → $0 in crypto bear market)
3. **Position sizing is respected** ($2.00/lot from day one, no exceptions)

CFD commodities have the wrong profile: expensive lots (high leverage = fewer lots), structural spread costs that eat TRIM room, and less fuel for the flywheel. The same EA works on both, but the math favors crypto despite the spread risk — IF you size correctly.
