//+------------------------------------------------------------------+
//|                                               SupplyDemand.mqh   |
//|                    Clean MQL5/MQL4 Supply & Demand Zone Indicator |
//|                    Body-to-wick zones, fractal detection          |
//+------------------------------------------------------------------+
//  Draws supply/demand zones on chart using OBJ_RECTANGLE objects.
//  Zones are detected at fractal highs/lows with body-to-wick bounds.
//  Strength tiers: UNTESTED -> TESTED -> PROVEN -> BROKEN
//
//  O(1) per bar: after initial build, each new bar only checks one
//  candidate fractal and tests bar 0 against existing zones.
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
   int               fractalBar;   // bar index in series mode (aged +1 each bar)
   int               touchCount;
   ENUM_ZONE_TYPE    type;
   ENUM_ZONE_STRENGTH strength;
   int               uid;          // unique ID for stable object naming
   bool              drawn;        // whether chart objects exist for this zone
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
bool         g_initialized  = false;    // first-run flag for incremental mode
int          g_nextUid      = 0;        // monotonic zone ID counter

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpFractalLookback < 1 || InpBackLimit < 1)
      return INIT_PARAMETERS_INCORRECT;

   g_lastBarTime = 0;
   g_lastAlertTime = 0;
   g_initialized = false;
   g_nextUid = 0;
   g_zoneCount = 0;
   ArrayResize(g_zones, 0, 128);

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

   //--- New-bar gate
   if(time[0] != g_lastBarTime)
   {
      g_lastBarTime = time[0];
      datetime currentTime = time[0];

      if(!g_initialized)
      {
         //--- Full rebuild on first run
         FullRebuild(open, high, low, close, time, rates_total, currentTime);
         g_initialized = true;
      }
      else
      {
         //--- O(1) incremental update
         IncrementalUpdate(open, high, low, close, time, rates_total, currentTime);
      }
   }

   //--- Alerts run every tick (with cooldown)
   if(InpAlertPopup || InpAlertSound)
      CheckAlerts(close[0], high[0], low[0]);

   return rates_total;
}

//+------------------------------------------------------------------+
//| Full rebuild — runs once on first bar                             |
//+------------------------------------------------------------------+
void FullRebuild(const double &open[], const double &high[],
                 const double &low[], const double &close[],
                 const datetime &time[], int rates_total,
                 datetime currentTime)
{
   //--- Clear everything
   ObjectsDeleteAll(0, PREFIX);
   g_zoneCount = 0;
   g_nextUid = 0;
   ArrayResize(g_zones, 0, 128);

   int limit = MathMin(InpBackLimit, rates_total - InpFractalLookback - 1);

   //--- Find fractal zones
   FindZones(open, high, low, close, time, limit);

   //--- Test zones against price action
   TestZones(high, low, close, limit);

   //--- Merge overlapping same-type zones
   if(InpMergeZones)
      MergeZones();

   //--- Draw all zones
   DrawAllZones(currentTime);

   if(InpShowLabels)
      DrawAllLabels(currentTime);
}

//+------------------------------------------------------------------+
//| O(1) incremental update — runs on each subsequent new bar         |
//+------------------------------------------------------------------+
void IncrementalUpdate(const double &open[], const double &high[],
                       const double &low[], const double &close[],
                       const datetime &time[], int rates_total,
                       datetime currentTime)
{
   //--- Step 1: Age all zone fractalBar indices by +1 (bar 0 shifted right)
   for(int i = 0; i < g_zoneCount; i++)
      g_zones[i].fractalBar++;

   //--- Step 2: Prune zones that aged beyond BackLimit
   bool pruned = false;
   {
      int writeIdx = 0;
      for(int i = 0; i < g_zoneCount; i++)
      {
         if(g_zones[i].fractalBar > InpBackLimit)
         {
            //--- Delete chart objects for this zone
            DeleteZoneObjects(g_zones[i].uid);
            pruned = true;
         }
         else
         {
            if(writeIdx != i)
               g_zones[writeIdx] = g_zones[i];
            writeIdx++;
         }
      }
      if(writeIdx != g_zoneCount)
      {
         g_zoneCount = writeIdx;
         ArrayResize(g_zones, g_zoneCount, 128);
      }
   }

   //--- Step 3: Check the one new candidate bar for fractals
   int candidate = InpFractalLookback;
   int limit = MathMin(InpBackLimit, rates_total - InpFractalLookback - 1);
   bool newZoneAdded = false;

   if(candidate <= limit - InpFractalLookback)
   {
      //--- Supply zone at fractal high
      if(IsFractalHigh(high, candidate, InpFractalLookback, limit))
      {
         SZone zone;
         zone.hi         = high[candidate];
         zone.lo         = MathMin(close[candidate], open[candidate]);
         if(zone.hi - zone.lo < _Point)
            zone.lo = zone.hi - _Point;
         zone.startTime  = time[candidate];
         zone.fractalBar = candidate;
         zone.touchCount = 0;
         zone.type       = ZONE_SUPPLY;
         zone.strength   = ZONE_UNTESTED;
         zone.uid        = g_nextUid++;
         zone.drawn      = false;

         //--- Test new zone against bar 0 only (bars 1+ didn't exist when zone formed)
         TestSingleBarAgainstZone(zone, high[0], low[0], close[0]);
         UpdateZoneStrength(zone);

         AddZone(zone);
         newZoneAdded = true;
      }

      //--- Demand zone at fractal low
      if(IsFractalLow(low, candidate, InpFractalLookback, limit))
      {
         SZone zone;
         zone.hi         = MathMax(close[candidate], open[candidate]);
         zone.lo         = low[candidate];
         if(zone.hi - zone.lo < _Point)
            zone.hi = zone.lo + _Point;
         zone.startTime  = time[candidate];
         zone.fractalBar = candidate;
         zone.touchCount = 0;
         zone.type       = ZONE_DEMAND;
         zone.strength   = ZONE_UNTESTED;
         zone.uid        = g_nextUid++;
         zone.drawn      = false;

         //--- Test new zone against bar 0
         TestSingleBarAgainstZone(zone, high[0], low[0], close[0]);
         UpdateZoneStrength(zone);

         AddZone(zone);
         newZoneAdded = true;
      }
   }

   //--- Step 4: Merge if new zone added
   if(newZoneAdded && InpMergeZones)
      MergeZones();

   //--- Step 5: Test bar 0 against all non-broken existing zones
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN)
         continue;

      ENUM_ZONE_STRENGTH prevStrength = g_zones[i].strength;

      TestSingleBarAgainstZone(g_zones[i], high[0], low[0], close[0]);
      UpdateZoneStrength(g_zones[i]);

      //--- If strength changed, update object color
      if(g_zones[i].strength != prevStrength)
      {
         if(g_zones[i].strength == ZONE_BROKEN && !InpShowBroken)
         {
            DeleteZoneObjects(g_zones[i].uid);
            g_zones[i].drawn = false;
         }
         else if(g_zones[i].drawn)
         {
            string zName = PREFIX + "Z" + IntegerToString(g_zones[i].uid);
            ObjectSetInteger(0, zName, OBJPROP_COLOR, GetZoneColorDirect(g_zones[i]));
            if(InpShowLabels)
            {
               string lName = PREFIX + "L" + IntegerToString(g_zones[i].uid);
               string text = (g_zones[i].type == ZONE_SUPPLY ? "Supply" : "Demand") +
                             " [" + StrengthLabel(g_zones[i].strength) + "]";
               ObjectSetString(0, lName, OBJPROP_TEXT, text);
            }
         }
      }
   }

   //--- Step 6: Purge broken zones from array if not showing them
   if(!InpShowBroken)
      PurgeBrokenZones();

   //--- Step 7: Update end time for all visible zones + draw new zones
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN && !InpShowBroken)
         continue;

      if(!g_zones[i].drawn)
      {
         //--- Create objects for new zone
         DrawSingleZone(i, currentTime);
         if(InpShowLabels)
            DrawSingleLabel(i, currentTime);
         g_zones[i].drawn = true;
      }
      else
      {
         //--- Update end time (right edge) for existing zone
         string zName = PREFIX + "Z" + IntegerToString(g_zones[i].uid);
         ObjectSetInteger(0, zName, OBJPROP_TIME, 1, currentTime);
         if(InpShowLabels)
         {
            string lName = PREFIX + "L" + IntegerToString(g_zones[i].uid);
            ObjectSetInteger(0, lName, OBJPROP_TIME, currentTime);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Test a single bar against a zone (touch or break)                 |
//+------------------------------------------------------------------+
void TestSingleBarAgainstZone(SZone &zone, double barHigh, double barLow, double barClose)
{
   if(zone.strength == ZONE_BROKEN)
      return;

   //--- Does this bar's range overlap the zone?
   if(barHigh >= zone.lo && barLow <= zone.hi)
   {
      //--- Check for break (close pierces beyond zone boundary)
      if(zone.type == ZONE_SUPPLY && barClose > zone.hi)
      {
         zone.strength = ZONE_BROKEN;
         return;
      }
      if(zone.type == ZONE_DEMAND && barClose < zone.lo)
      {
         zone.strength = ZONE_BROKEN;
         return;
      }

      //--- Count touch
      zone.touchCount++;
   }
}

//+------------------------------------------------------------------+
//| Update zone strength based on touch count                         |
//+------------------------------------------------------------------+
void UpdateZoneStrength(SZone &zone)
{
   if(zone.strength == ZONE_BROKEN)
      return;

   if(zone.touchCount == 0)
      zone.strength = ZONE_UNTESTED;
   else if(zone.touchCount <= 2)
      zone.strength = ZONE_TESTED;
   else
      zone.strength = ZONE_PROVEN;
}

//+------------------------------------------------------------------+
//| Delete chart objects for a zone by UID                             |
//+------------------------------------------------------------------+
void DeleteZoneObjects(int uid)
{
   string zName = PREFIX + "Z" + IntegerToString(uid);
   string lName = PREFIX + "L" + IntegerToString(uid);
   ObjectDelete(0, zName);
   ObjectDelete(0, lName);
}

//+------------------------------------------------------------------+
//| Draw a single zone rectangle                                      |
//+------------------------------------------------------------------+
void DrawSingleZone(int idx, datetime endTime)
{
   string name = PREFIX + "Z" + IntegerToString(g_zones[idx].uid);
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, g_zones[idx].startTime);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, endTime);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, g_zones[idx].hi);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, g_zones[idx].lo);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, InpZoneFill);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, InpZoneBorderWidth);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_COLOR, GetZoneColorDirect(g_zones[idx]));
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
#ifdef __MQL5__
   ObjectSetString(0, name, OBJPROP_TOOLTIP,
      (g_zones[idx].type == ZONE_SUPPLY ? "Supply" : "Demand") + " | " +
      StrengthLabel(g_zones[idx].strength) + " | Touches: " +
      IntegerToString(g_zones[idx].touchCount));
#endif
}

//+------------------------------------------------------------------+
//| Draw a single zone label                                          |
//+------------------------------------------------------------------+
void DrawSingleLabel(int idx, datetime endTime)
{
   string name = PREFIX + "L" + IntegerToString(g_zones[idx].uid);
   string text = (g_zones[idx].type == ZONE_SUPPLY ? "Supply" : "Demand") +
                 " [" + StrengthLabel(g_zones[idx].strength) + "]";
   double vpos;
   if(g_zones[idx].type == ZONE_SUPPLY)
      vpos = g_zones[idx].hi - (g_zones[idx].hi - g_zones[idx].lo) * 0.15;
   else
      vpos = g_zones[idx].lo + (g_zones[idx].hi - g_zones[idx].lo) * 0.15;

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
//| Find fractal zones and add to array (full scan — initial only)    |
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
         zone.uid        = g_nextUid++;
         zone.drawn      = false;
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
         zone.uid        = g_nextUid++;
         zone.drawn      = false;
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
//| Test zones against subsequent price action (full scan — initial)  |
//+------------------------------------------------------------------+
void TestZones(const double &high[], const double &low[],
               const double &close[], int limit)
{
   for(int z = g_zoneCount - 1; z >= 0; z--)
   {
      int scanFrom = g_zones[z].fractalBar - InpFractalLookback - 1;
      if(scanFrom < 0) scanFrom = 0;

      for(int b = scanFrom; b >= 0; b--)
      {
         if(high[b] >= g_zones[z].lo && low[b] <= g_zones[z].hi)
         {
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
            g_zones[z].touchCount++;
         }
      }

      UpdateZoneStrength(g_zones[z]);
   }

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
      else
      {
         //--- Clean up objects for purged zones
         DeleteZoneObjects(g_zones[i].uid);
      }
   }
   g_zoneCount = writeIdx;
   ArrayResize(g_zones, g_zoneCount, 128);
}

//+------------------------------------------------------------------+
//| Merge overlapping zones of the same type (sort-and-sweep)         |
//+------------------------------------------------------------------+
void MergeZones()
{
   if(g_zoneCount < 2) return;

   SortZones();

   int writeIdx = 0;
   for(int i = 1; i < g_zoneCount; i++)
   {
      if(g_zones[i].type == g_zones[writeIdx].type &&
         g_zones[i].lo <= g_zones[writeIdx].hi)
      {
         //--- Merge into writeIdx — delete the consumed zone's objects
         DeleteZoneObjects(g_zones[i].uid);

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

   for(int i = 0; i < g_zoneCount; i++)
      UpdateZoneStrength(g_zones[i]);
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
//| Draw all zone rectangles (initial draw, sets drawn flag)          |
//+------------------------------------------------------------------+
void DrawAllZones(datetime endTime)
{
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN && !InpShowBroken)
         continue;

      DrawSingleZone(i, endTime);
      g_zones[i].drawn = true;
   }
}

//+------------------------------------------------------------------+
//| Draw labels on zones (initial draw)                               |
//+------------------------------------------------------------------+
void DrawAllLabels(datetime endTime)
{
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zones[i].strength == ZONE_BROKEN && !InpShowBroken)
         continue;

      DrawSingleLabel(i, endTime);
   }
}

//+------------------------------------------------------------------+
//| Get color for zone based on type and strength                     |
//+------------------------------------------------------------------+
color GetZoneColorDirect(const SZone &zone)
{
   if(zone.strength == ZONE_BROKEN)
      return InpBrokenColor;

   if(zone.type == ZONE_SUPPLY)
   {
      switch(zone.strength)
      {
         case ZONE_UNTESTED: return InpSupUntested;
         case ZONE_TESTED:   return InpSupTested;
         case ZONE_PROVEN:   return InpSupProven;
         default:            return InpSupUntested;
      }
   }
   else
   {
      switch(zone.strength)
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
