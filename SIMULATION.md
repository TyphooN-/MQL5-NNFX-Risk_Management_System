# Simulation: Hedged Martingale vs Standard Short — SOL & DOGE to $0

## Starting Conditions

| | Value |
|---|---|
| Account | Fresh $100K deposit (IC Markets EU) |
| Account Equity | ~$78,500 |
| Margin Level | ~65% (at TRIM threshold) |
| Margin Call Level | 50% |
| SOL Price | ~$87 |
| Margin per lot | $86.69 (from OrderCalcMargin) |

### EA Configuration (v1.420)

| Parameter | Value |
|---|---|
| Mode | MG: SHORT |
| TRIM threshold | 65% margin level |
| TRIM formula | Forward-looking: `maxSafe = floor((equity/0.65 - margin) / marginPerLot)` |
| PROTECT threshold | 56% margin level (static — never lower after 54% broker liquidation) |
| PROTECT lots | Dynamic: `ceil(totalHedgeLots × max(1 - ML/threshold, 0.01))` per tick |
| Dead zone | 56%–65% (EA does nothing) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (shorts) in crisis |

### Why Forward-Looking TRIM (v1.420)

**v1.415 bug:** The old formula `min(headroom - 1, 1.0)` used current ML. At net 0 after Open MG, ML = 999% (margin ≈ $0), so `headroom = 999/65 = 15.4`, `fraction = 1.0` → TRIM tried to close ALL hedge lots. Two fires closed ~2,000 lots, crashing ML from 999% to 25%, triggering a PROTECT cascade that destroyed the entire position.

**v1.420 fix:** Forward-looking TRIM computes exactly how many lots can be closed before ML drops to threshold:
```
maxMargin = equity / (threshold / 100)
availableRoom = maxMargin - currentMargin
maxSafeLots = floor(availableRoom / marginPerLot)
```

**At net 0 (ML 999%), equity $78.5K, margin $0:**
- maxMargin = $78,500 / 0.65 = $120,769
- availableRoom = $120,769 - $0 = $120,769
- maxSafe = floor($120,769 / $86.69) = 1,393 lots

Instead of closing all 21,363 hedge lots (v1.415), TRIM closes only 1,393 lots (6.5%). ML lands at exactly 65%, TRIM pauses. Next favorable price tick creates room for a few more lots. Gradual, safe, self-regulating.

### Net-Based Margin

The broker charges margin on **net exposure only** — not gross. This is fundamental to the strategy:

- **Trimming longs INCREASES margin** (grows net short → more margin required → ML drops)
- **PROTECT balanced close preserves net** → margin unchanged
- **The position is safest when most hedged** (low net = low margin)
- **Spread still affects equity on gross** — spread tolerance = equity / gross lots

**PROTECT at 56%** leaves 6% buffer above 50% margin call. Dynamic lot sizing prevents cascade — close size scales with margin urgency.

### Entry Rules: Single Base Price, Maximum Intensity

**The hedge must be set up at maximum intensity at a single base price.** This is the most critical rule of the strategy.

1. **Single base price** — all longs and shorts entered at the same price. No averaging in, no adding below base.
2. **Safe intensity at open** — gross set to equity / $2.00 on day one. This is the biggest the position will ever be. **Never exceed this limit** — three liquidation events proved that oversized positions are always destroyed by spread spikes before trimming can reach safety.
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
Gross-based spread tolerance = Equity / Gross lots

$78,500 / 42,726 = $1.84/lot spread tolerance
```

**Net-based margin:** Broker charges margin on net exposure only (~$87 × net lots). With net ~1,402 and $78.5K equity, ML ≈ 65%. Spread tolerance is $1.84/lot on gross — close to but slightly below the $2.00 overnight safety threshold.

### Current Positions (v1.420 deployment — 2026-03-06)

| Asset | Price | Long (Hedge) | Short (Bias) | Net Short | ML |
|-------|-------|-------------|--------------|-----------|-----|
| SOLUSD | ~$87 | ~19,961 | 21,363 | ~1,402 | ~65% |
| DOGEUSD | — | 0 | 0 | 0 | — |

**Position history:** Fresh $100K account. Open MG placed 21,363/side at ~$87. v1.420 forward-looking TRIM fired 5 times: closed 900 + 499 + 1 + 1 + 1 = 1,402 hedge lots, bringing ML to exactly 65%. TRIM is now self-pacing at 1 lot per favorable tick.

**Note on DOGE:** Will be opened once SOL longs are under ~10K and equity headroom allows. See [DOGE Entry Timing](#doge-entry-timing).

### Trim Progression to Pure Short (Forward-Looking TRIM)

With v1.420, TRIM brings ML to exactly 65% at each price level. The max sustainable net at price P is `equity / (0.65 × P)`. As SOL drops, equity grows from net short P/L and margin per lot decreases — both effects accelerate trimming.

**Key insight:** Closing a hedge position doesn't change equity (unrealized P/L becomes realized). So TRIM can be computed purely from equity, margin, and price at each level.

| SOL Price | Hedge (Long) | Net Short | Lots Trimmed | Gross | Equity | ML | Spread Tol. | Status |
|---|---|---|---|---|---|---|---|---|
| **$87 (now)** | **19,961** | **1,402** | **1,402** | **41,324** | **$78,500** | **65%** | **$1.90** | At threshold |
| $80 | 19,665 | 1,698 | 296 | 41,028 | $88,314 | 65% | $2.15 | **Overnight safe** |
| $70 | 19,049 | 2,314 | 616 | 40,412 | $105,294 | 65% | $2.60 | Safe |
| $60 | 18,070 | 3,293 | 979 | 39,433 | $128,434 | 65% | $3.26 | Comfortable |
| $50 | 16,398 | 4,965 | 1,672 | 37,761 | $161,364 | 65% | $4.27 | Very safe |
| $40 | 13,247 | 8,116 | 3,151 | 34,610 | $211,014 | 65% | $6.10 | Growing fast |
| $30 | 6,380 | 14,983 | 6,867 | 27,743 | $292,174 | 65% | $10.53 | Accelerating |
| **$20** | **0** | **21,363** | **6,380** | **21,363** | **$442,004** | **103%** | **$20.69** | **PURE SHORT** |
| $10 | 0 | 21,363 | — | 21,363 | $655,634 | 307% | $30.69 | Printing |
| $5 | 0 | 21,363 | — | 21,363 | $762,449 | 713% | $35.69 | Locked in |
| **$0** | **0** | **21,363** | **—** | **21,363** | **$869,264** | **∞** | **∞** | **Done** |

**Cumulative hedge lots trimmed: 19,961** (from $87 entry to various closing prices)
**Average hedge closing price: ~$33.50** (most lots close at lower prices where trim accelerates)

### How TRIM Pacing Works

TRIM brings ML to 65% then waits for price movement to create more room:

| SOL Drop | Equity Gained (from net) | New Room | Lots Trimmed | Trim Accelerates? |
|---|---|---|---|---|
| $87 → $80 | $9,814 (1,402 × $7) | $9,814 | 296 | Slow — small net |
| $80 → $70 | $16,980 (1,698 × $10) | $16,980 | 616 | Moderate |
| $70 → $60 | $23,140 (2,314 × $10) | $23,140 | 979 | Building |
| $60 → $50 | $32,930 (3,293 × $10) | $32,930 | 1,672 | Significant |
| $50 → $40 | $49,650 (4,965 × $10) | $49,650 | 3,151 | Fast |
| $40 → $30 | $81,160 (8,116 × $10) | $81,160 | 6,867 | Rapid |
| $30 → $20 | $149,830 (14,983 × $10) | $149,830 | 6,380 (all) | **Complete** |

**The flywheel:** Each $1 SOL drop → shorts profit → equity up → more TRIM room → more net → next $1 drop earns more. The trim rate compounds as the position unwinds.

### Key Milestones

- **$80**: Spread tolerance crosses $2.00/lot → **overnight safe**
- **$50**: Equity $161K, spread tolerance $4.27 → deeply safe, TRIM accelerating
- **$30**: Equity $292K, 70% of hedge consumed → home stretch
- **$20**: **PURE SHORT** — all 19,961 hedge lots consumed. Equity $442K. Position is locked profit from here
- **$0**: Equity **$869K** — total profit **$791K** (10.1x return on $78.5K)

### PROTECT as Strategic Tool

PROTECT (balanced close) is not just an emergency mechanism — **it serves the strategy**:

1. **Reduces gross exposure** — fewer lots means less equity impact from spread spikes
2. **Preserves net short ratio** — balanced close maintains the directional thesis
3. **Better than broker intervention** — the broker would liquidate positions randomly (often closing shorts, destroying the thesis). PROTECT closes balanced pairs, preserving the net short structure.
4. **Resumes trimming faster** — surviving a spread spike means the EA can continue trimming longs on the next move

**The tradeoff:** PROTECT destroys shorts alongside longs. But losing shorts to survive beats losing the entire position to a broker stop-out. The shorts can be rebuilt; a liquidated account cannot.

**Important:** With net-based margin, balanced close doesn't change net → doesn't change margin → doesn't directly improve ML. PROTECT helps by reducing gross (limiting future spread damage), not by fixing ML. Forward-looking TRIM (v1.420) prevents TRIM from ever cascading into PROTECT territory.

**Dynamic sizing:** PROTECT close size is `ceil(totalHedgeLots × urgency)` where urgency = `max(1 - ML/threshold, 0.01)`. Scales to any position size — no tuning needed.

**Constraints:**
- PROTECT at 56% is the floor (never lower after 54% broker liquidation experience)
- Hard floor at 10% — below this, broker handles stop-out, EA intervention only makes it worse

### Overnight Safety

With forward-looking TRIM (v1.420), ML stays at 65% during active trimming. Overnight safety depends on **spread tolerance** (equity / gross), not ML:

| SOL Price | Gross | Equity | Spread Tol. | Overnight? |
|---|---|---|---|---|
| **$87 (now)** | **41,324** | **$78,500** | **$1.90** | **Borderline — close to $2.00** |
| $80 | 41,028 | $88,314 | $2.15 | **Yes — above $2.00** |
| $70 | 40,412 | $105,294 | $2.60 | Yes |
| $50 | 37,761 | $161,364 | $4.27 | Very safe |

**At current price ($87), spread tolerance is $1.90/lot — slightly below the $2.00 safety rule.** Overnight is borderline. A $3 SOL drop to $84 would bring tolerance to ~$2.05. Once past $80, the position is safely overnight-able and only gets safer.

---

## Scenario A: Standard Short (No Hedging)

With $78,500 equity, 1:1 crypto margin, and 200% margin level (minimum to survive any volatility):

**Maximum position at open:**
- SOLUSD: ~452 lots short @ $87

### Profit if SOL hits $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 452 | $87 | $39,324 |

**Return: $39,324 on $78,500 = 0.50x (50% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

## Scenario B: Hedged Martingale (Current Strategy)

### Current Position Structure

The hedge: ~19,961 long lots vs 21,363 short lots on SOLUSD. Net short exposure is ~1,402 lots. The broker charges margin on net exposure only — not gross. Gross (~41,324) still determines spread tolerance for equity swings.

The EA manages this automatically (v1.420 — forward-looking TRIM):
- **Above 65%**: TRIM — `maxSafe = floor((equity/0.65 - margin) / marginPerLot)` — closes only enough to bring ML to threshold
- **56%–65%**: Dead zone — EA does nothing, allows normal price action
- **Below 56%**: PROTECT — balanced close `ceil(hedgeLots × urgency)` per tick (scales with margin urgency)
- **Below 10%**: Hard floor — EA halts entirely, broker handles stop-out
- **No hedges left**: EA refuses to close bias — shorts are sacred

### Forward-Looking TRIM (v1.420)

TRIM computes the exact margin available before ML hits threshold, then closes that many lots — never more. This prevents the v1.415 catastrophe where artificially high ML (999% at net 0) caused TRIM to close everything.

PROTECT stays fixed at 56%. TRIM can **never** cascade into PROTECT because it's mathematically impossible for TRIM to push ML below its own threshold.

### Phase 1: $87 → $30 (Continuous TRIM, no bounces needed)

With forward-looking TRIM (v1.420), the EA doesn't need bounces to trim. It continuously closes hedge lots whenever ML is above 65%, self-pacing to maintain ML at exactly the threshold. Each SOL price drop creates room (equity grows from net short P/L + margin per lot drops).

**TRIM doesn't wait for profitable longs.** It closes the highest-cost hedge positions regardless of P/L — the goal is margin recovery, not trade profit. As SOL drops, hedge lots are closed at increasing losses, but equity grows faster from net short exposure.

| Price Range | Lots Trimmed | Avg Loss/Lot | Trim Cost | Equity After | Net Short |
|---|---|---|---|---|---|
| $87 → $80 | 296 | $3.50 | $1,036 | $88,314 | 1,698 |
| $80 → $70 | 616 | $12 | $7,392 | $105,294 | 2,314 |
| $70 → $60 | 979 | $22 | $21,538 | $128,434 | 3,293 |
| $60 → $50 | 1,672 | $32 | $53,504 | $161,364 | 4,965 |
| $50 → $40 | 3,151 | $42 | $132,342 | $211,014 | 8,116 |
| $40 → $30 | 6,867 | $52 | $356,684 | $292,174 | 14,983 |
| **Subtotal** | **13,581** | | **$572,496** | | |

**Phase 1 note:** Trim cost ($572K) is already accounted for in equity — closing doesn't change equity (unrealized → realized). The equity numbers above are the ACTUAL equity at each price level.

### Phase 2: $30 → $0 (Pure short from ~$20)

Remaining ~6,380 hedge lots consumed between $30 and $20. Position becomes pure short at ~$20.

**$30 → $20:** Final 6,380 longs consumed — trim cost ~$396K (avg loss $62/lot). Equity: $442K.
- **DOGE shorts opened at maximum size**

**$20 → $0: Pure short**
- Each dollar down = 21,363 × $1 = **$21,363 profit per dollar**
- DOGE shorts adding to profits on every tick down
- No more trim costs — position is pure profit accumulation
- Equity: $442K → $655K → $869K

### Final Close at $0

| Component | Lots | Profit |
|-----------|------|--------|
| SOLUSD shorts (21,363 × $87) | 21,363 | **$1,858,581** |
| Long trim costs (19,961 lots consumed) | 19,961 | **-$968K** |
| Starting equity | — | $78,500 |
| DOGE (opened after unwind) | TBD | TBD |
| **Final equity** | | **$869,264** |
| **Net profit (SOL only)** | | **$790,764** |

The long trim cost (~$968K) doesn't come out of equity at closing time — it was already accounted for as realized losses during the trim process. The $869K is the actual final account equity.

### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Final equity at SOL $0 | $869,264 |
| Starting equity | $78,500 |
| **SOL Net Profit** | **$790,764 (10.1x)** |
| DOGE (opened after unwind) | TBD |

---

## Side by Side Comparison

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $78,500 | $78,500 |
| Max short lots (SOL) | 452 | 21,363 (held now) |
| Survives 10% spike? | NO (margin call) | YES (~20K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES (price drops create TRIM room) |
| Hedge removal cost | N/A | ~$968K (price of building 21.4K net short) |
| SOL profit if → $0 | **$39,324** | **$790,764** |
| Return multiple | **0.50x** | **10.1x** |
| Final account value | ~$117,824 | **~$869,264** |


---

## Key Assumptions

1. **Continuous decline**: SOL trends from $87 → $0 with bounces along the way (conservative for crypto bear market)
2. **Execution**: EA trims longs automatically via forward-looking TRIM (v1.420), balanced PROTECT below 56%
3. **Spread noise**: ~$1.90/lot tolerance at current gross — borderline overnight, safe after $80
4. **No black swan recovery**: SOL does not recover permanently
5. **Margin management**: Forward-looking TRIM cannot push ML below its threshold (mathematically impossible). PROTECT at 56% leaves 6% buffer above 50% stop-out
6. **DOGE**: Opened at max size once SOL hedge is sufficiently unwound — both ride to $0
7. **Position structure**: ~20K long / 21.4K short SOL held. No new lots added below base — EA only trims the hedge
8. **PROTECT safeguards**: Hard floor (10%), dynamic lot sizing (scales with urgency), never closes bias
9. **Position sizing**: Gross lots must reach equity / $2.00 ($1.90 currently — borderline) before overnight is safe

## The Multiplier Effect Visualized

```
Standard Short:
  $78K equity → 452 SOL lots → hold → $39K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $78K equity → 21,363 SOL short lots (hedged with ~20K longs)
    → Net short: 1,402 lots (nearly flat — survives any spike)
    → $87 → $80:  TRIM closes    296 longs → net short:  1,698 lots
    → $80 → $70:  TRIM closes    616 longs → net short:  2,314 lots
    → $70 → $60:  TRIM closes    979 longs → net short:  3,293 lots
    → $60 → $50:  TRIM closes  1,672 longs → net short:  4,965 lots
    → $50 → $40:  TRIM closes  3,151 longs → net short:  8,116 lots
    → $40 → $30:  TRIM closes  6,867 longs → net short: 14,983 lots
    → $30 → $20:  TRIM closes  6,380 longs → net short: 21,363 lots (PURE SHORT)
    → DOGE shorts opened at max size
    → SOL hits $0: close all        → $791K net profit (10.1x) plus DOGE
  [Forward-looking TRIM: each SOL drop creates room → more hedge closes → bigger net
   → next drop earns more. The flywheel compounds. Longs are fuel, shorts are profit.]
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

#### Phase 1: SOL $87 → $20

Current net short: ~1,402 lots (growing as forward-looking TRIM unwinds hedges)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $87 | 1,402 | $121,974 | $10,063 | $78,500 | 12.8% |
| $70 | 2,314 | $161,980 | $13,363 | $105,294 | 12.7% |
| $50 | 4,965 | $248,250 | $20,481 | $161,364 | 12.7% |
| $40 | 8,116 | $324,640 | $26,783 | $211,014 | 12.7% |
| $30 | 14,983 | $449,490 | $37,083 | $292,174 | 12.7% |

*VaR stays remarkably stable as % of equity (~12.7%) during the trim phase because forward-looking TRIM maintains ML at exactly 65%. Both net exposure and equity grow proportionally.*

#### Phase 2: SOL $20 → $0 (The Lock-In)

**Once longs are fully unwound at ~$20, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $20 | 21,363 | $427,260 | $35,249 | $442,004 | 8.0% |
| $15 | 21,363 | $320,445 | $26,437 | $548,819 | 4.8% |
| $10 | 21,363 | $213,630 | $17,625 | $655,634 | 2.7% |
| $5 | 21,363 | $106,815 | $8,812 | $762,449 | 1.2% |
| $2 | 21,363 | $42,726 | $3,525 | $826,175 | 0.4% |
| $0 | 21,363 | $0 | $0 | $869,264 | 0.00% |

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

**Phase 1 ($87 → $20): Stable VaR, Moderate Dampening**

With forward-looking TRIM maintaining ML at 65%, VaR stays stable at ~12.7% of equity:

| Strategy VaR % | Target VaR (est.) | Risk Multiplier | Effect |
|----------------|-------------------|-----------------|--------|
| 12.7% | ~6.0% | 0.47x | DARWIN shows 47% of raw returns |

Returns are real but moderately dampened on the DARWIN while hedge is active. The stable VaR is much better than the v1.415 wild swings.

**Phase 2 ($20 → $0): VaR Compressing → AMPLIFICATION**

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
| SOL net profit at $0 | $790,764 | ~$2,000,000+ (amplified ~2.5x avg) |
| DOGE (opened after unwind) | TBD | TBD |
| DarwinIA performance fees | — | $50,000 — $200,000 |
| **SOL Net Total** | **$790,764** | **$2,000,000+** |

The DARWIN doesn't generate separate profit for your signal account, but:
1. **DarwinIA performance fees** are real cash (15% of profits on allocated capital)
2. **Investor allocations** earn you management/performance fees
3. **Track record** attracts more capital post-event

---

## Complete Side by Side Comparison

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $78,500 | $78,500 | $78,500 |
| Max short lots (SOL) | 452 | 21,363 (held now) | 21,363 (held now) |
| Survives 10% spike? | NO | YES (~20K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | Stable 12.7% → compressing | Stable → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.47x → 9.75x |
| Hedge removal cost | N/A | -$968,000 | -$968,000 |
| SOL signal profit | $39,324 | $790,764 | $790,764 |
| DOGE | — | TBD (after unwind) | TBD (after unwind) |
| DARWIN amplified returns | N/A | N/A | $2,000,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $50,000 — $200,000 |
| Return multiple (SOL only) | 0.50x | **10.1x** | 10.1x + DOGE + fees |

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

**Safeguard 3 — Dynamic Lot Sizing (v1.420)**
```
TRIM:    maxSafe = floor((equity/0.65 - margin) / marginPerLot)  — forward-looking, can never overshoot
PROTECT: close size = ceil(totalHedgeLots × urgency), urgency = max(1 - ML/threshold, 0.01)
```
Replaces the fixed closes and circuit breaker. Forward-looking TRIM (v1.420) computes exactly how many lots can be closed before ML hits threshold — mathematically impossible to cascade into PROTECT. PROTECT urgency scales with danger level — no tuning needed.

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

| Setting | Before (cascade) | After (v1.420) | Improvement |
|---------|-------------------|-----------------|-------------|
| TRIM | 59-61% | 65% (forward-looking) | Can never overshoot threshold |
| TRIM lots | 20 fixed | `floor((eq/0.65 - margin) / mpl)` | Exact margin math, no guessing |
| PROTECT | 54-56% | 56% (static) | Fixed reference point |
| PROTECT lots | 10 fixed | `ceil(hedge × urgency)` | Scales with position + danger |
| Dead zone | 4-6% | 9% (56-65) | Covers spread noise at current gross |
| Deactivation | Midpoint (~60%) | Threshold (56%) | No more firing at 57-58% |
| Cooldown | 1-15 seconds | None (per tick) | Forward-looking sizing handles pacing |
| Circuit breaker | 30-1000 fires | Removed | Forward-looking = can't cascade |

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

4. **Fresh account rule: build to safe size, never beyond.** Never open gross lots above equity / $2.00 — this is the only defense that matters.

---

## Post-Mortem #4: Full Liquidation While Away (2026-03-05)

### What Happened

With 83K gross lots (41.1K L / 42.3K S) on $72K equity, a spread spike while away destroyed the entire position. Settings were 66/56 with 15s cooldown. ML was at 66.3% just before stepping away.

**Timeline:**

1. **11:09 — Last trim**: TRIM fired at 66.3% ML, equity $74,975. Everything normal.

2. **17:05:02 — Spread spike**: ML crashed from ~66% to **4.7% instantly**. No visible price movement on the chart — pure spread widening.

3. **PROTECT fired once** at 4.7% ML. Hard floor immediately halted PROTECT (below 10%).

4. **17:05:04 — Full broker liquidation**: Broker closed ALL positions — 41,110 longs and 42,340 shorts. Hedge: 0, Bias: 0. Equity: **$45,723** (down from $75K).

5. **Balance increased by $8,098** — broker closing profitable shorts realized gains, partially offsetting the spread damage.

### Root Cause

**Same as Post-Mortem #3: position was 2.4x over the safe limit.**

```
$72,264 / $2.00 = 36,132 max safe gross
Actual gross: 83,450 — 2.3x over the limit
Spread tolerance: $0.87/lot — a $0.87 spread wipe = total margin failure
```

The spread spike was invisible on the price chart. SOL showed no abnormal price action at 17:05. The spread widened for seconds, consumed all margin on 83K gross, and returned to normal. The chart shows nothing.

### Why This Keeps Happening

Three liquidation events — all the same cause:

| Event | Gross | Equity | Tolerance | Over Limit |
|---|---|---|---|---|
| PM#3: Overnight wipe | 89K | $60K | $0.67/lot | 2.97x |
| Broker liquidation (03-04) | 110K | $69K | $0.63/lot | 3.19x |
| **PM#4: Away wipe** | **83K** | **$72K** | **$0.87/lot** | **2.30x** |

Every time: gross was 2-3x over the safe limit. Every time: EA safeguards worked correctly but couldn't prevent what position sizing should have prevented.

### The Invisible Killer

Spread spikes don't appear on price charts. They last 1-5 seconds. At safe sizing ($2.00/lot tolerance), a spread spike costs margin temporarily but ML recovers. At 2x+ over the limit, the same spike is fatal.

**There is no EA setting, no dead zone width, no cooldown, no circuit breaker that protects against spread spikes on an oversized position.** The position sizing rule is the ONLY defense.

### Lessons Confirmed (Third Time)

1. **The $2.00/lot rule is not optional.** Three accounts have been damaged or destroyed by ignoring it. No EA configuration compensates for oversized positions.

2. **"I'll trim down to safety" doesn't work.** The spike always comes before the trimming is done. Even with v1.415 dynamic lot sizing (aggressive closes with headroom), trimming requires sustained ML above the threshold — the spread spike doesn't wait.

3. **Opening at max intensity above the rule is the fundamental error.** The entry rules say "gross set to equity / $2.00 on day one." Every position that exceeded this was liquidated.

4. **Equity $45,723 is salvageable.** Enough to rebuild within the sizing rule: 22.8K gross = 11.4K per side.

---

## Liquidation Triggers: Known, Observed, and Speculated

Four post-mortems have revealed that **margin level is cosmetic with net-based margin** — the broker charges margin on net exposure only, so ML can show 60%+ while the position is fatally exposed to spread risk on the full gross. This section catalogs every known and suspected way the broker can liquidate a position.

### Known Triggers (Confirmed from 4 Post-Mortems)

| Trigger | Mechanism | Confirmed In |
|---|---|---|
| **ML < 50% stop-out** | Broker's published margin call level. Once equity/margin < 50%, broker begins force-liquidating | All PMs |
| **Spread spike → equity collapse** | Spread widens on ALL lots (gross-based), not just net. At $0.87/lot tolerance, a sub-$1 spread wipe = total margin failure | PM#3, PM#4 |
| **Full position liquidation** | Broker closes EVERYTHING — not partial, not just enough to restore ML. All longs and all shorts gone in seconds | PM#3, PM#4 |
| **Invisible on chart** | Spread spikes don't appear on price charts. No abnormal candle, no wick, no gap. Lasts 1-5 seconds | PM#4 |

### Known Broker Behaviors (Observed)

| Behavior | Details |
|---|---|
| **Liquidates entire position** | Even when closing half would restore ML, broker closes all. Possible risk-aversion policy for crypto |
| **Speed of execution** | PM#4: from 66% ML to 0 lots in ~2 seconds. No human reaction possible |
| **Balance increases on liquidation** | Closing profitable shorts realizes gains. PM#4: balance went UP by $8,098 even as equity dropped $30K |
| **Net-based margin is cosmetic** | ML shows 62-126% on heavily hedged positions, but spread tolerance is $0.47-0.87/lot — fatal |
| **No warning** | No margin call email, no alert, no pre-liquidation notice. Just gone |

### The Real Risk Metric

**ML is NOT the survival metric. Spread tolerance is.**

```
Spread tolerance = Equity / Gross lots

$78,500 / 41,324 gross = $1.90/lot  ← current position (borderline)
$72,264 / 83,450 gross = $0.87/lot  ← PM#4 (liquidated)
$60,000 / 89,000 gross = $0.67/lot  ← PM#3 (liquidated)

Safe minimum: $2.00/lot (survives overnight spreads)
```

ML can show 65% (looks safe) while spread tolerance is $1.90/lot (borderline). The broker's margin calculation uses net exposure, but spread risk hits gross exposure. These are fundamentally different numbers.

### Speculated Triggers (To Research and Avoid)

| Trigger | Speculation | Risk Level |
|---|---|---|
| **Overnight margin multiplier** | Some brokers increase margin requirements outside market hours (crypto is 24/7 but liquidity drops on weekends). Higher margin → lower ML → stop-out at "normal" positioning | Medium — test by observing weekend ML behavior |
| **Max notional value limits** | Broker may cap total notional exposure (gross × price). At 71.6K lots × $89 = $6.4M notional — some brokers flag positions above $1-5M | Medium — would explain why smaller positions survive longer |
| **Negative balance protection** | EU/ASIC brokers must prevent negative balance. If the broker's model predicts a position COULD go negative, they may liquidate preemptively before the published 50% stop-out | High — would explain "why did it liquidate at 60%+ ML" |
| **Dynamic margin requirements** | Broker may silently increase margin requirements during high-volatility periods. A position that required $53K margin yesterday may require $80K today with no visible change in settings | High — completely invisible to the trader |
| **Broker discretion clause** | Most broker agreements include "we may close positions at our discretion to manage risk." Large crypto hedges may trigger manual risk desk intervention | Medium — unpredictable but likely at $6M+ notional |
| **Swap/financing drain** | Daily swap charges on large gross positions erode equity over time. At 71.6K gross, even a small per-lot swap compounds to significant daily costs | Low — visible in account history, can be tracked |
| **Position count limits** | Some brokers limit the number of open positions or total lots. Hitting the limit may prevent new hedges or trigger forced reduction | Low — typically disclosed in account terms |
| **Liquidity provider rejection** | The broker's LP may reject or partially fill orders at extreme sizes. During a spread spike, LP may pull quotes entirely, leaving the broker to liquidate at whatever price is available | Medium — explains why liquidation prices are often worse than expected |

### Fresh Account Safety Framework

For the next fresh account (or recovery of this one), the safety framework is:

| Rule | Value | Why |
|---|---|---|
| **Max gross** | Equity / $2.00 | Survives $2.00 overnight spread spikes |
| **Opening size** | Safe from day one | Never "open big, trim down" — the spike comes before trimming finishes |
| **PROTECT** | 56% fixed, dynamic lots | Below this, balanced close scales with urgency |
| **TRIM** | 65% forward-looking (v1.420) | Computes max safe lots from margin math — can never cascade into PROTECT |
| **Hard floor** | 10% | Below this, broker handles it — EA intervention only makes it worse |
| **Monitor spread tolerance** | Log equity/gross daily | If tolerance drops below $2.00, stop opening new lots |
| **Weekend caution** | Reduce gross Friday or accept risk | Crypto weekend liquidity is thinner → wider spreads |
| **Notional awareness** | Track gross × price | If notional exceeds $2M, consider whether broker risk desk may intervene |

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

## Fresh Account Sizing

The position sizing rule must be respected from the first trade. No exceptions.

### Formula

```
Max safe gross = Equity / $2.00

Per side (hedged) = Max safe gross / 2
```

### Current Position Sizing

**With ~$78,500 equity:**

| Metric | Value | Safe? |
|---|---|---|
| Gross | 41,324 | $78,500 / 41,324 = **$1.90/lot** |
| Safe max gross | 39,250 | $78,500 / $2.00 |
| Over limit by | ~2,074 lots (5%) | **Borderline — safe after $3 SOL drop** |

### Why Safe Size from Day One

The previous strategy was "open at maximum intensity, trim down to safety." This failed three times because:

1. **Spread spikes are random and invisible** — you can't predict when one will hit
2. **Trimming takes time** — hours to days to reach safe gross from oversized
3. **Every moment over the limit is a gamble** — you're betting the spike doesn't come before trimming finishes

**New rule: open at safe size and stay safe.** The position is smaller, the profits are smaller, but the position survives. Current position (21.4K short at $87) riding SOL to $0 is worth **$869K** — far more than a 42K position that gets liquidated at $92.

### Current Position Financials ($78,500 equity, 21,363 shorts)

| Component | Amount |
|---|---|
| Final equity at SOL $0 | $869,264 |
| Starting equity | $78,500 |
| **Net profit** | **$790,764** |
| **Return multiple** | **10.1x** |
| Pure short achieved at | ~$20 SOL |

10.1x on a position that forward-looking TRIM can't destroy. Spread tolerance crosses $2.00 at $80 SOL.

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
- Same PROTECT/hard floor safeguards with dynamic lot sizing
- TRIM/PROTECT settings calibrated for DOGE spread behavior (may differ from SOL)

**Key difference:** By the time DOGE is opened, the account has substantial equity from SOL shorts. This means:
- DOGE spread tolerance is excellent from day one (unlike SOL which started over-exposed)
- DOGE overnight safety is immediate if sized correctly
- No anxious trimming phase — DOGE starts safe and stays safe

### Combined Ride to $0

Once SOL is pure short and DOGE is open:
- Both assets grinding to $0 simultaneously
- VaR collapsing on both positions
- Combined per-dollar profit: 21,363 (SOL) + DOGE lots
- Darwinex amplification applies to the combined position
- DarwinIA scoring benefits from the extreme return/drawdown ratio across both

### Why DOGE on the Same Account?

- Same directional thesis (short to $0) — one DARWIN, one track record
- Combined VaR compression is more impressive than separate
- Single DarwinIA evaluation with combined returns
- Full equity available — no capital split across accounts

---

## Bottom Line

The hedged martingale turns a **0.50x return** into a **10.1x return** on SOL alone, with DOGE to be added after unwind. The difference is entirely due to:

1. **Massive gross exposure**: 21,363 short lots held (vs 452 lots a pure short could afford)
2. **Hedge protection**: ~20K long lots absorb upside spikes — net-based margin keeps ML high when hedged
3. **Forward-looking TRIM (v1.420)**: Computes exactly how many lots can be closed before ML hits threshold — mathematically impossible to overshoot
4. **Self-pacing unwind**: TRIM brings ML to exactly 65%, then waits for price movement to create room. Each SOL drop → equity up → more room → more trim → bigger net → next drop earns more (flywheel)
5. **Net-based margin**: Broker charges margin on net exposure only — heavily hedged positions have low margin despite large gross
6. **Survivability**: PROTECT zone fires balanced closes below 56%:
   - Dynamic close size = `ceil(hedgeLots × urgency)` — scales with danger level
   - Hard floor (10%) — EA halts below this, broker handles stop-out
   - Never closes bias — shorts are sacred
7. **PROTECT can't be triggered by TRIM** — forward-looking formula guarantees TRIM never pushes ML below its own threshold

The **VaR compression** as price approaches zero creates a secondary amplifier through Darwinex:

8. **Stable VaR during trim**: Forward-looking TRIM keeps VaR at ~12.7% of equity throughout Phase 1
9. **Collapsing VaR after unwind**: Once pure short at ~$20, VaR only decreases → risk multiplier climbs
10. **DARWIN amplification**: Risk multiplier up to 9.75x in the final collapse phase
11. **DarwinIA magnetism**: Extreme return/drawdown ratio attracts maximum allocation
12. **Performance fees**: 15% of profits on up to 875K EUR allocated capital

**The strategy holds 47x more short lots than a pure short could afford. Net-based margin means the heavily hedged position (net 1,402 on 41.3K gross) requires only $122K margin — ML starts at ~65%. The hedge makes this possible by neutralizing directional risk while the EA systematically strips the hedge away via forward-looking TRIM, growing net short exposure at the mathematically optimal rate. The longs are fuel to burn (~$968K trim cost), not a profit source. The profit comes from the shorts' exposure growing as the hedge is consumed ($869K equity at $0). With ~20K longs to unwind and TRIM/PROTECT at 65/56 (v1.420 forward-looking — no cooldowns, no circuit breaker, TRIM can never cascade into PROTECT), the unwind rate is controlled by SOL price movement. TRIM self-paces at exactly 65% ML and accelerates as the flywheel builds: more net → more profit per $1 drop → more room → more trim. Pure short at ~$20, then DOGE at max size. Everything rides to $0 in the VaR compression spiral. Then flip long SOL from the bottom and ride the next cycle up.**
