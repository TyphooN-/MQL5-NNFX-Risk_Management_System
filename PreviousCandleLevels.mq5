/**=   PreviousCandleLevels.mq5   (TyphooN's Previous Candlestick Level Indicator)
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
#property version   "1.036"
#property description "TyphooN's PreviousCandleLevels"
#property indicator_chart_window
// Define input parameters
input color PreviousCandleColour = clrWhite;
input color JudasLevelColour = clrMagenta;
input int Line_Thickness = 2;
// Global vars
string objname1 = "Previous_";
string objname2 = "Current_";
double Previous_H1_High, Previous_H1_Low, Previous_H4_High, Previous_H4_Low, Previous_D1_High, Previous_D1_Low, Previous_W1_High, Previous_W1_Low,
   Previous_MN1_High, Previous_MN1_Low, Asian_High, Asian_Low, London_High, London_Low, Current_D1_Low, Current_D1_High, Ask, Bid;
int lastCheckedCandle = -1;
input int AsianBeginningHour = 0;   // Asian session start hour
input int AsianEndingHour = 8;      // Asian session end hour
input int LondonBeginningHour = 8;  // London session start hour
input int LondonEndingHour = 16;    // London session end hour
datetime AsianSessionStart, AsianSessionEnd, LondonSessionStart, LondonSessionEnd;
datetime LastJudasUpdate = 0;
int OnInit()
{
   datetime CurrentDay = iTime(_Symbol, PERIOD_D1, 0);
   AsianSessionStart = CurrentDay + AsianBeginningHour * 3600;
   AsianSessionEnd = CurrentDay + AsianEndingHour * 3600;
   LondonSessionStart = CurrentDay + LondonBeginningHour * 3600;
   LondonSessionEnd = CurrentDay + LondonEndingHour * 3600;
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
   datetime CurrentDay = iTime(_Symbol, PERIOD_D1, 0);
   AsianSessionStart = CurrentDay + AsianBeginningHour * 3600;
   AsianSessionEnd = CurrentDay + AsianEndingHour * 3600;
   LondonSessionStart = CurrentDay + LondonBeginningHour * 3600;
   LondonSessionEnd = CurrentDay + LondonEndingHour * 3600;
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
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
   if (((TimeCurrent() > (LastJudasUpdate + 60)) && ((Ask > Current_D1_High) || (Bid < Current_D1_Low))))
   {
      UpdateJudasData();
      DrawLines();
      //Print("Called Judas Data update.");
   }
   // Check if a new day has started since the last calculation
   if (IsNewDayForSessions())
   {
      // Delete current Asian and London session high/low lines
      ObjectsDeleteAll(0, objname2 + "Asian_High");
      ObjectsDeleteAll(0, objname2 + "Asian_Low");
      ObjectsDeleteAll(0, objname2 + "London_High");
      ObjectsDeleteAll(0, objname2 + "London_Low");
    }
 //  Print("AsianSessionStart: ", AsianSessionStart, " AsianSessionEnd: ", AsianSessionEnd);
//  Print("Current Time: ", TimeTradeServer());
 //  Print("LondonSessionStart: ", LondonSessionStart, " LondonSessionEnd: ", LondonSessionEnd);
 // Print("Current Time: ", TimeTradeServer());
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
   UpdateSessionData(AsianSessionStart, AsianSessionEnd, Asian_High, Asian_Low);
   UpdateSessionData(LondonSessionStart, LondonSessionEnd, London_High, London_Low);
   // Calculate current day's High and low
   int currentDayStartShift = iBarShift(_Symbol, PERIOD_D1, iTime(_Symbol, PERIOD_D1, 0));
   int currentDayEndShift = iBarShift(_Symbol, PERIOD_CURRENT, iTime(_Symbol, PERIOD_M1, 0));
   Current_D1_High = iHigh(_Symbol, PERIOD_D1, currentDayEndShift);
   Current_D1_Low = iLow(_Symbol, PERIOD_D1, currentDayStartShift);
}
void UpdateSessionData(const datetime& SessionStart, const datetime& SessionEnd, double& SessionHigh, double& SessionLow)
{
   datetime currentDate = iTime(_Symbol, PERIOD_H1, 0);
   int bars = iBars(_Symbol, PERIOD_H1);
   int SessionStartIndex = -1;
   int SessionEndIndex = -1;
   MqlDateTime barDateTime;
   MqlDateTime sessionStartDateTime;
   MqlDateTime sessionEndDateTime;
   MqlDateTime currentDateTime;
   TimeToStruct(SessionStart, sessionStartDateTime);
   TimeToStruct(SessionEnd, sessionEndDateTime);
   TimeToStruct(currentDate, currentDateTime);
   // Find SessionStartIndex and SessionEndIndex for the current date
   for (int i = 0; i < bars; i++)
   {
      datetime barTime = iTime(_Symbol, PERIOD_H1, i);
      TimeToStruct(barTime, barDateTime);
      if (barDateTime.year == currentDateTime.year &&
          barDateTime.mon == currentDateTime.mon &&
          barDateTime.day == currentDateTime.day)
      {
         if (barDateTime.year > sessionStartDateTime.year ||
             (barDateTime.year == sessionStartDateTime.year && barDateTime.mon > sessionStartDateTime.mon) ||
             (barDateTime.year == sessionStartDateTime.year && barDateTime.mon == sessionStartDateTime.mon && barDateTime.day >= sessionStartDateTime.day))
         {
            SessionStartIndex = i;
         }
         if (barDateTime.year < sessionEndDateTime.year ||
             (barDateTime.year == sessionEndDateTime.year && barDateTime.mon < sessionEndDateTime.mon) ||
             (barDateTime.year == sessionEndDateTime.year && barDateTime.mon == sessionEndDateTime.mon && barDateTime.day <= sessionEndDateTime.day))
         {
            SessionEndIndex = i;
         }
         if (barDateTime.year > sessionEndDateTime.year ||
             (barDateTime.year == sessionEndDateTime.year && barDateTime.mon > sessionEndDateTime.mon) ||
             (barDateTime.year == sessionEndDateTime.year && barDateTime.mon == sessionEndDateTime.mon && barDateTime.day > sessionEndDateTime.day))
         {
            break;  // No need to check further, as we have found the SessionEndIndex
         }
      }
   }
   //Print("SessionStartIndex: ", SessionStartIndex, " SessionEndIndex: ", SessionEndIndex);
   // Process bars between SessionStartIndex and SessionEndIndex
   for (int i = SessionStartIndex; i <= SessionEndIndex; i++)
   {
      double High = iHigh(_Symbol, PERIOD_H1, i);
      double Low = iLow(_Symbol, PERIOD_H1, i);
      //Print("Bar: ", i, " High: ", High, " Low: ", Low);
      if (High > SessionHigh || SessionHigh == 0)
      {
         SessionHigh = High;
      }
      if (Low < SessionLow || SessionLow == 0)
      {
         SessionLow = Low;
      }
   }
   //Print("Final SessionHigh: ", SessionHigh, " SessionLow: ", SessionLow);
}
void DeleteHorizontalLine(string object)
{
      if(ObjectCreate(0, object, OBJ_TREND, 0, 0, 0, 0, 0))
      {
         ObjectDelete(0, object);
      }
}
void DrawLines()
{
   if (_Period <= PERIOD_H1)
   {
      DrawHorizontalLine(Previous_H1_High, objname1 + "H1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_H1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H1_Low, objname1 + "H1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_H1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H4_High, objname1 + "H4_High", PreviousCandleColour, iTime(_Symbol, PERIOD_H4, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H4_Low, objname1 + "H4_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_H4, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_High, objname1 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_Low, objname1 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_High, objname1 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname1 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_High, objname2 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_Low, objname2 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      if (TimeCurrent() >= AsianSessionEnd)
      {
         DrawHorizontalLine(Asian_High, objname2 + "Asian_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
         DrawHorizontalLine(Asian_Low, objname2 + "Asian_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      }
      if (TimeCurrent() >= LondonSessionEnd)
      {
         DrawHorizontalLine(London_High, objname2 + "London_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
         DrawHorizontalLine(London_Low, objname2 + "London_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      }
   }
   if(_Period >= PERIOD_H1 && _Period <= PERIOD_H8)
   {
      DeleteHorizontalLine(objname1 + "H1_High");
      DeleteHorizontalLine(objname1 + "H1_Low");
      DrawHorizontalLine(Previous_H4_High, objname1 + "H4_High", PreviousCandleColour, iTime(_Symbol, PERIOD_H4, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_H4_Low, objname1 + "H4_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_H4, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_High, objname1 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_Low, objname1 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_High, objname1 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname1 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_High, objname2 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_Low, objname2 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      if (TimeCurrent() >= AsianSessionEnd)
      {
         DrawHorizontalLine(Asian_High, objname2 + "Asian_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
         DrawHorizontalLine(Asian_Low, objname2 + "Asian_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      }
      if (TimeCurrent() >= LondonSessionEnd)
      {
         DrawHorizontalLine(London_High, objname2 + "London_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
         DrawHorizontalLine(London_Low, objname2 + "London_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      }
   }
   if(_Period == PERIOD_D1 || _Period == PERIOD_H12)
   {
      DeleteHorizontalLine(objname1 + "H1_High");
      DeleteHorizontalLine(objname1 + "H1_Low");
      DeleteHorizontalLine(objname1 + "H4_High");
      DeleteHorizontalLine(objname1 + "H4_Low");
      DrawHorizontalLine(Previous_D1_High, objname1 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_D1_Low, objname1 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_High, objname1 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname1 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_High, objname2 + "D1_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Current_D1_Low, objname2 + "D1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      if (TimeCurrent() >= AsianSessionEnd)
      {
         DrawHorizontalLine(Asian_High, objname2 + "Asian_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
         DrawHorizontalLine(Asian_Low, objname2 + "Asian_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      }
      if (TimeCurrent() >= LondonSessionEnd)
      {
         DrawHorizontalLine(London_High, objname2 + "London_High", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
         DrawHorizontalLine(London_Low, objname2 + "London_Low", JudasLevelColour, iTime(_Symbol, PERIOD_D1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      }
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
      DeleteHorizontalLine(objname2 + "Asian_High");
      DeleteHorizontalLine(objname2 + "Asian_Low");
      DeleteHorizontalLine(objname2 + "London_High");
      DeleteHorizontalLine(objname2 + "London_Low");
      DrawHorizontalLine(Previous_W1_High, objname2 + "W1_High", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_W1_Low, objname2 + "W1_Low", JudasLevelColour, iTime(_Symbol, PERIOD_W1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_High, objname1 + "MN1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname1 + "MN1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
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
      DeleteHorizontalLine(objname2 + "D1_High");
      DeleteHorizontalLine(objname2 + "D1_Low");
      DeleteHorizontalLine(objname2 + "Asian_High");
      DeleteHorizontalLine(objname2 + "Asian_Low");
      DeleteHorizontalLine(objname2 + "London_High");
      DeleteHorizontalLine(objname2 + "London_Low");
      DrawHorizontalLine(Previous_MN1_High, objname2 + "MN1_High", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
      DrawHorizontalLine(Previous_MN1_Low, objname2 + "MN1_Low", PreviousCandleColour, iTime(_Symbol, PERIOD_MN1, 1), iTime(_Symbol, PERIOD_CURRENT, 0));
   }
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
bool IsNewDayForSessions()
{
    // Get the current date and time
    datetime CurrentServerTime = TimeCurrent();
    MqlDateTime CurrentMqlTime;
    TimeToStruct(CurrentServerTime, CurrentMqlTime);
    // Compare the current date to the date when Asian and London sessions were last updated
    datetime AsianLondonSessionDate = iTime(_Symbol, PERIOD_D1, 1);
    MqlDateTime AsianLondonSessionMqlTime;
    TimeToStruct(AsianLondonSessionDate, AsianLondonSessionMqlTime);
    if (CurrentMqlTime.year != AsianLondonSessionMqlTime.year ||
        CurrentMqlTime.mon != AsianLondonSessionMqlTime.mon ||
        CurrentMqlTime.day != AsianLondonSessionMqlTime.day)
    {
        return true; // It's a new day
    }
    return false; // Same day as the last session update
}
