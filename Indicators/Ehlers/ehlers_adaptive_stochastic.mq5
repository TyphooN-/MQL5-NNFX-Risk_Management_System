//+------------------------------------------------------------------+
//|                                   ehlers_adaptive_stochastic.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Adaptive Stochastic - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_maximum  1.2
#property indicator_minimum -0.2
#property indicator_level1   0.3
#property indicator_level2   0.7
#property indicator_label1  "Adaptive Stochastic"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrPurple
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
double stochBuf[];
double work[];

EhlersHPCoeffs     g_hp;
EhlersLPCoeffs     g_lp;
DominantCycleState g_dc;

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, filtBuf,     INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, highPassBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, stochBuf,    INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "AStoch(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
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

   if (prev_calculated == 0) ResetDominantCycle(g_dc);
   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      filtBuf[i]     = LowPass(g_lp, highPassBuf, filtBuf, i);

      if (i <= hpPeriod + 1)
      {
         stochBuf[i] = 0;
         result[i]   = 0;
         continue;
      }

      double domCycle = ComputeDominantCycle(g_dc, filtBuf, i, avgLength);
      int dc = (int)domCycle;

      // Stochastic over dominant cycle
      double highestC = filtBuf[i];
      double lowestC  = filtBuf[i];
      for (int c = 0; c < dc; c++)
      {
         if (filtBuf[i - c] > highestC) highestC = filtBuf[i - c];
         if (filtBuf[i - c] < lowestC)  lowestC  = filtBuf[i - c];
      }

      stochBuf[i] = (highestC - lowestC != 0) ? (filtBuf[i] - lowestC) / (highestC - lowestC) : 0;

      // Supersmoother
      result[i] = g_lp.c1 * (stochBuf[i] + stochBuf[i-1]) / 2.0
                  + g_lp.c2 * result[i-1] + g_lp.c3 * result[i-2];
   }
   return rates_total;
}
//+------------------------------------------------------------------+
