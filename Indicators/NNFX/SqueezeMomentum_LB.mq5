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

   for (int pos = limit; pos >= 0; pos--)
   {
      // --- Bollinger Bands ---
      double basis = SMA(close, BBLength, pos);
      double dev   = BBMult * StdDev(close, BBLength, pos, basis);
      double upperBB = basis + dev;
      double lowerBB = basis - dev;

      // --- Keltner Channel ---
      double ma = SMA(close, KCLength, pos);
      RangeBuf[pos] = UseTrueRange ? TrueRange(high, low, close, pos) : (high[pos] - low[pos]);
      double rangema = SMA(RangeBuf, KCLength, pos);
      double upperKC = ma + rangema * KCMult;
      double lowerKC = ma - rangema * KCMult;

      // --- Squeeze state ---
      bool sqzOn  = (lowerBB > lowerKC) && (upperBB < upperKC);
      bool sqzOff = (lowerBB < lowerKC) && (upperBB > upperKC);

      // --- Momentum via linear regression ---
      double highest = high[Highest(high, KCLength, pos)];
      double lowest  = low[Lowest(low, KCLength, pos)];
      double sma     = SMA(close, KCLength, pos);
      LinSrc[pos] = close[pos] - ((highest + lowest) / 2.0 + sma) / 2.0;
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
   }
   return rates_total;
}

//+------------------------------------------------------------------+
//| Helper functions — self-contained, no handles needed             |
//+------------------------------------------------------------------+
double SMA(const double &a[], int p, int s)
{
   double sum = 0;
   for (int i = 0; i < p; i++) sum += a[s + i];
   return sum / p;
}

double StdDev(const double &a[], int p, int s, double mean)
{
   double sq = 0;
   for (int i = 0; i < p; i++) { double d = a[s + i] - mean; sq += d * d; }
   return MathSqrt(sq / p);
}

double TrueRange(const double &h[], const double &l[], const double &c[], int s)
{
   return MathMax(h[s] - l[s], MathMax(MathAbs(h[s] - c[s + 1]), MathAbs(l[s] - c[s + 1])));
}

int Highest(const double &a[], int cnt, int start)
{
   int idx = start;
   double mx = a[start];
   for (int i = 1; i < cnt; i++)
      if (a[start + i] > mx) { mx = a[start + i]; idx = start + i; }
   return idx;
}

int Lowest(const double &a[], int cnt, int start)
{
   int idx = start;
   double mn = a[start];
   for (int i = 1; i < cnt; i++)
      if (a[start + i] < mn) { mn = a[start + i]; idx = start + i; }
   return idx;
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
