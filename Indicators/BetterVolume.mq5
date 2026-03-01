//+------------------------------------------------------------------+
//|                                               BetterVolume.mq5   |
//|                    Port of Emini-Watch Better Volume indicator    |
//|                    Classifies volume using buy/sell pressure      |
//+------------------------------------------------------------------+
#property copyright   "TyphooN"
#property link        "https://marketwizardry.org"
#property version     "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2

// Plot 1 - volume color histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_width1  2
#property indicator_color1  clrYellow,clrRed,clrWhite,clrGreen,clrMagenta,clrSteelBlue
#property indicator_label1  "Volume"

// Plot 2 - average volume line
#property indicator_type2   DRAW_LINE
#property indicator_width2  1
#property indicator_color2  clrDodgerBlue
#property indicator_label2  "AvgVol"

#include "BetterVolume.mqh"
