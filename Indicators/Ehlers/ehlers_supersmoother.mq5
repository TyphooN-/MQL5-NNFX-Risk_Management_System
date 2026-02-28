//+------------------------------------------------------------------+
//|                                         ehlers_supersmoother.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Supersmoother Filter - Ehlers Cycle Analytics"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "SuperSmoother"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrOrange
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2

#include "EhlersCommon.mqh"

input enPrices Price    = pr_close; // Price Type
input int      lpPeriod = 10;       // Low Pass Period

double result[];
double work[];

EhlersLPCoeffs g_lp;

int OnInit()
{
   SetIndexBuffer(0, result, INDICATOR_DATA);
   IndicatorSetString(INDICATOR_SHORTNAME, "SSmoother(" + IntegerToString(lpPeriod) + ")");
   ComputeLPCoeffs(lpPeriod, g_lp);
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
   if (rates_total < 4) return 0;
   if (ArrayRange(work, 0) != rates_total)
      ArrayResize(work, rates_total);

   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]   = getPrice(Price, open, close, high, low, i, rates_total);
      result[i] = LowPass(g_lp, work, result, i);
   }
   return rates_total;
}
//+------------------------------------------------------------------+
