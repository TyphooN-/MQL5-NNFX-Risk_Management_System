/**=              MTF_200SMA.mq5  (TyphooN's Multi Timeframe 200SMA)
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
#property version   "1.009"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   9
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
#property indicator_label9  "D1 13SMA"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrWhite
#property indicator_style9  STYLE_SOLID
#property indicator_width9  2
// Input variables
input bool Enable_H1_200SMA = true;
input bool Enable_H4_200SMA = true;
input bool Enable_D1_200SMA = true;
input bool Enable_W1_200SMA = true;
input bool Enable_M1_200SMA = true;
input bool Enable_M5_200SMA = true;
input bool Enable_M15_200SMA = true;
input bool Enable_M30_200SMA = true;
input bool Enable_D1_13SMA = true;
input bool W1_Empty_Warning = false;
int MAPeriod = 200;
ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE;
// Handles
int HandleH1, HandleH4, HandleD1, HandleW1, HandleM1, HandleM5, HandleM15, HandleM30, HandleD1_13SMA;
// Buffers
double MABufferH1[], MABufferH4[], MABufferD1[], MABufferW1[], MABufferM1[], MABufferM5[], MABufferM15[], MABufferM30[], MABufferD1_13SMA[];
bool W1_Enable, M1_Enable, M5_Enable, M15_Enable, M30_Enable;
bool isTimerSet = false;
int lastCheckedCandle = -1;
int OnInit()
{
   W1_Enable = Enable_W1_200SMA;
   //--- indicator buffers mapping
   SetIndexBuffer(0, MABufferH1, INDICATOR_DATA);
   SetIndexBuffer(1, MABufferH4, INDICATOR_DATA);
   SetIndexBuffer(2, MABufferD1, INDICATOR_DATA);
   SetIndexBuffer(3, MABufferW1, INDICATOR_DATA);
   SetIndexBuffer(4, MABufferM1, INDICATOR_DATA);
   SetIndexBuffer(5, MABufferM5, INDICATOR_DATA);
   SetIndexBuffer(6, MABufferM15, INDICATOR_DATA);
   SetIndexBuffer(7, MABufferM30, INDICATOR_DATA);
   SetIndexBuffer(8, MABufferD1_13SMA, INDICATOR_DATA);
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
   EraseBufferValues(MABufferM1);
   EraseBufferValues(MABufferM5);
   EraseBufferValues(MABufferM15);
   EraseBufferValues(MABufferM30);
   EraseBufferValues(MABufferH1);
   EraseBufferValues(MABufferH4);
   EraseBufferValues(MABufferD1);
   EraseBufferValues(MABufferW1);
   EraseBufferValues(MABufferD1_13SMA);
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
      HandleM1 = iMA(NULL, PERIOD_M1, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM1, 0, 0, BufferSize(MABufferM1), MABufferM1);
   }
   if (M5_Enable)
   {
      HandleM5 = iMA(NULL, PERIOD_M5, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM5, 0, 0, BufferSize(MABufferM5), MABufferM5);
   }
   if (M15_Enable)
   {
      HandleM15 = iMA(NULL, PERIOD_M15, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM15, 0, 0, BufferSize(MABufferM15), MABufferM15);
   }
   if (M30_Enable)
   {
      HandleM30 = iMA(NULL, PERIOD_M30, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleM30, 0, 0, BufferSize(MABufferM30), MABufferM30);
   }
   if (Enable_H1_200SMA)
   {
      HandleH1 = iMA(NULL, PERIOD_H1, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleH1, 0, 0, BufferSize(MABufferH1), MABufferH1);
   }
   if (Enable_H4_200SMA)
   {
      HandleH4 = iMA(NULL, PERIOD_H4, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleH4, 0, 0, BufferSize(MABufferH4), MABufferH4);
   }
   if (Enable_D1_200SMA)
   {
      HandleD1 = iMA(NULL, PERIOD_D1, MAPeriod, 0, MODE_SMA, MAPrice);
      CopyBuffer(HandleD1, 0, 0, BufferSize(MABufferD1), MABufferD1);
   }
   if (Enable_D1_13SMA)
   {
      HandleD1_13SMA = iMA(NULL, PERIOD_D1, 13, 0, MODE_SMA, MAPrice);  // 13 period SMA
      CopyBuffer(HandleD1_13SMA, 0, 0, BufferSize(MABufferD1_13SMA), MABufferD1_13SMA);
   }
   if (Enable_W1_200SMA)
   {
      HandleW1 = iMA(NULL, PERIOD_W1, MAPeriod, 0, MODE_SMA, MAPrice);
      if (HandleW1 != INVALID_HANDLE)
      {
         int copySizeW1 = CopyBuffer(HandleW1, 0, 0, BufferSize(MABufferW1), MABufferW1);
         if (copySizeW1 > 0)
         {
            bool isEmptyValueExist = false;
            for (int i = 0; i < copySizeW1; i++)
            {
               if (MABufferW1[i] == EMPTY_VALUE)
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
         HandleM1 = iMA(NULL, PERIOD_M1, MAPeriod, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM1, 0, 0, BufferSize(MABufferM1), MABufferM1);
      }
      if (M5_Enable)
      {
         HandleM5 = iMA(NULL, PERIOD_M5, MAPeriod, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM5, 0, 0, BufferSize(MABufferM5), MABufferM5);
      }
      if (M15_Enable)
      {
         HandleM15 = iMA(NULL, PERIOD_M15, MAPeriod, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM15, 0, 0, BufferSize(MABufferM15), MABufferM15);
      }
      if (M30_Enable)
      {
         HandleM30 = iMA(NULL, PERIOD_M30, MAPeriod, 0, MODE_SMA, MAPrice);
         CopyBuffer(HandleM30, 0, 0, BufferSize(MABufferM30), MABufferM30);
      }
   }
   if (_Period >= PERIOD_D1)
   {
      EraseBufferValues(MABufferM1);
      EraseBufferValues(MABufferM5);
      EraseBufferValues(MABufferM15);
      EraseBufferValues(MABufferM30);
   }
   if (Enable_H1_200SMA)
      CopyBuffer(HandleH1, 0, 0, BufferSize(MABufferH1), MABufferH1);
   if (Enable_H4_200SMA)
      CopyBuffer(HandleH4, 0, 0, BufferSize(MABufferH4), MABufferH4);
   if (Enable_D1_200SMA)
      CopyBuffer(HandleD1, 0, 0, BufferSize(MABufferD1), MABufferD1);
   if (Enable_W1_200SMA)
   {
      HandleW1 = iMA(NULL, PERIOD_W1, MAPeriod, 0, MODE_SMA, MAPrice);
      if (HandleW1 != INVALID_HANDLE)
      {
         int copySizeW1 = CopyBuffer(HandleW1, 0, 0, BufferSize(MABufferW1), MABufferW1);
         if (copySizeW1 > 0)
         {
            bool isEmptyValueExist = false;
            for (int i = 0; i < copySizeW1; i++)
            {
               if (MABufferW1[i] == EMPTY_VALUE)
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
