/**=             TyphooN.mq5  (TyphooN's FakeCandle Indicator)
 *               Copyright 2024, TyphooN (https://www.marketwizardry.org/)
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
#property copyright "TyphooN"
#property link      "http://marketwizardry.info/"
#property version   "1.00"
#property indicator_chart_window
input double FakeHigh = 1.0;
input double FakeLow = 0.5;
input double FakeClose = 0.75;
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
   datetime fake_time = time[rates_total - 1] + PeriodSeconds();
   double fake_open = close[rates_total - 1];
   double fake_high = FakeHigh;
   double fake_low = FakeLow;
   double fake_close = FakeClose;
   // Calculate the width of the candlestick body
   double body_width = MathAbs(fake_open - fake_close);
   // Determine the coordinates of the rectangle for the body
   datetime body_left = (datetime)(fake_time - PeriodSeconds()); // Adjusting for candle width
   datetime body_top = (datetime)MathMax(fake_open, fake_close);
   datetime body_right = (datetime)(fake_time + PeriodSeconds()); // Adjusting for candle width
   datetime body_bottom = (datetime)MathMin(fake_open, fake_close);
   // Determine the coordinates of the wicks
   double wick_top = fake_high;
   double wick_bottom = fake_low;
   datetime wick_x = (datetime)fake_time;
   // Draw fake candlestick body
   ObjectCreate(0, "FakeCandleBody", OBJ_RECTANGLE_LABEL, 0, body_left, body_top, body_right, body_bottom);
   ObjectSetInteger(0, "FakeCandleBody", OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, "FakeCandleBody", OBJPROP_STYLE, STYLE_SOLID);
   // Draw fake candlestick wicks
   ObjectCreate(0, "FakeCandleWickTop", OBJ_TREND, 0, wick_x, wick_top, wick_x, body_top);
   ObjectSetInteger(0, "FakeCandleWickTop", OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, "FakeCandleWickTop", OBJPROP_STYLE, STYLE_SOLID);
   ObjectCreate(0, "FakeCandleWickBottom", OBJ_TREND, 0, wick_x, body_bottom, wick_x, wick_bottom);
   ObjectSetInteger(0, "FakeCandleWickBottom", OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, "FakeCandleWickBottom", OBJPROP_STYLE, STYLE_SOLID);
   return(rates_total);
}
