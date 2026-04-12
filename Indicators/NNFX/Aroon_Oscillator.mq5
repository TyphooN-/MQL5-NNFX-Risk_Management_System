//+------------------------------------------------------------------+
//|                                              AroonOscillator.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2011, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru"
//---- Indicator Version Number
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//----two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- Drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- lime color is used as the color of a bullish candlestick
#property indicator_color1  Lime
//---- line of the indicator 1 is a solid curve
#property indicator_style1  STYLE_SOLID
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- bullish indicator label display
#property indicator_label1  "BullsAroon"
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- red color is used as the color of the bearish indicator line
#property indicator_color2  Red
//---- line of the indicator 2 is a solid curve
#property indicator_style2  STYLE_SOLID
//---- thickness of line of the indicator 2 is equal to 1
#property indicator_width2  1
//---- bearish indicator label display
#property indicator_label2  "BearsAroon"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 70.0
#property indicator_level2 50.0
#property indicator_level3 30.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| Input parameters of the indicator            |
//+----------------------------------------------+
input int AroonPeriod= 9; // period of the indicator
input int AroonShift = 0; // horizontal shift of the indicator in bars
//+----------------------------------------------+
//---- declaration of dynamic arrays that further
// will be used as indicator buffers
double BullsAroonBuffer[];
double BearsAroonBuffer[];

//--- Monotone deques for O(1) amortized sliding-window HH/LL over AroonPeriod
//--- Strict inequalities preserve original's "oldest wins on tie" semantics
int g_maxDq[], g_minDq[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

  ArraySetAsSeries(BullsAroonBuffer, false);
  ArraySetAsSeries(BearsAroonBuffer, false);

//---- transformation of the BullsAroonBuffer dynamic indicator into an indicator buffer
   SetIndexBuffer(0,BullsAroonBuffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by AroonShift
   PlotIndexSetInteger(0,PLOT_SHIFT,AroonShift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by AroonPeriod
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,AroonPeriod);
//--- creation of a label to be displayed in the Data Window
   PlotIndexSetString(0,PLOT_LABEL,"BullsAroon");

//---- transformation of the BearsAroonBuffer dynamic array into an indicator buffer
   SetIndexBuffer(1,BearsAroonBuffer,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by AroonShift
   PlotIndexSetInteger(1,PLOT_SHIFT,AroonShift);
//---- performing shift of the beginning of counting of drawing the indicator 2 by AroonPeriod
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,AroonPeriod);
//--- creation of a label to be displayed in the Data Window
   PlotIndexSetString(1,PLOT_LABEL,"BearsAroon");

//---- Initialization of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Aroon(",AroonPeriod,", ",AroonShift,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- Pre-allocate deques
   int dqCap = AroonPeriod + 1;
   if(ArrayResize(g_maxDq, dqCap) == -1 || ArrayResize(g_minDq, dqCap) == -1)
      return INIT_FAILED;
//----
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of minimums of price for the calculation of indicator
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {

  ArraySetAsSeries(high, false);
  ArraySetAsSeries(low, false);

//---- checking the number of bars to be enough for the calculation
   if(rates_total<AroonPeriod-1)
      return(0);

//---- declaration of local variables
   int first,bar;
   double BULLS,BEARS;

//---- calculation of the starting number 'first' for the cycle of recalculation of bars
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
      first=AroonPeriod-1; // starting number for calculation of all bars

   else first=prev_calculated-1; // starting number for calculation of new bars

//--- Monotone deque sliding window: O(1) amortized HH/LL over AroonPeriod
//--- Strict `<` / `>` in eviction preserves original's "oldest wins on tie" semantics,
//--- where front-of-deque holds the EARLIEST index at the current max/min value.
   int dqCap = AroonPeriod + 1;
   int startBar = (int)MathMax(first - AroonPeriod + 1, 0);
   int maxH = 0, maxT = 0, minH = 0, minT = 0;

   for(bar = startBar; bar < rates_total && !IsStopped(); bar++)
     {
      int windowStart = bar - AroonPeriod + 1;
      if(windowStart < 0) windowStart = 0;

      //--- Push high[bar] onto max-deque (strict < keeps earlier ties at front)
      while(maxT > maxH && high[g_maxDq[(maxT - 1) % dqCap]] < high[bar]) maxT--;
      g_maxDq[maxT % dqCap] = bar; maxT++;
      while(maxH < maxT && g_maxDq[maxH % dqCap] < windowStart) maxH++;

      //--- Push low[bar] onto min-deque (strict > keeps earlier ties at front)
      while(minT > minH && low[g_minDq[(minT - 1) % dqCap]] > low[bar]) minT--;
      g_minDq[minT % dqCap] = bar; minT++;
      while(minH < minT && g_minDq[minH % dqCap] < windowStart) minH++;

      if(bar < first) continue; // seeding only

      int hiIdx = g_maxDq[maxH % dqCap];
      int loIdx = g_minDq[minH % dqCap];
      BULLS = 100 - (bar - hiIdx) * 100.0 / AroonPeriod;
      BEARS = 100 - (bar - loIdx) * 100.0 / AroonPeriod;
      BullsAroonBuffer[bar] = BULLS;
      BearsAroonBuffer[bar] = BEARS;
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
