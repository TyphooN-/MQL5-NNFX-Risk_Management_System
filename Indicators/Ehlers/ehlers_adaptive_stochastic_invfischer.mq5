//+------------------------------------------------------------------+
//|                        ehlers_adaptive_stochastic_invfischer.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Adaptive Stochastic Inv Fischer - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2
#property indicator_maximum  1.2
#property indicator_minimum -1.2
#property indicator_level1   0
#property indicator_label1  "Adaptive Stochastic Inv Fischer"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrPurple
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2
#property indicator_label2  "Signal"
#property indicator_type2    DRAW_LINE
#property indicator_color2   clrDodgerBlue
#property indicator_style2   STYLE_DASH
#property indicator_width2   2

#include "EhlersCommon.mqh"

input enPrices Price     = pr_close; // Price Type
input int      avgLength = 3;        // Averaging Length
input int      hpPeriod  = 48;       // High Pass Period
input int      lpPeriod  = 10;       // Low Pass Period

double result[];
double signalBuf[];
double filtBuf[];
double highPassBuf[];
double stochBuf[];
double adapStochBuf[];
double work[];

EhlersHPCoeffs     g_hp;
EhlersLPCoeffs     g_lp;
DominantCycleState g_dc;

int OnInit()
{
   SetIndexBuffer(0, result,       INDICATOR_DATA);
   SetIndexBuffer(1, signalBuf,    INDICATOR_DATA);
   SetIndexBuffer(2, filtBuf,      INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, highPassBuf,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, stochBuf,     INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, adapStochBuf, INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "AStochIF(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
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
         stochBuf[i]     = 0;
         adapStochBuf[i] = 0;
         result[i]       = 0;
         signalBuf[i]    = 0;
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

      // Supersmoother on stochastic
      adapStochBuf[i] = g_lp.c1 * (stochBuf[i] + stochBuf[i-1]) / 2.0
                        + g_lp.c2 * adapStochBuf[i-1] + g_lp.c3 * adapStochBuf[i-2];

      // Inverse Fischer transform
      double value1 = 2.0 * (adapStochBuf[i] - 0.5);
      result[i] = (MathExp(2.0 * 3.0 * value1) - 1.0) / (MathExp(2.0 * 3.0 * value1) + 1.0);
      signalBuf[i] = 0.9 * result[i-1];
   }
   return rates_total;
}
//+------------------------------------------------------------------+
