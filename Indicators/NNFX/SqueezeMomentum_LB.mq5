//+------------------------------------------------------------------+
//|                                          SqueezeMomentum_LB.mq5  |
//|                   LazyBear's Squeeze Momentum (TradingView port)  |
//|                         Original MQ4: Bugscoder Studio            |
//|                         Converted to MQ5                          |
//+------------------------------------------------------------------+
//  4-color momentum histogram + 3-color squeeze state dots.
//  Histogram: Lime = up & rising, Green = up & falling,
//             Red = down & falling, Maroon = down & rising
//  Dots:      Blue = squeeze ON (BB inside KC),
//             Black = squeeze OFF (BB outside KC), Gray = neutral
//+------------------------------------------------------------------+
#property copyright "Bugscoder Studio"
#property link      "https://www.bugscoder.com/"
#property version   "2.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2

// Plot 1 — momentum color histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_width1  2
#property indicator_color1  clrLime,clrGreen,clrRed,clrMaroon
#property indicator_label1  "Momentum"

// Plot 2 — squeeze state dots
#property indicator_type2   DRAW_COLOR_ARROW
#property indicator_width2  2
#property indicator_color2  clrBlue,clrBlack,clrGray
#property indicator_label2  "Squeeze"

input int    BBLength     = 20;   // BB Length
input double BBMult       = 2.0;  // BB MultFactor
input int    KCLength     = 20;   // KC Length
input double KCMult       = 1.5;  // KC MultFactor
input bool   UseTrueRange = true; // Use TrueRange (KC)

double HistData[], HistClr[];
double DotData[],  DotClr[];
double RangeBuf[], LinSrc[];

//--- Monotone deques for O(1) amortized sliding HH/LL over KCLength window
int g_maxDq[], g_minDq[];

int OnInit()
{
   SetIndexBuffer(0, HistData, INDICATOR_DATA);
   SetIndexBuffer(1, HistClr,  INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, DotData,  INDICATOR_DATA);
   SetIndexBuffer(3, DotClr,   INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4, RangeBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, LinSrc,   INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(1, PLOT_ARROW, 167);
   IndicatorSetString(INDICATOR_SHORTNAME,
      "SqzMom_LB(" + IntegerToString(BBLength) + "," + IntegerToString(KCLength) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   ArraySetAsSeries(HistData, true);
   ArraySetAsSeries(HistClr,  true);
   ArraySetAsSeries(DotData,  true);
   ArraySetAsSeries(DotClr,   true);
   ArraySetAsSeries(RangeBuf, true);
   ArraySetAsSeries(LinSrc,   true);
   int dqCap = (int)MathMax(BBLength, KCLength) + 2;
   if(ArrayResize(g_maxDq, dqCap) == -1 || ArrayResize(g_minDq, dqCap) == -1)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   ArraySetAsSeries(high,  true);
   ArraySetAsSeries(low,   true);
   ArraySetAsSeries(close, true);

   int maxPer   = (int)MathMax(BBLength, KCLength);
   int lookback = maxPer + KCLength + 2;
   if (rates_total < lookback) return 0;

   int limit;
   if (prev_calculated <= 0)
      limit = rates_total - lookback;
   else
      limit = rates_total - prev_calculated + 1;
   if (limit > rates_total - lookback) limit = rates_total - lookback;
   if (limit < 0) limit = 0;

   // --- O(1) running sums for BB close, KC close, KC range ---
   double sumBB = 0, sumBBSq = 0;
   for (int j = 0; j < BBLength; j++)
   {
      double c = close[limit + j];
      sumBB   += c;
      sumBBSq += c * c;
   }
   double sumKC = 0, sumRG = 0;
   for (int j = 0; j < KCLength; j++)
   {
      int idx = limit + j;
      RangeBuf[idx] = UseTrueRange ? TrueRange(high, low, close, idx) : (high[idx] - low[idx]);
      sumKC += close[idx];
      sumRG += RangeBuf[idx];
   }

   // --- Monotone deques seeded with window [limit, limit+KCLength-1] ---
   int dqCap = (int)ArraySize(g_maxDq);
   int maxH = 0, maxT = 0, minH = 0, minT = 0;
   for (int j = limit + KCLength - 1; j >= limit; j--)
   {
      while (maxT > maxH && high[g_maxDq[(maxT - 1) % dqCap]] <= high[j]) maxT--;
      g_maxDq[maxT % dqCap] = j; maxT++;
      while (minT > minH && low[g_minDq[(minT - 1) % dqCap]]  >= low[j])  minT--;
      g_minDq[minT % dqCap] = j; minT++;
   }

   double invBB = 1.0 / BBLength;
   double invKC = 1.0 / KCLength;

   for (int pos = limit; pos >= 0; pos--)
   {
      // --- Bollinger Bands (running sum + sum-of-squares variance) ---
      double basis = sumBB * invBB;
      double var   = (sumBBSq - sumBB * sumBB * invBB) * invBB;
      if (var < 0) var = 0;
      double dev   = BBMult * MathSqrt(var);
      double upperBB = basis + dev;
      double lowerBB = basis - dev;

      // --- Keltner Channel ---
      double ma      = sumKC * invKC;
      double rangema = sumRG * invKC;
      double upperKC = ma + rangema * KCMult;
      double lowerKC = ma - rangema * KCMult;

      // --- Squeeze state ---
      bool sqzOn  = (lowerBB > lowerKC) && (upperBB < upperKC);
      bool sqzOff = (lowerBB < lowerKC) && (upperBB > upperKC);

      // --- Momentum via linear regression ---
      double highest = high[g_maxDq[maxH % dqCap]];
      double lowest  = low[g_minDq[minH % dqCap]];
      LinSrc[pos] = close[pos] - ((highest + lowest) / 2.0 + ma) / 2.0;
      double val  = LinReg(LinSrc, KCLength, pos);
      HistData[pos] = val;

      // 4-color histogram (compare to previous bar, already calculated)
      double prev = HistData[pos + 1];
      if      (val > 0 && val >= prev) HistClr[pos] = 0; // Lime:   up & rising
      else if (val > 0 && val <  prev) HistClr[pos] = 1; // Green:  up & falling
      else if (val < 0 && val <= prev) HistClr[pos] = 2; // Red:    down & falling
      else                             HistClr[pos] = 3; // Maroon: down & rising

      // Squeeze dots at zero line
      DotData[pos] = 0;
      if (sqzOn)       DotClr[pos] = 0; // Blue:  squeeze on
      else if (sqzOff) DotClr[pos] = 1; // Black: squeeze off
      else             DotClr[pos] = 2; // Gray:  neutral

      // --- Slide window to pos-1 (newer bar) ---
      if (pos > 0)
      {
         int addK  = pos - 1;
         int remBB = addK + BBLength;
         int remKC = addK + KCLength;

         double cAdd   = close[addK];
         double cRemBB = close[remBB];
         sumBB   += cAdd - cRemBB;
         sumBBSq += cAdd * cAdd - cRemBB * cRemBB;

         double cRemKC = close[remKC];
         sumKC += cAdd - cRemKC;

         RangeBuf[addK] = UseTrueRange ? TrueRange(high, low, close, addK) : (high[addK] - low[addK]);
         sumRG += RangeBuf[addK] - RangeBuf[remKC];

         // Drop expiring index (addK+KCLength = pos+KCLength-1 no longer in new window)
         int dropIdx = pos + KCLength - 1;
         if (maxH < maxT && g_maxDq[maxH % dqCap] == dropIdx) maxH++;
         if (minH < minT && g_minDq[minH % dqCap] == dropIdx) minH++;

         // Push new index addK
         while (maxT > maxH && high[g_maxDq[(maxT - 1) % dqCap]] <= high[addK]) maxT--;
         g_maxDq[maxT % dqCap] = addK; maxT++;
         while (minT > minH && low[g_minDq[(minT - 1) % dqCap]]  >= low[addK])  minT--;
         g_minDq[minT % dqCap] = addK; minT++;
      }
   }
   return rates_total;
}

//+------------------------------------------------------------------+
//| Helper functions — self-contained, no handles needed             |
//+------------------------------------------------------------------+
double TrueRange(const double &h[], const double &l[], const double &c[], int s)
{
   return MathMax(h[s] - l[s], MathMax(MathAbs(h[s] - c[s + 1]), MathAbs(l[s] - c[s + 1])));
}

double LinReg(const double &src[], int p, int s)
{
   double SumY = 0, Sum1 = 0;
   for (int x = 0; x < p; x++)
   {
      double c = src[x + s];
      SumY += c;
      Sum1 += x * c;
   }
   double SumBars = p * (p - 1) * 0.5;
   double SumSqr  = (p - 1.0) * p * (2.0 * p - 1) / 6.0;
   double Num2    = SumBars * SumBars - p * SumSqr;
   double Slope   = (Num2 != 0) ? (p * Sum1 - SumBars * SumY) / Num2 : 0;
   return (SumY - Slope * SumBars) / p + Slope * (p - 1);
}
//+------------------------------------------------------------------+
