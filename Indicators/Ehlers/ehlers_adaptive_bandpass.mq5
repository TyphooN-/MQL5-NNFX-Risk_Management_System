//+------------------------------------------------------------------+
//|                                     ehlers_adaptive_bandpass.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Adaptive BandPass - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_maximum  1.2
#property indicator_minimum -1.2
#property indicator_level1  -0.707
#property indicator_level2   0.707
#property indicator_label1  "Adaptive BandPass"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrGoldenrod
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2
#property indicator_label2  "Bandpass Signal"
#property indicator_type2    DRAW_LINE
#property indicator_color2   clrDodgerBlue
#property indicator_style2   STYLE_DASH
#property indicator_width2   2

#include "EhlersCommon.mqh"

input enPrices Price     = pr_close; // Price Type
input double   bandwidth = 0.3;      // Bandwidth
input int      avgLength = 3;        // Averaging Length
input int      hpPeriod  = 48;       // High Pass Period
input int      lpPeriod  = 10;       // Low Pass Period

double result[];
double signal[];
double filtBuf[];
double highPassBuf[];
double bandPassBuf[];
double work[];

EhlersHPCoeffs     g_hp;
EhlersLPCoeffs     g_lp;
DominantCycleState g_dc;
double g_peak = 0;

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, signal,      INDICATOR_DATA);
   SetIndexBuffer(2, filtBuf,     INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, highPassBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, bandPassBuf, INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "ABP(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
   if (lpPeriod < 1 || hpPeriod < 1) return INIT_PARAMETERS_INCORRECT;
   ComputeHPCoeffs(hpPeriod, g_hp);
   ComputeLPCoeffs(lpPeriod, g_lp);
   InitDominantCycle(g_dc, lpPeriod, hpPeriod);
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

   if (prev_calculated == 0) { ResetDominantCycle(g_dc); g_peak = 0; }
   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      filtBuf[i]     = LowPass(g_lp, highPassBuf, filtBuf, i);

      if (i <= hpPeriod + 1)
      {
         bandPassBuf[i] = 0;
         result[i]      = 0;
         signal[i]      = 0;
         continue;
      }

      double domCycle = ComputeDominantCycle(g_dc, filtBuf, i, avgLength);
      int dc = (int)domCycle;

      // Bandpass filter
      double beta1  = MathCos(2.0 * EHLERS_PI / (0.9 * dc));
      double gamma1 = 1.0 / MathCos(2.0 * EHLERS_PI * bandwidth / (0.9 * dc));
      double alpha2 = gamma1 - MathSqrt(gamma1 * gamma1 - 1.0);

      bandPassBuf[i] = 0.5 * (1.0 - alpha2) * (filtBuf[i] - filtBuf[i-2])
                       + beta1 * (1.0 + alpha2) * bandPassBuf[i-1]
                       - alpha2 * bandPassBuf[i-2];

      // AGC peak normalization
      g_peak *= 0.991;
      if (MathAbs(bandPassBuf[i]) > g_peak)
         g_peak = MathAbs(bandPassBuf[i]);

      result[i] = (g_peak != 0) ? bandPassBuf[i] / g_peak : 0;
      signal[i] = 0.9 * result[i-1];
   }
   return rates_total;
}
//+------------------------------------------------------------------+
