/**=        ATR_Projection.mq5  (TyphooN's ATR Projection Indicator)
 *               Copyright 2023, TyphooN (https://www.decapool.net/)
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
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots 0
#property version "1.017"
input group  "[ATR/Period Settings]";
input int    ATR_Period                    = 14;
input bool   M15_ATR_Projections           = true;
input bool   H1_ATR_Projections            = true;
input bool   H1_Historical_Projection      = false;
input bool   H4_ATR_Projections            = true;
input bool   D1_ATR_Projections            = true;
input bool   W1_ATR_Projections            = true;
input bool   MN1_ATR_Projections           = true;
input group  "[Line Settings]";
input ENUM_LINE_STYLE ATR_linestyle        = STYLE_DOT;
input int    ATR_Line_Thickness             = 2;
input color  ATR_Line_Color                = clrYellow;
input bool   ATR_Line_Background           = false;
input group  "[Info Text Settings]";
input string FontName                      = "Courier New";
input int    FontSize                      = 8;
input color  FontColor                     = clrWhite;
const ENUM_BASE_CORNER Corner              = CORNER_RIGHT_UPPER;
input int    HorizPos                      = 310;
input int    VertPos                       = 104;
input int    ATRInfoDecimals               = 3;
string objname = "Projected ATR ";
int handle_iATR_D1, handle_iATR_W1, handle_iATR_MN1, handle_iATR_H4, handle_iATR_H1, handle_iATR_M15;
double iATR_D1[], iATR_W1[], iATR_MN1[], iATR_H4[], iATR_H1[], iATR_M15[];
int copiedD1, copiedW1, copiedMN1, copiedH4, copiedH1, copiedM15;
double avgD1, avgD, avgW1, avgH4, avgH1, avgH1_Historical1, avgH1_Historical2, avgMN1, avgM15;
double currentOpenD1 = 0;
double currentOpenW1 = 0;
double currentOpenMN1 = 0;
double currentOpenH4 = 0;
double currentOpenH1 = 0;
double currentOpenM15 = 0;
double currentOpenH1Historical1 = 0;
double currentOpenH1Historical2 = 0;
int lastCheckedCandle = -1;
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, iATR_D1, INDICATOR_DATA);
   SetIndexBuffer(1, iATR_W1, INDICATOR_DATA);
   SetIndexBuffer(2, iATR_MN1, INDICATOR_DATA);
   SetIndexBuffer(3, iATR_H4, INDICATOR_DATA);
   SetIndexBuffer(4, iATR_H1, INDICATOR_DATA);
   SetIndexBuffer(5, iATR_M15, INDICATOR_DATA);
   ObjectCreate(0, objname + "Info1", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_YDISTANCE, VertPos);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_CORNER, Corner);
   ObjectSetString(0, objname + "Info1", OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_COLOR, FontColor);
   ObjectCreate(0, objname + "Info2", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_YDISTANCE, VertPos + 13);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_CORNER, Corner);
   ObjectSetString(0, objname + "Info2", OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_COLOR, FontColor);
   ArraySetAsSeries(iATR_D1, true);
   ArraySetAsSeries(iATR_W1, true);
   ArraySetAsSeries(iATR_MN1, true);
   ArraySetAsSeries(iATR_H4, true);
   ArraySetAsSeries(iATR_H1, true);
   ArraySetAsSeries(iATR_M15, true);
   handle_iATR_D1 = iATR(_Symbol, PERIOD_D1, ATR_Period);
   handle_iATR_W1 = iATR(_Symbol, PERIOD_W1, ATR_Period);
   handle_iATR_MN1 = iATR(_Symbol, PERIOD_MN1, ATR_Period);
   handle_iATR_H4 = iATR(_Symbol, PERIOD_H4, ATR_Period);
   handle_iATR_H1 = iATR(_Symbol, PERIOD_H1, ATR_Period);
   handle_iATR_M15 = iATR(_Symbol, PERIOD_M15, ATR_Period);
   // Check if the handles are created successfully
   if (handle_iATR_D1 == INVALID_HANDLE || handle_iATR_W1 == INVALID_HANDLE || handle_iATR_MN1 == INVALID_HANDLE ||
      handle_iATR_H4 == INVALID_HANDLE || handle_iATR_H1 == INVALID_HANDLE || handle_iATR_M15 == INVALID_HANDLE)
   {
      Print("Failed to create handles for iATR indicator");
      Print("handle_iATR_D1: ", handle_iATR_D1);
      Print("handle_iATR_W1: ", handle_iATR_W1);
      Print("handle_iATR_MN1: ", handle_iATR_MN1);
      Print("handle_iATR_H4: ", handle_iATR_H4);
      Print("handle_iATR_H1: ", handle_iATR_H1);
      Print("handle_iATR_M15: ", handle_iATR_M15);
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
}
void UpdateCandlestickData()
{
   currentOpenD1 = iOpen(_Symbol, PERIOD_D1, 0);
   currentOpenW1 = iOpen(_Symbol, PERIOD_W1, 0);
   currentOpenMN1 = iOpen(_Symbol, PERIOD_MN1, 0);
   currentOpenH4 = iOpen(_Symbol, PERIOD_H4, 0);
   currentOpenH1 = iOpen(_Symbol, PERIOD_H1, 0);
   currentOpenM15 = iOpen(_Symbol, PERIOD_M15, 0);
   currentOpenH1Historical1 = iOpen(_Symbol, PERIOD_H1, 1);
   currentOpenH1Historical2 = iOpen(_Symbol, PERIOD_H1, 2);
}
void UpdateATRData()
{
   copiedD1 = CopyBuffer(handle_iATR_D1, 0, 0, ATR_Period, iATR_D1);
   copiedW1 = CopyBuffer(handle_iATR_W1, 0, 0, ATR_Period, iATR_W1);
   copiedMN1 = CopyBuffer(handle_iATR_MN1, 0, 0, ATR_Period, iATR_MN1);
   copiedH4 = CopyBuffer(handle_iATR_H4, 0, 0, ATR_Period, iATR_H4);
   copiedM15 = CopyBuffer(handle_iATR_M15, 0, 0, ATR_Period, iATR_M15);
   if (H1_Historical_Projection == true)
   {
      copiedH1 = CopyBuffer(handle_iATR_H1, 0, 0, (ATR_Period + 2), iATR_H1);
   }
   if(H1_Historical_Projection == false)
   {
      copiedH1 = CopyBuffer(handle_iATR_H1, 0, 0, ATR_Period, iATR_H1);
   }
}
int OnCalculate(const int        rates_total,
               const int        prev_calculated,
               const datetime& time[],
               const double&   open[],
               const double&   high[],
               const double&   low[],
               const double&   close[],
               const long&     tick_volume[],
               const long&     volume[],
               const int&      spread[])
{
    static datetime prevTradeServerTime = 0;  // Initialize with 0 on the first run
    datetime currentTradeServerTime = TimeTradeServer();
    // Check if a new 15-minute interval
    if (IsNewM15Interval(currentTradeServerTime, prevTradeServerTime))
    {
      UpdateATRData();
      UpdateCandlestickData();
      prevTradeServerTime = currentTradeServerTime;
      //Print("Updating ATR Data and Candlestick data due to 15 min server time.");
    }
   // Calculate the number of bars to be processed
   int limit = rates_total - prev_calculated;
   // If there are no new bars, return
   if (limit <= 0)
      return 0;
   // Check if a new candlestick has formed
   if (lastCheckedCandle != rates_total - 1) {
      //Print("New candle has formed, updating ATR & Candlestick Data");
      // Update the last checked candle index
      lastCheckedCandle = rates_total - 1;
      UpdateATRData();
      UpdateCandlestickData();
   }
   int currentbar = rates_total - 1;
   // Check if the current bar is within the valid range of the arrays
   if (currentbar >= ATR_Period && currentbar < rates_total)
   {
   // Calculate the average true range (ATR) for the specified period
      avgD1 = iATR_D1[0];
      avgW1 = iATR_W1[0];
      avgMN1 = iATR_MN1[0];
      avgH4 = iATR_H4[0];
      avgH1 = iATR_H1[0];
      avgH1_Historical1 = iATR_H1[1];
      avgH1_Historical2 = iATR_H1[2];
      avgM15 = iATR_M15[0];
   }
   double M15info = 0;
   double H1info = 0;
   double H4info = 0;
   double D1info = 0;
   double W1info = 0;
   double MN1info = 0;
   if (copiedD1 != ATR_Period)
      D1info = copiedD1;
   if (copiedW1 != ATR_Period)
      W1info = copiedW1;
   if (copiedMN1 != ATR_Period)
      MN1info = copiedMN1;
   if (copiedH4 != ATR_Period)
      H4info = copiedH4;
   if (H1_Historical_Projection == true && copiedH1 != (ATR_Period + 2))
      H1info = copiedH1;
   if (H1_Historical_Projection == false && copiedH1 != ATR_Period)
      H1info = copiedH1;
   if (copiedM15 != ATR_Period)
      M15info = copiedM15;
    if (copiedD1 == ATR_Period)
      D1info = avgD1;
   if (copiedW1 == ATR_Period)
      W1info = avgW1;
   if (copiedMN1 == ATR_Period)
      MN1info = avgMN1;
   if (copiedH4 == ATR_Period)
      H4info = avgH4;
   if (H1_Historical_Projection == true && copiedH1 == (ATR_Period + 2))
      H1info = avgH1;
   if (H1_Historical_Projection == false && copiedH1 == ATR_Period)
      H1info = avgH1;
   if (copiedM15 == ATR_Period)
      M15info = avgM15;
   string infoText1 = "ATR| M15: " + DoubleToString(M15info, ATRInfoDecimals) + " H1: " + DoubleToString(H1info, ATRInfoDecimals) + " H4: " + DoubleToString(H4info, ATRInfoDecimals);
   string infoText2 = "ATR| D1: " + DoubleToString(D1info, ATRInfoDecimals) + " W1: " + DoubleToString(W1info, ATRInfoDecimals) + " MN1: " + DoubleToString(MN1info, ATRInfoDecimals);
   ObjectSetString(0, objname + "Info1", OBJPROP_TEXT, infoText1);
   ObjectSetString(0, objname + "Info2", OBJPROP_TEXT, infoText2);
   static int waitCount = 2;
   if ( waitCount > 0 ) {
      UpdateATRData();
      UpdateCandlestickData();
      waitCount--;
      return ( prev_calculated );
   }
   //PrintFormat( "ATR and candlestick Data is now available" );
   // Initialize vars
   double atrLevelAboveD1currentOpen = 0;
   double atrLevelBelowD1currentOpen = 0;
   double atrLevelAboveW1currentOpen = 0;
   double atrLevelBelowW1currentOpen = 0;
   double atrLevelAboveMN1currentOpen = 0;
   double atrLevelBelowMN1currentOpen = 0;
   double atrLevelAboveH4currentOpen = 0;
   double atrLevelBelowH4currentOpen = 0;
   double atrLevelAboveH1currentOpen = 0;
   double atrLevelBelowH1currentOpen = 0;
   double atrLevelAboveH1currentOpenHistorical1 = 0;
   double atrLevelBelowH1currentOpenHistorical1 = 0;
   double atrLevelAboveH1currentOpenHistorical2 = 0;
   double atrLevelBelowH1currentOpenHistorical2 = 0;
   double atrLevelAboveM15currentOpen = 0;
   double atrLevelBelowM15currentOpen = 0;
   datetime endTime = time[rates_total - 1];
   if (D1_ATR_Projections && _Period <= PERIOD_W1)
   {
      datetime startTimeD1 = iTime(_Symbol, PERIOD_D1, 7);
      atrLevelAboveD1currentOpen = currentOpenD1 + avgD1;
      atrLevelBelowD1currentOpen = currentOpenD1 - avgD1;
      ObjectCreate(0, objname + "High D1", OBJ_TREND, 0, startTimeD1, currentOpenD1 + avgD1, endTime, currentOpenD1 + avgD1);
      ObjectSetInteger(0, objname + "High D1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High D1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High D1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High D1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low D1", OBJ_TREND, 0, startTimeD1, currentOpenD1 - avgD1, endTime, currentOpenD1 - avgD1);
      ObjectSetInteger(0, objname + "Low D1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low D1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low D1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low D1", OBJPROP_BACK, ATR_Line_Background);
   }
   if (W1_ATR_Projections)
   {
      datetime startTimeW1 = iTime(_Symbol, PERIOD_W1, 4);
      atrLevelAboveW1currentOpen = currentOpenW1 + avgW1;
      atrLevelBelowW1currentOpen = currentOpenW1 - avgW1;
      ObjectCreate(0, objname + "High W1", OBJ_TREND, 0, startTimeW1, atrLevelAboveW1currentOpen, endTime, atrLevelAboveW1currentOpen);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low W1", OBJ_TREND, 0, startTimeW1, atrLevelBelowW1currentOpen, endTime, atrLevelBelowW1currentOpen);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_BACK, ATR_Line_Background);
   }
   if (MN1_ATR_Projections)
   {
      datetime startTimeMN1 = iTime(_Symbol, PERIOD_MN1, 2);
      atrLevelAboveMN1currentOpen = currentOpenMN1 + avgMN1;
      atrLevelBelowMN1currentOpen = currentOpenMN1 - avgMN1;
      ObjectCreate(0, objname + "High MN1", OBJ_TREND, 0, startTimeMN1, atrLevelAboveMN1currentOpen, endTime, atrLevelAboveMN1currentOpen);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low MN1", OBJ_TREND, 0, startTimeMN1, atrLevelBelowMN1currentOpen, endTime, atrLevelBelowMN1currentOpen);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_BACK, ATR_Line_Background);
   }
   if (H4_ATR_Projections && _Period <= PERIOD_D1)
   {
      datetime startTimeH4 = iTime(_Symbol, PERIOD_H4, 11);

         atrLevelAboveH4currentOpen = currentOpenH4 + avgH4;
         atrLevelBelowH4currentOpen = currentOpenH4 - avgH4;
         ObjectCreate(0, objname + "High H4", OBJ_TREND, 0, startTimeH4, atrLevelAboveH4currentOpen, endTime, atrLevelAboveH4currentOpen);
         ObjectSetInteger(0, objname + "High H4", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "High H4", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "High H4", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "High H4", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "Low H4", OBJ_TREND, 0, startTimeH4, atrLevelBelowH4currentOpen, endTime, atrLevelBelowH4currentOpen);
         ObjectSetInteger(0, objname + "Low H4", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "Low H4", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "Low H4", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "Low H4", OBJPROP_BACK, ATR_Line_Background);
   }
   if (H1_ATR_Projections && _Period <= PERIOD_H4)
   {
      datetime startTimeH1 = iTime(_Symbol, PERIOD_H1, 12);
      atrLevelAboveH1currentOpen = currentOpenH1 + avgH1;
      atrLevelBelowH1currentOpen = currentOpenH1 - avgH1;
      ObjectCreate(0, objname + "High H1", OBJ_TREND, 0, startTimeH1, atrLevelAboveH1currentOpen, endTime, atrLevelAboveH1currentOpen);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low H1", OBJ_TREND, 0, startTimeH1, atrLevelBelowH1currentOpen, endTime, atrLevelBelowH1currentOpen);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_BACK, ATR_Line_Background);
      if (H1_Historical_Projection)
      {
         datetime startTimeH1Historical1 = iTime(_Symbol, PERIOD_H1, 14);
         datetime startTimeH1Historical2 = iTime(_Symbol, PERIOD_H1, 17);
         atrLevelAboveH1currentOpenHistorical1 = currentOpenH1Historical1 + avgH1_Historical1;
         atrLevelBelowH1currentOpenHistorical1 = currentOpenH1Historical1 - avgH1_Historical1;
         ObjectCreate(0, objname + "High H1 Historical 1", OBJ_TREND, 0, startTimeH1Historical1, atrLevelAboveH1currentOpenHistorical1, endTime, atrLevelAboveH1currentOpenHistorical1);
         ObjectSetInteger(0, objname + "High H1 Historical 1", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "High H1 Historical 1", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "High H1 Historical 1", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "High H1_Historical 1", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "Low H1 Historical 1", OBJ_TREND, 0, startTimeH1Historical1, atrLevelBelowH1currentOpenHistorical1, endTime, atrLevelBelowH1currentOpenHistorical1);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_BACK, ATR_Line_Background);
         atrLevelAboveH1currentOpenHistorical2 = currentOpenH1Historical2 + avgH1_Historical2;
         atrLevelBelowH1currentOpenHistorical2 = currentOpenH1Historical2 - avgH1_Historical2;
         ObjectCreate(0, objname + "High H1 Historical 2", OBJ_TREND, 0, startTimeH1Historical2, atrLevelAboveH1currentOpenHistorical2, endTime, atrLevelAboveH1currentOpenHistorical2);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "Low H1 Historical 2", OBJ_TREND, 0, startTimeH1Historical2, atrLevelBelowH1currentOpenHistorical2, endTime, atrLevelBelowH1currentOpenHistorical2);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_BACK, ATR_Line_Background);
   }
   }
   if (M15_ATR_Projections && _Period <= PERIOD_H1)
   {
      datetime startTimeM15 = iTime(_Symbol, PERIOD_M15, 7);
      atrLevelAboveM15currentOpen = currentOpenM15 + avgM15;
      atrLevelBelowM15currentOpen = currentOpenM15 - avgM15;
      ObjectCreate(0, objname + "High M15", OBJ_TREND, 0, startTimeM15, atrLevelAboveM15currentOpen, endTime, atrLevelAboveM15currentOpen);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low M15", OBJ_TREND, 0, startTimeM15, atrLevelBelowM15currentOpen, endTime, atrLevelBelowM15currentOpen);
      ObjectSetInteger(0, objname + "Low M15", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low M15", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low M15", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low M15", OBJPROP_BACK, ATR_Line_Background);
   }
   return rates_total;
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
