//+------------------------------------------------------------------+
//|                                  ehlers_even_better_sinewave.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: thetestspecimen                         |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Even Better Sinewave - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_maximum  1.2
#property indicator_minimum -1.2
#property indicator_level1  -0.707
#property indicator_level2   0.707
#property indicator_label1  "Even Better Sinewave"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrLightBlue
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2

#include "EhlersCommon.mqh"

input enPrices Price    = pr_close; // Price Type
input int      lpPeriod = 10;       // Low Pass Period
input int      hpPeriod = 40;       // High Pass Period

double result[];
double highPassBuf[];
double filtBuf[];
double work[];

EhlersHPCoeffs g_hp;
EhlersLPCoeffs g_lp;

int OnInit()
{
   SetIndexBuffer(0, result,      INDICATOR_DATA);
   SetIndexBuffer(1, highPassBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, filtBuf,     INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "EBSW(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
   if (lpPeriod < 1 || hpPeriod < 1) return INIT_PARAMETERS_INCORRECT;
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
   if (rates_total < 4) return 0;
   if (ArrayRange(work, 0) != rates_total)
      ArrayResize(work, rates_total);

   int start = (int)MathMax(prev_calculated - 1, 0);
   for (int i = start; i < rates_total && !IsStopped(); i++)
   {
      work[i]        = getPrice(Price, open, close, high, low, i, rates_total);
      highPassBuf[i] = HighPass(g_hp, work, highPassBuf, i);
      filtBuf[i]     = LowPass(g_lp, highPassBuf, filtBuf, i);

      if (i < 3)
      {
         result[i] = 0;
      }
      else
      {
         double wave = (filtBuf[i] + filtBuf[i-1] + filtBuf[i-2]) / 3.0;
         double pwr  = (filtBuf[i]*filtBuf[i] + filtBuf[i-1]*filtBuf[i-1] + filtBuf[i-2]*filtBuf[i-2]) / 3.0;
         result[i] = (pwr > 0) ? wave / MathSqrt(pwr) : 0;
      }
   }
   return rates_total;
}
//+------------------------------------------------------------------+
