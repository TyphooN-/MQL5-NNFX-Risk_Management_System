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
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
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
//----
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

//---- main cycle of calculation of the indicator
   for(bar=first; bar<rates_total; bar++)
     {
      //---- calculation of the indicator values
      BULLS = 100 - getHighestIndex(high, bar) * 100.0 / AroonPeriod;
      BEARS = 100 - getLowestIndex(low, bar) * 100.0 / AroonPeriod;

      //---- initialization of cells of the indicator buffers with obtained values
      BullsAroonBuffer[bar] = BULLS;
      BearsAroonBuffer[bar] = BEARS;
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+

int getHighestIndex(const double &high[], int startIndex){
   double highestValue = -1;
   int highestIndex = 0;

   for(int a=startIndex-AroonPeriod+1; a<=startIndex; a++){
      double value = high[a];

      if(value > highestValue){
         highestIndex = startIndex - a;
         highestValue = value;
      }
   }

   return highestIndex;
}

int getLowestIndex(const double &low[], int startIndex){
   double lowestValue = DBL_MAX;
   int lowestIndex = 0;

   for(int a=startIndex-AroonPeriod+1; a<=startIndex; a++){
      double value = low[a];

      if(value < lowestValue){
         lowestIndex = startIndex - a;
         lowestValue = value;
      }
   }

   return lowestIndex;
}
