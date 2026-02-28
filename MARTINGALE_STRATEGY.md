# Martingale Hedge Strategy — Crypto Short to Zero

## Thesis

Crypto assets (SOL, DOGE) go to zero. Maximize short exposure and profit by using a hedged martingale that exploits broker margin netting rules and crypto volatility.

## Core Mechanism

MT5 brokers charge margin on **net exposure only**. Hedged (matched long/short) pairs cost zero margin.

```
Gross positions:
  Long:  5,188 SOL lots
  Short: 6,913 SOL lots
  Total: 12,101 lots

Broker sees:
  Hedged pairs:  5,188 long vs 5,188 short = $0 margin
  Unhedged net:  6,913 - 5,188 = 1,725 short  = margin charged
```

This lets you carry **$1.08M gross notional** on **$94K equity** — an **11.4x leverage multiplier** from hedging alone.

## Current Position Snapshot

| Asset | Long Lots | Short Lots | Net Short | Price | Net Notional |
|-------|-----------|------------|-----------|-------|-------------|
| SOLUSD | 5,188 | 6,913 | 1,725 | ~$86 | $148,350 |
| DOGEUSD | 0 | 379,000 | 379,000 | ~$0.0957 | $36,270 |
| **Total** | | | | | **$184,620** |

| Metric | Value |
|--------|-------|
| Account Balance | $94,292 |
| Account Equity | $94,202 |
| Used Margin | $184,819 |
| Free Margin | -$90,617 |
| Margin Level | 50.97% |
| Gross Notional | ~$1,077,636 |
| Leverage Multiplier | ~11.4x |

## Without Hedging vs With Hedging

At 100% margin level, no hedging, same equity:

| | Pure Short (no hedge) | Current Hedged | Advantage |
|---|---|---|---|
| SOLUSD | 881 lots | 1,725 net (6,913 gross) | +96% net / +685% gross |
| DOGEUSD | 191,900 lots | 379,000 lots | +98% |
| Total Notional | $94,202 | $184,724 | +96% |
| Gross Exposure | $94,202 | $1,077,636 | +1,044% |

## How the Strategy Works

### Two Machines Running Simultaneously

**Machine 1 — The Harvester (hedged pairs)**

The 5,188 matched long/short pairs cost zero margin. They exist to generate harvestable profit on every price bounce.

- Price goes up: longs become profitable, close them, bank the profit
- Price comes back down: shorts recover, longs are already closed (profit kept)
- Net cost of the round trip: zero (minus spread)

**Machine 2 — The Directional Bet (net short)**

The 1,725 unhedged net short lots are the conviction trade. These profit dollar-for-dollar as price drops toward zero.

### The Cycle

```
1. SOL at $86
   Position: 5,188 Long / 6,913 Short

2. SOL spikes to $90 (+$4)
   → Longs profitable: 5,188 x $4 = $20,752 available
   → EA closes profitable longs in chunks
   → Balance increases, margin freed, slots freed
   → EA opens new shorts at $90 (better entry)
   → EA or manual re-opens longs at $90 for next hedge

3. SOL drops to $80 (-$10)
   → All shorts profit from their various entry prices
   → Longs at $90 are losing — hold or close at loss to free slots
   → Open more shorts if margin allows

4. SOL bounces to $85 (+$5)
   → Longs at $90 still underwater — hold
   → Or harvest any longs that ARE profitable

5. SOL spikes to $92 (+$12 from $80)
   → Longs become profitable again → harvest
   → Stack more shorts at $92
   → Re-hedge with new longs

6. Repeat all the way down to $0
```

### Taking Losses on Longs

Not every long is harvested at a profit. On sustained drops, longs lose value and must sometimes be closed at a loss to:

- Free position slots for more shorts
- Free margin to avoid margin call
- Reposition longs at a lower price

**This is acceptable.** The long losses are the cost of doing business. The short profit at zero dwarfs all cumulative long losses. The longs are expendable ammunition — some make money on bounces, some lose money on drops. Either way, the short stack grows.

## Profit Potential: SOL and DOGE to Zero

### Gross Short Profit

| Asset | Short Lots | Avg Entry | Profit at $0 |
|-------|-----------|-----------|-------------|
| SOLUSD | 6,913 | ~$86 | $594,518 |
| DOGEUSD | 379,000 | ~$0.0957 | $36,270 |
| **Total** | | | **$630,788** |

### Static Hold vs Flawless Execution

**Static hold (no management):**
- Short profit: $630,788
- Long losses (held to zero): -$446,168
- Net: **$184,620** (~2x return)

**Flawless execution with harvesting:**

| Component | Estimate |
|-----------|----------|
| Original shorts to zero | $630,788 |
| New shorts added at higher prices (bounces) | $50,000 — $150,000+ |
| Harvested long profits (15-20 cycles) | $150,000 — $400,000+ |
| Cumulative long losses (cost of hedging) | -$30,000 — -$50,000 |
| **Total** | **$800,000 — $1,200,000+** |

### Return Multiple

| Scenario | Profit | Return on $94K |
|----------|--------|----------------|
| Static (no management) | ~$185,000 | ~2x |
| Conservative (low volatility) | ~$750,000 | ~8x |
| Moderate (normal crypto vol) | ~$1,000,000 | ~10.6x |
| Best case (high volatility) | ~$1,200,000+ | ~12.7x+ |

### The Compounding Effect

The position grows itself:

1. Harvest profits increase balance
2. Increased balance provides more margin capacity
3. More margin capacity allows more shorts at higher bounce prices
4. More shorts generate bigger harvests next cycle
5. Repeat — the position compounds

By the time SOL reaches $40, the gross short position could be 2-3x larger than today, entirely funded by harvested long profits.

## Why Volatility Is Profit

Straight line to zero: ~$630K (just the shorts)
Volatile path to zero: ~$1M+ (bounces are harvestable)

**The more SOL spikes before dying, the more money the strategy makes** — as long as each spike is survived (which the hedge ensures). Volatility is fuel, not risk.

## Safety Guards (EA Implementation)

| Parameter | Default | Purpose |
|-----------|---------|---------|
| MartingaleCloseChunkSize | 50 lots | Partial close size for profit banking and PROTECT |
| MartingaleCooldown | 30s | Seconds between margin-based operations |
| MartingaleEquityTP | 0 (disabled) | Close all if $ profit target reached |
| MartingaleUnwindLotSize | 1 lot | Lots per TRIM close (hedge removal) |
| MartingaleUnwindMarginPct | 0 (disabled) | TRIM: unwind hedges when margin >= this % |
| MartingaleHarvestMarginPct | 0 (disabled) | HARVEST: bank profits on bias when margin >= this % (post-trim) |
| MartingaleHarvestLotSize | 1 lot | Lots per HARVEST close |
| MartingaleDangerMarginPct | 0 (disabled) | PROTECT: emergency bias close when margin >= this % |

## EA Behavior by Mode

| Mode | Profit Banking | Margin Tiers | Use Case |
|------|---------------|-------------|----------|
| MG_OFF | Nothing | Nothing | Inactive |
| MG_SHORT | Closes profitable longs every tick | PROTECT → TRIM → HARVEST | Short bias strategy |
| MG_LONG | Closes profitable shorts every tick | PROTECT → TRIM → HARVEST | Long bias strategy |
| MG_UNWIND | Nothing | Closes worst P/L position | Exit strategy |

## Risk

The strategy survives if and only if the account avoids the **50% margin call**. The margin level safety (200% default) prevents the EA from adding positions in dangerous territory. Manual intervention may be needed to close losing longs during sharp drops to maintain margin.

The thesis requires crypto going to zero (or near zero). If SOL/DOGE recover and sustain higher prices permanently, the net short position accumulates losses indefinitely. The hedge buys time but does not eliminate directional risk.
