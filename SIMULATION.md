# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account Equity | $92,931 |
| Account Balance | $97,980 |
| Margin Level | 62.9% |
| Margin Call Level | 50% |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 64% margin level |
| TRIM lots | 20 per close (10s cooldown) |
| PROTECT threshold | 58% margin level |
| PROTECT lots | 10 per side (balanced close, no cooldown) |
| Dead zone | 58%–64% (EA does nothing) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Circuit breaker | 30 fires max before auto-disable |
| Bias protection | Never closes bias (shorts) in crisis |

### Current Positions

| Asset | Price | Long Lots | Short Lots | Net Short |
|-------|-------|-----------|------------|-----------|
| SOLUSD | ~$84.50 | 20,680 | 22,000 | 1,320 |
| DOGEUSD | $0.2127 | 0 | 402,000 | 402,000 |

---

## Scenario A: Standard Short (No Hedging)

With $92,931 equity, 1:1 crypto margin, and 100% margin level (all equity committed):

**Maximum position at open:**
- SOLUSD: 1,100 lots short @ $84.50 (using 80% allocation = $74,345)
- DOGEUSD: 87,400 lots short @ $0.2127 (using 20% allocation = $18,586)

**No margin buffer.** A 1% spike upward triggers margin call. Realistically, you'd need 200% margin level minimum to survive any volatility, cutting the position in half:

- SOLUSD: ~550 lots short
- DOGEUSD: ~43,700 lots short

### Profit if SOL and DOGE hit $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 550 | $84.50 | $46,475 |
| DOGEUSD | 43,700 | $0.2127 | $9,295 |
| **Total** | | | **$55,770** |

**Return: $55,770 on $92,931 = 0.60x (60% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Current Position Structure

The hedge is significant: 20,680 long lots vs 22,000 short lots on SOLUSD. Net short exposure is 1,320 lots, but the gross exposure creates margin requirement — which is why margin level sits at 62.9% despite having $93K equity.

The EA manages this automatically:
- **Above 64%**: TRIM — close 20 lots of hedge (BUY) every 10s, freeing margin
- **58%–64%**: Dead zone — EA does nothing, allows normal price action
- **Below 58%**: PROTECT — balanced close 10L + 10S every tick (preserves net short)
- **Below 10%**: Hard floor — EA halts entirely, broker handles stop-out
- **After 30 fires**: Circuit breaker — PROTECT auto-disables
- **No hedges left**: EA refuses to close bias — shorts are sacred

### Phase 1: $84 → $60 (29% drop with 5 bounces)

SOL doesn't drop straight. It bounces. Each bounce is a harvest cycle. The EA trims longs above 64% margin, building net short exposure.

**Bounce 1: $84 → $90 → $75**
- Spike to $90: margin improves (longs gain), EA trims longs above 64%
- ~1,000 long lots trimmed at profit during the spike
- Drop to $75: shorts profit massively, net short exposure grows
- Harvested: **~$6,000** from trimmed longs
- Net new short exposure: ~1,000 lots

**Bounce 2: $75 → $82 → $68**
- Spike to $82: EA trims more longs, ~1,500 lots closed
- Harvested: **~$10,500**
- Growing net short exposure

**Bounce 3: $68 → $76 → $62**
- Harvest: **~$12,000** from trimmed longs
- Short lots freed from long removal add to net exposure

**Bounce 4: $62 → $70 → $58**
- Harvest: **~$14,000**
- Net short growing as longs consumed

**Bounce 5: $58 → $65 → $55**
- Harvest: **~$10,000**

**Phase 1 subtotal:**
- Harvested long profits: ~$53,000
- Long lots trimmed: ~7,500 (20,680 → ~13,180)
- Net short exposure: ~8,820 lots (up from 1,320)
- Balance now: $97,980 + $53,000 = **~$151,000**
- Equity recovering as unrealized short P/L grows

### Phase 2: $60 → $20 (continued drop with 5 bounces)

Balance is now ~$151K. Long hedge is being steadily consumed by EA. Net short growing.

**Bounces 6-10: SOL oscillating down from $60 to $20**
- Each bounce: EA trims more longs during spikes above 64%
- Longs reduced from ~13,180 to ~3,000
- Net short exposure grows to ~19,000 lots
- Harvested: ~$75,000 from longs
- DOGE shorts adding ~$48,000 as DOGE follows crypto lower

**Balance now: ~$273,000**
**SOL net short: ~19,000 lots at blended entry**

### Phase 3: $20 → $0 (final collapse with 5 bounces)

Most longs are consumed. Position is nearly pure short. VaR collapsing.

**Bounces 11-15: $20 → $0**
- Remaining longs (~3,000) fully consumed
- Once longs are gone: pure short, no more hedge volatility
- Each dollar down = 22,000 × $1 = **$22,000 profit per dollar**
- Harvested from final longs: ~$9,000
- DOGE contributing ~$37,500 more

**Balance before final close: ~$319,500**

### Final Close at $0

| Component | Lots | Avg Entry | Profit |
|-----------|------|-----------|--------|
| SOLUSD shorts | 22,000 | ~$84 avg | $1,848,000 |
| DOGEUSD shorts | 402,000 | ~$0.2127 avg | $85,505 |
| Long hedge losses (consumed) | 20,680 | — | -$250,000 |
| Harvested long profits (15 cycles) | — | — | $137,000 |
| **Net Total** | | | **$1,820,505** |

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Harvested long profits (15 cycles) | $137,000 |
| Final short close at $0 | $1,933,505 |
| Long hedge losses consumed along the way | -$250,000 |
| **Total Profit** | **$1,820,505** |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $92,931 | $92,931 |
| Max short lots (SOL) | 550 | 22,000 (already held) |
| Max short lots (DOGE) | 43,700 | 402,000 (already held) |
| Survives 10% spike? | NO (margin call) | YES (20.7K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES ($137K harvested) |
| Profit if SOL/DOGE → $0 | **$55,770** | **$1,820,505** |
| Return multiple | **0.60x** | **19.6x** |
| Final account value | ~$148,701 | **~$1,913,436** |


---

## Key Assumptions

1. **Volatility**: 15 significant bounces (5-15%) on the way to zero — conservative for crypto
2. **Execution**: EA trims longs automatically (20 lots/10s above 64% margin), balanced PROTECT below 58%
3. **Spread cost**: ~$500-$1,000 per full harvest cycle (negligible vs profits)
4. **No black swan recovery**: SOL and DOGE do not recover permanently
5. **Margin management**: EA's zone-based system prevents margin call (broker stop-out at 50%)
6. **DOGE**: 402,000 short lots held without hedge — contributes ~$85,505 if DOGE → $0
7. **Position structure**: Unlike previous sim, lots are already held (20.7K long / 22K short SOL). No new lots added — EA only trims the hedge to grow net short exposure
8. **PROTECT safeguards**: Hard floor (10%), circuit breaker (30 fires), never closes bias — prevents the death spiral that destroyed the previous account

## The Multiplier Effect Visualized

```
Standard Short:
  $93K equity → 550 SOL lots → hold → $46K profit
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $93K equity → 22,000 SOL short lots (hedged with 20,680 longs)
    → Net short: 1,320 lots (nearly flat — survives any spike)
    → Bounce 1:  EA trims 1K longs  → net short:  2,320 lots
    → Bounce 2:  EA trims 1.5K longs → net short:  3,820 lots
    → Bounce 3:  EA trims 2K longs  → net short:  5,820 lots
    → ...
    → Bounce 10: longs down to 3K   → net short: 19,000 lots
    → ...
    → Bounce 15: longs fully consumed → net short: 22,000 lots (PURE SHORT)
    → SOL hits $0: close all          → $1,821K profit
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

Current net short: 1,320 lots (but growing as EA trims longs)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $84 | 1,320 | $110,880 | $9,148 | $92,931 | 9.8% |

| $78 | 3,000 | $234,000 | $19,305 | $105,000* | 18.4% |
| $72 | 5,000 | $360,000 | $29,700 | $120,000* | 24.8% |
| $65 | 7,000 | $455,000 | $37,538 | $140,000* | 26.8% |
| $60 | 8,820 | $529,200 | $43,659 | $161,000* | 27.1% |

*Equity grows from harvested longs + unrealized short P/L. VaR rises as net exposure grows, but the hedge is absorbing upside shocks.*

#### Phase 2: SOL $60 → $20

Longs being consumed rapidly, net short growing:

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $60 | 8,820 | $529,200 | $43,659 | $161,000 | 27.1% |
| $50 | 12,000 | $600,000 | $49,500 | $200,000 | 24.8% |
| $40 | 16,000 | $640,000 | $52,800 | $230,000 | 23.0% |
| $30 | 19,000 | $570,000 | $47,025 | $260,000 | 18.1% |
| $20 | 20,000 | $400,000 | $33,000 | $273,000 | 12.1% |

VaR peaks mid-phase then starts compressing as price collapse outpaces lot growth.

#### Phase 3: SOL $20 → $0 (The Lock-In)

**Once longs are fully unwound, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $20 | 22,000 | $440,000 | $36,300 | $319,500 | 11.4% |
| $15 | 22,000 | $330,000 | $27,225 | $429,500 | 6.3% |
| $10 | 22,000 | $220,000 | $18,150 | $539,500 | 3.4% |
| $5 | 22,000 | $110,000 | $9,075 | $1,649,500 | 0.6% |
| $2 | 22,000 | $44,000 | $3,630 | $1,715,500 | 0.2% |
| $0.50 | 22,000 | $11,000 | $908 | $1,749,000 | 0.05% |
| $0 | 22,000 | $0 | $0 | $1,913,436 | 0.00% |

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

**Phase 1 ($84 → $60): Moderate VaR, Multiplier ≤ 1.0**

Strategy VaR is moderate due to gross exposure (42.7K total lots). The Darwinex risk engine **dampens** the DARWIN:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 9.8% | ~6.0% | 0.61x | DARWIN shows 61% of raw returns |
| 27.1% | ~6.5% | 0.24x | Dampened during hedge unwinding |

Returns are real but dampened on the DARWIN while hedge is active.

**Phase 2 ($60 → $20): VaR Normalizing, Multiplier → 1.0**

As longs are consumed and VaR compresses:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 12.1% | ~6.0% | 0.50x | Still dampened |
| 6.3% | ~5.5% | 0.87x | Approaching parity |
| 3.4% | ~4.5% | 1.32x | **Amplification begins** |

**Phase 3 ($20 → $0): Low VaR, Multiplier > 1.0 — AMPLIFICATION**

This is where the Darwinex system works in your favor. Strategy VaR is collapsing toward zero while the DARWIN targets 3.25%+:

| SOL Price | Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|-----------|----------------|-------------------|-----------------|--------|
| $10 | 3.4% | ~4.5% | 1.32x | Mild amplification |
| $5 | 0.6% | ~3.3% | 5.5x | **5.5x amplification** |
| $2 | 0.2% | ~3.25% | 16.3x | **Capped at 9.75x** |
| $0.50 | 0.05% | ~3.25% | 65x | **Capped at 9.75x** |

**D-Leverage caps at 9.75x for positions held > 60 minutes.** So the maximum practical multiplier is **~9.75x**.

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
| Phase 1 profits ($84→$60) | $53,000 | ~$13,000 (dampened) |
| Phase 2 profits ($60→$20) | $75,000 | ~$37,500 (~0.5x avg) |
| Phase 3 profits ($20→$0) | $1,692,505 | ~$6,770,000+ (amplified ~4x avg) |
| DarwinIA performance fees | — | $100,000 — $500,000 |
| **Total** | **$1,820,505** | **$6,770,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $92,931 | $92,931 | $92,931 |
| Max short lots (SOL) | 550 | 22,000 (held now) | 22,000 (held now) |
| Survives 10% spike? | NO | YES (20.7K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | High → compressing | High → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.24x → 9.75x |
| Signal profit | $55,770 | $1,820,505 | $1,820,505 |
| DARWIN amplified returns | N/A | N/A | $6,770,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $100,000 — $500,000 |
| Return multiple | 0.60x | **19.6x** | 19.6x + fee income |

---

## Post-Mortem: The 57% PROTECT Disaster (2026-03-02)

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

Three safeguards were added to prevent this from ever happening again:

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

**Safeguard 3 — Circuit Breaker (30 fires max)**
```
After 30 PROTECT fires, it auto-disables.
"PROTECT CIRCUIT BREAKER — 30 fires reached. Disabled until manual reset."
```
This prevents the death spiral of consuming all positions overnight. At 10 lots per side per fire, 30 fires = 300 lots max from each side — a controlled reduction, not a total liquidation. The counter resets when MG mode is toggled.

### With These Safeguards, What Would Have Happened

If the three safeguards had been active during the 03:12 crash:

1. **03:12:20**: Margin hits 7.5% → **PROTECT HALTED** (below 10% floor). Zero additional closes.
2. All 65K+ short lots would still be intact.
3. The broker might stop-out a few positions, but the EA wouldn't pile on.
4. When the spread spike resolved, margin would have recovered (as it did — jumping to 182% after the broker's own liquidations).
5. The user's manual re-hedge at 03:19 would have worked — the EA wouldn't fight it.

**Estimated equity preserved: ~$50,000+ (vs the $26,883 that survived)**

### Lessons Learned

1. **PROTECT threshold must be well below the operating margin range.** At 57% with margin hovering at 62-64%, PROTECT fired on every spread dip. The new threshold of 58% with TRIM at 64% gives a 6% dead zone.

2. **Balanced close works but slowly consumes positions.** Over hours of repeated firing, both sides shrink. The circuit breaker (30 fires) caps this consumption.

3. **The EA must never fight the user.** When the user manually opens positions to save the account, the EA must not immediately close them. The hard floor and circuit breaker prevent this — once tripped, PROTECT stays disabled until manual reset.

4. **Spread spikes are temporary — intervention is permanent.** The spread normalized within seconds, but PROTECT's damage was irreversible. The dead zone exists specifically to let temporary spikes pass without triggering emergency action.

---

## Bottom Line

The hedged martingale turns a **0.60x return** into a **19.6x return** on the same thesis and starting capital. The difference is entirely due to:

1. **Large gross exposure**: 22,000 short lots already held (vs 550 lots a pure short could afford)
2. **Hedge protection**: 20,680 long lots absorb upside spikes — no margin call
3. **EA-managed unwinding**: TRIM zone automatically removes hedge on bounces above 64% margin
4. **Survivability**: PROTECT zone fires balanced closes below 58% with three safeguards:
   - Hard floor (10%) — EA halts below this, broker handles stop-out
   - Never closes bias — shorts are sacred, only balanced close when hedged
   - Circuit breaker (30 fires) — prevents death spiral

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

5. **Collapsing VaR**: Nominal value shrinks → VaR shrinks → risk multiplier climbs
6. **Profit lock-in**: Once longs are unwound, VaR can only decrease — the value is locked
7. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
8. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
9. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy doesn't just profit from the short — it holds 40x more short lots than a pure short could afford. The hedge makes this possible by neutralizing directional risk while the EA systematically strips the hedge away on every bounce, growing net short exposure until the position is pure profit.**
