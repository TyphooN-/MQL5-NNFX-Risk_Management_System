//+------------------------------------------------------------------+
//|                                        ehlers_roofing_filter.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Roofing Filter - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_label1  "Roofing Filter"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrGoldenrod
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2
#property indicator_label2  "Signal"
#property indicator_type2    DRAW_LINE
#property indicator_color2   clrDodgerBlue
#property indicator_style2   STYLE_DASH
#property indicator_width2   2

#include "EhlersCommon.mqh"

input enPrices Price    = pr_close; // Price Type
input int      hpPeriod = 80;       // High Pass Period
input int      lpPeriod = 40;       // Low Pass Period

double result[];
double signal[];
double highPassBuf[];
double work[];

EhlersHPCoeffs g_hp;
EhlersLPCoeffs g_lp;

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, signal,      INDICATOR_DATA);
   SetIndexBuffer(2, highPassBuf, INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "Roof(" + IntegerToString(hpPeriod) + "," + IntegerToString(lpPeriod) + ")");
   ComputeHPCoeffs(hpPeriod, g_hp);
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
   if (rates_total < 5) return 0;
   if (ArrayRange(work, 0) != rates_total)
      ArrayResize(work, rates_total);

   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      result[i]      = LowPass(g_lp, highPassBuf, result, i);
      signal[i]      = (i > 3) ? result[i-2] : 0;
   }
   return rates_total;
}
//+------------------------------------------------------------------+
