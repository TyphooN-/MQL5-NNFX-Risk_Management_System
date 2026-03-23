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
   int      idx;
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

   //--- Clean previous objects
   ObjectsDeleteAll(0, PREFIX);

   //--- Find all fractal swing highs and lows
   SSwing swingHighs[];
   SSwing swingLows[];
   int highCount = 0, lowCount = 0;

   int limit = rates_total - InpFractalLookback;
   for(int i = InpFractalLookback; i < limit; i++)
   {
      if(IsFractalHigh(high, i, InpFractalLookback, rates_total))
      {
         highCount++;
         ArrayResize(swingHighs, highCount, 64);
         swingHighs[highCount - 1].idx   = i;
         swingHighs[highCount - 1].price = high[i];
         swingHighs[highCount - 1].time  = time[i];
      }
      if(IsFractalLow(low, i, InpFractalLookback, rates_total))
      {
         lowCount++;
         ArrayResize(swingLows, lowCount, 64);
         swingLows[lowCount - 1].idx   = i;
         swingLows[lowCount - 1].price = low[i];
         swingLows[lowCount - 1].time  = time[i];
      }
   }

   if(highCount == 0 || lowCount == 0)
      return rates_total;

   //--- Filter to recent portion of chart (series indexing: 0 = newest)
   int recentBar = (int)MathFloor(rates_total * InpRecentPct);

   //--- Find highest high and lowest low in the recent portion
   //--- In series mode, bar 0 = newest, bar N = oldest. "Recent" = small bar indices.
   SSwing bestHigh, bestLow;
   bool foundHigh = false, foundLow = false;

   for(int i = 0; i < highCount; i++)
   {
      if(swingHighs[i].idx <= recentBar)
      {
         if(!foundHigh || swingHighs[i].price > bestHigh.price)
         {
            bestHigh = swingHighs[i];
            foundHigh = true;
         }
      }
   }
   for(int i = 0; i < lowCount; i++)
   {
      if(swingLows[i].idx <= recentBar)
      {
         if(!foundLow || swingLows[i].price < bestLow.price)
         {
            bestLow = swingLows[i];
            foundLow = true;
         }
      }
   }

   if(!foundHigh || !foundLow)
      return rates_total;

   double highPrice = bestHigh.price;
   double lowPrice  = bestLow.price;
   double range     = highPrice - lowPrice;
   if(range <= 0)
      return rates_total;

   //--- Determine bull or bear: in series mode, smaller idx = more recent
   //--- Bull = low came before high in time (low has larger idx in series)
   bool isBull = (bestLow.idx > bestHigh.idx);  // larger idx = older = came first

   //--- Draw start/end times
   datetime startTime = MathMin(bestHigh.time, bestLow.time);
   datetime endTime   = time[0];

   //--- Draw swing high/low connector
   string swingName = PREFIX + "Swing";
   ObjectCreate(0, swingName, OBJ_TREND, 0,
      bestLow.time, bestLow.price, bestHigh.time, bestHigh.price);
   ObjectSetInteger(0, swingName, OBJPROP_COLOR, InpSwingLineColor);
   ObjectSetInteger(0, swingName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, swingName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, swingName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, swingName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, swingName, OBJPROP_BACK, true);

   //--- Draw each Fibonacci level
   for(int lv = 0; lv < g_levelCount; lv++)
   {
      double price;
      if(isBull)
      {
         // Bull: retrace from high toward low; extensions above high
         if(g_levels[lv].isExtension && g_levels[lv].ratio > 1.0)
            price = lowPrice + range * g_levels[lv].ratio;
         else
            price = highPrice - range * g_levels[lv].ratio;
      }
      else
      {
         // Bear: retrace from low toward high; extensions below low
         if(g_levels[lv].isExtension && g_levels[lv].ratio > 1.0)
            price = highPrice - range * g_levels[lv].ratio;
         else
            price = lowPrice + range * g_levels[lv].ratio;
      }

      color lineColor = g_levels[lv].isExtension ? InpExtensionColor : InpRetracementColor;

      //--- Draw the horizontal level line
      string lineName = PREFIX + "L" + IntegerToString(lv);
      ObjectCreate(0, lineName, OBJ_TREND, 0, startTime, price, endTime, price);
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

      //--- Draw label
      if(InpShowLabels)
      {
         string labelName = PREFIX + "T" + IntegerToString(lv);
         ObjectCreate(0, labelName, OBJ_TEXT, 0, 0, 0);
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

   ChartRedraw(0);
   return rates_total;
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
