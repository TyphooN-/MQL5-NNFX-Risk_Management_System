/**=             AutoFibonacci.mqh  (TyphooN's Auto Fibonacci Indicator)
 *               Copyright 2026, TyphooN (https://www.marketwizardry.org/)
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
//  Fractal-based Auto Fibonacci — finds most significant recent swing
//  high/low and draws retracement (0-100%) + extension (127.2-423.6%) levels.
//  Mirrors the TyphooN-Terminal calcAutoFibonacci() implementation exactly.
//
//  O(1) per bar: after initial build, each new bar only checks one
//  candidate fractal, prunes old fractals, and redraws only on change.
//+------------------------------------------------------------------+

//--- Inputs
input int    InpFractalLookback  = 10;          // Fractal Lookback (bars each side)
input double InpRecentPct        = 0.6;         // Recent portion of chart to search (0.0-1.0)
input color  InpRetracementColor = clrGold;     // Retracement Level Color
input color  InpExtensionColor   = clrDodgerBlue; // Extension Level Color
input color  InpSwingLineColor   = clrWhite;    // Swing High/Low Line Color
input ENUM_LINE_STYLE InpLineStyle = STYLE_DOT; // Line Style
input int    InpLineWidth        = 1;           // Line Width
input bool   InpShowLabels       = true;        // Show Level Labels
input string InpFontName         = "Courier New"; // Label Font
input int    InpFontSize         = 8;           // Label Font Size

//--- Constants
const string PREFIX = "AutoFib#";

//--- Swing point struct
struct SSwing
{
   double   price;
   datetime time;
};

//--- Fib level struct
struct SFibLevel
{
   double   ratio;
   string   label;
   bool     isExtension;
};

//--- Globals
datetime g_lastBarTime = 0;
bool     g_fibInitialized = false;

//--- Persistent swing lists
SSwing   g_swingHighs[];
SSwing   g_swingLows[];
int      g_highCount = 0;
int      g_lowCount  = 0;

//--- Cached best swing points for change detection
double   g_prevBestHighPrice = 0;
double   g_prevBestLowPrice  = 0;
datetime g_prevBestHighTime  = 0;
datetime g_prevBestLowTime   = 0;
datetime g_prevEndTime       = 0;

//+------------------------------------------------------------------+
//| Fib levels (retracement + extension)                              |
//+------------------------------------------------------------------+
SFibLevel g_levels[];
int       g_levelCount = 0;

void InitLevels()
{
   g_levelCount = 13;
   ArrayResize(g_levels, g_levelCount);
   g_levels[0].ratio  = 0.0;    g_levels[0].label  = "0%";      g_levels[0].isExtension  = false;
   g_levels[1].ratio  = 0.236;  g_levels[1].label  = "23.6%";   g_levels[1].isExtension  = false;
   g_levels[2].ratio  = 0.382;  g_levels[2].label  = "38.2%";   g_levels[2].isExtension  = false;
   g_levels[3].ratio  = 0.5;    g_levels[3].label  = "50%";     g_levels[3].isExtension  = false;
   g_levels[4].ratio  = 0.618;  g_levels[4].label  = "61.8%";   g_levels[4].isExtension  = false;
   g_levels[5].ratio  = 0.786;  g_levels[5].label  = "78.6%";   g_levels[5].isExtension  = false;
   g_levels[6].ratio  = 1.0;    g_levels[6].label  = "100%";    g_levels[6].isExtension  = false;
   g_levels[7].ratio  = 1.272;  g_levels[7].label  = "127.2%";  g_levels[7].isExtension  = true;
   g_levels[8].ratio  = 1.618;  g_levels[8].label  = "161.8%";  g_levels[8].isExtension  = true;
   g_levels[9].ratio  = 2.0;    g_levels[9].label  = "200%";    g_levels[9].isExtension  = true;
   g_levels[10].ratio = 2.618;  g_levels[10].label = "261.8%";  g_levels[10].isExtension = true;
   g_levels[11].ratio = 3.618;  g_levels[11].label = "361.8%";  g_levels[11].isExtension = true;
   g_levels[12].ratio = 4.236;  g_levels[12].label = "423.6%";  g_levels[12].isExtension = true;
}

//+------------------------------------------------------------------+
//| Initialization                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpFractalLookback < 1)
      return INIT_PARAMETERS_INCORRECT;

   InitLevels();
   g_lastBarTime = 0;
   g_fibInitialized = false;
   g_highCount = 0;
   g_lowCount = 0;
   ArrayResize(g_swingHighs, 0, 64);
   ArrayResize(g_swingLows, 0, 64);
   g_prevBestHighPrice = 0;
   g_prevBestLowPrice = 0;
   g_prevBestHighTime = 0;
   g_prevBestLowTime = 0;
   g_prevEndTime = 0;

#ifdef __MQL5__
   IndicatorSetString(INDICATOR_SHORTNAME,
      "AutoFib(" + IntegerToString(InpFractalLookback) + ")");
#else
   IndicatorShortName("AutoFib(" + IntegerToString(InpFractalLookback) + ")");
#endif

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, PREFIX);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Main calculation                                                  |
//+------------------------------------------------------------------+
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
   if(rates_total < InpFractalLookback * 2 + 10)
      return 0;

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low,  true);
   ArraySetAsSeries(close, true);

   //--- Only recalculate on new bar
   if(time[0] == g_lastBarTime)
      return rates_total;
   g_lastBarTime = time[0];

   int recentBar = (int)MathFloor(rates_total * InpRecentPct);
   datetime cutoffTime = time[recentBar < rates_total ? recentBar : rates_total - 1];

   if(!g_fibInitialized)
   {
      //--- Full scan on first run
      g_highCount = 0;
      g_lowCount = 0;
      ArrayResize(g_swingHighs, 0, 64);
      ArrayResize(g_swingLows, 0, 64);

      int limit = rates_total - InpFractalLookback;
      for(int i = InpFractalLookback; i < limit; i++)
      {
         if(IsFractalHigh(high, i, InpFractalLookback, rates_total))
         {
            g_highCount++;
            if (ArrayResize(g_swingHighs, g_highCount, 64) == -1) { g_highCount--; continue; }
            g_swingHighs[g_highCount - 1].price = high[i];
            g_swingHighs[g_highCount - 1].time  = time[i];
         }
         if(IsFractalLow(low, i, InpFractalLookback, rates_total))
         {
            g_lowCount++;
            if (ArrayResize(g_swingLows, g_lowCount, 64) == -1) { g_lowCount--; continue; }
            g_swingLows[g_lowCount - 1].price = low[i];
            g_swingLows[g_lowCount - 1].time  = time[i];
         }
      }
      g_fibInitialized = true;
   }
   else
   {
      //--- O(1) incremental: check the one new candidate bar
      int candidate = InpFractalLookback;
      if(candidate < rates_total - InpFractalLookback)
      {
         if(IsFractalHigh(high, candidate, InpFractalLookback, rates_total))
         {
            g_highCount++;
            if (ArrayResize(g_swingHighs, g_highCount, 64) != -1)
            {
               g_swingHighs[g_highCount - 1].price = high[candidate];
               g_swingHighs[g_highCount - 1].time  = time[candidate];
            }
            else g_highCount--;
         }
         if(IsFractalLow(low, candidate, InpFractalLookback, rates_total))
         {
            g_lowCount++;
            if (ArrayResize(g_swingLows, g_lowCount, 64) != -1)
            {
               g_swingLows[g_lowCount - 1].price = low[candidate];
               g_swingLows[g_lowCount - 1].time  = time[candidate];
            }
            else g_lowCount--;
         }
      }

      //--- Prune fractals older than cutoff (outside recent portion)
      PruneSwings(g_swingHighs, g_highCount, cutoffTime);
      PruneSwings(g_swingLows, g_lowCount, cutoffTime);
   }

   if(g_highCount == 0 || g_lowCount == 0)
   {
      //--- No valid swings — clear drawing
      if(g_prevBestHighPrice != 0 || g_prevBestLowPrice != 0)
      {
         ObjectsDeleteAll(0, PREFIX);
         g_prevBestHighPrice = 0;
         g_prevBestLowPrice = 0;
         g_prevBestHighTime = 0;
         g_prevBestLowTime = 0;
      }
      return rates_total;
   }

   //--- Find highest high and lowest low in stored swings
   //--- (only considers fractals in the recent portion — old ones pruned above)
   SSwing bestHigh, bestLow;
   bool foundHigh = false, foundLow = false;

   for(int i = 0; i < g_highCount; i++)
   {
      if(g_swingHighs[i].time >= cutoffTime)
      {
         if(!foundHigh || g_swingHighs[i].price > bestHigh.price)
         {
            bestHigh = g_swingHighs[i];
            foundHigh = true;
         }
      }
   }
   for(int i = 0; i < g_lowCount; i++)
   {
      if(g_swingLows[i].time >= cutoffTime)
      {
         if(!foundLow || g_swingLows[i].price < bestLow.price)
         {
            bestLow = g_swingLows[i];
            foundLow = true;
         }
      }
   }

   if(!foundHigh || !foundLow)
   {
      if(g_prevBestHighPrice != 0 || g_prevBestLowPrice != 0)
      {
         ObjectsDeleteAll(0, PREFIX);
         g_prevBestHighPrice = 0;
         g_prevBestLowPrice = 0;
      }
      return rates_total;
   }

   double highPrice = bestHigh.price;
   double lowPrice  = bestLow.price;
   double range     = highPrice - lowPrice;
   if(range <= 0)
      return rates_total;

   datetime endTime = time[0];
   bool bestChanged = (bestHigh.price != g_prevBestHighPrice ||
                       bestLow.price  != g_prevBestLowPrice  ||
                       bestHigh.time  != g_prevBestHighTime   ||
                       bestLow.time   != g_prevBestLowTime);

   if(bestChanged)
   {
      //--- Full redraw: best swing points changed
      ObjectsDeleteAll(0, PREFIX);

      //--- Determine bull or bear: low came before high in time = bullish
      bool isBull = (bestLow.time < bestHigh.time);

      //--- Draw start/end times
      datetime startTime = MathMin(bestHigh.time, bestLow.time);

      //--- Draw swing high/low connector
      string swingName = PREFIX + "Swing";
      if (!ObjectCreate(0, swingName, OBJ_TREND, 0,
         bestLow.time, bestLow.price, bestHigh.time, bestHigh.price))
      { int err = GetLastError(); if (err != 4200) Print("AutoFib: failed to create swing line: ", err); }
      ObjectSetInteger(0, swingName, OBJPROP_COLOR, InpSwingLineColor);
      ObjectSetInteger(0, swingName, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, swingName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, swingName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, swingName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, swingName, OBJPROP_BACK, true);

      //--- Draw each Fibonacci level
      DrawFibLevels(highPrice, lowPrice, range, isBull, startTime, endTime);

      g_prevBestHighPrice = bestHigh.price;
      g_prevBestLowPrice  = bestLow.price;
      g_prevBestHighTime  = bestHigh.time;
      g_prevBestLowTime   = bestLow.time;
      g_prevEndTime       = endTime;

      ChartRedraw(0);
   }
   else if(endTime != g_prevEndTime)
   {
      //--- Same swing points, just extend end time (right edge of fib levels)
      bool isBull = (bestLow.time < bestHigh.time);
      datetime startTime = MathMin(bestHigh.time, bestLow.time);

      //--- Update swing line end point (extend to newest bar visually)
      //--- Level lines: update end time
      for(int lv = 0; lv < g_levelCount; lv++)
      {
         string lineName = PREFIX + "L" + IntegerToString(lv);
         if(ObjectFind(0, lineName) != -1)
         {
            double price = ComputeFibPrice(lv, highPrice, lowPrice, range, isBull);
            ObjectMove(0, lineName, 1, endTime, price);
         }
         if(InpShowLabels)
         {
            string labelName = PREFIX + "T" + IntegerToString(lv);
            if(ObjectFind(0, labelName) != -1)
               ObjectSetInteger(0, labelName, OBJPROP_TIME, endTime);
         }
      }
      g_prevEndTime = endTime;
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Compute fib price for a given level index                         |
//+------------------------------------------------------------------+
double ComputeFibPrice(int lv, double highPrice, double lowPrice, double range, bool isBull)
{
   if(isBull)
   {
      if(g_levels[lv].isExtension && g_levels[lv].ratio > 1.0)
         return lowPrice + range * g_levels[lv].ratio;
      else
         return highPrice - range * g_levels[lv].ratio;
   }
   else
   {
      if(g_levels[lv].isExtension && g_levels[lv].ratio > 1.0)
         return highPrice - range * g_levels[lv].ratio;
      else
         return lowPrice + range * g_levels[lv].ratio;
   }
}

//+------------------------------------------------------------------+
//| Draw all Fibonacci levels                                         |
//+------------------------------------------------------------------+
void DrawFibLevels(double highPrice, double lowPrice, double range,
                   bool isBull, datetime startTime, datetime endTime)
{
   for(int lv = 0; lv < g_levelCount; lv++)
   {
      double price = ComputeFibPrice(lv, highPrice, lowPrice, range, isBull);
      color lineColor = g_levels[lv].isExtension ? InpExtensionColor : InpRetracementColor;

      string lineName = PREFIX + "L" + IntegerToString(lv);
      if (!ObjectCreate(0, lineName, OBJ_TREND, 0, startTime, price, endTime, price))
      { int err = GetLastError(); if (err != 4200) Print("AutoFib: failed to create level '", lineName, "': ", err); }
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, lineName, OBJPROP_STYLE, InpLineStyle);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, InpLineWidth);
      ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
#ifdef __MQL5__
      ObjectSetString(0, lineName, OBJPROP_TOOLTIP,
         g_levels[lv].label + " @ " + DoubleToString(price, _Digits));
#endif

      if(InpShowLabels)
      {
         string labelName = PREFIX + "T" + IntegerToString(lv);
         if (!ObjectCreate(0, labelName, OBJ_TEXT, 0, 0, 0))
         { int err = GetLastError(); if (err != 4200) Print("AutoFib: failed to create label '", labelName, "': ", err); }
         ObjectSetInteger(0, labelName, OBJPROP_TIME, endTime);
         ObjectSetDouble(0, labelName, OBJPROP_PRICE, price);
         ObjectSetString(0, labelName, OBJPROP_TEXT,
            g_levels[lv].label + " " + DoubleToString(price, _Digits));
         ObjectSetString(0, labelName, OBJPROP_FONT, InpFontName);
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, InpFontSize);
         ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
         ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_RIGHT);
         ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Prune swings older than cutoff time                               |
//+------------------------------------------------------------------+
void PruneSwings(SSwing &swings[], int &count, datetime cutoffTime)
{
   int writeIdx = 0;
   for(int i = 0; i < count; i++)
   {
      if(swings[i].time >= cutoffTime)
      {
         if(writeIdx != i)
            swings[writeIdx] = swings[i];
         writeIdx++;
      }
   }
   if(writeIdx != count)
   {
      count = writeIdx;
      ArrayResize(swings, count, 64);
   }
}

//+------------------------------------------------------------------+
//| Fractal high detection (matches TyphooN-Terminal exactly)         |
//+------------------------------------------------------------------+
bool IsFractalHigh(const double &high[], int bar, int lookback, int total)
{
   double val = high[bar];
   for(int i = 1; i <= lookback; i++)
   {
      if(bar - i < 0 || bar + i >= total)
         return false;
      if(high[bar - i] >= val || high[bar + i] >= val)
         return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Fractal low detection (matches TyphooN-Terminal exactly)          |
//+------------------------------------------------------------------+
bool IsFractalLow(const double &low[], int bar, int lookback, int total)
{
   double val = low[bar];
   for(int i = 1; i <= lookback; i++)
   {
      if(bar - i < 0 || bar + i >= total)
         return false;
      if(low[bar - i] <= val || low[bar + i] <= val)
         return false;
   }
   return true;
}
//+------------------------------------------------------------------+
