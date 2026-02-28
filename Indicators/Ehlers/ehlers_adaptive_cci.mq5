//+------------------------------------------------------------------+
//|                                          ehlers_adaptive_cci.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Adaptive CCI - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_maximum  200
#property indicator_minimum -200
#property indicator_level1  -100
#property indicator_level2   100
#property indicator_label1  "Adaptive CCI"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrDeepSkyBlue
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
double ratioBuf[];
double avePriceBuf[];
double work[];

EhlersHPCoeffs     g_hp;
EhlersLPCoeffs     g_lp;
DominantCycleState g_dc;

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, filtBuf,     INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, highPassBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, ratioBuf,    INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, avePriceBuf, INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "ACCI(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
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

   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      filtBuf[i]     = LowPass(g_lp, highPassBuf, filtBuf, i);

      if (i <= hpPeriod + 1)
      {
         ratioBuf[i]    = 0;
         avePriceBuf[i] = 0;
         result[i]      = 0;
         continue;
      }

      double domCycle = ComputeDominantCycle(g_dc, filtBuf, i, avgLength);
      int dc = (int)domCycle;

      // Average price over dominant cycle
      double avePrice = 0;
      for (int c = 0; c < dc; c++)
         avePrice += filtBuf[i - c];
      avePrice /= (double)dc;
      avePriceBuf[i] = avePrice;

      // RMS deviation
      double rms = 0;
      for (int c = 0; c < dc; c++)
         rms += (filtBuf[i - c] - avePriceBuf[i - c]) * (filtBuf[i - c] - avePriceBuf[i - c]);
      rms = MathSqrt(rms / (double)dc);

      double num   = filtBuf[i] - avePrice;
      double denom = 0.015 * rms;
      ratioBuf[i] = num / denom;

      // Supersmoother on ratio
      result[i] = g_lp.c1 * (ratioBuf[i] + ratioBuf[i-1]) / 2.0
                  + g_lp.c2 * result[i-1] + g_lp.c3 * result[i-2];
   }
   return rates_total;
}
//+------------------------------------------------------------------+
