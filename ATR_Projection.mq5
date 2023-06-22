/**=        ATR_Projection.mqh  (TyphooN's ATR Projection Indicator)
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
#property indicator_plots 0
#property version "1.006"
input int    ATR_Period                    = 14;
input bool   H1_ATR_Projections            = true;
input bool   H1_Historical_Projection      = true;
input bool   H4_ATR_Projections            = true;
input bool   D1_ATR_Projections            = true;
input bool   W1_ATR_Projections            = true;
input bool   MN1_ATR_Projections           = true;
input bool   UsePrevClose                  = true;
input bool   UseCurrentOpen                = false;
input ENUM_LINE_STYLE ATR_linestyle        = STYLE_DOT;
input int    ATR_Linethickness             = 2;
input color  ATR_Line_Color                = clrYellow;
input bool   ATR_Line_Background           = false;
input string FontName                      = "Courier New";
input int    FontSize                      = 8;
input color  FontColor                     = clrWhite;
const ENUM_BASE_CORNER Corner              = CORNER_RIGHT_UPPER;
input int    HorizPos                      = 310;
input int    VertPos                       = 140;
string objname = "ATR";
int handle_iATR_D1, handle_iATR_W1, handle_iATR_MN1, handle_iATR_H4, handle_iATR_H1, handle_iATR_M30;
double iATR_D1[], iATR_W1[], iATR_MN1[], iATR_H4[], iATR_H1[], iATR_M30[];
int copiedD1, copiedW1, copiedMN1, copiedH4, copiedH1, copiedM30;
double avgD1, avgD, avgW1, avgH4, avgH1, avgH1_Historical, avgMN1, avgM30;
double prevCloseD1 = 0.0;
double currentOpenD1 = 0.0;
double prevCloseW1 = 0.0;
double currentOpenW1 = 0.0;
double prevCloseMN1 = 0.0;
double currentOpenMN1 = 0.0;
double prevCloseH4 = 0.0;
double currentOpenH4 = 0.0;
double prevCloseH1 = 0.0;
double currentOpenH1 = 0.0;
double prevCloseH1Historical = 0.0;
double currentOpenH1Historical = 0.0;
int OnInit()
{
   ObjectCreate(0, objname + "Info1", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_YDISTANCE, VertPos);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_CORNER, Corner);
   ObjectSetString(0, objname + "Info1", OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_COLOR, FontColor);
   ObjectCreate(0, objname + "Info2", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_YDISTANCE, VertPos + (FontSize * 2));
   ObjectSetInteger(0, objname + "Info2", OBJPROP_CORNER, Corner);
   ObjectSetString(0, objname + "Info2", OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_COLOR, FontColor);
   if (H1_Historical_Projection) {
      ObjectCreate(0, objname + "H1_Historical_Projection", OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, objname + "H1_Historical_Projection", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "H1_Historical_Projection", OBJPROP_WIDTH, ATR_Linethickness);
      ObjectSetInteger(0, objname + "H1_Historical_Projection", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "H1_Historical_Projection", OBJPROP_BACK, ATR_Line_Background);
   }
   ArraySetAsSeries(iATR_D1, true);
   ArraySetAsSeries(iATR_W1, true);
   ArraySetAsSeries(iATR_MN1, true);
   ArraySetAsSeries(iATR_H4, true);
   ArraySetAsSeries(iATR_H1, true);
   ArraySetAsSeries(iATR_M30, true);
   handle_iATR_D1 = iATR(_Symbol, PERIOD_D1, ATR_Period);
   handle_iATR_W1 = iATR(_Symbol, PERIOD_W1, ATR_Period);
   handle_iATR_MN1 = iATR(_Symbol, PERIOD_MN1, ATR_Period);
   handle_iATR_H4 = iATR(_Symbol, PERIOD_H4, ATR_Period);
   handle_iATR_H1 = iATR(_Symbol, PERIOD_H1, ATR_Period);
   handle_iATR_M30 = iATR(_Symbol, PERIOD_M30, ATR_Period);
   // Check if the handles are created successfully
   if (handle_iATR_D1 == INVALID_HANDLE || handle_iATR_W1 == INVALID_HANDLE || handle_iATR_MN1 == INVALID_HANDLE ||
      handle_iATR_H4 == INVALID_HANDLE || handle_iATR_H1 == INVALID_HANDLE || handle_iATR_M30 == INVALID_HANDLE)
   {
      Print("Failed to create handles for iATR indicator");
      Print("handle_iATR_D1: ", handle_iATR_D1);
      Print("handle_iATR_W1: ", handle_iATR_W1);
      Print("handle_iATR_MN1: ", handle_iATR_MN1);
      Print("handle_iATR_H4: ", handle_iATR_H4);
      Print("handle_iATR_H1: ", handle_iATR_H1);
      Print("handle_iATR_M30: ", handle_iATR_M30);
      return INIT_FAILED;
   }
   // Copy buffer values to arrays
   copiedD1 = CopyBuffer(handle_iATR_D1, 0, 0, ATR_Period, iATR_D1);
   copiedW1 = CopyBuffer(handle_iATR_W1, 0, 0, ATR_Period, iATR_W1);
   copiedMN1 = CopyBuffer(handle_iATR_MN1, 0, 0, ATR_Period, iATR_MN1);
   copiedH4 = CopyBuffer(handle_iATR_H4, 0, 0, ATR_Period, iATR_H4);
   copiedH1 = CopyBuffer(handle_iATR_H1, 0, 0, (ATR_Period+1), iATR_H1);
   copiedM30 = CopyBuffer(handle_iATR_M30, 0, 0, ATR_Period, iATR_M30);
   return INIT_SUCCEEDED;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
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
   prevCloseD1 = iClose(_Symbol, PERIOD_D1, 1);
   currentOpenD1 = iClose(_Symbol, PERIOD_D1, 0);
   prevCloseW1 = iClose(_Symbol, PERIOD_W1, 1);
   currentOpenW1 = iClose(_Symbol, PERIOD_W1, 0);
   prevCloseMN1 = iClose(_Symbol, PERIOD_MN1, 1);
   currentOpenMN1 = iClose(_Symbol, PERIOD_MN1, 0);
   prevCloseH4 = iClose(_Symbol, PERIOD_H4, 1);
   currentOpenH4 = iClose(_Symbol, PERIOD_H4, 0);
   prevCloseH1 = iClose(_Symbol, PERIOD_H1, 1);
   currentOpenH1 = iClose(_Symbol, PERIOD_H1, 0);
   prevCloseH1Historical = iClose(_Symbol, PERIOD_H1, 2);
   currentOpenH1Historical = iClose(_Symbol, PERIOD_H1, 1);
   // Calculate the number of bars to be processed
   int limit = rates_total - prev_calculated;
   // If there are no new bars, return
   if (limit <= 0)
      return 0;
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
      avgH1_Historical = iATR_H1[1];
      avgM30 = iATR_M30[0];
   }
   // Initialize vars
   double atrLevelAboveD1prevClose = 0.0;
   double atrLevelBelowD1prevClose = 0.0;
   double atrLevelAboveD1currentOpen = 0.0;
   double atrLevelBelowD1currentOpen = 0.0;
   double atrLevelAboveW1prevClose = 0.0;
   double atrLevelBelowW1prevClose = 0.0;
   double atrLevelAboveW1currentOpen = 0.0;
   double atrLevelBelowW1currentOpen = 0.0;
   double atrLevelAboveMN1prevClose = 0.0;
   double atrLevelBelowMN1prevClose = 0.0;
   double atrLevelAboveMN1currentOpen = 0.0;
   double atrLevelBelowMN1currentOpen = 0.0;
   double atrLevelAboveH4prevClose = 0.0;
   double atrLevelBelowH4prevClose = 0.0;
   double atrLevelAboveH4currentOpen = 0.0;
   double atrLevelBelowH4currentOpen = 0.0;
   double atrLevelAboveH1prevClose = 0.0;
   double atrLevelBelowH1prevClose = 0.0;
   double atrLevelAboveH1prevCloseHistorical = 0.0;
   double atrLevelBelowH1prevCloseHistorical = 0.0;
   double atrLevelAboveH1currentOpen = 0.0;
   double atrLevelBelowH1currentOpen = 0.0;
   double atrLevelAboveH1currentOpenHistorical = 0.0;
   double atrLevelBelowH1currentOpenHistorical = 0.0;
   datetime endTime = time[rates_total - 1];
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
      datetime startTimeW1 = iTime(_Symbol, PERIOD_W1, 3);
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
         ObjectSetInteger(0, objname + "LineTopH1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomH1_PrevClose", OBJ_TREND, 0, startTimeH1, atrLevelBelowH1prevClose, endTime, atrLevelBelowH1prevClose);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomH1_PrevClose", OBJPROP_BACK, ATR_Line_Background);
      }
      if (UseCurrentOpen) {
         atrLevelAboveH1currentOpen = currentOpenH1 + avgH1;
         atrLevelBelowH1currentOpen = currentOpenH1 - avgH1;
         ObjectCreate(0, objname + "LineTopH1_CurrentOpen", OBJ_TREND, 0, startTimeH1, atrLevelAboveH1currentOpen, endTime, atrLevelAboveH1currentOpen);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineTopH1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "LineBottomH1_CurrentOpen", OBJ_TREND, 0, startTimeH1, atrLevelBelowH1currentOpen, endTime, atrLevelBelowH1currentOpen);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "LineBottomH1_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
      }
      if (H1_Historical_Projection) {
   //   Print (DoubleToString(avgH1_Historical,8));
         datetime startTimeH1Historical = iTime(_Symbol, PERIOD_H1, 13);
         if (UsePrevClose) {
            atrLevelAboveH1prevCloseHistorical = prevCloseH1Historical + avgH1_Historical;
            atrLevelBelowH1prevCloseHistorical = prevCloseH1Historical - avgH1_Historical;
            ObjectCreate(0, objname + "LineTopH1Historical_PrevClose", OBJ_TREND, 0, startTimeH1Historical, atrLevelAboveH1prevCloseHistorical, endTime, atrLevelAboveH1prevCloseHistorical);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineTopH1Historical_PrevClose", OBJPROP_BACK, ATR_Line_Background);
            ObjectCreate(0, objname + "LineBottomH1Historical_PrevClose", OBJ_TREND, 0, startTimeH1Historical, atrLevelBelowH1prevCloseHistorical, endTime, atrLevelBelowH1prevCloseHistorical);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_PrevClose", OBJPROP_BACK, ATR_Line_Background);
         }
         if (UseCurrentOpen) {
            atrLevelAboveH1currentOpenHistorical = currentOpenH1Historical + avgH1_Historical;
            atrLevelBelowH1currentOpenHistorical = currentOpenH1Historical - avgH1_Historical;
            ObjectCreate(0, objname + "LineTopH1Historical_CurrentOpen", OBJ_TREND, 0, startTimeH1Historical, atrLevelAboveH1currentOpenHistorical, endTime, atrLevelAboveH1currentOpenHistorical);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineTopH1Historical_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
            ObjectCreate(0, objname + "LineBottomH1Historical_CurrentOpen", OBJ_TREND, 0, startTimeH1Historical, atrLevelBelowH1currentOpenHistorical, endTime, atrLevelBelowH1currentOpenHistorical);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen", OBJPROP_STYLE, ATR_linestyle);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen", OBJPROP_WIDTH, ATR_Linethickness);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen", OBJPROP_COLOR, ATR_Line_Color);
            ObjectSetInteger(0, objname + "LineBottomH1Historical_CurrentOpen", OBJPROP_BACK, ATR_Line_Background);
         }
}
   }
   double M30info = 0;
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
   if (copiedH1 != (ATR_Period + 1))
      H1info = copiedH1;
   if (copiedM30 != ATR_Period)
      M30info = copiedM30;
    if (copiedD1 == ATR_Period)
      D1info = avgD1;
   if (copiedW1 == ATR_Period)
      W1info = avgW1;
   if (copiedMN1 == ATR_Period)
      MN1info = avgMN1;
   if (copiedH4 == ATR_Period)
      H4info = avgH4;
   if (copiedH1 == (ATR_Period + 1))
      H1info = avgH1;
   if (copiedM30 == ATR_Period)
      M30info = avgM30;
   string infoText1 = "ATR | M30: " + DoubleToString(M30info, 3) + " H1: " + DoubleToString(H1info, 3) + " H4: " + DoubleToString(H4info, 3);
   string infoText2 = "ATR | D1: " + DoubleToString(D1info, 3) + " W1: " + DoubleToString(W1info, 3) + " MN1: " + DoubleToString(MN1info, 3);
   ObjectSetString(0, objname + "Info1", OBJPROP_TEXT, infoText1);
   ObjectSetString(0, objname + "Info2", OBJPROP_TEXT, infoText2);
   return rates_total;
}
