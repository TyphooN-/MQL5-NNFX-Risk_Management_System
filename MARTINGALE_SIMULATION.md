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

### Position State (from EA log 2026-03-18 08:00)

| | Value |
|---|---|
| Account | $100K Darwinex Zero Crypto |
| SOL Price | ~$91.67 |
| Balance | $78,573 |
| Equity | $78,610 |
| Margin | $143,346 |
| ML | 54.8% (TRIM 54 / PROTECT 51 — active drop, trimming fast) |
| **SOLUSD** | |
| Long (hedge) | 16,247 (trimming actively — SOL dropping) |
| Short (bias) | 17,220 |
| Net Short | 973 |
| SOL Gross | 33,467 |
| TRIM closes (this session) | 32 |
| PROTECT closes | 0 |
| **ADAUSD** | |
| Short (naked) | **200,000** |
| ADA Price | ~$0.28 (entry) |
| ADA Margin | ~$56,000 (200K × $0.28) |
| ADA Profit @$0 | **$56,000** |
| **DOGEUSD** | |
| Status | **Stacking as margin allows** |
| Max volume/order | 10,000,000 lots |
| Min volume | 1,000 lots |
| Margin per lot | $0.10 |
| **Combined** | |
| TRIM | **56% / PROTECT 52%** (passive — set and forget) |
| Spread tolerance (SOL) | $78,424 / 33,510 = **$2.34/lot** |

### EA Configuration (Passive Grinding — Set and Forget)

| Parameter | Value |
|---|---|
| Mode | **MG: SHORT** (SOLUSD) |
| TRIM threshold | **54%** margin level (tightened during active SOL drop) |
| PROTECT threshold | **51%** margin level |
| Dead zone | 51%–54% (3% buffer — active monitoring) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (shorts) in crisis |
| ADAUSD | **MG: OFF** — 200K naked short, no hedge needed |
| DOGEUSD | **Manual stacking** as margin allows (EA bug 4756 on ADA/DOGE) |

**TRIM/PROTECT dead zone guide (for reference):**

| TRIM | PROTECT | Dead Zone | Use Case |
|---|---|---|---|
| 61% | 52% | 9% | **Overnight / AFK** — safe, slow trim |
| 56% | 52% | 4% | **Current — passive grinding** |
| 54% | 52% | 2% | Active monitoring only |
| 53% | 51% | 2% | Burst trimming — watch closely |
| 52% | 51% | 1% | **Maximum burst** — every tick, don't look away |

**Session summary (2026-03-18):**
1. Second MG opened with Open MG $3.00 (~14.5K L/S added)
2. Burst trimming + PROTECT fires reduced position (bias: 19,647 → 17,220)
3. 2K SOL longs bought manually → freed margin → 200K ADA short placed manually
4. DOGE stacking planned as margin allows (10M max vol, $0.10/lot margin)
5. TRIM 56/PROTECT 52 set for passive grinding. EA trimming 1 lot/tick.

**Known EA bug:** `OrderCalcMargin` error 4756 on ADAUSD/DOGEUSD. Manual orders work. Root cause: `OrderCheck` likely fails on symbols with very low margin per lot. Place ADA/DOGE orders manually until fixed.

### Position Sizing

```
SOLUSD:
  Shorts (bias) = 17,220
  Longs (hedge) = 16,247 (trimming actively — SOL dropping through $91.67)
  Net short = 973
  SOL Gross = 33,467
  Spread tolerance = $78,610 / 33,467 = $2.35/lot

ADAUSD:
  Shorts (naked) = 200,000 lots
  ADA price = ~$0.64
  ADA margin = ~$128,000
  No hedge — rides naked to $0

Combined margin: ~$128,667
Combined ML: 60.8%
```

**TRIM 54% with ML 54.8%.** SOL dropping — TRIM firing actively, 1-2 lots per tick. Widen to 61/51 before stepping away.

### Current Dual-Instrument Strategy

**SOLUSD:** Hedged martingale short — TRIM 56/PROTECT 52, grinding down 16,433 hedge longs. Let it work passively.

**ADAUSD:** 200,000 naked short — rides to $0 alongside SOL. Provides VaR diversification for DARWIN scoring. Placed manually (EA OrderCalcMargin bug on ADA — to be fixed).

### TRIM Progression to Pure Short (SOL)

With TRIM 56 and PROTECT 52, TRIM grinds hedge longs as SOL drops. 16,433 hedge to consume.

| SOL Price | Equity (est.) | SOL Hedge | SOL Net Short | SOL Gross | ML | Status |
|---|---|---|---|---|---|---|
| **$92 (now)** | **$78,250** | **16,433** | **787** | **33,653** | **60.8%** | TRIM 56 — grinding |
| $88 | $81,398 | 15,851 | 1,369 | 33,071 | 56% | TRIM at threshold |
| $80 | $92,290 | 14,558 | 2,662 | 31,778 | 56% | Safe |
| $70 | $118,910 | 11,834 | 5,386 | 29,054 | 56% | Comfortable |
| $60 | $172,770 | 6,710 | 10,510 | 23,930 | 56% | Growing fast |
| $50 | $277,870 | 0 | 17,220 | 17,220 | ~81% | **PURE SHORT** |
| $40 | $450,070 | 0 | 17,220 | 17,220 | 131% | Printing |
| $20 | $794,470 | 0 | 17,220 | 17,220 | 231% | Locked in |
| $10 | $966,670 | 0 | 17,220 | 17,220 | 562% | Locked in |
| **$0** | **$1,138,870** | **0** | **17,220** | **17,220** | **∞** | **Done** |

**Pure SOL short at ~$50.** Every $1 below $50 = **$17,220** profit.

### Combined Profit at $0 (Both Instruments)

| Instrument | Bias Lots | Entry Price | Profit @$0 |
|---|---|---|---|
| SOLUSD | 17,220 | ~$94 | **$1,138,870** |
| ADAUSD | 200,000 | ~$0.28 | **$56,000** |
| DOGEUSD | TBD (stacking) | ~$0.17 | **TBD** |
| **Combined** | | | **~$1,195,000+** |

### How TRIM Pacing Works (SOL, TRIM 56/PROTECT 52)

| SOL Drop | Equity Gained (from net) | Lots Trimmed | Net After | Status |
|---|---|---|---|---|
| $92 → $88 | $3,148 (787 × $4) | 582 | 1,369 | TRIM grinding |
| $88 → $80 | $10,952 (1,369 × $8) | 1,293 | 2,662 | Moderate |
| $80 → $70 | $26,620 (2,662 × $10) | 2,724 | 5,386 | Building |
| $70 → $60 | $53,860 (5,386 × $10) | 5,124 | 10,510 | Fast |
| $60 → $50 | $105,100 (10,510 × $10) | 6,710 (all) | 17,220 | **Complete — PURE SHORT** |

### Key Milestones

- **$88**: TRIM at threshold, grinding 1 lot per tick
- **$80**: Equity $92K, net 2,662 → safe, flywheel building
- **$70**: Equity $119K, net 5,386 → comfortable
- **$60**: Equity $173K, net 10,510 → flywheel accelerating fast
- **~$50**: **SOL PURE SHORT** — all 16,433 hedge consumed. 17,220 lots riding free
- **$0**: SOL **$1,139K** + ADA **$128K** = **~$1,267K total profit**
- **Combined with ADA**: SOL $666K + ADA $280K = **~$946K total**

### ADA Short Stacking (Same Account — VaR Diversification)

**Strategy:** As SOL equity grows, stack 1,000-lot naked ADA short orders (max per order). Max 400 positions per account — SOL martingale uses many positions, remaining slots used for ADA shorts. ADA chosen over DOGE for DARWIN VaR optimization.

**Why ADA, not DOGE:**
- **4x more VaR per order** — ADA $0.70 vs DOGE $0.17. 1,000 lots × $0.70 = $700 nominal vs $170
- **Lower correlation with SOL** — ADA has its own ecosystem (Cardano/Plutus). Darwinex rewards diversified VaR
- **Slower VaR decay** — ADA holds VaR longer as price drops, smoothing the DARWIN profile
- **Better D-Score** — multiple uncorrelated short positions = consistent risk profile

**Why stack shorts:** As SOL approaches $0, SOL VaR collapses (nominal shrinking). ADA shorts maintain VaR → Darwinex sees consistent risk-taking → better DARWIN scoring → more DarwinIA allocation.

**Broker limits:** 1,000 lots max per order, 400 positions max per account.

#### ADA Stacking Plan (1,000 lots per order, ~$0.70 ADA)

Each 1,000-lot ADA short: margin = $700, profit at $0 = $700.

| SOL Price | SOL Equity | Available Positions | ADA Orders Stacked | ADA Lots Total | ADA Profit @$0 |
|---|---|---|---|---|---|
| **$80** | $111K | ~50 | 10 | 10,000 | $7,000 |
| **$70** | $138K | ~80 | 30 | 30,000 | $21,000 |
| **$62 (pure short)** | $170K | ~150 | 80 | 80,000 | $56,000 |
| **$50** | $266K | ~200 | 150 | 150,000 | $105,000 |
| **$40** | $346K | ~250 | 200 | 200,000 | $140,000 |
| **$30** | $426K | ~300 | 300 | 300,000 | $210,000 |
| **$20** | $506K | ~350 | 400 | 400,000 | $280,000 |

**At max stacking (400 orders × 1,000 lots = 400,000 ADA short):**
- ADA margin: 400K × $0.70 = $280K
- ADA profit at $0: **$280,000**
- Combined SOL + ADA at $0: **$666K + $280K = ~$946K**

#### VaR Impact on DARWIN

| Phase | SOL VaR | ADA VaR | Combined | DARWIN Effect |
|---|---|---|---|---|
| SOL trimming ($94→$62) | Stable ~12% | Growing (stacking) | **Rising** | Building track record |
| SOL pure short ($62→$20) | Compressing | **Stable/growing** | **Stable** | Consistent risk = good D-Score |
| SOL near $0 ($20→$0) | Collapsing | **Holds** | **ADA dominates** | VaR doesn't vanish — DARWIN stays active |
| Both at $0 | $0 | $0 | $0 | Close out — massive return locked |

**Without ADA:** DARWIN VaR collapses as SOL approaches $0. Darwinex sees a "dead" strategy. D-Score drops.
**With ADA:** DARWIN VaR stays elevated through ADA shorts. Consistent risk profile. Better DarwinIA scoring. More allocation = more performance fees.

#### Key Milestones (Updated)

- **~$80**: Begin stacking ADA shorts (10 orders, 10K lots)
- **~$70**: DOGE trigger was here — ADA stacking accelerated (30 orders)
- **~$62**: SOL **PURE SHORT** + 80K ADA lots stacked
- **~$50**: 150K ADA lots. Combined equity growing on both positions
- **~$20**: Max ADA stacking (400K lots). SOL + ADA printing simultaneously
- **$0**: **SOL $666K + ADA $280K = ~$946K total profit**

### Adverse Move Safety (Overnight)

With net 1,791 at $94, equity $85,318, PROTECT at 50.1%:

| SOL Price | Bounce | Equity | ML | Status |
|---|---|---|---|---|
| $94 (now) | — | $85,318 | 50.7% | Dead zone |
| **$94.40** | **+0.4%** | **$84,602** | **~50.1%** | **PROTECT fires** — balanced close |
| $97 | +3.2% | $79,943 | 43% | PROTECT firing |
| $100 | +6.4% | $74,568 | 38% | PROTECT urgent |

**PROTECT fires at ~$94.40 ($0.40 SOL bounce).** With TRIM at 61% for overnight, the 10.9% dead zone means PROTECT won't cascade — it fires once, balanced closes, ML recovers, and settles in the dead zone. Spread tolerance at $6.00/lot provides excellent overnight safety.

### Overnight Safety

| SOL Price | Gross | Equity | Spread Tol. | Overnight? |
|---|---|---|---|---|
| **$94 (now)** | **14,209** | **$85,318** | **$6.00** | **Very safe — 3x the $2.00 rule** |
| $89 | 14,209 | $94,273 | $6.63 | Very safe |
| $80 | 13,302 | $110,584 | $8.31 | Extremely safe |

### SOLUSD Multiplier Effect

```
Standard Short:
  $85K equity → 453 SOL lots → hold → $42.5K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale (after burst trimming):
  $85K equity → 8,000 SOL short lots (hedged with 6,209 longs)
    → Net short: 1,791 lots — TRIM paused at 50.7% ML
    → Hedge already 75% consumed at $94 via burst trimming
    → $94 → $89:  no trims (ML below 61%)  net short: 1,791 lots
    → $89 → $80:  TRIM closes    883 longs → net short: 2,698 lots
    → $80 → $70:  TRIM closes  1,939 longs → net short: 4,637 lots
    → ~$70: DOGE shorts opened on second account
    → $70 → $62:  TRIM closes  3,363 longs → net short: 8,000 lots (PURE SHORT)
    → SOL hits $0: close all        → ~$581K net profit (6.8x) plus DOGE
  [Burst trimming at $94 pre-burned 75% of hedge fuel.
   Pure short at $62 instead of $27. DOGE entry at $70 instead of $45.
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

### Operation SOL/ADA/DOGE → $0

**Multi-instrument crypto short.** SOL martingale + ADA naked short + DOGE naked short on same account. TRIM 56/PROTECT 52 grinding SOL hedge passively.

| Instrument | Position | Lots | Entry | Margin | Profit @$0 |
|---|---|---|---|---|---|
| **SOLUSD** | 16,433L / 17,220S (martingale) | 17,220 bias | ~$94 | ~$73K (net 787) | **$1,139K** |
| **ADAUSD** | Naked short | 200,000 | ~$0.28 | ~$56K | **$56K** |
| **DOGEUSD** | Naked short (stacking) | TBD | ~$0.17 | $0.10/lot | **TBD** |
| **Combined** | | | | ~$129K | **$1,195K+** |

**DOGE max volume: 10,000,000 lots per order. Min: 1,000. Margin: $0.10/lot.** Stack as margin allows — won't hit position limit due to volume limits.

**Target: all three to $0.**

| Milestone | SOL Price | SOL Net Short | Status |
|---|---|---|---|
| Now | $92 | 787 | TRIM 56/52 grinding passively |
| TRIM building | $80 | 2,662 | Flywheel engaging |
| Accelerating | $60 | 10,510 | Stack more ADA/DOGE with freed margin |
| **SOL pure short** | **~$50** | **17,220** | All hedge consumed |
| **Target** | **$0** | **17,220** | **SOL $1.14M + ADA $56K + DOGE TBD** |

### Why Multi-Instrument Short Is Optimal for Darwinex

Stacking short positions across SOL, ADA, and DOGE isn't just about more profit — it fundamentally improves every metric Darwinex uses to score, amplify, and allocate capital to your DARWIN.

#### 1. VaR Stability = Better D-Score

Darwinex calculates VaR as:
```
VaR = 1.65 × StdDev(daily returns) × NominalValue
```

With only SOL short, VaR **collapses as SOL approaches $0** — the nominal value shrinks and the DARWIN looks like it stopped trading. Darwinex penalizes this with lower D-Score (Investable Attributes score).

With SOL + ADA + DOGE short:
- As SOL VaR collapses ($94 → $10 = 89% VaR reduction), ADA and DOGE VaR **persists**
- The DARWIN shows **continuous, consistent risk-taking** — not a one-shot trade that wound down
- D-Score stays elevated through the entire collapse phase

| Phase | SOL VaR | ADA+DOGE VaR | Combined | D-Score Impact |
|---|---|---|---|---|
| SOL trimming ($94→$50) | Stable/growing | Stable | **Strong** | Building track record |
| SOL pure short ($50→$10) | **Compressing** | Stable | **ADA/DOGE hold it up** | Consistent risk |
| Near $0 ($10→$0) | **Near zero** | **Still active** | **DARWIN stays alive** | No "dead strategy" penalty |

**Without ADA/DOGE:** D-Score drops as SOL VaR vanishes. Darwinex sees a dormant strategy. Investor confidence drops.

**With ADA/DOGE:** D-Score stays healthy. DARWIN looks actively managed through the entire thesis.

#### 2. Risk Multiplier Amplification

Darwinex normalizes all DARWINs to a target VaR band of **3.25% — 6.5% monthly** (95% confidence):

```
Risk Multiplier = Target VaR / Strategy VaR
```

When strategy VaR is LOW (SOL near $0), the risk multiplier goes UP — Darwinex **amplifies returns** to compensate for lower perceived risk. This is the "lock-in" effect:

| Strategy VaR | Target VaR | Risk Multiplier | Effect on DARWIN Returns |
|---|---|---|---|
| 12% (SOL at $94) | 6% | 0.5x | Returns dampened |
| 6% (SOL at $50) | 5% | 0.83x | Moderate dampening |
| 2% (SOL at $10) | 4% | 2.0x | **2x amplification** |
| 0.5% (SOL at $2) | 3.25% | 6.5x | **6.5x amplification** |

**But VaR can't go to zero.** If SOL is your only position and it's near $0, VaR approaches zero → risk multiplier approaches infinity → Darwinex caps at 9.75x D-Leverage. The DARWIN stops being investable because there's no risk to normalize against.

**ADA and DOGE maintain a VaR floor.** Even when SOL VaR is negligible, ADA/DOGE provide enough VaR to keep the risk multiplier in a healthy range (2-6x) instead of spiking to cap. This means:
- Returns are amplified but not capped
- The DARWIN remains investable (DarwinIA keeps scoring it)
- Investor allocation continues

#### 3. Correlation Diversification = Higher Sharpe Ratio

Darwinex rewards strategies with high risk-adjusted returns. Adding uncorrelated instruments improves the Sharpe ratio:

```
Portfolio VaR < Sum of individual VaRs (when correlation < 1)

SOL alone:  VaR = VaR_SOL
SOL + ADA:  VaR = sqrt(VaR_SOL² + VaR_ADA² + 2×corr×VaR_SOL×VaR_ADA)
            If corr = 0.7: Portfolio VaR < VaR_SOL + VaR_ADA
```

**Lower portfolio VaR with same expected return = higher Sharpe = better DarwinIA scoring.** Even though SOL and ADA are correlated (~0.7), adding ADA still improves the risk-adjusted profile. DOGE adds a third leg with slightly different dynamics (meme momentum vs ecosystem value).

#### 4. DarwinIA Allocation and Performance Fees

DarwinIA scores DARWINs on **risk-adjusted returns** with heavy weight on consistency:

**DarwinIA SILVER (3-month allocation: €30K — €375K):**
- 22% current month return
- 67% cumulative 6-month return
- 11% max drawdown

**DarwinIA GOLD (6-month allocation: €50K — €500K):**
- Return/Drawdown ratio > 2.5
- Minimum returns: >20% (1yr) to >40% (5yr)

Multi-instrument short delivers on ALL these metrics:

| Metric | SOL Only | SOL + ADA + DOGE |
|---|---|---|
| Monthly return consistency | Volatile (one instrument) | **Smoother** (three instruments) |
| Drawdown | Higher (concentrated) | **Lower** (diversified) |
| Return/Drawdown ratio | Good | **Better** (same return, less drawdown) |
| VaR stability | Collapses near $0 | **Maintained** |
| DarwinIA scoring | Degrades as SOL nears $0 | **Stays competitive** |

**Performance fee income** at peak DarwinIA allocation (€375K SILVER):
- DARWIN makes 30% in a month (amplified from signal return)
- 15% performance fee on €375K × 30% = **€16,875 per month**
- This is on top of signal account profits

#### 5. Investor Experience

Investors in the DARWIN see:
- **Consistent returns** — not a spike-then-nothing pattern
- **Managed risk profile** — VaR doesn't vanish, strategy looks active
- **Multiple positions** — appears like a diversified fund, not a single bet
- **Growing equity curve** — three instruments all contributing to smooth upward performance

This attracts and retains investor capital. More capital = more performance fees = more profit for the trader.

#### The Compounding Effect

```
More instruments short → Better VaR profile → Higher D-Score
Higher D-Score → More DarwinIA allocation → More performance fees
Better risk-adjusted returns → More investors → More AUM → More fees
Consistent VaR → Risk multiplier stays in sweet spot (2-6x) → DARWIN outperforms signal
All three go to $0 → Signal profit $1.2M+ → DARWIN amplified to $2-3M+ → Fees on top
```

**Every additional short instrument adds profit, improves the DARWIN, and compounds through Darwinex's scoring system.** The marginal cost (margin, spread) is tiny. The marginal benefit (VaR stability, D-Score, investor confidence, amplification) is enormous.

**Bottom line: stack every crypto short you can. SOL is the engine. ADA and DOGE are the turbochargers for the DARWIN.**

### Crypto Lessons (PM#1-5)

Three $100K accounts, five spread-spike liquidations. The EA logic worked perfectly every time — forward-looking TRIM, dynamic PROTECT, hard floor, bias protection all fired correctly. The accounts were destroyed by **crypto's uniquely violent spread behavior** at insufficient spread tolerance. Key lesson: the $2.00/lot rule is necessary and must be respected from day one. Even $1.91/lot tolerance was fatal (PM#5).

### Why Martingale for Crypto, Not CFD

The hedged martingale works best when:
1. **Lots are cheap** (1:1 margin = 1 lot per $1 of price) — maximizes TRIM fuel
2. **Thesis is strong** (SOL/ADA/DOGE → $0 in crypto bear market)
3. **Position sizing is respected** ($2.00/lot from day one, no exceptions)
4. **Multiple instruments** amplify DARWIN performance through VaR diversification

CFD commodities have the wrong profile: expensive lots (high leverage = fewer lots), structural spread costs that eat TRIM room, and less fuel for the flywheel. The same EA works on both, but the math favors crypto despite the spread risk — IF you size correctly.
