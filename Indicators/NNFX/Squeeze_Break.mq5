//+------------------------------------------------------------------+
//|                                               Squeeze_Break.mq5  |
//|        Based on John Carter's "Mastering the Trade" strategy      |
//|                          Original MQ4: DesO'Regan                 |
//|                          Converted to MQ5                         |
//+------------------------------------------------------------------+
//  Green histogram = BB outside KC (trending/volatile)
//  Red histogram   = BB inside KC (consolidating/squeeze)
//  Blue line       = Momentum (close minus close N bars ago)
//  Alert fires on squeeze-to-breakout transition.
//+------------------------------------------------------------------+
#property copyright "DesORegan"
#property link      "mailto: oregan_des@hotmail.com"
#property version   "2.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrForestGreen
#property indicator_width1  3
#property indicator_label1  "Breakout"

#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_width2  3
#property indicator_label2  "Squeeze"

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_DOT
#property indicator_width3  1
#property indicator_label3  "Momentum"

input int    BollPeriod     = 20;   // Bollinger Period
input double BollDev        = 2.0;  // Bollinger Deviation
input int    KeltnerPeriod  = 20;   // Keltner Period
input double KeltnerMul     = 1.5;  // Keltner Multiplier
input int    MomentumPeriod = 12;   // Momentum Period
input bool   AlertOn        = true; // Enable Alerts

double PosHist[], NegHist[], Mom[];

bool     g_prevSqueeze;
datetime g_lastAlertTime;

int OnInit()
{
   SetIndexBuffer(0, PosHist, INDICATOR_DATA);
   SetIndexBuffer(1, NegHist, INDICATOR_DATA);
   SetIndexBuffer(2, Mom,     INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,
      "SqzBreak(B:" + IntegerToString(BollPeriod) + "," + DoubleToString(BollDev, 1) +
      " K:" + IntegerToString(KeltnerPeriod) + "," + DoubleToString(KeltnerMul, 1) +
      " M:" + IntegerToString(MomentumPeriod) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, 4);
   ArraySetAsSeries(PosHist, true);
   ArraySetAsSeries(NegHist, true);
   ArraySetAsSeries(Mom,     true);
   g_prevSqueeze   = false;
   g_lastAlertTime = 0;
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
   ArraySetAsSeries(time,  true);

   int lookback = (int)MathMax(MomentumPeriod, KeltnerPeriod) + BollPeriod + 2;
   if (rates_total < lookback) return 0;

   int limit;
   if (prev_calculated <= 0)
      limit = rates_total - lookback;
   else
      limit = rates_total - prev_calculated + 1;
   if (limit > rates_total - lookback) limit = rates_total - lookback;
   if (limit < 0) limit = 0;

   for (int i = limit; i >= 0; i--)
   {
      // --- Keltner Channel (SMA of High/Low/Typical) ---
      double maHi  = SMA(high, KeltnerPeriod, i);
      double maLo  = SMA(low,  KeltnerPeriod, i);
      double keltMid = 0;
      for (int j = 0; j < KeltnerPeriod; j++)
         keltMid += (high[i + j] + low[i + j] + close[i + j]) / 3.0;
      keltMid /= KeltnerPeriod;
      double keltUpper = keltMid + (maHi - maLo) * KeltnerMul;
      double keltLower = keltMid - (maHi - maLo) * KeltnerMul;

      // --- Bollinger Bands ---
      double bollMid = SMA(close, BollPeriod, i);
      double stddev  = StdDev(close, BollPeriod, i, bollMid);
      double bollUpper = bollMid + BollDev * stddev;
      double bollLower = bollMid - BollDev * stddev;

      // --- Momentum ---
      Mom[i] = close[i] - close[i + MomentumPeriod];

      // --- Squeeze / Breakout detection ---
      bool squeeze  = (bollUpper < keltUpper) && (bollLower > keltLower);
      bool breakout = (bollUpper >= keltUpper) || (bollLower <= keltLower);

      if (breakout)
      {
         PosHist[i] = MathAbs(bollUpper - keltUpper) + MathAbs(bollLower - keltLower);
         NegHist[i] = EMPTY_VALUE;
      }
      else if (squeeze)
      {
         NegHist[i] = -(MathAbs(bollUpper - keltUpper) + MathAbs(bollLower - keltLower));
         PosHist[i] = EMPTY_VALUE;
      }
      else
      {
         PosHist[i] = EMPTY_VALUE;
         NegHist[i] = EMPTY_VALUE;
      }

      // --- Alert on squeeze-to-breakout transition (bar 0 only) ---
      if (AlertOn && i == 0 && breakout && g_prevSqueeze && g_lastAlertTime != time[0])
      {
         string dir = (Mom[0] > 0) ? "LONG" : "SHORT";
         Alert("Squeeze Break: ", _Symbol, " ", dir, " breakout at ", TimeToString(TimeCurrent()));
         g_lastAlertTime = time[0];
      }
      if (i == 0) g_prevSqueeze = squeeze;
   }
   return rates_total;
}

//+------------------------------------------------------------------+
//| Helper functions                                                 |
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
//+------------------------------------------------------------------+
