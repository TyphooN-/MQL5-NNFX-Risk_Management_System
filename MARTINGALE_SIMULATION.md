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

### Position State (from EA log 2026-03-17 21:35)

| | Value |
|---|---|
| Account | $100K Darwinex Zero Crypto |
| SOL Price | ~$95 |
| Balance | $92,733.28 |
| Equity | $87,438 |
| Margin | $143,704 |
| ML | 60.8% → 53% burst → back to 61% |
| Long (hedge) | 13,740 (est. after 406 trims) |
| Short (bias) | 15,499 |
| Net Short | 1,759 |
| Gross | 29,239 |
| TRIM closes so far | 406 |
| PROTECT closes | 6 |
| Margin per lot | ~$95 (1:1 crypto) |
| Spread tolerance | $87,438 / 29,239 = **$2.99/lot** (safe overnight) |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | **MG: SHORT** |
| TRIM threshold | **61%** margin level |
| TRIM formula | `maxSafe = floor((equity/0.61 - margin) / marginPerLot)` |
| PROTECT threshold | **50.1%** margin level |
| Dead zone | 50.1%–61% (10.9% buffer) |
| Note | Multiple burst trims at 51-53%, then back to 61% for overnight safety |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (shorts) in crisis |
| Open MG | $2.00/lot safety rule |

### Position Sizing

```
Shorts (bias) = 15,499
Longs (hedge) = 13,740 (after 406 TRIM closes + 6 PROTECT balanced closes)
Gross = 29,239
Net short = 1,759

Spread tolerance = $87,438 / 29,239 = $2.99/lot (overnight safe — approaching $3.00)
```

**ML settling ~53% after burst trims, back to 61% TRIM for overnight.** 406 closes so far. TRIM won't fire again until SOL drops to ~$89 where equity growth pushes ML back above 61%.

### TRIM Progression to Pure Short

With TRIM 61 and PROTECT 50.1, TRIM maintains ML at ~61% as SOL drops. ML is currently 51.0% — below TRIM — so **no trims fire until SOL drops to ~$89** where equity growth pushes ML back above 61%.

| SOL Price | Equity | Longs (Hedge) | Net Short | Gross | Spread Tol. | ML | Status |
|---|---|---|---|---|---|---|---|
| **$95 (now)** | **$87,438** | **13,740** | **1,759** | **29,239** | **$2.99** | **~53%** | Dead zone — TRIM at 61% |
| $89 | $97,992 | 13,740 | 1,759 | 29,239 | $3.35 | 62% | **TRIM resumes** |
| $80 | $113,823 | 13,077 | 2,422 | 28,576 | $3.98 | 61% | Safe |
| $70 | $138,043 | 11,871 | 3,628 | 27,370 | $5.04 | 61% | Comfortable |
| $60 | $174,323 | 9,861 | 5,638 | 25,360 | $6.87 | 61% | Very safe |
| $50 | $230,703 | 6,231 | 9,268 | 21,730 | $10.62 | 61% | Growing fast |
| $40 | $323,383 | 372 | 15,127 | 15,871 | $20.38 | 61% | Nearly pure |
| **~$40** | **~$326,000** | **0** | **15,499** | **15,499** | **$21.03** | **~63%** | **PURE SHORT** |
| $20 | $636,000 | 0 | 15,499 | 15,499 | $41.03 | 205% | Printing |
| $10 | $791,000 | 0 | 15,499 | 15,499 | $51.04 | 510% | Locked in |
| $5 | $868,000 | 0 | 15,499 | 15,499 | $56.04 | 1,121% | Locked in |
| **$0** | **$946,000** | **0** | **15,499** | **15,499** | **∞** | **∞** | **Done** |

### How TRIM Pacing Works

TRIM fires when ML > 61%, brings ML back to 61%, then waits for price movement to create more room. At 51% ML, TRIM is paused — resumes at ~$89 SOL:

| SOL Drop | Equity Gained (from net) | Lots Trimmed | Net After | Trim Accelerates? |
|---|---|---|---|---|
| $95 → $89 | $10,554 (1,759 × $6) | 0 → 24 | 1,783 | **TRIM resumes at ~$89** |
| $89 → $80 | $16,047 (1,783 × $9) | 639 | 2,422 | Moderate |
| $80 → $70 | $24,220 (2,422 × $10) | 1,206 | 3,628 | Building |
| $70 → $60 | $36,280 (3,628 × $10) | 2,010 | 5,638 | Significant |
| $60 → $50 | $56,380 (5,638 × $10) | 3,630 | 9,268 | Fast |
| $50 → $40 | $92,680 (9,268 × $10) | 5,859 | 15,127 | Rapid |
| $40 → ~$40 | $6,508 (15,127 × ~$0.4) | 372 (all) | 15,499 | **Complete — PURE SHORT** |

**The flywheel:** Each $1 SOL drop → shorts profit → equity up → more TRIM room → more net → next $1 drop earns more. The trim rate compounds as the position unwinds.

### Key Milestones

- **~$89**: TRIM resumes — ML crosses back above 61%
- **$80**: Equity $114K, net 2,422, spread tolerance $3.98 → safe
- **$50**: Equity $231K, net 9,268 → deep safety, flywheel accelerating
- **$40**: Equity $323K, net 15,127 → nearly pure
- **~$40**: **PURE SHORT** — all 13,740 hedge lots consumed. Equity ~$326K. 15,499 lots riding free
- **$0**: Equity **~$946,000** — total profit **~$858,000 (9.8x return on $87K)**

### DOGE Entry Timing

Once SOL hedge is sufficiently unwound (longs under ~10K, equity over $200K at ~$50 SOL), open DOGE MG: SHORT on a **second account**:

- **Trigger:** SOL price below $50 (equity ~$231K, spread tolerance $10.62 — deeply safe)
- **DOGE entry:** Fresh $100K account, same strategy (MG: SHORT, TRIM 61, PROTECT 50.1, $2.00/lot)
- **Why separate account:** Independent TRIM/PROTECT, no cross-margin risk, clean spread tolerance calculation
- **DOGE advantages:** Lower price per lot = higher spread tolerance per lot, rides to $0 alongside SOL

Both positions ride to $0 simultaneously. SOL provides the primary profit (~$987K), DOGE adds secondary profit on its own flywheel.

### Adverse Move Safety (From Current)

With net 1,831 at $94, equity $88,900, PROTECT at 50.4%:

| SOL Price | Bounce | Equity | ML | Status |
|---|---|---|---|---|
| $94 (now) | — | $88,900 | 51.7% | Dead zone |
| **$94.80** | **+0.9%** | **$87,434** | **~50.4%** | **PROTECT threshold** |
| $97 | +3.2% | $83,407 | 47.0% | PROTECT firing |
| $100 | +6.4% | $77,914 | 41.4% | PROTECT urgent |

**PROTECT fires at ~$94.80 (less than $1 SOL bounce).** Only 1.3 points of buffer above PROTECT at 50.4%. This is extremely tight — but intentional. PROTECT balanced closes are self-healing: they reduce gross, preserve net, and improve spread tolerance. The 4 PROTECT fires already reduced gross from ~48K to ~36K and improved spread tolerance from $1.88 to $2.48.

**Plan:** Raise PROTECT to 54% once position stabilizes, creating a 7-point dead zone (54→61). This provides ~7% SOL bounce buffer before balanced closes begin.

### Overnight Safety

| SOL Price | Gross | Equity | Spread Tol. | Overnight? |
|---|---|---|---|---|
| **$94 (now)** | **35,805** | **$88,900** | **$2.48** | **Yes — above $2.00** |
| $89 | 35,805 | $98,055 | $2.74 | Safe |
| $80 | 35,284 | $114,774 | $3.25 | Very safe |

**Spread tolerance is $2.48/lot — safely above the $2.00 rule.** PROTECT balanced closes reduced gross from ~48K to ~36K, which was a net positive for overnight safety. The position is overnight-safe at current price.

---

### Scenario Comparison: Standard Short vs Hedged Martingale

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $88,900 | $88,900 |
| Max short lots (SOL) | 473 (200% ML) | 18,818 (hedged) |
| Survives 10% spike? | NO (margin call) | YES (16,987 long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES (price drops create TRIM room) |
| Hedge removal cost | N/A | ~$621K (price of building 18.8K net short) |
| SOL profit if → $0 | **$44,462** | **~$910,000** |
| Return multiple | **0.50x** | **10.2x** |
| Final account value | ~$133,362 | **~$999,000** |

### SOLUSD Multiplier Effect

```
Standard Short:
  $89K equity → 473 SOL lots → hold → $44.5K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $89K equity → 18,818 SOL short lots (hedged with 16,987 longs)
    → Net short: 1,831 lots (nearly flat — survives any spike)
    → ML: 51.7% — TRIM paused, waiting for SOL to drop to ~$89
    → $94 → $89:  no trims      (ML still below 61%)  net short:  1,831 lots
    → $89 → $88:  TRIM closes     30 longs → net short:  1,861 lots
    → $88 → $80:  TRIM closes    491 longs → net short:  2,352 lots
    → $80 → $70:  TRIM closes    887 longs → net short:  3,239 lots
    → $70 → $60:  TRIM closes  1,425 longs → net short:  4,664 lots
    → $60 → $50:  TRIM closes  2,461 longs → net short:  7,125 lots
    → $50 → $40:  TRIM closes  4,702 longs → net short: 11,827 lots
    → $40 → $33:  TRIM closes  6,991 longs → net short: 18,818 lots (PURE SHORT)
    → DOGE shorts opened on second account at max size
    → SOL hits $0: close all        → ~$910K net profit (10.2x) plus DOGE
  [Forward-looking TRIM: each SOL drop creates room → more hedge closes → bigger net
   → next drop earns more. The flywheel compounds. Longs are fuel, shorts are profit.]
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

SOLUSD MG: SHORT opened at $94, TRIM 61/PROTECT 50.1. 13,740 L / 15,499 S, net short 1,759 lots. 406 trim closes, 6 PROTECT closes. ML ~53% — TRIM paused until ~$89. Spread tolerance $2.99/lot (overnight safe). Pure short at ~$40, equity $326K → $946K at $0.

TRIM is paused (ML ~53%, below the 61% threshold). Multiple burst trims at 51-53% throughout the session reduced hedge from ~25K to ~13.7K. It resumes when SOL drops to ~$89. From there, every dollar SOL drops compounds into more net short exposure. Pure short at ~$40 SOL. DOGE entry on second account once SOL position is deeply safe (~$50 SOL).

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
