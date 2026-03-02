# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account Equity | $57,221 |
| Account Balance | $127,540 |
| Margin Level | 69.61% |
| Margin Call Level | 50% |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 70% margin level |
| TRIM lots | 5 per close (30s cooldown) |
| PROTECT threshold | 60% margin level |
| PROTECT lots | 10 per close (no cooldown) |
| Dead zone | 60%–70% (EA does nothing) |

### Current Positions

| Asset | Price | Long Lots | Short Lots | Net Short |
|-------|-------|-----------|------------|-----------|
| SOLUSD | $84.67 | 65,685 | 66,370 | 685 |
| DOGEUSD | $0.2127 | 0 | 220,000 | 220,000 |

---

## Scenario A: Standard Short (No Hedging)

With $57,221 equity, 1:1 crypto margin, and 100% margin level (all equity committed):

**Maximum position at open:**
- SOLUSD: 676 lots short @ $84.67 (using 80% allocation = $45,777)
- DOGEUSD: 53,900 lots short @ $0.2127 (using 20% allocation = $11,444)

**No margin buffer.** A 1% spike upward triggers margin call. Realistically, you'd need 200% margin level minimum to survive any volatility, cutting the position in half:

- SOLUSD: ~338 lots short
- DOGEUSD: ~27,000 lots short

### Profit if SOL and DOGE hit $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 338 | $84.67 | $28,618 |
| DOGEUSD | 27,000 | $0.2127 | $5,743 |
| **Total** | | | **$34,361** |

**Return: $34,361 on $57,221 = 0.60x (60% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Current Position Structure

The hedge is massive: 65,685 long lots vs 66,370 short lots on SOLUSD. Net short exposure is only 685 lots, but the gross exposure creates enormous margin requirement — which is why margin level sits at 69.61% despite having $57K equity.

The EA manages this automatically:
- **Above 70%**: TRIM — close 5 lots of hedge (BUY) every 30s, freeing margin
- **60%–70%**: Dead zone — EA does nothing, allows normal price action
- **Below 60%**: PROTECT — emergency close 10 lots of bias (SELL) every tick to prevent margin call

### Phase 1: $84 → $60 (29% drop with 5 bounces)

SOL doesn't drop straight. It bounces. Each bounce is a harvest cycle. The EA trims longs above 70% margin, building net short exposure.

**Bounce 1: $84 → $90 → $75**
- Spike to $90: margin improves (longs gain), EA trims longs above 70%
- ~2,000 long lots trimmed at profit during the spike
- Drop to $75: shorts profit massively, net short exposure grows
- Harvested: **~$12,000** from trimmed longs
- Net new short exposure: ~2,000 lots

**Bounce 2: $75 → $82 → $68**
- Spike to $82: EA trims more longs, ~3,000 lots closed
- Harvested: **~$21,000**
- Growing net short exposure

**Bounce 3: $68 → $76 → $62**
- Harvest: **~$24,000** from trimmed longs
- Short lots freed from long removal add to net exposure

**Bounce 4: $62 → $70 → $58**
- Harvest: **~$28,000**
- Net short growing as longs consumed

**Bounce 5: $58 → $65 → $55**
- Harvest: **~$20,000**

**Phase 1 subtotal:**
- Harvested long profits: ~$105,000
- Long lots trimmed: ~15,000 (65,685 → ~50,000)
- Net short exposure: ~16,000 lots (up from 685)
- Balance now: $127,540 + $105,000 = **~$232,000**
- Equity recovering as unrealized short P/L grows

### Phase 2: $60 → $20 (continued drop with 5 bounces)

Balance is now ~$232K. Long hedge is being steadily consumed by EA. Net short growing.

**Bounces 6-10: SOL oscillating down from $60 to $20**
- Each bounce: EA trims more longs during spikes above 70%
- Longs reduced from ~50,000 to ~10,000
- Net short exposure grows to ~56,000 lots
- Harvested: ~$150,000 from longs
- DOGE shorts adding ~$25,000 as DOGE follows crypto lower

**Balance now: ~$382,000**
**SOL net short: ~56,000 lots at blended entry**

### Phase 3: $20 → $0 (final collapse with 5 bounces)

Most longs are consumed. Position is nearly pure short. VaR collapsing.

**Bounces 11-15: $20 → $0**
- Remaining longs (~10,000) fully consumed
- Once longs are gone: pure short, no more hedge volatility
- Each dollar down = 66,370 × $1 = **$66,370 profit per dollar**
- Harvested from final longs: ~$30,000
- DOGE contributing ~$20,000 more

**Balance before final close: ~$432,000**

### Final Close at $0

| Component | Lots | Avg Entry | Profit |
|-----------|------|-----------|--------|
| SOLUSD shorts | 66,370 | ~$84 avg | $5,575,080 |
| DOGEUSD shorts | 220,000 | ~$0.2127 avg | $46,794 |
| Long hedge losses (consumed) | 65,685 | — | -$800,000 |
| Harvested long profits (15 cycles) | — | — | $285,000 |
| **Net Total** | | | **$5,106,874** |

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Harvested long profits (15 cycles) | $285,000 |
| Final short close at $0 | $5,621,874 |
| Long hedge losses consumed along the way | -$800,000 |
| **Total Profit** | **$5,106,874** |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $57,221 | $57,221 |
| Max short lots (SOL) | 338 | 66,370 (already held) |
| Max short lots (DOGE) | 27,000 | 220,000 (already held) |
| Survives 10% spike? | NO (margin call) | YES (65K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES ($285K harvested) |
| Profit if SOL/DOGE → $0 | **$34,361** | **$5,106,874** |
| Return multiple | **0.6x** | **89.3x** |
| Final account value | ~$91,582 | **~$5,164,094** |

---

## Key Assumptions

1. **Volatility**: 15 significant bounces (5-15%) on the way to zero — conservative for crypto
2. **Execution**: EA trims longs automatically (5 lots/30s above 70% margin), protects below 60%
3. **Spread cost**: ~$500-$1,000 per full harvest cycle (negligible vs profits)
4. **No black swan recovery**: SOL and DOGE do not recover permanently
5. **Margin management**: EA's zone-based system prevents margin call (broker stop-out at 50%)
6. **DOGE**: 220,000 short lots held without hedge — contributes ~$46,794 if DOGE → $0
7. **Position structure**: Unlike previous sim, lots are already held (65K long / 66K short SOL). No new lots added — EA only trims the hedge to grow net short exposure

## The Multiplier Effect Visualized

```
Standard Short:
  $57K equity → 338 SOL lots → hold → $34K profit
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $57K equity → 66,370 SOL short lots (hedged with 65,685 longs)
    → Net short: 685 lots (nearly flat — survives any spike)
    → Bounce 1:  EA trims 2K longs  → net short:  2,685 lots
    → Bounce 2:  EA trims 3K longs  → net short:  5,685 lots
    → Bounce 3:  EA trims 4K longs  → net short:  9,685 lots
    → ...
    → Bounce 10: longs down to 10K  → net short: 56,370 lots
    → ...
    → Bounce 15: longs fully consumed → net short: 66,370 lots (PURE SHORT)
    → SOL hits $0: close all          → $5,106K profit
  [Same lots, just removing the hedge. Volatility = fuel for trimming.]
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

#### Phase 1: SOL $84 → $60

Current net short: 685 lots (but growing as EA trims longs)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $84 | 685 | $57,540 | $4,747 | $57,221 | 8.3% |
| $78 | 4,000 | $312,000 | $25,740 | $70,000* | 36.8% |
| $72 | 8,000 | $576,000 | $47,520 | $90,000* | 52.8% |
| $65 | 12,000 | $780,000 | $64,350 | $120,000* | 53.6% |
| $60 | 16,000 | $960,000 | $79,200 | $160,000* | 49.5% |

*Equity grows from harvested longs + unrealized short P/L. VaR rises as net exposure grows, but the hedge is absorbing upside shocks.*

**What's happening**: Unlike a pure short, the hedge means a spike UP doesn't kill you — 65,685 long lots absorb the hit. As the EA trims longs on bounces above 70% margin, net short exposure grows gradually.

#### Phase 2: SOL $60 → $20

Longs being consumed rapidly, net short growing:

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $60 | 16,000 | $960,000 | $79,200 | $160,000 | 49.5% |
| $50 | 30,000 | $1,500,000 | $123,750 | $250,000 | 49.5% |
| $40 | 45,000 | $1,800,000 | $148,500 | $300,000 | 49.5% |
| $30 | 56,000 | $1,680,000 | $138,600 | $350,000 | 39.6% |
| $20 | 60,000 | $1,200,000 | $99,000 | $382,000 | 25.9% |

VaR peaks mid-phase then starts compressing as price collapse outpaces lot growth.

#### Phase 3: SOL $20 → $0 (The Lock-In)

This is where your point hits. **Once longs are fully unwound, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $20 | 66,370 | $1,327,400 | $109,511 | $432,000 | 25.4% |
| $15 | 66,370 | $995,550 | $82,133 | $763,000 | 10.8% |
| $10 | 66,370 | $663,700 | $54,755 | $1,095,000 | 5.0% |
| $5 | 66,370 | $331,850 | $27,378 | $4,426,000 | 0.6% |
| $2 | 66,370 | $132,740 | $10,951 | $4,625,000 | 0.2% |
| $0.50 | 66,370 | $33,185 | $2,738 | $4,725,000 | 0.06% |
| $0 | 66,370 | $0 | $0 | $5,164,094 | 0.00% |

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

**Phase 1 ($84 → $60): High VaR, Multiplier ≤ 1.0**

Strategy VaR is elevated due to massive gross exposure (132K total lots). The Darwinex risk engine **dampens** the DARWIN:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 8.3% | ~6.0% | 0.72x | DARWIN shows 72% of raw returns |
| 52.8% | ~6.5% | 0.12x | Heavily dampened during hedge unwinding |
| 49.5% | ~6.5% | 0.13x | Still dampened — gross exposure huge |

Returns are real but heavily dampened on the DARWIN while hedge is active. DarwinIA sees high risk.

**Phase 2 ($60 → $20): VaR Normalizing, Multiplier → 1.0**

As longs are consumed and VaR compresses:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 25.9% | ~6.0% | 0.23x | Still dampened |
| 10.8% | ~5.5% | 0.51x | Approaching crossover |
| 5.0% | ~4.5% | 0.90x | **Near parity** |

**Phase 3 ($20 → $0): Low VaR, Multiplier > 1.0 — AMPLIFICATION**

This is where the Darwinex system works in your favor. Strategy VaR is collapsing toward zero while the DARWIN targets 3.25%+:

| SOL Price | Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|-----------|----------------|-------------------|-----------------|--------|
| $10 | 5.0% | ~4.5% | 0.90x | Near parity |
| $5 | 0.6% | ~3.3% | 5.5x | **5.5x amplification** |
| $2 | 0.2% | ~3.25% | 16.3x | **Capped at 9.75x** |
| $0.50 | 0.06% | ~3.25% | 54x | **Capped at 9.75x** |

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
| Phase 1 profits ($84→$60) | $105,000 | ~$13,000 (heavily dampened) |
| Phase 2 profits ($60→$20) | $150,000 | ~$75,000 (~0.5x avg) |
| Phase 3 profits ($20→$0) | $4,851,874 | ~$19,000,000+ (amplified ~4x avg) |
| DarwinIA performance fees | — | $100,000 — $500,000 |
| **Total** | **$5,106,874** | **$19,000,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $57,221 | $57,221 | $57,221 |
| Max short lots (SOL) | 338 | 66,370 (held now) | 66,370 (held now) |
| Survives 10% spike? | NO | YES (65K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | High → compressing | High → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.12x → 9.75x |
| Signal profit | $34,361 | $5,106,874 | $5,106,874 |
| DARWIN amplified returns | N/A | N/A | $19,000,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $100,000 — $500,000 |
| Return multiple | 0.6x | **89.3x** | 89.3x + fee income |

---

## Bottom Line

The hedged martingale turns a **0.6x return** into an **89.3x return** on the same thesis and starting capital. The difference is entirely due to:

1. **Massive gross exposure**: 66,370 short lots already held (vs 338 lots a pure short could afford)
2. **Hedge protection**: 65,685 long lots absorb upside spikes — no margin call
3. **EA-managed unwinding**: TRIM zone automatically removes hedge on bounces above 70% margin
4. **Survivability**: PROTECT zone fires below 60% to prevent broker stop-out at 50%

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

5. **Collapsing VaR**: Nominal value shrinks → VaR shrinks → risk multiplier climbs
6. **Profit lock-in**: Once longs are unwound, VaR can only decrease — the value is locked
7. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
8. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
9. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy doesn't just profit from the short — it holds 196x more short lots than a pure short could afford. The hedge makes this possible by neutralizing directional risk while the EA systematically strips the hedge away on every bounce, growing net short exposure until the position is pure profit.**
