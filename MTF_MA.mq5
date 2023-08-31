/**=                 MTF_SMA.mq5  (TyphooN's Multi Timeframe MA)
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
#property version   "1.020"
#property indicator_chart_window
#property indicator_buffers 28
#property indicator_plots   9
#property indicator_label1  "M1 200SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "M5 200SMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMagenta
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "M15 200SMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "M30 200SMA"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrMagenta
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label5  "H1 200SMA"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrOrange
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
#property indicator_label6  "H4 200SMA"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrOrange
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
#property indicator_label7  "D1 200SMA"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrOrange
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2
#property indicator_label8  "W1 200SMA"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrOrange
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
int HandleM1_200SMA, HandleM1_50SMA, HandleM5_200SMA, HandleM5_50SMA, HandleM15_200SMA, HandleM15_50SMA, HandleM15_13EMA, HandleM15_8EMA, HandleM30_200SMA;
int HandleM30_50SMA, HandleM30_13EMA, HandleM30_8EMA, HandleH1_200SMA, HandleH1_50SMA, HandleH1_13EMA, HandleH1_8EMA, HandleH4_200SMA, HandleH4_50SMA, HandleH4_13EMA;
int HandleH4_8EMA, HandleD1_200SMA, HandleD1_50SMA, HandleD1_13EMA, HandleD1_8EMA, HandleW1_200SMA, HandleW1_50SMA, HandleW1_13EMA, HandleW1_8EMA;
// Buffers
double MABufferM1_200SMA[], MABufferM1_50SMA[], MABufferM5_200SMA[], MABufferM5_50SMA[], MABufferM15_200SMA[], MABufferM15_50SMA[], MABufferM15_13EMA[], MABufferM15_8EMA[], MABufferM30_200SMA[];
double MABufferM30_50SMA[], MABufferM30_13EMA[], MABufferM30_8EMA[], MABufferH1_200SMA[], MABufferH1_50SMA[], MABufferH1_13EMA[], MABufferH1_8EMA[], MABufferH4_200SMA[], MABufferH4_50SMA[];
double MABufferH4_13EMA[], MABufferH4_8EMA[], MABufferD1_200SMA[], MABufferD1_50SMA[], MABufferD1_13EMA[], MABufferD1_8EMA[], MABufferW1_200SMA[], MABufferW1_50SMA[], MABufferW1_13EMA[], MABufferW1_8EMA[];
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
   SetIndexBuffer(16, MABufferM15_8EMA, INDICATOR_DATA);
   SetIndexBuffer(17, MABufferM30_8EMA, INDICATOR_DATA);
   SetIndexBuffer(18, MABufferH1_8EMA, INDICATOR_DATA);
   SetIndexBuffer(19, MABufferH4_8EMA, INDICATOR_DATA);
   SetIndexBuffer(20, MABufferD1_8EMA, INDICATOR_DATA);
   SetIndexBuffer(21, MABufferW1_8EMA, INDICATOR_DATA);
   SetIndexBuffer(22, MABufferM15_13EMA, INDICATOR_DATA);
   SetIndexBuffer(23, MABufferM30_13EMA, INDICATOR_DATA);
   SetIndexBuffer(24, MABufferH1_13EMA, INDICATOR_DATA);
   SetIndexBuffer(25, MABufferH4_13EMA, INDICATOR_DATA);
   SetIndexBuffer(26, MABufferD1_13EMA, INDICATOR_DATA);
   SetIndexBuffer(27, MABufferW1_13EMA, INDICATOR_DATA);
   string timeFrames[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1"};
   string objnameInfo200SMA = objname + "200SMAInfo";
   ObjectCreate(0, objnameInfo200SMA, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_XDISTANCE, HorizPos);
   ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_YDISTANCE, VertPos);
   ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_CORNER, Corner);
   ObjectSetString(0, objnameInfo200SMA, OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, objnameInfo200SMA, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, objnameInfo200SMA, OBJPROP_TEXT, "200 SMA| ");
   int additionalSpacing = 0; 
   for (int i = 0; i < ArraySize(timeFrames); i++)
   {
      string objnameInfo = objname + timeFrames[i] + "Info";
      ObjectCreate(0, objnameInfo, OBJ_LABEL, 0, 0, 0);
      if ( timeFrames[i] == "M30" || timeFrames[i] == "H1")
      {
         additionalSpacing += 5;
      }
      ObjectSetInteger(0, objnameInfo, OBJPROP_XDISTANCE, HorizPos - 65 - (i * 25 + additionalSpacing));
      ObjectSetInteger(0, objnameInfo, OBJPROP_YDISTANCE, VertPos);
      ObjectSetInteger(0, objnameInfo, OBJPROP_CORNER, Corner);
      ObjectSetString(0, objnameInfo, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, objnameInfo, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, objnameInfo, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, objnameInfo, OBJPROP_TEXT, timeFrames[i]);
   }
   return 0;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
}
void UpdateInfoLabel(string timeframe, bool isAbove)
{
    string objnameInfo = objname + timeframe + "Info";
    color textColor = isAbove ? clrLime : clrRed;
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
   bool isAbove_H1_200SMA = currentPrice > MABufferH1_200SMA[rates_total - 1];
   bool isAbove_H4_200SMA = currentPrice > MABufferH4_200SMA[rates_total - 1];
   bool isAbove_D1_200SMA = currentPrice > MABufferD1_200SMA[rates_total - 1];
   bool isAbove_W1_200SMA = currentPrice > MABufferW1_200SMA[rates_total - 1];
   bool isAbove_M1_200SMA = currentPrice > MABufferM1_200SMA[rates_total - 1];
   bool isAbove_M5_200SMA = currentPrice > MABufferM5_200SMA[rates_total - 1];
   bool isAbove_M15_200SMA = currentPrice > MABufferM15_200SMA[rates_total - 1];
   bool isAbove_M30_200SMA = currentPrice > MABufferM30_200SMA[rates_total - 1];
   UpdateInfoLabel("M1", isAbove_M1_200SMA);
   UpdateInfoLabel("M5", isAbove_M5_200SMA);
   UpdateInfoLabel("M15", isAbove_M15_200SMA);
   UpdateInfoLabel("M30", isAbove_M30_200SMA);
   UpdateInfoLabel("H1", isAbove_H1_200SMA);
   UpdateInfoLabel("H4", isAbove_H4_200SMA);
   UpdateInfoLabel("D1", isAbove_D1_200SMA);
   UpdateInfoLabel("W1", isAbove_W1_200SMA);
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
   EraseBufferValues(MABufferM15_13EMA);
   EraseBufferValues(MABufferM30_13EMA);
   EraseBufferValues(MABufferH1_13EMA);
   EraseBufferValues(MABufferH4_13EMA);
   EraseBufferValues(MABufferD1_13EMA);
   EraseBufferValues(MABufferW1_13EMA);
   EraseBufferValues(MABufferM15_8EMA);
   EraseBufferValues(MABufferM30_8EMA);
   EraseBufferValues(MABufferH1_8EMA);
   EraseBufferValues(MABufferH4_8EMA);
   EraseBufferValues(MABufferD1_8EMA);
   EraseBufferValues(MABufferW1_8EMA);
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
   HandleD1_13EMA = iMA(NULL, PERIOD_D1, 13, 0, MODE_SMA, MAPrice);
   CopyBuffer(HandleD1_13EMA, 0, 0, BufferSize(MABufferD1_13EMA), MABufferD1_13EMA);
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
   HandleM15_13EMA = iMA(NULL, PERIOD_M15, 13, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleM15_13EMA, 0, 0, BufferSize(MABufferM15_13EMA), MABufferM15_13EMA);
   HandleM30_13EMA = iMA(NULL, PERIOD_M30, 13, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleM30_13EMA, 0, 0, BufferSize(MABufferM30_13EMA), MABufferM30_13EMA);
   HandleH1_13EMA = iMA(NULL, PERIOD_H1, 13, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleH1_13EMA, 0, 0, BufferSize(MABufferH1_13EMA), MABufferH1_13EMA);
   HandleH4_13EMA = iMA(NULL, PERIOD_H4, 13, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleH4_13EMA, 0, 0, BufferSize(MABufferH4_13EMA), MABufferH4_13EMA);
   HandleD1_13EMA = iMA(NULL, PERIOD_D1, 13, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleD1_13EMA, 0, 0, BufferSize(MABufferD1_13EMA), MABufferD1_13EMA);
   HandleW1_13EMA = iMA(NULL, PERIOD_W1, 13, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleW1_13EMA, 0, 0, BufferSize(MABufferW1_13EMA), MABufferW1_13EMA);
   HandleM15_8EMA = iMA(NULL, PERIOD_M15, 8, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleM15_8EMA, 0, 0, BufferSize(MABufferM15_8EMA), MABufferM15_8EMA);
   HandleM30_8EMA = iMA(NULL, PERIOD_M30, 8, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleM30_8EMA, 0, 0, BufferSize(MABufferM30_8EMA), MABufferM30_8EMA);
   HandleH1_8EMA = iMA(NULL, PERIOD_H1, 8, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleH1_8EMA, 0, 0, BufferSize(MABufferH1_8EMA), MABufferH1_8EMA);
   HandleH4_8EMA = iMA(NULL, PERIOD_H4, 8, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleH4_8EMA, 0, 0, BufferSize(MABufferH4_8EMA), MABufferH4_8EMA);
   HandleD1_8EMA = iMA(NULL, PERIOD_D1, 8, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleD1_8EMA, 0, 0, BufferSize(MABufferD1_8EMA), MABufferD1_8EMA);
   HandleW1_8EMA = iMA(NULL, PERIOD_W1, 8, 0, MODE_EMA, MAPrice);
   CopyBuffer(HandleW1_8EMA, 0, 0, BufferSize(MABufferW1_8EMA), MABufferW1_8EMA);
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
   CopyBuffer(HandleM15_13EMA, 0, 0, BufferSize(MABufferM15_13EMA), MABufferM15_13EMA);
   CopyBuffer(HandleM30_13EMA, 0, 0, BufferSize(MABufferM30_13EMA), MABufferM30_13EMA);
   CopyBuffer(HandleH1_13EMA, 0, 0, BufferSize(MABufferH1_13EMA), MABufferH1_13EMA);
   CopyBuffer(HandleH4_13EMA, 0, 0, BufferSize(MABufferH4_13EMA), MABufferH4_13EMA);
   CopyBuffer(HandleD1_13EMA, 0, 0, BufferSize(MABufferD1_13EMA), MABufferD1_13EMA);
   CopyBuffer(HandleW1_13EMA, 0, 0, BufferSize(MABufferW1_13EMA), MABufferW1_13EMA);
   CopyBuffer(HandleM15_8EMA, 0, 0, BufferSize(MABufferM15_8EMA), MABufferM15_8EMA);
   CopyBuffer(HandleM30_8EMA, 0, 0, BufferSize(MABufferM30_8EMA), MABufferM30_8EMA);
   CopyBuffer(HandleH1_8EMA, 0, 0, BufferSize(MABufferH1_8EMA), MABufferH1_8EMA);
   CopyBuffer(HandleH4_8EMA, 0, 0, BufferSize(MABufferH4_8EMA), MABufferH4_8EMA);
   CopyBuffer(HandleD1_8EMA, 0, 0, BufferSize(MABufferD1_8EMA), MABufferD1_8EMA);
   CopyBuffer(HandleW1_8EMA, 0, 0, BufferSize(MABufferW1_8EMA), MABufferW1_8EMA);
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
