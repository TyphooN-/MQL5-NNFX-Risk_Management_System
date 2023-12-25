/**=        ATR_Projection.mqh   (TyphooN's HTF Levels Indicator)
 *      Copyright 2023, TyphooN (https://www.marketwizardry.org/)
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
#property copyright "Copyright 2023 TyphooN (MarketWizardry.org)"
#property link      "http://www.marketwizardry.info/"
#property version   "1.001"
#property description "TyphooN's HTF High/Low Levels"
#property indicator_chart_window
// Define input parameters
input string objectName = "HL_Lines"; // Object name
input color lineColor = clrWhite;       // Line color
input int Line_Thickness = 2;
double W1_High;
double W1_Low;
double D1_High;
double D1_Low;
double H4_High;
double H4_Low;
double MN1_High;
double MN1_Low;
int lastCheckedCandle = -1;
int OnInit()
{
   return(INIT_SUCCEEDED);
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
   static datetime prevTradeServerTime = 0;  // Initialize with 0 on the first run
   datetime currentTradeServerTime = 0;
   currentTradeServerTime = TimeTradeServer();
   // Check if a new 15-minute interval
   if (IsNewM15Interval(currentTradeServerTime, prevTradeServerTime))
   {
      UpdateCandlestickData();
      prevTradeServerTime = currentTradeServerTime;
      //Print("Updating ATR Data and Candlestick data due to 15 min server time.");
   }
   // Calculate the number of bars to be processed
   int limit = rates_total - prev_calculated;
   // If there are no new bars, return
   if (limit <= 0)
   {
      return 0;
   }
   // Check if a new candlestick has formed
   if (lastCheckedCandle != rates_total - 1)
   {
      //Print("New candle has formed, updating ATR & Candlestick Data");
      // Update the last checked candle index
      lastCheckedCandle = rates_total - 1;
      UpdateCandlestickData();
   }
   DrawHorizontalLine(W1_High, "W1_High", lineColor, iTime(_Symbol, PERIOD_W1, 1), TimeCurrent());
   DrawHorizontalLine(W1_Low, "W1_Low", lineColor, iTime(_Symbol, PERIOD_W1, 1), TimeCurrent());
   DrawHorizontalLine(D1_High, "D1_High", lineColor, iTime(_Symbol, PERIOD_D1, 1), TimeCurrent());
   DrawHorizontalLine(D1_Low, "D1_Low", lineColor, iTime(_Symbol, PERIOD_D1, 1), TimeCurrent());
   DrawHorizontalLine(H4_High, "H4_High", lineColor, iTime(_Symbol, PERIOD_H4, 1), TimeCurrent());
   DrawHorizontalLine(H4_Low, "H4_Low", lineColor, iTime(_Symbol, PERIOD_H4, 1), TimeCurrent());
   DrawHorizontalLine(MN1_High, "MN1_High", lineColor, iTime(_Symbol, PERIOD_MN1, 1), TimeCurrent());
   DrawHorizontalLine(MN1_Low, "MN1_Low", lineColor, iTime(_Symbol, PERIOD_MN1, 1), TimeCurrent());
   return(rates_total);
}
void UpdateCandlestickData()
{
      W1_High = iHigh(_Symbol, PERIOD_W1, 1);
      W1_Low = iLow(_Symbol, PERIOD_W1, 1);
      D1_High = iHigh(_Symbol, PERIOD_D1, 1);
      D1_Low = iLow(_Symbol, PERIOD_D1, 1);
      H4_High = iHigh(_Symbol, PERIOD_H4, 1);
      H4_Low = iLow(_Symbol, PERIOD_H4, 1);
      MN1_High = iHigh(_Symbol, PERIOD_MN1, 1);
      MN1_Low = iLow(_Symbol, PERIOD_MN1, 1);
}
void DrawHorizontalLine(double price, string label, color clr, datetime startTime, datetime endTime)
{
   ObjectCreate(0, label, OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, label, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, label, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, label, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, label, OBJPROP_SELECTED, false);
   ObjectSetDouble(0, label, OBJPROP_PRICE, price);
   ObjectSetInteger(0, label, OBJPROP_WIDTH, Line_Thickness);
}
bool IsNewM15Interval(const datetime& currentTime, const datetime& prevTime)
{
   MqlDateTime currentMqlTime, prevMqlTime;
   TimeToStruct(currentTime, currentMqlTime);
   TimeToStruct(prevTime, prevMqlTime);
   //Print("IsNewM15Interval() has run.");
   // Check if the minutes have changed
   if (currentMqlTime.min != prevMqlTime.min)
   {
   // Check if the current time is at a a 15 minute interval
   if (currentMqlTime.min == 0 || currentMqlTime.min == 15 || currentMqlTime.min == 30 || currentMqlTime.min == 45 )
   {
      return true;
   }
   }
   return false;
}
void OnDeinit(const int reason)
{
   ObjectDelete(0, objectName);
}
