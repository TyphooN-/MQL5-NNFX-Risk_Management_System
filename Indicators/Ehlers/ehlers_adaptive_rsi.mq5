//+------------------------------------------------------------------+
//|                                          ehlers_adaptive_rsi.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Adaptive RSI - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_maximum  1.2
#property indicator_minimum -0.2
#property indicator_level1   0.3
#property indicator_level2   0.7
#property indicator_label1  "Adaptive RSI"
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
double denomBuf[];
double work[];

//--- Prefix sums of |Δfilt|⁺ / |Δfilt|⁻ for O(1) window sums
double g_cumPos[], g_cumNeg[];

EhlersHPCoeffs  g_hp;
EhlersLPCoeffs  g_lp;
DominantCycleState g_dc;
double g_closesUpOld = 0;

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, filtBuf,     INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, highPassBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, denomBuf,    INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "ARSI(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
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
      if (ArrayResize(work, rates_total) == -1) return 0;
   if (ArrayRange(g_cumPos, 0) != rates_total)
      if (ArrayResize(g_cumPos, rates_total) == -1 ||
          ArrayResize(g_cumNeg, rates_total) == -1) return 0;

   if (prev_calculated == 0) { ResetDominantCycle(g_dc); g_closesUpOld = 0; }
   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      filtBuf[i]     = LowPass(g_lp, highPassBuf, filtBuf, i);

      //--- Incremental prefix sums of positive/negative filt deltas
      double pd = 0, nd = 0;
      if (i > 0)
      {
         double d = filtBuf[i] - filtBuf[i-1];
         if (d > 0)      pd = d;
         else if (d < 0) nd = -d;
      }
      g_cumPos[i] = (i > 0 ? g_cumPos[i-1] : 0) + pd;
      g_cumNeg[i] = (i > 0 ? g_cumNeg[i-1] : 0) + nd;

      if (i <= hpPeriod + 1)
      {
         denomBuf[i] = 0;
         result[i]   = 0;
         continue;
      }

      double domCycle = ComputeDominantCycle(g_dc, filtBuf, i, avgLength);
      int rsiDomCycle = (int)(domCycle / 2.0 - 1.0);
      if (rsiDomCycle < 0) rsiDomCycle = 0;

      //--- Window sum of posDelta/negDelta over [i-rsiDomCycle, i]
      int lowIdx = i - rsiDomCycle - 1;
      double closeUp, closeDown;
      if (lowIdx >= 0)
      {
         closeUp   = g_cumPos[i] - g_cumPos[lowIdx];
         closeDown = g_cumNeg[i] - g_cumNeg[lowIdx];
      }
      else
      {
         closeUp   = g_cumPos[i];
         closeDown = g_cumNeg[i];
      }

      denomBuf[i] = closeUp + closeDown;

      if (denomBuf[i] != 0 && denomBuf[i-1] != 0)
         result[i] = g_lp.c1 * (closeUp / denomBuf[i] + g_closesUpOld / denomBuf[i-1]) / 2.0
                     + g_lp.c2 * result[i-1] + g_lp.c3 * result[i-2];
      else
         result[i] = 0;

      g_closesUpOld = closeUp;
   }
   return rates_total;
}
//+------------------------------------------------------------------+
