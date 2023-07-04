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
#property version "1.012"
input int    ATR_Period                    = 14;
input bool   M15_ATR_Projections           = true;
input bool   H1_ATR_Projections            = true;
input bool   H1_Historical_Projection      = false;
input bool   H4_ATR_Projections            = true;
input bool   D1_ATR_Projections            = true;
input bool   W1_ATR_Projections            = true;
input bool   MN1_ATR_Projections           = true;
input bool   UsePrevClose                  = false;
input bool   UseCurrentOpen                = true;
input ENUM_LINE_STYLE ATR_linestyle        = STYLE_DOT;
input int    ATR_Linethickness             = 2;
input color  ATR_Line_Color                = clrYellow;
input bool   ATR_Line_Background           = true;
input string FontName                      = "Courier New";
input int    FontSize                      = 8;
input color  FontColor                     = clrWhite;
const ENUM_BASE_CORNER Corner              = CORNER_RIGHT_UPPER;
input int    HorizPos                      = 310;
input int    VertPos                       = 104;
input int    ATRInfoDecimals               = 3;
string objname = "ATR";
int handle_iATR_D1, handle_iATR_W1, handle_iATR_MN1, handle_iATR_H4, handle_iATR_H1, handle_iATR_M15;
double iATR_D1[], iATR_W1[], iATR_MN1[], iATR_H4[], iATR_H1[], iATR_M15[];
int copiedD1, copiedW1, copiedMN1, copiedH4, copiedH1, copiedM15;
double avgD1, avgD, avgW1, avgH4, avgH1, avgH1_Historical1, avgH1_Historical2, avgMN1, avgM15;
double prevCloseD1 = 0;
double currentOpenD1 = 0;
double prevCloseW1 = 0;
double currentOpenW1 = 0;
double prevCloseMN1 = 0;
double currentOpenMN1 = 0;
double prevCloseH4 = 0;
double currentOpenH4 = 0;
double prevCloseH1 = 0;
double currentOpenH1 = 0;
double prevCloseM15 = 0;
double currentOpenM15 = 0;
double prevCloseH1Historical1 = 0;
double prevCloseH1Historical2 = 0;
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
   if (H1_Historical_Projection) {
      ObjectCreate(0, objname + "H1_Historical_Projection1", OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, objname + "H1_Historical_Projection1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "H1_Historical_Projection1", OBJPROP_WIDTH, ATR_Linethickness);
      ObjectSetInteger(0, objname + "H1_Historical_Projection1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "H1_Historical_Projection1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "H1_Historical_Projection2", OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, objname + "H1_Historical_Projection2", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "H1_Historical_Projection2", OBJPROP_WIDTH, ATR_Linethickness);
      ObjectSetInteger(0, objname + "H1_Historical_Projection2", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "H1_Historical_Projection2", OBJPROP_BACK, ATR_Line_Background);
   }
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
   // Copy buffer values to arrays
   copiedD1 = CopyBuffer(handle_iATR_D1, 0, 0, ATR_Period, iATR_D1);
   copiedW1 = CopyBuffer(handle_iATR_W1, 0, 0, ATR_Period, iATR_W1);
   copiedMN1 = CopyBuffer(handle_iATR_MN1, 0, 0, ATR_Period, iATR_MN1);
   copiedH4 = CopyBuffer(handle_iATR_H4, 0, 0, ATR_Period, iATR_H4);
   copiedH1 = CopyBuffer(handle_iATR_H1, 0, 0, (ATR_Period+2), iATR_H1);
   copiedM15 = CopyBuffer(handle_iATR_M15, 0, 0, ATR_Period, iATR_M15);
   return INIT_SUCCEEDED;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
}
void UpdateCandlestickData()
{
   if (UsePrevClose) {
      prevCloseD1 = iClose(_Symbol, PERIOD_D1, 1);
      prevCloseW1 = iClose(_Symbol, PERIOD_W1, 1);
      prevCloseMN1 = iClose(_Symbol, PERIOD_MN1, 1);
      prevCloseH4 = iClose(_Symbol, PERIOD_H4, 1);
      prevCloseH1 = iClose(_Symbol, PERIOD_H1, 1);
      prevCloseM15 = iClose(_Symbol, PERIOD_M15, 1);
      prevCloseH1Historical1 = iClose(_Symbol, PERIOD_H1, 2);
      prevCloseH1Historical2 = iClose(_Symbol, PERIOD_H1, 3);
   }
   if (UseCurrentOpen) {
      currentOpenD1 = iOpen(_Symbol, PERIOD_D1, 0);
      currentOpenW1 = iOpen(_Symbol, PERIOD_W1, 0);
      currentOpenMN1 = iOpen(_Symbol, PERIOD_MN1, 0);
      currentOpenH4 = iOpen(_Symbol, PERIOD_H4, 0);
      currentOpenH1 = iOpen(_Symbol, PERIOD_H1, 0);
      currentOpenM15 = iOpen(_Symbol, PERIOD_M15, 0);
      currentOpenH1Historical1 = iOpen(_Symbol, PERIOD_H1, 1);
      currentOpenH1Historical2 = iOpen(_Symbol, PERIOD_H1, 2);
   }
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
    // Check if a new 30-minute interval or 1-hour interval has started
    if (IsNewM15Interval(currentTradeServerTime, prevTradeServerTime))
    {
      UpdateATRData();
      UpdateCandlestickData();
      prevTradeServerTime = currentTradeServerTime;
      Print("Updating ATR Data and Candlestick data due to 15 min server time.");
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
   static int waitCountATR = 2;
   if ( waitCountATR > 0 ) {
      UpdateATRData();
      waitCountATR--;
      //PrintFormat( "Waiting for ATR data" );
      return ( prev_calculated );
   }
   //    PrintFormat( "ATR Data is now available" );
   // Initialize vars
   double atrLevelAboveD1prevClose = 0;
   double atrLevelBelowD1prevClose = 0;
   double atrLevelAboveD1currentOpen = 0;
   double atrLevelBelowD1currentOpen = 0;
   double atrLevelAboveW1prevClose = 0;
   double atrLevelBelowW1prevClose = 0;
   double atrLevelAboveW1currentOpen = 0;
   double atrLevelBelowW1currentOpen = 0;
   double atrLevelAboveMN1prevClose = 0;
   double atrLevelBelowMN1prevClose = 0;
   double atrLevelAboveMN1currentOpen = 0;
   double atrLevelBelowMN1currentOpen = 0;
   double atrLevelAboveH4prevClose = 0;
   double atrLevelBelowH4prevClose = 0;
   double atrLevelAboveH4currentOpen = 0;
   double atrLevelBelowH4currentOpen = 0;
   double atrLevelAboveH1prevClose = 0;
   double atrLevelBelowH1prevClose = 0;
   double atrLevelAboveH1prevCloseHistorical1 = 0;
   double atrLevelBelowH1prevCloseHistorical1 = 0;
   double atrLevelAboveH1prevCloseHistorical2 = 0;
   double atrLevelBelowH1prevCloseHistorical2 = 0;
   double atrLevelAboveM15prevClose = 0;
   double atrLevelBelowM15prevClose = 0;
   double atrLevelAboveH1currentOpen = 0;
   double atrLevelBelowH1currentOpen = 0;
   double atrLevelAboveH1currentOpenHistorical1 = 0;
   double atrLevelBelowH1currentOpenHistorical1 = 0;
   double atrLevelAboveH1currentOpenHistorical2 = 0;
   double atrLevelBelowH1currentOpenHistorical2 = 0;
   double atrLevelAboveM15currentOpen = 0;
   double atrLevelBelowM15currentOpen = 0;
   datetime endTime = time[rates_total - 1];
   static int waitCountCandlestick = 2;
   if ( waitCountCandlestick > 0 ) {
      UpdateCandlestickData();
      waitCountCandlestick--;
      //PrintFormat( "Waiting for Candlestick Data" );
      return ( prev_calculated );
   }
    //     PrintFormat( "Candlestick Data is now available" );
   if (D1_ATR_Projections && _Period <= PERIOD_W1)
   {
      atrLevelAboveD1prevClose = prevCloseD1 + avgD1;
      atrLevelBelowD1prevClose = prevCloseD1 - avgD1;
      datetime startTimeD1 = iTime(_Symbol, PERIOD_D1, 7);
      if (UsePrevClose) {
         ObjectCreate(0, objname + "LineTopD1_PrevClose", OBJ_TREND, 0, startTimeD1, prevCloseD1 + avgD1, endTime, prevCloseD1 + avgD1);
         ObjectSetInteger(0, objname + "LineTopD1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopD1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopD1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopD1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomD1_PrevClose", OBJ_TREND, 0, startTimeD1, prevCloseD1 - avgD1, endTime, prevCloseD1 - avgD1);
         ObjectSetInteger(0, objname + "LineBottomD1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomD1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomD1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomD1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
      }
      if (UseCurrentOpen) {
         atrLevelAboveD1currentOpen = currentOpenD1 + avgD1;
         atrLevelBelowD1currentOpen = currentOpenD1 - avgD1;
         ObjectCreate(0, objname + "LineTopD1_CurrentOpen", OBJ_TREND, 0, startTimeD1, currentOpenD1 + avgD1, endTime, currentOpenD1 + avgD1);
         ObjectSetInteger(0, objname + "LineTopD1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopD1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopD1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopD1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomD1_CurrentOpen", OBJ_TREND, 0, startTimeD1, currentOpenD1 - avgD1, endTime, currentOpenD1 - avgD1);
         ObjectSetInteger(0, objname + "LineBottomD1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomD1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomD1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomD1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
      }
   }
   if (W1_ATR_Projections)
   {
      datetime startTimeW1 = iTime(_Symbol, PERIOD_W1, 4);
      if (UsePrevClose) {
         atrLevelAboveW1prevClose = prevCloseW1 + avgW1;
         atrLevelBelowW1prevClose = prevCloseW1 - avgW1;
         ObjectCreate(0, objname + "LineTopW1_PrevClose", OBJ_TREND, 0, startTimeW1, atrLevelAboveW1prevClose, endTime, atrLevelAboveW1prevClose);
         ObjectSetInteger(0, objname + "LineTopW1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopW1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopW1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopW1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomW1_PrevClose", OBJ_TREND, 0, startTimeW1, atrLevelBelowW1prevClose, endTime, atrLevelBelowW1prevClose);
         ObjectSetInteger(0, objname + "LineBottomW1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomW1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomW1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomW1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
      }
      if (UseCurrentOpen) {
         atrLevelAboveW1currentOpen = currentOpenW1 + avgW1;
         atrLevelBelowW1currentOpen = currentOpenW1 - avgW1;
         ObjectCreate(0, objname + "LineTopW1_CurrentOpen", OBJ_TREND, 0, startTimeW1, atrLevelAboveW1currentOpen, endTime, atrLevelAboveW1currentOpen);
         ObjectSetInteger(0, objname + "LineTopW1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopW1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopW1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopW1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomW1_CurrentOpen", OBJ_TREND, 0, startTimeW1, atrLevelBelowW1currentOpen, endTime, atrLevelBelowW1currentOpen);
         ObjectSetInteger(0, objname + "LineBottomW1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomW1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomW1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomW1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
      }
   }
   if (MN1_ATR_Projections)
   {
      datetime startTimeMN1 = iTime(_Symbol, PERIOD_MN1, 2);
      if (UsePrevClose) {
         atrLevelAboveMN1prevClose = prevCloseMN1 + avgMN1;
         atrLevelBelowMN1prevClose = prevCloseMN1 - avgMN1;
         ObjectCreate(0, objname + "LineTopMN1_PrevClose", OBJ_TREND, 0, startTimeMN1, atrLevelAboveMN1prevClose, endTime, atrLevelAboveMN1prevClose);
         ObjectSetInteger(0, objname + "LineTopMN1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopMN1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopMN1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopMN1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomMN1_PrevClose", OBJ_TREND, 0, startTimeMN1, atrLevelBelowMN1prevClose, endTime, atrLevelBelowMN1prevClose);
         ObjectSetInteger(0, objname + "LineBottomMN1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomMN1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomMN1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomMN1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
      }
      if (UseCurrentOpen) {
         atrLevelAboveMN1currentOpen = currentOpenMN1 + avgMN1;
         atrLevelBelowMN1currentOpen = currentOpenMN1 - avgMN1;
         ObjectCreate(0, objname + "LineTopMN1_CurrentOpen", OBJ_TREND, 0, startTimeMN1, atrLevelAboveMN1currentOpen, endTime, atrLevelAboveMN1currentOpen);
         ObjectSetInteger(0, objname + "LineTopMN1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopMN1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopMN1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopMN1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomMN1_CurrentOpen", OBJ_TREND, 0, startTimeMN1, atrLevelBelowMN1currentOpen, endTime, atrLevelBelowMN1currentOpen);
         ObjectSetInteger(0, objname + "LineBottomMN1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomMN1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomMN1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomMN1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
      }
   }
   if (H4_ATR_Projections && _Period <= PERIOD_D1)
   {
      datetime startTimeH4 = iTime(_Symbol, PERIOD_H4, 11);
      if (UsePrevClose) {
         atrLevelAboveH4prevClose = prevCloseH4 + avgH4;
         atrLevelBelowH4prevClose = prevCloseH4 - avgH4;
         ObjectCreate(0, objname + "LineTopH4_PrevClose", OBJ_TREND, 0, startTimeH4, atrLevelAboveH4prevClose, endTime, atrLevelAboveH4prevClose);
         ObjectSetInteger(0, objname + "LineTopH4_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopH4_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopH4_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopH4_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomH4_PrevClose", OBJ_TREND, 0, startTimeH4, atrLevelBelowH4prevClose, endTime, atrLevelBelowH4prevClose);
         ObjectSetInteger(0, objname + "LineBottomH4_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomH4_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomH4_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomH4_PrevClose", OBJPROP_BACK, ATR_Line_Background);
      }
      if (UseCurrentOpen) {
         atrLevelAboveH4currentOpen = currentOpenH4 + avgH4;
         atrLevelBelowH4currentOpen = currentOpenH4 - avgH4;
         ObjectCreate(0, objname + "LineTopH4_CurrentOpen", OBJ_TREND, 0, startTimeH4, atrLevelAboveH4currentOpen, endTime, atrLevelAboveH4currentOpen);
         ObjectSetInteger(0, objname + "LineTopH4_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopH4_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopH4_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopH4_CurrentOpen", OBJPROP_BACK, true);
         ObjectCreate(0, objname + "LineBottomH4_CurrentOpen", OBJ_TREND, 0, startTimeH4, atrLevelBelowH4currentOpen, endTime, atrLevelBelowH4currentOpen);
         ObjectSetInteger(0, objname + "LineBottomH4_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomH4_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomH4_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomH4_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
      }
   }
   if (H1_ATR_Projections && _Period <= PERIOD_H4)
   {
      datetime startTimeH1 = iTime(_Symbol, PERIOD_H1, 12);
      if (UsePrevClose) {
         atrLevelAboveH1prevClose = prevCloseH1 + avgH1;
         atrLevelBelowH1prevClose = prevCloseH1 - avgH1;
         ObjectCreate(0, objname + "LineTopH1_PrevClose", OBJ_TREND, 0, startTimeH1, atrLevelAboveH1prevClose, endTime, atrLevelAboveH1prevClose);
         ObjectSetInteger(0, objname + "LineTopH1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopH1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopH1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopH1_PrevClose", OBJPROP_BACK, false);
         ObjectCreate(0, objname + "LineBottomH1_PrevClose", OBJ_TREND, 0, startTimeH1, atrLevelBelowH1prevClose, endTime, atrLevelBelowH1prevClose);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_BACK, false);
      }
      if (UseCurrentOpen) {
         atrLevelAboveH1currentOpen = currentOpenH1 + avgH1;
         atrLevelBelowH1currentOpen = currentOpenH1 - avgH1;
         ObjectCreate(0, objname + "LineTopH1_CurrentOpen", OBJ_TREND, 0, startTimeH1, atrLevelAboveH1currentOpen, endTime, atrLevelAboveH1currentOpen);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_BACK, false);
         ObjectCreate(0, objname + "LineBottomH1_CurrentOpen", OBJ_TREND, 0, startTimeH1, atrLevelBelowH1currentOpen, endTime, atrLevelBelowH1currentOpen);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_BACK, false);
      }
      if (H1_Historical_Projection) {
         datetime startTimeH1Historical1 = iTime(_Symbol, PERIOD_H1, 14);
         datetime startTimeH1Historical2 = iTime(_Symbol, PERIOD_H1, 17);
         if (UsePrevClose) {
            atrLevelAboveH1prevCloseHistorical1 = prevCloseH1Historical1 + avgH1_Historical1;
            atrLevelBelowH1prevCloseHistorical1 = prevCloseH1Historical1 - avgH1_Historical1;
            ObjectCreate(0, objname + "LineTopH1Historical_PrevClose1", OBJ_TREND, 0, startTimeH1Historical1, atrLevelAboveH1prevCloseHistorical1, endTime, atrLevelAboveH1prevCloseHistorical1);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose1", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose1", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose1", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose1", OBJPROP_BACK, false);
            ObjectCreate(0, objname + "LineBottomH1Historical_PrevClose1", OBJ_TREND, 0, startTimeH1Historical1, atrLevelBelowH1prevCloseHistorical1, endTime, atrLevelBelowH1prevCloseHistorical1);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose1", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose1", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose1", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose1", OBJPROP_BACK, false);
            atrLevelAboveH1prevCloseHistorical2 = prevCloseH1Historical2 + avgH1_Historical2;
            atrLevelBelowH1prevCloseHistorical2 = prevCloseH1Historical2 - avgH1_Historical2;
            ObjectCreate(0, objname + "LineTopH1Historical_PrevClose2", OBJ_TREND, 0, startTimeH1Historical2, atrLevelAboveH1prevCloseHistorical2, endTime, atrLevelAboveH1prevCloseHistorical2);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose2", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose2", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose2", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose2", OBJPROP_BACK, false);
            ObjectCreate(0, objname + "LineBottomH1Historical_PrevClose2", OBJ_TREND, 0, startTimeH1Historical2, atrLevelBelowH1prevCloseHistorical2, endTime, atrLevelBelowH1prevCloseHistorical2);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose2", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose2", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose2", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose2", OBJPROP_BACK, false);
         }
         if (UseCurrentOpen) {
            atrLevelAboveH1currentOpenHistorical1 = currentOpenH1Historical1 + avgH1_Historical1;
            atrLevelBelowH1currentOpenHistorical1 = currentOpenH1Historical1 - avgH1_Historical1;
            ObjectCreate(0, objname + "LineTopH1Historical_CurrentOpen1", OBJ_TREND, 0, startTimeH1Historical1, atrLevelAboveH1currentOpenHistorical1, endTime, atrLevelAboveH1currentOpenHistorical1);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen1", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen1", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen1", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen1", OBJPROP_BACK, false);
            ObjectCreate(0, objname + "LineBottomH1Historical_CurrentOpen1", OBJ_TREND, 0, startTimeH1Historical1, atrLevelBelowH1currentOpenHistorical1, endTime, atrLevelBelowH1currentOpenHistorical1);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen1", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen1", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen1", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen1", OBJPROP_BACK, false);
            atrLevelAboveH1currentOpenHistorical2 = currentOpenH1Historical2 + avgH1_Historical2;
            atrLevelBelowH1currentOpenHistorical2 = currentOpenH1Historical2 - avgH1_Historical2;
            ObjectCreate(0, objname + "LineTopH1Historical_CurrentOpen2", OBJ_TREND, 0, startTimeH1Historical2, atrLevelAboveH1currentOpenHistorical2, endTime, atrLevelAboveH1currentOpenHistorical2);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen2", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen2", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen2", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen2", OBJPROP_BACK, false);
            ObjectCreate(0, objname + "LineBottomH1Historical_CurrentOpen2", OBJ_TREND, 0, startTimeH1Historical2, atrLevelBelowH1currentOpenHistorical2, endTime, atrLevelBelowH1currentOpenHistorical2);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen2", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen2", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen2", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen2", OBJPROP_BACK, false);
         }
   }
   }
   if (M15_ATR_Projections && _Period <= PERIOD_H1)
   {
      datetime startTimeM15 = iTime(_Symbol, PERIOD_M15, 7);
      if (UsePrevClose) {
         atrLevelAboveM15prevClose = prevCloseM15 + avgH4;
         atrLevelBelowM15prevClose = prevCloseM15 - avgH4;
         ObjectCreate(0, objname + "LineTopM15_PrevClose", OBJ_TREND, 0, startTimeM15, atrLevelAboveM15prevClose, endTime, atrLevelAboveM15prevClose);
         ObjectSetInteger(0, objname + "LineTopM15_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopM15_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopM15_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopM15_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomM15_PrevClose", OBJ_TREND, 0, startTimeM15, atrLevelBelowM15prevClose, endTime, atrLevelBelowM15prevClose);
         ObjectSetInteger(0, objname + "LineBottomM15_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomM15_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomM15_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomM15_PrevClose", OBJPROP_BACK, ATR_Line_Background);
      }
      if (UseCurrentOpen) {
         atrLevelAboveM15currentOpen = currentOpenM15 + avgM15;
         atrLevelBelowM15currentOpen = currentOpenM15 - avgM15;
         ObjectCreate(0, objname + "LineTopM15_CurrentOpen", OBJ_TREND, 0, startTimeM15, atrLevelAboveM15currentOpen, endTime, atrLevelAboveM15currentOpen);
         ObjectSetInteger(0, objname + "LineTopM15_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopM15_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopM15_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopM15_CurrentOpen", OBJPROP_BACK, true);
         ObjectCreate(0, objname + "LineBottomM15_CurrentOpen", OBJ_TREND, 0, startTimeM15, atrLevelBelowM15currentOpen, endTime, atrLevelBelowM15currentOpen);
         ObjectSetInteger(0, objname + "LineBottomM15_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomM15_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomM15_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomM15_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
      }
   }
   return rates_total;
}
bool IsNewM15Interval(const datetime& currentTime, const datetime& prevTime)
{
    MqlDateTime currentMqlTime, prevMqlTime;
    TimeToStruct(currentTime, currentMqlTime);
    TimeToStruct(prevTime, prevMqlTime);
    //Print("IsNew30MinInterval() has run.");
    // Check if the minutes have changed
    if (currentMqlTime.min != prevMqlTime.min)
    {
        // Check if the current time is at a a 15 minute interval
        if (currentMqlTime.min == 0 || currentMqlTime.min == 15 || currentMqlTime.min == 30 || currentMqlTime.min == 45 )
        {
            // Check if the hours have changed
          //  if (currentMqlTime.hour != prevMqlTime.hour)
          //  {
                return true;
          //  }
        }
    }
    return false;
}
