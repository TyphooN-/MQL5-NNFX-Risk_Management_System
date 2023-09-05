/**=                 MTF_MA.mq5  (TyphooN's Multi Timeframe MA)
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
#property copyright "TyphooN"
#property link      "http://decapool.net"
#property version   "1.024"
#property indicator_chart_window
#property indicator_buffers 32
#property indicator_plots   8
#property indicator_label1  "M1 200SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "M5 200SMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "M15 200SMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrange
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "M30 200SMA"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label5  "H1 200SMA"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
#property indicator_label6  "H4 200SMA"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrMagenta
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
#property indicator_label7  "D1 200SMA"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrMagenta
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2
#property indicator_label8  "W1 200SMA"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrMagenta
#property indicator_style8  STYLE_SOLID
#property indicator_width8  2
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
// Buffers
double MABufferM1_200SMA[], MABufferM1_50SMA[], MABufferM1_20SMA[], MABufferM1_10SMA[], MABufferM5_200SMA[], MABufferM5_50SMA[], MABufferM5_20SMA[], MABufferM5_10SMA[], MABufferM15_200SMA[], MABufferM15_50SMA[], MABufferM15_20SMA[];
double MABufferM15_10SMA[], MABufferM30_200SMA[], MABufferM30_50SMA[], MABufferM30_20SMA[], MABufferM30_10SMA[], MABufferH1_200SMA[], MABufferH1_50SMA[], MABufferH1_20SMA[], MABufferH1_10SMA[], MABufferH4_200SMA[], MABufferH4_50SMA[];
double MABufferH4_20SMA[], MABufferH4_10SMA[], MABufferD1_200SMA[], MABufferD1_50SMA[], MABufferD1_20SMA[], MABufferD1_10SMA[], MABufferW1_200SMA[], MABufferW1_50SMA[], MABufferW1_20SMA[], MABufferW1_10SMA[];
bool isTimerSet = false;
int lastCheckedCandle = -1;
string objname = "MTF_SMA";
int OnInit()
{
   SetIndexBuffer(0, MABufferM1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(1, MABufferM5_200SMA, INDICATOR_DATA);
   SetIndexBuffer(2, MABufferM15_200SMA, INDICATOR_DATA);
   SetIndexBuffer(3, MABufferM30_200SMA, INDICATOR_DATA);
   SetIndexBuffer(4, MABufferH1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(5, MABufferH4_200SMA, INDICATOR_DATA);
   SetIndexBuffer(6, MABufferD1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(7, MABufferW1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(8, MABufferM1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(9, MABufferM5_50SMA, INDICATOR_DATA);
   SetIndexBuffer(10, MABufferM15_50SMA, INDICATOR_DATA);
   SetIndexBuffer(11, MABufferM30_50SMA, INDICATOR_DATA);
   SetIndexBuffer(12, MABufferH1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(13, MABufferH4_50SMA, INDICATOR_DATA);
   SetIndexBuffer(14, MABufferD1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(15, MABufferW1_50SMA, INDICATOR_DATA);
   SetIndexBuffer(16, MABufferM1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(17, MABufferM5_10SMA, INDICATOR_DATA);
   SetIndexBuffer(18, MABufferM15_10SMA, INDICATOR_DATA);
   SetIndexBuffer(19, MABufferM30_10SMA, INDICATOR_DATA);
   SetIndexBuffer(20, MABufferH1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(21, MABufferH4_10SMA, INDICATOR_DATA);
   SetIndexBuffer(22, MABufferD1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(23, MABufferW1_10SMA, INDICATOR_DATA);
   SetIndexBuffer(24, MABufferM1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(25, MABufferM5_20SMA, INDICATOR_DATA);
   SetIndexBuffer(26, MABufferM15_20SMA, INDICATOR_DATA);
   SetIndexBuffer(27, MABufferM30_20SMA, INDICATOR_DATA);
   SetIndexBuffer(28, MABufferH1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(29, MABufferH4_20SMA, INDICATOR_DATA);
   SetIndexBuffer(30, MABufferD1_20SMA, INDICATOR_DATA);
   SetIndexBuffer(31, MABufferW1_20SMA, INDICATOR_DATA);
   string objnameInfo1 = objname + "Info1";
   ObjectCreate(0, objnameInfo1, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objnameInfo1, OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objnameInfo1, OBJPROP_YDISTANCE, VertPos);
   ObjectSetInteger(0, objnameInfo1, OBJPROP_CORNER, Corner);
   ObjectSetString(0, objnameInfo1, OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objnameInfo1, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objnameInfo1, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, objnameInfo1, OBJPROP_TEXT, "DEATH X|");
   string objnameInfo2 = objname + "Info2";
   ObjectCreate(0, objnameInfo2, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objnameInfo2, OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objnameInfo2, OBJPROP_YDISTANCE, VertPos + 13);
   ObjectSetInteger(0, objnameInfo2, OBJPROP_CORNER, Corner);
   ObjectSetString(0, objnameInfo2, OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objnameInfo2, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objnameInfo2, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, objnameInfo2, OBJPROP_TEXT, "200 SMA| ");
   string objnameInfo3 = objname + "Info3";
   ObjectCreate(0, objnameInfo3, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objnameInfo3, OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objnameInfo3, OBJPROP_YDISTANCE, VertPos + 26);
   ObjectSetInteger(0, objnameInfo3, OBJPROP_CORNER, Corner);
   ObjectSetString(0, objnameInfo3, OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objnameInfo3, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objnameInfo3, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, objnameInfo3, OBJPROP_TEXT, "20/50 X|");
   string objnameInfo4 = objname + "Info4";
   ObjectCreate(0, objnameInfo4, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objnameInfo4, OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objnameInfo4, OBJPROP_YDISTANCE, VertPos + 39);
   ObjectSetInteger(0, objnameInfo4, OBJPROP_CORNER, Corner);
   ObjectSetString(0, objnameInfo4, OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objnameInfo4, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objnameInfo4, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, objnameInfo4, OBJPROP_TEXT, "10/20 X|");
   int additionalSpacing = 0; 
   string timeFrames[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1"};
   for (int i = 0; i < ArraySize(timeFrames); i++)
   {
      if ( timeFrames[i] == "M30" || timeFrames[i] == "H1")
      {
         additionalSpacing += 5;
      }
      string objnameInfoDEATH = objname + timeFrames[i] + "DEATH";
      ObjectCreate(0, objnameInfoDEATH, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
      ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_YDISTANCE, VertPos);
      ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfoDEATH, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfoDEATH, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfoDEATH, OBJPROP_TEXT, timeFrames[i]);
      string objnameInfo200SMA = objname + timeFrames[i] + "200SMA";
      ObjectCreate(0, objnameInfo200SMA, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
      ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_YDISTANCE, VertPos+13);
      ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo200SMA, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo200SMA, OBJPROP_TEXT, timeFrames[i]);
      string objname20_50 = objname + timeFrames[i] + "20_50";
      ObjectCreate(0, objname20_50, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname20_50, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
      ObjectSetInteger(0, objname20_50, OBJPROP_YDISTANCE, VertPos+26);
      ObjectSetInteger(0, objname20_50, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname20_50, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname20_50, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objname20_50, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objname20_50, OBJPROP_TEXT, timeFrames[i]);
      string objname10_20 = objname + timeFrames[i] + "10_20";
      ObjectCreate(0, objname10_20, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objname10_20, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 29 + additionalSpacing));
      ObjectSetInteger(0, objname10_20, OBJPROP_YDISTANCE, VertPos+39);
      ObjectSetInteger(0, objname10_20, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objname10_20, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objname10_20, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objname10_20, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objname10_20, OBJPROP_TEXT, timeFrames[i]);
   }
   return 0;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
}
void UpdateInfoLabel(string timeframe, bool condition, string label)
{
    string objnameInfo = objname + timeframe + label;
    color textColor = condition ? clrLime : clrRed;
    ObjectSetInteger(0, objnameInfo, OBJPROP_COLOR, textColor);
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
   static int waitCount = 2;
   if (waitCount > 0)
   {
      UpdateBuffersOnCalculate(0, rates_total);
      waitCount--;
      return prev_calculated;
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
   HandleD1_20SMA = iMA(NULL, PERIOD_D1, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_20SMA, 0, 0, BufferSize(MABufferD1_20SMA), MABufferD1_20SMA);
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
   HandleM1_20SMA = iMA(NULL, PERIOD_M1, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_20SMA, 0, 0, BufferSize(MABufferM1_20SMA), MABufferM1_20SMA);
   HandleM5_20SMA = iMA(NULL, PERIOD_M5, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_20SMA, 0, 0, BufferSize(MABufferM5_20SMA), MABufferM5_20SMA);
   HandleM15_20SMA = iMA(NULL, PERIOD_M15, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_20SMA, 0, 0, BufferSize(MABufferM15_20SMA), MABufferM15_20SMA);
   HandleM30_20SMA = iMA(NULL, PERIOD_M30, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_20SMA, 0, 0, BufferSize(MABufferM30_20SMA), MABufferM30_20SMA);
   HandleH1_20SMA = iMA(NULL, PERIOD_H1, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_20SMA, 0, 0, BufferSize(MABufferH1_20SMA), MABufferH1_20SMA);
   HandleH4_20SMA = iMA(NULL, PERIOD_H4, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_20SMA, 0, 0, BufferSize(MABufferH4_20SMA), MABufferH4_20SMA);
   HandleD1_20SMA = iMA(NULL, PERIOD_D1, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_20SMA, 0, 0, BufferSize(MABufferD1_20SMA), MABufferD1_20SMA);
   HandleW1_20SMA = iMA(NULL, PERIOD_W1, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_20SMA, 0, 0, BufferSize(MABufferW1_20SMA), MABufferW1_20SMA);
   HandleM1_10SMA = iMA(NULL, PERIOD_M1, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM1_10SMA, 0, 0, BufferSize(MABufferM1_10SMA), MABufferM1_10SMA);
   HandleM5_10SMA = iMA(NULL, PERIOD_M5, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM5_10SMA, 0, 0, BufferSize(MABufferM5_10SMA), MABufferM5_10SMA);
   HandleM15_10SMA = iMA(NULL, PERIOD_M15, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM15_10SMA, 0, 0, BufferSize(MABufferM15_10SMA), MABufferM15_10SMA);
   HandleM30_10SMA = iMA(NULL, PERIOD_M30, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleM30_10SMA, 0, 0, BufferSize(MABufferM30_10SMA), MABufferM30_10SMA);
   HandleH1_10SMA = iMA(NULL, PERIOD_H1, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH1_10SMA, 0, 0, BufferSize(MABufferH1_10SMA), MABufferH1_10SMA);
   HandleH4_10SMA = iMA(NULL, PERIOD_H4, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleH4_10SMA, 0, 0, BufferSize(MABufferH4_10SMA), MABufferH4_10SMA);
   HandleD1_10SMA = iMA(NULL, PERIOD_D1, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_10SMA, 0, 0, BufferSize(MABufferD1_10SMA), MABufferD1_10SMA);
   HandleW1_10SMA = iMA(NULL, PERIOD_W1, 8, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleW1_10SMA, 0, 0, BufferSize(MABufferW1_10SMA), MABufferW1_10SMA);
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
