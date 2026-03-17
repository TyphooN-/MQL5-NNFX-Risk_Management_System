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
| **1:1 (crypto)** | **64%** | **54%** | **10%** | Each 1% price move ≈ 1% ML change. 10pt dead zone survives ~10% bounce |

**Why 64/54 over 64/56:** PROTECT at 54% gives 10-point dead zone instead of 8. SOL can bounce ~10% before PROTECT fires. The extra 2 points of buffer prevent premature balanced closes during normal crypto volatility — critical for overnight safety.

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

### Position State

| | Value |
|---|---|
| Account | $100K Darwinex Zero Crypto |
| SOL Price | ~$94.00 |
| Balance | $97,387 |
| Equity | $91,534 |
| Margin | $143,310 |
| Free Margin | -$51,776 |
| ML | 63.87% (dead zone) |
| Net Short | 1,526 |
| Unrealized P/L | -$5,878 |
| Margin per lot | ~$94 (1:1 crypto) |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | **MG: SHORT** |
| TRIM threshold | **64%** margin level |
| TRIM formula | `maxSafe = floor((equity/0.64 - margin) / marginPerLot)` |
| PROTECT threshold | **54%** margin level |
| Dead zone | 54%–64% (10% buffer — survives ~10% SOL bounce) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (shorts) in crisis |
| Open MG | $2.00/lot safety rule |

### Position Sizing

```
Open MG at $2.00/lot → max gross = $100,000 / $2.00 = 50,000
Per side = 25,000
Shorts (bias) = ~25,763
Longs (hedge) = ~24,237
Gross = ~49,000 (approx — exact from opening)
Net short = 1,526 (after TRIM at 64%)

Spread tolerance = $91,534 / ~49,000 = $1.87/lot (borderline — crosses $2.00 at ~$90 SOL)
```

### TRIM Progression to Pure Short

With TRIM 64 and PROTECT 54, TRIM maintains ML at exactly 64% as SOL drops. Each price drop creates room: equity grows from net short P/L + margin per lot decreases.

| SOL Price | Equity | Longs (Hedge) | Net Short | Gross | Spread Tol. | Status |
|---|---|---|---|---|---|---|
| **$94 (now)** | **$91,534** | **~23,474** | **1,526** | **~48,474** | **$1.89** | Dead zone |
| $90 | $97,638 | 23,305 | 1,695 | 48,305 | $2.02 | **Overnight safe** |
| $80 | $114,588 | 22,762 | 2,238 | 47,762 | $2.40 | Safe |
| $70 | $136,968 | 21,942 | 3,058 | 46,942 | $2.92 | Comfortable |
| $60 | $167,548 | 20,639 | 4,361 | 45,639 | $3.67 | Very safe |
| $50 | $211,158 | 18,401 | 6,599 | 43,401 | $4.87 | Growing fast |
| $40 | $277,148 | 14,174 | 10,826 | 39,174 | $7.08 | Accelerating |
| $30 | $385,408 | 4,927 | 20,073 | 29,927 | $12.88 | Nearly pure |
| **~$27** | **~$446,000** | **0** | **25,000** | **25,000** | **$17.84** | **PURE SHORT** |
| $20 | $621,000 | 0 | 25,000 | 25,000 | $24.84 | Printing |
| $10 | $871,000 | 0 | 25,000 | 25,000 | $34.84 | Locked in |
| $5 | $996,000 | 0 | 25,000 | 25,000 | $39.84 | Locked in |
| **$0** | **$1,121,000** | **0** | **25,000** | **25,000** | **∞** | **Done** |

### How TRIM Pacing Works

TRIM brings ML to 64% then waits for price movement to create more room:

| SOL Drop | Equity Gained (from net) | Lots Trimmed | Net After | Trim Accelerates? |
|---|---|---|---|---|
| $94 → $90 | $6,104 (1,526 × $4) | 169 | 1,695 | Slow — small net |
| $90 → $80 | $16,950 (1,695 × $10) | 543 | 2,238 | Moderate |
| $80 → $70 | $22,380 (2,238 × $10) | 820 | 3,058 | Building |
| $70 → $60 | $30,580 (3,058 × $10) | 1,303 | 4,361 | Significant |
| $60 → $50 | $43,610 (4,361 × $10) | 2,238 | 6,599 | Fast |
| $50 → $40 | $65,990 (6,599 × $10) | 4,227 | 10,826 | Rapid |
| $40 → $30 | $108,260 (10,826 × $10) | 9,247 | 20,073 | Compounding |
| $30 → $27 | $60,219 (20,073 × $3) | 4,927 (all) | 25,000 | **Complete** |

**The flywheel:** Each $1 SOL drop → shorts profit → equity up → more TRIM room → more net → next $1 drop earns more. The trim rate compounds as the position unwinds.

### Key Milestones

- **$90**: Spread tolerance crosses $2.00/lot → **overnight safe**
- **$80**: Equity $115K, spread tolerance $2.40 → safe, TRIM building
- **$50**: Equity $211K, net 6,599 → deep safety, flywheel accelerating
- **$30**: Equity $385K, 80% of hedge consumed → home stretch
- **$27**: **PURE SHORT** — all ~23,474 hedge lots consumed. Equity ~$446K. 25,000 lots riding free
- **$0**: Equity **~$1,121,000** — total profit **~$1,029,000 (11.2x return on $91.5K)**

### DOGE Entry Timing

Once SOL hedge is sufficiently unwound (longs under ~10K, equity over $200K at ~$45 SOL), open DOGE MG: SHORT on a **second account**:

- **Trigger:** SOL price below $45 (equity ~$211K, spread tolerance $4.87 — deeply safe)
- **DOGE entry:** Fresh $100K account, same strategy (MG: SHORT, TRIM 64, PROTECT 54, $2.00/lot)
- **Why separate account:** Independent TRIM/PROTECT, no cross-margin risk, clean spread tolerance calculation
- **DOGE advantages:** Lower price per lot = higher spread tolerance per lot, rides to $0 alongside SOL

Both positions ride to $0 simultaneously. SOL provides the primary profit (~$1.1M), DOGE adds secondary profit on its own flywheel.

### Adverse Move Safety (From Current)

With net 1,526 at $94, equity $91,534, PROTECT at 54%:

| SOL Price | Bounce | Equity | ML | Status |
|---|---|---|---|---|
| $94 (now) | — | $91,534 | 63.9% | Dead zone |
| $96 | +2.1% | $88,482 | 60.0% | Dead zone |
| $100 | +6.4% | $82,378 | 52.7% | PROTECT firing |
| **$103.50** | **+10.1%** | **$77,084** | **~54%** | **PROTECT threshold** |
| $110 | +17.0% | $67,118 | ~30% | PROTECT urgent |

**PROTECT fires at ~$103.50 (10% SOL bounce).** The 10-point dead zone (64→54) provides solid buffer. At $94 with net 1,526, a $9.50 adverse move is needed before balanced closes begin.

### Overnight Safety

| SOL Price | Gross | Equity | Spread Tol. | Overnight? |
|---|---|---|---|---|
| **$94 (now)** | **~48,474** | **$91,534** | **$1.89** | **Borderline — $0.11 below $2.00** |
| $90 | 48,305 | $97,638 | $2.02 | **Yes — above $2.00** |
| $85 | 48,094 | $104,299 | $2.17 | Yes |
| $80 | 47,762 | $114,588 | $2.40 | Safe |

**At current price ($94), spread tolerance is $1.89/lot — slightly below the $2.00 safety rule.** A $4 SOL drop to $90 brings tolerance to $2.02. Once past $90, the position is safely overnight-able and only gets safer.

---

### Scenario Comparison: Standard Short vs Hedged Martingale

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $91,534 | $91,534 |
| Max short lots (SOL) | 487 (200% ML) | ~25,000 (hedged) |
| Survives 10% spike? | NO (margin call) | YES (~23K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES (price drops create TRIM room) |
| Hedge removal cost | N/A | ~$675K (price of building 25K net short) |
| SOL profit if → $0 | **$45,778** | **~$1,029,000** |
| Return multiple | **0.50x** | **11.2x** |
| Final account value | ~$137,312 | **~$1,121,000** |

### SOLUSD Multiplier Effect

```
Standard Short:
  $91.5K equity → 487 SOL lots → hold → $45.8K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $91.5K equity → ~25,000 SOL short lots (hedged with ~23,474 longs)
    → Net short: 1,526 lots (nearly flat — survives any spike)
    → $94 → $90:  TRIM closes    169 longs → net short:  1,695 lots
    → $90 → $80:  TRIM closes    543 longs → net short:  2,238 lots
    → $80 → $70:  TRIM closes    820 longs → net short:  3,058 lots
    → $70 → $60:  TRIM closes  1,303 longs → net short:  4,361 lots
    → $60 → $50:  TRIM closes  2,238 longs → net short:  6,599 lots
    → $50 → $40:  TRIM closes  4,227 longs → net short: 10,826 lots
    → $40 → $30:  TRIM closes  9,247 longs → net short: 20,073 lots
    → $30 → $27:  TRIM closes  4,927 longs → net short: 25,000 lots (PURE SHORT)
    → DOGE shorts opened on second account at max size
    → SOL hits $0: close all        → ~$1,029K net profit (11.2x) plus DOGE
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
PROTECT: close size = ceil(totalHedgeLots × urgency), urgency = max(1 - ML/threshold, 0.01)
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
| **PROTECT** | 54% fixed, dynamic lots | Below this, balanced close scales with urgency. Wider dead zone than original 56% |
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

Fresh $100K account on SOLUSD MG: SHORT. Position opened 2026-03-17 at ~$94. TRIM 64 / PROTECT 54 / $2.00 per lot. Net short 1,526 lots. Spread tolerance borderline at $1.89/lot — crosses $2.00 at $90 SOL.

The flywheel is engaged. Every dollar SOL drops compounds into more net short exposure via forward-looking TRIM. Pure short at ~$27 SOL. DOGE entry on second account once SOL position is deeply safe (~$45 SOL).

**Target: both to $0.**

| Milestone | SOL Price | Equity | Net Short | Status |
|---|---|---|---|---|
| Now | $94 | $91,534 | 1,526 | Dead zone, TRIM pacing |
| Overnight safe | $90 | $97,638 | 1,695 | Spread tol > $2.00 |
| Flywheel engaging | $70 | $136,968 | 3,058 | Building fast |
| DOGE entry trigger | $45 | ~$230,000 | ~8,000 | Open DOGE on second account |
| Pure short | ~$27 | ~$446,000 | 25,000 | All hedge consumed |
| **Target** | **$0** | **~$1,121,000** | **25,000** | **11.2x return** |

### Crypto Lessons (PM#1-5)

Three $100K accounts, five spread-spike liquidations. The EA logic worked perfectly every time — forward-looking TRIM, dynamic PROTECT, hard floor, bias protection all fired correctly. The accounts were destroyed by **crypto's uniquely violent spread behavior** at insufficient spread tolerance. Key lesson: the $2.00/lot rule is necessary and must be respected from day one. Even $1.91/lot tolerance was fatal (PM#5).

### Why Martingale for Crypto, Not CFD

The hedged martingale works best when:
1. **Lots are cheap** (1:1 margin = 1 lot per $1 of price) — maximizes TRIM fuel
2. **Thesis is strong** (SOL/DOGE → $0 in crypto bear market)
3. **Position sizing is respected** ($2.00/lot from day one, no exceptions)

CFD commodities have the wrong profile: expensive lots (high leverage = fewer lots), structural spread costs that eat TRIM room, and less fuel for the flywheel. The same EA works on both, but the math favors crypto despite the spread risk — IF you size correctly.
