//+------------------------------------------------------------------+
//|                             ehlers_autocorrelation_reversals.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Autocorrelation Reversals - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_maximum  1.2
#property indicator_minimum  0
#property indicator_label1  "Autocorrelation Reversals"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrFireBrick
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2

#include "EhlersCommon.mqh"

input enPrices Price     = pr_close; // Price Type
input int      avgLength = 3;        // Averaging Length
input int      hpPeriod  = 48;       // High Pass Period
input int      lpPeriod  = 10;       // Low Pass Period

double result[];
double filtBuf[];
double highPassBuf[];
double work[];

EhlersHPCoeffs g_hp;
EhlersLPCoeffs g_lp;
double g_corr[];      // current bar Pearson correlations (scaled 0..1)
double g_corrPrev[];  // previous bar correlations (file-scope to avoid per-bar heap alloc)

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, filtBuf,     INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, highPassBuf, INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "ACRev(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
   if (lpPeriod < 1 || hpPeriod < 1) return INIT_PARAMETERS_INCORRECT;
   ComputeHPCoeffs(hpPeriod, g_hp);
   ComputeLPCoeffs(lpPeriod, g_lp);
   ArrayResize(g_corr, hpPeriod + 1);
   ArrayResize(g_corrPrev, hpPeriod + 1);
   ArrayInitialize(g_corr, 0);
   ArrayInitialize(g_corrPrev, 0);
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
   if (rates_total < hpPeriod + 3) return 0;
   if (ArrayRange(work, 0) != rates_total)
      ArrayResize(work, rates_total);

   int avLen = (avgLength == 0) ? hpPeriod : avgLength;

   if (prev_calculated == 0) { ArrayInitialize(g_corr, 0); ArrayInitialize(g_corrPrev, 0); }
   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      filtBuf[i]     = LowPass(g_lp, highPassBuf, filtBuf, i);

      if (i <= hpPeriod + 1 + avLen)
      {
         result[i] = 0;
         continue;
      }

      // Pearson correlation with lagged copy tracking
      for (int lag = 0; lag <= hpPeriod; lag++)
      {
         g_corrPrev[lag] = g_corr[lag]; // save previous bar's correlation

         double m = (avgLength == 0) ? (double)lag : (double)avgLength;
         double Sx=0, Sy=0, Sxx=0, Syy=0, Sxy=0;
         for (int c = 0; c < (int)m; c++)
         {
            double X = filtBuf[i - c];
            double Y = filtBuf[i - lag - c];
            Sx  += X;     Sy  += Y;
            Sxx += X * X; Sxy += X * Y;
            Syy += Y * Y;
         }
         double denom = (m * Sxx - Sx * Sx) * (m * Syy - Sy * Sy);
         if (denom > 0)
         {
            double r = (m * Sxy - Sx * Sy) / MathSqrt(denom);
            g_corr[lag] = 0.5 * (r + 1.0); // scale to 0..1
         }
      }

      // Count threshold crossings between current and previous correlations
      int sumDeltas = 0;
      for (int lag = 3; lag <= hpPeriod; lag++)
      {
         if ((g_corr[lag] > 0.5 && g_corrPrev[lag] < 0.5) ||
             (g_corr[lag] < 0.5 && g_corrPrev[lag] > 0.5))
            sumDeltas++;
      }

      result[i] = (sumDeltas > 24) ? 1 : 0;
   }
   return rates_total;
}
//+------------------------------------------------------------------+
