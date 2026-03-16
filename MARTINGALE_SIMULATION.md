# Hedged Martingale Strategy & Simulation

The hedged martingale exploits net-based margin to carry massive directional exposure via a hedge that is systematically trimmed as the thesis plays out. The EA (TyphooN v1.420) manages the position automatically via forward-looking TRIM and dynamic PROTECT.

**Current plan:** CFD commodities — XNGUSD long from spring seasonal low.
**Historical:** SOLUSD crypto short — five spread-spike liquidations, lessons preserved below.

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

### TRIM Threshold: 1:1 vs Leveraged Instruments

**Critical:** The TRIM/PROTECT dead zone must scale with leverage:

| Leverage | TRIM | PROTECT | Dead Zone | Rationale |
|---|---|---|---|---|
| 1:1 (crypto) | 65-66% | 56-60% | 6-10% | Each 1% price move ≈ 1% ML change |
| **5:1 (CFD)** | **80%** | **56%** | **24%** | Each 1% price move ≈ 3% ML change |

With x5 leverage, a 2% adverse price move covers the entire 65→56 dead zone. TRIM at 80% provides equivalent safety margin.

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

## Historical: SOLUSD Crypto Account (March 2026)

Three $100K Darwinex Zero accounts, five spread-spike liquidations. The EA worked correctly every time — the accounts were destroyed by crypto's uniquely violent spread behavior. All lessons below informed the CFD pivot.

### SOLUSD Starting Conditions

| | Value |
|---|---|
| Account | $100K deposit (IC Markets EU) — now ~$72K after 5 spread-spike events |
| Account Equity | ~$72,000 |
| Margin Level | ~66% (at TRIM threshold) |
| Margin Call Level | 50% |
| SOL Price | ~$85 |
| Margin per lot | ~$85.48 (from OrderCalcMargin) |

### EA Configuration (v1.420)

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

### SOLUSD v1.420 TRIM Example

At net 0 (ML 999%), equity $72K, margin $0:
- maxMargin = $72,000 / 0.66 = $109,091
- availableRoom = $109,091 - $0 = $109,091
- maxSafe = floor($109,091 / $85.48) = 1,276 lots

Instead of closing all 19,488 hedge lots (v1.415 bug), TRIM closes only 1,276 lots (6.5%). ML lands at exactly 66%, TRIM pauses. Gradual, safe, self-regulating.

### SOLUSD Position Sizing

```
Spread tolerance = $72,000 / 37,700 gross = $1.91/lot (borderline — $2.00 minimum)
```

### Current Positions (post-PM#5 re-hedge — 2026-03-06)

| Asset | Price | Long (Hedge) | Short (Bias) | Net Short | ML |
|-------|-------|-------------|--------------|-----------|-----|
| SOLUSD | ~$85 | ~18,212 | 19,488 | ~1,276 | ~66% |
| DOGEUSD | — | 0 | 0 | 0 | — |

**Position history:** $100K deposit. Five spread-spike events (PM#1-5) reduced equity to ~$72K. After PM#5 broker liquidation (everything except 1,100 original shorts), re-hedged via Open MG at 19,488/side at ~$85. v1.420 TRIM fired ~1,276 times, bringing ML to exactly 66%. TRIM is now self-pacing at 1 lot per favorable tick.

**Note on DOGE:** Will be opened once SOL longs are under ~10K and equity headroom allows. See [DOGE Entry Timing](#doge-entry-timing).

### Trim Progression to Pure Short (Forward-Looking TRIM)

With v1.420, TRIM brings ML to exactly 66% at each price level. The max sustainable net at price P is `equity / (0.66 × P)`. As SOL drops, equity grows from net short P/L and margin per lot decreases — both effects accelerate trimming.

**Key insight:** Closing a hedge position doesn't change equity (unrealized P/L becomes realized). So TRIM can be computed purely from equity, margin, and price at each level.

| SOL Price | Hedge (Long) | Net Short | Lots Trimmed | Gross | Equity | ML | Spread Tol. | Status |
|---|---|---|---|---|---|---|---|---|
| **$85 (now)** | **18,212** | **1,276** | **1,276** | **37,700** | **$72,000** | **66%** | **$1.91** | At threshold |
| $80 | 18,004 | 1,484 | 208 | 37,492 | $78,380 | 66% | $2.09 | **Overnight safe** |
| $70 | 17,470 | 2,018 | 534 | 36,958 | $93,220 | 66% | $2.52 | Safe |
| $60 | 16,624 | 2,864 | 846 | 36,112 | $113,400 | 66% | $3.14 | Comfortable |
| $50 | 15,184 | 4,304 | 1,440 | 34,672 | $142,040 | 66% | $4.10 | Very safe |
| $40 | 12,477 | 7,011 | 2,707 | 31,965 | $185,080 | 66% | $5.79 | Growing fast |
| $30 | 6,600 | 12,888 | 5,877 | 26,088 | $255,190 | 66% | $9.78 | Accelerating |
| **$25** | **116** | **19,372** | **6,484** | **19,604** | **$319,630** | **66%** | **$16.30** | Nearly pure |
| **~$25** | **0** | **19,488** | **116** | **19,488** | **$320,792** | **97%** | **$16.46** | **PURE SHORT** |
| $20 | 0 | 19,488 | — | 19,488 | $414,070 | 106% | $21.25 | Printing |
| $10 | 0 | 19,488 | — | 19,488 | $608,950 | 313% | $31.25 | Locked in |
| $5 | 0 | 19,488 | — | 19,488 | $706,390 | 725% | $36.25 | Locked in |
| **$0** | **0** | **19,488** | **—** | **19,488** | **$803,830** | **∞** | **∞** | **Done** |

**Cumulative hedge lots trimmed: 18,212** (from $85 entry to various closing prices)
**Average hedge closing price: ~$35** (most lots close at lower prices where trim accelerates)

### How TRIM Pacing Works

TRIM brings ML to 66% then waits for price movement to create more room:

| SOL Drop | Equity Gained (from net) | New Room | Lots Trimmed | Trim Accelerates? |
|---|---|---|---|---|
| $85 → $80 | $6,380 (1,276 × $5) | $6,380 | 208 | Slow — small net |
| $80 → $70 | $14,840 (1,484 × $10) | $14,840 | 534 | Moderate |
| $70 → $60 | $20,180 (2,018 × $10) | $20,180 | 846 | Building |
| $60 → $50 | $28,640 (2,864 × $10) | $28,640 | 1,440 | Significant |
| $50 → $40 | $43,040 (4,304 × $10) | $43,040 | 2,707 | Fast |
| $40 → $30 | $70,110 (7,011 × $10) | $70,110 | 5,877 | Rapid |
| $30 → $25 | $64,440 (12,888 × $5) | $64,440 | 6,600 (all) | **Complete** |

**The flywheel:** Each $1 SOL drop → shorts profit → equity up → more TRIM room → more net → next $1 drop earns more. The trim rate compounds as the position unwinds.

### Key Milestones

- **$80**: Spread tolerance crosses $2.00/lot → **overnight safe**
- **$50**: Equity $142K, spread tolerance $4.10 → deeply safe, TRIM accelerating
- **$30**: Equity $255K, 64% of hedge consumed → home stretch
- **$25**: **PURE SHORT** — all 18,212 hedge lots consumed. Equity $321K. Position is locked profit from here
- **$0**: Equity **$804K** — total profit **$732K** (11.2x return on $72K)

### Overnight Safety

With forward-looking TRIM (v1.420), ML stays at 66% during active trimming. Overnight safety depends on **spread tolerance** (equity / gross), not ML:

| SOL Price | Gross | Equity | Spread Tol. | Overnight? |
|---|---|---|---|---|
| **$85 (now)** | **37,700** | **$72,000** | **$1.91** | **Borderline — close to $2.00** |
| $80 | 37,492 | $78,380 | $2.09 | **Yes — above $2.00** |
| $70 | 36,958 | $93,220 | $2.52 | Yes |
| $50 | 34,672 | $142,040 | $4.10 | Very safe |

**At current price ($85), spread tolerance is $1.91/lot — slightly below the $2.00 safety rule.** Overnight is borderline. A $3 SOL drop to $82 would bring tolerance to ~$2.10. Once past $80, the position is safely overnight-able and only gets safer.

---

### Scenario A: Standard Short (No Hedging)

With $72,000 equity, 1:1 crypto margin, and 200% margin level (minimum to survive any volatility):

**Maximum position at open:**
- SOLUSD: ~424 lots short @ $85

#### Profit if SOL hits $0

| Asset | Short Lots | Entry | Profit |
|-------|-----------|-------|--------|
| SOLUSD | 424 | $85 | $36,040 |

**Return: $36,040 on $72,000 = 0.50x (50% return)**

The position can't grow because there's no mechanism to add lots. You hold a fixed position and wait.

---

### Scenario B: SOLUSD Hedged Martingale

#### Position Structure

The hedge: ~18,212 long lots vs 19,488 short lots on SOLUSD. Net short exposure is ~1,276 lots. The broker charges margin on net exposure only — not gross. Gross (~37,700) still determines spread tolerance for equity swings.

The EA manages this automatically (v1.420 — forward-looking TRIM):
- **Above 66%**: TRIM — `maxSafe = floor((equity/0.66 - margin) / marginPerLot)` — closes only enough to bring ML to threshold
- **60%–66%**: Dead zone — EA does nothing, allows normal price action
- **Below 60%**: PROTECT — balanced close `ceil(hedgeLots × urgency)` per tick (scales with margin urgency)
- **Below 10%**: Hard floor — EA halts entirely, broker handles stop-out
- **No hedges left**: EA refuses to close bias — shorts are sacred

#### SOLUSD TRIM Behavior

PROTECT at 60%. TRIM at 66% (forward-looking). TRIM can **never** cascade into PROTECT — mathematically impossible.

#### Phase 1: $85 → $30 (Continuous TRIM, no bounces needed)

With forward-looking TRIM (v1.420), the EA doesn't need bounces to trim. It continuously closes hedge lots whenever ML is above 66%, self-pacing to maintain ML at exactly the threshold. Each SOL price drop creates room (equity grows from net short P/L + margin per lot drops).

**TRIM doesn't wait for profitable longs.** It closes the highest-cost hedge positions regardless of P/L — the goal is margin recovery, not trade profit. As SOL drops, hedge lots are closed at increasing losses, but equity grows faster from net short exposure.

| Price Range | Lots Trimmed | Avg Loss/Lot | Trim Cost | Equity After | Net Short |
|---|---|---|---|---|---|
| $85 → $80 | 208 | $2.50 | $520 | $78,380 | 1,484 |
| $80 → $70 | 534 | $10 | $5,340 | $93,220 | 2,018 |
| $70 → $60 | 846 | $20 | $16,920 | $113,400 | 2,864 |
| $60 → $50 | 1,440 | $30 | $43,200 | $142,040 | 4,304 |
| $50 → $40 | 2,707 | $40 | $108,280 | $185,080 | 7,011 |
| $40 → $30 | 5,877 | $50 | $293,850 | $255,190 | 12,888 |
| **Subtotal** | **11,612** | | **$468,110** | | |

**Phase 1 note:** Trim cost ($468K) is already accounted for in equity — closing doesn't change equity (unrealized → realized). The equity numbers above are the ACTUAL equity at each price level.

#### Phase 2: $30 → $0 (Pure short from ~$25)

Remaining ~6,600 hedge lots consumed between $30 and $25. Position becomes pure short at ~$25.

**$30 → $25:** Final 6,600 longs consumed — trim cost ~$363K (avg loss $55/lot). Equity: $321K.
- **DOGE shorts opened at maximum size**

**$25 → $0: Pure short**
- Each dollar down = 19,488 × $1 = **$19,488 profit per dollar**
- DOGE shorts adding to profits on every tick down
- No more trim costs — position is pure profit accumulation
- Equity: $321K → $609K → $804K

#### Final Close at $0

| Component | Lots | Profit |
|-----------|------|--------|
| SOLUSD shorts (19,488 × $85) | 19,488 | **$1,656,480** |
| Long trim costs (18,212 lots consumed) | 18,212 | **-$831K** |
| Starting equity | — | $72,000 |
| DOGE (opened after unwind) | TBD | TBD |
| **Final equity** | | **~$804,000** |
| **Net profit (SOL only)** | | **~$732,000** |

The long trim cost (~$831K) doesn't come out of equity at closing time — it was already accounted for as realized losses during the trim process. The $804K is the actual final account equity.

#### Total Cumulative Profit

| Component | Amount |
|-----------|--------|
| Final equity at SOL $0 | ~$804,000 |
| Starting equity | $72,000 |
| **SOL Net Profit** | **~$732,000 (11.2x)** |
| DOGE (opened after unwind) | TBD |

### SOLUSD Side by Side

| | Standard Short | Hedged Martingale |
|---|---|---|
| Starting equity | $72,000 | $72,000 |
| Max short lots (SOL) | 424 | 19,488 (held now) |
| Survives 10% spike? | NO (margin call) | YES (~18K long hedge absorbs) |
| Position grows over time? | NO (fixed) | YES (longs trimmed → net short grows) |
| Profits from volatility? | NO | YES (price drops create TRIM room) |
| Hedge removal cost | N/A | ~$831K (price of building 19.5K net short) |
| SOL profit if → $0 | **$36,040** | **~$732,000** |
| Return multiple | **0.50x** | **11.2x** |
| Final account value | ~$108,040 | **~$804,000** |


---

### Key Assumptions (SOLUSD)

1. **Continuous decline**: SOL trends from $85 → $0 with bounces along the way (conservative for crypto bear market)
2. **Execution**: EA trims longs automatically via forward-looking TRIM (v1.420), balanced PROTECT below 60%
3. **Spread noise**: ~$1.91/lot tolerance at current gross — borderline overnight, safe after $80
4. **No black swan recovery**: SOL does not recover permanently
5. **Margin management**: Forward-looking TRIM cannot push ML below its threshold (mathematically impossible). PROTECT at 60% leaves 10% buffer above 50% stop-out
6. **DOGE**: Opened at max size once SOL hedge is sufficiently unwound — both ride to $0
7. **Position structure**: ~18K long / 19.5K short SOL held. No new lots added below base — EA only trims the hedge
8. **PROTECT safeguards**: Hard floor (10%), dynamic lot sizing (scales with urgency), never closes bias
9. **Position sizing**: Gross lots must reach equity / $2.00 ($1.91 currently — borderline) before overnight is safe

### SOLUSD Multiplier Effect

```
Standard Short:
  $72K equity → 424 SOL lots → hold → $36K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale:
  $72K equity → 19,488 SOL short lots (hedged with ~18K longs)
    → Net short: 1,276 lots (nearly flat — survives any spike)
    → $85 → $80:  TRIM closes    208 longs → net short:  1,484 lots
    → $80 → $70:  TRIM closes    534 longs → net short:  2,018 lots
    → $70 → $60:  TRIM closes    846 longs → net short:  2,864 lots
    → $60 → $50:  TRIM closes  1,440 longs → net short:  4,304 lots
    → $50 → $40:  TRIM closes  2,707 longs → net short:  7,011 lots
    → $40 → $30:  TRIM closes  5,877 longs → net short: 12,888 lots
    → $30 → $25:  TRIM closes  6,600 longs → net short: 19,488 lots (PURE SHORT)
    → DOGE shorts opened at max size
    → SOL hits $0: close all        → $732K net profit (11.2x) plus DOGE
  [Forward-looking TRIM: each SOL drop creates room → more hedge closes → bigger net
   → next drop earns more. The flywheel compounds. Longs are fuel, shorts are profit.]
```

---

### VaR Dynamics: The Darwinex Amplifier

#### How VaR Is Calculated

```
VaR = 1.65 × StdDev(daily returns) × NominalValue

NominalValue = |PositionSize| × (TickValue / TickSize) × CurrentPrice
```

**VaR is tethered to price.** As the underlying asset price drops, the nominal value of the position shrinks, and VaR shrinks with it. This is independent of P/L — it's a function of what you can lose from *here*, not what you've already gained.

#### VaR Through the Phases

#### Phase 1: SOL $87 → $20

Current net short: ~1,276 lots (growing as forward-looking TRIM unwinds hedges)

| SOL Price | Net Short Lots | Nominal Value | VaR (est. 5% daily vol) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------------------|---------------|-----------------|
| $85 | 1,276 | $108,460 | $8,948 | $72,000 | 12.4% |
| $70 | 2,018 | $141,260 | $11,654 | $93,220 | 12.5% |
| $50 | 4,304 | $215,200 | $17,754 | $142,040 | 12.5% |
| $40 | 7,011 | $280,440 | $23,136 | $185,080 | 12.5% |
| $30 | 12,888 | $386,640 | $31,898 | $255,190 | 12.5% |

*VaR stays remarkably stable as % of equity (~12.5%) during the trim phase because forward-looking TRIM maintains ML at exactly 66%. Both net exposure and equity grow proportionally.*

#### Phase 2: SOL $20 → $0 (The Lock-In)

**Once longs are fully unwound at ~$25, shorts are pure profit with collapsing VaR:**

| SOL Price | Net Short Lots | Nominal Value | VaR (est.) | Equity (est.) | VaR % of Equity |
|-----------|---------------|---------------|------------|---------------|-----------------|
| $25 | 19,488 | $487,200 | $40,194 | $320,792 | 12.5% |
| $20 | 19,488 | $389,760 | $32,155 | $414,070 | 7.8% |
| $15 | 19,488 | $292,320 | $24,116 | $511,510 | 4.7% |
| $10 | 19,488 | $194,880 | $16,077 | $608,950 | 2.6% |
| $5 | 19,488 | $97,440 | $8,039 | $706,390 | 1.1% |
| $2 | 19,488 | $38,976 | $3,216 | $764,926 | 0.4% |
| $0 | 19,488 | $0 | $0 | $803,830 | 0.00% |

**Once longs are unwound, VaR can only decrease.** Every tick down:
- Nominal value shrinks → VaR shrinks
- Equity grows (shorts profiting) → VaR % shrinks even faster
- The profit is locked — there is nothing left to lose in the direction of the thesis

#### The Darwinex Risk Multiplier Effect

Darwinex normalizes all DARWINs to a target VaR band of **3.25% — 6.5% monthly** (95% confidence):

```
Target VaR = (Current VaR / Max VaR in lookback) × 6.5%

Risk Multiplier = Target VaR / Strategy VaR
```

#### How This Applies to the Strategy

**Phase 1 ($87 → $20): Stable VaR, Moderate Dampening**

With forward-looking TRIM maintaining ML at 66%, VaR stays stable at ~12.5% of equity:

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

#### The Lock-In Moment

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

#### VaR Impact on DarwinIA Allocation

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

#### Combined Profit with Darwinex Amplification

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

### Complete SOLUSD Comparison (with Darwinex)

| | Standard Short | Hedged Martingale | Hedged + Darwinex |
|---|---|---|---|
| Starting equity | $72,000 | $72,000 | $72,000 |
| Max short lots (SOL) | 424 | 19,488 (held now) | 19,488 (held now) |
| Survives 10% spike? | NO | YES (~18K long hedge) | YES |
| Position grows? | NO | YES (net short grows) | YES |
| VaR trajectory | Flat | Stable 12.5% → compressing | Stable → compressing → amplified |
| Risk multiplier | N/A | N/A | 0.47x → 9.75x |
| Hedge removal cost | N/A | -$831,000 | -$831,000 |
| SOL signal profit | $36,040 | ~$732,000 | ~$732,000 |
| DOGE | — | TBD (after unwind) | TBD (after unwind) |
| DARWIN amplified returns | N/A | N/A | $1,800,000+ on DARWIN |
| DarwinIA fee income | N/A | N/A | $50,000 — $200,000 |
| Return multiple (SOL only) | 0.50x | **11.2x** | 11.2x + DOGE + fees |

---

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
TRIM:    maxSafe = floor((equity/0.65 - margin) / marginPerLot)  — forward-looking, can never overshoot
PROTECT: close size = ceil(totalHedgeLots × urgency), urgency = max(1 - ML/threshold, 0.01)
```
Replaces the fixed closes and circuit breaker. Forward-looking TRIM (v1.420) computes exactly how many lots can be closed before ML hits threshold — mathematically impossible to cascade into PROTECT. PROTECT urgency scales with danger level — no tuning needed.

---

### Post-Mortem #2: The 55% PROTECT Cascade (2026-03-03)

#### What Happened

With 83K gross lots (41K L / 42K S), PROTECT at 55% with 1-second cooldown proved insufficient. ML was hovering at 59.6% with TRIM at 59% slowly removing longs. A spread-driven ML dip triggered a cascade.

**Timeline:**

1. **ML dips below 55%**: PROTECT begins firing. Each balanced close removes 10L + 10S — only 0.024% of the 83K gross. ML barely moves.

2. **30 fires in 58 seconds**: PROTECT consumed all 30 circuit breaker fires in under a minute. Total: 300 lots removed from each side (600 lots total). ML stayed at 56-57% throughout — the closes were too small relative to gross exposure to recover ML above the 57% deactivation midpoint.

3. **Circuit breaker trips**: PROTECT auto-disabled after fire #30. But the damage was done — 600 lots gone, and ML still dangerously low.

4. **Broker intervenes**: Broker closed additional positions. ML jumped to 216% after forced liquidation.

5. **EA restarts**: Position stabilized at 39,870 L / 40,910 S. ML at 70%. TRIM resumes at 60%.

#### Post-Mortem #2b: Broker Liquidation During TRIM (2026-03-03)

After rebuilding to 45K L / 46K S, trimming at 60% with PROTECT at 54% caused a second broker intervention. Each trim closed a **losing** long (-$350 to -$520 per 20 lots), which:
1. Reduced equity (realized loss)
2. Reduced hedge netting → more unhedged shorts → higher margin requirement
3. Both effects pushed ML **down** while trimming — the opposite of the intended effect

The broker closed 1,000 short lots when ML dropped below their threshold during active trimming. Resolution: raise TRIM to 61% so trimming only starts when ML has enough headroom.

#### Post-Mortem #2c: PROTECT Oscillation at 61/56 and 60/56 (2026-03-04)

At 60/56 (4% dead zone), PROTECT fired 5 times due to spread-driven ML oscillation. The deactivation midpoint was (60+56)/2 = 58%, leaving only 2% between midpoint and TRIM. Spread noise of 1.5% easily bridged this gap, causing:
1. ML drops below 56% → PROTECT fires
2. ML recovers above 58% → PROTECT deactivates
3. Spread pushes ML back below 56% → PROTECT fires again

Similarly at 61/56, midpoint was 58.5%, gap to TRIM was 2.5% — still within spread noise.

**Resolution:** Raise TRIM to 62/56 to widen the dead zone. Later, the midpoint deactivation system was removed entirely — PROTECT now deactivates as soon as ML recovers above the threshold (55%). This eliminated the excessive firing at 57-58% ML that the midpoint caused.

#### Root Causes

1. **1-second cooldown too short at 83K gross**: 30 fires in 58 seconds exhausted the circuit breaker before the market could recover. At this gross exposure, each fire is meaningless — 10 lots out of 83K can't move ML.

2. **PROTECT threshold too close to operating range**: With 1.5% spread-induced ML swings, PROTECT was easily triggered by a slightly wider spread.

3. **Deactivation midpoint too close to TRIM**: The midpoint system kept PROTECT firing at 57-58% ML (safely above danger). Later removed — PROTECT now deactivates at threshold (56%), not midpoint.

4. **Trimming underwater longs pushes ML down**: Closing longs at a loss reduces equity AND reduces hedge netting. At 60% TRIM with ML barely above threshold, trimming itself can trigger broker intervention.

#### Resolution: Dynamic TRIM with Fixed PROTECT

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

### Post-Mortem #3: Overnight Spread Spike Wipe (2026-03-03/04)

#### What Happened

With 89K gross lots (44K L / 45K S) on $60K equity, an overnight spread spike destroyed the account. Settings were 64/55 with 5s cooldown.

**Timeline:**

1. **23:06 — Spread spike**: ML crashed from 64% to **7.3% instantly** in a single tick. The spread widened enough to consume ~$34K of margin on 89K gross lots.

2. **PROTECT fires once**: EA correctly identified the crisis. Hard floor kicked in at 6% — EA stood down.

3. **Broker liquidation**: Broker force-liquidated ~88K lots, leaving only ~1,000 shorts.

4. **04:14 — Wild position swings**: Positions appeared and disappeared as the broker continued unwinding. Account gutted to **$16,656**.

#### Root Cause

**Position was 4x too large for the equity.** All EA safeguards worked correctly:
- Hard floor correctly halted PROTECT at 6%
- EA stood down and let broker handle it
- Never closed bias

The fundamental problem: 89K gross lots on $60K equity = **$0.67/lot spread tolerance**. Any significant spread widening exceeds equity. The $2.00/lot overnight spread was 3x the tolerance.

#### The Position Sizing Rule

```
Max safe gross lots = Equity / $2.00

$60,000 / $2.00 = 30,000 max safe gross lots
Actual gross: 89,000 — nearly 3x over the limit
```

No amount of TRIM/PROTECT tuning can save a position that is fundamentally too large for the equity. The EA can manage spread noise, prevent cascades, and handle normal market moves. But catastrophic overnight spread spikes require the position itself to be within safety limits.

#### Lessons Learned

1. **Position sizing is the ultimate safety mechanism.** TRIM/PROTECT/cooldown/circuit breaker are secondary defenses. The primary defense is keeping gross lots below equity / $2.00.

2. **Overnight spread spikes are catastrophic at scale.** A $2.00 spread on 89K lots = $178K impact on a $60K account. No EA can survive this.

3. **All EA safeguards worked correctly.** The hard floor, circuit breaker, bias protection, and cooldown all performed as designed. The account was lost because the position was too large, not because the EA failed.

4. **Fresh account rule: build to safe size, never beyond.** Never open gross lots above equity / $2.00 — this is the only defense that matters.

---

### Post-Mortem #4: Full Liquidation While Away (2026-03-05)

#### What Happened

With 83K gross lots (41.1K L / 42.3K S) on $72K equity, a spread spike while away destroyed the entire position. Settings were 66/56 with 15s cooldown. ML was at 66.3% just before stepping away.

**Timeline:**

1. **11:09 — Last trim**: TRIM fired at 66.3% ML, equity $74,975. Everything normal.

2. **17:05:02 — Spread spike**: ML crashed from ~66% to **4.7% instantly**. No visible price movement on the chart — pure spread widening.

3. **PROTECT fired once** at 4.7% ML. Hard floor immediately halted PROTECT (below 10%).

4. **17:05:04 — Full broker liquidation**: Broker closed ALL positions — 41,110 longs and 42,340 shorts. Hedge: 0, Bias: 0. Equity: **$45,723** (down from $75K).

5. **Balance increased by $8,098** — broker closing profitable shorts realized gains, partially offsetting the spread damage.

#### Root Cause

**Same as Post-Mortem #3: position was 2.4x over the safe limit.**

```
$72,264 / $2.00 = 36,132 max safe gross
Actual gross: 83,450 — 2.3x over the limit
Spread tolerance: $0.87/lot — a $0.87 spread wipe = total margin failure
```

The spread spike was invisible on the price chart. SOL showed no abnormal price action at 17:05. The spread widened for seconds, consumed all margin on 83K gross, and returned to normal. The chart shows nothing.

#### Why This Keeps Happening

Five liquidation events — all the same cause:

| Event | Gross | Equity | Tolerance | Over Limit |
|---|---|---|---|---|
| PM#3: Overnight wipe | 89K | $60K | $0.67/lot | 2.97x |
| Broker liquidation (03-04) | 110K | $69K | $0.63/lot | 3.19x |
| PM#4: Away wipe | 83K | $72K | $0.87/lot | 2.30x |
| **PM#5: Active monitoring** | **~38K** | **$72K** | **$1.91/lot** | **1.05x** |

PM#5 is notable: spread tolerance was almost exactly at $2.00 — the "safe" limit. Proves that $2.00 is the minimum, not a comfortable margin. Every time: EA safeguards worked correctly but couldn't prevent what position sizing should have prevented.

#### The Invisible Killer

Spread spikes don't appear on price charts. They last 1-5 seconds. At safe sizing ($2.00/lot tolerance), a spread spike costs margin temporarily but ML recovers. At 2x+ over the limit, the same spike is fatal.

**There is no EA setting, no dead zone width, no cooldown, no circuit breaker that protects against spread spikes on an oversized position.** The position sizing rule is the ONLY defense.

#### Lessons Confirmed (Third Time)

1. **The $2.00/lot rule is not optional.** Three accounts have been damaged or destroyed by ignoring it. No EA configuration compensates for oversized positions.

2. **"I'll trim down to safety" doesn't work.** The spike always comes before the trimming is done. Even with v1.415 dynamic lot sizing (aggressive closes with headroom), trimming requires sustained ML above the threshold — the spread spike doesn't wait.

3. **Opening at max intensity above the rule is the fundamental error.** The entry rules say "gross set to equity / $2.00 on day one." Every position that exceeded this was liquidated.

4. **Equity $45,723 is salvageable.** Enough to rebuild within the sizing rule: 22.8K gross = 11.4K per side.

---

### Post-Mortem #5: Spread Spike During Weekend Prep (2026-03-06)

#### What Happened

After rebuilding from PM#4 ($45.7K → re-hedge at ~21K/side, trimmed to ~20K/21.4K, equity ~$78.5K), a spread spike during active monitoring destroyed the position again. Settings were 60/56 (tightened for active monitoring after v1.420 deployment).

**Timeline:**

1. **~13:30 — Active trimming**: TRIM firing at 60% ML, equity ~$72K. 95 trim closes completed. Everything working correctly.

2. **13:46 — Spread spike**: ML crashed from ~60% to **36.2% instantly**. No visible price movement.

3. **PROTECT fired once** at 36.2% ML — closed 463 longs + 702 shorts. Hard floor immediately halted PROTECT (ML hit 9.4%).

4. **Broker liquidated everything** except the original 1,100 short lots (bias). All hedge longs and additional shorts gone. Equity: **~$72,000**.

5. **Re-hedge via Open MG**: Placed 19,488/side at ~$85. v1.420 TRIM closed ~1,276 lots, settling at 66% ML. Settings widened to 66/60.

#### Root Cause

**Same as PM#3 and PM#4: spread tolerance at the boundary.**

```
Spread tolerance at time of spike: ~$1.91/lot
Gross lots: ~37,700
A $1.91 spread spike = total margin failure on this gross
```

#### PROTECT Unbalanced Close (Bug Observed)

PROTECT fire closed 463 longs + 702 shorts — **not balanced** despite the code intending balanced closes. Possible causes:
- Some positions were already being closed by TRIM when PROTECT fired
- Broker execution timing differences between long and short close orders
- Further investigation needed

#### Lessons (Fifth Time)

1. **$1.91/lot is not safe for any duration** — even "active monitoring" can't react to a sub-second spike
2. **The $2.00 rule applies to ALL timeframes**, not just overnight
3. **PROTECT and hard floor worked correctly** — saved the 1,100 bias shorts
4. **Settings widened to 66/60** for the rebuild — more buffer, slower trimming, but safer
5. **Equity stabilized at ~$72K** — the account is resilient due to bias preservation

#### Monday Plan (2026-03-09)

| Setting | Value | Rationale |
|---|---|---|
| TRIM | 66% | Conservative — slow, safe trimming |
| PROTECT | 60% | 10% buffer above margin call |
| Target | Wait for SOL to drop to $80 | Spread tolerance crosses $2.00 → overnight safe |
| If stable | Tighten TRIM to 63% | Faster trimming once position is safer |

**Key**: The position gets permanently safer as SOL drops. At $80, spread tolerance = $2.09/lot and improving every tick.

---

### Liquidation Triggers: Known, Observed, and Speculated

Five post-mortems have revealed that **margin level is cosmetic with net-based margin** — the broker charges margin on net exposure only, so ML can show 60%+ while the position is fatally exposed to spread risk on the full gross. This section catalogs every known and suspected way the broker can liquidate a position.

#### Known Triggers (Confirmed from 5 Post-Mortems)

| Trigger | Mechanism | Confirmed In |
|---|---|---|
| **ML < 50% stop-out** | Broker's published margin call level. Once equity/margin < 50%, broker begins force-liquidating | All PMs |
| **Spread spike → equity collapse** | Spread widens on ALL lots (gross-based), not just net. At $0.87-1.91/lot tolerance, a sub-$2 spread wipe = total margin failure | PM#3, PM#4, PM#5 |
| **Full position liquidation** | Broker closes EVERYTHING — not partial, not just enough to restore ML. All longs and all shorts gone in seconds | PM#3, PM#4 |
| **Invisible on chart** | Spread spikes don't appear on price charts. No abnormal candle, no wick, no gap. Lasts 1-5 seconds | PM#4 |

#### Known Broker Behaviors (Observed)

| Behavior | Details |
|---|---|
| **Liquidates entire position** | Even when closing half would restore ML, broker closes all. Possible risk-aversion policy for crypto |
| **Speed of execution** | PM#4: from 66% ML to 0 lots in ~2 seconds. No human reaction possible |
| **Balance increases on liquidation** | Closing profitable shorts realizes gains. PM#4: balance went UP by $8,098 even as equity dropped $30K |
| **Net-based margin is cosmetic** | ML shows 62-126% on heavily hedged positions, but spread tolerance is $0.47-0.87/lot — fatal |
| **No warning** | No margin call email, no alert, no pre-liquidation notice. Just gone |

#### The Real Risk Metric

**ML is NOT the survival metric. Spread tolerance is.**

```
Spread tolerance = Equity / Gross lots

$72,000 / 37,700 gross = $1.91/lot  ← current position (borderline)
$72,000 / 37,700 gross = $1.91/lot  ← PM#5 (liquidated — even ~$2.00 isn't safe enough)
$72,264 / 83,450 gross = $0.87/lot  ← PM#4 (liquidated)
$60,000 / 89,000 gross = $0.67/lot  ← PM#3 (liquidated)

Safe minimum: $2.00/lot (survives overnight spreads)
```

ML can show 65% (looks safe) while spread tolerance is $1.90/lot (borderline). The broker's margin calculation uses net exposure, but spread risk hits gross exposure. These are fundamentally different numbers.

#### Speculated Triggers (To Research and Avoid)

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

#### Fresh Account Safety Framework

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

#### The Paradox of Net-Based Margin

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

### Fresh Account Sizing (Crypto Lessons)

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

## Pivot: CFD Commodities (March 2026)

### Why CFD Instead of Crypto

Five spread-spike liquidations across three $100K accounts proved that **crypto spread behavior is fundamentally incompatible with the hedged martingale at scale**. The EA logic (forward-looking TRIM, dynamic PROTECT, hard floor, bias protection) works perfectly — the problem is crypto-specific:

| Issue | Crypto (SOLUSD) | CFD Commodities |
|---|---|---|
| Spread spikes | Violent, invisible, sub-second, 10-100x normal | Predictable, correlated with scheduled events (EIA, OPEC) |
| Spread spike frequency | Random — any time, any day | Concentrated around news releases and session opens |
| Margin model | 1:1 (no leverage) — need massive lot counts | 5:1 leverage — fewer lots, same notional exposure |
| Position sizing sensitivity | $2.00/lot tolerance barely survivable | Higher tolerance per lot due to contract multiplier |
| Market hours | 24/7 — no safe window | Defined hours — daily close, weekend close |

### New Account Setup

| Parameter | Value |
|---|---|
| Account | $100K virtual Darwinex Zero CFD |
| Leverage | x5 (20% margin) |
| Margin model | Net-based (hedge account, same as crypto) |
| Margin call | 50% stop-out |
| EA | TyphooN v1.420 — same forward-looking TRIM, no code changes needed |

### TRIM Threshold Adjustment for x5 Leverage

**Critical: The default 65/56 TRIM/PROTECT settings are too tight for x5 leverage.**

With 1:1 margin (crypto), a 5.7% adverse price move uses ~6% of dead zone. Safe.

With 5:1 margin (CFD), a **2% adverse price move** pushes ML from 65% straight to 56% — PROTECT fires immediately. The x5 leverage amplifies margin sensitivity ~3x.

| Setting | Crypto (1:1) | CFD (5:1) | Why |
|---|---|---|---|
| TRIM | 65-66% | **80%** | Equivalent dead zone sensitivity |
| PROTECT | 56-60% | **56%** | Same buffer above 50% stop-out |
| Dead zone | 6-10% | **24%** | Absorbs leveraged price swings |
| Hard floor | 10% | **10%** | Universal |

With TRIM 80% and PROTECT 56%, a 5.7% adverse move uses ~10% of the 24% dead zone — similar behavior to SOL's 65/56 at 1:1.

---

## Candidate Instruments

### Ranked by Martingale Suitability

**1. XNGUSD (Natural Gas) LONG — Best Setup**
- Structural demand floor from crypto mining + AI data centers
- Clear seasonal pattern: spring low ($2.80-3.00) → winter high ($5-10+)
- Limited downside (structural floor ~$2.00-2.50), multiple upside catalysts
- Entry target: April 2026 spring seasonal low

**2. XAGUSD (Silver) SHORT → then LONG from bottom**
- ATH $121.67 (Jan 2026) → crashed to $65 → recovering to ~$84
- Currently short SLV and in profit — ride to $75 support
- Flip long from monthly bottom ($69-75) with martingale
- Long-term bull consensus: $112-119 year-end, BofA $309 target
- Better as second trade — limited short runway from $84

**3. UKOIL/USOIL (Oil) LONG — Pass at Current Levels**
- Oil at ~$98 (WTI), already moved from $55 on Strait of Hormuz crisis
- Binary ceasefire risk: Hormuz reopens → oil crashes $30+ in days
- IEA released 400M barrels from strategic reserves — ceiling on upside
- 4.236 fib extension targets ~$149 (confluence with 2008 ATH $147.27)
- Revisit only if oil pulls back to $65-70 on ceasefire, then re-entry on next catalyst

---

## Simulation: XNGUSD Long — Fresh $100K CFD Account (Real Broker Data)

### Confirmed Broker Data (2026-03-13)

| Parameter | Value | Source |
|---|---|---|
| Account | $100K Darwinex Zero CFD | Account setup |
| Margin per 0.10 lot | **$316.40** | Live broker query |
| Margin per 1.00 lot | **$3,164.00** | Derived |
| Volume min | 0.10 | Broker spec |
| Volume step | 0.10 | Broker spec |
| VaR per 0.10 lot | $145.00 (daily, 95%) | Live broker query |
| Effective leverage | ~1:9.5 on XNGUSD | Implied from margin |
| Contract size | **10,000 MMBtu per lot** (implied from margin + VaR) | Confirm via ExportSymbols.mq5 |
| Margin model | Net-based (hedge account) | Broker spec |
| Margin call | 50% stop-out | Broker spec |
| XNGUSD Entry | ~$3.00 (spring seasonal low) | Target |
| Target | $10.00 (4.236 fib extension — seasonal high) | Technical |

**Contract size derivation:** Margin = lots × CS × price / leverage. $3,164 = 1.0 × CS × $3.00 / L. VaR confirms: $145 ≈ 1.65 × 0.03 × 0.10 × 10,000 × $3.00 = $148.50. CS = **10,000 MMBtu** with ~9.5:1 effective leverage on XNGUSD. **Run ExportSymbols.mq5 to confirm — if CS = 1,000, divide all profits by 10.**

**Derived values at 10,000 MMBtu per lot:**
- Tick value: 10,000 × $0.001 = **$10 per tick per lot**
- $1.00 price move = **$10,000 per lot**
- Margin per lot at price P ≈ $3,164 × (P / $3.00)

### Classic Doubling Martingale Reference (from lot simulation)

For reference, a classic 2x doubling martingale starting at 0.10 lots:

| Level | Lots | Margin | Cum Lots | Cum Margin | % Balance | Status |
|---|---|---|---|---|---|---|
| 1 | 0.10 | $316.40 | 0.10 | $316.40 | 0.32% | Safe |
| 2 | 0.20 | $632.80 | 0.30 | $949.20 | 0.95% | Safe |
| 3 | 0.40 | $1,265.60 | 0.70 | $2,214.80 | 2.21% | Safe |
| 4 | 0.80 | $2,531.20 | 1.50 | $4,746.00 | 4.75% | Safe |
| 5 | 1.60 | $5,062.40 | 3.10 | $9,808.40 | 9.81% | Safe |
| 6 | 3.20 | $10,124.80 | 6.30 | $19,933.20 | 19.93% | Caution |
| **7** | **6.40** | **$20,249.60** | **12.70** | **$40,182.80** | **40.18%** | **Max safe** |
| 8 | 12.80 | $40,499.20 | 25.50 | $80,682.00 | 80.68% | Danger |
| 9 | 25.60 | $80,998.40 | 51.10 | $161,680.40 | 161.68% | IMPOSSIBLE |

**Max safe depth: 7 levels** (12.70 lots, $40,183 margin, 40% of balance). Level 8 is technically possible but leaves <20% free margin. Level 9 exceeds account balance. *This approach is NOT what the EA uses — included for reference only.*

---

### Scenario A: Full Tilt Long (No Hedge) — All Lot Levels

With $100K equity, entry at ~$3.00, margin per lot = $3,164:

| Lots | Margin | ML% | Free Margin | Survives Drop | Status |
|---|---|---|---|---|---|
| 1.00 | $3,164 | 3,162% | $96,836 | ~97% | Ultra safe |
| 2.00 | $6,328 | 1,581% | $93,672 | ~94% | Ultra safe |
| 3.00 | $9,492 | 1,054% | $90,508 | ~90% | Ultra safe |
| 5.00 | $15,820 | 632% | $84,180 | ~84% | Very safe |
| 7.00 | $22,148 | 452% | $77,852 | ~78% | Very safe |
| 10.00 | $31,640 | 316% | $68,360 | ~68% | Safe |
| 12.00 | $37,968 | 263% | $62,032 | ~62% | Safe |
| **15.80** | **$49,991** | **200%** | **$50,009** | **~50%** | **Recommended max** |
| 18.00 | $56,952 | 176% | $43,048 | ~43% | Moderate |
| 20.00 | $63,280 | 158% | $36,720 | ~37% | Caution |
| 22.00 | $69,608 | 144% | $30,392 | ~30% | Caution |
| 25.00 | $79,100 | 126% | $20,900 | ~21% | Warning |
| 28.00 | $88,592 | 113% | $11,408 | ~11% | Danger |
| 30.00 | $94,920 | 105% | $5,080 | ~5% | Danger |
| **31.60** | **$99,944** | **100%** | **$56** | **~0%** | **Absolute max** |

**"Survives Drop" = % price drop before 50% ML margin call.**

**Full tilt = 31.60 lots (100% ML)** — every dollar of equity used as margin. Any adverse move triggers margin call immediately. This is the absolute maximum the broker will allow.

#### Full Tilt Long — Profit at All Target Prices (31.60 lots, 100% ML)

| NG Price | Move | Profit/Lot | Total Profit | Final Equity | Return |
|---|---|---|---|---|---|
| $3.10 | +$0.10 | $1,000 | $31,600 | $131,600 | 1.32x |
| $3.25 | +$0.25 | $2,500 | $79,000 | $179,000 | 1.79x |
| $3.50 | +$0.50 | $5,000 | $158,000 | $258,000 | 2.58x |
| $4.00 | +$1.00 | $10,000 | $316,000 | $416,000 | 4.16x |
| $5.00 | +$2.00 | $20,000 | $632,000 | $732,000 | 7.32x |
| $6.00 | +$3.00 | $30,000 | $948,000 | $1,048,000 | 10.48x |
| $7.00 | +$4.00 | $40,000 | $1,264,000 | $1,364,000 | 13.64x |
| $8.00 | +$5.00 | $50,000 | $1,580,000 | $1,680,000 | 16.80x |
| **$10.00** | **+$7.00** | **$70,000** | **$2,212,000** | **$2,312,000** | **23.12x** |

**WARNING: At 100% ML, the FIRST adverse tick triggers margin call.** There is zero buffer. If NG drops $0.01 from entry, the broker may begin liquidating. This is only viable if you are certain the position moves in your favor immediately, or if you accept the risk of total loss on any dip.

---

### Actual Position: 48 Long / 41 Short (Opened 2026-03-16)

#### Current State (as of 2026-03-16 ~13:20 ET)

| | Value |
|---|---|
| Long lots | **48** |
| Short lots | **41** |
| Net long | **7** |
| Gross | **89** |
| Balance | $99,933 |
| Equity | **$17,937** |
| Margin | $21,677 (net 7 × ~$3,097) |
| ML | **82.7%** |
| Total P/L | **-$81,320** |
| NG Bid/Ask | $2.970 / $3.027 |
| Spread | **57 points** (tightened from 65 at open) |
| EA Mode | **MG: LONG** — TRIM 65, PROTECT 56 active |

**P/L breakdown:** ~$57,850 spread cost (89 gross × $650) + ~$23,470 adverse price movement (NG dropped from $3.135 entry to $2.970 bid). The spread has tightened from 65→57 points, partially recovering ~$7,120 (89 × 8pts × $10).

#### EA Configuration (XNGUSD — v1.420)

| Parameter | Value |
|---|---|
| Mode | **MG: LONG** |
| TRIM threshold | **65%** margin level |
| TRIM formula | `maxSafe = floor((equity/0.65 - margin) / marginPerLot)` |
| PROTECT threshold | **56%** margin level |
| Dead zone | 56%–65% (9% buffer) |
| Hard floor | 10% — PROTECT halts, broker handles it |
| Bias protection | Never closes bias (longs) in crisis |

#### TRIM Progression If Enabled (From Current Position)

With 48L/41S, net 7, equity $17,937 at $2.970. TRIM at 65% (ML currently 82.7% — above threshold, TRIM would fire).

At current price, TRIM can close **1 short** (brings net to 8, ML settles ~72%):
```
maxSafe = floor(($17,937/0.65 - $21,677) / $3,097) = floor(1.91) = 1
```

As NG price rises, equity grows from net long P/L → more TRIM room → more shorts closed → bigger net → flywheel:

| NG Price | Equity | Shorts | Net Long | ML | Status |
|---|---|---|---|---|---|
| **$2.97 (now)** | **$17,937** | **41** | **7→8** | **72%** | TRIM closes 1 short |
| $3.00 | $20,337 | 40 | 9 | 72% | Slow — low equity |
| $3.10 | $29,337 | 36 | 13 | 69% | Building |
| $3.20 | $42,337 | 30 | 19 | 68% | Accelerating |
| $3.30 | $61,337 | 22 | 27 | 67% | Fast |
| $3.40 | $88,337 | 12 | 37 | 66% | Rapid |
| **~$3.48** | **$120,000** | **0** | **48** | **~72%** | **PURE LONG** |
| $3.50 | $129,600 | 0 | 48 | 77% | Printing |
| $4.00 | $369,600 | 0 | 48 | 192% | Locked in |
| $5.00 | $849,600 | 0 | 48 | 354% | Locked in |
| $7.00 | $1,809,600 | 0 | 48 | 536% | Locked in |
| $10.00 | $3,249,600 | 0 | 48 | — | Strong |
| **$53.00** | **$23,889,600** | **0** | **48** | **—** | **TARGET** |

**Pure long at ~$3.48** — $0.51 above current price (17% rise needed). From there, every $1 NG rise = **$480,000** additional equity.

#### Key Insight: 48 Lots Is More Than We Planned

The original plan was 40/side. The actual position has **48 longs** — 20% more long lots than planned. This means at pure long, the position is significantly more powerful:

| | Planned (40/side) | Actual (48L/41S) |
|---|---|---|
| Long lots | 40 | **48** |
| Pure long at | ~$3.22 | ~$3.48 (higher due to more shorts) |
| Equity per $1 rise (pure) | $400,000 | **$480,000** |
| Equity at $10 | $2,793,000 | **$3,250,000** |
| Equity at $53 (TP) | — | **$23,890,000** |
| Return at $53 | — | **~239x** |

The tradeoff: more shorts to burn through (41 vs 16.70), so pure long is reached later ($3.48 vs $3.22). But once pure, 48 lots earns 20% more per dollar of NG rise.

#### Adverse Move Safety (From Current)

With net 8 at $2.97, equity $17,937:

| NG Price | Drop | Equity | ML | Status |
|---|---|---|---|---|
| $2.97 (now) | — | $17,937 | 72% | Dead zone |
| $2.95 | -0.7% | $16,337 | 67% | Dead zone |
| **$2.93** | **-1.3%** | **$14,737** | **56%** | **PROTECT fires** |
| $2.85 | -4.0% | $8,337 | ~10% | **Hard floor** |

**PROTECT at $2.93 (-$0.04).** With only $18K equity, PROTECT balanced closes will reduce gross quickly. The 41 shorts provide substantial hedge — each balanced close removes 1L+1S, preserving the net 8 long bias.

#### How TRIM Pacing Works (From Current)

| NG Move | Net Long | Equity Gained | Shorts Trimmed | Status |
|---|---|---|---|---|
| $2.97 (now) | 7 → 8 | — | 1 | Initial TRIM at 82.7% ML |
| $2.97 → $3.00 | 8 → 9 | $2,400 | 1 | Very slow — low equity |
| $3.00 → $3.10 | 9 → 13 | $9,000 | 4 | Building |
| $3.10 → $3.20 | 13 → 19 | $13,000 | 6 | Accelerating |
| $3.20 → $3.30 | 19 → 27 | $19,000 | 8 | Fast |
| $3.30 → $3.40 | 27 → 37 | $27,000 | 10 | Rapid |
| $3.40 → $3.48 | 37 → 48 | $37,000 | 11 (all remaining) | **PURE LONG** |
| $3.48 → $53.00 | 48 | $23,769,600 | — | Riding to target |

**The flywheel starts slow (only $18K equity, net 8) but accelerates as equity grows.** Each $0.10 rise adds ~$8K-$37K depending on current net. Once past $3.20, the acceleration is dramatic.

#### Key Milestones

- **$3.00**: Back above $20K equity, net 9 — survival confirmed
- **$3.10**: Equity $29K, net 13 — flywheel engaging
- **$3.20**: Equity $42K, net 19 — nearly half of shorts consumed
- **$3.30**: Equity $61K, net 27 — past the initial spread damage
- **$3.48**: **PURE LONG** — all 41 shorts consumed. Equity ~$120K. 48 lots riding free
- **$5.00**: Equity $850K
- **$10.00**: Equity $3.25M
- **$53.00**: Equity **$23.89M** — target reached. **~239x return on $100K**

---

## XNGUSD Long Thesis: Structural Demand

### Why Natural Gas Long is the Best Martingale Trade

Natural gas has a unique combination of **capped downside** and **multiple independent upside catalysts** — ideal for a directional martingale.

### Structural Demand Floor: Crypto Mining

Crypto mining operations (primarily Bitcoin) increasingly use natural gas turbines for power:

- **Stranded/flared gas** at wellheads now has a buyer — mobile mining containers convert waste gas to Bitcoin
- **Behind-the-meter** operations bypass grid constraints entirely
- Post-China ban, US dominates Bitcoin hashrate — Texas, North Dakota, Wyoming, Pennsylvania
- **Self-correcting demand floor**: when natgas is cheap, mining becomes MORE profitable → more miners deploy → more gas demand → price support

This creates a structural price floor at ~$2.00-2.50 that didn't exist before ~2020. As US crypto mining continues to grow (especially in energy-rich states), this floor strengthens over time.

### AI Data Center Demand

Natural gas supplies ~40% of US electricity. AI data center buildout is creating sustained baseload demand growth:

- Every major AI lab is building massive compute clusters
- Data centers require reliable 24/7 power — gas turbines are the primary source
- This demand is secular (growing for years), not cyclical
- Combined with crypto mining, this represents a structural shift in gas demand

### Seasonal Pattern

Natural gas follows a reliable seasonal cycle:

```
Spring (Mar-Apr): Seasonal low — heating demand drops, production steady
Summer (Jun-Aug): Moderate demand — cooling/power generation
Fall (Sep-Nov):   Building season — storage injections
Winter (Dec-Feb): Seasonal high — heating demand peaks, cold snaps spike price
```

**Entry target: April 2026 spring low (~$2.80-3.00)**. The seasonal pattern provides a natural timing framework — buy the spring low, ride to the winter high.

### Geopolitical Upside

The 2026 Strait of Hormuz crisis has disrupted Qatar LNG exports (20% of global supply). While US domestic gas is relatively insulated (export terminals at capacity), prolonged disruption could tighten the market as LNG export capacity expands.

### Combined Demand Stack

| Factor | Effect | Timeframe |
|---|---|---|
| Crypto mining at wellheads | Demand floor at $2.00-2.50 | Structural (permanent) |
| AI data center buildout | Sustained baseload demand growth | Structural (years) |
| Seasonal winter heating | Cyclical spikes to $5-10+ | Annual (Dec-Feb) |
| Hormuz LNG disruption | Supply reduction upside | Geopolitical (months) |
| US LNG export expansion | Growing export demand | Medium-term (2026-2028) |

**For the martingale:** Limited downside (structural floor) + multiple independent upside catalysts = asymmetric risk/reward. The hedge (short) side has limited room to run against you, while the bias (long) side has multiple paths to the target.

---

## Instrument Configuration Notes

### Contract Size (Confirmed via Margin Data)

**XNGUSD contract size: 10,000 MMBtu per lot** (implied from margin per lot = $3,164 at ~$3.00 with ~9.5:1 leverage, confirmed by VaR cross-check). Still recommended to verify via `ExportSymbols.mq5`.

If actual CS = 1,000 (unlikely given margin data):
- Divide all dollar profits by 10
- Multiply lot counts by 10
- Return ratios stay the same

### MartingaleSpreadTolerance Recalibration

The `$2.00` default is crypto-specific (1 lot = 1 unit, $2 spread = $2/lot). For CFDs:

```
SpreadTolerance = ContractSize × WorstExpectedSpread

XNGUSD (10,000 contract): 10,000 × $0.060 spike = $600/lot
XAGUSD (1,000 oz):        1,000 × $0.50 spike   = $500/lot  (estimate)
USOIL  (1,000 bbl):       1,000 × $0.30 spike   = $300/lot  (estimate)
```

Set `MartingaleSpreadTolerance` per instrument based on observed worst-case spread spikes. Confirm with live spread data.

### Settings Per Instrument

| Parameter | XNGUSD | XAGUSD | USOIL |
|---|---|---|---|
| TRIM | **65%** | 80% | 80% |
| PROTECT | **56%** | 56% | 56% |
| Open MG (SpreadTolerance) | **1250** | TBD | TBD |
| Margin/lot | **$3,164** | TBD | TBD |
| Actual spread | **65 points ($650/lot)** | TBD | TBD |
| Direction | LONG | SHORT → LONG | LONG |
| Entry timing | **March 15, 2026** | $75 or $69 support | $65-70 ceasefire pullback |

---

## Tonight's Entry Checklist (XNGUSD Long)

### EA Parameters — Set These

| Parameter | Value | Notes |
|---|---|---|
| **Mode** | **MG: LONG** | Longs = bias (sacred), shorts = hedge (fuel) |
| **TRIM threshold** | **65** | Aggressive — 9% dead zone above PROTECT |
| **PROTECT threshold** | **56** | Dynamic balanced close below this |
| **Hard floor** | **10** | Below this, EA stands down |
| **Open MG** | **1250** | $100K / $1,250 = 80 gross → 40 per side |

### What Happens After Open

1. **EA opens** 40 long + 40 short at market price (~$3.10)
2. **Spread cost:** 80 × $650 = $52,000 → equity drops to **$48,000**
3. **Net = 0, margin = $0, ML = ∞** (net-based margin)
4. **TRIM fires immediately** — closes 23.30 shorts to bring ML to 65%
5. **Position:** 40.00 long, 16.70 short, net 23.30 long, ML = 65%
6. **Monday US session:** spread tightens 65→5 → equity recovers ~$34K → **$82K**
7. **TRIM resumes** — closes remaining shorts rapidly
8. **Pure long at ~$3.22** — all shorts consumed, locked profit from there
9. **Target $10.00** → equity $2.79M → **27.9x return**

### Risk Awareness

- **PROTECT fires at ~$3.07** (1.0% drop / $0.03 from $3.10 entry) — tight, avoid EIA days
- **NG structural floor at $2.00-2.50** — below this is historically unprecedented
- **PROTECT balanced close is self-healing** — reduces gross, preserves net, increases spread tolerance
- **Spread recovery is significant** — $34K recovery when spread tightens from 65→5
- **Do NOT hold through EIA Wednesday 10:30am ET** without monitoring (nat gas storage report = spread spike risk)

---

## Bottom Line

### SOL Crypto Lessons (Historical)

Three $100K accounts, five spread-spike liquidations, $100K+ lost. The EA logic worked perfectly every time — forward-looking TRIM, dynamic PROTECT, hard floor, bias protection all fired correctly. The accounts were destroyed by **crypto's uniquely violent spread behavior** at insufficient spread tolerance. Key lesson: the $2.00/lot rule is necessary but not sufficient for crypto — even $1.91/lot tolerance was fatal (PM#5).

### CFD Commodities (Forward-Looking)

The same EA (v1.420) on commodity CFDs addresses every failure mode:

1. **~10x effective leverage** means fewer lots for the same notional — 40 lots controls $1.2M notional
2. **Predictable spread spikes** tied to scheduled events (EIA, OPEC) — not random invisible sub-second wipes
3. **TRIM at 65%** with PROTECT at 56% — aggressive 9% dead zone, viable because CFD spreads are predictable
4. **XNGUSD long** has the best risk/reward: structural demand floor (crypto mining + AI), seasonal pattern, geopolitical upside
5. **27.9x return potential** ($100K → $2.79M) on a $3.10 → $10 natgas move with 40/side — calibrated for 65-point structural spread
6. **Spread recovery:** entering at wide spread means equity recovers ~$34K when spread tightens during US hours — the spread tax is mostly temporary

**The martingale holds 1.6x more long lots than a safe full-tilt position (40 vs 25) and benefits from spread recovery. The 65-point spread costs $52K at entry but recovers $34K when liquidity returns — net cost ~$18K. Forward-looking TRIM builds net long exposure at the mathematically optimal rate. Pure long at just $3.22 — only $0.12 above entry. From there, every $1 natgas rise = $400,000 additional equity. The hedge shorts are fuel to burn, the bias longs are profit. TRIM self-paces at exactly 65% ML with the same forward-looking formula that proved reliable on SOL — calibrated for XNGUSD's structural spread.**
