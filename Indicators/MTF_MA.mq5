//+------------------------------------------------------------------+
//|                                                    MTF_MA.mq5    |
//|                    Multi Timeframe MA Bull/Bear Power Indicator   |
//|                    200/100/50/20/10 SMA across M1-W1 timeframes  |
//+------------------------------------------------------------------+
#property copyright   "TyphooN"
#property link        "https://www.marketwizardry.org"
#property version     "1.079"
#property indicator_chart_window
#property indicator_buffers 41
#property indicator_plots   6

#property indicator_label1  "H1 200SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrTomato
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "H4 200SMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMagenta
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "D1 200SMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#property indicator_label4  "W1 200SMA"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrMagenta
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

#property indicator_label5  "W1 100SMA"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

#property indicator_label6  "MN1 100SMA"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrMagenta
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2

#include "MTF_MA.mqh"
