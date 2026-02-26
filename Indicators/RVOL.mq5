#property copyright "Darwinex & Trade Like A Machine Ltd / TyphooN"
#property link      "http://www.darwinex.com"
#property strict
#property version   "1.001"

// Indicator Settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrGreen, clrOrange, clrRed
#property indicator_style1  0
#property indicator_width1  3

// Level of above average (1.25) and below average (0.8) volume (for time of day) - (ratio of 1.0 indicates current volume is the same as average)
#property indicator_level1 1.25 // Above Average Volume Level
#property indicator_level2 0.8  // Below Average Volume Level

#include "RVOL.mqh"
