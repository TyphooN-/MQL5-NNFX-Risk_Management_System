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
#ifdef __MQL5__
    input group  "[ATR/PERIOD SETTINGS]"; 
#else
    #ifdef __MQL4__
        input string group1 = "[ATR/PERIOD SETTINGS]";
    #endif
#endif
input int    ATR_Period                    = 14;
input bool   M15_ATR_Projections           = true;
input bool   H1_ATR_Projections            = true;
input bool   H4_ATR_Projections            = true;
input bool   D1_ATR_Projections            = true;
input bool   W1_ATR_Projections            = true;
input bool   MN1_ATR_Projections           = true;
#ifdef __MQL5__
    input group  "[LINE SETTINGS]"; 
#else
    #ifdef __MQL4__
        input string group2 =  "[LINE SETTINGS]";
    #endif
#endif
input ENUM_LINE_STYLE ATR_linestyle        = STYLE_DOT;
input int    ATR_Line_Thickness             = 2;
input color  ATR_Line_Color                = clrYellow;
input bool   ATR_Line_Background           = true;
#ifdef __MQL5__
    input group  "[INFO TEXT SETTINGS]";
#else
    #ifdef __MQL4__
        input string group3 =  "[INFO TEXT SETTINGS]";
    #endif
#endif
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
double avgD1, avgW1, avgH4, avgH1, avgMN1, avgM15;
double currentOpenD1 = 0;
double currentOpenW1 = 0;
double currentOpenMN1 = 0;
double currentOpenH4 = 0;
double currentOpenH1 = 0;
double currentOpenM15 = 0;
int lastCheckedCandle = -1;
double prevBidPrice = 0.0;
double prevAskPrice = 0.0;
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0, iATR_D1, INDICATOR_DATA);
   SetIndexBuffer(1, iATR_W1, INDICATOR_DATA);
   SetIndexBuffer(2, iATR_MN1, INDICATOR_DATA);
   SetIndexBuffer(3, iATR_H4, INDICATOR_DATA);
   SetIndexBuffer(4, iATR_H1, INDICATOR_DATA);
   SetIndexBuffer(5, iATR_M15, INDICATOR_DATA);
#ifdef __MQL5__
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
#endif
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
}
void UpdateATRData()
{
#ifdef __MQL5__
   copiedD1 = CopyBuffer(handle_iATR_D1, 0, 0, ATR_Period, iATR_D1);
   copiedW1 = CopyBuffer(handle_iATR_W1, 0, 0, ATR_Period, iATR_W1);
   copiedMN1 = CopyBuffer(handle_iATR_MN1, 0, 0, ATR_Period, iATR_MN1);
   copiedH4 = CopyBuffer(handle_iATR_H4, 0, 0, ATR_Period, iATR_H4);
   copiedM15 = CopyBuffer(handle_iATR_M15, 0, 0, ATR_Period, iATR_M15);
   copiedH1 = CopyBuffer(handle_iATR_H1, 0, 0, ATR_Period, iATR_H1);
#else
   #ifdef __MQL4__
   copiedD1=0;
   for(int i=0; i<ATR_Period; i++)
   {
     iATR_D1[i] = iATR(_Symbol, PERIOD_D1, ATR_Period, i);
      copiedD1++;
   }
   copiedW1=0;
   for(int i=0; i<ATR_Period; i++)
   {
      iATR_W1[i] = iATR(_Symbol, PERIOD_W1, ATR_Period, i);
      copiedW1++;
   }
   copiedMN1=0;
   for(int i=0; i<ATR_Period; i++)
   {
      iATR_MN1[i] = iATR(_Symbol, PERIOD_MN1, ATR_Period, i);
      copiedMN1++;
   }
   copiedH4=0;
   for(int i=0; i<ATR_Period; i++)
   {
      iATR_H4[i] = iATR(_Symbol, PERIOD_H4, ATR_Period, i);
      copiedH4++;
   }
   copiedM15=0;
   for(int i=0; i<ATR_Period; i++)
   {
      iATR_M15[i] = iATR(_Symbol, PERIOD_M15, ATR_Period, i);
      copiedM15++;
   }
   copiedH1=0;
   for(int i=0; i<ATR_Period; i++)
   {
      iATR_H1[i] = iATR(_Symbol, PERIOD_H1, ATR_Period, i);
      copiedH1++;
   }
   #endif
#endif
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
   datetime currentTradeServerTime = 0;
#ifdef __MQL5__
    currentTradeServerTime = TimeTradeServer();
#else
    #ifdef __MQL4__
        currentTradeServerTime = TimeCurrent();
    #endif
#endif
    // Check if a new 15-minute interval
    if (IsNewM15Interval(currentTradeServerTime, prevTradeServerTime))
    {
      UpdateATRData();
      UpdateCandlestickData();
      prevTradeServerTime = currentTradeServerTime;
    }
    // Get the current bid and ask prices
    double currentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    // Check if both bid and ask prices have changed from the previous tick
    if (currentBidPrice == prevBidPrice && currentAskPrice == prevAskPrice)
    {
      // If both bid and ask prices are the same as the previous tick, return prev_calculated
      return prev_calculated;
   }
    // Update the previous bid and ask prices with the current prices
    prevBidPrice = currentBidPrice;
    prevAskPrice = currentAskPrice;
   // Calculate the number of bars to be processed
   int limit = rates_total - prev_calculated;
   // If there are no new bars, return (must return prev_calculated, not 0, to avoid forced full recalc)
   if (limit <= 0)
      return prev_calculated;
   // Check if a new candlestick has formed
   if (lastCheckedCandle != rates_total - 1) {
      // Update the last checked candle index
      lastCheckedCandle = rates_total - 1;
      UpdateATRData();
      UpdateCandlestickData();
   }
   int currentbar = rates_total - 1;
   // Check if the current bar is within the valid range of the arrays
   if (currentbar >= ATR_Period)
   {
   // Calculate the average true range (ATR) for the specified period
      avgD1 = iATR_D1[0];
      avgW1 = iATR_W1[0];
      avgMN1 = iATR_MN1[0];
      avgH4 = iATR_H4[0];
      avgH1 = iATR_H1[0];
      avgM15 = iATR_M15[0];
   }
   double D1info = (copiedD1 == ATR_Period) ? avgD1 : copiedD1;
   double W1info = (copiedW1 == ATR_Period) ? avgW1 : copiedW1;
   double MN1info = (copiedMN1 == ATR_Period) ? avgMN1 : copiedMN1;
   double H4info = (copiedH4 == ATR_Period) ? avgH4 : copiedH4;
   double H1info = (copiedH1 == ATR_Period) ? avgH1 : copiedH1;
   double M15info = (copiedM15 == ATR_Period) ? avgM15 : copiedM15;
   bool IsM15AboveH1 = (avgM15 >= avgH1);
   bool IsM15AboveH4 = (avgM15 >= avgH4);
   bool IsH1AboveH4 = (avgH1 >= avgH4);
   bool IsH4AboveD1 = (avgH4 >= avgD1);
   // Change InfoText1 font color if any lower timeframe ATR values are higher than higher timeframe ATR values
   color FontColor1 = (IsM15AboveH1 && IsM15AboveH4 && IsH1AboveH4 && IsH4AboveD1) ? clrMagenta : FontColor;
   bool IsD1AboveW1 = (avgD1 > avgW1);
   bool IsD1AboveMN1 = (avgD1 > avgMN1);
   bool IsW1AboveMN1 = (avgW1 > avgMN1);
   color FontColor2 = (IsD1AboveW1 && IsD1AboveMN1 && IsW1AboveMN1) ? clrMagenta : FontColor;
   string infoText1 = "ATR| M15: " + DoubleToString(M15info, ATRInfoDecimals) + " H1: " + DoubleToString(H1info, ATRInfoDecimals) + " H4: " + DoubleToString(H4info, ATRInfoDecimals);
   string infoText2 = "ATR| D1: " + DoubleToString(D1info, ATRInfoDecimals) + " W1: " + DoubleToString(W1info, ATRInfoDecimals) + " MN1: " + DoubleToString(MN1info, ATRInfoDecimals);
   static bool infoObjectsCreated = false;
   if (!infoObjectsCreated)
   {
      infoObjectsCreated = true;
      ObjectCreate(0, objname + "Info1", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname + "Info1", OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objname + "Info1", OBJPROP_YDISTANCE, VertPos);
      ObjectSetInteger(0, objname + "Info1", OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname + "Info1", OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname + "Info1", OBJPROP_FONTSIZE, FontSize);
      ObjectCreate(0, objname + "Info2", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname + "Info2", OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objname + "Info2", OBJPROP_YDISTANCE, VertPos + 13);
      ObjectSetInteger(0, objname + "Info2", OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname + "Info2", OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname + "Info2", OBJPROP_FONTSIZE, FontSize);
   }
   // Only update text/color when changed
   static string prevInfoText1, prevInfoText2;
   static color prevFontColor1 = clrNONE, prevFontColor2 = clrNONE;
   if (infoText1 != prevInfoText1) { ObjectSetString(0, objname + "Info1", OBJPROP_TEXT, infoText1); prevInfoText1 = infoText1; }
   if (FontColor1 != prevFontColor1) { ObjectSetInteger(0, objname + "Info1", OBJPROP_COLOR, FontColor1); prevFontColor1 = FontColor1; }
   if (infoText2 != prevInfoText2) { ObjectSetString(0, objname + "Info2", OBJPROP_TEXT, infoText2); prevInfoText2 = infoText2; }
   if (FontColor2 != prevFontColor2) { ObjectSetInteger(0, objname + "Info2", OBJPROP_COLOR, FontColor2); prevFontColor2 = FontColor2; }
#ifdef __MQL5__
   static bool dataReady = false;
   if (!dataReady)
   {
      if (BarsCalculated(handle_iATR_D1) <= 0 || BarsCalculated(handle_iATR_MN1) <= 0)
      {
         UpdateATRData();
         UpdateCandlestickData();
         return prev_calculated;
      }
      dataReady = true;
   }
#endif
   #ifdef __MQL5__
   datetime endTime = time[rates_total - 1];
#else
    #ifdef __MQL4__
    datetime endTime = time[0];
    #endif
#endif
   if (D1_ATR_Projections && _Period <= PERIOD_W1 && _Period != PERIOD_MN1)
   {
      datetime startTimeD1 = iTime(_Symbol, PERIOD_D1, 7);
      double ATRLevelAboveD1 = currentOpenD1 + avgD1;
      double ATRLevelBelowD1 = currentOpenD1 - avgD1;
      DrawHorizontalLine(ATRLevelAboveD1, objname + "High D1", startTimeD1, endTime);
      DrawHorizontalLine(ATRLevelBelowD1, objname + "Low D1", startTimeD1, endTime);
   }
   if (W1_ATR_Projections)
   {
      datetime startTimeW1 = iTime(_Symbol, PERIOD_W1, 4);
      double ATRLevelAboveW1 = currentOpenW1 + avgW1;
      double ATRLevelBelowW1 = currentOpenW1 - avgW1;
      DrawHorizontalLine(ATRLevelAboveW1, objname + "High W1", startTimeW1, endTime);
      DrawHorizontalLine(ATRLevelBelowW1, objname + "Low W1", startTimeW1, endTime);
   }
   if (MN1_ATR_Projections)
   {
      datetime startTimeMN1 = iTime(_Symbol, PERIOD_MN1, 2);
      double ATRLevelAboveMN1 = currentOpenMN1 + avgMN1;
      double ATRLevelBelowMN1 = currentOpenMN1 - avgMN1;
      DrawHorizontalLine(ATRLevelAboveMN1, objname + "High MN1", startTimeMN1, endTime);
      DrawHorizontalLine(ATRLevelBelowMN1, objname + "Low MN1", startTimeMN1, endTime);
   }
   if (H4_ATR_Projections && _Period <= PERIOD_D1 && _Period != PERIOD_MN1)
   {
      datetime startTimeH4 = iTime(_Symbol, PERIOD_H4, 11);
      double ATRLevelAboveH4 = currentOpenH4 + avgH4;
      double ATRLevelBelowH4 = currentOpenH4 - avgH4;
      DrawHorizontalLine(ATRLevelAboveH4, objname + "High H4", startTimeH4, endTime);
      DrawHorizontalLine(ATRLevelBelowH4, objname + "Low H4", startTimeH4, endTime);
   }
   if (H1_ATR_Projections && _Period <= PERIOD_H4 && _Period != PERIOD_MN1)
   {
      datetime startTimeH1 = iTime(_Symbol, PERIOD_H1, 12);
      double ATRLevelAboveH1 = currentOpenH1 + avgH1;
      double ATRLevelBelowH1 = currentOpenH1 - avgH1;
      DrawHorizontalLine(ATRLevelAboveH1, objname + "High H1", startTimeH1, endTime);
      DrawHorizontalLine(ATRLevelBelowH1, objname + "Low H1", startTimeH1, endTime);
   }
   if (M15_ATR_Projections && _Period <= PERIOD_H1 && _Period != PERIOD_MN1)
   {
      datetime startTimeM15 = iTime(_Symbol, PERIOD_M15, 7);
      double ATRLevelAboveM15 = currentOpenM15 + avgM15;
      double ATRLevelBelowM15 = currentOpenM15 - avgM15;
      DrawHorizontalLine(ATRLevelAboveM15, objname + "High M15", startTimeM15, endTime);
      DrawHorizontalLine(ATRLevelBelowM15, objname + "Low M15", startTimeM15, endTime);
   }
   return rates_total;
}
void DrawHorizontalLine(double price, string label, datetime StartTime, datetime EndTime)
{
   if(ObjectFind(0, label) != -1)
   {
      ObjectMove(0, label, 0, StartTime, price);
      ObjectMove(0, label, 1, EndTime, price);
      return;
   }
   ObjectCreate(0, label, OBJ_TREND, 0, StartTime, price, EndTime, price);
   ObjectSetInteger(0, label, OBJPROP_STYLE, ATR_linestyle);
   ObjectSetInteger(0, label, OBJPROP_WIDTH, ATR_Line_Thickness);
   ObjectSetInteger(0, label, OBJPROP_COLOR, ATR_Line_Color);
   ObjectSetInteger(0, label, OBJPROP_BACK, ATR_Line_Background);
}
bool IsNewM15Interval(const datetime& currentTime, const datetime& prevTime)
{
    MqlDateTime currentMqlTime, prevMqlTime;
    TimeToStruct(currentTime, currentMqlTime);
    TimeToStruct(prevTime, prevMqlTime);
    // Check if the minutes have changed
    if (currentMqlTime.min != prevMqlTime.min)
    {
        // Check if the current time is at a a 15 minute interval
        if (currentMqlTime.min % 15 == 0)
        {
#ifdef __MQL4__
                ObjectsDeleteAll(0, objname);
#endif
                return true;
        }
    }
    return false;
}

