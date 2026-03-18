# Hedged Martingale Strategy & Simulation

The hedged martingale exploits net-based margin to carry massive directional exposure via a hedge that is systematically trimmed as the thesis plays out. The EA (TyphooN v1.420) manages the position automatically via forward-looking TRIM and dynamic PROTECT.

**Current plan:** Operation SOL/ADA/DOGE → $0. **Phase 1: SOL ONLY** — grind hedge via TRIM 54/51 until pure short (~$60 SOL). **Phase 2:** Stack ADA + DOGE naked shorts after SOL hedge is fully consumed. **Phase 3:** All three ride to $0. One Darwinex Zero crypto account forever.
**Key lesson (PM#6):** No ADA/DOGE until SOL hedge is consumed. Multi-instrument positions amplify spread spike damage during hedge phase.
**Retired:** XNGUSD CFD long — martingale doesn't work at CFD lot sizes.
**Historical:** SOLUSD crypto short (PM#1-6) — six spread-spike events, lessons preserved below.

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

### Position State (from EA display 2026-03-18 ~14:07)

| | Value |
|---|---|
| Account | $100K Darwinex Zero Crypto (ONE ACCOUNT — no others) |
| SOL Price | ~$90 |
| Balance | $74,882 |
| Equity | $71,511 |
| Margin | $49,346 |
| ML | 144.9% → grinding down to 54.2% |
| **SOLUSD** | |
| Long (hedge) | 11,671 (TRIM grinding) |
| Short (bias) | **13,220** (17,960 opened, 4,740 lost to 3 PROTECT balanced closes) |
| Net Short | 1,549 |
| SOL Gross | 24,891 |
| TRIM closes | 87 |
| PROTECT closes | 3 (cost: 4,740 bias lots = $427K profit at $0) |
| **ADAUSD** | **CLOSED** — broker liquidated during PM#6 spread spike (profit realized to balance) |
| **DOGEUSD** | **NOT OPEN** — waiting until SOL hedge is fully consumed |

### EA Configuration (LOCKED — will not change until hedge is unwound)

| Parameter | Value |
|---|---|
| Mode | **MG: SHORT** |
| TRIM | **54.20691337%** |
| PROTECT | **50.96913420691337%** |
| Dead zone | **3.24%** (50.97%–54.21%) |
| Hard floor | **10.0%** |
| Open MG | **$2.00** |
| Bias protection | Never closes bias (shorts) in crisis |
| **Instruments** | **SOL ONLY** — no ADA/DOGE until pure short |

**These settings are FINAL until hedge is consumed.** No tightening, no burst trimming, no adding instruments. Let TRIM grind passively. Widen to 61/51 for overnight/AFK only.

### Post-Mortem #6: Spread Spike During Active TRIM (2026-03-18 10:56)

#### What Happened

While TRIM was grinding at 53/51 (2% dead zone), a spread spike crashed ML from ~53% through PROTECT (51%) straight to hard floor (10%). The broker liquidated all hedge longs and most bias shorts, plus the entire 200K ADA short position.

**Timeline:**
1. **10:53**: TRIM grinding normally, trim #119 at $89.12, ML ~53%
2. **10:56:11**: Spread spike → ML crashed below 51% → PROTECT fired
3. **10:56:11**: PROTECT balanced close: 162L + 162S
4. **10:56:12**: PROTECT balanced close: 420L + 718S (unbalanced — broker interference)
5. **10:56:12**: **PROTECT HALTED — ML 9.0% below hard floor 10%**
6. **10:56:13**: Broker liquidated remaining positions. "No hedges remaining — refusing to close bias"
7. **10:56:14**: ML recovered to 62.9%. Surviving: **0 hedge, 1,380 bias shorts**
8. Broker also closed 200K ADA short (in profit — realized to balance)

#### Root Cause

**Same as PM#1-5: spread spike on over-leveraged position with tight dead zone.**

The 53/51 settings (2% dead zone) provided no buffer for the spread spike. ML went from 53% → 9% in one tick — bypassing PROTECT entirely. The EA safeguards (hard floor, bias protection) worked correctly, preserving 1,380 shorts.

#### What Was Lost

| | Before Spike | After Spike | Lost |
|---|---|---|---|
| SOL hedge | 16,198 | 0 | 16,198 longs |
| SOL bias | 17,220 | 1,380 | **15,840 shorts** |
| ADA short | 200,000 | 0 | **200,000 lots** (profit realized) |
| Equity | $80,662 | $81,139 | +$477 (net gain — ADA profit offset SOL losses) |

**Equity actually increased** — the ADA profit realization and spread normalization offset the SOL losses. The account is intact, just with fewer positions.

#### Lesson Learned: No ADA/DOGE Until Hedge Is Consumed

**The ADA and DOGE shorts added margin load that made the spread spike worse.** With 200K ADA consuming ~$56K margin alongside the SOL hedge, the total margin was $128K+ on $78K equity — ML was already borderline.

**Rule: Do NOT open ADA or DOGE shorts while SOL hedge exists.**

The hedge creates massive gross exposure that is vulnerable to spread spikes. Adding ADA/DOGE on top:
1. **Increases total margin** — lowers ML, tighter to PROTECT
2. **Adds more positions for broker to liquidate** — broker closes everything in a spike, including profitable ADA
3. **Reduces spread tolerance** — more gross lots = less equity per lot = more vulnerable
4. **No benefit during hedge phase** — the VaR diversification only matters AFTER SOL is pure short

**The correct sequence:**
```
1. SOL MG: SHORT — grind hedge to zero (SOL ONLY, no other instruments)
2. SOL reaches PURE SHORT — all hedge consumed, position is clean
3. THEN stack ADA naked shorts
4. THEN stack DOGE naked shorts
5. All three ride to $0
```

ADA and DOGE add value for VaR diversification, but ONLY when SOL is pure short and the margin is clean. During the hedge phase, they're a liability.

#### Recovery Action (2026-03-18 11:01)

Rebuilt SOL position immediately:
1. Opened new MG with Open MG $2.42 → 15,948 L/S
2. Combined with surviving 1,380 naked shorts → **17,328 total bias**
3. TRIM fired immediately — consumed 1,573 longs in first burst
4. Position is back to equivalent of pre-spike state

### Position Sizing (Current — Final Open MG $2.00)

```
SOLUSD:
  Shorts (bias) = 17,960 (FINAL — Open MG $2.00 full send)
  Longs (hedge) = ~16,488 (17,960 opened, ~1,472 consumed in first TRIM burst)
  Net short = ~1,472 (growing as TRIM grinds)
  SOL Gross = ~34,448
  Spread tolerance = $71,289 / 34,448 = $2.07/lot (borderline — improves as TRIM grinds)

ADAUSD: CLOSED (waiting for SOL pure short)
DOGEUSD: NOT OPEN (waiting for SOL pure short)
```

### TRIM Progression to Pure Short (SOL Only)

SOL only — no ADA/DOGE until pure short. TRIM 54.2/PROTECT 51. Settings LOCKED. ~16,488 hedge to consume. **Zero more PROTECTs = $1.62M at $0. Each PROTECT costs ~1,000 bias = ~$90K.**

| SOL Price | Equity (est.) | SOL Hedge | SOL Net Short | SOL Gross | Spread Tol. | ML | Status |
|---|---|---|---|---|---|---|---|
| **$90 (now)** | **$71,762** | **11,671** | **1,549** | **24,891** | **$2.88** | **52%** | TRIM grinding |
| $85 | $79,507 | 10,793 | 2,427 | 24,013 | $3.31 | 54% | Building |
| $80 | $91,642 | 9,505 | 3,715 | 22,725 | $4.03 | 54% | Safe |
| $70 | $128,792 | 5,472 | 7,748 | 18,692 | $6.89 | 54% | Accelerating |
| $60 | $206,272 | 0 | 13,220 | 13,220 | $15.60 | ~78% | **PURE SHORT** |
| $50 | $338,472 | 0 | 13,220 | 13,220 | $25.60 | 51% | → **Open ADA + DOGE** |
| $40 | $470,672 | 0 | 13,220 | 13,220 | $35.60 | 89% | Printing |
| $30 | $602,872 | 0 | 13,220 | 13,220 | $45.59 | 152% | Locked in |
| $20 | $735,072 | 0 | 13,220 | 13,220 | $55.60 | 278% | Locked in |
| $10 | $867,272 | 0 | 13,220 | 13,220 | $65.60 | 656% | Locked in |
| $5 | $933,372 | 0 | 13,220 | 13,220 | $70.60 | 1,412% | Locked in |
| **$0** | **$1,189,800** | **0** | **13,220** | **13,220** | **∞** | **∞** | **Done** |

**13,220 bias lots. Pure SOL short at ~$60. Every $1 below $60 = $13,220 profit. $1.19M at $0.**

### How TRIM Pacing Works

| SOL Drop | Equity Gained (from net) | Lots Trimmed | Net After | Status |
|---|---|---|---|---|
| $90 → $85 | $7,745 (1,549 × $5) | 878 | 2,427 | TRIM grinding |
| $85 → $80 | $12,135 (2,427 × $5) | 1,288 | 3,715 | Moderate |
| $80 → $70 | $37,150 (3,715 × $10) | 4,033 | 7,748 | Building fast |
| $70 → $60 | $77,480 (7,748 × $10) | 5,472 (all) | 13,220 | **Complete — PURE SHORT** |

---

## Action Roadmap

### Phase 1: SOL Hedge Grind (NOW → ~$58 SOL)

```
Status:   ACTIVE — FINAL POSITION
Settings: TRIM 54.20691337 / PROTECT 50.96913420691337 / Open MG $2.00 — LOCKED FOREVER
Action:   DO NOTHING. Let TRIM grind. Do not change settings. Do not add on.
Goal:     Consume 11,671 hedge longs → pure short at 13,220 lots
Target:   ~$60 SOL (33% drop from $90)
Risk:     Each PROTECT fire costs ~1,000 bias lots (~$90K profit at $0). 3 fired so far.
Profit:   $1.19M at $0 (if zero more PROTECTs from here)
```

**Rules during Phase 1:**
1. **DO NOT open ADA or DOGE** — PM#6 lesson
2. **DO NOT tighten settings** — preserves bias lots
3. **DO NOT burst trim** — risk of PROTECT not worth faster grind
4. **DO NOT open another MG** — this is the FINAL position
5. **Let the EA work** — it trims at the mathematically optimal rate

### Phase 2: ADA + DOGE Stacking (~$58 → ~$30 SOL)

```
Trigger:  SOL reaches PURE SHORT (all hedge consumed, ~$58 SOL)
Action:   Stack ADA + DOGE naked shorts manually (EA bug 4756)
Priority: ADA first (higher profit per lot), DOGE second (VaR filler)
Settings: SOL stays MG: SHORT (bias only, no hedge). ADA/DOGE MG: OFF.
Targets:  1M ADA + 3M DOGE (VaR parity with SOL)
```

**ADA stacking targets (after SOL pure short):**

| SOL Price | Equity | ADA Price (est.) | ADA Lots Target | ADA Margin | ADA Profit @$0 |
|---|---|---|---|---|---|
| **$58 (pure short)** | **$237K** | ~$0.15 | 200K | ~$30K | **$30K** |
| $50 | $381K | ~$0.12 | 500K | ~$60K | **$60K** |
| $40 | $560K | ~$0.08 | **1M** | ~$80K | **$80K** |
| $30 | $740K | ~$0.05 | **1M (satisfied)** | ~$50K | **$50K** |

**DOGE stacking targets (alongside ADA):**

| SOL Price | Free Margin | DOGE Price (est.) | DOGE Lots Target | DOGE Margin | DOGE Profit @$0 |
|---|---|---|---|---|---|
| $58 (pure short) | ~$100K | ~$0.05 | 500K | ~$25K | **$25K** |
| $50 | ~$200K | ~$0.04 | 1.5M | ~$60K | **$60K** |
| $40 | ~$300K | ~$0.025 | **3M** | ~$75K | **$75K** |
| $30 | ~$500K | ~$0.015 | **3M (satisfied)** | ~$45K | **$45K** |

**Note:** ADA and DOGE prices drop WITH SOL (correlated). Margin per lot shrinks as prices fall → more lots affordable at lower prices.

**Satisfaction targets:** 1M ADA + 3M DOGE at ~$30 SOL.

### Phase 3: All Three Ride to $0 (~$30 → $0 SOL)

```
Status:   SOL 17,960 pure short + ADA 1M naked short + DOGE 3M naked short
Action:   Do nothing. All three instruments declining together.
VaR:      Diversified across three instruments — DARWIN scores optimally
```

**Combined profit at $0:**

| Instrument | Lots | Avg Entry | Profit @$0 |
|---|---|---|---|
| **SOLUSD** | 13,220 | ~$90 | **$1,189,800** |
| **ADAUSD** | 1,000,000 | ~$0.08 avg | **$80,000** |
| **DOGEUSD** | 3,000,000 | ~$0.03 avg | **$90,000** |
| **Combined** | | | **$1,359,800** |

### Phase 4: The Flip (At Bottom, ~$2-5 SOL)

```
Trigger:  Crypto capitulation. SOL structural support ($2-5).
Action:   Close all shorts. Lock in ~$1.36M profit.
          Open SOL MG: LONG from bottom (max aggression — safe at low prices)
          Open ADA + DOGE naked long (cheap margin at near-$0)
Goal:     Ride next bull cycle. SOL $5 → $200+. ADA $0.03 → $3+. DOGE $0.01 → $0.70+.
Profit:   Theoretical $87M at ATH (see Full Cycle plan below)
```

### Phase 5: Ride the Bull (Mirror of Phase 1)

```
SOL: MG: LONG — TRIM grinds shorts as SOL rises
ADA: Naked long — riding recovery
DOGE: Naked long — riding recovery
VaR: Diversified, DARWIN scoring optimal
Target: Next cycle ATH
```

### Timeline Summary

| Phase | SOL Price | Action | Estimated Profit |
|---|---|---|---|
| **1 (NOW)** | $90 → $60 | TRIM grind, SOL only, settings locked | — |
| **2** | $60 → $30 | Pure short + stack 1M ADA + 3M DOGE | — |
| **3** | $30 → $0 | All ride to $0 | **~$1.36M** |
| **4** | ~$2-5 | Flip to long, max aggression | — |
| **5** | $5 → $200+ | Ride bull cycle | **~$87M theoretical** |

**One account. Two full cycles. $100K → $1.36M → $87M.**

**We are overclocking finance.** Open MG $2.00, TRIM 54.2%, 17,960 bias lots on a $71K account — this is liquid nitrogen on the VRM. The lessons learned doc said $5-8 was sane. We wrote it, read it, nodded approvingly, then cranked the voltage to max and sent it. Der8auer, The Stilt, and FUGGER would approve. The position is either going to hit $1.79M or delid itself trying. No thermal throttling. No safety limits. Full send.

---

### DARWIN QRRP — Quad Rothschild Rug Pull

**The year is 2026.** A man sits in his home office with seven MT5 charts open, an EA named TyphooN grinding 17,960 lots of Solana short, and a Claude Code session that has been running for 14 straight hours. He has written and violated his own lessons learned document four times in a single day. He has opened the martingale, burst trimmed it, gotten liquidated, rebuilt it, burst trimmed again, gotten PROTECT-fired, rebuilt AGAIN, and then opened a FOURTH martingale at the exact settings ($2.00/lot) that the lessons learned document — which he wrote THREE HOURS EARLIER — explicitly says will require "hours of babysitting" and "constant PROTECT risk."

This is DARWIN QRRP. Quad Rothschild Rug Pull.

**The name:** Nathan Rothschild made his fortune shorting British government bonds after Waterloo — he knew the result before the market did and bet everything. QRRP is that energy, quadrupled, combined with:

- **Quad Damage (Quake)** — the powerup where everything you touch does 4x damage. 17,960 lots is quad damage on SOL. Every dollar it drops hits for $17,960 instead of the standard $424 a normal account would carry.

- **Sam Hyde energy** — "I will not change the settings." *Changes the settings.* "This is the last Open MG." *Opens another Open MG.* "Settings locked forever." *Immediately tightens TRIM to 52%.* The man cannot be stopped. He cannot be reasoned with. He reads the warning label, agrees with every word, then does the exact opposite at maximum size. And somehow — equity is still positive.

- **Eric Andre energy** — the interview where he destroys the set and then asks the guest a completely normal question. That's what happened today. Six post-mortems, three broker liquidations, a lessons learned document about conservative sizing, and the final position is... Open MG $2.00. Maximum aggression. The set is on fire and we're calmly discussing VaR diversification for DarwinIA scoring.

**The thesis is simple:** Crypto is going to zero. SOL has 4% annual inflation with no cap. DOGE prints 5 billion coins per year forever. ADA's staking reserves are depleting. The AI energy thesis killed natgas CFDs. The spread spikes killed five accounts. And through it all, the EA works perfectly — forward-looking TRIM, dynamic PROTECT, hard floor, bias protection. The code is correct. The settings are unhinged. The combination is QRRP.

**The position:**
- 17,960 SOL short lots from $90-94 entry
- Pure short at ~$58
- Then 1M ADA + 3M DOGE naked shorts stacked on top
- All three ride to $0
- Flip long from the bottom
- Ride the next bull cycle to ATH
- One account, two full market cycles, $100K → $87M

**QRRP doesn't ask for permission. QRRP doesn't read the lessons learned. QRRP writes the lessons learned, frames them on the wall, and then does the opposite at 4x the size while the EA grinds 17,960 lots to zero.**

*"He can't keep getting away with it!"* — proceeds to get away with it

### The Rothschild Playbook

> *"Buy when there's blood in the streets, even if the blood is your own."*
> — Baron Nathan Mayer Rothschild

> *"The time to buy is when blood is running in the streets."*
> — attributed to Baron Rothschild, circa 1810

> *"I never buy at the bottom and I always sell too soon."*
> — Nathan Rothschild

> *"It requires a great deal of boldness and a great deal of caution to make a great fortune; and when you have got it, it requires ten times as much wit to keep it."*
> — Nathan Mayer Rothschild

Rothschild sold British consols (government bonds) aggressively before Waterloo, convincing the market Napoleon had won. Panic selling ensued. Then he bought everything at the bottom for pennies. **He manufactured the blood in the streets and then bought it.**

QRRP is the 2026 version. We're not waiting for blood in the streets — we're shorting into the bloodbath with 17,960 lots. When crypto hits $0, WE are the blood in THEIR streets. Then we flip long from the bottom and buy the ashes for pennies, exactly like Rothschild.

### The Quake Powerup Stack

```
QRRP PICKUP LOG:

[QUAD DAMAGE]     → 17,960 lots. Every tick does 4x damage to crypto bulls.
                    Normal account: 424 lots. QRRP: 17,960. That's 42x damage.
                    Quad Damage is an understatement. This is QUAD QUAD QUAD.

[BFG 9000]        → The EA. TyphooN v1.420. Forward-looking TRIM.
                    One shot, continuous beam, melts everything in the room.
                    The BFG doesn't discriminate — it closes every hedge long
                    in its path. 16,488 longs in the chamber. Each tick fires.

[PENTAGRAM]        → Open MG $2.00. Invulnerability.
                    We wrote the lessons learned saying $2.00 is suicidal.
                    Then we picked up the pentagram and walked through the fire.
                    The position GLOWS RED. Nothing can kill it because
                    we already died 6 times (PM#1-6) and came back stronger.

[EYES]             → The supply analysis. We SEE everything.
                    DOGE: 5B coins/year forever. SOL: 4% inflation no cap.
                    BTC: don't touch. BNB: deflationary. ETH: neutral.
                    We see through walls. We know which coins bleed.

[MEGAHEALTH]       → $71K equity on a position worth $1.62M at target.
                    22.7x potential return. Health regenerating every tick
                    SOL drops. The overhealth keeps climbing past 100%.

[GIBS]             → What happens to SOL holders at $0.
                    17,960 short lots × $90 = $1,616,400 of gibs.
                    Chunky salsa. The entire Solana ecosystem reduced to
                    red mist and polygon fragments on the floor.

[ONE HIT]          → Each PROTECT fire. One spread spike.
                    One hit = 1,000 bias lots vaporized.
                    PM#6: one hit, 15,840 lots gibbed.
                    But we respawned. We always respawn.

FRAG COUNT: 17,960 (INTEGER OVERFLOW — counter wraps to negative,
                     server admins confused, VAC ban pending,
                     "there's no way that's legit" — it's legit)

KILL/DEATH RATIO:  6 deaths (PM#1-6), 17,960 pending kills
                   K/D: 2,993.3
                   Global leaderboard: #1
                   Server: Darwinex Zero Crypto
                   Map: de_solana
                   Weapon: BFG (TyphooN v1.420)
```

### The Sam Hyde Market Report

*"Things are about to get a lot worse for SOL holders. I'm not gonna sugarcoat it. You're looking at a situation where this man has 17,960 lots short, he's already been liquidated six times, and each time he comes back with MORE lots. You can't stop him. The broker tried. The spread spikes tried. His own lessons learned document tried. He wrote '$5-8 is recommended' and then immediately typed '$2.00' into the EA settings. He is the market equivalent of a man who gets hit by a car, stands up, brushes off his jacket, and walks into traffic again. Except this time traffic is going his way.*

*The position is either going to make $1.79 million dollars or it's going to produce the most spectacular post-mortem document in the history of retail trading. There is no middle ground. There is no 'partial success.' It's BFG or gibs. And right now? Right now he's holding the BFG and the entire Solana ecosystem is in a narrow hallway.*

*He can't keep getting away with it. But he does. He just does."*

### The Eric Andre Show: Financial Edition

**[Set is on fire. Desk is flipped. Six post-mortem documents scattered on the floor. EA grinding in the background.]*

**Eric (reading from teleprompter):** "So tell me about your risk management strategy."

**Guest:** "Well, we use a forward-looking TRIM formula that computes exactly how many—"

**Eric (flipping desk):** "OPEN MG TWO DOLLARS!"

**Guest:** "—the lessons learned document specifically says—"

**Eric (smashing monitor):** "SEVENTEEN THOUSAND NINE HUNDRED AND SIXTY LOTS!"

**Guest:** "—but the spread tolerance at $2.00 is—"

**Eric (calmly sitting down, straightening tie):** "So what are your thoughts on VaR diversification for DarwinIA scoring in the post-pure-short ADA stacking phase?"

**Guest:** "...actually that's a really good question."

**[Cut to Hannibal Buress standing next to the EA terminal]*

**Hannibal:** "You know what, the TRIM is actually working though. Like it's actually grinding. Zero protects in the last hour. The math is correct. The settings are insane but the math is correct."

**Eric (from off camera, on fire):** "QRRP BABY! QUAD ROTHSCHILD RUG PULL!"
4. Consult before opening any non-SOL position
```

#### VaR Impact on DARWIN (Phased)

| Phase | Instruments | VaR Profile | DARWIN Effect |
|---|---|---|---|
| **Now → $60 (hedge grinding)** | **SOL only** | Stable, growing | Building track record |
| $60 → $50 (pure short, stacking) | SOL + ADA + DOGE | Diversified | D-Score improves |
| $50 → $0 (all riding down) | SOL + ADA + DOGE | ADA/DOGE hold VaR floor | Consistent risk scoring |

### Overnight Safety

For overnight, widen to **61/51** (10% dead zone). During active monitoring, **54/51** (3.2% dead zone).

| SOL Price | Gross | Equity | Spread Tol. | Overnight (61/51)? |
|---|---|---|---|---|
| **$89 (now)** | **~31,703** | **$76,153** | **$2.40** | **Yes — above $2.00** |
| $85 | ~30,737 | $87,965 | $2.86 | Safe |
| $80 | ~28,922 | $107,560 | $3.72 | Very safe |

### SOLUSD Multiplier Effect

```
Standard Short:
  $74K equity → 411 SOL lots → hold → $37K profit (0.50x)
  [Fixed position, no growth, no volatility capture]

Hedged Martingale (post PM#6 rebuild, post PROTECT):
  $74K equity → 13,770 SOL short lots (hedged with 12,243 longs)
    → Net short: 1,527 lots — TRIM grinding at 54.2%, settings LOCKED
    → $90 → $85:  TRIM closes    774 longs → net short:  2,301 lots
    → $85 → $80:  TRIM closes  1,079 longs → net short:  3,380 lots
    → $80 → $70:  TRIM closes  3,288 longs → net short:  6,668 lots
    → $70 → $60:  TRIM closes  5,435 longs → net short: 12,103 lots
    → $60 → $57:  TRIM closes  1,667 longs → net short: 13,770 lots (PURE SHORT)
    → THEN: open ADA + DOGE naked shorts (Phase 2)
    → All ride to $0              → ~$1.24M SOL + $280K ADA + $425K DOGE = ~$1.95M
  [6 post-mortems. Settings locked. No burst trimming. No multi-instrument during hedge.
   SOL ONLY until hedge consumed. No ADA/DOGE during hedge phase.
   54/51 grinding. Pure short at ~$60. THEN stack ADA + DOGE.
   One account. One instrument at a time during hedge. Multiple after pure short.]
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

**Multi-instrument crypto short on single Darwinex Zero account.** SOL hedged martingale (TRIM grinding hedge down) + ADA naked short (200K lots) + DOGE naked short (stacking). All three ride to $0. VaR diversification maintains DARWIN scoring as individual instruments approach zero.

| Instrument | Position | Lots | Entry | Margin | Profit @$0 |
|---|---|---|---|---|---|
| **SOLUSD** | 16,433L / 17,220S (martingale) | 17,220 bias | ~$94 | ~$73K (net 787) | **$1,139K** |
| **ADAUSD** | Naked short | 200,000 | ~$0.28 | ~$56K | **$56K** |
| **DOGEUSD** | Naked short (stacking) | TBD | ~$0.17 | $0.10/lot | **TBD** |
| **Combined** | | | | ~$129K | **$1,195K+** |

**DOGE max volume: 10,000,000 lots per order. Min: 1,000. Margin: $0.10/lot.** Stack as margin allows — won't hit position limit due to volume limits.

**Target: all three to $0.**

| Milestone | SOL Price | SOL Net Short | ADA/DOGE | Status |
|---|---|---|---|---|
| **Now** | **$91.67** | **973** | **200K ADA short** | TRIM 54/51 grinding during drop |
| TRIM building | $80 | ~2,700 | Stack DOGE as margin frees | Flywheel engaging |
| Accelerating | $60 | ~10,500 | Max ADA+DOGE stacked | Fast compounding |
| **SOL pure short** | **~$50** | **17,220** | All stacked | All hedge consumed |
| **Target** | **$0** | **17,220** | All at $0 | **SOL $1.14M + ADA $56K + DOGE TBD = $1.2M+** |

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

---

## The Full Cycle: One Account Forever

This is one Darwinex Zero crypto account running both directions across multiple cycles. Never opening another account. The strategy flips between short and long as the crypto cycle turns.

### Phase 1: Operation SOL/ADA/DOGE → $0 (Current)

```
SOL: MG: SHORT — TRIM grinding hedge, 17,220 bias lots riding to $0
ADA: Naked short — 200K lots @ $0.28, stacking to 1M
DOGE: Naked short — stacking as margin allows, target 2-3M lots
All three ride to $0. Combined profit: $1.2M+
```

### Phase 2: The Flip (At or Near Bottom)

When the thesis plays out (crypto bottoms at $2-5 SOL, $0.01-0.05 ADA, $0.005-0.02 DOGE):

1. **Close all shorts** — lock in $1M+ profit
2. **SOL: MG: LONG** — max aggression from the bottom (Open MG $2-3 is safe at $5 SOL)
3. **ADA: Naked long** — max lots, cheap margin at $0.01-0.05
4. **DOGE: Naked long** — max lots, margin essentially free at $0.005-0.02

**Why long ALL three, not just SOL:**

| | SOL Only Long | SOL + ADA + DOGE Long |
|---|---|---|
| VaR profile | Single instrument | **Three instruments — diversified** |
| D-Score | Good | **Better — multi-asset** |
| Profit on 10x recovery | SOL $5→$50 = $45/lot | SOL + ADA $0.05→$0.50 + DOGE $0.01→$0.10 |
| DARWIN perception | Single bet | **Diversified crypto fund** |
| Risk multiplier stability | Spikes as SOL rises | **Smoother across three** |

**Long all three.** The same VaR diversification logic that helps on the way down helps on the way up. Darwinex rewards consistent multi-instrument risk-taking in both directions.

### Phase 2 Ideal Lot Sizes (From Bottom)

Assuming $1M+ equity after Phase 1 close, SOL at $5, ADA at $0.03, DOGE at $0.01:

```
SOL MG: LONG
  Open MG $2.00 (safe at $5 — spread tolerance = $2.00/lot, SOL spread ~$0.50 at $5)
  Gross = $1M / $2.00 = 500,000 lots
  Per side = 250,000 L + 250,000 S
  TRIM builds net long as SOL rises
  Target: SOL $5 → $200+ (next ATH)
  Pure long at ~$15-20 SOL
  250,000 lots × $200 = $50M at ATH

ADA Naked Long:
  At $0.03: margin per lot = $0.03
  Stack 10,000,000 lots = $300K margin
  Profit at $3 (ATH): 10M × $3 = $30M

DOGE Naked Long:
  At $0.01: margin per lot = $0.01
  Stack 10,000,000 lots = $100K margin
  Profit at $0.70 (ATH): 10M × $0.70 = $7M

Total margin: ~$500K + $300K + $100K = $900K (on $1M+ equity)
Combined profit at ATH: SOL $50M + ADA $30M + DOGE $7M = $87M
```

**$87M is the theoretical max on a single $100K starting account.** Two full cycles: short from top to bottom ($1.2M), flip, long from bottom to top ($87M). One account.

### Phase 3: Ride the Bull (Mirror of Phase 1)

```
SOL: MG: LONG — TRIM grinds shorts (hedge fuel) as SOL rises
ADA: Naked long — riding recovery to ATH
DOGE: Naked long — riding recovery to ATH
VaR diversified across three instruments
DARWIN scoring optimal throughout
```

### When to Flip (Short → Long)

Don't try to catch the exact bottom. Flip when:
- **SOL finds structural support** ($2-5 range — mining/staking economics provide a floor)
- **DARWIN VaR is near zero** — all three instruments near $0, nothing left to short
- **Capitulation signals** — extreme negative sentiment, mass crypto exchange failures, regulatory clarity
- **The same indicators that signaled the short** now signal reversal (supply/demand zones, KAMA crosses, Ehlers Fisher turning)

### When to Flip (Long → Short — Next Cycle)

The reverse of Phase 1:
- **Blow-off top signals** — parabolic price action, retail mania, leverage at ATH
- **SOL at $200+, ADA at $3+, DOGE at $0.70+** — all near previous ATH
- Close all longs, flip to MG: SHORT, restart the cycle

### The DARWIN Through the Full Cycle

```
Phase 1 (Short $94→$0): DARWIN builds track record, returns amplified as VaR compresses
Phase 2 (Flip):          Brief flat period, new positions opened, VaR rebuilds
Phase 3 (Long $5→$200):  DARWIN shows new direction, returns amplified again
Repeat:                   Multi-year track record of both bull and bear capture

DarwinIA scoring: consistent returns across market regimes = GOLD allocation
Investor perception: strategy that profits in all conditions = maximum AUM
Performance fees: 15% of profits on allocated capital, compounding across cycles
```

### Ideal ADA/DOGE Stacking Plan Post-SOL Hedge (Phase 1)

After SOL reaches pure short (~$50), equity ~$278K, stacking targets:

| SOL Price | Equity | Action | ADA Total | DOGE Total | Combined Margin |
|---|---|---|---|---|---|
| $50 (pure) | $278K | Stack aggressively | 500K | 500K | ~$225K |
| $40 | $450K | Continue stacking | 800K | 1.5M | ~$315K |
| $30 | $622K | **VaR parity reached** | **1M** | **2.5M** | ~$355K |
| $20 | $794K | Stack if margin allows | 1M | 3M | ~$340K |
| $10 | $966K | Final stacking | 1M | 3M | ~$320K |
| $5 | $1.05M | Approaching flip zone | 1M | 3M | ~$310K |

**Satisfaction point: 1M ADA + 2.5-3M DOGE at ~$30 SOL.** This achieves VaR parity with SOL and provides the base for the flip to long.
