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
#property link      "http://www.mql5.com"
#property version   "1.000"
#property description "TyphooN's MQL5 Risk Management System"
#property indicator_chart_window
// Define input parameters
input string objectName = "HL_Lines"; // Object name
input color lineColor = clrWhite;       // Line color
input int Line_Thickness = 2;
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
   static datetime LastCandlestick = 0;
   // Check if a new candlestick has formed
   if (time[0] != LastCandlestick)
   {
      // Update the last candle time
      LastCandlestick = time[0];
      // Calculate the highest and lowest prices for the specified timeframes
      double w1High = iHigh(_Symbol, PERIOD_W1, 1);
      double w1Low = iLow(_Symbol, PERIOD_W1, 1);
      double d1High = iHigh(_Symbol, PERIOD_D1, 1);
      double d1Low = iLow(_Symbol, PERIOD_D1, 1);
      double h4High = iHigh(_Symbol, PERIOD_H4, 1);
      double h4Low = iLow(_Symbol, PERIOD_H4, 1);
      double mn1High = iHigh(_Symbol, PERIOD_MN1, 1);
      double mn1Low = iLow(_Symbol, PERIOD_MN1, 1);
      // Draw horizontal lines for each timeframe with the start time as the beginning of the previous D1 candle
      DrawHorizontalLine(w1High, "W1_High", lineColor, iTime(_Symbol, PERIOD_W1, 1), TimeCurrent());
      DrawHorizontalLine(w1Low, "W1_Low", lineColor, iTime(_Symbol, PERIOD_W1, 1), TimeCurrent());
      DrawHorizontalLine(d1High, "D1_High", lineColor, iTime(_Symbol, PERIOD_D1, 1), TimeCurrent());
      DrawHorizontalLine(d1Low, "D1_Low", lineColor, iTime(_Symbol, PERIOD_D1, 1), TimeCurrent());
      DrawHorizontalLine(h4High, "H4_High", lineColor, iTime(_Symbol, PERIOD_H4, 1), TimeCurrent());
      DrawHorizontalLine(h4Low, "H4_Low", lineColor, iTime(_Symbol, PERIOD_H4, 1), TimeCurrent());
      DrawHorizontalLine(mn1High, "MN1_High", lineColor, iTime(_Symbol, PERIOD_MN1, 1), TimeCurrent());
      DrawHorizontalLine(mn1Low, "MN1_Low", lineColor, iTime(_Symbol, PERIOD_MN1, 1), TimeCurrent());
   }
   return(rates_total);
}
void DrawHorizontalLine(double price, string label, color clr, datetime startTime, datetime endTime)
{
   // Delete the previous object with the same name
   ObjectDelete(0, label);
   // Draw a horizontal line at the specified price
   ObjectCreate(0, label, OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, label, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, label, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, label, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, label, OBJPROP_SELECTED, false);
   ObjectSetDouble(0, label, OBJPROP_PRICE, price);
   ObjectSetInteger(0, label, OBJPROP_WIDTH, Line_Thickness);
}
void OnDeinit(const int reason)
{
   ObjectDelete(0, objectName);
}
