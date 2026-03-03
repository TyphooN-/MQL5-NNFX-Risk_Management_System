//+------------------------------------------------------------------+
//|                                               SupplyDemand.mqh   |
//|                    Clean MQL5/MQL4 Supply & Demand Zone Indicator |
//|                    Body-to-wick zones, fractal detection          |
//+------------------------------------------------------------------+
//  Draws supply/demand zones on chart using OBJ_RECTANGLE objects.
//  Zones are detected at fractal highs/lows with body-to-wick bounds.
//  Strength tiers: UNTESTED -> TESTED -> PROVEN -> BROKEN
//+------------------------------------------------------------------+

//--- Enums
enum ENUM_ZONE_TYPE
{
   ZONE_SUPPLY = 0,
   ZONE_DEMAND = 1
};

enum ENUM_ZONE_STRENGTH
{
   ZONE_UNTESTED = 0,   // 0 touches
   ZONE_TESTED   = 1,   // 1-2 touches
   ZONE_PROVEN   = 2,   // 3+ touches
   ZONE_BROKEN   = 3    // close pierced boundary
};

//--- Zone struct
struct SZone
{
   double            hi;
   double            lo;
   datetime          startTime;
   int               fractalBar;   // bar index at creation (valid within same recalc)
   int               touchCount;
   ENUM_ZONE_TYPE    type;
   ENUM_ZONE_STRENGTH strength;
};

//--- Inputs
input int    InpFractalLookback  = 5;       // Fractal Lookback (bars each side)
input int    InpBackLimit        = 1000;    // Max History Bars
input bool   InpShowBroken       = false;   // Show Broken Zones
input bool   InpMergeZones       = true;    // Merge Overlapping Zones
input bool   InpShowLabels       = true;    // Show Zone Labels
input bool   InpZoneFill         = true;    // Fill Zones
input int    InpZoneBorderWidth  = 1;       // Zone Border Width

input string __sep1__            = "";      // --- Supply Colors ---
input color  InpSupUntested      = clrSkyBlue;      // Supply Untested
input color  InpSupTested        = clrDeepSkyBlue;  // Supply Tested
input color  InpSupProven        = clrDodgerBlue;   // Supply Proven

input string __sep2__            = "";      // --- Demand Colors ---
input color  InpDemUntested      = clrDarkSeaGreen; // Demand Untested
input color  InpDemTested        = clrMediumSeaGreen;// Demand Tested
input color  InpDemProven        = clrSeaGreen;      // Demand Proven

input color  InpBrokenColor      = clrDimGray;       // Broken Zone Color

input string __sep3__            = "";      // --- Alerts ---
input bool   InpAlertPopup       = false;   // Alert Popup
input bool   InpAlertSound       = false;   // Alert Sound
input int    InpAlertCooldown    = 300;     // Alert Cooldown (seconds)

//--- Constants
const string PREFIX = "SD#";

//--- Globals
SZone        g_zones[];
int          g_zoneCount    = 0;
datetime     g_lastBarTime  = 0;
datetime     g_lastAlertTime = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpFractalLookback < 1 || InpBackLimit < 1)
      return INIT_PARAMETERS_INCORRECT;

   g_lastBarTime = 0;
   g_lastAlertTime = 0;

#ifdef __MQL5__
   IndicatorSetString(INDICATOR_SHORTNAME, "SupplyDemand(" +
      IntegerToString(InpFractalLookback) + "," +
      IntegerToString(InpBackLimit) + ")");
#else
   IndicatorShortName("SupplyDemand(" +
      IntegerToString(InpFractalLookback) + "," +
      IntegerToString(InpBackLimit) + ")");
#endif
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, PREFIX);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
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
   if(rates_total < InpFractalLookback * 2 + 1)
      return 0;

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   //--- New-bar gate for full recalc
   if(time[0] != g_lastBarTime)
   {
      g_lastBarTime = time[0];

      //--- Full rebuild
      ObjectsDeleteAll(0, PREFIX);
      g_zoneCount = 0;
      ArrayResize(g_zones, 0, 128);

      int limit = MathMin(InpBackLimit, rates_total - InpFractalLookback - 1);

      //--- Find fractal zones
      FindZones(open, high, low, close, time, limit);

      //--- Test zones against price action
      TestZones(high, low, close, limit);

      //--- Merge overlapping same-type zones
      if(InpMergeZones)
         MergeZones();

      //--- Draw zones to the current bar (right edge)
      datetime currentTime = time[0];
      DrawAllZones(currentTime);

      if(InpShowLabels)
         DrawAllLabels(currentTime);
   }

   //--- Alerts run every tick (with cooldown)
   if(InpAlertPopup || InpAlertSound)
      CheckAlerts(close[0], high[0], low[0]);

   return rates_total;
}

//+------------------------------------------------------------------+
//| Fractal detection                                                 |
//+------------------------------------------------------------------+
bool IsFractalHigh(const double &high[], int bar, int lookback, int limit)
{
   double val = high[bar];
   for(int i = 1; i <= lookback; i++)
   {
      if(bar - i < 0 || bar + i > limit)
         return false;
      if(high[bar - i] >= val || high[bar + i] >= val)
         return false;
   }
   return true;
}

bool IsFractalLow(const double &low[], int bar, int lookback, int limit)
{
   double val = low[bar];
   for(int i = 1; i <= lookback; i++)
   {
      if(bar - i < 0 || bar + i > limit)
         return false;
      if(low[bar - i] <= val || low[bar + i] <= val)
         return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Find fractal zones and add to array                               |
//+------------------------------------------------------------------+
void FindZones(const double &open[], const double &high[],
               const double &low[], const double &close[],
               const datetime &time[], int limit)
{
   for(int i = InpFractalLookback; i <= limit - InpFractalLookback; i++)
   {
      //--- Supply zone at fractal high
      if(IsFractalHigh(high, i, InpFractalLookback, limit))
      {
         SZone zone;
         zone.hi         = high[i];
         zone.lo         = MathMin(close[i], open[i]);
         if(zone.hi - zone.lo < _Point)
            zone.lo = zone.hi - _Point;
         zone.startTime  = time[i];
         zone.fractalBar = i;
         zone.touchCount = 0;
         zone.type       = ZONE_SUPPLY;
         zone.strength   = ZONE_UNTESTED;
         AddZone(zone);
      }

      //--- Demand zone at fractal low
      if(IsFractalLow(low, i, InpFractalLookback, limit))
      {
         SZone zone;
         zone.hi         = MathMax(close[i], open[i]);
         zone.lo         = low[i];
         if(zone.hi - zone.lo < _Point)
            zone.hi = zone.lo + _Point;
         zone.startTime  = time[i];
         zone.fractalBar = i;
         zone.touchCount = 0;
         zone.type       = ZONE_DEMAND;
         zone.strength   = ZONE_UNTESTED;
         AddZone(zone);
      }
   }
}

//+------------------------------------------------------------------+
//| Add zone to dynamic array                                         |
//+------------------------------------------------------------------+
void AddZone(SZone &zone)
{
   g_zoneCount++;
   ArrayResize(g_zones, g_zoneCount, 128);
   g_zones[g_zoneCount - 1] = zone;
}

//+------------------------------------------------------------------+
//| Test zones against subsequent price action                        |
//+------------------------------------------------------------------+
void TestZones(const double &high[], const double &low[],
               const double &close[], int limit)
{
   for(int z = g_zoneCount - 1; z >= 0; z--)
   {
      //--- Scan bars after the fractal formation window
      //--- Skip the fractal bar and its lookback neighbors to avoid inflating touches
      int scanFrom = g_zones[z].fractalBar - InpFractalLookback - 1;
      if(scanFrom < 0) scanFrom = 0;

      for(int b = scanFrom; b >= 0; b--)
      {
         //--- Does this bar's range overlap the zone?
         if(high[b] >= g_zones[z].lo && low[b] <= g_zones[z].hi)
         {
            //--- Check for break (close pierces beyond zone boundary)
            if(g_zones[z].type == ZONE_SUPPLY && close[b] > g_zones[z].hi)
            {
               g_zones[z].strength = ZONE_BROKEN;
               break;
            }
            if(g_zones[z].type == ZONE_DEMAND && close[b] < g_zones[z].lo)
            {
               g_zones[z].strength = ZONE_BROKEN;
               break;
            }

            //--- Count touch
            g_zones[z].touchCount++;
         }
      }

      //--- Set strength based on touches (if not broken)
      if(g_zones[z].strength != ZONE_BROKEN)
      {
         if(g_zones[z].touchCount == 0)
            g_zones[z].strength = ZONE_UNTESTED;
         else if(g_zones[z].touchCount <= 2)
            g_zones[z].strength = ZONE_TESTED;
         else
            g_zones[z].strength = ZONE_PROVEN;
      }
   }

   //--- Remove broken zones if not showing them
   if(!InpShowBroken)
      PurgeBrokenZones();
}

//+------------------------------------------------------------------+
//| Remove broken zones from array                                    |
//+------------------------------------------------------------------+
void PurgeBrokenZones()
{
   int writeIdx = 0;
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength != ZONE_BROKEN)
      {
         if(writeIdx != i)
            g_zones[writeIdx] = g_zones[i];
         writeIdx++;
      }
   }
   g_zoneCount = writeIdx;
   ArrayResize(g_zones, g_zoneCount, 128);
}

//+------------------------------------------------------------------+
//| Merge overlapping zones of the same type (sort-and-sweep O(n lg n))
//+------------------------------------------------------------------+
void MergeZones()
{
   if(g_zoneCount < 2) return;

   //--- Sort zones by type (supply first), then by lo ascending
   SortZones();

   int writeIdx = 0;
   for(int i = 1; i < g_zoneCount; i++)
   {
      //--- Same type and overlapping?
      if(g_zones[i].type == g_zones[writeIdx].type &&
         g_zones[i].lo <= g_zones[writeIdx].hi)
      {
         //--- Merge into writeIdx
         g_zones[writeIdx].hi = MathMax(g_zones[writeIdx].hi, g_zones[i].hi);
         g_zones[writeIdx].lo = MathMin(g_zones[writeIdx].lo, g_zones[i].lo);
         g_zones[writeIdx].touchCount += g_zones[i].touchCount;
         if(g_zones[i].startTime < g_zones[writeIdx].startTime)
            g_zones[writeIdx].startTime = g_zones[i].startTime;
         if(g_zones[i].strength == ZONE_BROKEN)
            g_zones[writeIdx].strength = ZONE_BROKEN;
      }
      else
      {
         writeIdx++;
         if(writeIdx != i)
            g_zones[writeIdx] = g_zones[i];
      }
   }
   g_zoneCount = writeIdx + 1;
   ArrayResize(g_zones, g_zoneCount, 128);

   //--- Update strength for all merged zones
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN) continue;
      if(g_zones[i].touchCount == 0)
         g_zones[i].strength = ZONE_UNTESTED;
      else if(g_zones[i].touchCount <= 2)
         g_zones[i].strength = ZONE_TESTED;
      else
         g_zones[i].strength = ZONE_PROVEN;
   }
}

//+------------------------------------------------------------------+
//| Sort zones by type then lo ascending (insertion sort, stable)     |
//+------------------------------------------------------------------+
void SortZones()
{
   for(int i = 1; i < g_zoneCount; i++)
   {
      SZone key = g_zones[i];
      int j = i - 1;
      while(j >= 0 && (g_zones[j].type > key.type ||
            (g_zones[j].type == key.type && g_zones[j].lo > key.lo)))
      {
         g_zones[j + 1] = g_zones[j];
         j--;
      }
      g_zones[j + 1] = key;
   }
}

//+------------------------------------------------------------------+
//| Draw all zone rectangles                                          |
//+------------------------------------------------------------------+
void DrawAllZones(datetime endTime)
{
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN && !InpShowBroken)
         continue;

      string name = PREFIX + "Z" + IntegerToString(i);
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, g_zones[i].startTime);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, endTime);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, g_zones[i].hi);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, g_zones[i].lo);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_FILL, InpZoneFill);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, InpZoneBorderWidth);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_COLOR, GetZoneColor(i));
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
#ifdef __MQL5__
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         (g_zones[i].type == ZONE_SUPPLY ? "Supply" : "Demand") + " | " +
         StrengthLabel(g_zones[i].strength) + " | Touches: " +
         IntegerToString(g_zones[i].touchCount));
#endif
   }
}

//+------------------------------------------------------------------+
//| Draw labels on zones                                              |
//+------------------------------------------------------------------+
void DrawAllLabels(datetime endTime)
{
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN && !InpShowBroken)
         continue;

      string name = PREFIX + "L" + IntegerToString(i);
      string text = (g_zones[i].type == ZONE_SUPPLY ? "Supply" : "Demand") +
                    " [" + StrengthLabel(g_zones[i].strength) + "]";
      // Supply labels at top of zone, Demand labels at bottom — prevents overlap confusion
      double vpos;
      if(g_zones[i].type == ZONE_SUPPLY)
         vpos = g_zones[i].hi - (g_zones[i].hi - g_zones[i].lo) * 0.15;
      else
         vpos = g_zones[i].lo + (g_zones[i].hi - g_zones[i].lo) * 0.15;

      ObjectCreate(0, name, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_TIME, endTime);
      ObjectSetDouble(0, name, OBJPROP_PRICE, vpos);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Get color for zone based on type and strength                     |
//+------------------------------------------------------------------+
color GetZoneColor(int idx)
{
   if(g_zones[idx].strength == ZONE_BROKEN)
      return InpBrokenColor;

   if(g_zones[idx].type == ZONE_SUPPLY)
   {
      switch(g_zones[idx].strength)
      {
         case ZONE_UNTESTED: return InpSupUntested;
         case ZONE_TESTED:   return InpSupTested;
         case ZONE_PROVEN:   return InpSupProven;
         default:            return InpSupUntested;
      }
   }
   else
   {
      switch(g_zones[idx].strength)
      {
         case ZONE_UNTESTED: return InpDemUntested;
         case ZONE_TESTED:   return InpDemTested;
         case ZONE_PROVEN:   return InpDemProven;
         default:            return InpDemUntested;
      }
   }
}

//+------------------------------------------------------------------+
//| Strength label string                                             |
//+------------------------------------------------------------------+
string StrengthLabel(ENUM_ZONE_STRENGTH s)
{
   switch(s)
   {
      case ZONE_UNTESTED: return "Untested";
      case ZONE_TESTED:   return "Tested";
      case ZONE_PROVEN:   return "Proven";
      case ZONE_BROKEN:   return "Broken";
   }
   return "";
}

//+------------------------------------------------------------------+
//| Check for price entering a zone and fire alerts                   |
//+------------------------------------------------------------------+
void CheckAlerts(double curClose, double curHigh, double curLow)
{
   datetime now = TimeCurrent();
   if(now - g_lastAlertTime < InpAlertCooldown)
      return;

   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN)
         continue;

      //--- Price entered zone
      if(curHigh >= g_zones[i].lo && curLow <= g_zones[i].hi)
      {
         string msg = _Symbol + " " + EnumToString((ENUM_TIMEFRAMES)Period()) + ": Price in " +
                      (g_zones[i].type == ZONE_SUPPLY ? "Supply" : "Demand") +
                      " zone [" + StrengthLabel(g_zones[i].strength) + "]";

         if(InpAlertPopup)
            Alert(msg);
         if(InpAlertSound)
            PlaySound("alert.wav");

         g_lastAlertTime = now;
         break;
      }
   }
}
//+------------------------------------------------------------------+
