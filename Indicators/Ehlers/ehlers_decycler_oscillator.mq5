//+------------------------------------------------------------------+
//|                                   ehlers_decycler_oscillator.mq5 |
//|         Copyright 2013, John F. Ehlers. All rights reserved.     |
//|         MQL5 conversion: Copyright 2020, thetestspecimen (MIT)   |
//|         Optimized: TyphooN (https://www.marketwizardry.org/)     |
//+------------------------------------------------------------------+
#property copyright "2013, John F. Ehlers"
#property link      "https://github.com/thetestspecimen"
#property version   "1.01"
#property description "Decycler Oscillator - Ehlers Cycle Analytics"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_level1  0
#property indicator_label1  "Decycler Oscillator"
#property indicator_type1    DRAW_LINE
#property indicator_color1   clrLightBlue
#property indicator_style1   STYLE_SOLID
#property indicator_width1   2

#include "EhlersCommon.mqh"

input enPrices Price    = pr_close; // Price Type
input int      lpPeriod = 30;       // Low Pass Period
input int      hpPeriod = 60;       // High Pass Period

double result[];
double hpBuf[];
double lpBuf[];
double work[];

EhlersHPCoeffs g_hpLP;
EhlersHPCoeffs g_hpHP;

int OnInit()
{
   SetIndexBuffer(0, result, INDICATOR_DATA);
   SetIndexBuffer(1, hpBuf,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, lpBuf,  INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME, "DecOsc(" + IntegerToString(lpPeriod) + "," + IntegerToString(hpPeriod) + ")");
   ComputeHPCoeffs(lpPeriod, g_hpLP);
   ComputeHPCoeffs(hpPeriod, g_hpHP);
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
      lpBuf[i]  = HighPass(g_hpLP, work, lpBuf, i);
      hpBuf[i]  = HighPass(g_hpHP, work, hpBuf, i);
      result[i] = (i < 3) ? 0 : hpBuf[i] - lpBuf[i];
   }
   return rates_total;
}
//+------------------------------------------------------------------+
