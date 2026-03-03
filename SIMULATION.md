# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account Equity | $81,000 |
| Account Balance | $88,090 |
| Margin Level | 57.1% |
| Margin Call Level | 50% |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 61% margin level |
| TRIM lots | 20 per close (10s cooldown) |
| PROTECT threshold | 56% margin level |
| PROTECT lots | 10 per side (balanced close, no cooldown) |
| Dead zone | 56%–61% (EA does nothing) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Circuit breaker | 30 fires max before auto-disable |
| Bias protection | Never closes bias (shorts) in crisis |

### Current Positions

| Asset | Price | Long Lots | Short Lots | Net Short |
|-------|-------|-----------|------------|-----------|
| SOLUSD | ~$84 | 8,720 | 10,000 | 1,280 |
| DOGEUSD | ~$0.097 | 0 | 384,000 | 384,000 |

**Note on DOGE:** The DOGE short is actively managed — profits are taken when it makes sense to add to balance, then redeployed if conditions warrant. The 384K figure is the current snapshot, not a fixed hold-to-zero position.

---

## Scenario A: Standard Short (No Hedging)

With $81,000 equity, 1:1 crypto margin, and 100% margin level (all equity committed):

**Maximum position at open:**
- SOLUSD: 771 lots short @ $84 (using 80% allocation = $64,800)
- DOGEUSD: 167,010 lots short @ $0.097 (using 20% allocation = $16,200)

**No margin buffer.** A 1% spike upward triggers margin call. Realistically, you'd need 200% margin level minimum to survive any volatility, cutting the position in half:

- SOLUSD: ~386 lots short
- DOGEUSD: ~83,505 lots short

### Profit if SOL and DOGE hit $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 386 | $84 | $32,424 |
| DOGEUSD | 83,505 | $0.097 | $8,100 |
| **Total** | | | **$40,524** |

**Return: $40,524 on $81,000 = 0.50x (50% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Current Position Structure

The hedge is significant: 8,720 long lots vs 10,000 short lots on SOLUSD. Net short exposure is 1,280 lots, but the gross exposure creates margin requirement — which is why margin level sits at 57.1% despite having $81K equity.

The EA manages this automatically:
- **Above 61%**: TRIM — close 20 lots of hedge (BUY) every 10s, freeing margin
- **56%–61%**: Dead zone — EA does nothing, allows normal price action
- **Below 56%**: PROTECT — balanced close 10L + 10S every tick (preserves net short)
- **Below 10%**: Hard floor — EA halts entirely, broker handles stop-out
- **After 30 fires**: Circuit breaker — PROTECT auto-disables
- **No hedges left**: EA refuses to close bias — shorts are sacred

### Why Tighter Settings Work Now

With a less intense martingale (8,720 longs vs 18K+ in earlier snapshots), the gross exposure is smaller and margin moves are less extreme. This allows tighter thresholds:
- **TRIM at 61%** (was 63%) — starts trimming sooner, faster unwind
- **PROTECT at 56%** (was 58%) — leaves 6% buffer above 50% margin call, closest comfortable level
- **Dead zone still 5%** — same width, just shifted down
- **Fewer longs = fewer bounces** — unwind completes in ~7 bounces across 2 phases

### Phase 1: $84 → $40 (52% drop with 4 bounces)

SOL doesn't drop straight. It bounces. Each bounce is a harvest cycle. The EA trims longs above 61% margin, building net short exposure.

**Bounce 1: $84 → $90 → $72**
- Spike to $90: margin improves (longs gain), EA trims longs above 61%
- ~1,500 long lots trimmed at profit during the spike
- Drop to $72: shorts profit massively, net short exposure grows
- Harvested: **~$9,000** from trimmed longs

**Bounce 2: $72 → $80 → $58**
- Spike to $80: EA trims more longs, ~2,500 lots closed
- Harvested: **~$12,500**

**Bounce 3: $58 → $66 → $48**
- Harvest: **~$10,000** from trimmed longs

**Bounce 4: $48 → $55 → $40**
- Harvest: **~$6,000**
- Most longs consumed

**Phase 1 subtotal:**
- Harvested long profits: ~$37,500
- Long lots trimmed: ~8,000 (8,720 → ~720)
- Net short exposure: ~9,280 lots (up from 1,280)
- Balance now: $88,090 + $37,500 + DOGE trading profits = **~$135,000+**
- Equity recovering as unrealized short P/L grows

### Phase 2: $40 → $0 (final collapse with 3 bounces)

Remaining ~720 longs consumed. Position becomes pure short. VaR collapsing.

**Bounce 5: $40 → $46 → $25**
- Final longs (~720) fully consumed during spike
- Harvested: **~$3,000**
- Once longs gone: pure short, no more hedge volatility

**Bounces 6-7: $25 → $10 → $0**
- Pure short — each dollar down = 10,000 × $1 = **$10,000 profit per dollar**
- DOGE contributing additional profit if still deployed

**Balance before final close: ~$170,000**

### Final Close at $0

| Component | Lots | Avg Entry | Profit |
|-----------|------|-----------|--------|
| SOLUSD shorts | 10,000 | ~$84 avg | $840,000 |
| DOGEUSD shorts | 384,000 | ~$0.097 avg | $37,248 |
| Long hedge losses (consumed) | 8,720 | — | -$106,000 |
| Harvested long profits (7 cycles) | — | — | $49,000 |
| **Net Total** | | | **$820,248** |

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Harvested long profits (7 cycles) | $49,000 |
| Final short close at $0 | $877,248 |
| Long hedge losses consumed along the way | -$106,000 |
| **Total Profit** | **$820,248** |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $81,000 | $81,000 |
| Max short lots (SOL) | 386 | 10,000 (already held) |
| Max short lots (DOGE) | 83,505 | 384,000 (already held) |
| Survives 10% spike? | NO (margin call) | YES (8.7K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES ($49K harvested) |
| Profit if SOL/DOGE → $0 | **$40,524** | **$820,248** |
| Return multiple | **0.50x** | **10.1x** |
| Final account value | ~$121,524 | **~$901,248** |


---

## Key Assumptions

1. **Volatility**: 7 significant bounces (5-15%) on the way to zero — conservative for crypto
2. **Execution**: EA trims longs automatically (20 lots/10s above 61% margin), balanced PROTECT below 56%
3. **Spread cost**: ~$500-$1,000 per full harvest cycle (negligible vs profits)
4. **No black swan recovery**: SOL and DOGE do not recover permanently
5. **Margin management**: EA's zone-based system prevents margin call (broker stop-out at 50%, PROTECT at 56% leaves 6% buffer)
6. **DOGE**: 384,000 short lots actively managed — profits taken and redeployed as conditions warrant, contributing to balance growth throughout
7. **Position structure**: Lots already held (8.7K long / 10K short SOL, 384K short DOGE). No new lots added — EA only trims the hedge to grow net short exposure
8. **PROTECT safeguards**: Hard floor (10%), circuit breaker (30 fires), never closes bias — prevents the death spiral that destroyed the previous account

## The Multiplier Effect Visualized

```
Standard Short:
  $81K equity → 386 SOL lots → hold → $41K profit
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $81K equity → 10,000 SOL short lots (hedged with 8,720 longs)
    → Net short: 1,280 lots (nearly flat — survives any spike)
    → Bounce 1:  EA trims 1.5K longs → net short:  2,780 lots
    → Bounce 2:  EA trims 2.5K longs → net short:  5,280 lots
    → Bounce 3:  EA trims 2.5K longs → net short:  7,780 lots
    → Bounce 4:  EA trims 1.5K longs → net short:  9,280 lots
    → Bounce 5:  final longs consumed → net short: 10,000 lots (PURE SHORT)
    → SOL hits $0: close all          → $820K profit
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

#### Phase 1: SOL $84 → $40

Current net short: 1,280 lots (but growing as EA trims longs)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $84 | 1,280 | $107,520 | $8,870 | $81,000 | 10.9% |
| $72 | 3,000 | $216,000 | $17,820 | $93,000* | 19.2% |
| $58 | 5,500 | $319,000 | $26,318 | $107,000* | 24.6% |
| $48 | 7,800 | $374,400 | $30,888 | $120,000* | 25.7% |
| $40 | 9,300 | $372,000 | $30,690 | $140,000* | 21.9% |

*Equity grows from harvested longs + unrealized short P/L. VaR rises as net exposure grows, but the hedge is absorbing upside shocks.*

#### Phase 2: SOL $40 → $0 (The Lock-In)

**Once longs are fully unwound, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $40 | 10,000 | $400,000 | $33,000 | $160,000 | 20.6% |
| $30 | 10,000 | $300,000 | $24,750 | $280,000 | 8.8% |
| $20 | 10,000 | $200,000 | $16,500 | $430,000 | 3.8% |
| $10 | 10,000 | $100,000 | $8,250 | $650,000 | 1.3% |
| $5 | 10,000 | $50,000 | $4,125 | $800,000 | 0.5% |
| $2 | 10,000 | $20,000 | $1,650 | $870,000 | 0.2% |
| $0 | 10,000 | $0 | $0 | $901,000 | 0.00% |

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

**Phase 1 ($84 → $40): Moderate VaR, Multiplier ≤ 1.0**

Strategy VaR is moderate due to gross exposure (19K total lots). The Darwinex risk engine **dampens** the DARWIN:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 10.9% | ~6.0% | 0.55x | DARWIN shows 55% of raw returns |
| 25.7% | ~6.5% | 0.25x | Dampened during hedge unwinding |

Returns are real but dampened on the DARWIN while hedge is active.

**Phase 2 ($40 → $0): VaR Compressing → AMPLIFICATION**

As longs are consumed and VaR compresses, the Darwinex system works in your favor:

| SOL Price | Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|-----------|----------------|-------------------|-----------------|--------|
| $30 | 8.8% | ~6.0% | 0.68x | Still dampened |
| $20 | 3.8% | ~5.0% | 1.32x | **Parity reached** |
| $10 | 1.3% | ~4.0% | 3.08x | **3.1x amplification** |
| $5 | 0.5% | ~3.3% | 6.6x | **6.6x amplification** |
| $2 | 0.2% | ~3.25% | 16.3x | **Capped at 9.75x** |

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
| Phase 1 profits ($84→$40) | $37,500 | ~$9,400 (dampened) |
| Phase 2 profits ($40→$0) | $782,748 | ~$3,130,000+ (amplified ~4x avg) |
| DarwinIA performance fees | — | $100,000 — $500,000 |
| **Total** | **$820,248** | **$3,130,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $81,000 | $81,000 | $81,000 |
| Max short lots (SOL) | 386 | 10,000 (held now) | 10,000 (held now) |
| Survives 10% spike? | NO | YES (8.7K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | High → compressing | High → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.25x → 9.75x |
| Signal profit | $40,524 | $820,248 | $820,248 |
| DARWIN amplified returns | N/A | N/A | $3,130,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $100,000 — $500,000 |
| Return multiple | 0.50x | **10.1x** | 10.1x + fee income |

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

1. **PROTECT threshold must be well below the operating margin range.** At 57% with margin hovering at 62-64%, PROTECT fired on every spread dip. The new threshold of 56% with TRIM at 61% gives a 5% dead zone while leaving 6% buffer above the 50% margin call.

2. **Balanced close works but slowly consumes positions.** Over hours of repeated firing, both sides shrink. The circuit breaker (30 fires) caps this consumption.

3. **The EA must never fight the user.** When the user manually opens positions to save the account, the EA must not immediately close them. The hard floor and circuit breaker prevent this — once tripped, PROTECT stays disabled until manual reset.

4. **Spread spikes are temporary — intervention is permanent.** The spread normalized within seconds, but PROTECT's damage was irreversible. The dead zone exists specifically to let temporary spikes pass without triggering emergency action.

---

## Bottom Line

The hedged martingale turns a **0.50x return** into a **10.1x return** on the same thesis and starting capital. The difference is entirely due to:

1. **Large gross exposure**: 10,000 short lots already held (vs 386 lots a pure short could afford)
2. **Hedge protection**: 8,720 long lots absorb upside spikes — no margin call
3. **EA-managed unwinding**: TRIM zone automatically removes hedge on bounces above 61% margin
4. **Survivability**: PROTECT zone fires balanced closes below 56% with three safeguards:
   - Hard floor (10%) — EA halts below this, broker handles stop-out
   - Never closes bias — shorts are sacred, only balanced close when hedged
   - Circuit breaker (30 fires) — prevents death spiral

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

5. **Collapsing VaR**: Nominal value shrinks → VaR shrinks → risk multiplier climbs
6. **Profit lock-in**: Once longs are unwound, VaR can only decrease — the value is locked
7. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
8. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
9. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy doesn't just profit from the short — it holds 26x more short lots than a pure short could afford. The hedge makes this possible by neutralizing directional risk while the EA systematically strips the hedge away on every bounce, growing net short exposure until the position is pure profit. With fewer longs to unwind (8.7K) and tighter settings (61/56), the path to pure short is fast — 7 bounces across 2 phases. DOGE contributes additional balance growth through active profit-taking and redeployment.**
