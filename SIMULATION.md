# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account Equity | $59,432 |
| Account Balance | $84,803 |
| Margin Level | 59.0% |
| Margin Call Level | 50% |

### EA Configuration

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 61% margin level |
| TRIM lots | 20 per close (10s cooldown) |
| PROTECT threshold | 55% margin level |
| PROTECT lots | 10 per side (balanced close) |
| PROTECT cooldown | 5 seconds between fires |
| Dead zone | 55%–61% (EA does nothing) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Circuit breaker | 69 fires max before auto-disable |
| Bias protection | Never closes bias (shorts) in crisis |

### Why 61/55 (6% Dead Zone)

With 89K gross lots, spread changes cause **~1.5% ML swings** tick-to-tick. The 6% dead zone provides safety after two cascade incidents:
- Normal spread fluctuation never accidentally triggers PROTECT
- PROTECT deactivation midpoint at 58% — 3% hysteresis prevents oscillation
- PROTECT at 55% leaves 5% buffer above 50% margin call
- 5-second cooldown prevents cascade at scale — 69 fires takes minimum 5.75 minutes
- At 89K gross, 10 lots/side balanced close is 0.022% of gross — needs time to recover
- TRIM at 61% prevents trimming underwater longs from pushing ML toward PROTECT

### Current Positions

| Asset | Price | Long Lots | Short Lots | Net Short |
|-------|-------|-----------|------------|-----------|
| SOLUSD | ~$87 | 43,940 | 45,100 | 1,160 |
| DOGEUSD | — | 0 | 0 | 0 |

**Note on DOGE:** Closed during SOL hedge unwind to reduce complexity. Once SOL longs are fully unwound and position is pure short, DOGE shorts will be reopened at maximum size and everything rides to $0.

### Balance vs Equity Gap

Balance ($85K) exceeds equity ($59K) by ~$26K — this is the unrealized cost of the hedge (spread paid on 89K lots + unrealized P/L). This gap closes as:
1. Longs are trimmed (realized gains go to balance)
2. SOL price drops (shorts profit, equity rises toward balance)
3. Once fully unwound, equity ≈ balance and both grow together

---

## Scenario A: Standard Short (No Hedging)

With $59,432 equity, 1:1 crypto margin, and 100% margin level (all equity committed):

**Maximum position at open:**
- SOLUSD: 683 lots short @ $87 (using 100% allocation = $59,432)

**No margin buffer.** A 1% spike upward triggers margin call. Realistically, you'd need 200% margin level minimum to survive any volatility, cutting the position in half:

- SOLUSD: ~342 lots short

### Profit if SOL hits $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 342 | $87 | $29,754 |

**Return: $29,754 on $59,432 = 0.50x (50% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Current Position Structure

The hedge is massive: 43,940 long lots vs 45,100 short lots on SOLUSD. Net short exposure is only 1,160 lots, but the gross exposure (89,040 lots) creates significant margin requirement.

The EA manages this automatically:
- **Above 61%**: TRIM — close 20 lots of hedge (BUY) every 10s, freeing margin
- **55%–61%**: Dead zone — EA does nothing, allows normal price action
- **Below 55%**: PROTECT — balanced close 10L + 10S (5s cooldown between fires)
- **Below 10%**: Hard floor — EA halts entirely, broker handles stop-out
- **After 69 fires**: Circuit breaker — PROTECT auto-disables
- **No hedges left**: EA refuses to close bias — shorts are sacred

### Dynamic TRIM Strategy

TRIM can be adjusted based on market conditions while PROTECT stays fixed at 55%:

| Market Condition | TRIM | Dead Zone | Rationale |
|------------------|------|-----------|-----------|
| Fast drop (ML rising) | 57–58% | 2–3% | ML rising, PROTECT risk near zero, max trim speed |
| Normal trend | 59–60% | 4–5% | Consistent trimming with bounce buffer |
| **Current setting** | **61%** | **6%** | Post-cascade safety, prevents trim-induced ML drops |
| Sharp bounce underway | 63–65% | 8–10% | Maximum protection during adverse moves |

### Phase 1: $87 → $35 (5 bounces)

SOL doesn't drop straight. It bounces. Each bounce is a harvest cycle. The EA trims longs above 61% margin, building net short exposure.

**Bounce 1: $87 → $92 → $72**
- Spike to $92: margin improves (longs gain), EA trims longs above 61%
- ~6,000 long lots trimmed at profit during the spike
- Drop to $72: shorts profit massively, net short exposure grows
- Harvested: **~$30,000** from trimmed longs

**Bounce 2: $72 → $80 → $58**
- Spike to $80: EA trims more longs, ~8,000 lots closed
- Harvested: **~$40,000**

**Bounce 3: $58 → $66 → $48**
- Harvest: **~$32,000** from trimmed longs

**Bounce 4: $48 → $55 → $40**
- Harvest: **~$22,000**

**Bounce 5: $40 → $46 → $35**
- Harvest: **~$16,000**
- Most longs consumed

**Phase 1 subtotal:**
- Harvested long profits: ~$140,000
- Long lots trimmed: ~41,000 (43,940 → ~3,000)
- Net short exposure: ~42,100 lots (up from 1,160)
- Balance growing with each harvested close

### Phase 2: $35 → $0 (final collapse with 3 bounces)

Remaining ~3,000 longs consumed. Position becomes pure short. VaR collapsing.

**Bounce 6: $35 → $40 → $20**
- Final longs (~3,000) fully consumed during spike
- Harvested: **~$6,000**
- Once longs gone: pure short, no more hedge volatility

**Bounces 7-8: $20 → $5 → $0**
- Pure short — each dollar down = 45,100 × $1 = **$45,100 profit per dollar**
- DOGE reopened at max size for additional profit

### Final Close at $0

| Component | Lots | Avg Entry | Profit |
|-----------|------|-----------|--------|
| SOLUSD shorts | 45,100 | ~$87 avg | $3,923,700 |
| Long hedge losses (consumed) | 43,940 | — | -$527,000 |
| Harvested long profits (8 cycles) | — | — | $146,000 |
| DOGE (reopened after unwind) | TBD | — | TBD |
| **SOL Net Total** | | | **$3,542,700** |

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Harvested long profits (8 cycles) | $146,000 |
| Final short close at $0 | $3,923,700 |
| Long hedge losses consumed along the way | -$527,000 |
| **SOL Total Profit** | **$3,542,700** |
| DOGE (reopened after unwind) | TBD |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $59,432 | $59,432 |
| Max short lots (SOL) | 342 | 45,100 (already held) |
| Survives 10% spike? | NO (margin call) | YES (44K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES ($146K harvested) |
| SOL profit if → $0 | **$29,754** | **$3,542,700** |
| Return multiple | **0.50x** | **59.6x** |
| Final account value | ~$89,186 | **~$3,602,132** |


---

## Key Assumptions

1. **Volatility**: 8 significant bounces (5-15%) on the way to zero — conservative for crypto
2. **Execution**: EA trims longs automatically (20 lots/10s above 61% margin), balanced PROTECT below 55% with 5s cooldown
3. **Spread noise**: ~1.5% ML swing from spread changes — absorbed by 6% dead zone
4. **No black swan recovery**: SOL does not recover permanently
5. **Margin management**: EA's zone-based system prevents margin call (broker stop-out at 50%, PROTECT at 55% leaves 5% buffer, 5s cooldown prevents cascade)
6. **DOGE**: Closed during unwind. Reopened at max size once SOL hedge is fully unwound
7. **Position structure**: 44K long / 45K short SOL already held. No new lots added — EA only trims the hedge to grow net short exposure
8. **PROTECT safeguards**: Hard floor (10%), circuit breaker (69 fires), 5s cooldown, never closes bias
9. **Dynamic TRIM**: Can be adjusted 57-65% based on conditions while PROTECT stays fixed at 55%

## The Multiplier Effect Visualized

```
Standard Short:
  $59K equity → 342 SOL lots → hold → $30K profit
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $59K equity → 45,100 SOL short lots (hedged with 43,940 longs)
    → Net short: 1,160 lots (nearly flat — survives any spike)
    → Bounce 1:  EA trims 6K longs   → net short:  7,160 lots
    → Bounce 2:  EA trims 8K longs   → net short: 15,160 lots
    → Bounce 3:  EA trims 8K longs   → net short: 23,160 lots
    → Bounce 4:  EA trims 8K longs   → net short: 31,160 lots
    → Bounce 5:  EA trims 6K longs   → net short: 37,160 lots
    → Bounce 6:  EA trims 3K longs   → net short: 40,160 lots
    → Bounce 7:  final longs consumed → net short: 45,100 lots (PURE SHORT)
    → DOGE shorts reopened at max size
    → SOL hits $0: close all          → $3,543K profit (plus DOGE)
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

#### Phase 1: SOL $87 → $35

Current net short: 1,160 lots (but growing rapidly as EA trims longs)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $87 | 1,160 | $100,920 | $8,326 | $59,432 | 14.0% |
| $72 | 7,160 | $515,520 | $42,530 | $82,000* | 51.9% |
| $58 | 15,160 | $879,280 | $72,541 | $115,000* | 63.1% |
| $48 | 31,160 | $1,495,680 | $123,394 | $195,000* | 63.3% |
| $35 | 40,160 | $1,405,600 | $115,962 | $290,000* | 40.0% |

*Equity grows from harvested longs + unrealized short P/L. VaR rises significantly as net exposure grows — heavily dampens DARWIN during this phase.*

#### Phase 2: SOL $35 → $0 (The Lock-In)

**Once longs are fully unwound, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $35 | 45,100 | $1,578,500 | $130,226 | $350,000 | 37.2% |
| $25 | 45,100 | $1,127,500 | $93,019 | $750,000 | 12.4% |
| $15 | 45,100 | $676,500 | $55,811 | $1,500,000 | 3.7% |
| $10 | 45,100 | $451,000 | $37,208 | $2,100,000 | 1.8% |
| $5 | 45,100 | $225,500 | $18,604 | $2,900,000 | 0.6% |
| $2 | 45,100 | $90,200 | $7,442 | $3,400,000 | 0.2% |
| $0 | 45,100 | $0 | $0 | $3,602,000 | 0.00% |

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

**Phase 1 ($87 → $35): Very High VaR, Multiplier << 1.0**

Strategy VaR is very high due to gross exposure (89K total lots). The Darwinex risk engine **heavily dampens** the DARWIN:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 14.0% | ~6.0% | 0.43x | DARWIN shows 43% of raw returns |
| 63.3% | ~6.5% | 0.10x | Heavily dampened during peak exposure |

Returns are real but heavily dampened on the DARWIN while hedge is active.

**Phase 2 ($35 → $0): VaR Compressing → AMPLIFICATION**

As longs are consumed and VaR compresses, the Darwinex system works in your favor:

| SOL Price | Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|-----------|----------------|-------------------|-----------------|--------|
| $25 | 12.4% | ~6.0% | 0.48x | Still dampened |
| $15 | 3.7% | ~5.0% | 1.35x | **Parity reached** |
| $10 | 1.8% | ~4.0% | 2.22x | **2.2x amplification** |
| $5 | 0.6% | ~3.3% | 5.5x | **5.5x amplification** |
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
| Phase 1 profits ($87→$35) | $140,000 | ~$16,000 (heavily dampened) |
| Phase 2 profits ($35→$0) | $3,402,700 | ~$8,500,000+ (amplified ~2.5x avg) |
| DOGE (reopened after unwind) | TBD | TBD |
| DarwinIA performance fees | — | $100,000 — $500,000 |
| **SOL Total** | **$3,542,700** | **$8,500,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $59,432 | $59,432 | $59,432 |
| Max short lots (SOL) | 342 | 45,100 (held now) | 45,100 (held now) |
| Survives 10% spike? | NO | YES (44K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | High → compressing | High → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.10x → 9.75x |
| SOL signal profit | $29,754 | $3,542,700 | $3,542,700 |
| DOGE | — | TBD (after unwind) | TBD (after unwind) |
| DARWIN amplified returns | N/A | N/A | $8,500,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $100,000 — $500,000 |
| Return multiple (SOL only) | 0.50x | **59.6x** | 59.6x + DOGE + fees |

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

**Safeguard 3 — Circuit Breaker (69 fires max)**
```
After 69 PROTECT fires, it auto-disables.
"PROTECT CIRCUIT BREAKER — 69 fires reached. Disabled until manual reset."
```
This prevents the death spiral of consuming all positions overnight. At 10 lots per side per fire, 69 fires = 690 lots max from each side — a controlled reduction, not a total liquidation. The counter resets when MG mode is toggled.

**Safeguard 4 — PROTECT Cooldown (5 seconds)**
```
After each PROTECT fire, the EA waits 5 seconds before firing again.
```
At 89K gross lots, 10 lots/side per fire is only 0.022% of gross — too small to meaningfully move ML in a single fire. The 5s cooldown ensures 69 fires takes a minimum of 5.75 minutes, giving the market time to resolve spread spikes and preventing the circuit breaker from being exhausted during brief volatility.

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

### Root Causes

1. **1-second cooldown too short at 83K gross**: 30 fires in 58 seconds exhausted the circuit breaker before the market could recover. At this gross exposure, each fire is meaningless — 10 lots out of 83K can't move ML.

2. **PROTECT at 55% too close to operating range**: With 1.5% spread-induced ML swings, the effective operating band was 58-62%. PROTECT at 55% was only 3% below the noise floor — easily triggered by a slightly wider spread.

3. **Deactivation midpoint too close**: (55 + 59) / 2 = 57%. With ML oscillating at 56-57%, PROTECT never deactivated between fires — each fire saw ML still below 57% and kept firing.

4. **Trimming underwater longs pushes ML down**: Closing longs at a loss reduces equity AND reduces hedge netting. At 60% TRIM with ML barely above threshold, trimming itself can trigger broker intervention.

### Resolution: 61/55 with 5-Second Cooldown, 69 Max Fires

| Setting | Before (cascade) | After (current) | Improvement |
|---------|-------------------|-----------------|-------------|
| TRIM | 59% | 61% | 2% higher — needs real headroom to start |
| PROTECT | 55% | 55% | Same, but wider dead zone above |
| Dead zone | 4% (55-59) | 6% (55-61) | 50% wider — covers spread noise + trim effects |
| Cooldown | 1 second | 5 seconds | 69 fires now takes 5.75 min minimum |
| Max fires | 30 | 69 | More runway for genuine crises |
| Deactivation midpoint | 57% | 58% | Further above operating ML |

**With 61/55/5s, the cascade would not have happened:**
- ML at 56-57% is above 55% → PROTECT fires less frequently
- 5s cooldown means 69 fires takes 5.75 minutes — not 58 seconds
- 6% dead zone contains the 1.5% spread noise
- TRIM at 61% prevents the "trimming pushes ML down" problem

### Lessons Learned

1. **Cooldown must scale with gross exposure.** At 89K gross, 10 lots/fire is noise. The cooldown must be long enough for the market to demonstrate whether the ML drop is real or spread-driven. 5 seconds lets spread spikes resolve naturally.

2. **PROTECT threshold must be below the spread noise band.** If operating ML is 58-62% and spread causes ±1.5% swings, PROTECT must be below 56.5% minimum. At 55%, there's a 1.5% gap below the noise floor.

3. **Circuit breaker fires are precious at scale.** Each fire consumes 20 lots total from an 89K gross position — 0.022%. Spacing them out over minutes lets each fire have actual effect on a smaller (and shrinking) position.

4. **Trimming underwater longs can push ML down.** The realized loss + reduced hedge netting can cause ML to drop during TRIM. TRIM threshold must be high enough that this effect doesn't push ML toward PROTECT.

5. **The broker is the last resort, and that's OK.** When PROTECT can't recover ML (because each fire is too small), the circuit breaker correctly stops the EA. The broker's forced liquidation actually fixed the ML. The EA's job is to prevent the crisis, not to solve it once it's catastrophic.

---

## Bottom Line

The hedged martingale turns a **0.50x return** into a **59.6x return** on SOL alone, with DOGE to be added after unwind. The difference is entirely due to:

1. **Massive gross exposure**: 45,100 short lots already held (vs 342 lots a pure short could afford)
2. **Hedge protection**: 43,940 long lots absorb upside spikes — no margin call
3. **EA-managed unwinding**: TRIM zone automatically removes hedge on bounces above 61% margin
4. **Dynamic TRIM**: Can be adjusted 57-65% based on conditions while PROTECT stays fixed at 55%
5. **Spread compensation**: 6% dead zone absorbs the 1.5% ML swings from 89K gross lots
6. **Survivability**: PROTECT zone fires balanced closes below 55% with four safeguards:
   - Hard floor (10%) — EA halts below this, broker handles stop-out
   - Never closes bias — shorts are sacred, only balanced close when hedged
   - Circuit breaker (69 fires) — prevents death spiral
   - 5-second cooldown — spread spikes resolve before cascade

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

7. **Collapsing VaR**: Nominal value shrinks → VaR shrinks → risk multiplier climbs
8. **Profit lock-in**: Once longs are unwound, VaR can only decrease — the value is locked
9. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
10. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
11. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy holds 132x more short lots than a pure short could afford. The hedge makes this possible by neutralizing directional risk while the EA systematically strips the hedge away on every bounce, growing net short exposure until the position is pure profit. With 44K longs to unwind and settings calibrated for cascade prevention (61/55 with 5s PROTECT cooldown, 69 max fires), the unwind targets completion by SOL ~$30-40. Once pure short, DOGE reopened at max size and everything rides to $0.**
