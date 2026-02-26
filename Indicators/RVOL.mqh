//+------------------------------------------------------------------+
//|                                                          RVOL.mqh |
//|                  Darwinex & Trade Like A Machine Ltd / TyphooN    |
//|                                          http://www.darwinex.com |
//+------------------------------------------------------------------+
// Input Parameters
input int InpAveragingDays = 10; // Number of Days for Comparison
input ENUM_APPLIED_VOLUME InpVolumeType = VOLUME_TICK; // Volume Type

// Indicator Buffers
double ExtRelVolumesBuffer[];
double ExtColorsBuffer[];
int AveragingDays;

void OnInit()
{
#ifdef __MQL5__
   // Set Buffers
   SetIndexBuffer(0, ExtRelVolumesBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtColorsBuffer, INDICATOR_COLOR_INDEX);
   // Define how many bars required to begin drawing
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 100);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 100);
   // Set indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
#else
   #ifdef __MQL4__
   SetIndexBuffer(0, ExtRelVolumesBuffer);
   SetIndexBuffer(1, ExtColorsBuffer);
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 3);
   SetIndexDrawBegin(0, 100);
   SetIndexDrawBegin(1, 100);
   SetIndexLabel(0, "RVOL");
   IndicatorDigits(2);
   #endif
#endif

   // Ensure valid InpAveragingDays
   if (InpAveragingDays >= 1)
      AveragingDays = InpAveragingDays;
   else
      AveragingDays = 5;

   // Set name of indicator
   string short_name = StringFormat("RVOL (Relative Volume) (%d)", AveragingDays);
#ifdef __MQL5__
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   // Mean Level
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrWhite);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, clrWhite);
#else
   #ifdef __MQL4__
   IndicatorShortName(short_name);
   SetLevelValue(0, 1.25);
   SetLevelValue(1, 0.8);
   SetLevelStyle(STYLE_SOLID, 1, clrWhite);
   #endif
#endif

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

   // Use sliding window for O(n) mean calculation instead of O(n * AveragingDays)
   double windowSum = 0.0;

   // Initialize window sum for the starting position
   int windowStart = (startBar >= AveragingDays) ? startBar : AveragingDays;
   if (windowStart <= rates_total && windowStart >= AveragingDays)
   {
      for (int j = 1; j <= AveragingDays; j++)
         windowSum += (double)volume[windowStart - j];
   }

   // Fill pre-window bars if needed
   for (int i = startBar; i < windowStart && i < rates_total && !IsStopped(); i++)
   {
      ExtRelVolumesBuffer[i] = 0.0;
      ExtColorsBuffer[i] = 0.0;
   }

   // Main loop with sliding window
   for (int i = windowStart; i < rates_total && !IsStopped(); i++)
   {
      // Slide the window: add new element, remove oldest
      if (i > windowStart)
      {
         windowSum += (double)volume[i - 1];
         windowSum -= (double)volume[i - AveragingDays - 1];
      }

      double curr_volume = (double)volume[i];
      double mean_volume = windowSum / AveragingDays;
      ExtRelVolumesBuffer[i] = curr_volume / mean_volume;

      if (ExtRelVolumesBuffer[i] > 1.25) // Above Average Volume
         ExtColorsBuffer[i] = 0.0;
      else if (ExtRelVolumesBuffer[i] > 0.8) // Average Volume
         ExtColorsBuffer[i] = 1.0;
      else // Below Average Volume
         ExtColorsBuffer[i] = 2.0;
   }
}
