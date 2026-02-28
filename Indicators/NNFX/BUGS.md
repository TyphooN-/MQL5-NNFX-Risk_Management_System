# NNFX Third-Party Indicator Bug Report

Audit date: 2026-02-28
Scope: All 26+ indicators in `Indicators/NNFX/`
Status: **ALL FIXED** (2026-02-28)

---

## CRITICAL

### 1. STC.mq5 — iMA Handle Leak (2 handles per tick, never released)

**File:** `STC.mq5` lines 121-125
**Impact:** Terminal crash after minutes/hours of runtime

```mql5
// INSIDE OnCalculate — called every tick!
myMA = iMA(NULL, 0, MAShort, 0, MODE_EMA, PRICE_CLOSE);    // line 121
if  (CopyBuffer(myMA, 0, 0, rates_total, MAShortBuf) != rates_total) return(0);

myMA = iMA(NULL, 0, MALong, 0, MODE_EMA, PRICE_CLOSE);     // line 124
if  (CopyBuffer(myMA, 0, 0, rates_total, MALongBuf) != rates_total) return(0);
```

`iMA()` creates a new indicator handle each call. These are never released with
`IndicatorRelease()`. On a fast-ticking pair, this leaks ~120 handles/minute
and will exhaust the terminal's handle pool.

**Fix:** Move `iMA()` calls to `OnInit()`, store handles in globals, use
`IndicatorRelease()` in `OnDeinit()`.
**Status:** FIXED — handles `hMAShort`/`hMALong` created in OnInit, released in OnDeinit.

---

### 2. CMF.mq5 — tick_volume Series Mismatch (reads wrong bar)

**File:** `CMF.mq5` lines 70-73, 90, 101
**Impact:** Silently computes wrong CMF values when using tick volume

```mql5
ArraySetAsSeries(high,true);       // line 70 — series
ArraySetAsSeries(low,true);        // line 71 — series
ArraySetAsSeries(close,true);      // line 72 — series
ArraySetAsSeries(volume,true);     // line 73 — series
// tick_volume is NEVER set as series!
```

The main loop indexes with `i` in series order (descending). When
`InpVolume==VOLUME_TICK`, line 90 reads `tick_volume[i]` — but tick_volume
is in ascending order. For `i=0` (most recent bar), it reads
`tick_volume[0]` which is the **oldest** bar in the dataset.

```mql5
// line 90 — tick_volume[i] is backwards from close[i]/high[i]/low[i]
ExtBufferTMP[i]=(...) * (InpVolume==VOLUME_TICK ? tick_volume[i] : volume[i]);
```

Line 101 compounds this by using `ArrayCopy(array_mfv, tick_volume, 0, i, count)`
where the source start position `i` is series-order.

**Fix:** Add `ArraySetAsSeries(tick_volume, true);` after line 73.
**Status:** FIXED

---

### 3. TTMS.mq5 — Wrong Handle Checked for iATR (copy-paste bug)

**File:** `TTMS.mq5` lines 122-127
**Impact:** ATR handle failure goes undetected; indicator uses INVALID_HANDLE

```mql5
handle_atr=iATR(NULL,PERIOD_CURRENT,period_sm);        // line 122 — assigns handle_atr
if(handle_dev==INVALID_HANDLE)                          // line 123 — checks handle_dev!
  {
   Print("The iATR(",(string)period_sm,") object was not created: Error ",GetLastError());
   return INIT_FAILED;
  }
```

If `iATR()` fails, `handle_atr` is INVALID_HANDLE but the code checks
`handle_dev` (the StdDev handle from line 115, which already passed). The
error is never caught, OnInit returns INIT_SUCCEEDED, and OnCalculate later
calls `CopyBuffer(handle_atr, ...)` with an invalid handle — returning 0
every tick and producing an empty indicator with no error message.

**Fix:** Change line 123 to `if(handle_atr==INVALID_HANDLE)`.
**Status:** FIXED

---

## HIGH

### 4. SolarWind.mq5 — Division by Zero in DoTheCrossOverCalc

**File:** `SolarWind.mq5` line 226
**Impact:** Runtime crash or NaN propagation

```mql5
Value = 0.33*2*((price-MinL)/(MaxH-MinL)-0.5) + 0.67*Value1;
```

When the market is flat over the lookback period (all highs equal all lows),
`MaxH == MinL` and the expression divides by zero. The `MathMin/MathMax`
clamp on line 227 happens after the division, so it cannot prevent NaN from
propagating into the Fisher transform on line 228.

**Fix:** Guard: `if(MaxH == MinL) { calcZero[workBar] = Fish; calcOne[workBar] = ...; return; }`
**Status:** FIXED — `if(MaxH - MinL > 0)` guard added, else carries forward previous Value.

---

### 5. SolarWind.mq5 — Array Out-of-Bounds in Smoothing Loop

**File:** `SolarWind.mq5` line 246, 250
**Impact:** Array index out of range

```mql5
for( k=0; k<smooth && g_maxBars; k++)   // g_maxBars (~30000) is always truthy
{
   ...
   sum += weight*calcOne[i+k];           // i + k can exceed buffer size
}
```

The condition `k<smooth && g_maxBars` should be `k<smooth && (i+k)<g_maxBars`
or similar bounds check. When `i = firstWorkBar` and `smooth = 15`, the index
`i + k` can reach `firstWorkBar + 14`, which may exceed the allocated buffer
size.

**Fix:** Change loop condition to `k<smooth && (i+k)<rates_total` or similar.
**Status:** FIXED — condition changed to `k<smooth && (i+k)<=firstWorkBar`.

---

### 6. WAE.mq5 — Exit Short Alert Never Fires

**File:** `WAE.mq5` lines 256-258
**Impact:** Functional bug — exit signal for short positions is dead code

```mql5
if(Trend1<0 && MathAbs(Trend1)<Explo1 &&
   MathAbs(Trend1)<MathAbs(Trend2) && MathAbs(Trend2)>Explo2 &&
   Trend1>Dead && ...       // <— Trend1 is NEGATIVE, Dead is POSITIVE
```

This block is inside the exit-short detection. `Trend1` is guaranteed negative
at this point (checked on line 256), but `Dead = _Point * DeadZonePip` is
always positive. The condition `Trend1 > Dead` is therefore always `false`,
making the entire exit-short alert unreachable.

**Fix:** Change `Trend1>Dead` to `MathAbs(Trend1)>Dead`.
**Status:** FIXED

---

### 7. SSL_Channel.mq5 (Novateq) — CopyBuffer Return Unchecked

**File:** `SSL_Channel.mq5` lines 84-85
**Impact:** Reads uninitialized/garbage data if MA handles not ready

```mql5
CopyBuffer( HighHandle, 0, 0, limit + 1, highValues );   // return value ignored
CopyBuffer( LowHandle, 0, 0, limit + 1, lowValues );     // return value ignored
```

On the first ticks after loading (or on timeframe switch), the iMA handles
may not have finished calculating. `CopyBuffer` returns -1 or 0, leaving
`highValues[]` and `lowValues[]` uninitialized. The loop then reads
`highValues[i]` / `lowValues[i]` which are garbage or zero, causing the SSL
lines to jump wildly on chart load.

**Fix:** Check return values: `if(CopyBuffer(...) != limit+1) return 0;`
**Status:** FIXED — also removed stray semicolon at file scope (bug #12).

---

## MEDIUM

### 8. BraidFilter.mq5 — Full Recalculation Every Tick

**File:** `BraidFilter.mq5` line 107
**Impact:** Performance — unnecessary CPU load, ~4x full CopyBuffer per tick

```mql5
limit=rates_total-2;   // ignores prev_calculated entirely
```

Regardless of `prev_calculated`, the indicator always sets `limit` to
cover the entire history. This forces all 4 `CopyBuffer` calls (ATR, 3x MA)
to copy the full dataset and the main loop to iterate all bars. On a chart
with 100k bars, this wastes significant CPU every tick.

**Fix:** Use standard incremental pattern:
```mql5
limit = (prev_calculated < 2) ? rates_total - 2 : rates_total - prev_calculated;
```
**Status:** FIXED

---

### 9. ASH.mq5 — Per-Bar Array Allocation in Highest/Lowest

**File:** `ASH.mq5` lines 210-214, 219-224
**Impact:** Performance — thousands of array alloc/dealloc per recalculation

```mql5
int Highest(const int count,const int start)
{
   double array[];                    // allocated per call
   ArraySetAsSeries(array,true);
   return(CopyHigh(Symbol(),PERIOD_CURRENT,start,count,array)==count
          ? ArrayMaximum(array)+start : WRONG_VALUE);
}
```

When `InpMode==MODE_STO`, `Highest()` and `Lowest()` are called once per
bar. Each call allocates a dynamic array, calls `CopyHigh`/`CopyLow`,
finds the max/min, then deallocates. On full recalculation of 10k bars,
this means 20k array allocations.

**Fix:** Pre-copy high/low data in OnCalculate once, iterate for max/min
in-place (like the SqueezeMomentum_LB.mq5 approach).
**Status:** FIXED — Highest/Lowest now take `const double &h[]` param, scan OnCalculate arrays directly.

---

### 10. ASH.mq5 — Unreachable Return Statement

**File:** `ASH.mq5` line 224
**Impact:** Dead code (no runtime effect)

```mql5
int Lowest(const int count,const int start)
{
   ...
   return(CopyLow(...)==count ? ArrayMinimum(array)+start : WRONG_VALUE);   // line 223
   return WRONG_VALUE;   // line 224 — UNREACHABLE
}
```

Line 224 can never execute because line 223 always returns.

**Fix:** Delete line 224.
**Status:** FIXED

---

### 11. SSL_Channel_Chart.mq5 — Fragile Manual Series Conversion

**File:** `SSL_Channel_Chart.mq5` lines 96-97
**Impact:** Confusing code that's easy to break; no direction buffer init

```mql5
if (close[rates_total-1-i] > MAHigh[limit-i]) Hlv[i]= 1;
if (close[rates_total-1-i] < MALow[limit-i]) Hlv[i]= -1;
```

Instead of calling `ArraySetAsSeries(close, true)`, the code manually
converts indices with `close[rates_total-1-i]`. While technically correct,
this is fragile and inconsistent with the rest of the codebase. The
`Hlv[]` buffer is also never initialized, so on the first bar
`Hlv[limit+1]` is 0 (neither bullish nor bearish), causing incorrect
SSL direction on the oldest visible bar.

**Fix:** Use `ArraySetAsSeries(close, true)` and `close[i]` directly.
Initialize `Hlv` buffer with `ArrayInitialize(Hlv, 0)` on first run.
**Status:** FIXED — added ArraySetAsSeries for close/MAHigh/MALow, simplified indexing, added CopyBuffer checks.

---

### 12. SSL_Channel.mq5 (Novateq) — Stray Semicolon at File Scope

**File:** `SSL_Channel.mq5` line 36
**Impact:** Cosmetic (compiles, no runtime effect)

```mql5
int                        LowHandle;

;           // <— stray semicolon
int OnInit() {
```
**Status:** FIXED (removed alongside bug #7 fix)

---

## CLEAN — No Bugs Found

The following indicators passed the audit with no significant issues:

| Indicator | Notes |
|-----------|-------|
| ALMA.mq5 | Clean, self-contained ALMA implementation |
| Aroon.mq5 | Standard MetaQuotes-style, handles created in OnInit |
| Aroon_Oscillator.mq5 | Clean derived indicator |
| Blau_Ergodic_TSI.mq5 | Clean, proper incremental calculation |
| ForceIndex.mq5 | Standard MetaQuotes implementation |
| HMA.mq5 | Clean Hull MA |
| KijunSen.mq5 | Simple, correct |
| McGinleyDynamic.mq5 | Clean |
| QQE.mq5 | Proper handle management |
| REX.mq5 | Clean mladen implementation |
| RSX.mq5 | Ring-buffer RSX, correct if unconventional |
| Squeeze.mq5 | Clean mladen class-based implementation |
| SqueezeMomentum_LB.mq5 | Our MQ4→MQ5 conversion, self-contained |
| Squeeze_Break.mq5 | Our MQ4→MQ5 conversion, self-contained |
| TDFI.mq5 | Clean |
| VPCI.mq5 | Clean, standard MetaQuotes style |

---

## Summary

| Severity | Count | Indicators Affected |
|----------|-------|---------------------|
| CRITICAL | 3 | STC, CMF, TTMS |
| HIGH | 4 | SolarWind (2), WAE, SSL_Channel |
| MEDIUM | 5 | BraidFilter, ASH (2), SSL_Channel_Chart, SSL_Channel |
| CLEAN | 16 | See table above |

All 12 bugs have been fixed in-place.
