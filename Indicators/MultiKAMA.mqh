/**=             TyphooN.mq5  (TyphooN's MultiKAMA)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.org/)
 *
 * Disclaimer and Licence
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/
input int InpPeriodAMA = 10;      // AMA period
input int InpFastPeriodEMA = 2;  // Fast EMA period
input int InpSlowPeriodEMA = 30; // Slow EMA period
double ExtAMABuffer_H1[];
double ExtAMABuffer_H4[];
double ExtAMABuffer_D1[];
double ExtAMABuffer_W1[];
double ExtAMABuffer_MN1[];
#ifdef __MQL5__
int handle_KAMA_H1, handle_KAMA_H4, handle_KAMA_D1, handle_KAMA_W1, handle_KAMA_MN1;
#endif
int OnInit()
{
   //--- indicator buffers mapping
#ifdef __MQL5__
   SetIndexBuffer(0, ExtAMABuffer_H1);
   SetIndexBuffer(1, ExtAMABuffer_H4);
   SetIndexBuffer(2, ExtAMABuffer_D1);
   SetIndexBuffer(3, ExtAMABuffer_W1);
   SetIndexBuffer(4, ExtAMABuffer_MN1);
#else
   #ifdef __MQL4__
   SetIndexBuffer(0, ExtAMABuffer_H1);
   SetIndexBuffer(1, ExtAMABuffer_H4);
   SetIndexBuffer(2, ExtAMABuffer_D1);
   SetIndexBuffer(3, ExtAMABuffer_W1);
   SetIndexBuffer(4, ExtAMABuffer_MN1);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrWhite);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrWhite);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, clrWhite);
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 2, clrWhite);
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 2, clrWhite);
   SetIndexLabel(0, "KAMA_H1");
   SetIndexLabel(1, "KAMA_H4");
   SetIndexLabel(2, "KAMA_D1");
   SetIndexLabel(3, "KAMA_W1");
   SetIndexLabel(4, "KAMA_MN1");
   #endif
#endif
   //--- set accuracy
#ifdef __MQL5__
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
#else
   #ifdef __MQL4__
   IndicatorDigits(Digits + 1);
   #endif
#endif
#ifdef __MQL5__
   //--- create handles for the original KAMA indicator
   handle_KAMA_H1 = iCustom(NULL, PERIOD_H1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA);
   handle_KAMA_H4 = iCustom(NULL, PERIOD_H4, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA);
   handle_KAMA_D1 = iCustom(NULL, PERIOD_D1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA);
   handle_KAMA_W1 = iCustom(NULL, PERIOD_W1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA);
   handle_KAMA_MN1 = iCustom(NULL, PERIOD_MN1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA);
   if(handle_KAMA_H1 == INVALID_HANDLE ||
      handle_KAMA_H4 == INVALID_HANDLE ||
      handle_KAMA_D1 == INVALID_HANDLE ||
      handle_KAMA_W1 == INVALID_HANDLE ||
      handle_KAMA_MN1 == INVALID_HANDLE)
   {
      Print("Failed to create handle for KAMA indicator");
      return(INIT_FAILED);
   }
#endif
   //--- OnInit done
   return (INIT_SUCCEEDED);
}
#ifdef __MQL5__
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   int calculated = prev_calculated - 1;
   if (calculated < 0)
   {
      calculated = 0;
   }
   //--- calculate KAMA for each timeframe
   WaitForIndicatorData(handle_KAMA_H1, ExtAMABuffer_H1, rates_total, "KAMA_H1");
   WaitForIndicatorData(handle_KAMA_H4, ExtAMABuffer_H4, rates_total, "KAMA_H4");
   WaitForIndicatorData(handle_KAMA_D1, ExtAMABuffer_D1, rates_total, "KAMA_D1");
   WaitForIndicatorData(handle_KAMA_W1, ExtAMABuffer_W1, rates_total, "KAMA_W1");
   WaitForIndicatorData(handle_KAMA_MN1, ExtAMABuffer_MN1, rates_total, "KAMA_MN1");
    // Check if the buffers are correctly filled
    if (rates_total > 0)
    {
        int latestIndex = rates_total - 1; // Index of the latest bar
        GlobalVariableSet("recent_KAMA_H1", ExtAMABuffer_H1[latestIndex]);
        GlobalVariableSet("recent_KAMA_H4", ExtAMABuffer_H4[latestIndex]);
        GlobalVariableSet("recent_KAMA_D1", ExtAMABuffer_D1[latestIndex]);
        GlobalVariableSet("recent_KAMA_W1", ExtAMABuffer_W1[latestIndex]);
        GlobalVariableSet("recent_KAMA_MN1", ExtAMABuffer_MN1[latestIndex]);
    }
   // Get the current price
   double currentPrice = price[rates_total - 1];
   // Check if the current price is above or below each KAMA
   bool isAbove_KAMA_H1 = currentPrice > ExtAMABuffer_H1[rates_total - 1];
   bool isAbove_KAMA_H4 = currentPrice > ExtAMABuffer_H4[rates_total - 1];
   bool isAbove_KAMA_D1 = currentPrice > ExtAMABuffer_D1[rates_total - 1];
   bool isAbove_KAMA_W1 = currentPrice > ExtAMABuffer_W1[rates_total - 1];
   bool isAbove_KAMA_MN1 = currentPrice > ExtAMABuffer_MN1[rates_total - 1];
   // Set global variables for each timeframe's KAMA comparison
   GlobalVariableSet("IsAbove_KAMA_H1", isAbove_KAMA_H1);
   GlobalVariableSet("IsAbove_KAMA_H4", isAbove_KAMA_H4);
   GlobalVariableSet("IsAbove_KAMA_D1", isAbove_KAMA_D1);
   GlobalVariableSet("IsAbove_KAMA_W1", isAbove_KAMA_W1);
   GlobalVariableSet("IsAbove_KAMA_MN1", isAbove_KAMA_MN1);
   //--- return value of prev_calculated for next call
   return (rates_total);
}
void WaitForIndicatorData(int handle, double &buffer[], int rates_total, string name)
{
   if (CopyBuffer(handle, 0, 0, rates_total, buffer) > 0)
   {
      return;
   }
   else
   {
      //Print("Error in CopyBuffer for ", name, ": ", GetLastError(), ", retrying...");
      // If the copy buffer fails, wait for a short period before retrying
      Sleep(1000); // Wait for 1000 milliseconds before retrying
   }
}
#else
#ifdef __MQL4__
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
   int calculated = prev_calculated - 1;
   if (calculated < 0)
      calculated = 0;
   // In MQL4, iCustom returns values directly per bar
   for (int i = calculated; i < rates_total && !IsStopped(); i++)
   {
      int shift = rates_total - 1 - i;
      ExtAMABuffer_H1[i] = iCustom(NULL, PERIOD_H1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA, 0, shift);
      ExtAMABuffer_H4[i] = iCustom(NULL, PERIOD_H4, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA, 0, shift);
      ExtAMABuffer_D1[i] = iCustom(NULL, PERIOD_D1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA, 0, shift);
      ExtAMABuffer_W1[i] = iCustom(NULL, PERIOD_W1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA, 0, shift);
      ExtAMABuffer_MN1[i] = iCustom(NULL, PERIOD_MN1, "KAMA", InpPeriodAMA, InpFastPeriodEMA, InpSlowPeriodEMA, 0, shift);
   }
   // Set global variables
   if (rates_total > 0)
   {
      int latestIndex = rates_total - 1;
      GlobalVariableSet("recent_KAMA_H1", ExtAMABuffer_H1[latestIndex]);
      GlobalVariableSet("recent_KAMA_H4", ExtAMABuffer_H4[latestIndex]);
      GlobalVariableSet("recent_KAMA_D1", ExtAMABuffer_D1[latestIndex]);
      GlobalVariableSet("recent_KAMA_W1", ExtAMABuffer_W1[latestIndex]);
      GlobalVariableSet("recent_KAMA_MN1", ExtAMABuffer_MN1[latestIndex]);
      double currentPrice = close[latestIndex];
      GlobalVariableSet("IsAbove_KAMA_H1", currentPrice > ExtAMABuffer_H1[latestIndex]);
      GlobalVariableSet("IsAbove_KAMA_H4", currentPrice > ExtAMABuffer_H4[latestIndex]);
      GlobalVariableSet("IsAbove_KAMA_D1", currentPrice > ExtAMABuffer_D1[latestIndex]);
      GlobalVariableSet("IsAbove_KAMA_W1", currentPrice > ExtAMABuffer_W1[latestIndex]);
      GlobalVariableSet("IsAbove_KAMA_MN1", currentPrice > ExtAMABuffer_MN1[latestIndex]);
   }
   return (rates_total);
}
#endif
#endif
