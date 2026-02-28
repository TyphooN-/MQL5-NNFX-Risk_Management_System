//+------------------------------------------------------------------+
//|                                                        Aroon.mq5 |
//+------------------------------------------------------------------+
#property indicator_separate_window // the place of the indicator
#property indicator_buffers 2 // number of buffers
#property indicator_plots 2 // number of plots
#property indicator_type1  DRAW_LINE      // type of the up values to be drawn is a line
#property indicator_color1 clrGreen       // up line color
#property indicator_style1 STYLE_DASH     // up line style
#property indicator_width1 2              // up line width
#property indicator_label1 "Up"           // up line label
#property indicator_type2  DRAW_LINE      // type of the down values to be drawn is a line
#property indicator_color2 clrRed         // down line color
#property indicator_style2 STYLE_DASH     // down line style
#property indicator_width2 2              // down line width
#property indicator_label2 "Down"         // down line label
#property indicator_level1 10.0
#property indicator_level2 50.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
input int periodInp = 25; // Period
input int shiftInp  = 0;  // horizontal shift
double    upBuffer[];
double    downBuffer[];
int OnInit()
  {
   SetIndexBuffer(0, upBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, downBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_SHIFT, shiftInp);
   PlotIndexSetInteger(1, PLOT_SHIFT, shiftInp);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, periodInp);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, periodInp);
   ArraySetAsSeries(upBuffer, true);
   ArraySetAsSeries(downBuffer, true);
   string indicatorName = StringFormat("Aroon Indicator (%i,%i) - ", periodInp, shiftInp);
   IndicatorSetString(INDICATOR_SHORTNAME, indicatorName);
   IndicatorSetInteger(INDICATOR_DIGITS, 0);
   return INIT_SUCCEEDED;
  }
int OnCalculate(const int       rates_total,
                const int       prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
  {
   if(rates_total < periodInp - 1)
      return (0);
   int count = rates_total - prev_calculated;
   if(prev_calculated > 0)
      count++;
   if(count > (rates_total - periodInp + 1))
      count = (rates_total - periodInp + 1);
   for(int i = count - 1; i >= 0; i--)
     {
      int highestVal   = iHighest(Symbol(), Period(), MODE_HIGH, periodInp, i);
      int lowestVal    = iLowest(Symbol(), Period(), MODE_LOW, periodInp, i);
      upBuffer[i]   = (periodInp - (highestVal - i)) * 100 / periodInp;
      downBuffer[i] = (periodInp - (lowestVal - i)) * 100 / periodInp;
     }
   return (rates_total);
  }
//+------------------------------------------------------------------+
