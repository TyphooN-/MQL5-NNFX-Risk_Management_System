/**=             MTF_MA.mq5  (TyphooN's Multi Timeframe MA Bull/Bear Power Indicator)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.info)
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
#property link      "https://www.marketwizardry.info"
#property version   "1.072"
#property indicator_chart_window
#property indicator_buffers 41
#property indicator_plots   6
#property indicator_label1  "H1 200SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrTomato
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "H4 200SMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMagenta
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "D1 200SMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "W1 200SMA"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrMagenta
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label5  "W1 100SMA"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
#property indicator_label6  "MN1 100SMA"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrMagenta
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
// Input variables
input group  "[INFO TEXT SETTINGS]";
input string FontName                      = "Courier New";
input int    FontSize                      = 8;
const ENUM_BASE_CORNER Corner              = CORNER_RIGHT_UPPER;
input int    HorizPos                      = 310;
input int    VertPos                       = 130;
bool W1_Empty_Warning = false;
ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE;
// Handles
int HandleM1_200SMA, HandleM1_50SMA, HandleM1_20SMA, HandleM1_10SMA, HandleM5_200SMA, HandleM5_50SMA, HandleM5_20SMA, HandleM5_10SMA, HandleM15_200SMA, HandleM15_50SMA, HandleM15_20SMA;
int HandleM15_10SMA, HandleM30_200SMA, HandleM30_50SMA, HandleM30_20SMA, HandleM30_10SMA, HandleH1_200SMA, HandleH1_50SMA, HandleH1_20SMA, HandleH1_10SMA, HandleH4_200SMA;
int HandleH4_50SMA, HandleH4_20SMA, HandleH4_10SMA, HandleD1_200SMA, HandleD1_50SMA, HandleD1_20SMA, HandleD1_10SMA, HandleW1_200SMA, HandleW1_50SMA, HandleW1_20SMA, HandleW1_10SMA;
int HandleM1_100SMA, HandleM5_100SMA, HandleM15_100SMA, HandleM30_100SMA, HandleH1_100SMA, HandleH4_100SMA, HandleD1_100SMA, HandleW1_100SMA, HandleMN1_100SMA;
// Buffers
double MABufferM1_200SMA[], MABufferM1_50SMA[], MABufferM1_20SMA[], MABufferM1_10SMA[], MABufferM5_200SMA[], MABufferM5_50SMA[], MABufferM5_20SMA[], MABufferM5_10SMA[], MABufferM15_200SMA[], MABufferM15_50SMA[], MABufferM15_20SMA[];
double MABufferM15_10SMA[], MABufferM30_200SMA[], MABufferM30_50SMA[], MABufferM30_20SMA[], MABufferM30_10SMA[], MABufferH1_200SMA[], MABufferH1_50SMA[], MABufferH1_20SMA[], MABufferH1_10SMA[], MABufferH4_200SMA[], MABufferH4_50SMA[];
double MABufferH4_20SMA[], MABufferH4_10SMA[], MABufferD1_200SMA[], MABufferD1_50SMA[], MABufferD1_20SMA[], MABufferD1_10SMA[], MABufferW1_200SMA[], MABufferW1_50SMA[], MABufferW1_20SMA[], MABufferW1_10SMA[];
double MABufferM1_100SMA[], MABufferM5_100SMA[], MABufferM15_100SMA[], MABufferM30_100SMA[], MABufferH1_100SMA[], MABufferH4_100SMA[], MABufferD1_100SMA[], MABufferW1_100SMA[], MABufferMN1_100SMA[];
int BullPowerLTF = 0;
int BullPowerMTF = 0;
int BullPowerHTF = 0;
int BearPowerLTF = 0;
int BearPowerMTF = 0;
int BearPowerHTF = 0;
double TotalBearPower;
double TotalBullPower;
bool isTimerSet = false;
int lastCheckedCandle = -1;
double prevBidPrice = 0.0;
double prevAskPrice = 0.0;
string objname = "MTF_MA_";
int OnInit()
{
   SetIndexBuffer(0, MABufferH1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(1, MABufferH4_200SMA, INDICATOR_DATA);
   SetIndexBuffer(2, MABufferD1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(3, MABufferW1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(4, MABufferW1_100SMA, INDICATOR_DATA);
   SetIndexBuffer(5, MABufferMN1_100SMA, INDICATOR_DATA);
   SetIndexBuffer(6, MABufferM1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(7, MABufferM5_200SMA, INDICATOR_DATA);
   SetIndexBuffer(8, MABufferH4_100SMA, INDICATOR_DATA);
   SetIndexBuffer(9, MABufferD1_100SMA, INDICATOR_DATA);
   SetIndexBuffer(10, MABufferM15_200SMA, INDICATOR_DATA);
   SetIndexBuffer(11, MABufferM30_200SMA, INDICATOR_DATA);
   SetIndexBuffer(12, MABufferM1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(13, MABufferM5_50SMA, INDICATOR_DATA);
   SetIndexBuffer(14, MABufferM15_50SMA, INDICATOR_DATA);
   SetIndexBuffer(15, MABufferM30_50SMA, INDICATOR_DATA);
   SetIndexBuffer(16, MABufferH1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(17, MABufferH4_50SMA, INDICATOR_DATA);
   SetIndexBuffer(18, MABufferD1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(19, MABufferW1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(20, MABufferM1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(21, MABufferM5_10SMA, INDICATOR_DATA);
   SetIndexBuffer(22, MABufferM15_10SMA, INDICATOR_DATA);
   SetIndexBuffer(23, MABufferM30_10SMA, INDICATOR_DATA);
   SetIndexBuffer(24, MABufferH1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(25, MABufferH4_10SMA, INDICATOR_DATA);
   SetIndexBuffer(26, MABufferD1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(27, MABufferW1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(28, MABufferM1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(29, MABufferM5_20SMA, INDICATOR_DATA);
   SetIndexBuffer(30, MABufferM15_20SMA, INDICATOR_DATA);
   SetIndexBuffer(31, MABufferM30_20SMA, INDICATOR_DATA);
   SetIndexBuffer(32, MABufferH1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(33, MABufferH4_20SMA, INDICATOR_DATA);
   SetIndexBuffer(34, MABufferD1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(35, MABufferW1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(36, MABufferM1_100SMA, INDICATOR_DATA);
   SetIndexBuffer(37, MABufferM5_100SMA, INDICATOR_DATA);
   SetIndexBuffer(38, MABufferM15_100SMA, INDICATOR_DATA);
   SetIndexBuffer(39, MABufferM30_100SMA, INDICATOR_DATA);
   SetIndexBuffer(40, MABufferH1_100SMA, INDICATOR_DATA);
   return 0;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
}
void UpdateInfoLabel(string timeframe, bool condition, string label)
{
   GlobalVariableSet("PowerCalcComplete", false);
   string objnameInfo = objname + timeframe + label;
   color textColor = condition ? clrLime : clrRed;
   int TotalBearPowerLTF, TotalBullPowerLTF, TotalBearPowerHTF, TotalBullPowerHTF;
   TotalBearPowerLTF = (BearPowerLTF * 5);
   TotalBullPowerLTF = (BullPowerLTF * 5);
   TotalBearPowerHTF = (BearPowerHTF * 5);
   TotalBullPowerHTF = (BullPowerHTF * 5);
   // Check if the color has changed
   if (ObjectGetInteger(0, objnameInfo, OBJPROP_COLOR) != textColor)
   {
      // Decrement the appropriate variable based on the previous color
      if (ObjectGetInteger(0, objnameInfo, OBJPROP_COLOR) == clrLime)
      {
         if (StringFind(timeframe, "M1", 0) != -1 || StringFind(timeframe, "M5", 0) != -1 || StringFind(timeframe, "M15", 0) != -1 || StringFind(timeframe, "M30", 0) != -1) 
         {
            BullPowerLTF--;
         }
         else if (StringFind(timeframe, "H1", 0) != -1 || StringFind(timeframe, "H4", 0) != -1 || StringFind(timeframe, "D1", 0) != -1 || StringFind(timeframe, "W1", 0) != -1)
         {
            BullPowerHTF--;
         }
      }
      else if (ObjectGetInteger(0, objnameInfo, OBJPROP_COLOR) == clrRed)
      {
         if (StringFind(timeframe, "M1", 0) != -1 || StringFind(timeframe, "M5", 0) != -1 || StringFind(timeframe, "M15", 0) != -1 || StringFind(timeframe, "M30", 0) != -1) 
         {
            BearPowerLTF--;
         }
         else if (StringFind(timeframe, "H1", 0) != -1 || StringFind(timeframe, "H4", 0) != -1 || StringFind(timeframe, "D1", 0) != -1 || StringFind(timeframe, "W1", 0) != -1)
         {
            BearPowerHTF--;
         }
      }
      // Update the color and count variables
      ObjectSetInteger(0, objnameInfo, OBJPROP_COLOR, textColor);
      if (condition)
      {
         // Increment the appropriate variable based on the timeframe
         if (StringFind(timeframe, "M1", 0) != -1 || StringFind(timeframe, "M5", 0) != -1 || StringFind(timeframe, "M15", 0) != -1 || StringFind(timeframe, "M30", 0) != -1) 
         {
            BullPowerLTF++;
         }
         else if (StringFind(timeframe, "H1", 0) != -1 || StringFind(timeframe, "H4", 0) != -1 || StringFind(timeframe, "D1", 0) != -1 || StringFind(timeframe, "W1", 0) != -1)
         {
            BullPowerHTF++;
         }
      }
      else
      {
         // Increment the appropriate variable based on the timeframe
         if (StringFind(timeframe, "M1", 0) != -1 || StringFind(timeframe, "M5", 0) != -1 || StringFind(timeframe, "M15", 0) != -1 || StringFind(timeframe, "M30", 0) != -1) 
         {
            BearPowerLTF++;
         }
         else if (StringFind(timeframe, "H1", 0) != -1 || StringFind(timeframe, "H4", 0) != -1 || StringFind(timeframe, "D1", 0) != -1 || StringFind(timeframe, "W1", 0) != -1)
         {
            BearPowerHTF++;
         }
      }
      // Update the colors based on the TotalBullPower and TotalBearPower
      if (TotalBearPowerHTF > TotalBullPowerHTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrRed);
      }
      if (TotalBullPowerHTF > TotalBearPowerHTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrWhite);
      }
      if (TotalBearPowerLTF > TotalBullPowerLTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrRed);
      }
      if (TotalBullPowerLTF > TotalBearPowerLTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrWhite);
      }
      if (TotalBullPowerHTF == TotalBearPowerHTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrWhite);
      }
      if (TotalBullPowerLTF == TotalBearPowerLTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrWhite);
      }
      // Update the total variables
      TotalBearPowerLTF = (BearPowerLTF * 5);
      TotalBullPowerLTF = (BullPowerLTF * 5);
      double TotalScoreLTF = TotalBullPowerLTF + TotalBearPowerLTF;
      TotalBearPowerHTF = (BearPowerHTF * 5);
      TotalBullPowerHTF = (BullPowerHTF * 5);
      double TotalScoreHTF = TotalBullPowerHTF + TotalBearPowerHTF;
      if (TotalBearPowerHTF > TotalBullPowerHTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrRed);
      }
      if (TotalBullPowerHTF > TotalBearPowerHTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrWhite);
      }
      if (TotalBearPowerLTF > TotalBullPowerLTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrRed);
      }
      else if (TotalBullPowerLTF > TotalBearPowerLTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrWhite);
      }
      if (TotalBullPowerHTF == TotalBearPowerHTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrWhite);
      }
      if (TotalBullPowerLTF == TotalBearPowerLTF)
      {
         ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrWhite);
      }
      // Update the labels with the new values
      string BullPowerTextLTF = "LTF Bull Power: " + IntegerToString(TotalBullPowerLTF);
      string BearPowerTextLTF = "LTF Bear Power: " + IntegerToString(TotalBearPowerLTF);
      ObjectSetString(0, objname + "InfoBullPowerLTF", OBJPROP_TEXT, BullPowerTextLTF);
      ObjectSetString(0, objname + "InfoBearPowerLTF", OBJPROP_TEXT, BearPowerTextLTF);
      string BullPowerTextHTF = "HTF Bull Power: " + IntegerToString(TotalBullPowerHTF);
      string BearPowerTextHTF = "HTF Bear Power: " + IntegerToString(TotalBearPowerHTF);
      ObjectSetString(0, objname + "InfoBullPowerHTF", OBJPROP_TEXT, BullPowerTextHTF);
      ObjectSetString(0, objname + "InfoBearPowerHTF", OBJPROP_TEXT, BearPowerTextHTF);
   }
   GlobalVariableSet("GlobalBullPowerLTF", TotalBullPowerLTF);
   GlobalVariableSet("GlobalBearPowerLTF", TotalBearPowerLTF);
   GlobalVariableSet("GlobalBullPowerHTF", TotalBullPowerHTF);
   GlobalVariableSet("GlobalBearPowerHTF", TotalBearPowerHTF);
   GlobalVariableSet("PowerCalcComplete", true);
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
   int start;
   if (prev_calculated == 0)
   {
      start = 0;
   }
   else
   {
      start = prev_calculated - 1;
   }
   static datetime prevTime = TimeTradeServer();
   static bool isTimerStarted = false;
   datetime currentTime = TimeTradeServer();
   if (lastCheckedCandle != rates_total - 1)
   {
    //  Print("New candle has formed, updating MA Data");
      // Update the last checked candle index
      lastCheckedCandle = rates_total - 1;
      UpdateBuffers();
      // Restart the timer
      isTimerStarted = false;
   }
   if (!isTimerStarted && IsNewMinute(currentTime, prevTime))
   {
      isTimerStarted = true;
      //Print("Timer started or restarted");
      isTimerSet = EventSetTimer(60);
      if (!isTimerSet)
      {
         Print("Error setting timer");
      }
   }
   int elapsedSeconds = (int)(currentTime - prevTime);
   if (isTimerStarted && elapsedSeconds >= 60)
   {
      //Print("One minute has passed, updating MA Data");
      prevTime = currentTime;
      UpdateBuffers();
   }
   static int waitCount = 10;
   if (waitCount > 0)
   {
      UpdateBuffersOnCalculate(0, rates_total);
      waitCount--;
      return prev_calculated;
   }
   string objnameInfo1 = objname + "Info1";
   if (ObjectFind(0, objnameInfo1) == -1)
   {
      ObjectCreate(0, objnameInfo1, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfo1, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objnameInfo1, OBJPROP_YDISTANCE, VertPos);
      ObjectSetInteger(0, objnameInfo1, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo1, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo1, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo1, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo1, OBJPROP_TEXT, "200 SMA");
   }
   string objnameInfo2 = objname + "Info2";
   if (ObjectFind(0, objnameInfo2) == -1)
   {
      ObjectCreate(0, objnameInfo2, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfo2, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objnameInfo2, OBJPROP_YDISTANCE, VertPos + 13);
      ObjectSetInteger(0, objnameInfo2, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo2, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo2, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo2, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo2, OBJPROP_TEXT, "DEATH X");
   }
   string objnameInfo3 = objname + "Info3";
   if (ObjectFind(0, objnameInfo3) == -1)
   {
      ObjectCreate(0, objnameInfo3, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfo3, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objnameInfo3, OBJPROP_YDISTANCE, VertPos + 26);
      ObjectSetInteger(0, objnameInfo3, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo3, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo3, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo3, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo3, OBJPROP_TEXT, "100/200");
   }
   string objnameInfo4 = objname + "Info4";
   if (ObjectFind(0, objnameInfo4) == -1)
   {
      ObjectCreate(0, objnameInfo4, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfo4, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objnameInfo4, OBJPROP_YDISTANCE, VertPos + 39);
      ObjectSetInteger(0, objnameInfo4, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo4, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo4, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo4, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo4, OBJPROP_TEXT, "20/50 X");
   }
   string objnameInfo5 = objname + "Info5";
   if (ObjectFind(0, objnameInfo5) == -1)
   {
      ObjectCreate(0, objnameInfo5, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfo5, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objnameInfo5, OBJPROP_YDISTANCE, VertPos + 52);
      ObjectSetInteger(0, objnameInfo5, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo5, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo5, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo5, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo5, OBJPROP_TEXT, "10/20 X");
   }
   int additionalSpacing = 0; 
   string timeFrames[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1"};
   for (int i = 0; i < ArraySize(timeFrames); i++)
   {
      if ( timeFrames[i] == "M30" || timeFrames[i] == "H1")
      {
         additionalSpacing += 5;
      }
      string objnameInfo200SMA = objname + timeFrames[i] + "200SMA";
      if (ObjectFind(0, objnameInfo200SMA) == -1)
      {
         ObjectCreate(0, objnameInfo200SMA, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
         ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_YDISTANCE, VertPos);
         ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_CORNER, Corner);
         ObjectSetString(0, objnameInfo200SMA, OBJPROP_FONT, FontName);
         ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, objnameInfo200SMA, OBJPROP_TEXT, timeFrames[i]);
      }
      string objnameInfoDEATH = objname + timeFrames[i] + "DEATH";
      if (ObjectFind(0, objnameInfoDEATH) == -1)
      {
         ObjectCreate(0, objnameInfoDEATH, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
         ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_YDISTANCE, VertPos+13);
         ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_CORNER, Corner);
         ObjectSetString(0, objnameInfoDEATH, OBJPROP_FONT, FontName);
         ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, objnameInfoDEATH, OBJPROP_TEXT, timeFrames[i]);
      }
      string objnameInfo100_200 = objname + timeFrames[i] + "100_200";
      if (ObjectFind(0, objnameInfo100_200) == -1)
      {
         ObjectCreate(0, objnameInfo100_200, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, objnameInfo100_200, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
         ObjectSetInteger(0, objnameInfo100_200, OBJPROP_YDISTANCE, VertPos+26);
         ObjectSetInteger(0, objnameInfo100_200, OBJPROP_CORNER, Corner);
         ObjectSetString(0, objnameInfo100_200, OBJPROP_FONT, FontName);
         ObjectSetInteger(0, objnameInfo100_200, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(0, objnameInfo100_200, OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, objnameInfo100_200, OBJPROP_TEXT, timeFrames[i]);
      }
      string objname20_50 = objname + timeFrames[i] + "20_50";
      if (ObjectFind(0, objname20_50) == -1)
      {
         ObjectCreate(0, objname20_50, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, objname20_50, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
         ObjectSetInteger(0, objname20_50, OBJPROP_YDISTANCE, VertPos+39);
         ObjectSetInteger(0, objname20_50, OBJPROP_CORNER, Corner);
         ObjectSetString(0, objname20_50, OBJPROP_FONT, FontName);
         ObjectSetInteger(0, objname20_50, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(0, objname20_50, OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, objname20_50, OBJPROP_TEXT, timeFrames[i]);
      }
      string objname10_20 = objname + timeFrames[i] + "10_20";
      if (ObjectFind(0, objname10_20) == -1)
      {
         ObjectCreate(0, objname10_20, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, objname10_20, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
         ObjectSetInteger(0, objname10_20, OBJPROP_YDISTANCE, VertPos+52);
         ObjectSetInteger(0, objname10_20, OBJPROP_CORNER, Corner);
         ObjectSetString(0, objname10_20, OBJPROP_FONT, FontName);
         ObjectSetInteger(0, objname10_20, OBJPROP_FONTSIZE, FontSize);
         ObjectSetInteger(0, objname10_20, OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, objname10_20, OBJPROP_TEXT, timeFrames[i]);
      }
   }
   string BullPowerTextLTF = "LTF Bull Power INIT";
   string BearPowerTextLTF = "LTF Bear Power INIT";
   string BullPowerTextHTF = "HTF Bull Power INIT";
   string BearPowerTextHTF = "HTF Bear Power INIT";
   if (ObjectFind(0, objname + "InfoBullPowerLTF") == -1)
   {
      ObjectCreate(0, objname + "InfoBullPowerLTF", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_YDISTANCE, VertPos + 65);
      ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname + "InfoBullPowerLTF", OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objname + "InfoBullPowerLTF", OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objname + "InfoBullPowerLTF", OBJPROP_TEXT, BullPowerTextLTF);
   }
   if (ObjectFind(0, objname + "InfoBearPowerLTF") == -1)
   {
      ObjectCreate(0, objname + "InfoBearPowerLTF", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_XDISTANCE, HorizPos - 160);
      ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_YDISTANCE, VertPos + 65);
      ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname + "InfoBearPowerLTF", OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objname + "InfoBearPowerLTF", OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objname + "InfoBearPowerLTF", OBJPROP_TEXT, BearPowerTextLTF);
   }
   if (ObjectFind(0, objname + "InfoBullPowerHTF") == -1)
   {
      ObjectCreate(0, objname + "InfoBullPowerHTF", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_YDISTANCE, VertPos + 77);
      ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname + "InfoBullPowerHTF", OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objname + "InfoBullPowerHTF", OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objname + "InfoBullPowerHTF", OBJPROP_TEXT, BullPowerTextHTF);
   }
   if (ObjectFind(0, objname + "InfoBearPowerHTF") == -1)
   {
      ObjectCreate(0, objname + "InfoBearPowerHTF", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_XDISTANCE, HorizPos - 160);
      ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_YDISTANCE, VertPos + 77);
      ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname + "InfoBearPowerHTF", OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objname + "InfoBearPowerHTF", OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objname + "InfoBearPowerHTF", OBJPROP_TEXT, BearPowerTextHTF);
   }
   // Get the current price
   double currentPrice = close[rates_total - 1];
   // Check the relationship of the current price with the 200-period SMAs
   bool isAbove_M1_200SMA = currentPrice > MABufferM1_200SMA[rates_total - 1];
   bool isAbove_M5_200SMA = currentPrice > MABufferM5_200SMA[rates_total - 1];
   bool isAbove_M15_200SMA = currentPrice > MABufferM15_200SMA[rates_total - 1];
   bool isAbove_M30_200SMA = currentPrice > MABufferM30_200SMA[rates_total - 1];
   bool isAbove_H1_200SMA = currentPrice > MABufferH1_200SMA[rates_total - 1];
   bool isAbove_H4_200SMA = currentPrice > MABufferH4_200SMA[rates_total - 1];
   bool isAbove_D1_200SMA = currentPrice > MABufferD1_200SMA[rates_total - 1];
   bool isAbove_W1_200SMA = currentPrice > MABufferW1_200SMA[rates_total - 1];
   UpdateInfoLabel("M1", isAbove_M1_200SMA, "200SMA");
   UpdateInfoLabel("M5", isAbove_M5_200SMA, "200SMA");
   UpdateInfoLabel("M15", isAbove_M15_200SMA, "200SMA");
   UpdateInfoLabel("M30", isAbove_M30_200SMA, "200SMA");
   UpdateInfoLabel("H1", isAbove_H1_200SMA, "200SMA");
   UpdateInfoLabel("H4", isAbove_H4_200SMA, "200SMA");
   UpdateInfoLabel("D1", isAbove_D1_200SMA, "200SMA");
   UpdateInfoLabel("W1", isAbove_W1_200SMA, "200SMA");
   // Check for DEATH and GOLDEN crosses
   bool isOnDeathRow_M1 = MABufferM1_50SMA[rates_total - 1] > MABufferM1_200SMA[rates_total - 1];
   bool isOnDeathRow_M5 = MABufferM5_50SMA[rates_total - 1] > MABufferM5_200SMA[rates_total - 1];
   bool isOnDeathRow_M15 = MABufferM15_50SMA[rates_total - 1] > MABufferM15_200SMA[rates_total - 1];
   bool isOnDeathRow_M30 = MABufferM30_50SMA[rates_total - 1] > MABufferM30_200SMA[rates_total - 1];
   bool isOnDeathRow_H1 = MABufferH1_50SMA[rates_total - 1] > MABufferH1_200SMA[rates_total - 1];
   bool isOnDeathRow_H4 = MABufferH4_50SMA[rates_total - 1] > MABufferH4_200SMA[rates_total - 1];
   bool isOnDeathRow_D1 = MABufferD1_50SMA[rates_total - 1] > MABufferD1_200SMA[rates_total - 1];
   bool isOnDeathRow_W1 = MABufferW1_50SMA[rates_total - 1] > MABufferW1_200SMA[rates_total - 1];
   UpdateInfoLabel("M1", isOnDeathRow_M1, "DEATH");
   UpdateInfoLabel("M5", isOnDeathRow_M5, "DEATH");
   UpdateInfoLabel("M15", isOnDeathRow_M15, "DEATH");
   UpdateInfoLabel("M30", isOnDeathRow_M30, "DEATH");
   UpdateInfoLabel("H1", isOnDeathRow_H1, "DEATH");
   UpdateInfoLabel("H4", isOnDeathRow_H4, "DEATH");
   UpdateInfoLabel("D1", isOnDeathRow_D1, "DEATH");
   UpdateInfoLabel("W1", isOnDeathRow_W1, "DEATH");
   // Check for 100/200 SMA crosses
   bool is100_200cross_M1 = MABufferM1_100SMA[rates_total - 1] > MABufferM1_200SMA[rates_total - 1];
   bool is100_200cross_M5 = MABufferM5_100SMA[rates_total - 1] > MABufferM5_200SMA[rates_total - 1];
   bool is100_200cross_M15 = MABufferM15_100SMA[rates_total - 1] > MABufferM15_200SMA[rates_total - 1];
   bool is100_200cross_M30 = MABufferM30_100SMA[rates_total - 1] > MABufferM30_200SMA[rates_total - 1];
   bool is100_200cross_H1 = MABufferH1_100SMA[rates_total - 1] > MABufferH1_200SMA[rates_total - 1];
   bool is100_200cross_H4 = MABufferH4_100SMA[rates_total - 1] > MABufferH4_200SMA[rates_total - 1];
   bool is100_200cross_D1 = MABufferD1_100SMA[rates_total - 1] > MABufferD1_200SMA[rates_total - 1];
   bool is100_200cross_W1 = MABufferW1_100SMA[rates_total - 1] > MABufferW1_200SMA[rates_total - 1];
   UpdateInfoLabel("M1", is100_200cross_M1, "100_200");
   UpdateInfoLabel("M5", is100_200cross_M5, "100_200");
   UpdateInfoLabel("M15", is100_200cross_M15, "100_200");
   UpdateInfoLabel("M30", is100_200cross_M30, "100_200");
   UpdateInfoLabel("H1", is100_200cross_H1, "100_200");
   UpdateInfoLabel("H4", is100_200cross_H4, "100_200");
   UpdateInfoLabel("D1", is100_200cross_D1, "100_200");
   UpdateInfoLabel("W1", is100_200cross_W1, "100_200");
   // Check for 20 SMA / 50 SMA crosses
   bool is20_50cross_M1 = MABufferM1_20SMA[rates_total - 1] > MABufferM1_50SMA[rates_total - 1];
   bool is20_50cross_M5 = MABufferM5_20SMA[rates_total - 1] > MABufferM5_50SMA[rates_total - 1];
   bool is20_50cross_M15 = MABufferM15_20SMA[rates_total - 1] > MABufferM15_50SMA[rates_total - 1];
   bool is20_50cross_M30 = MABufferM30_20SMA[rates_total - 1] > MABufferM30_50SMA[rates_total - 1];
   bool is20_50cross_H1 = MABufferH1_20SMA[rates_total - 1] > MABufferH1_50SMA[rates_total - 1];
   bool is20_50cross_H4 = MABufferH4_20SMA[rates_total - 1] > MABufferH4_50SMA[rates_total - 1];
   bool is20_50cross_D1 = MABufferD1_20SMA[rates_total - 1] > MABufferD1_50SMA[rates_total - 1];
   bool is20_50cross_W1 = MABufferW1_20SMA[rates_total - 1] > MABufferW1_50SMA[rates_total - 1];
   UpdateInfoLabel("M1", is20_50cross_M1, "20_50");
   UpdateInfoLabel("M5", is20_50cross_M5, "20_50");
   UpdateInfoLabel("M15", is20_50cross_M15, "20_50");
   UpdateInfoLabel("M30", is20_50cross_M30, "20_50");
   UpdateInfoLabel("H1", is20_50cross_H1, "20_50");
   UpdateInfoLabel("H4", is20_50cross_H4, "20_50");
   UpdateInfoLabel("D1", is20_50cross_D1, "20_50");
   UpdateInfoLabel("W1", is20_50cross_W1, "20_50");
   // Check for 10 SMA / 20 SMA crosses
   bool is10_20cross_M1 = MABufferM1_10SMA[rates_total - 1] > MABufferM1_20SMA[rates_total - 1];
   bool is10_20cross_M5 = MABufferM5_10SMA[rates_total - 1] > MABufferM5_20SMA[rates_total - 1];
   bool is10_20cross_M15 = MABufferM15_10SMA[rates_total - 1] > MABufferM15_20SMA[rates_total - 1];
   bool is10_20cross_M30 = MABufferM30_10SMA[rates_total - 1] > MABufferM30_20SMA[rates_total - 1];
   bool is10_20cross_H1 = MABufferH1_10SMA[rates_total - 1] > MABufferH1_20SMA[rates_total - 1];
   bool is10_20cross_H4 = MABufferH4_10SMA[rates_total - 1] > MABufferH4_20SMA[rates_total - 1];
   bool is10_20cross_D1 = MABufferD1_10SMA[rates_total - 1] > MABufferD1_20SMA[rates_total - 1];
   bool is10_20cross_W1 = MABufferW1_10SMA[rates_total - 1] > MABufferW1_20SMA[rates_total - 1];
   UpdateInfoLabel("M1", is10_20cross_M1, "10_20");
   UpdateInfoLabel("M5", is10_20cross_M5, "10_20");
   UpdateInfoLabel("M15", is10_20cross_M15, "10_20");
   UpdateInfoLabel("M30", is10_20cross_M30, "10_20");
   UpdateInfoLabel("H1", is10_20cross_H1, "10_20");
   UpdateInfoLabel("H4", is10_20cross_H4, "10_20");
   UpdateInfoLabel("D1", is10_20cross_D1, "10_20");
   UpdateInfoLabel("W1", is10_20cross_W1, "10_20");
   return rates_total;
}
void UpdateBuffers()
{
   // Clear buffer values before updating
   EraseBufferValues(MABufferM1_200SMA);
   EraseBufferValues(MABufferM5_200SMA);
   EraseBufferValues(MABufferM15_200SMA);
   EraseBufferValues(MABufferM30_200SMA);
   EraseBufferValues(MABufferH1_200SMA);
   EraseBufferValues(MABufferH4_200SMA);
   EraseBufferValues(MABufferD1_200SMA);
   EraseBufferValues(MABufferW1_200SMA);
   EraseBufferValues(MABufferM1_50SMA);
   EraseBufferValues(MABufferM5_50SMA);
   EraseBufferValues(MABufferM15_50SMA);
   EraseBufferValues(MABufferM30_50SMA);
   EraseBufferValues(MABufferH1_50SMA);
   EraseBufferValues(MABufferH4_50SMA);
   EraseBufferValues(MABufferD1_50SMA);
   EraseBufferValues(MABufferW1_50SMA);
   EraseBufferValues(MABufferM1_20SMA);
   EraseBufferValues(MABufferM5_20SMA);
   EraseBufferValues(MABufferM15_20SMA);
   EraseBufferValues(MABufferM30_20SMA);
   EraseBufferValues(MABufferH1_20SMA);
   EraseBufferValues(MABufferH4_20SMA);
   EraseBufferValues(MABufferD1_20SMA);
   EraseBufferValues(MABufferW1_20SMA);
   EraseBufferValues(MABufferM1_10SMA);
   EraseBufferValues(MABufferM5_10SMA);
   EraseBufferValues(MABufferM15_10SMA);
   EraseBufferValues(MABufferM30_10SMA);
   EraseBufferValues(MABufferH1_10SMA);
   EraseBufferValues(MABufferH4_10SMA);
   EraseBufferValues(MABufferD1_10SMA);
   EraseBufferValues(MABufferW1_10SMA);
   EraseBufferValues(MABufferMN1_100SMA);
   HandleM1_200SMA = iMA(NULL, PERIOD_M1, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_200SMA, 0, 0, BufferSize(MABufferM1_200SMA), MABufferM1_200SMA);
   HandleM5_200SMA = iMA(NULL, PERIOD_M5, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_200SMA, 0, 0, BufferSize(MABufferM5_200SMA), MABufferM5_200SMA);
   HandleM15_200SMA = iMA(NULL, PERIOD_M15, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_200SMA, 0, 0, BufferSize(MABufferM15_200SMA), MABufferM15_200SMA);
   HandleM30_200SMA = iMA(NULL, PERIOD_M30, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_200SMA, 0, 0, BufferSize(MABufferM30_200SMA), MABufferM30_200SMA);
   HandleH1_200SMA = iMA(NULL, PERIOD_H1, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_200SMA, 0, 0, BufferSize(MABufferH1_200SMA), MABufferH1_200SMA);
   HandleH4_200SMA = iMA(NULL, PERIOD_H4, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_200SMA, 0, 0, BufferSize(MABufferH4_200SMA), MABufferH4_200SMA);
   HandleD1_200SMA = iMA(NULL, PERIOD_D1, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_200SMA, 0, 0, BufferSize(MABufferD1_200SMA), MABufferD1_200SMA);
   HandleW1_200SMA = iMA(NULL, PERIOD_W1, 200, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_200SMA, 0, 0, BufferSize(MABufferW1_200SMA), MABufferW1_200SMA);
   HandleM1_50SMA = iMA(NULL, PERIOD_M1, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_50SMA, 0, 0, BufferSize(MABufferM1_50SMA), MABufferM1_50SMA);
   HandleM5_50SMA = iMA(NULL, PERIOD_M5, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_50SMA, 0, 0, BufferSize(MABufferM5_50SMA), MABufferM5_50SMA);
   HandleM15_50SMA = iMA(NULL, PERIOD_M15, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_50SMA, 0, 0, BufferSize(MABufferM15_50SMA), MABufferM15_50SMA);
   HandleM30_50SMA = iMA(NULL, PERIOD_M30, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_50SMA, 0, 0, BufferSize(MABufferM30_50SMA), MABufferM30_50SMA);
   HandleH1_50SMA = iMA(NULL, PERIOD_H1, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_50SMA, 0, 0, BufferSize(MABufferH1_50SMA), MABufferH1_50SMA);
   HandleH4_50SMA = iMA(NULL, PERIOD_H4, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_50SMA, 0, 0, BufferSize(MABufferH4_50SMA), MABufferH4_50SMA);
   HandleD1_50SMA = iMA(NULL, PERIOD_D1, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_50SMA, 0, 0, BufferSize(MABufferD1_50SMA), MABufferD1_50SMA);
   HandleW1_50SMA = iMA(NULL, PERIOD_W1, 50, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_50SMA, 0, 0, BufferSize(MABufferW1_50SMA), MABufferW1_50SMA);
   HandleM1_20SMA = iMA(NULL, PERIOD_M1, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_20SMA, 0, 0, BufferSize(MABufferM1_20SMA), MABufferM1_20SMA);
   HandleM5_20SMA = iMA(NULL, PERIOD_M5, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_20SMA, 0, 0, BufferSize(MABufferM5_20SMA), MABufferM5_20SMA);
   HandleM15_20SMA = iMA(NULL, PERIOD_M15, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_20SMA, 0, 0, BufferSize(MABufferM15_20SMA), MABufferM15_20SMA);
   HandleM30_20SMA = iMA(NULL, PERIOD_M30, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_20SMA, 0, 0, BufferSize(MABufferM30_20SMA), MABufferM30_20SMA);
   HandleH1_20SMA = iMA(NULL, PERIOD_H1, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_20SMA, 0, 0, BufferSize(MABufferH1_20SMA), MABufferH1_20SMA);
   HandleH4_20SMA = iMA(NULL, PERIOD_H4, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_20SMA, 0, 0, BufferSize(MABufferH4_20SMA), MABufferH4_20SMA);
   HandleD1_20SMA = iMA(NULL, PERIOD_D1, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_20SMA, 0, 0, BufferSize(MABufferD1_20SMA), MABufferD1_20SMA);
   HandleW1_20SMA = iMA(NULL, PERIOD_W1, 20, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_20SMA, 0, 0, BufferSize(MABufferW1_20SMA), MABufferW1_20SMA);
   HandleM1_10SMA = iMA(NULL, PERIOD_M1, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_10SMA, 0, 0, BufferSize(MABufferM1_10SMA), MABufferM1_10SMA);
   HandleM5_10SMA = iMA(NULL, PERIOD_M5, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_10SMA, 0, 0, BufferSize(MABufferM5_10SMA), MABufferM5_10SMA);
   HandleM15_10SMA = iMA(NULL, PERIOD_M15, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_10SMA, 0, 0, BufferSize(MABufferM15_10SMA), MABufferM15_10SMA);
   HandleM30_10SMA = iMA(NULL, PERIOD_M30, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_10SMA, 0, 0, BufferSize(MABufferM30_10SMA), MABufferM30_10SMA);
   HandleH1_10SMA = iMA(NULL, PERIOD_H1, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_10SMA, 0, 0, BufferSize(MABufferH1_10SMA), MABufferH1_10SMA);
   HandleH4_10SMA = iMA(NULL, PERIOD_H4, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_10SMA, 0, 0, BufferSize(MABufferH4_10SMA), MABufferH4_10SMA);
   HandleD1_10SMA = iMA(NULL, PERIOD_D1, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_10SMA, 0, 0, BufferSize(MABufferD1_10SMA), MABufferD1_10SMA);
   HandleW1_10SMA = iMA(NULL, PERIOD_W1, 10, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_10SMA, 0, 0, BufferSize(MABufferW1_10SMA), MABufferW1_10SMA);
   HandleM1_100SMA = iMA(NULL, PERIOD_M1, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_100SMA, 0, 0, BufferSize(MABufferM1_100SMA), MABufferM1_100SMA);
   HandleM5_100SMA = iMA(NULL, PERIOD_M5, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_100SMA, 0, 0, BufferSize(MABufferM5_100SMA), MABufferM5_100SMA);
   HandleM15_100SMA = iMA(NULL, PERIOD_M15, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_100SMA, 0, 0, BufferSize(MABufferM15_100SMA), MABufferM15_100SMA);
   HandleM30_100SMA = iMA(NULL, PERIOD_M30, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_100SMA, 0, 0, BufferSize(MABufferM30_100SMA), MABufferM30_100SMA);
   HandleH1_100SMA = iMA(NULL, PERIOD_H1, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_100SMA, 0, 0, BufferSize(MABufferH1_100SMA), MABufferH1_100SMA);
   HandleH4_100SMA = iMA(NULL, PERIOD_H4, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_100SMA, 0, 0, BufferSize(MABufferH4_100SMA), MABufferH4_100SMA);
   HandleD1_100SMA = iMA(NULL, PERIOD_D1, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_100SMA, 0, 0, BufferSize(MABufferD1_100SMA), MABufferD1_100SMA);
   HandleW1_100SMA = iMA(NULL, PERIOD_W1, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_100SMA, 0, 0, BufferSize(MABufferW1_100SMA), MABufferW1_100SMA);
   HandleMN1_100SMA = iMA(NULL, PERIOD_MN1, 100, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleMN1_100SMA, 0, 0, BufferSize(MABufferMN1_100SMA), MABufferMN1_100SMA);
}
void UpdateBuffersOnCalculate(int start, int rates_total)
{
   CopyBuffer(HandleM1_200SMA, 0, 0, BufferSize(MABufferM1_200SMA), MABufferM1_200SMA);
   CopyBuffer(HandleM5_200SMA, 0, 0, BufferSize(MABufferM5_200SMA), MABufferM5_200SMA);
   CopyBuffer(HandleM15_200SMA, 0, 0, BufferSize(MABufferM15_200SMA), MABufferM15_200SMA);
   CopyBuffer(HandleM30_200SMA, 0, 0, BufferSize(MABufferM30_200SMA), MABufferM30_200SMA);
   CopyBuffer(HandleH1_200SMA, 0, 0, BufferSize(MABufferH1_200SMA), MABufferH1_200SMA);
   CopyBuffer(HandleH4_200SMA, 0, 0, BufferSize(MABufferH4_200SMA), MABufferH4_200SMA);
   CopyBuffer(HandleD1_200SMA, 0, 0, BufferSize(MABufferD1_200SMA), MABufferD1_200SMA);
   CopyBuffer(HandleW1_200SMA, 0, 0, BufferSize(MABufferW1_200SMA), MABufferW1_200SMA);
   CopyBuffer(HandleM1_50SMA, 0, 0, BufferSize(MABufferM1_50SMA), MABufferM1_50SMA);
   CopyBuffer(HandleM5_50SMA, 0, 0, BufferSize(MABufferM5_50SMA), MABufferM5_50SMA);
   CopyBuffer(HandleM15_50SMA, 0, 0, BufferSize(MABufferM15_50SMA), MABufferM15_50SMA);
   CopyBuffer(HandleM30_50SMA, 0, 0, BufferSize(MABufferM30_50SMA), MABufferM30_50SMA);
   CopyBuffer(HandleH1_50SMA, 0, 0, BufferSize(MABufferH1_50SMA), MABufferH1_50SMA);
   CopyBuffer(HandleH4_50SMA, 0, 0, BufferSize(MABufferH4_50SMA), MABufferH4_50SMA);
   CopyBuffer(HandleD1_50SMA, 0, 0, BufferSize(MABufferD1_50SMA), MABufferD1_50SMA);
   CopyBuffer(HandleW1_50SMA, 0, 0, BufferSize(MABufferW1_50SMA), MABufferW1_50SMA);
   CopyBuffer(HandleM1_20SMA, 0, 0, BufferSize(MABufferM1_20SMA), MABufferM1_20SMA);
   CopyBuffer(HandleM5_20SMA, 0, 0, BufferSize(MABufferM5_20SMA), MABufferM5_20SMA);
   CopyBuffer(HandleM15_20SMA, 0, 0, BufferSize(MABufferM15_20SMA), MABufferM15_20SMA);
   CopyBuffer(HandleM30_20SMA, 0, 0, BufferSize(MABufferM30_20SMA), MABufferM30_20SMA);
   CopyBuffer(HandleH1_20SMA, 0, 0, BufferSize(MABufferH1_20SMA), MABufferH1_20SMA);
   CopyBuffer(HandleH4_20SMA, 0, 0, BufferSize(MABufferH4_20SMA), MABufferH4_20SMA);
   CopyBuffer(HandleD1_20SMA, 0, 0, BufferSize(MABufferD1_20SMA), MABufferD1_20SMA);
   CopyBuffer(HandleW1_20SMA, 0, 0, BufferSize(MABufferW1_20SMA), MABufferW1_20SMA);
   CopyBuffer(HandleM1_10SMA, 0, 0, BufferSize(MABufferM1_10SMA), MABufferM1_10SMA);
   CopyBuffer(HandleM5_10SMA, 0, 0, BufferSize(MABufferM5_10SMA), MABufferM5_10SMA);
   CopyBuffer(HandleM15_10SMA, 0, 0, BufferSize(MABufferM15_10SMA), MABufferM15_10SMA);
   CopyBuffer(HandleM30_10SMA, 0, 0, BufferSize(MABufferM30_10SMA), MABufferM30_10SMA);
   CopyBuffer(HandleH1_10SMA, 0, 0, BufferSize(MABufferH1_10SMA), MABufferH1_10SMA);
   CopyBuffer(HandleH4_10SMA, 0, 0, BufferSize(MABufferH4_10SMA), MABufferH4_10SMA);
   CopyBuffer(HandleD1_10SMA, 0, 0, BufferSize(MABufferD1_10SMA), MABufferD1_10SMA);
   CopyBuffer(HandleW1_10SMA, 0, 0, BufferSize(MABufferW1_10SMA), MABufferW1_10SMA);
   CopyBuffer(HandleM1_100SMA, 0, 0, BufferSize(MABufferM1_100SMA), MABufferM1_100SMA);
   CopyBuffer(HandleM5_100SMA, 0, 0, BufferSize(MABufferM5_100SMA), MABufferM5_100SMA);
   CopyBuffer(HandleM15_100SMA, 0, 0, BufferSize(MABufferM15_100SMA), MABufferM15_100SMA);
   CopyBuffer(HandleM30_100SMA, 0, 0, BufferSize(MABufferM30_100SMA), MABufferM30_100SMA);
   CopyBuffer(HandleH1_100SMA, 0, 0, BufferSize(MABufferH1_100SMA), MABufferH1_100SMA);
   CopyBuffer(HandleH4_100SMA, 0, 0, BufferSize(MABufferH4_100SMA), MABufferH4_100SMA);
   CopyBuffer(HandleD1_100SMA, 0, 0, BufferSize(MABufferD1_100SMA), MABufferD1_100SMA);
   CopyBuffer(HandleW1_100SMA, 0, 0, BufferSize(MABufferW1_100SMA), MABufferW1_100SMA);
   CopyBuffer(HandleMN1_100SMA, 0, 0, BufferSize(MABufferMN1_100SMA), MABufferMN1_100SMA);
}
bool IsNewMinute(const datetime &currentTime, const datetime &prevTime)
{
   MqlDateTime currentMqlTime, prevMqlTime;
   TimeToStruct(currentTime, currentMqlTime);
   TimeToStruct(prevTime, prevMqlTime);
   return currentMqlTime.min != prevMqlTime.min;
}
int BufferSize(const double &buffer[])
{
   return ArraySize(buffer);
}
void EraseBufferValues(double& buffer[])
{
   int bufferSize = BufferSize(buffer);
   for (int i = 0; i < bufferSize; i++)
   {
      buffer[i] = EMPTY_VALUE;
   }
}
