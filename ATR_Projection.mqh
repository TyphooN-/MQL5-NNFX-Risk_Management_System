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
input bool   H1_Historical_Projection      = false;
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
input bool   ATR_Line_Background           = false;
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
   ObjectSetInteger(0, objname + "Info1", OBJPROP_ZORDER, 1);
   ObjectCreate(0, objname + "Info2", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_YDISTANCE, VertPos + 13);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_CORNER, Corner);
   ObjectSetString(0, objname + "Info2", OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_COLOR, FontColor);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_ZORDER, 1);

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
   currentOpenH1Historical1 = iOpen(_Symbol, PERIOD_H1, 1);
   currentOpenH1Historical2 = iOpen(_Symbol, PERIOD_H1, 2);
}
void UpdateATRData()
{
#ifdef __MQL5__
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
    if (H1_Historical_Projection == true)
    {
        for(int i=0; i<ATR_Period+2; i++)
            iATR_H1[i] = iATR(_Symbol, PERIOD_H1, ATR_Period+2, i);

        copiedH1++;
    }
    
    if (H1_Historical_Projection == false)
    {
        for(int i=0; i<ATR_Period; i++)
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
   bool IsM15AboveH1 = (copiedM15 > copiedH1);
   bool IsM15AboveH4 = (copiedM15 > copiedH4);
   bool IsH1AboveH4 = (copiedH1 > copiedH4);
   bool IsH4AboveD1 = (copiedH4 > copiedD1);
   // Change InfoText1 font color if any lower timeframe ATR values are higher than higher timeframe ATR values
   color FontColor1 = FontColor;
   if (IsM15AboveH1 && IsM15AboveH4 && IsH1AboveH4 && IsH4AboveD1)
   {
       FontColor1 = clrMagenta;
   }
   else
   {
       FontColor1 = FontColor;
   }
   bool IsD1AboveW1 = (copiedD1 > copiedW1);
   bool IsD1AboveMN1 = (copiedD1 > copiedMN1);
   bool IsW1AboveMN1 = (copiedW1 > copiedMN1);
   // Change InfoText2 font color if any lower timeframe ATR values are higher than higher timeframe ATR values
   color FontColor2 = FontColor;
   if (IsD1AboveW1 && IsD1AboveMN1 && IsW1AboveMN1)
   {
       FontColor2 = clrMagenta;
   }
   else
   {
       FontColor2 = FontColor;
   }
   string infoText1 = "ATR| M15: " + DoubleToString(M15info, ATRInfoDecimals) + " H1: " + DoubleToString(H1info, ATRInfoDecimals) + " H4: " + DoubleToString(H4info, ATRInfoDecimals);
   string infoText2 = "ATR| D1: " + DoubleToString(D1info, ATRInfoDecimals) + " W1: " + DoubleToString(W1info, ATRInfoDecimals) + " MN1: " + DoubleToString(MN1info, ATRInfoDecimals);
   ObjectSetString(0, objname + "Info1", OBJPROP_TEXT, infoText1);
   ObjectSetInteger(0, objname + "Info1", OBJPROP_COLOR, FontColor1);
   ObjectSetString(0, objname + "Info2", OBJPROP_TEXT, infoText2);
   ObjectSetInteger(0, objname + "Info2", OBJPROP_COLOR, FontColor2);
   static int waitCount = 2;
   if ( waitCount > 0 )
   {
      UpdateATRData();
      UpdateCandlestickData();
      waitCount--;
      return ( prev_calculated );
   }
   //PrintFormat( "ATR and candlestick Data is now available" );
   // Initialize vars
   double ATRLevelAboveD1 = 0;
   double ATRLevelBelowD1 = 0;
   double ATRLevelAboveW1 = 0;
   double ATRLevelBelowW1 = 0;
   double ATRLevelAboveMN1 = 0;
   double ATRLevelBelowMN1 = 0;
   double ATRLevelAboveH4 = 0;
   double ATRLevelBelowH4 = 0;
   double ATRLevelAboveH1 = 0;
   double ATRLevelBelowH1 = 0;
   double ATRLevelAboveH1Historical1 = 0;
   double ATRLevelBelowH1Historical1 = 0;
   double ATRLevelAboveH1Historical2 = 0;
   double ATRLevelBelowH1Historical2 = 0;
   double ATRLevelAboveM15 = 0;
   double ATRLevelBelowM15 = 0;
   
   #ifdef __MQL5__
   datetime endTime = time[rates_total - 1];
#else
    #ifdef __MQL4__
    datetime endTime = time[0];
    #endif
#endif

   if (D1_ATR_Projections && _Period <= PERIOD_W1)
   {
      datetime startTimeD1 = iTime(_Symbol, PERIOD_D1, 7);
      ATRLevelAboveD1 = currentOpenD1 + avgD1;
      ATRLevelBelowD1 = currentOpenD1 - avgD1;
      GlobalVariableSet("GlobalATRLevelAboveD1", ATRLevelAboveD1);
      GlobalVariableSet("GlobalATRLevelBelowD1", ATRLevelBelowD1);
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
      ATRLevelAboveW1 = currentOpenW1 + avgW1;
      ATRLevelBelowW1 = currentOpenW1 - avgW1;
      GlobalVariableSet("GlobalATRLevelAboveW1", ATRLevelAboveW1);
      GlobalVariableSet("GlobalATRLevelBelowW1", ATRLevelBelowW1);
      ObjectCreate(0, objname + "High W1", OBJ_TREND, 0, startTimeW1, ATRLevelAboveW1, endTime, ATRLevelAboveW1);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High W1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low W1", OBJ_TREND, 0, startTimeW1, ATRLevelBelowW1, endTime, ATRLevelBelowW1);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low W1", OBJPROP_BACK, ATR_Line_Background);
   }
   if (MN1_ATR_Projections)
   {
      datetime startTimeMN1 = iTime(_Symbol, PERIOD_MN1, 2);
      ATRLevelAboveMN1 = currentOpenMN1 + avgMN1;
      ATRLevelBelowMN1 = currentOpenMN1 - avgMN1;
      GlobalVariableSet("GlobalATRLevelAboveMN1", ATRLevelAboveMN1);
      GlobalVariableSet("GlobalATRLevelBelowMN1", ATRLevelBelowMN1);
      ObjectCreate(0, objname + "High MN1", OBJ_TREND, 0, startTimeMN1, ATRLevelAboveMN1, endTime, ATRLevelAboveMN1);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High MN1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low MN1", OBJ_TREND, 0, startTimeMN1, ATRLevelBelowMN1, endTime, ATRLevelBelowMN1);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low MN1", OBJPROP_BACK, ATR_Line_Background);
   }
   if (H4_ATR_Projections && _Period <= PERIOD_D1)
   {
      datetime startTimeH4 = iTime(_Symbol, PERIOD_H4, 11);
      ATRLevelAboveH4 = currentOpenH4 + avgH4;
      ATRLevelBelowH4 = currentOpenH4 - avgH4;
      GlobalVariableSet("GlobalATRLevelAboveH4", ATRLevelAboveH4);
      GlobalVariableSet("GlobalATRLevelBelowH4", ATRLevelBelowH4);
      ObjectCreate(0, objname + "High H4", OBJ_TREND, 0, startTimeH4, ATRLevelAboveH4, endTime, ATRLevelAboveH4);
      ObjectSetInteger(0, objname + "High H4", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High H4", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High H4", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High H4", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low H4", OBJ_TREND, 0, startTimeH4, ATRLevelBelowH4, endTime, ATRLevelBelowH4);
      ObjectSetInteger(0, objname + "Low H4", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low H4", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low H4", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low H4", OBJPROP_BACK, ATR_Line_Background);
   }
   if (H1_ATR_Projections && _Period <= PERIOD_H4)
   {
      datetime startTimeH1 = iTime(_Symbol, PERIOD_H1, 12);
      ATRLevelAboveH1 = currentOpenH1 + avgH1;
      ATRLevelBelowH1 = currentOpenH1 - avgH1;
      GlobalVariableSet("GlobalATRLevelAboveH1", ATRLevelAboveH1);
      GlobalVariableSet("GlobalATRLevelBelowH1", ATRLevelBelowH1);
      ObjectCreate(0, objname + "High H1", OBJ_TREND, 0, startTimeH1, ATRLevelAboveH1, endTime, ATRLevelAboveH1);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High H1", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low H1", OBJ_TREND, 0, startTimeH1, ATRLevelBelowH1, endTime, ATRLevelBelowH1);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "Low H1", OBJPROP_BACK, ATR_Line_Background);
      if (H1_Historical_Projection)
      {
         datetime startTimeH1Historical1 = iTime(_Symbol, PERIOD_H1, 14);
         datetime startTimeH1Historical2 = iTime(_Symbol, PERIOD_H1, 17);
         ATRLevelAboveH1Historical1 = currentOpenH1Historical1 + avgH1_Historical1;
         ATRLevelBelowH1Historical1 = currentOpenH1Historical1 - avgH1_Historical1;
         ObjectCreate(0, objname + "High H1 Historical 1", OBJ_TREND, 0, startTimeH1Historical1, ATRLevelAboveH1Historical1, endTime, ATRLevelAboveH1Historical1);
         ObjectSetInteger(0, objname + "High H1 Historical 1", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "High H1 Historical 1", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "High H1 Historical 1", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "High H1_Historical 1", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "Low H1 Historical 1", OBJ_TREND, 0, startTimeH1Historical1, ATRLevelBelowH1Historical1, endTime, ATRLevelBelowH1Historical1);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "Low H1 Historical 1", OBJPROP_BACK, ATR_Line_Background);
         ATRLevelAboveH1Historical2 = currentOpenH1Historical2 + avgH1_Historical2;
         ATRLevelBelowH1Historical2 = currentOpenH1Historical2 - avgH1_Historical2;
         ObjectCreate(0, objname + "High H1 Historical 2", OBJ_TREND, 0, startTimeH1Historical2, ATRLevelAboveH1Historical2, endTime, ATRLevelAboveH1Historical2);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "High H1 Historical 2", OBJPROP_BACK, ATR_Line_Background);
         ObjectCreate(0, objname + "Low H1 Historical 2", OBJ_TREND, 0, startTimeH1Historical2, ATRLevelBelowH1Historical2, endTime, ATRLevelBelowH1Historical2);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_STYLE, ATR_linestyle);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_WIDTH, ATR_Line_Thickness);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_COLOR, ATR_Line_Color);
         ObjectSetInteger(0, objname + "Low H1 Historical 2", OBJPROP_BACK, ATR_Line_Background);
   }
   }
   if (M15_ATR_Projections && _Period <= PERIOD_H1)
   {
      datetime startTimeM15 = iTime(_Symbol, PERIOD_M15, 7);
      ATRLevelAboveM15 = currentOpenM15 + avgM15;
      ATRLevelBelowM15 = currentOpenM15 - avgM15;
      GlobalVariableSet("GlobalATRLevelAboveM15", ATRLevelAboveM15);
      GlobalVariableSet("GlobalATRLevelBelowM15", ATRLevelAboveM15);
      ObjectCreate(0, objname + "High M15", OBJ_TREND, 0, startTimeM15, ATRLevelAboveM15, endTime, ATRLevelAboveM15);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_STYLE, ATR_linestyle);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_WIDTH, ATR_Line_Thickness);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_COLOR, ATR_Line_Color);
      ObjectSetInteger(0, objname + "High M15", OBJPROP_BACK, ATR_Line_Background);
      ObjectCreate(0, objname + "Low M15", OBJ_TREND, 0, startTimeM15, ATRLevelBelowM15, endTime, ATRLevelBelowM15);
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
#ifdef __MQL4__
                ObjectsDeleteAll(0, objname);

#endif

                return true;
        }
    }
    return false;
}
