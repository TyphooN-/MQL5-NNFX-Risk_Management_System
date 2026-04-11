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

//--- Monotone deque for O(1) amortized sliding window max/min
int g_maxDeque[], g_minDeque[];
int g_maxHead, g_maxTail, g_minHead, g_minTail;

int OnInit()
  {
   if(periodInp <= 0) return INIT_PARAMETERS_INCORRECT;
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
   //--- Pre-allocate deques for O(1) amortized sliding window max/min
   if (ArrayResize(g_maxDeque, periodInp + 1) == -1 ||
       ArrayResize(g_minDeque, periodInp + 1) == -1)
      return INIT_FAILED;
   g_maxHead = 0; g_maxTail = 0;
   g_minHead = 0; g_minTail = 0;
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
   if(rates_total < periodInp)
      return (0);

   //--- Determine start bar (non-series: 0 = oldest)
   //--- high[]/low[] are non-series by default in MQL5 OnCalculate
   int startBar;
   if(prev_calculated <= 0)
   {
      startBar = 0;
   }
   else
   {
      //--- Incremental: rebuild deque from window start of last processed bar
      startBar = MathMax(0, prev_calculated - 1 - periodInp);
   }
   //--- Always reset deques — O(Period) rebuild on incremental, O(N) on full load
   g_maxHead = 0; g_maxTail = 0;
   g_minHead = 0; g_minTail = 0;

   int dqSize = periodInp + 1;

   for(int bar = startBar; bar < rates_total && !IsStopped(); bar++)
   {
      int windowStart = bar - periodInp + 1;
      if(windowStart < 0) windowStart = 0;

      //--- Max deque for high[] — maintain decreasing order
      while(g_maxHead != g_maxTail && high[g_maxDeque[(g_maxTail - 1) % dqSize]] <= high[bar])
         g_maxTail--;
      g_maxDeque[g_maxTail % dqSize] = bar;
      g_maxTail++;
      while(g_maxHead != g_maxTail && g_maxDeque[g_maxHead % dqSize] < windowStart)
         g_maxHead++;

      //--- Min deque for low[] — maintain increasing order
      while(g_minHead != g_minTail && low[g_minDeque[(g_minTail - 1) % dqSize]] >= low[bar])
         g_minTail--;
      g_minDeque[g_minTail % dqSize] = bar;
      g_minTail++;
      while(g_minHead != g_minTail && g_minDeque[g_minHead % dqSize] < windowStart)
         g_minHead++;

      if(bar >= periodInp - 1)
      {
         int highIdx = g_maxDeque[g_maxHead % dqSize];
         int lowIdx  = g_minDeque[g_minHead % dqSize];
         //--- Convert to series index for output buffers
         int si = rates_total - 1 - bar;
         //--- bars since highest high / lowest low
         upBuffer[si]   = (double)(periodInp - (bar - highIdx)) * 100.0 / periodInp;
         downBuffer[si] = (double)(periodInp - (bar - lowIdx))  * 100.0 / periodInp;
      }
   }

   return (rates_total);
  }
//+------------------------------------------------------------------+
