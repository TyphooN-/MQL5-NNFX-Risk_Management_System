/**=                 MTF_SMA.mq5  (TyphooN's Multi Timeframe SMA)
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
#property version   "1.014"
#property indicator_chart_window
#property indicator_buffers 13
#property indicator_plots   13
#property indicator_label1  "H1 200SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta
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
#property indicator_label5  "M1 200SMA"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrOrange
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
#property indicator_label6  "M5 200SMA"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrOrange
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
#property indicator_label7  "M15 200SMA"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrOrange
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2
#property indicator_label8  "M30 200SMA"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrOrange
#property indicator_style8  STYLE_SOLID
#property indicator_width8  2
#property indicator_label9  "M15 13SMA"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrWhite
#property indicator_style9  STYLE_SOLID
#property indicator_width9  2
#property indicator_label10  "M30 13SMA"
#property indicator_type10   DRAW_LINE
#property indicator_color10  clrWhite
#property indicator_style10  STYLE_SOLID
#property indicator_width10  2
#property indicator_label11  "H1 13SMA"
#property indicator_type11   DRAW_LINE
#property indicator_color11  clrWhite
#property indicator_style11  STYLE_SOLID
#property indicator_width11  2
#property indicator_label12  "H4 13SMA"
#property indicator_type12   DRAW_LINE
#property indicator_color12  clrWhite
#property indicator_style12  STYLE_SOLID
#property indicator_width12  2
#property indicator_label13  "D1 13SMA"
#property indicator_type13   DRAW_LINE
#property indicator_color13  clrWhite
#property indicator_style13  STYLE_SOLID
#property indicator_width13  2
#property indicator_label14  "W1 13SMA"
#property indicator_type14   DRAW_LINE
#property indicator_color14  clrWhite
#property indicator_style14  STYLE_SOLID
#property indicator_width14  2
// Input variables
input group "Long Term MAs (Support and Resistance)"
input bool Enable_H1_200SMA = true;
input bool Enable_H4_200SMA = true;
input bool Enable_D1_200SMA = true;
input bool Enable_W1_200SMA = true;
input bool Enable_M1_200SMA = true;
input bool Enable_M5_200SMA = true;
input bool Enable_M15_200SMA = true;
input bool Enable_M30_200SMA = true;
input group "Short Term MAs (Trend Confirmation)"
input bool Enable_M15_13SMA = true;
input bool Enable_M30_13SMA = true;
input bool Enable_H1_13SMA = true;
input bool Enable_H4_13SMA = true;
input bool Enable_D1_13SMA = true;
input bool Enable_W1_13SMA = true;
bool W1_Empty_Warning = false;
ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE;
// Handles
int HandleH1_200SMA, HandleH4_200SMA, HandleD1_200SMA, HandleW1_200SMA, HandleM1_200SMA, HandleM5_200SMA, HandleM15_200SMA, HandleM15_13SMA, HandleM30_200SMA, HandleM30_13SMA, HandleH1_13SMA, HandleH4_13SMA, HandleD1_13SMA, HandleW1_13SMA;
// Buffers
double MABufferH1_200SMA[], MABufferH4_200SMA[], MABufferD1_200SMA[], MABufferW1_200SMA[], MABufferM1_200SMA[], MABufferM5_200SMA[], MABufferM15_200SMA[], MABufferM15_13SMA[], MABufferM30_200SMA[], MABufferM30_13SMA[],  MABufferH1_13SMA[], MABufferH4_13SMA[], MABufferD1_13SMA[], MABufferW1_13SMA[];
bool W1_Enable, M1_Enable, M5_Enable, M15_Enable, M30_Enable;
bool isTimerSet = false;
int lastCheckedCandle = -1;
int OnInit()
{
   W1_Enable = Enable_W1_200SMA;
   //--- indicator buffers mapping
   SetIndexBuffer(0, MABufferH1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(1, MABufferH4_200SMA, INDICATOR_DATA);
   SetIndexBuffer(2, MABufferD1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(3, MABufferW1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(4, MABufferM1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(5, MABufferM5_200SMA, INDICATOR_DATA);
   SetIndexBuffer(6, MABufferM15_200SMA, INDICATOR_DATA);
   SetIndexBuffer(7, MABufferM30_200SMA, INDICATOR_DATA);
   SetIndexBuffer(8, MABufferM15_13SMA, INDICATOR_DATA);
   SetIndexBuffer(9, MABufferM30_13SMA, INDICATOR_DATA);
   SetIndexBuffer(10, MABufferH1_13SMA, INDICATOR_DATA);
   SetIndexBuffer(11, MABufferH4_13SMA, INDICATOR_DATA);
   SetIndexBuffer(12, MABufferD1_13SMA, INDICATOR_DATA);
   SetIndexBuffer(13, MABufferW1_13SMA, INDICATOR_DATA);
   
   return 0;
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
   EraseBufferValues(MABufferM15_13SMA);
   EraseBufferValues(MABufferM30_13SMA);
   EraseBufferValues(MABufferH1_13SMA);
   EraseBufferValues(MABufferH4_13SMA);
   EraseBufferValues(MABufferD1_13SMA);
   EraseBufferValues(MABufferW1_13SMA);
   if (_Period < PERIOD_D1)
   {
      M1_Enable = Enable_M1_200SMA;
      M5_Enable = Enable_M5_200SMA;
      M15_Enable = Enable_M15_200SMA;
      M30_Enable = Enable_M30_200SMA;
   }
   if (_Period >= PERIOD_D1)
   {
      M1_Enable = false;
      M5_Enable = false;
      M15_Enable = false;
      M30_Enable = false;
   }
   if (M1_Enable)
   {
      HandleM1_200SMA = iMA(NULL, PERIOD_M1, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM1_200SMA, 0, 0, BufferSize(MABufferM1_200SMA), MABufferM1_200SMA);
   }
   if (M5_Enable)
   {
      HandleM5_200SMA = iMA(NULL, PERIOD_M5, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM5_200SMA, 0, 0, BufferSize(MABufferM5_200SMA), MABufferM5_200SMA);
   }
   if (M15_Enable)
   {
      HandleM15_200SMA = iMA(NULL, PERIOD_M15, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM15_200SMA, 0, 0, BufferSize(MABufferM15_200SMA), MABufferM15_200SMA);
   }
   if (M30_Enable)
   {
      HandleM30_200SMA = iMA(NULL, PERIOD_M30, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM30_200SMA, 0, 0, BufferSize(MABufferM30_200SMA), MABufferM30_200SMA);
   }
   if (Enable_H1_200SMA)
   {
      HandleH1_200SMA = iMA(NULL, PERIOD_H1, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleH1_200SMA, 0, 0, BufferSize(MABufferH1_200SMA), MABufferH1_200SMA);
   }
   if (Enable_H4_200SMA)
   {
      HandleH4_200SMA = iMA(NULL, PERIOD_H4, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleH4_200SMA, 0, 0, BufferSize(MABufferH4_200SMA), MABufferH4_200SMA);
   }
   if (Enable_D1_200SMA)
   {
      HandleD1_200SMA = iMA(NULL, PERIOD_D1, 200, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleD1_200SMA, 0, 0, BufferSize(MABufferD1_200SMA), MABufferD1_200SMA);
   }
   if (Enable_D1_13SMA)
   {
      HandleD1_13SMA = iMA(NULL, PERIOD_D1, 13, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleD1_13SMA, 0, 0, BufferSize(MABufferD1_13SMA), MABufferD1_13SMA);
   }
   if (Enable_H1_13SMA)
   {
      HandleH1_13SMA = iMA(NULL, PERIOD_H1, 13, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleH1_13SMA, 0, 0, BufferSize(MABufferH1_13SMA), MABufferH1_13SMA);
   }
   if (Enable_H4_13SMA)
   {
      HandleH4_13SMA = iMA(NULL, PERIOD_H4, 13, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleH4_13SMA, 0, 0, BufferSize(MABufferH4_13SMA), MABufferH4_13SMA);
   }
   if (Enable_M15_13SMA)
   {
      HandleM15_13SMA = iMA(NULL, PERIOD_M15, 13, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM15_13SMA, 0, 0, BufferSize(MABufferM15_13SMA), MABufferM15_13SMA);
   }
   if (Enable_M30_13SMA)
   {
      HandleM30_13SMA = iMA(NULL, PERIOD_M30, 13, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM30_13SMA, 0, 0, BufferSize(MABufferM30_13SMA), MABufferM30_13SMA);
   }
   if (Enable_W1_13SMA)
   {
      HandleW1_13SMA = iMA(NULL, PERIOD_W1, 13, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleW1_13SMA, 0, 0, BufferSize(MABufferW1_13SMA), MABufferW1_13SMA);
   }
   if (Enable_W1_200SMA)
   {
      HandleW1_200SMA = iMA(NULL, PERIOD_W1, 200, 0, MODE_SMA, MAPrice);
      if (HandleW1_200SMA != INVALID_HANDLE)
      {
         int copySizeW1 = CopyBuffer(HandleW1_200SMA, 0, 0, BufferSize(MABufferW1_200SMA), MABufferW1_200SMA);
         if (copySizeW1 > 0)
         {
            bool isEmptyValueExist = false;
            for (int i = 0; i < copySizeW1; i++)
            {
               if (MABufferW1_200SMA[i] == EMPTY_VALUE)
               {
                  isEmptyValueExist = true;
                  break;
               }
            }
            if (isEmptyValueExist)
            {
               if (W1_Empty_Warning)
               {
                  // Print("Warning: W1 SMA data contains EMPTY_VALUE!");
               }
            }
         }
      }
      else
      {
         Print("Warning: Unable to calculate W1 SMA! Disabling!");
         W1_Enable = false;
      }
   }
}
void UpdateBuffersOnCalculate(int start, int rates_total)
{
   if (_Period < PERIOD_D1)
   {
      if (M1_Enable)
      {
         HandleM1_200SMA = iMA(NULL, PERIOD_M1, 200, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM1_200SMA, 0, 0, BufferSize(MABufferM1_200SMA), MABufferM1_200SMA);
      }
      if (M5_Enable)
      {
         HandleM5_200SMA = iMA(NULL, PERIOD_M5, 200, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM5_200SMA, 0, 0, BufferSize(MABufferM5_200SMA), MABufferM5_200SMA);
      }
      if (M15_Enable)
      {
         HandleM15_200SMA = iMA(NULL, PERIOD_M15, 200, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM15_200SMA, 0, 0, BufferSize(MABufferM15_200SMA), MABufferM15_200SMA);
      }
      if (M30_Enable)
      {
         HandleM30_200SMA = iMA(NULL, PERIOD_M30, 200, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM30_200SMA, 0, 0, BufferSize(MABufferM30_200SMA), MABufferM30_200SMA);
      }
   }
   if (_Period >= PERIOD_D1)
   {
      EraseBufferValues(MABufferM1_200SMA);
      EraseBufferValues(MABufferM5_200SMA);
      EraseBufferValues(MABufferM15_200SMA);
      EraseBufferValues(MABufferM30_200SMA);
   }
   if (Enable_H1_200SMA)
      CopyBuffer(HandleH1_200SMA, 0, 0, BufferSize(MABufferH1_200SMA), MABufferH1_200SMA);
   if (Enable_H4_200SMA)
      CopyBuffer(HandleH4_200SMA, 0, 0, BufferSize(MABufferH4_200SMA), MABufferH4_200SMA);
   if (Enable_D1_200SMA)
      CopyBuffer(HandleD1_200SMA, 0, 0, BufferSize(MABufferD1_200SMA), MABufferD1_200SMA);
   if (Enable_M15_13SMA)
      CopyBuffer(HandleM15_13SMA, 0, 0, BufferSize(MABufferM15_13SMA), MABufferM15_13SMA);
   if (Enable_M30_13SMA)
      CopyBuffer(HandleM30_13SMA, 0, 0, BufferSize(MABufferM30_13SMA), MABufferM30_13SMA);
   if (Enable_H1_13SMA)
      CopyBuffer(HandleH1_13SMA, 0, 0, BufferSize(MABufferH1_13SMA), MABufferH1_13SMA);
   if (Enable_H4_13SMA)
      CopyBuffer(HandleH4_13SMA, 0, 0, BufferSize(MABufferH4_13SMA), MABufferH4_13SMA);
   if (Enable_D1_13SMA)
      CopyBuffer(HandleD1_13SMA, 0, 0, BufferSize(MABufferD1_13SMA), MABufferD1_13SMA);
   if (Enable_W1_13SMA)
      CopyBuffer(HandleW1_13SMA, 0, 0, BufferSize(MABufferW1_13SMA), MABufferW1_13SMA);
   if (Enable_W1_200SMA)
   {
      HandleW1_200SMA = iMA(NULL, PERIOD_W1, 200, 0, MODE_SMA, MAPrice);
      if (HandleW1_200SMA != INVALID_HANDLE)
      {
         int copySizeW1 = CopyBuffer(HandleW1_200SMA, 0, 0, BufferSize(MABufferW1_200SMA), MABufferW1_200SMA);
         if (copySizeW1 > 0)
         {
            bool isEmptyValueExist = false;
            for (int i = 0; i < copySizeW1; i++)
            {
               if (MABufferW1_200SMA[i] == EMPTY_VALUE)
               {
                  isEmptyValueExist = true;
                  break;
               }
            }
            if (isEmptyValueExist)
            {
               if (W1_Empty_Warning)
               {
                  // Print("Warning: W1 SMA data contains EMPTY_VALUE!");
               }
            }
         }
      }
      else
      {
         Print("Warning: Unable to calculate W1 SMA! Disabling!");
         W1_Enable = false;
      }
   }
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
