/**=             MTF_MA.mqh  (TyphooN's Multi Timeframe MA Bull/Bear Power Indicator)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.org)
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
// Input variables
#ifdef __MQL5__
input group  "[INFO TEXT SETTINGS]";
#else
input string __grp1__ = "=== INFO TEXT SETTINGS ==="; // [INFO TEXT SETTINGS]
#endif
input string FontName                      = "Courier New";
input int    FontSize                      = 8;
const ENUM_BASE_CORNER Corner              = CORNER_RIGHT_UPPER;
input int    HorizPos                      = 310;
input int    VertPos                       = 130;
ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE;

#ifdef __MQL5__
// Handles (MQL5 only)
int HandleM1_200SMA, HandleM1_50SMA, HandleM1_20SMA, HandleM1_10SMA, HandleM5_200SMA, HandleM5_50SMA, HandleM5_20SMA, HandleM5_10SMA, HandleM15_200SMA, HandleM15_50SMA, HandleM15_20SMA;
int HandleM15_10SMA, HandleM30_200SMA, HandleM30_50SMA, HandleM30_20SMA, HandleM30_10SMA, HandleH1_200SMA, HandleH1_50SMA, HandleH1_20SMA, HandleH1_10SMA, HandleH4_200SMA;
int HandleH4_50SMA, HandleH4_20SMA, HandleH4_10SMA, HandleD1_200SMA, HandleD1_50SMA, HandleD1_20SMA, HandleD1_10SMA, HandleW1_200SMA, HandleW1_50SMA, HandleW1_20SMA, HandleW1_10SMA;
int HandleM1_100SMA, HandleM5_100SMA, HandleM15_100SMA, HandleM30_100SMA, HandleH1_100SMA, HandleH4_100SMA, HandleD1_100SMA, HandleW1_100SMA, HandleMN1_100SMA;
#endif

// Buffers
double MABufferM1_200SMA[], MABufferM1_50SMA[], MABufferM1_20SMA[], MABufferM1_10SMA[], MABufferM5_200SMA[], MABufferM5_50SMA[], MABufferM5_20SMA[], MABufferM5_10SMA[], MABufferM15_200SMA[], MABufferM15_50SMA[], MABufferM15_20SMA[];
double MABufferM15_10SMA[], MABufferM30_200SMA[], MABufferM30_50SMA[], MABufferM30_20SMA[], MABufferM30_10SMA[], MABufferH1_200SMA[], MABufferH1_50SMA[], MABufferH1_20SMA[], MABufferH1_10SMA[], MABufferH4_200SMA[], MABufferH4_50SMA[];
double MABufferH4_20SMA[], MABufferH4_10SMA[], MABufferD1_200SMA[], MABufferD1_50SMA[], MABufferD1_20SMA[], MABufferD1_10SMA[], MABufferW1_200SMA[], MABufferW1_50SMA[], MABufferW1_20SMA[], MABufferW1_10SMA[];
double MABufferM1_100SMA[], MABufferM5_100SMA[], MABufferM15_100SMA[], MABufferM30_100SMA[], MABufferH1_100SMA[], MABufferH4_100SMA[], MABufferD1_100SMA[], MABufferW1_100SMA[], MABufferMN1_100SMA[];
int BullPowerLTF = 0;
int BullPowerHTF = 0;
int BearPowerLTF = 0;
int BearPowerHTF = 0;
int lastCheckedCandle = -1;
double prevBidPrice = 0.0;
double prevAskPrice = 0.0;
string objname = "MTF_MA_";
bool g_dataReady = false;
bool g_objectsCreated = false;
bool g_buffersLoaded = false;
datetime g_prevTime = 0;
int g_prevBullLTF = -1, g_prevBearLTF = -1, g_prevBullHTF = -1, g_prevBearHTF = -1;
// Cached object name strings (8 TFs x 5 labels = 40, plus 4 power labels)
string g_objNames[8][5];  // [tf_index][label_index] for UpdateInfoLabel
string g_nameBullLTF, g_nameBearLTF, g_nameBullHTF, g_nameBearHTF;
// Symbol-qualified GlobalVariable names (prevent cross-chart contamination)
string g_gvBullLTF, g_gvBearLTF, g_gvBullHTF, g_gvBearHTF;
int OnInit()
{
#ifdef __MQL5__
   SetIndexBuffer(0, MABufferH1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(1, MABufferH4_200SMA, INDICATOR_DATA);
   SetIndexBuffer(2, MABufferD1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(3, MABufferW1_200SMA, INDICATOR_DATA);
   SetIndexBuffer(4, MABufferW1_100SMA, INDICATOR_DATA);
   SetIndexBuffer(5, MABufferMN1_100SMA, INDICATOR_DATA);
   SetIndexBuffer(6, MABufferM1_200SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, MABufferM5_200SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, MABufferH4_100SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, MABufferD1_100SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, MABufferM15_200SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, MABufferM30_200SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, MABufferM1_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, MABufferM5_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, MABufferM15_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, MABufferM30_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(16, MABufferH1_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, MABufferH4_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(18, MABufferD1_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(19, MABufferW1_50SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(20, MABufferM1_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(21, MABufferM5_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(22, MABufferM15_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(23, MABufferM30_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(24, MABufferH1_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(25, MABufferH4_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(26, MABufferD1_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(27, MABufferW1_10SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(28, MABufferM1_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(29, MABufferM5_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(30, MABufferM15_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(31, MABufferM30_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(32, MABufferH1_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(33, MABufferH4_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(34, MABufferD1_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(35, MABufferW1_20SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(36, MABufferM1_100SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(37, MABufferM5_100SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(38, MABufferM15_100SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(39, MABufferM30_100SMA, INDICATOR_CALCULATIONS);
   SetIndexBuffer(40, MABufferH1_100SMA, INDICATOR_CALCULATIONS);
   // Create all iMA handles once
   HandleM1_200SMA = iMA(NULL, PERIOD_M1, 200, 0, MODE_SMA, MAPrice);
   HandleM5_200SMA = iMA(NULL, PERIOD_M5, 200, 0, MODE_SMA, MAPrice);
   HandleM15_200SMA = iMA(NULL, PERIOD_M15, 200, 0, MODE_SMA, MAPrice);
   HandleM30_200SMA = iMA(NULL, PERIOD_M30, 200, 0, MODE_SMA, MAPrice);
   HandleH1_200SMA = iMA(NULL, PERIOD_H1, 200, 0, MODE_SMA, MAPrice);
   HandleH4_200SMA = iMA(NULL, PERIOD_H4, 200, 0, MODE_SMA, MAPrice);
   HandleD1_200SMA = iMA(NULL, PERIOD_D1, 200, 0, MODE_SMA, MAPrice);
   HandleW1_200SMA = iMA(NULL, PERIOD_W1, 200, 0, MODE_SMA, MAPrice);
   HandleM1_50SMA = iMA(NULL, PERIOD_M1, 50, 0, MODE_SMA, MAPrice);
   HandleM5_50SMA = iMA(NULL, PERIOD_M5, 50, 0, MODE_SMA, MAPrice);
   HandleM15_50SMA = iMA(NULL, PERIOD_M15, 50, 0, MODE_SMA, MAPrice);
   HandleM30_50SMA = iMA(NULL, PERIOD_M30, 50, 0, MODE_SMA, MAPrice);
   HandleH1_50SMA = iMA(NULL, PERIOD_H1, 50, 0, MODE_SMA, MAPrice);
   HandleH4_50SMA = iMA(NULL, PERIOD_H4, 50, 0, MODE_SMA, MAPrice);
   HandleD1_50SMA = iMA(NULL, PERIOD_D1, 50, 0, MODE_SMA, MAPrice);
   HandleW1_50SMA = iMA(NULL, PERIOD_W1, 50, 0, MODE_SMA, MAPrice);
   HandleM1_20SMA = iMA(NULL, PERIOD_M1, 20, 0, MODE_SMA, MAPrice);
   HandleM5_20SMA = iMA(NULL, PERIOD_M5, 20, 0, MODE_SMA, MAPrice);
   HandleM15_20SMA = iMA(NULL, PERIOD_M15, 20, 0, MODE_SMA, MAPrice);
   HandleM30_20SMA = iMA(NULL, PERIOD_M30, 20, 0, MODE_SMA, MAPrice);
   HandleH1_20SMA = iMA(NULL, PERIOD_H1, 20, 0, MODE_SMA, MAPrice);
   HandleH4_20SMA = iMA(NULL, PERIOD_H4, 20, 0, MODE_SMA, MAPrice);
   HandleD1_20SMA = iMA(NULL, PERIOD_D1, 20, 0, MODE_SMA, MAPrice);
   HandleW1_20SMA = iMA(NULL, PERIOD_W1, 20, 0, MODE_SMA, MAPrice);
   HandleM1_10SMA = iMA(NULL, PERIOD_M1, 10, 0, MODE_SMA, MAPrice);
   HandleM5_10SMA = iMA(NULL, PERIOD_M5, 10, 0, MODE_SMA, MAPrice);
   HandleM15_10SMA = iMA(NULL, PERIOD_M15, 10, 0, MODE_SMA, MAPrice);
   HandleM30_10SMA = iMA(NULL, PERIOD_M30, 10, 0, MODE_SMA, MAPrice);
   HandleH1_10SMA = iMA(NULL, PERIOD_H1, 10, 0, MODE_SMA, MAPrice);
   HandleH4_10SMA = iMA(NULL, PERIOD_H4, 10, 0, MODE_SMA, MAPrice);
   HandleD1_10SMA = iMA(NULL, PERIOD_D1, 10, 0, MODE_SMA, MAPrice);
   HandleW1_10SMA = iMA(NULL, PERIOD_W1, 10, 0, MODE_SMA, MAPrice);
   HandleM1_100SMA = iMA(NULL, PERIOD_M1, 100, 0, MODE_SMA, MAPrice);
   HandleM5_100SMA = iMA(NULL, PERIOD_M5, 100, 0, MODE_SMA, MAPrice);
   HandleM15_100SMA = iMA(NULL, PERIOD_M15, 100, 0, MODE_SMA, MAPrice);
   HandleM30_100SMA = iMA(NULL, PERIOD_M30, 100, 0, MODE_SMA, MAPrice);
   HandleH1_100SMA = iMA(NULL, PERIOD_H1, 100, 0, MODE_SMA, MAPrice);
   HandleH4_100SMA = iMA(NULL, PERIOD_H4, 100, 0, MODE_SMA, MAPrice);
   HandleD1_100SMA = iMA(NULL, PERIOD_D1, 100, 0, MODE_SMA, MAPrice);
   HandleW1_100SMA = iMA(NULL, PERIOD_W1, 100, 0, MODE_SMA, MAPrice);
   HandleMN1_100SMA = iMA(NULL, PERIOD_MN1, 100, 0, MODE_SMA, MAPrice);
   if (HandleM1_200SMA == INVALID_HANDLE || HandleM5_200SMA == INVALID_HANDLE ||
       HandleM15_200SMA == INVALID_HANDLE || HandleM30_200SMA == INVALID_HANDLE ||
       HandleH1_200SMA == INVALID_HANDLE || HandleH4_200SMA == INVALID_HANDLE ||
       HandleD1_200SMA == INVALID_HANDLE || HandleW1_200SMA == INVALID_HANDLE ||
       HandleM1_50SMA == INVALID_HANDLE || HandleM5_50SMA == INVALID_HANDLE ||
       HandleM15_50SMA == INVALID_HANDLE || HandleM30_50SMA == INVALID_HANDLE ||
       HandleH1_50SMA == INVALID_HANDLE || HandleH4_50SMA == INVALID_HANDLE ||
       HandleD1_50SMA == INVALID_HANDLE || HandleW1_50SMA == INVALID_HANDLE ||
       HandleM1_20SMA == INVALID_HANDLE || HandleM5_20SMA == INVALID_HANDLE ||
       HandleM15_20SMA == INVALID_HANDLE || HandleM30_20SMA == INVALID_HANDLE ||
       HandleH1_20SMA == INVALID_HANDLE || HandleH4_20SMA == INVALID_HANDLE ||
       HandleD1_20SMA == INVALID_HANDLE || HandleW1_20SMA == INVALID_HANDLE ||
       HandleM1_10SMA == INVALID_HANDLE || HandleM5_10SMA == INVALID_HANDLE ||
       HandleM15_10SMA == INVALID_HANDLE || HandleM30_10SMA == INVALID_HANDLE ||
       HandleH1_10SMA == INVALID_HANDLE || HandleH4_10SMA == INVALID_HANDLE ||
       HandleD1_10SMA == INVALID_HANDLE || HandleW1_10SMA == INVALID_HANDLE ||
       HandleM1_100SMA == INVALID_HANDLE || HandleM5_100SMA == INVALID_HANDLE ||
       HandleM15_100SMA == INVALID_HANDLE || HandleM30_100SMA == INVALID_HANDLE ||
       HandleH1_100SMA == INVALID_HANDLE || HandleH4_100SMA == INVALID_HANDLE ||
       HandleD1_100SMA == INVALID_HANDLE || HandleW1_100SMA == INVALID_HANDLE ||
       HandleMN1_100SMA == INVALID_HANDLE)
   {
      Print("Failed to create iMA handles");
      return INIT_FAILED;
   }
#else
   // MQL4: SetIndexBuffer with 2-arg form, set styles for 6 plotted lines
   SetIndexBuffer(0, MABufferH1_200SMA);
   SetIndexBuffer(1, MABufferH4_200SMA);
   SetIndexBuffer(2, MABufferD1_200SMA);
   SetIndexBuffer(3, MABufferW1_200SMA);
   SetIndexBuffer(4, MABufferW1_100SMA);
   SetIndexBuffer(5, MABufferMN1_100SMA);
   SetIndexBuffer(6, MABufferM1_200SMA);
   SetIndexBuffer(7, MABufferM5_200SMA);
   SetIndexBuffer(8, MABufferH4_100SMA);
   SetIndexBuffer(9, MABufferD1_100SMA);
   SetIndexBuffer(10, MABufferM15_200SMA);
   SetIndexBuffer(11, MABufferM30_200SMA);
   SetIndexBuffer(12, MABufferM1_50SMA);
   SetIndexBuffer(13, MABufferM5_50SMA);
   SetIndexBuffer(14, MABufferM15_50SMA);
   SetIndexBuffer(15, MABufferM30_50SMA);
   SetIndexBuffer(16, MABufferH1_50SMA);
   SetIndexBuffer(17, MABufferH4_50SMA);
   SetIndexBuffer(18, MABufferD1_50SMA);
   SetIndexBuffer(19, MABufferW1_50SMA);
   SetIndexBuffer(20, MABufferM1_10SMA);
   SetIndexBuffer(21, MABufferM5_10SMA);
   SetIndexBuffer(22, MABufferM15_10SMA);
   SetIndexBuffer(23, MABufferM30_10SMA);
   SetIndexBuffer(24, MABufferH1_10SMA);
   SetIndexBuffer(25, MABufferH4_10SMA);
   SetIndexBuffer(26, MABufferD1_10SMA);
   SetIndexBuffer(27, MABufferW1_10SMA);
   SetIndexBuffer(28, MABufferM1_20SMA);
   SetIndexBuffer(29, MABufferM5_20SMA);
   SetIndexBuffer(30, MABufferM15_20SMA);
   SetIndexBuffer(31, MABufferM30_20SMA);
   SetIndexBuffer(32, MABufferH1_20SMA);
   SetIndexBuffer(33, MABufferH4_20SMA);
   SetIndexBuffer(34, MABufferD1_20SMA);
   SetIndexBuffer(35, MABufferW1_20SMA);
   SetIndexBuffer(36, MABufferM1_100SMA);
   SetIndexBuffer(37, MABufferM5_100SMA);
   SetIndexBuffer(38, MABufferM15_100SMA);
   SetIndexBuffer(39, MABufferM30_100SMA);
   SetIndexBuffer(40, MABufferH1_100SMA);
   // Plot styles for 6 visible lines
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrTomato);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrMagenta);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, clrMagenta);
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 2, clrMagenta);
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 2, clrMagenta);
   SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 2, clrMagenta);
   SetIndexLabel(0, "H1 200SMA");
   SetIndexLabel(1, "H4 200SMA");
   SetIndexLabel(2, "D1 200SMA");
   SetIndexLabel(3, "W1 200SMA");
   SetIndexLabel(4, "W1 100SMA");
   SetIndexLabel(5, "MN1 100SMA");
#endif
   // Reset counters on re-init (timeframe change, recompile)
   BullPowerLTF = 0;
   BullPowerHTF = 0;
   BearPowerLTF = 0;
   BearPowerHTF = 0;
   lastCheckedCandle = -1;
   prevBidPrice = 0.0;
   prevAskPrice = 0.0;
   g_dataReady = false;
   g_objectsCreated = false;
   g_buffersLoaded = false;
   g_prevTime = 0;
   g_prevBullLTF = -1; g_prevBearLTF = -1;
   g_prevBullHTF = -1; g_prevBearHTF = -1;
   // Cache object name strings for UpdateInfoLabel (avoids 40+ string allocations per tick)
   string tfNames[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1"};
   string lblNames[] = {"200SMA", "DEATH", "100_200", "20_50", "10_20"};
   for (int t = 0; t < 8; t++)
      for (int l = 0; l < 5; l++)
         g_objNames[t][l] = objname + tfNames[t] + lblNames[l];
   g_nameBullLTF = objname + "InfoBullPowerLTF";
   g_nameBearLTF = objname + "InfoBearPowerLTF";
   g_nameBullHTF = objname + "InfoBullPowerHTF";
   g_nameBearHTF = objname + "InfoBearPowerHTF";
   // Symbol-qualified GV names (prevent cross-chart contamination)
   g_gvBullLTF = "GlobalBullPowerLTF_" + _Symbol;
   g_gvBearLTF = "GlobalBearPowerLTF_" + _Symbol;
   g_gvBullHTF = "GlobalBullPowerHTF_" + _Symbol;
   g_gvBearHTF = "GlobalBearPowerHTF_" + _Symbol;
   // Clean stale objects from previous instance (crash recovery)
   ObjectsDeleteAll(0, objname);
   return 0;
}
void OnDeinit(const int pReason)
{
   ObjectsDeleteAll(0, objname);
#ifdef __MQL5__
   // Release all 41 iMA handles
   IndicatorRelease(HandleM1_200SMA);  IndicatorRelease(HandleM5_200SMA);
   IndicatorRelease(HandleM15_200SMA); IndicatorRelease(HandleM30_200SMA);
   IndicatorRelease(HandleH1_200SMA);  IndicatorRelease(HandleH4_200SMA);
   IndicatorRelease(HandleD1_200SMA);  IndicatorRelease(HandleW1_200SMA);
   IndicatorRelease(HandleM1_50SMA);   IndicatorRelease(HandleM5_50SMA);
   IndicatorRelease(HandleM15_50SMA);  IndicatorRelease(HandleM30_50SMA);
   IndicatorRelease(HandleH1_50SMA);   IndicatorRelease(HandleH4_50SMA);
   IndicatorRelease(HandleD1_50SMA);   IndicatorRelease(HandleW1_50SMA);
   IndicatorRelease(HandleM1_20SMA);   IndicatorRelease(HandleM5_20SMA);
   IndicatorRelease(HandleM15_20SMA);  IndicatorRelease(HandleM30_20SMA);
   IndicatorRelease(HandleH1_20SMA);   IndicatorRelease(HandleH4_20SMA);
   IndicatorRelease(HandleD1_20SMA);   IndicatorRelease(HandleW1_20SMA);
   IndicatorRelease(HandleM1_10SMA);   IndicatorRelease(HandleM5_10SMA);
   IndicatorRelease(HandleM15_10SMA);  IndicatorRelease(HandleM30_10SMA);
   IndicatorRelease(HandleH1_10SMA);   IndicatorRelease(HandleH4_10SMA);
   IndicatorRelease(HandleD1_10SMA);   IndicatorRelease(HandleW1_10SMA);
   IndicatorRelease(HandleM1_100SMA);  IndicatorRelease(HandleM5_100SMA);
   IndicatorRelease(HandleM15_100SMA); IndicatorRelease(HandleM30_100SMA);
   IndicatorRelease(HandleH1_100SMA);  IndicatorRelease(HandleH4_100SMA);
   IndicatorRelease(HandleD1_100SMA);  IndicatorRelease(HandleW1_100SMA);
   IndicatorRelease(HandleMN1_100SMA);
#endif
   // Clean up GlobalVariables
   GlobalVariableDel(g_gvBullLTF);
   GlobalVariableDel(g_gvBearLTF);
   GlobalVariableDel(g_gvBullHTF);
   GlobalVariableDel(g_gvBearHTF);
}
void UpdateInfoLabel(const string &objnameInfo, bool condition, bool isLTF, bool isHTF)
{
   color textColor = condition ? clrLime : clrRed;
   // Check if the color has changed
   color prevColor = (color)ObjectGetInteger(0, objnameInfo, OBJPROP_COLOR);
   if (prevColor != textColor)
   {
      // Decrement the appropriate variable based on the previous color
      if (prevColor == clrLime)
      {
         if (isLTF) BullPowerLTF--;
         else if (isHTF) BullPowerHTF--;
      }
      else if (prevColor == clrRed)
      {
         if (isLTF) BearPowerLTF--;
         else if (isHTF) BearPowerHTF--;
      }
      // Update the color and count variables
      ObjectSetInteger(0, objnameInfo, OBJPROP_COLOR, textColor);
      if (condition)
      {
         if (isLTF) BullPowerLTF++;
         else if (isHTF) BullPowerHTF++;
      }
      else
      {
         if (isLTF) BearPowerLTF++;
         else if (isHTF) BearPowerHTF++;
      }
      // Recompute totals after increment/decrement, then update colors
      int TotalBearPowerLTF = (BearPowerLTF * 5);
      int TotalBullPowerLTF = (BullPowerLTF * 5);
      int TotalBearPowerHTF = (BearPowerHTF * 5);
      int TotalBullPowerHTF = (BullPowerHTF * 5);
      if (TotalBearPowerHTF > TotalBullPowerHTF)
      {
         ObjectSetInteger(0, g_nameBullHTF, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, g_nameBearHTF, OBJPROP_COLOR, clrRed);
      }
      else if (TotalBullPowerHTF > TotalBearPowerHTF)
      {
         ObjectSetInteger(0, g_nameBullHTF, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, g_nameBearHTF, OBJPROP_COLOR, clrWhite);
      }
      if (TotalBearPowerLTF > TotalBullPowerLTF)
      {
         ObjectSetInteger(0, g_nameBullLTF, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, g_nameBearLTF, OBJPROP_COLOR, clrRed);
      }
      else if (TotalBullPowerLTF > TotalBearPowerLTF)
      {
         ObjectSetInteger(0, g_nameBullLTF, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, g_nameBearLTF, OBJPROP_COLOR, clrWhite);
      }
      if (TotalBullPowerHTF == TotalBearPowerHTF)
      {
         ObjectSetInteger(0, g_nameBullHTF, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, g_nameBearHTF, OBJPROP_COLOR, clrWhite);
      }
      if (TotalBullPowerLTF == TotalBearPowerLTF)
      {
         ObjectSetInteger(0, g_nameBullLTF, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, g_nameBearLTF, OBJPROP_COLOR, clrWhite);
      }
      // Update the labels with the new values
      string BullPowerTextLTF = "LTF Bull Power: " + IntegerToString(TotalBullPowerLTF);
      string BearPowerTextLTF = "LTF Bear Power: " + IntegerToString(TotalBearPowerLTF);
      ObjectSetString(0, g_nameBullLTF, OBJPROP_TEXT, BullPowerTextLTF);
      ObjectSetString(0, g_nameBearLTF, OBJPROP_TEXT, BearPowerTextLTF);
      string BullPowerTextHTF = "HTF Bull Power: " + IntegerToString(TotalBullPowerHTF);
      string BearPowerTextHTF = "HTF Bear Power: " + IntegerToString(TotalBearPowerHTF);
      ObjectSetString(0, g_nameBullHTF, OBJPROP_TEXT, BullPowerTextHTF);
      ObjectSetString(0, g_nameBearHTF, OBJPROP_TEXT, BearPowerTextHTF);
   }
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
   if (rates_total <= 0) return 0;
   // Get the current bid and ask prices
#ifdef __MQL5__
   double currentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
#else
   double currentBidPrice = MarketInfo(_Symbol, MODE_BID);
   double currentAskPrice = MarketInfo(_Symbol, MODE_ASK);
#endif
   // Check if both bid and ask prices have changed from the previous tick
   if (currentBidPrice == prevBidPrice && currentAskPrice == prevAskPrice)
   {
      // If both bid and ask prices are the same as the previous tick, return prev_calculated
      return prev_calculated;
   }
   // Update the previous bid and ask prices with the current prices
   prevBidPrice = currentBidPrice;
   prevAskPrice = currentAskPrice;
#ifdef __MQL5__
   datetime currentTime = TimeTradeServer();
#else
   datetime currentTime = TimeCurrent();
#endif
   // Once buffers have loaded once, trust cached buffer data on intermediate ticks
   bool buffersOk = g_buffersLoaded;
   if (lastCheckedCandle != rates_total - 1)
   {
      lastCheckedCandle = rates_total - 1;
      buffersOk = UpdateBuffers();
      g_prevTime = currentTime;
   }
   else if (!g_buffersLoaded || (int)(currentTime - g_prevTime) >= 60)
   {
      g_prevTime = currentTime;
      buffersOk = UpdateBuffers();
   }
   if (!g_dataReady)
   {
#ifdef __MQL5__
      if (BarsCalculated(HandleM1_200SMA) <= 0 || BarsCalculated(HandleW1_200SMA) <= 0)
         buffersOk = false;
      else
      {
         g_dataReady = true;
         if (!buffersOk) buffersOk = UpdateBuffers();
      }
#else
      if (iBars(_Symbol, PERIOD_M1) <= 0 || iBars(_Symbol, PERIOD_W1) <= 0)
         buffersOk = false;
      else
      {
         g_dataReady = true;
         if (!buffersOk) buffersOk = UpdateBuffers();
      }
#endif
   }
   if (!g_objectsCreated)
   {
   g_objectsCreated = true;
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
   if (ObjectFind(0, g_nameBullLTF) == -1)
   {
      ObjectCreate(0, g_nameBullLTF, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, g_nameBullLTF, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, g_nameBullLTF, OBJPROP_YDISTANCE, VertPos + 65);
      ObjectSetInteger(0, g_nameBullLTF, OBJPROP_CORNER, Corner);
      ObjectSetString(0, g_nameBullLTF, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, g_nameBullLTF, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, g_nameBullLTF, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, g_nameBullLTF, OBJPROP_TEXT, BullPowerTextLTF);
   }
   if (ObjectFind(0, g_nameBearLTF) == -1)
   {
      ObjectCreate(0, g_nameBearLTF, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, g_nameBearLTF, OBJPROP_XDISTANCE, HorizPos - 160);
      ObjectSetInteger(0, g_nameBearLTF, OBJPROP_YDISTANCE, VertPos + 65);
      ObjectSetInteger(0, g_nameBearLTF, OBJPROP_CORNER, Corner);
      ObjectSetString(0, g_nameBearLTF, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, g_nameBearLTF, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, g_nameBearLTF, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, g_nameBearLTF, OBJPROP_TEXT, BearPowerTextLTF);
   }
   if (ObjectFind(0, g_nameBullHTF) == -1)
   {
      ObjectCreate(0, g_nameBullHTF, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, g_nameBullHTF, OBJPROP_XDISTANCE, HorizPos);
      ObjectSetInteger(0, g_nameBullHTF, OBJPROP_YDISTANCE, VertPos + 77);
      ObjectSetInteger(0, g_nameBullHTF, OBJPROP_CORNER, Corner);
      ObjectSetString(0, g_nameBullHTF, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, g_nameBullHTF, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, g_nameBullHTF, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, g_nameBullHTF, OBJPROP_TEXT, BullPowerTextHTF);
   }
   if (ObjectFind(0, g_nameBearHTF) == -1)
   {
      ObjectCreate(0, g_nameBearHTF, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, g_nameBearHTF, OBJPROP_XDISTANCE, HorizPos - 160);
      ObjectSetInteger(0, g_nameBearHTF, OBJPROP_YDISTANCE, VertPos + 77);
      ObjectSetInteger(0, g_nameBearHTF, OBJPROP_CORNER, Corner);
      ObjectSetString(0, g_nameBearHTF, OBJPROP_FONT, FontName);
      ObjectSetInteger(0, g_nameBearHTF, OBJPROP_FONTSIZE, FontSize);
      ObjectSetInteger(0, g_nameBearHTF, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, g_nameBearHTF, OBJPROP_TEXT, BearPowerTextHTF);
   }
   } // objectsCreated
   if (!buffersOk) return prev_calculated;
   if (!g_buffersLoaded) g_buffersLoaded = true;
#ifdef __MQL5__
   double currentPrice = close[rates_total - 1];
   int lastBar = rates_total - 1;
#else
   double currentPrice = close[0];
   int lastBar = 0;
#endif
   // Check the relationship of the current price with the 200-period SMAs
   bool isAbove_M1_200SMA = currentPrice > MABufferM1_200SMA[lastBar];
   bool isAbove_M5_200SMA = currentPrice > MABufferM5_200SMA[lastBar];
   bool isAbove_M15_200SMA = currentPrice > MABufferM15_200SMA[lastBar];
   bool isAbove_M30_200SMA = currentPrice > MABufferM30_200SMA[lastBar];
   bool isAbove_H1_200SMA = currentPrice > MABufferH1_200SMA[lastBar];
   bool isAbove_H4_200SMA = currentPrice > MABufferH4_200SMA[lastBar];
   bool isAbove_D1_200SMA = currentPrice > MABufferD1_200SMA[lastBar];
   bool isAbove_W1_200SMA = currentPrice > MABufferW1_200SMA[lastBar];
   UpdateInfoLabel(g_objNames[0][0], isAbove_M1_200SMA, true, false);
   UpdateInfoLabel(g_objNames[1][0], isAbove_M5_200SMA, true, false);
   UpdateInfoLabel(g_objNames[2][0], isAbove_M15_200SMA, true, false);
   UpdateInfoLabel(g_objNames[3][0], isAbove_M30_200SMA, true, false);
   UpdateInfoLabel(g_objNames[4][0], isAbove_H1_200SMA, false, true);
   UpdateInfoLabel(g_objNames[5][0], isAbove_H4_200SMA, false, true);
   UpdateInfoLabel(g_objNames[6][0], isAbove_D1_200SMA, false, true);
   UpdateInfoLabel(g_objNames[7][0], isAbove_W1_200SMA, false, true);
   // Check for DEATH and GOLDEN crosses
   bool isOnDeathRow_M1 = MABufferM1_50SMA[lastBar] > MABufferM1_200SMA[lastBar];
   bool isOnDeathRow_M5 = MABufferM5_50SMA[lastBar] > MABufferM5_200SMA[lastBar];
   bool isOnDeathRow_M15 = MABufferM15_50SMA[lastBar] > MABufferM15_200SMA[lastBar];
   bool isOnDeathRow_M30 = MABufferM30_50SMA[lastBar] > MABufferM30_200SMA[lastBar];
   bool isOnDeathRow_H1 = MABufferH1_50SMA[lastBar] > MABufferH1_200SMA[lastBar];
   bool isOnDeathRow_H4 = MABufferH4_50SMA[lastBar] > MABufferH4_200SMA[lastBar];
   bool isOnDeathRow_D1 = MABufferD1_50SMA[lastBar] > MABufferD1_200SMA[lastBar];
   bool isOnDeathRow_W1 = MABufferW1_50SMA[lastBar] > MABufferW1_200SMA[lastBar];
   UpdateInfoLabel(g_objNames[0][1], isOnDeathRow_M1, true, false);
   UpdateInfoLabel(g_objNames[1][1], isOnDeathRow_M5, true, false);
   UpdateInfoLabel(g_objNames[2][1], isOnDeathRow_M15, true, false);
   UpdateInfoLabel(g_objNames[3][1], isOnDeathRow_M30, true, false);
   UpdateInfoLabel(g_objNames[4][1], isOnDeathRow_H1, false, true);
   UpdateInfoLabel(g_objNames[5][1], isOnDeathRow_H4, false, true);
   UpdateInfoLabel(g_objNames[6][1], isOnDeathRow_D1, false, true);
   UpdateInfoLabel(g_objNames[7][1], isOnDeathRow_W1, false, true);
   // Check for 100/200 SMA crosses
   bool is100_200cross_M1 = MABufferM1_100SMA[lastBar] > MABufferM1_200SMA[lastBar];
   bool is100_200cross_M5 = MABufferM5_100SMA[lastBar] > MABufferM5_200SMA[lastBar];
   bool is100_200cross_M15 = MABufferM15_100SMA[lastBar] > MABufferM15_200SMA[lastBar];
   bool is100_200cross_M30 = MABufferM30_100SMA[lastBar] > MABufferM30_200SMA[lastBar];
   bool is100_200cross_H1 = MABufferH1_100SMA[lastBar] > MABufferH1_200SMA[lastBar];
   bool is100_200cross_H4 = MABufferH4_100SMA[lastBar] > MABufferH4_200SMA[lastBar];
   bool is100_200cross_D1 = MABufferD1_100SMA[lastBar] > MABufferD1_200SMA[lastBar];
   bool is100_200cross_W1 = MABufferW1_100SMA[lastBar] > MABufferW1_200SMA[lastBar];
   UpdateInfoLabel(g_objNames[0][2], is100_200cross_M1, true, false);
   UpdateInfoLabel(g_objNames[1][2], is100_200cross_M5, true, false);
   UpdateInfoLabel(g_objNames[2][2], is100_200cross_M15, true, false);
   UpdateInfoLabel(g_objNames[3][2], is100_200cross_M30, true, false);
   UpdateInfoLabel(g_objNames[4][2], is100_200cross_H1, false, true);
   UpdateInfoLabel(g_objNames[5][2], is100_200cross_H4, false, true);
   UpdateInfoLabel(g_objNames[6][2], is100_200cross_D1, false, true);
   UpdateInfoLabel(g_objNames[7][2], is100_200cross_W1, false, true);
   // Check for 20 SMA / 50 SMA crosses
   bool is20_50cross_M1 = MABufferM1_20SMA[lastBar] > MABufferM1_50SMA[lastBar];
   bool is20_50cross_M5 = MABufferM5_20SMA[lastBar] > MABufferM5_50SMA[lastBar];
   bool is20_50cross_M15 = MABufferM15_20SMA[lastBar] > MABufferM15_50SMA[lastBar];
   bool is20_50cross_M30 = MABufferM30_20SMA[lastBar] > MABufferM30_50SMA[lastBar];
   bool is20_50cross_H1 = MABufferH1_20SMA[lastBar] > MABufferH1_50SMA[lastBar];
   bool is20_50cross_H4 = MABufferH4_20SMA[lastBar] > MABufferH4_50SMA[lastBar];
   bool is20_50cross_D1 = MABufferD1_20SMA[lastBar] > MABufferD1_50SMA[lastBar];
   bool is20_50cross_W1 = MABufferW1_20SMA[lastBar] > MABufferW1_50SMA[lastBar];
   UpdateInfoLabel(g_objNames[0][3], is20_50cross_M1, true, false);
   UpdateInfoLabel(g_objNames[1][3], is20_50cross_M5, true, false);
   UpdateInfoLabel(g_objNames[2][3], is20_50cross_M15, true, false);
   UpdateInfoLabel(g_objNames[3][3], is20_50cross_M30, true, false);
   UpdateInfoLabel(g_objNames[4][3], is20_50cross_H1, false, true);
   UpdateInfoLabel(g_objNames[5][3], is20_50cross_H4, false, true);
   UpdateInfoLabel(g_objNames[6][3], is20_50cross_D1, false, true);
   UpdateInfoLabel(g_objNames[7][3], is20_50cross_W1, false, true);
   // Check for 10 SMA / 20 SMA crosses
   bool is10_20cross_M1 = MABufferM1_10SMA[lastBar] > MABufferM1_20SMA[lastBar];
   bool is10_20cross_M5 = MABufferM5_10SMA[lastBar] > MABufferM5_20SMA[lastBar];
   bool is10_20cross_M15 = MABufferM15_10SMA[lastBar] > MABufferM15_20SMA[lastBar];
   bool is10_20cross_M30 = MABufferM30_10SMA[lastBar] > MABufferM30_20SMA[lastBar];
   bool is10_20cross_H1 = MABufferH1_10SMA[lastBar] > MABufferH1_20SMA[lastBar];
   bool is10_20cross_H4 = MABufferH4_10SMA[lastBar] > MABufferH4_20SMA[lastBar];
   bool is10_20cross_D1 = MABufferD1_10SMA[lastBar] > MABufferD1_20SMA[lastBar];
   bool is10_20cross_W1 = MABufferW1_10SMA[lastBar] > MABufferW1_20SMA[lastBar];
   UpdateInfoLabel(g_objNames[0][4], is10_20cross_M1, true, false);
   UpdateInfoLabel(g_objNames[1][4], is10_20cross_M5, true, false);
   UpdateInfoLabel(g_objNames[2][4], is10_20cross_M15, true, false);
   UpdateInfoLabel(g_objNames[3][4], is10_20cross_M30, true, false);
   UpdateInfoLabel(g_objNames[4][4], is10_20cross_H1, false, true);
   UpdateInfoLabel(g_objNames[5][4], is10_20cross_H4, false, true);
   UpdateInfoLabel(g_objNames[6][4], is10_20cross_D1, false, true);
   UpdateInfoLabel(g_objNames[7][4], is10_20cross_W1, false, true);
   // Only update GVs when values change
   int bullLTF = BullPowerLTF * 5, bearLTF = BearPowerLTF * 5;
   int bullHTF = BullPowerHTF * 5, bearHTF = BearPowerHTF * 5;
   if (bullLTF != g_prevBullLTF) { GlobalVariableSet(g_gvBullLTF, bullLTF); g_prevBullLTF = bullLTF; }
   if (bearLTF != g_prevBearLTF) { GlobalVariableSet(g_gvBearLTF, bearLTF); g_prevBearLTF = bearLTF; }
   if (bullHTF != g_prevBullHTF) { GlobalVariableSet(g_gvBullHTF, bullHTF); g_prevBullHTF = bullHTF; }
   if (bearHTF != g_prevBearHTF) { GlobalVariableSet(g_gvBearHTF, bearHTF); g_prevBearHTF = bearHTF; }
   return rates_total;
}

bool UpdateBuffers()
{
   bool ok = true;
#ifdef __MQL5__
   ok &= (CopyBuffer(HandleM1_200SMA, 0, 0, ArraySize(MABufferM1_200SMA), MABufferM1_200SMA) > 0);
   ok &= (CopyBuffer(HandleM5_200SMA, 0, 0, ArraySize(MABufferM5_200SMA), MABufferM5_200SMA) > 0);
   ok &= (CopyBuffer(HandleM15_200SMA, 0, 0, ArraySize(MABufferM15_200SMA), MABufferM15_200SMA) > 0);
   ok &= (CopyBuffer(HandleM30_200SMA, 0, 0, ArraySize(MABufferM30_200SMA), MABufferM30_200SMA) > 0);
   ok &= (CopyBuffer(HandleH1_200SMA, 0, 0, ArraySize(MABufferH1_200SMA), MABufferH1_200SMA) > 0);
   ok &= (CopyBuffer(HandleH4_200SMA, 0, 0, ArraySize(MABufferH4_200SMA), MABufferH4_200SMA) > 0);
   ok &= (CopyBuffer(HandleD1_200SMA, 0, 0, ArraySize(MABufferD1_200SMA), MABufferD1_200SMA) > 0);
   ok &= (CopyBuffer(HandleW1_200SMA, 0, 0, ArraySize(MABufferW1_200SMA), MABufferW1_200SMA) > 0);
   ok &= (CopyBuffer(HandleM1_50SMA, 0, 0, ArraySize(MABufferM1_50SMA), MABufferM1_50SMA) > 0);
   ok &= (CopyBuffer(HandleM5_50SMA, 0, 0, ArraySize(MABufferM5_50SMA), MABufferM5_50SMA) > 0);
   ok &= (CopyBuffer(HandleM15_50SMA, 0, 0, ArraySize(MABufferM15_50SMA), MABufferM15_50SMA) > 0);
   ok &= (CopyBuffer(HandleM30_50SMA, 0, 0, ArraySize(MABufferM30_50SMA), MABufferM30_50SMA) > 0);
   ok &= (CopyBuffer(HandleH1_50SMA, 0, 0, ArraySize(MABufferH1_50SMA), MABufferH1_50SMA) > 0);
   ok &= (CopyBuffer(HandleH4_50SMA, 0, 0, ArraySize(MABufferH4_50SMA), MABufferH4_50SMA) > 0);
   ok &= (CopyBuffer(HandleD1_50SMA, 0, 0, ArraySize(MABufferD1_50SMA), MABufferD1_50SMA) > 0);
   ok &= (CopyBuffer(HandleW1_50SMA, 0, 0, ArraySize(MABufferW1_50SMA), MABufferW1_50SMA) > 0);
   ok &= (CopyBuffer(HandleM1_20SMA, 0, 0, ArraySize(MABufferM1_20SMA), MABufferM1_20SMA) > 0);
   ok &= (CopyBuffer(HandleM5_20SMA, 0, 0, ArraySize(MABufferM5_20SMA), MABufferM5_20SMA) > 0);
   ok &= (CopyBuffer(HandleM15_20SMA, 0, 0, ArraySize(MABufferM15_20SMA), MABufferM15_20SMA) > 0);
   ok &= (CopyBuffer(HandleM30_20SMA, 0, 0, ArraySize(MABufferM30_20SMA), MABufferM30_20SMA) > 0);
   ok &= (CopyBuffer(HandleH1_20SMA, 0, 0, ArraySize(MABufferH1_20SMA), MABufferH1_20SMA) > 0);
   ok &= (CopyBuffer(HandleH4_20SMA, 0, 0, ArraySize(MABufferH4_20SMA), MABufferH4_20SMA) > 0);
   ok &= (CopyBuffer(HandleD1_20SMA, 0, 0, ArraySize(MABufferD1_20SMA), MABufferD1_20SMA) > 0);
   ok &= (CopyBuffer(HandleW1_20SMA, 0, 0, ArraySize(MABufferW1_20SMA), MABufferW1_20SMA) > 0);
   ok &= (CopyBuffer(HandleM1_10SMA, 0, 0, ArraySize(MABufferM1_10SMA), MABufferM1_10SMA) > 0);
   ok &= (CopyBuffer(HandleM5_10SMA, 0, 0, ArraySize(MABufferM5_10SMA), MABufferM5_10SMA) > 0);
   ok &= (CopyBuffer(HandleM15_10SMA, 0, 0, ArraySize(MABufferM15_10SMA), MABufferM15_10SMA) > 0);
   ok &= (CopyBuffer(HandleM30_10SMA, 0, 0, ArraySize(MABufferM30_10SMA), MABufferM30_10SMA) > 0);
   ok &= (CopyBuffer(HandleH1_10SMA, 0, 0, ArraySize(MABufferH1_10SMA), MABufferH1_10SMA) > 0);
   ok &= (CopyBuffer(HandleH4_10SMA, 0, 0, ArraySize(MABufferH4_10SMA), MABufferH4_10SMA) > 0);
   ok &= (CopyBuffer(HandleD1_10SMA, 0, 0, ArraySize(MABufferD1_10SMA), MABufferD1_10SMA) > 0);
   ok &= (CopyBuffer(HandleW1_10SMA, 0, 0, ArraySize(MABufferW1_10SMA), MABufferW1_10SMA) > 0);
   ok &= (CopyBuffer(HandleM1_100SMA, 0, 0, ArraySize(MABufferM1_100SMA), MABufferM1_100SMA) > 0);
   ok &= (CopyBuffer(HandleM5_100SMA, 0, 0, ArraySize(MABufferM5_100SMA), MABufferM5_100SMA) > 0);
   ok &= (CopyBuffer(HandleM15_100SMA, 0, 0, ArraySize(MABufferM15_100SMA), MABufferM15_100SMA) > 0);
   ok &= (CopyBuffer(HandleM30_100SMA, 0, 0, ArraySize(MABufferM30_100SMA), MABufferM30_100SMA) > 0);
   ok &= (CopyBuffer(HandleH1_100SMA, 0, 0, ArraySize(MABufferH1_100SMA), MABufferH1_100SMA) > 0);
   ok &= (CopyBuffer(HandleH4_100SMA, 0, 0, ArraySize(MABufferH4_100SMA), MABufferH4_100SMA) > 0);
   ok &= (CopyBuffer(HandleD1_100SMA, 0, 0, ArraySize(MABufferD1_100SMA), MABufferD1_100SMA) > 0);
   ok &= (CopyBuffer(HandleW1_100SMA, 0, 0, ArraySize(MABufferW1_100SMA), MABufferW1_100SMA) > 0);
   // MN1 100SMA is a plotted line only (not used in bull/bear power grid) -- don't let it block the dashboard
   CopyBuffer(HandleMN1_100SMA, 0, 0, ArraySize(MABufferMN1_100SMA), MABufferMN1_100SMA);
#else
   // MQL4: direct iMA() calls -- only fetch bar 0 for calc-only buffers (dashboard grid)
   // Plotted buffers (6): fill all visible bars for chart line rendering
   int total = ArraySize(MABufferH1_200SMA);
   for (int i = 0; i < total; i++)
   {
      MABufferH1_200SMA[i]  = iMA(NULL, PERIOD_H1,  200, 0, MODE_SMA, PRICE_CLOSE, i);
      MABufferH4_200SMA[i]  = iMA(NULL, PERIOD_H4,  200, 0, MODE_SMA, PRICE_CLOSE, i);
      MABufferD1_200SMA[i]  = iMA(NULL, PERIOD_D1,  200, 0, MODE_SMA, PRICE_CLOSE, i);
      MABufferW1_200SMA[i]  = iMA(NULL, PERIOD_W1,  200, 0, MODE_SMA, PRICE_CLOSE, i);
      MABufferW1_100SMA[i]  = iMA(NULL, PERIOD_W1,  100, 0, MODE_SMA, PRICE_CLOSE, i);
      MABufferMN1_100SMA[i] = iMA(NULL, PERIOD_MN1, 100, 0, MODE_SMA, PRICE_CLOSE, i);
   }
   // Calculation-only buffers: only bar 0 matters for the dashboard grid
   MABufferM1_200SMA[0]  = iMA(NULL, PERIOD_M1,  200, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM5_200SMA[0]  = iMA(NULL, PERIOD_M5,  200, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM15_200SMA[0] = iMA(NULL, PERIOD_M15, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM30_200SMA[0] = iMA(NULL, PERIOD_M30, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM1_50SMA[0]   = iMA(NULL, PERIOD_M1,   50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM5_50SMA[0]   = iMA(NULL, PERIOD_M5,   50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM15_50SMA[0]  = iMA(NULL, PERIOD_M15,  50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM30_50SMA[0]  = iMA(NULL, PERIOD_M30,  50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH1_50SMA[0]   = iMA(NULL, PERIOD_H1,   50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH4_50SMA[0]   = iMA(NULL, PERIOD_H4,   50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferD1_50SMA[0]   = iMA(NULL, PERIOD_D1,   50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferW1_50SMA[0]   = iMA(NULL, PERIOD_W1,   50, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM1_20SMA[0]   = iMA(NULL, PERIOD_M1,   20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM5_20SMA[0]   = iMA(NULL, PERIOD_M5,   20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM15_20SMA[0]  = iMA(NULL, PERIOD_M15,  20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM30_20SMA[0]  = iMA(NULL, PERIOD_M30,  20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH1_20SMA[0]   = iMA(NULL, PERIOD_H1,   20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH4_20SMA[0]   = iMA(NULL, PERIOD_H4,   20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferD1_20SMA[0]   = iMA(NULL, PERIOD_D1,   20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferW1_20SMA[0]   = iMA(NULL, PERIOD_W1,   20, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM1_10SMA[0]   = iMA(NULL, PERIOD_M1,   10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM5_10SMA[0]   = iMA(NULL, PERIOD_M5,   10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM15_10SMA[0]  = iMA(NULL, PERIOD_M15,  10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM30_10SMA[0]  = iMA(NULL, PERIOD_M30,  10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH1_10SMA[0]   = iMA(NULL, PERIOD_H1,   10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH4_10SMA[0]   = iMA(NULL, PERIOD_H4,   10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferD1_10SMA[0]   = iMA(NULL, PERIOD_D1,   10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferW1_10SMA[0]   = iMA(NULL, PERIOD_W1,   10, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM1_100SMA[0]  = iMA(NULL, PERIOD_M1,  100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM5_100SMA[0]  = iMA(NULL, PERIOD_M5,  100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM15_100SMA[0] = iMA(NULL, PERIOD_M15, 100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferM30_100SMA[0] = iMA(NULL, PERIOD_M30, 100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH1_100SMA[0]  = iMA(NULL, PERIOD_H1,  100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferH4_100SMA[0]  = iMA(NULL, PERIOD_H4,  100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferD1_100SMA[0]  = iMA(NULL, PERIOD_D1,  100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferW1_100SMA[0]  = iMA(NULL, PERIOD_W1,  100, 0, MODE_SMA, PRICE_CLOSE, 0);
   MABufferMN1_100SMA[0] = iMA(NULL, PERIOD_MN1, 100, 0, MODE_SMA, PRICE_CLOSE, 0);
#endif
   return ok;
}
