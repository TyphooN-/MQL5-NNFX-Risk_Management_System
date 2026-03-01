/**=   PreviousCandleLevels.mqh   (TyphooN's Previous Candlestick Level Indicator)
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
// Define input parameters
input color PreviousCandleColour = clrWhite;
input color JudasLevelColour = clrMagenta;
input int Line_Thickness = 2;
// Global vars
string objname1 = "Previous_";
string objname2 = "Current_";
double Previous_H1_High, Previous_H1_Low, Previous_H4_High, Previous_H4_Low, Previous_D1_High, Previous_D1_Low, Previous_W1_High, Previous_W1_Low,
   Previous_MN1_High, Previous_MN1_Low, Current_D1_Low, Current_D1_High, Current_W1_Low, Current_W1_High, Current_MN1_Low, Current_MN1_High, Ask, Bid;
int lastCheckedCandle = -1;
double prevBidPrice = 0.0;
double prevAskPrice = 0.0;
datetime g_PrevTradeServerTime = 0;
// Cached object name strings (avoid per-call string concatenation in DrawLines)
string g_prev_H1_High, g_prev_H1_Low, g_prev_H4_High, g_prev_H4_Low;
string g_prev_D1_High, g_prev_D1_Low, g_prev_W1_High, g_prev_W1_Low;
string g_prev_MN1_High, g_prev_MN1_Low;
string g_cur_D1_High, g_cur_D1_Low, g_cur_W1_High, g_cur_W1_Low;
string g_cur_MN1_High, g_cur_MN1_Low;
int OnInit()
{
    lastCheckedCandle = -1;
    prevBidPrice = 0.0;
    prevAskPrice = 0.0;
    g_PrevTradeServerTime = 0;
    // Cache object name strings once
    g_prev_H1_High = objname1 + "H1_High";   g_prev_H1_Low = objname1 + "H1_Low";
    g_prev_H4_High = objname1 + "H4_High";   g_prev_H4_Low = objname1 + "H4_Low";
    g_prev_D1_High = objname1 + "D1_High";   g_prev_D1_Low = objname1 + "D1_Low";
    g_prev_W1_High = objname1 + "W1_High";   g_prev_W1_Low = objname1 + "W1_Low";
    g_prev_MN1_High = objname1 + "MN1_High"; g_prev_MN1_Low = objname1 + "MN1_Low";
    g_cur_D1_High = objname2 + "D1_High";    g_cur_D1_Low = objname2 + "D1_Low";
    g_cur_W1_High = objname2 + "W1_High";    g_cur_W1_Low = objname2 + "W1_Low";
    g_cur_MN1_High = objname2 + "MN1_High";  g_cur_MN1_Low = objname2 + "MN1_Low";
    return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, objname1);
   ObjectsDeleteAll(0, objname2);
}
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &High[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if (rates_total <= 0) return 0;
   // Get the current bid and ask prices
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // Check if both bid and ask prices have changed from the previous tick
   if (Bid == prevBidPrice && Ask == prevAskPrice)
   {
      // If both bid and ask prices are the same as the previous tick, return prev_calculated
      return prev_calculated;
   }
   // Update the previous bid and ask prices with the current prices
   prevBidPrice = Bid;
   prevAskPrice = Ask;
   datetime CurrentTradeServerTime = TimeCurrent();
   bool drewThisTick = false;
   // Check if it is a new H1 interval
   if (IsNewH1Interval(CurrentTradeServerTime, g_PrevTradeServerTime))
   {
      UpdatePreviousData();
      UpdateJudasData();
      DrawLines();
      drewThisTick = true;
      g_PrevTradeServerTime = CurrentTradeServerTime;
   }
   // Judas check runs intrabar (when price breaks D1 high/low) -- skip on W1/MN1 where D1 objects are deleted
   if (_Period < PERIOD_W1 && ((Ask > Current_D1_High) || (Bid < Current_D1_Low)))
   {
      double prevD1H = Current_D1_High, prevD1L = Current_D1_Low;
      double prevW1H = Current_W1_High, prevW1L = Current_W1_Low;
      double prevMN1H = Current_MN1_High, prevMN1L = Current_MN1_Low;
      UpdateJudasData();
      if (Current_D1_High != prevD1H || Current_D1_Low != prevD1L ||
          Current_W1_High != prevW1H || Current_W1_Low != prevW1L ||
          Current_MN1_High != prevMN1H || Current_MN1_Low != prevMN1L)
      {
         DrawLines();
      }
   }
   // Calculate the number of bars to be processed
   int limit = rates_total - prev_calculated;
   // If there are no new bars, return (must return prev_calculated, not 0, to avoid forced full recalc)
   if (limit <= 0)
      return prev_calculated;
   // Check if a new candlestick has formed
   if (lastCheckedCandle != rates_total - 1)
   {
      lastCheckedCandle = rates_total - 1;
      if (!drewThisTick)
      {
         UpdatePreviousData();
         UpdateJudasData();
         DrawLines();
      }
   }
   return(rates_total);
}
void UpdatePreviousData()
{
   // Guard against 0 returns (history not yet loaded) to prevent lines at price 0
   double val;
   val = iHigh(_Symbol, PERIOD_H1, 1);   if (val > 0) Previous_H1_High = val;
   val = iLow(_Symbol, PERIOD_H1, 1);    if (val > 0) Previous_H1_Low = val;
   val = iHigh(_Symbol, PERIOD_H4, 1);   if (val > 0) Previous_H4_High = val;
   val = iLow(_Symbol, PERIOD_H4, 1);    if (val > 0) Previous_H4_Low = val;
   val = iHigh(_Symbol, PERIOD_D1, 1);   if (val > 0) Previous_D1_High = val;
   val = iLow(_Symbol, PERIOD_D1, 1);    if (val > 0) Previous_D1_Low = val;
   val = iHigh(_Symbol, PERIOD_W1, 1);   if (val > 0) Previous_W1_High = val;
   val = iLow(_Symbol, PERIOD_W1, 1);    if (val > 0) Previous_W1_Low = val;
   val = iHigh(_Symbol, PERIOD_MN1, 1);  if (val > 0) Previous_MN1_High = val;
   val = iLow(_Symbol, PERIOD_MN1, 1);   if (val > 0) Previous_MN1_Low = val;
}
void UpdateJudasData()
{
   // Current bar (0) high/low for each timeframe -- replaces 6 iBarShift + 6 iTime calls
   // Guard against 0 returns (history not yet loaded) to prevent false Judas triggers
   double val;
   val = iHigh(_Symbol, PERIOD_D1, 0);   if (val > 0) Current_D1_High = val;
   val = iLow(_Symbol, PERIOD_D1, 0);    if (val > 0) Current_D1_Low = val;
   val = iHigh(_Symbol, PERIOD_W1, 0);   if (val > 0) Current_W1_High = val;
   val = iLow(_Symbol, PERIOD_W1, 0);    if (val > 0) Current_W1_Low = val;
   val = iHigh(_Symbol, PERIOD_MN1, 0);  if (val > 0) Current_MN1_High = val;
   val = iLow(_Symbol, PERIOD_MN1, 0);   if (val > 0) Current_MN1_Low = val;
}
void DeleteHorizontalLine(string label)
{
    ObjectDelete(0, label);
}
void DrawLines()
{
   // Cache iTime values to avoid redundant calls
   datetime currentBarTime = iTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 0);
   if (currentBarTime == 0) return;
   datetime prevH1Time = iTime(_Symbol, PERIOD_H1, 1);
   datetime prevH4Time = iTime(_Symbol, PERIOD_H4, 1);
   datetime prevD1Time = iTime(_Symbol, PERIOD_D1, 1);
   datetime prevW1Time = iTime(_Symbol, PERIOD_W1, 1);
   datetime prevMN1Time = iTime(_Symbol, PERIOD_MN1, 1);
   if (prevH1Time == 0 || prevH4Time == 0 || prevD1Time == 0 ||
       prevW1Time == 0 || prevMN1Time == 0)
      return;
   if (_Period < PERIOD_H1)
   {
      DrawHorizontalLine(Previous_H1_High, g_prev_H1_High, PreviousCandleColour, prevH1Time, currentBarTime);
      DrawHorizontalLine(Previous_H1_Low, g_prev_H1_Low, PreviousCandleColour, prevH1Time, currentBarTime);
      DrawHorizontalLine(Previous_H4_High, g_prev_H4_High, PreviousCandleColour, prevH4Time, currentBarTime);
      DrawHorizontalLine(Previous_H4_Low, g_prev_H4_Low, PreviousCandleColour, prevH4Time, currentBarTime);
      DrawHorizontalLine(Previous_D1_High, g_prev_D1_High, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Previous_D1_Low, g_prev_D1_Low, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Previous_W1_High, g_prev_W1_High, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Previous_W1_Low, g_prev_W1_Low, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_High, g_prev_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_Low, g_prev_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_D1_High, g_cur_D1_High, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Current_D1_Low, g_cur_D1_Low, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Current_W1_High, g_cur_W1_High, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Current_W1_Low, g_cur_W1_Low, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_High, g_cur_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_Low, g_cur_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
   }
#ifdef __MQL5__
   if(_Period >= PERIOD_H1 && _Period <= PERIOD_H8)
#else
   if(_Period >= PERIOD_H1 && _Period <= PERIOD_H4)
#endif
   {
      DeleteHorizontalLine(g_prev_H1_High);
      DeleteHorizontalLine(g_prev_H1_Low);
      DeleteHorizontalLine(g_prev_H4_High);
      DeleteHorizontalLine(g_prev_H4_Low);
      DrawHorizontalLine(Previous_D1_High, g_prev_D1_High, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Previous_D1_Low, g_prev_D1_Low, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Previous_W1_High, g_prev_W1_High, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Previous_W1_Low, g_prev_W1_Low, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_High, g_prev_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_Low, g_prev_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_D1_High, g_cur_D1_High, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Current_D1_Low, g_cur_D1_Low, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Current_W1_High, g_cur_W1_High, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Current_W1_Low, g_cur_W1_Low, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_High, g_cur_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_Low, g_cur_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
   }
#ifdef __MQL5__
   if(_Period == PERIOD_D1 || _Period == PERIOD_H12)
#else
   if(_Period == PERIOD_D1)
#endif
   {
      DeleteHorizontalLine(g_prev_H1_High);
      DeleteHorizontalLine(g_prev_H1_Low);
      DeleteHorizontalLine(g_prev_H4_High);
      DeleteHorizontalLine(g_prev_H4_Low);
      DeleteHorizontalLine(g_prev_D1_High);
      DeleteHorizontalLine(g_prev_D1_Low);
      DrawHorizontalLine(Previous_W1_High, g_prev_W1_High, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Previous_W1_Low, g_prev_W1_Low, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_High, g_prev_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_Low, g_prev_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_D1_High, g_cur_D1_High, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Current_D1_Low, g_cur_D1_Low, JudasLevelColour, prevD1Time, currentBarTime);
      DrawHorizontalLine(Current_W1_High, g_cur_W1_High, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Current_W1_Low, g_cur_W1_Low, JudasLevelColour, prevW1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_High, g_cur_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_Low, g_cur_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
   }
   if(_Period == PERIOD_W1)
   {
      DeleteHorizontalLine(g_prev_H1_High);
      DeleteHorizontalLine(g_prev_H1_Low);
      DeleteHorizontalLine(g_prev_H4_High);
      DeleteHorizontalLine(g_prev_H4_Low);
      DeleteHorizontalLine(g_prev_D1_High);
      DeleteHorizontalLine(g_prev_D1_Low);
      DeleteHorizontalLine(g_cur_D1_High);
      DeleteHorizontalLine(g_cur_D1_Low);
      DeleteHorizontalLine(g_prev_W1_High);
      DeleteHorizontalLine(g_prev_W1_Low);
      DeleteHorizontalLine(g_cur_W1_High);
      DeleteHorizontalLine(g_cur_W1_Low);
      DrawHorizontalLine(Previous_MN1_High, g_prev_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Previous_MN1_Low, g_prev_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_High, g_cur_MN1_High, JudasLevelColour, prevMN1Time, currentBarTime);
      DrawHorizontalLine(Current_MN1_Low, g_cur_MN1_Low, JudasLevelColour, prevMN1Time, currentBarTime);
   }
   if(_Period == PERIOD_MN1)
   {
      DeleteHorizontalLine(g_prev_H1_High);
      DeleteHorizontalLine(g_prev_H1_Low);
      DeleteHorizontalLine(g_prev_H4_High);
      DeleteHorizontalLine(g_prev_H4_Low);
      DeleteHorizontalLine(g_prev_D1_High);
      DeleteHorizontalLine(g_prev_D1_Low);
      DeleteHorizontalLine(g_prev_W1_High);
      DeleteHorizontalLine(g_prev_W1_Low);
      DeleteHorizontalLine(g_cur_W1_High);
      DeleteHorizontalLine(g_cur_W1_Low);
      DeleteHorizontalLine(g_cur_D1_High);
      DeleteHorizontalLine(g_cur_D1_Low);
      DeleteHorizontalLine(g_prev_MN1_High);
      DeleteHorizontalLine(g_prev_MN1_Low);
      DeleteHorizontalLine(g_cur_MN1_High);
      DeleteHorizontalLine(g_cur_MN1_Low);
   }
}
void DrawHorizontalLine(double price, string label, color clr, datetime startTime, datetime endTime)
{
   if(ObjectFind(0, label) != -1)
   {
      ObjectMove(0, label, 0, startTime, price);
      ObjectMove(0, label, 1, endTime, price);
      return;
   }
   ObjectCreate(0, label, OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, label, OBJPROP_STYLE, STYLE_SOLID);
   #ifdef __MQL5__ // In MT4 this will return error 4201
   ObjectSetInteger(0, label, OBJPROP_RAY_LEFT, false);
   #endif
   ObjectSetInteger(0, label, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, label, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, label, OBJPROP_WIDTH, Line_Thickness);
}
bool IsNewH1Interval(const datetime& currentTime, const datetime& prevTime)
{
   return (currentTime / 3600) != (prevTime / 3600);
}
