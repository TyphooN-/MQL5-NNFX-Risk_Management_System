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

// Input Parameters
input int InpAveragingDays = 10; // Number of Days for Comparison 
input ENUM_APPLIED_VOLUME InpVolumeType = VOLUME_TICK; // Volume Type

// Indicator Buffers
double ExtRelVolumesBuffer[];
double ExtColorsBuffer[];
int AveragingDays;
int OrderDigits;

void OnInit()
{
   // Set Buffers
   SetIndexBuffer(0, ExtRelVolumesBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtColorsBuffer, INDICATOR_COLOR_INDEX);
   
   // Define how many bars required to begin drawing 
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 100);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 100);

   // Set indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   
   // Ensure valid InpAveragingDays
   if (InpAveragingDays >= 1)
      AveragingDays = InpAveragingDays;
   else 
      AveragingDays = 5;
      
   // Set name of indicator
   string short_name = StringFormat("RVOL (Relative Volume) (%d)", AveragingDays);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   
   // Mean Level
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrWhite);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, clrWhite);

   // Determine OrderDigits
   OrderDigits = VolumeStepDigits();
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
   // Ensure enough bars are available
   if (rates_total < 1)
      return(0);

   // Set starting point for the processing
   int startBar = prev_calculated - 1;

   // Adjust Start position
   if (startBar < 1)
   {
      ExtRelVolumesBuffer[0] = 0;
      startBar = 1;
   }
     
   // Main cycle
   if (InpVolumeType == VOLUME_TICK)
      CalculateRelVolume(startBar, rates_total, tick_volume);
   else
      CalculateRelVolume(startBar, rates_total, volume);

   // OnCalculate done. Return new prev_calculated.
   return(rates_total);
}

void CalculateRelVolume(const int startBar, const int rates_total, const long& volume[])
{
   ExtRelVolumesBuffer[0] = (double)volume[0];
   ExtColorsBuffer[0] = 0.0;
   
   for (int i = startBar; i < rates_total && !IsStopped(); i++)
   {
      if (i >= AveragingDays)
      {
         double curr_volume = (double)volume[i];
         
         double mean_volume = 0.0;
         
         for (int j = 1; j <= AveragingDays; j++)
            mean_volume += (double)volume[i - j];  
            
         mean_volume /= (double)AveragingDays;
         
         ExtRelVolumesBuffer[i] = curr_volume / mean_volume; // Value of 1.0 represents current vol is equal to average volume, 0.0-1.0 is below average, >1.0 is above average
         
         if (ExtRelVolumesBuffer[i] > 1.25) // Above Average Volume
            ExtColorsBuffer[i] = 0.0;
         else if (ExtRelVolumesBuffer[i] > 0.8) // Average Volume
            ExtColorsBuffer[i] = 1.0;
         else // Below Average Volume
            ExtColorsBuffer[i] = 2.0;
      }
      else
      {
         ExtRelVolumesBuffer[i] = 0.0;
         ExtColorsBuffer[i] = 0.0;
      }
   }
}

int VolumeStepDigits()
{
   double step;
   SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP, step);
   int digits = 0;
   
   while (step < 1)
   {
      step *= 10;
      digits++;
   }
   
   return digits;
}
