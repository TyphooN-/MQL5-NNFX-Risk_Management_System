# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account Equity | $67,905 |
| Account Balance | $37,677 |
| Floating P/L | +$30,228 (equity leads — shorts printing) |
| Margin Level | 60.1% |
| Margin Call Level | 50% |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 66% margin level (65% when actively monitoring; scaled to gross) |
| TRIM lots | 20 per close (10s cooldown) |
| PROTECT threshold | 56% margin level (static — never lower after 54% broker liquidation) |
| PROTECT lots | 10 per side (balanced close) |
| PROTECT cooldown | 15 seconds between fires |
| Dead zone | 56%–66% (EA does nothing) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Circuit breaker | 1000 fires max before auto-disable |
| Bias protection | Never closes bias (shorts) in crisis |

### Why 66/56 (10% Dead Zone)

With 84K gross lots on $68K equity, spread changes cause **~1.5% ML swings** tick-to-tick. The TRIM threshold is scaled to gross exposure:

- **PROTECT deactivates** at 56% (same as threshold — no midpoint, fires only when genuinely below danger level)
- PROTECT at 56% leaves 6% buffer above 50% margin call
- 15-second cooldown prevents cascade at scale — 1000 fires takes minimum 250 minutes (~4 hours)
- TRIM at 66% prevents trimming from pushing ML toward PROTECT

**Dynamic TRIM tuning:** PROTECT stays fixed at 56%. TRIM is scaled to gross exposure — tighten 1% for every ~10K gross reduction:

| Gross Level | TRIM | Dead Zone | Spread Noise |
|---|---|---|---|
| **84K (now)** | **66%** | **10%** | ~1.5% |
| 80K | 63% | 7% | ~1.5% |
| 70K | 62% | 6% | ~1.3% |
| 58K (overnight safe) | 65% | 9% | Widen for sleep |
| 50K | 61% | 5% | ~1.0% |
| 40K | 60% | 4% | ~0.8% |

**Active monitoring override:** When watching the chart, TRIM can be set 1% tighter (e.g., 63% at 84K gross) to accelerate unwinding. Switch back to standard or wider before stepping away.

### Entry Rules: Single Base Price, Maximum Intensity

**The hedge must be set up at maximum intensity at a single base price.** This is the most critical rule of the strategy.

1. **Single base price** — all longs and shorts entered at the same price. No averaging in, no adding below base.
2. **Maximum intensity at open** — gross set to equity / $2.00 on day one. This is the biggest the position will ever be.
3. **One-way ratchet** — from entry, gross only decreases. Every trim, every PROTECT fire reduces gross permanently.
4. **Exception: adding above base** — if price pushes above the original entry, additional hedge lots can be added because the new longs are immediately profitable and trimmable. However, this increases gross and spread exposure, so it should be done sparingly and only when the spread tolerance (equity / new gross) remains acceptable.

**Why single base price:**
- All longs have identical P/L per dollar of movement — predictable, uniform trim losses
- No "toxic longs" entered below base that cost $500+ per trim and push ML toward PROTECT
- Bounces above entry make trims near breakeven or profitable
- Drops below entry have small, uniform trim losses

**Why adding below base is forbidden:**
- New longs are immediately underwater — every trim realizes a loss
- Adding lots increases gross without increasing equity proportionally → spread tolerance drops
- Spread cost on new lots is an immediate equity hit
- Dead zone must widen for larger gross → slower trimming → longer time over-exposed
- Resets the clock on reaching overnight safety — the safe gross target becomes further away, not closer

**Why adding above base is acceptable (with caution):**
- New longs are immediately profitable → trims near breakeven instead of realizing losses
- Adds more fuel for the trim engine on the next bounce
- But still increases gross → must verify spread tolerance stays above $2.00/lot after adding

**The lifecycle:**
```
Entry:  Max gross at one price → most dangerous moment
         ↓ (EA trims, gross shrinks)
Middle: Improving safety, growing net short
         ↓ (gross approaches safe level)
Safe:   Gross < equity/$2.00 → overnight safe
         ↓ (continue trimming)
Done:   Pure short → add DOGE → ride to $0
```

### Position Sizing Formula

```
Max safe gross lots = Equity / $2.00 (worst-case overnight spread)

$67,905 / $2.00 = 33,953 max safe gross lots
```

Current gross (83,710) is **2.46x over the safe limit** — EA is actively trimming to reach safety. Overnight is not safe until gross < 39K (or equity grows enough to cover current gross).

### Current Positions

| Asset | Price | Long Lots | Short Lots | Net Short |
|-------|-------|-----------|------------|-----------|
| SOLUSD | ~$92 | 41,240 | 42,470 | 1,230 |
| DOGEUSD | — | 0 | 0 | 0 |

**Note on DOGE:** Will be opened once SOL longs are under ~10K and equity headroom allows. Target entry around ~$50 SOL when equity is ~$837K+ and ~360K DOGE lots fit within the position sizing rule. See [DOGE Entry Timing](#doge-entry-timing) for details.

### Trim Progress to Pure Short

| Trim Progress | Longs | Shorts | Gross | Net Short | Spread Tolerance | TRIM |
|---|---|---|---|---|---|---|
| Now | 41,240 | 42,470 | 83,710 | 1,230 | $0.81/lot | 66% |
| 80K gross | 37,530 | 42,470 | 80,000 | 4,940 | $1.06/lot* | 66% |
| 70K gross | 27,530 | 42,470 | 70,000 | 14,940 | $1.90/lot* | 65% |
| 60K gross | 17,530 | 42,470 | 60,000 | 24,940 | $3.50/lot* | 64% |
| 50K gross | 7,530 | 42,470 | 50,000 | 34,940 | $6.00/lot* | 63% |
| **Fully trimmed** | **0** | **42,470** | **42,470** | **42,470** | **$10.00+/lot*** | **—** |

*Spread tolerance improves faster than gross shrinks because equity grows from net short floating P/L.*

### Equity > Balance Crossover

**Current state:** Equity ($67,905) **leads** balance ($37,677) by $30,228. The crossover has already happened — shorts' floating P/L dominates. Broker liquidations and PROTECT fires reduced balance faster than expected (crossover predicted at ~$87 SOL, occurred at ~$92).

**How the gap widens:** As SOL drops, equity grows from two sources:
1. **Net short exposure** — 1,230+ lots earn $1,230+ per $1 SOL drop (grows as longs trimmed)
2. **Trimming losses reduce balance further** — each trim realizes a loss, pushing balance down while equity stays stable

| SOL Price | Longs | Gross | Net Short | Balance | Floating P/L | Equity | Spread Tol. | Status |
|---|---|---|---|---|---|---|---|---|
| **$92 (now)** | 41,240 | 83,710 | 1,230 | $37,677 | +$30,228 | **$67,905** | $0.81 | **Equity leads** |
| $85 | 35,000 | 77,470 | 7,470 | $27,000 | +$100,000 | **$127,000** | $1.64 | Growing fast |
| $78 | 28,000 | 70,470 | 14,470 | $10,000 | +$235,000 | **$245,000** | **$3.48** | **Overnight safe** |
| $70 | 20,000 | 62,470 | 22,470 | -$30,000 | +$490,000 | **$460,000** | $7.36 | Comfortable |
| $60 | 12,000 | 54,470 | 30,470 | -$100,000 | +$870,000 | **$770,000** | $14.14 | Very safe |
| $50 | 5,000 | 47,470 | 37,470 | -$180,000 | +$1,400,000 | **$1,220,000** | $25.70 | Nearly pure |
| $35 | 1,000 | 43,470 | 41,470 | -$260,000 | +$2,300,000 | **$2,040,000** | $46.93 | Approaching pure |
| $0 | 0 | 42,470 | 42,470 | -$290,000 | +$3,907,240 | **$3,617,240** | ∞ | Done |

**Key milestones:**
- **~$87**: Equity eclipses balance. From here, equity only grows faster than balance falls.
- **~$82**: Trim costs drop below 5% of equity. Each trim loss is a rounding error against $150K+ equity.
- **~$78**: **Self-sustaining.** Overnight safe ($2.56/lot). Balance goes negative and never returns. Every $1 drop adds ~$26K equity but only ~$3-5K in trim costs.
- **~$50**: Position is deeply profitable. Swings become trivial relative to equity. Settings can be tightened aggressively.

### When Balance Becomes Irrelevant

Balance is **already** irrelevant — margin level, stop-out, and overnight survival all use **equity**, not balance. Negative balance is normal in hedged accounts and causes no practical problems: margin calculations, broker stop-out, and free margin all reference equity.

| SOL Price | Balance | Equity | Equity / \|Balance\| | Trim Costs as % of Equity |
|---|---|---|---|---|
| **$92 (now)** | **$37,677** | **$67,905** | **1.8x — Equity already leads** | — |
| $85 | $27,000 | $127,000 | 4.7x | 3.5% |
| $78 | $10,000 | $245,000 | 24.5x | 4.0% |
| $70 | -$30,000 | $460,000 | 15.3x | 3.2% |
| $60 | -$100,000 | $770,000 | 7.7x | 3.0% |
| $50 | -$180,000 | $1,220,000 | 6.8x | 2.5% |
| $35 | -$260,000 | $2,040,000 | 7.8x | 2.0% |

**The $78 threshold** is where the position becomes self-sustaining:
- Equity passes $245K (overnight safe)
- Balance goes permanently negative
- Trim costs are 4% of equity and shrinking relative to equity growth
- Each $1 drop: ~$14K equity gain vs ~$2-3K trim cost (5:1 ratio, widening)
- The shorts' floating P/L completely dominates all other accounting

### PROTECT as Strategic Tool

PROTECT (balanced close) is not just an emergency mechanism — **it serves the strategy**:

1. **Survives overnight spread spikes** — a balanced close reduces margin requirement, keeping the account alive through the spike
2. **Resumes trimming faster** — surviving the spike means the EA can continue trimming longs on the next bounce, growing net short
3. **Grows net short indirectly** — each balanced close removes 10L + 10S, preserving the net short ratio while reducing gross
4. **Better than broker intervention** — the broker would liquidate positions randomly (often closing shorts, destroying the thesis). PROTECT closes balanced pairs, preserving the net short structure.

**The tradeoff:** PROTECT destroys shorts (10 per fire alongside 10 longs). But losing 10 shorts to survive beats losing the entire position to a broker stop-out. The shorts can be rebuilt; a liquidated account cannot.

**Constraints:**
- PROTECT at 56% is the floor (never lower after 54% broker liquidation experience)
- 15-second cooldown — allows market to resolve spread spikes before burning lots
- 1000 max fires — meaningful margin relief at scale (10,000 lots per side = 17% of position)
- Unlimited fires acceptable if cooldown is sufficient (future consideration)

### Overnight Safety Plan

| Gross Level | Spread Tolerance | Overnight? | Settings |
|---|---|---|---|
| < 39K | $2.00+/lot | **Safe** | 64/56 |
| 39-50K | $1.60-2.00/lot | **Risky** | 68/56 |
| 50-70K | $1.10-1.60/lot | **Dangerous** | Don't sleep |
| 70K+ | < $1.10/lot | **No** | Manual balanced close first |

**Note:** These thresholds shift as equity grows. At $78 SOL with ~$207K equity, even 82K gross is overnight-safe ($2.52/lot). Check equity/gross ratio, not just gross alone.

If gross cannot be trimmed to a safe ratio by bedtime, a manual balanced close (equal lots L+S) should be used to force gross down to safety.

---

## Scenario A: Standard Short (No Hedging)

With $69,322 equity, 1:1 crypto margin, and 200% margin level (minimum to survive any volatility):

**Maximum position at open:**
- SOLUSD: ~385 lots short @ $90

### Profit if SOL hits $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 385 | $90 | $34,650 |

**Return: $34,650 on $69,322 = 0.50x (50% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Current Position Structure

The hedge: 41,240 long lots vs 42,470 short lots on SOLUSD. Net short exposure is 1,230 lots, but the gross exposure (83,710 lots) creates the margin requirement.

The EA manages this automatically:
- **Above 66%**: TRIM — close 20 lots of hedge (BUY) every 10s, freeing margin
- **56%–66%**: Dead zone — EA does nothing, allows normal price action
- **Below 56%**: PROTECT — balanced close 10L + 10S (15s cooldown between fires)
- **Below 10%**: Hard floor — EA halts entirely, broker handles stop-out
- **After 1000 fires**: Circuit breaker — PROTECT auto-disables
- **No hedges left**: EA refuses to close bias — shorts are sacred

### Dynamic TRIM Strategy

TRIM is adjusted based on market conditions while PROTECT stays fixed at 56%. PROTECT deactivates as soon as ML recovers above 56% — no midpoint overshoot. The dead zone width determines how much room TRIM has to operate without triggering PROTECT.

| Market Condition | TRIM | Dead Zone | When |
|------------------|------|-----------|------|
| **Current setting** | **66%** | **10%** | Standard operating (set and forget) |
| Active monitoring | 65% | 9% | Watching chart, accelerated trim |
| After gross < 70K | 65% | 9% | Can tighten permanently |
| After gross < 50K | 63% | 7% | Spread noise ~1.0% |
| Overnight | 68%+ | 12%+ | Sleeping (if gross safe) |

### Phase 1: $90 → $35 (5 bounces)

SOL doesn't drop straight. It bounces. Each bounce is a trim cycle. The EA trims longs above the TRIM threshold — the purpose is not to profit from longs but to **remove the hedge at minimum cost**, growing net short exposure so the shorts' floating P/L becomes the profit engine.

**Bounce 1: $90 → $96 → $75**
- Spike to $96: longs gain value, ML improves, EA trims longs
- ~9,000 long lots trimmed — near breakeven or small profit (above base price)
- Drop to $75: shorts profit massively, net short now 10,360 lots
- **Short floating P/L grows by ~$155,400** (10,360 × $15 drop)
- Trim cost: **~$0** (trimmed above base)

**Bounce 2: $75 → $83 → $62**
- Spike to $83: EA trims ~10,000 longs — these are below base ($90), small loss per trim
- Drop to $62: net short now 20,360 lots
- **Short floating P/L grows by ~$427,560** (20,360 × $21 from $83)
- Trim cost: **~$70,000** (10K lots × ~$7 avg loss below base)

**Bounce 3: $62 → $70 → $50**
- Trim ~10,000 longs at ~$20 below base
- Net short now 30,360 lots
- **Short floating P/L grows by ~$607,200** (30,360 × $20 drop)
- Trim cost: **~$200,000**

**Bounce 4: $50 → $57 → $40**
- Trim ~8,000 longs at ~$33 below base
- Net short now 38,360 lots
- **Short floating P/L grows by ~$652,120** (38,360 × $17 drop)
- Trim cost: **~$264,000**

**Bounce 5: $40 → $46 → $35**
- Trim ~7,000 longs at ~$44 below base. Most longs consumed.
- Net short now ~45,360 lots
- **Short floating P/L grows by ~$498,960** (45,360 × $11 drop)
- Trim cost: **~$308,000**

**Phase 1 subtotal:**
- Long lots trimmed: ~44,000 (41,240 → ~5,600)
- Total trim cost (realized long losses): ~$842,000
- Net short exposure: ~45,230 lots (up from 1,230)
- **Short floating P/L: ~$2,494,800** (45,360 lots × $55 avg drop from $90)
- The trim cost is the price of building 45,360 lots of net short exposure — far cheaper than trying to open 45K shorts outright

### Phase 2: $35 → $0 (final collapse with 3 bounces)

Remaining ~5,600 longs consumed. Position becomes pure short. VaR collapsing.

**Bounce 6: $35 → $40 → $20**
- Final longs (~5,600) consumed — trim cost ~$280,000
- Once longs gone: pure short, no more hedge volatility
- **DOGE shorts opened at maximum size**

**Bounces 7-8: $20 → $5 → $0**
- Pure short — each dollar down = 42,470 × $1 = **$42,470 profit per dollar**
- DOGE shorts adding to profits on every tick down
- No more trim costs — position is pure profit accumulation

### Final Close at $0

| Component | Lots | Profit |
|-----------|------|--------|
| SOLUSD shorts (closed at $0) | 42,470 | **$3,907,240** |
| Long trim costs (hedge removal) | 41,240 consumed | **-$900,000** |
| DOGE (opened after unwind) | TBD | TBD |
| **SOL Net Total** | | **$3,007,240** |

The long trim cost (~$900K) is the total price paid to remove the hedge across all bounces. This is the cost of building 42,470 lots of net short exposure — a position that would have required **$3.91M in margin** to open as a naked short. The hedge made it possible on $68K equity.

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Short positions closed at $0 | $3,907,240 |
| Long trim costs (hedge removal) | -$900,000 |
| **SOL Total Profit** | **$3,007,240** |
| DOGE (opened after unwind) | TBD |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $69,322 | $69,322 |
| Max short lots (SOL) | 385 | 42,470 (already held) |
| Survives 10% spike? | NO (margin call) | YES (41.2K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES (bounces = cheap trim opportunities) |
| Hedge removal cost | N/A | ~$900K (price of building 42K net short) |
| SOL profit if → $0 | **$34,650** | **$3,007,240** |
| Return multiple | **0.50x** | **44.3x** |
| Final account value | ~$103,555 | **~$3,075,145** |


---

## Key Assumptions

1. **Volatility**: 8 significant bounces (5-15%) on the way to zero — conservative for crypto
2. **Execution**: EA trims longs automatically (20 lots/10s above TRIM threshold), balanced PROTECT below 56% with 15s cooldown
3. **Spread noise**: ~1.5% ML swing from spread changes at 84K gross — absorbed by 8% dead zone
4. **No black swan recovery**: SOL does not recover permanently
5. **Margin management**: EA's zone-based system prevents margin call (broker stop-out at 50%, PROTECT at 56% leaves 6% buffer)
6. **DOGE**: Opened at max size once SOL hedge is fully unwound — both ride to $0
7. **Position structure**: 41.2K long / 42.5K short SOL already held. No new lots added below base — EA only trims the hedge
8. **PROTECT safeguards**: Hard floor (10%), circuit breaker (1000 fires), 15s cooldown, never closes bias
9. **Dynamic TRIM**: Scaled to gross — 64% at 84K, tighten 1% per ~10K gross reduction. PROTECT fixed at 56%
10. **Position sizing**: Gross lots must reach equity / $2.00 before overnight is safe (or equity must grow to cover current gross)

## The Multiplier Effect Visualized

```
Standard Short:
  $69K equity → 385 SOL lots → hold → $35K profit
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $69K equity → 42,470 SOL short lots (hedged with 41,240 longs)
    → Net short: 1,230 lots (nearly flat — survives any spike)
    → Bounce 1:  EA trims  9K longs  → net short: 10,230 lots
    → Bounce 2:  EA trims 10K longs  → net short: 20,230 lots
    → Bounce 3:  EA trims 10K longs  → net short: 30,230 lots
    → Bounce 4:  EA trims  8K longs  → net short: 38,230 lots
    → Bounce 5:  EA trims  7K longs  → net short: 45,230 lots
    → Bounce 6:  EA trims  5.6K longs→ net short: 42,470 lots (PURE SHORT)
    → DOGE shorts opened at max size
    → SOL hits $0: close all          → $3,007K net profit (plus DOGE)
  [Longs are a cost to remove, not a profit source. Shorts are the profit engine.
   Bounces make trimming cheaper. The goal: grow net short exposure at minimum cost.]
```

---

## VaR Dynamics: The Darwinex Amplifier

### How VaR Is Calculated

```
VaR = 1.65 × StdDev(daily returns) × NominalValue

NominalValue = |PositionSize| × (TickValue / TickSize) × CurrentPrice
```

**VaR is tethered to price.** As the underlying asset price drops, the nominal value of the position shrinks, and VaR shrinks with it. This is independent of P/L — it's a function of what you can lose from *here*, not what you've already gained.

### VaR Through the Phases

#### Phase 1: SOL $90 → $35

Current net short: 1,230 lots (but growing rapidly as EA trims longs)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $90 | 1,230 | $110,700 | $9,133 | $69,322 | 13.2% |
| $75 | 10,360 | $777,000 | $64,103 | $91,000* | 70.4% |
| $62 | 20,360 | $1,262,320 | $104,141 | $140,000* | 74.4% |
| $50 | 30,360 | $1,518,000 | $125,235 | $250,000* | 50.1% |
| $35 | 45,360 | $1,587,600 | $130,977 | $520,000* | 25.2% |

*Equity grows from short floating P/L minus trim costs. VaR rises significantly as net exposure grows — heavily dampens DARWIN during this phase.*

#### Phase 2: SOL $35 → $0 (The Lock-In)

**Once longs are fully unwound, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $35 | 42,470 | $1,783,600 | $147,147 | $600,000 | 24.5% |
| $25 | 42,470 | $1,274,000 | $105,105 | $1,100,000 | 9.6% |
| $15 | 42,470 | $764,400 | $63,063 | $1,900,000 | 3.3% |
| $10 | 42,470 | $509,600 | $42,042 | $2,500,000 | 1.7% |
| $5 | 42,470 | $254,800 | $21,021 | $3,100,000 | 0.7% |
| $2 | 42,470 | $101,920 | $8,408 | $3,400,000 | 0.2% |
| $0 | 42,470 | $0 | $0 | $3,615,000 | 0.00% |

**Once longs are unwound, VaR can only decrease.** Every tick down:
- Nominal value shrinks → VaR shrinks
- Equity grows (shorts profiting) → VaR % shrinks even faster
- The profit is locked — there is nothing left to lose in the direction of the thesis

### The Darwinex Risk Multiplier Effect

Darwinex normalizes all DARWINs to a target VaR band of **3.25% — 6.5% monthly** (95% confidence):

```
Target VaR = (Current VaR / Max VaR in lookback) × 6.5%

Risk Multiplier = Target VaR / Strategy VaR
```

#### How This Applies to the Strategy

**Phase 1 ($90 → $35): Very High VaR, Multiplier << 1.0**

Strategy VaR is very high due to gross exposure (84K total lots). The Darwinex risk engine **heavily dampens** the DARWIN:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 12.7% | ~6.0% | 0.47x | DARWIN shows 47% of raw returns |
| 74.4% | ~6.5% | 0.09x | Heavily dampened during peak exposure |

Returns are real but heavily dampened on the DARWIN while hedge is active.

**Phase 2 ($35 → $0): VaR Compressing → AMPLIFICATION**

As longs are consumed and VaR compresses, the Darwinex system works in your favor:

| SOL Price | Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|-----------|----------------|-------------------|-----------------|--------|
| $25 | 9.6% | ~6.0% | 0.63x | Still dampened |
| $15 | 3.3% | ~5.0% | 1.52x | **1.5x amplification** |
| $10 | 1.7% | ~4.0% | 2.35x | **2.4x amplification** |
| $5 | 0.7% | ~3.25% | 4.64x | **4.6x amplification** |
| $2 | 0.2% | ~3.25% | 9.75x | **Capped at 9.75x** |

**D-Leverage caps at 9.75x for positions held > 60 minutes.** So the maximum practical multiplier is **~9.75x**.

### The Lock-In Moment

**Once longs are fully unwound, the value is locked.**

```
With longs:
  Price goes up → longs profit, shorts lose → VaR stays elevated (hedge creates volatility)
  Price goes down → shorts profit, longs lose → VaR stays elevated

Without longs (fully unwound):
  Price goes up → shorts lose → but no longs to create paired volatility
  Price goes down → shorts profit → VaR ONLY decreases

  The only direction for VaR from here is DOWN.
  The only direction for equity from here is UP (if thesis holds).
```

Once longs are cleared:
1. **VaR collapses** — nominal value shrinking with price
2. **Equity only grows** — pure short profit accumulating
3. **Risk multiplier climbs** — Darwinex amplifies the returns
4. **Profit is locked** — mathematically, VaR approaches zero as price approaches zero
5. **DARWIN outperforms signal** — the lower the VaR, the higher the amplification

### VaR Impact on DarwinIA Allocation

DarwinIA scores DARWINs on risk-adjusted returns. The collapsing VaR creates an ideal profile:

**DarwinIA SILVER Rating Formula:**
- 22% current month return
- 67% cumulative 6-month return
- 11% max drawdown

**DarwinIA GOLD Requirements:**
- Return/Drawdown ratio > 2.5
- Minimum returns: >20% (1yr) to >40% (5yr)

During the collapse phase:
- **Returns are amplified** by the risk multiplier (up to 9.75x)
- **Drawdown is minimal** (VaR is tiny, position can barely lose)
- **Return/Drawdown ratio goes through the roof**

This means the DARWIN becomes a magnet for DarwinIA allocation:

| Allocation Tier | Amount | Duration |
|-----------------|--------|----------|
| DarwinIA SILVER | 30,000 — 375,000 EUR | 3 months |
| DarwinIA GOLD | 50,000 — 500,000 EUR | 6 months |
| **Performance fee** | **15% of profits** | Quarterly |

At peak amplification with a 375K EUR SILVER allocation:
- DARWIN makes 50% in a month (amplified from ~5% signal return)
- 15% performance fee on 375K × 50% = **$28,125 performance fee income**
- This is on top of the signal account profits

### Combined Profit with Darwinex Amplification

| Component | Signal Account | DARWIN (amplified) |
|-----------|---------------|-------------------|
| Short profits at $0 | $3,907,240 | ~$11,400,000+ (amplified ~2.5x avg) |
| Long trim costs | -$900,000 | (dampened in Phase 1) |
| DOGE (opened after unwind) | TBD | TBD |
| DarwinIA performance fees | — | $100,000 — $500,000 |
| **SOL Net Total** | **$3,007,240** | **$11,400,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $69,322 | $69,322 | $69,322 |
| Max short lots (SOL) | 385 | 42,470 (held now) | 42,470 (held now) |
| Survives 10% spike? | NO | YES (41.2K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | High → compressing | High → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.09x → 9.75x |
| Hedge removal cost | N/A | -$900,000 | -$900,000 |
| SOL signal profit | $34,650 | $3,007,240 | $3,007,240 |
| DOGE | — | TBD (after unwind) | TBD (after unwind) |
| DARWIN amplified returns | N/A | N/A | $8,900,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $100,000 — $500,000 |
| Return multiple (SOL only) | 0.50x | **44.3x** | 44.3x + DOGE + fees |

---

## Post-Mortem #1: The 57% PROTECT Disaster (2026-03-02)

### What Happened

The first virtual account running this strategy was destroyed overnight by a cascade of PROTECT failures. Starting conditions: $57K equity, 65K L / 66K S on SOLUSD, margin hovering around 62-64%.

**Timeline:**

1. **23:15 – 03:00**: PROTECT (set at 57%) fired repeatedly as margin oscillated near the threshold. Each fire was a balanced close (10L + 10S), preserving net short. This worked correctly — margin recovered each time. But over 3 hours, 22 balanced closes consumed 220 lots from each side.

2. **03:12:20 — The crash**: A spread spike dropped margin from ~62% to **7.5% instantly**. PROTECT rapid-fired 7 more balanced closes, burning through the remaining hedge lots. Margin spiraled: 7.5% → 3.3% → 2.3% → 1.7% → 1.3% → 1.0%.

3. **03:12:23 — No hedges left**: With all longs consumed, PROTECT fell back to closing bias (shorts). It rapid-fired **53 bias closes** (530 short lots destroyed) at 1-2% margin — locking in massive losses on every close.

4. **03:19 — User re-hedges manually**: User opened ~57K lots each side to rebuild the position. But PROTECT was still active (margin below 57%), so **the EA immediately destroyed the re-hedge too** — closing the user's manually opened positions as fast as they appeared.

5. **03:22 — Account gutted**: Final state: Hedge: 0, Bias: 0, Equity: **$26,883** (down from $57K). All 130K+ lots consumed. The EA fought the user's manual intervention.

### Root Causes

1. **No hard floor**: PROTECT kept firing at 1-2% margin where it couldn't possibly help. The broker was already force-liquidating positions — the EA just piled on.

2. **Bias-only fallback was catastrophic**: When no hedges remained, PROTECT switched to closing shorts. At 1% margin, selling 530 shorts just locked in losses — each close was worth less than the spread cost.

3. **No circuit breaker**: PROTECT fired 109 times total with no limit. It consumed every position on the account — first the hedges (balanced), then all the shorts (bias fallback), then the user's manually re-opened positions.

4. **Hedge margin netting**: In MT5 hedging mode, the broker gives reduced margin for hedged volume. The earlier PROTECT version (before balanced close) closed only longs, which **un-hedged** the shorts — each long close actually **increased** the margin requirement on remaining shorts, making margin spiral downward instead of recovering.

### How We Fixed It

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

**Safeguard 3 — Circuit Breaker (1000 fires max)**
```
After 1000 PROTECT fires, it auto-disables.
"PROTECT CIRCUIT BREAKER — 1000 fires reached. Disabled until manual reset."
```
At 114K gross, 69 fires removed only 690 lots per side (0.6% of position) — completely toothless. Raised to 1000 fires: 10,000 lots per side = 17% of position, providing meaningful margin relief. At 5s cooldown, 1000 fires takes minimum 83 minutes — spread spikes don't last that long. The counter resets when MG mode is toggled.

**Safeguard 4 — PROTECT Cooldown (5 seconds)**
```
After each PROTECT fire, the EA waits 5 seconds before firing again.
```
At scale, 10 lots/side per fire is too small to meaningfully move ML in a single fire. The 5s cooldown ensures 1000 fires takes a minimum of 83 minutes, giving the market time to resolve spread spikes naturally.

---

## Post-Mortem #2: The 55% PROTECT Cascade (2026-03-03)

### What Happened

With 83K gross lots (41K L / 42K S), PROTECT at 55% with 1-second cooldown proved insufficient. ML was hovering at 59.6% with TRIM at 59% slowly removing longs. A spread-driven ML dip triggered a cascade.

**Timeline:**

1. **ML dips below 55%**: PROTECT begins firing. Each balanced close removes 10L + 10S — only 0.024% of the 83K gross. ML barely moves.

2. **30 fires in 58 seconds**: PROTECT consumed all 30 circuit breaker fires in under a minute. Total: 300 lots removed from each side (600 lots total). ML stayed at 56-57% throughout — the closes were too small relative to gross exposure to recover ML above the 57% deactivation midpoint.

3. **Circuit breaker trips**: PROTECT auto-disabled after fire #30. But the damage was done — 600 lots gone, and ML still dangerously low.

4. **Broker intervenes**: Broker closed additional positions. ML jumped to 216% after forced liquidation.

5. **EA restarts**: Position stabilized at 39,870 L / 40,910 S. ML at 70%. TRIM resumes at 60%.

### Post-Mortem #2b: Broker Liquidation During TRIM (2026-03-03)

After rebuilding to 45K L / 46K S, trimming at 60% with PROTECT at 54% caused a second broker intervention. Each trim closed a **losing** long (-$350 to -$520 per 20 lots), which:
1. Reduced equity (realized loss)
2. Reduced hedge netting → more unhedged shorts → higher margin requirement
3. Both effects pushed ML **down** while trimming — the opposite of the intended effect

The broker closed 1,000 short lots when ML dropped below their threshold during active trimming. Resolution: raise TRIM to 61% so trimming only starts when ML has enough headroom.

### Post-Mortem #2c: PROTECT Oscillation at 61/56 and 60/56 (2026-03-04)

At 60/56 (4% dead zone), PROTECT fired 5 times due to spread-driven ML oscillation. The deactivation midpoint was (60+56)/2 = 58%, leaving only 2% between midpoint and TRIM. Spread noise of 1.5% easily bridged this gap, causing:
1. ML drops below 56% → PROTECT fires
2. ML recovers above 58% → PROTECT deactivates
3. Spread pushes ML back below 56% → PROTECT fires again

Similarly at 61/56, midpoint was 58.5%, gap to TRIM was 2.5% — still within spread noise.

**Resolution:** Raise TRIM to 62/56 to widen the dead zone. Later, the midpoint deactivation system was removed entirely — PROTECT now deactivates as soon as ML recovers above the threshold (55%). This eliminated the excessive firing at 57-58% ML that the midpoint caused.

### Root Causes

1. **1-second cooldown too short at 83K gross**: 30 fires in 58 seconds exhausted the circuit breaker before the market could recover. At this gross exposure, each fire is meaningless — 10 lots out of 83K can't move ML.

2. **PROTECT threshold too close to operating range**: With 1.5% spread-induced ML swings, PROTECT was easily triggered by a slightly wider spread.

3. **Deactivation midpoint too close to TRIM**: The midpoint system kept PROTECT firing at 57-58% ML (safely above danger). Later removed — PROTECT now deactivates at threshold (56%), not midpoint.

4. **Trimming underwater longs pushes ML down**: Closing longs at a loss reduces equity AND reduces hedge netting. At 60% TRIM with ML barely above threshold, trimming itself can trigger broker intervention.

### Resolution: Dynamic TRIM with Fixed PROTECT

| Setting | Before (cascade) | After (current) | Improvement |
|---------|-------------------|-----------------|-------------|
| TRIM | 59-61% | 66% (dynamic) | Raised until oscillation stops |
| PROTECT | 54-56% | 56% (static) | Fixed reference point |
| Dead zone | 4-6% | 10% (56-66) | Covers spread noise at 110K gross |
| Deactivation | Midpoint (~60%) | Threshold (56%) | No more firing at 57-58% |
| Cooldown | 1 second | 15 seconds | 1000 fires takes 183 min |
| Max fires | 30 | 1000 | Meaningful at 112K gross (10K lots/side) |

---

## Post-Mortem #3: Overnight Spread Spike Wipe (2026-03-03/04)

### What Happened

With 89K gross lots (44K L / 45K S) on $60K equity, an overnight spread spike destroyed the account. Settings were 64/55 with 5s cooldown.

**Timeline:**

1. **23:06 — Spread spike**: ML crashed from 64% to **7.3% instantly** in a single tick. The spread widened enough to consume ~$34K of margin on 89K gross lots.

2. **PROTECT fires once**: EA correctly identified the crisis. Hard floor kicked in at 6% — EA stood down.

3. **Broker liquidation**: Broker force-liquidated ~88K lots, leaving only ~1,000 shorts.

4. **04:14 — Wild position swings**: Positions appeared and disappeared as the broker continued unwinding. Account gutted to **$16,656**.

### Root Cause

**Position was 4x too large for the equity.** All EA safeguards worked correctly:
- Hard floor correctly halted PROTECT at 6%
- EA stood down and let broker handle it
- Never closed bias

The fundamental problem: 89K gross lots on $60K equity = **$0.67/lot spread tolerance**. Any significant spread widening exceeds equity. The $2.00/lot overnight spread was 3x the tolerance.

### The Position Sizing Rule

```
Max safe gross lots = Equity / $2.00

$60,000 / $2.00 = 30,000 max safe gross lots
Actual gross: 89,000 — nearly 3x over the limit
```

No amount of TRIM/PROTECT tuning can save a position that is fundamentally too large for the equity. The EA can manage spread noise, prevent cascades, and handle normal market moves. But catastrophic overnight spread spikes require the position itself to be within safety limits.

### Lessons Learned

1. **Position sizing is the ultimate safety mechanism.** TRIM/PROTECT/cooldown/circuit breaker are secondary defenses. The primary defense is keeping gross lots below equity / $2.00.

2. **Overnight spread spikes are catastrophic at scale.** A $2.00 spread on 89K lots = $178K impact on a $60K account. No EA can survive this.

3. **All EA safeguards worked correctly.** The hard floor, circuit breaker, bias protection, and cooldown all performed as designed. The account was lost because the position was too large, not because the EA failed.

4. **Fresh account rule: build to safe size, never beyond.** Current account: 84K gross on $68K equity ($0.81/lot tolerance) — EA is actively trimming. Equity growth from net short P/L will improve tolerance toward $2.00/lot by ~$78 SOL.

---

## The Full Cycle Strategy

The hedged martingale is designed for repeated execution across market cycles, focusing on two assets:

### Bear Market Phase (Current)
- **Account 1**: Short SOL → $0 via hedged martingale
- **Account 1**: Short DOGE → $0 (added once SOL longs < ~10K and equity headroom allows; ~$50 SOL target)
- SOL selected for: highest volatility, real zero risk (VC unlocks, ETH L2 competition, network outages)
- DOGE selected for: pure meme fragility, zero utility, Elon fatigue

### Bottom Detection & Flip
- Close remaining shorts at/near $0
- Flip to long on the same account
- Accumulated knowledge of SOL's price behavior from months of shorting informs bottom timing

### Bull Market Phase
- **Same account**: Long SOL at maximum size from the bottom
- SOL selected for: highest recovery multiple (did 32x last cycle: $8 → $260)
- Single-asset focus — no diversification needed when conviction is maximum

### Top Detection & Rebuild
- Close SOL longs at cycle top
- Rebuild hedged martingale shorts on SOL + DOGE
- Repeat

### One Account, One DARWIN
- Single crypto account handles both bear (short) and bull (long) phases
- One continuous DARWIN track record — VaR compression from shorts transitions into bull run returns
- No capital splitting — full equity rolls from short profits into long position
- Simpler management — one set of EA settings, one margin to monitor

### Why SOL + DOGE Only
- Deep knowledge of one primary asset beats shallow knowledge of many
- SOL's volatility profile works for both short (to $0) and long (from bottom)
- DOGE is the pure meme accelerant for the short side
- EA settings (TRIM/PROTECT/dead zone) are calibrated for SOL's spread behavior
- No need to re-learn spread noise, bounce patterns, or overnight behavior for new assets

---

## DOGE Entry Timing

DOGE shorts are added to the same account (Account 1) once the SOL unwind has progressed far enough that total gross (SOL + DOGE) stays within the position sizing rule: **total gross < equity / $2.00**.

### When to Add DOGE

| Trigger | SOL Price (est.) | SOL Longs | SOL Gross | Equity (est.) | DOGE Headroom | Sizing |
|---|---|---|---|---|---|---|
| After overnight-safe SOL | ~$78 | ~31,000 | ~82K | ~$207K | ~21,500 lots | Modest — starts early while DOGE priced high |
| **After significant trim** | **~$50** | **~8,000** | **~59K** | **~$837K** | **~359,500 lots** | **Large — SOL almost done, massive equity** |
| After full SOL trim | ~$35 | 0 | ~59K | ~$1.9M+ | ~899,000 lots | Maximum — zero competition for margin |

### Recommendation: Add After Significant Trim (~$50 SOL)

The sweet spot is once SOL longs are under ~10,000 and equity has grown substantially:

1. **DOGE is still priced high enough to short from** — waiting for full SOL trim risks DOGE already having dropped significantly
2. **Equity is massive** (~$837K+) — plenty of room for large DOGE position alongside remaining SOL
3. **SOL trim is nearly done** — only ~8,000 longs left, minimal risk of SOL margin competition
4. **Total gross stays safe**: 59K SOL + 359K DOGE = 418K total vs $837K / $2 = 418K limit

### DOGE Entry Sizing Formula

```
Available DOGE gross = (Equity / $2.00) - SOL gross

At $50 SOL:
  $837,000 / $2.00 = 418,500 max total gross
  418,500 - 59,000 SOL gross = 359,500 available DOGE lots
```

**Conservative approach:** Target DOGE gross at 80% of headroom to leave safety margin for spread spikes on two assets simultaneously.

### DOGE Position Structure

DOGE follows the same hedged martingale pattern as SOL:
- Enter at maximum intensity at a single DOGE base price
- Long + Short hedge, EA trims longs via TRIM zone
- Same PROTECT/circuit breaker/hard floor safeguards
- TRIM/PROTECT settings calibrated for DOGE spread behavior (may differ from SOL)

**Key difference:** By the time DOGE is opened, the account has substantial equity from SOL shorts. This means:
- DOGE spread tolerance is excellent from day one (unlike SOL which started over-exposed)
- DOGE overnight safety is immediate if sized correctly
- No anxious trimming phase — DOGE starts safe and stays safe

### Combined Ride to $0

Once SOL is pure short and DOGE is open:
- Both assets grinding to $0 simultaneously
- VaR collapsing on both positions
- Combined per-dollar profit: 42,470 (SOL) + DOGE lots
- Darwinex amplification applies to the combined position
- DarwinIA scoring benefits from the extreme return/drawdown ratio across both

### Why DOGE on the Same Account?

- Same directional thesis (short to $0) — one DARWIN, one track record
- Combined VaR compression is more impressive than separate
- Single DarwinIA evaluation with combined returns
- Full equity available — no capital split across accounts

---

## Bottom Line

The hedged martingale turns a **0.50x return** into a **44.3x return** on SOL alone, with DOGE to be added after unwind. The difference is entirely due to:

1. **Massive gross exposure**: 42,470 short lots already held (vs 377 lots a pure short could afford)
2. **Hedge protection**: 41,240 long lots absorb upside spikes — no margin call
3. **EA-managed unwinding**: TRIM zone automatically removes hedge above TRIM threshold
4. **Dynamic TRIM**: Scaled to gross — 66% at 84K, tighten 1% per ~10K gross reduction. PROTECT fixed at 56%
5. **Spread compensation**: 10% dead zone absorbs the 1.5% ML swings from 84K gross lots
6. **Survivability**: PROTECT zone fires balanced closes below 56% with four safeguards:
   - Hard floor (10%) — EA halts below this, broker handles stop-out
   - Never closes bias — shorts are sacred, only balanced close when hedged
   - Circuit breaker (1000 fires) — meaningful at scale
   - 15-second cooldown — spread spikes resolve before cascade
7. **PROTECT serves the strategy** — balanced close reduces margin to survive spikes and resume trimming, growing net short faster. Better than broker intervention.

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

8. **Collapsing VaR**: Nominal value shrinks → VaR shrinks → risk multiplier climbs
9. **Profit lock-in**: Once longs are unwound, VaR can only decrease — the value is locked
10. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
11. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
12. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy holds 110x more short lots than a pure short could afford. The hedge makes this possible by neutralizing directional risk while the EA systematically strips the hedge away, growing net short exposure at minimum cost until the position is pure short. The longs are not a profit source — they are a cost to remove (~$900K). The profit comes entirely from the shorts' floating P/L as net short exposure grows ($3,907,240 at $0). Bounces make trimming cheaper (longs closer to breakeven), and drops make the shorts print harder. With 41.2K longs to unwind and settings at 66/56 (set and forget — tighten only when actively monitoring or as gross drops, 15s PROTECT cooldown, 1000 max fires), the unwind targets completion by SOL ~$30-40. Once pure short, DOGE opened at max size and everything rides to $0 in the VaR compression spiral. Then flip long SOL from the bottom and ride the next cycle up.**
