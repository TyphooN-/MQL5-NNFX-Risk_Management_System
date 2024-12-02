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
int OnInit()
{
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
   static datetime PrevTradeServerTime = 0;  // Initialize with 0 on the first run
   datetime CurrentTradeServerTime = 0;
   CurrentTradeServerTime = TimeCurrent();
   // Check if it is a new H1 interval
   if (IsNewH1Interval(CurrentTradeServerTime, PrevTradeServerTime))
   {
      UpdatePreviousData();
      UpdateJudasData();
      DrawLines();
      PrevTradeServerTime = CurrentTradeServerTime;
      //Print("Updating ATR Data and Candlestick data due to 1 hour server time change.");
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
      UpdatePreviousData();
      UpdateJudasData();
      DrawLines();
   }
   if ((Ask > Current_D1_High) || (Bid < Current_D1_Low))
   {
      UpdateJudasData();
      DrawLines();
      //Print("Called Judas Data update.");
   }
   return(rates_total);
}
void UpdatePreviousData()
{
   Previous_H1_High = iHigh(_Symbol, PERIOD_H1, 1);
   Previous_H1_Low = iLow(_Symbol, PERIOD_H1, 1);
   Previous_H4_High = iHigh(_Symbol, PERIOD_H4, 1);
   Previous_H4_Low = iLow(_Symbol, PERIOD_H4, 1);
   Previous_D1_High = iHigh(_Symbol, PERIOD_D1, 1);
   Previous_D1_Low = iLow(_Symbol, PERIOD_D1, 1);
   Previous_W1_High = iHigh(_Symbol, PERIOD_W1, 1);
   Previous_W1_Low = iLow(_Symbol, PERIOD_W1, 1);
   Previous_MN1_High = iHigh(_Symbol, PERIOD_MN1, 1);
   Previous_MN1_Low = iLow(_Symbol, PERIOD_MN1, 1);
}
void UpdateJudasData()
{
   // Calculate current day's High and Low
   int currentDayStartShift = iBarShift(_Symbol, PERIOD_D1, iTime(_Symbol, PERIOD_D1, 0));
   int currentDayEndShift = iBarShift(_Symbol, PERIOD_CURRENT, iTime(_Symbol, PERIOD_M1, 0));
   Current_D1_High = iHigh(_Symbol, PERIOD_D1, currentDayEndShift);
   Current_D1_Low = iLow(_Symbol, PERIOD_D1, currentDayStartShift);
   // Calculate current week's High and Low
   int currentWeekStartShift = iBarShift(_Symbol, PERIOD_W1, iTime(_Symbol, PERIOD_W1, 0));
   int currentWeekEndShift = iBarShift(_Symbol, PERIOD_CURRENT, iTime(_Symbol, PERIOD_M1, 0));
   Current_W1_High = iHigh(_Symbol, PERIOD_W1, currentWeekEndShift);
   Current_W1_Low = iLow(_Symbol, PERIOD_W1, currentWeekStartShift);
   // Calculate current month's High and Low
   int currentMonthStartShift = iBarShift(_Symbol, PERIOD_MN1, iTime(_Symbol, PERIOD_MN1, 0));
   int currentMonthEndShift = iBarShift(_Symbol, PERIOD_CURRENT, iTime(_Symbol, PERIOD_M1, 0));
   Current_MN1_High = iHigh(_Symbol, PERIOD_MN1, currentMonthEndShift);
   Current_MN1_Low = iLow(_Symbol, PERIOD_MN1, currentMonthStartShift);
}
void DeleteHorizontalLine(string label)
{
    if(ObjectFind(0, label) != -1)
    {
        ObjectDelete(0, label);
    }
}
void DrawLines()
{
   if (_Period < PERIOD_H1)
   {      
      DrawHorizontalLine(Previous_H1_High, objname1 + "H1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_H1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H1_Low, objname1 + "H1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_H1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H4_High, objname1 + "H4_High", PreviousCandleColour, iTime(_Symbol, PERIOD_H4, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H4_Low, objname1 + "H4_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_H4, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_High, objname1 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_Low, objname1 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_High, objname1 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname1 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_High, objname2 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_Low, objname2 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_W1_High, objname2 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_W1_Low, objname2 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_High, objname2 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_Low, objname2 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
   }
   if(_Period >= PERIOD_H1 && _Period <= PERIOD_H8)
   {
      DeleteHorizontalLine(objname1 + "H1_High");
      DeleteHorizontalLine(objname1 + "H1_Low");
      DeleteHorizontalLine(objname1 + "H4_High");
      DeleteHorizontalLine(objname1 + "H4_Low");
      DrawHorizontalLine(Previous_D1_High, objname1 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_Low, objname1 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_High, objname1 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname1 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_High, objname2 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_Low, objname2 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_W1_High, objname2 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_W1_Low, objname2 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_High, objname2 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_Low, objname2 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
   }
   if(_Period == PERIOD_D1 || _Period == PERIOD_H12)
   {
      DeleteHorizontalLine(objname1 + "H1_High");
      DeleteHorizontalLine(objname1 + "H1_Low");
      DeleteHorizontalLine(objname1 + "H4_High");
      DeleteHorizontalLine(objname1 + "H4_Low");
      DeleteHorizontalLine(objname1 + "D1_High");
      DeleteHorizontalLine(objname1 + "D1_Low");
      DrawHorizontalLine(Previous_W1_High, objname1 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname1 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_High, objname2 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_Low, objname2 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_W1_High, objname2 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_W1_Low, objname2 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_High, objname2 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_Low, objname2 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
   }
   if(_Period == PERIOD_W1)
   {
      DeleteHorizontalLine(objname1 + "H1_High");
      DeleteHorizontalLine(objname1 + "H1_Low");
      DeleteHorizontalLine(objname1 + "H4_High");
      DeleteHorizontalLine(objname1 + "H4_Low");
      DeleteHorizontalLine(objname1 + "D1_High");
      DeleteHorizontalLine(objname1 + "D1_Low");
      DeleteHorizontalLine(objname2 + "D1_High");
      DeleteHorizontalLine(objname2 + "D1_Low");
      DeleteHorizontalLine(objname1 + "W1_High");
      DeleteHorizontalLine(objname1 + "W1_Low");
      DeleteHorizontalLine(objname1 + "W1_High");
      DeleteHorizontalLine(objname1 + "W1_Low");
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_High, objname2 + "MN1_High", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_MN1_Low, objname2 + "MN1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
   }
   if(_Period == PERIOD_MN1)
   {
      DeleteHorizontalLine(objname1 + "H1_High");
      DeleteHorizontalLine(objname1 + "H1_Low");
      DeleteHorizontalLine(objname1 + "H4_High");
      DeleteHorizontalLine(objname1 + "H4_Low");
      DeleteHorizontalLine(objname1 + "D1_High");
      DeleteHorizontalLine(objname1 + "D1_Low");
      DeleteHorizontalLine(objname1 + "W1_High");
      DeleteHorizontalLine(objname1 + "W1_Low");
      DeleteHorizontalLine(objname2 + "W1_High");
      DeleteHorizontalLine(objname2 + "W1_Low");
      DeleteHorizontalLine(objname2 + "D1_High");
      DeleteHorizontalLine(objname2 + "D1_Low");
      DeleteHorizontalLine(objname1 + "MN1_High");
      DeleteHorizontalLine(objname1 + "MN1_Low");
      DeleteHorizontalLine(objname2 + "MN1_High");
      DeleteHorizontalLine(objname2 + "MN1_Low");
   }
}
void DrawHorizontalLine(double price, string label, color clr, datetime startTime, datetime endTime)
{
   if(ObjectFind(0, label) != -1)
   {
      DeleteHorizontalLine(label);
   }
   ObjectCreate(0, label, OBJ_TREND, 0, startTime, price, endTime, price);
//   if(GetLastError()>0)
//   {
//      Print(IntegerToString(_LastError) +" Error creating "+ label);
//  }
   ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, label, OBJPROP_STYLE, STYLE_SOLID);
   #ifdef __MQL5__ // In MT4 this will return error 4201
   ObjectSetInteger(0, label, OBJPROP_RAY_LEFT, false);
   #endif
   ObjectSetInteger(0, label, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, label, OBJPROP_SELECTED, false);
   ObjectSetDouble(0, label, OBJPROP_PRICE, price);
   ObjectSetInteger(0, label, OBJPROP_WIDTH, Line_Thickness);
}
bool IsNewH1Interval(const datetime& currentTime, const datetime& prevTime)
{
   MqlDateTime currentMqlTime, prevMqlTime;
   TimeToStruct(currentTime, currentMqlTime);
   TimeToStruct(prevTime, prevMqlTime);
   // Check if the day has changed
   if (currentMqlTime.day != prevMqlTime.day)
   {
      return true;
   }
   // Check if the minutes have changed
   if (currentMqlTime.min != prevMqlTime.min)
   {
      // Check if the current time is at an hourly interval
      if (currentMqlTime.min == 0 && prevMqlTime.hour < currentMqlTime.hour)
      {
         return true;
      }
   }
   return false;
}
