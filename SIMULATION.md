# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account Equity | $94,202 |
| Account Balance | $94,292 |
| Margin Call Level | 50% |

### Current Positions

| Asset | Price | Long Lots | Short Lots | Net Short |
|-------|-------|-----------|------------|-----------|
| SOLUSD | $86.06 | 5,188 | 6,913 | 1,725 |
| DOGEUSD | $0.0957 | 0 | 379,000 | 379,000 |

---

## Scenario A: Standard Short (No Hedging)

With $94,202 equity, 1:1 crypto margin, and 100% margin level (all equity committed):

**Maximum position at open:**
- SOLUSD: 881 lots short @ $86.06 (using 80.5% allocation = $75,833)
- DOGEUSD: 191,900 lots short @ $0.0957 (using 19.5% allocation = $18,369)

**No margin buffer.** A 1% spike upward triggers margin call. Realistically, you'd need 200% margin level minimum to survive any volatility, cutting the position in half:

- SOLUSD: ~440 lots short
- DOGEUSD: ~96,000 lots short

### Profit if SOL and DOGE hit $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 440 | $86.06 | $37,866 |
| DOGEUSD | 96,000 | $0.0957 | $9,187 |
| **Total** | | | **$47,054** |

**Return: $47,054 on $94,202 = 0.50x (50% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Phase 1: $86 → $60 (30% drop with 5 bounces)

SOL doesn't drop straight. It bounces. Each bounce is a harvest cycle.

**Bounce 1: $86 → $92 → $78**
- Spike to $92: harvest 5,188 long lots × $6 = **$31,128 banked**
- Close longs, open ~5,000 new shorts at $92
- Re-open longs at $92 for next hedge
- Drop to $78: all shorts profit, new shorts from $92 profit $14 each
- Net new shorts added: ~500 (from freed margin)

**Bounce 2: $78 → $85 → $72**
- Spike to $85: harvest longs × $7 avg = **~$36,000 banked**
- Stack shorts at $85, re-hedge
- Drop to $72

**Bounce 3: $72 → $80 → $65**
- Harvest: ~$40,000 banked
- Stack more shorts at $80

**Bounce 4: $65 → $74 → $60**
- Harvest: ~$45,000 banked
- Stack more shorts at $74

**Bounce 5: $60 → $68 → $60**
- Harvest: ~$40,000 banked

**Phase 1 subtotal:**
- Harvested long profits: ~$192,000
- Balance now: $94,292 + $192,000 = **~$286,000**
- Short lots accumulated: ~8,500 (original 6,913 + ~1,587 new at higher prices)
- Average short entry lifted to ~$88 (better than original)
- Long losses taken along the way: ~$30,000
- Net harvest profit: ~$162,000

### Phase 2: $60 → $20 (continued drop with 5 bounces)

Balance is now ~$286K. Margin capacity much larger. Can run bigger positions.

**Bounces 6-10: SOL oscillating down from $60 to $20**
- Each bounce harvests $30,000-$60,000 from longs
- More shorts added at each bounce peak
- Short position grows to ~12,000 lots
- Harvested: ~$200,000
- Long losses: ~$40,000
- Net: ~$160,000

**Balance now: ~$446,000**
**Short lots: ~12,000 at ~$75 average entry**

### Phase 3: $20 → $0 (final collapse with 5 bounces)

Crypto is dying. Bounces get smaller but position is massive.

**Bounces 11-15: $20 → $0**
- Smaller dollar bounces but still harvestable
- Each cycle: $10,000-$30,000 harvested
- Short position grows to ~15,000 lots
- Harvested: ~$80,000
- Long losses: ~$20,000

**Balance before final close: ~$506,000**

### Final Close at $0

| Component | Lots | Avg Entry | Profit |
|-----------|------|-----------|--------|
| SOLUSD shorts | 15,000 | ~$75 avg | $1,125,000 |
| DOGEUSD shorts | 500,000 | ~$0.08 avg | $40,000 |
| Residual long losses | — | — | -$15,000 |
| **Total final close** | | | **$1,150,000** |

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Harvested long profits (15 cycles) | $402,000 |
| Cumulative long losses | -$90,000 |
| Final short close at $0 | $1,150,000 |
| **Total Profit** | **$1,462,000** |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $94,202 | $94,202 |
| Max short lots (SOL) | 440 | 6,913 → 15,000 |
| Max short lots (DOGE) | 96,000 | 379,000 → 500,000 |
| Survives 10% spike? | NO (margin call) | YES (hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (compounding) |
| Profits from volatility? | NO | YES ($402K harvested) |
| Profit if SOL/DOGE → $0 | **$47,054** | **$1,462,000** |
| Return multiple | **0.5x** | **15.5x** |
| Final account value | ~$141,000 | **~$1,556,000** |

---

## Key Assumptions

1. **Volatility**: 15 significant bounces (5-15%) on the way to zero — conservative for crypto
2. **Execution**: EA harvests profitable longs automatically, partial closes at 50 lots
3. **Spread cost**: ~$500-$1,000 per full harvest cycle (negligible vs profits)
4. **No black swan recovery**: SOL and DOGE do not recover permanently
5. **Margin management**: Losing longs closed when needed to maintain margin above 50%
6. **DOGE follows similar pattern**: Grows from 379K to ~500K short lots through same mechanism
7. **Position growth**: Each harvest cycle frees margin to add ~200-500 more short lots

## The Multiplier Effect Visualized

```
Standard Short:
  $94K equity → 440 SOL lots → hold → $47K profit
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $94K equity → 6,913 SOL lots (11.4x leverage via hedge)
    → Bounce 1:  harvest $31K, add shorts  →  7,400 lots
    → Bounce 2:  harvest $36K, add shorts  →  7,800 lots
    → Bounce 3:  harvest $40K, add shorts  →  8,200 lots
    → ...
    → Bounce 10: harvest $50K, add shorts  → 12,000 lots
    → ...
    → Bounce 15: harvest $25K, add shorts  → 15,000 lots
    → SOL hits $0: close all              → $1,462K profit
  [Growing position, compounding, volatility = fuel]
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

#### Phase 1: SOL $86 → $60

Current net short: 1,725 lots

| SOL Price | Nominal Value (1,725 lots) | VaR (est. 5% daily vol) | VaR % of Equity |
|-----------|---------------------------|------------------------|-----------------|
| $86 | $148,350 | $12,240 | 13.0% |
| $78 | $134,550 | $11,100 | 8.5%* |
| $72 | $124,200 | $10,247 | 5.7%* |
| $65 | $112,125 | $9,250 | 4.2%* |
| $60 | $103,500 | $8,539 | 3.0%* |

*Equity grows from harvesting, so VaR % drops even faster than the absolute number.*

**What's happening**: VaR is falling in absolute terms (lower price = lower nominal) AND as a percentage of equity (equity is growing from harvested profits). Double compression.

#### Phase 2: SOL $60 → $20

Short lots growing to ~12,000, but price is collapsing:

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $60 | 8,500 | $510,000 | $42,075 | $286,000 | 14.7% |
| $50 | 9,500 | $475,000 | $39,188 | $340,000 | 11.5% |
| $40 | 10,500 | $420,000 | $34,650 | $380,000 | 9.1% |
| $30 | 11,500 | $345,000 | $28,463 | $420,000 | 6.8% |
| $20 | 12,000 | $240,000 | $19,800 | $446,000 | 4.4% |

The position grows in lots but VaR % compresses because price is falling faster than lots are added.

#### Phase 3: SOL $20 → $0 (The Lock-In)

This is where your point hits. **Once longs are fully unwound, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $20 | 15,000 | $300,000 | $24,750 | $506,000 | 4.9% |
| $15 | 15,000 | $225,000 | $18,563 | $581,000 | 3.2% |
| $10 | 15,000 | $150,000 | $12,375 | $656,000 | 1.9% |
| $5 | 15,000 | $75,000 | $6,188 | $731,000 | 0.8% |
| $2 | 15,000 | $30,000 | $2,475 | $776,000 | 0.3% |
| $0.50 | 15,000 | $7,500 | $619 | $798,500 | 0.08% |
| $0 | 15,000 | $0 | $0 | $1,556,000 | 0.00% |

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

**Phase 1 ($86 → $60): High VaR, Multiplier ≤ 1.0**

Strategy VaR is elevated (13% → 5.7% of equity). The Darwinex risk engine **dampens** the DARWIN:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 13.0% | ~6.5% | 0.50x | DARWIN shows 50% of raw returns |
| 8.5% | ~5.5% | 0.65x | DARWIN shows 65% of raw returns |
| 5.7% | ~4.8% | 0.84x | Getting closer to 1:1 |

Returns are real but dampened on the DARWIN. DarwinIA sees a conservative risk profile.

**Phase 2 ($60 → $20): VaR Normalizing, Multiplier → 1.0**

As VaR compresses into the 3.25%–6.5% band, the risk multiplier approaches 1:1:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 6.8% | ~5.5% | 0.81x | Nearly 1:1 |
| 4.4% | ~4.5% | 1.02x | **Crossover — DARWIN amplifies** |

**Phase 3 ($20 → $0): Low VaR, Multiplier > 1.0 — AMPLIFICATION**

This is where the Darwinex system works in your favor. Strategy VaR is collapsing toward zero while the DARWIN targets 3.25%+:

| SOL Price | Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|-----------|----------------|-------------------|-----------------|--------|
| $20 | 4.9% | ~4.5% | 0.92x | Near parity |
| $15 | 3.2% | ~3.8% | 1.19x | **1.2x amplification** |
| $10 | 1.9% | ~3.5% | 1.84x | **1.8x amplification** |
| $5 | 0.8% | ~3.3% | 4.13x | **4x amplification** |
| $2 | 0.3% | ~3.25% | 10.8x | **10.8x amplification** |

**But D-Leverage caps at 9.75x for positions held > 60 minutes.** So the maximum practical multiplier is **~9.75x**.

Even capped, the DARWIN is amplifying returns by up to 9.75x in the final collapse phase. Every 1% you make on the signal account shows as ~9.75% on the DARWIN.

### The Lock-In Moment

Your key insight: **once longs are fully unwound, the value is locked.**

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
| Phase 1 profits ($86→$60) | $162,000 | ~$97,000 (dampened) |
| Phase 2 profits ($60→$20) | $160,000 | ~$144,000 (~0.9x avg) |
| Phase 3 profits ($20→$0) | $1,140,000 | ~$4,500,000+ (amplified ~4x avg) |
| DarwinIA performance fees | — | $50,000 — $200,000 |
| **Total** | **$1,462,000** | **$4,700,000 — $5,000,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $94,202 | $94,202 | $94,202 |
| Max short lots (SOL) | 440 | 6,913 → 15,000 | 6,913 → 15,000 |
| Survives 10% spike? | NO | YES | YES |
| Position grows? | NO | YES | YES |
| VaR trajectory | Flat | Compressing | Compressing → amplified returns |
| Risk multiplier | N/A | N/A | 0.5x → 9.75x |
| Signal profit | $47,054 | $1,462,000 | $1,462,000 |
| DARWIN amplified returns | N/A | N/A | $4,700,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $50,000 — $200,000 |
| Return multiple | 0.5x | 15.5x | 15.5x + fee income |

---

## Bottom Line

The hedged martingale turns a **0.5x return** into a **15.5x return** on the same thesis and starting capital. The difference is entirely due to:

1. **Hedge leverage**: Carrying 11x more gross exposure on the same equity
2. **Volatility harvesting**: Every bounce generates realized profit
3. **Compounding**: Harvested profits fund larger positions
4. **Survivability**: The hedge prevents margin calls that would kill a pure short

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

5. **Collapsing VaR**: Nominal value shrinks → VaR shrinks → risk multiplier climbs
6. **Profit lock-in**: Once longs are unwound, VaR can only decrease — the value is locked
7. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
8. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
9. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy doesn't just profit from the short. It profits from the volatility on the way down, and then the Darwinex risk engine amplifies the final collapse into outsized DARWIN returns that attract institutional capital and performance fees.**
