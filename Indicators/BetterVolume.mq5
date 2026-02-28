//+------------------------------------------------------------------+
//|                                               BetterVolume.mq5   |
//|                    Port of Emini-Watch Better Volume indicator    |
//|                    Classifies volume using buy/sell pressure      |
//+------------------------------------------------------------------+
//  Color histogram: classifies each bar's volume into categories.
//  Yellow = Low Volume, Red = Climax Up, White = Climax Down,
//  Green = Churn, Magenta = Climax+Churn, Slate = Normal
//+------------------------------------------------------------------+
#property copyright   "TyphooN"
#property link        "https://marketwizardry.org"
#property version     "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2

// Plot 1 - volume color histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_width1  2
#property indicator_color1  clrYellow,clrRed,clrWhite,clrGreen,clrMagenta,clrSteelBlue
#property indicator_label1  "Volume"

// Plot 2 - average volume line
#property indicator_type2   DRAW_LINE
#property indicator_width2  1
#property indicator_color2  clrDodgerBlue
#property indicator_label2  "AvgVol"

//--- Classification enum (matches color index order)
enum ENUM_VOL_CLASS
{
   VOL_LOW         = 0,   // Yellow
   VOL_CLIMAX_UP   = 1,   // Red
   VOL_CLIMAX_DN   = 2,   // White
   VOL_CHURN       = 3,   // Green
   VOL_CLIMAX_CHURN= 4,   // Magenta
   VOL_NORMAL      = 5    // SteelBlue
};

//--- Inputs
input int              InpLookback     = 20;            // Lookback Period
input bool             InpUse2Bars     = true;          // Enable 2-Bar Analysis
input bool             InpShowAvg      = false;         // Show Average Volume Line
input int              InpAvgPeriod    = 20;            // Average Volume Period
input ENUM_APPLIED_VOLUME InpVolumeType = VOLUME_TICK;  // Volume Type

input string __sep1__  = "";                            // --- Enable/Disable ---
input bool             InpEnableLowVol = true;          // Enable Low Volume
input bool             InpEnableClimax = true;          // Enable Climax
input bool             InpEnableChurn  = true;          // Enable Churn
input bool             InpEnableClimaxChurn = true;     // Enable Climax+Churn

input string __sep2__  = "";                            // --- Colors ---
input color            InpClrLowVol    = clrYellow;     // Low Volume Color
input color            InpClrClimaxUp  = clrRed;        // Climax Up Color
input color            InpClrClimaxDn  = clrWhite;      // Climax Down Color
input color            InpClrChurn     = clrGreen;      // Churn Color
input color            InpClrClimaxCh  = clrMagenta;    // Climax+Churn Color
input color            InpClrNormal    = clrSteelBlue;   // Normal Color

//--- Buffers
double HistData[];
double HistClr[];
double AvgData[];
double AvgCalc[];   // calculation buffer for intermediate values

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, HistData, INDICATOR_DATA);
   SetIndexBuffer(1, HistClr,  INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, AvgData,  INDICATOR_DATA);
   SetIndexBuffer(3, AvgCalc,  INDICATOR_CALCULATIONS);

   //--- Apply user colors at runtime
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, InpClrLowVol);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, InpClrClimaxUp);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 2, InpClrClimaxDn);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 3, InpClrChurn);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 4, InpClrClimaxCh);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 5, InpClrNormal);

   if(InpLookback < 1 || InpAvgPeriod < 1)
      return INIT_PARAMETERS_INCORRECT;

   //--- Hide avg line if disabled
   if(!InpShowAvg)
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);

   IndicatorSetString(INDICATOR_SHORTNAME,
      "BetterVol(" + IntegerToString(InpLookback) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   return INIT_SUCCEEDED;
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
   ArraySetAsSeries(HistData, true);
   ArraySetAsSeries(HistClr,  true);
   ArraySetAsSeries(AvgData,  true);
   ArraySetAsSeries(AvgCalc,  true);
   ArraySetAsSeries(open,  true);
   ArraySetAsSeries(high,  true);
   ArraySetAsSeries(low,   true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(tick_volume, true);
   ArraySetAsSeries(volume, true);

   int lookback = InpLookback + 2;
   if(rates_total < lookback) return 0;

   int limit;
   if(prev_calculated <= 0)
      limit = rates_total - lookback;
   else
      limit = rates_total - prev_calculated + 1;
   if(limit > rates_total - lookback) limit = rates_total - lookback;
   if(limit < 0) limit = 0;

   for(int pos = limit; pos >= 0; pos--)
   {
      double vol = GetVolume(tick_volume, volume, pos);
      HistData[pos] = vol;

      //--- Estimate buy/sell volumes
      double buyVol, sellVol;
      EstimateBuySell(open, high, low, close, tick_volume, volume, pos, buyVol, sellVol);

      //--- Classify this bar
      ENUM_VOL_CLASS cls = ClassifyBar(open, high, low, close, tick_volume, volume, pos, buyVol, sellVol);
      HistClr[pos] = (double)cls;

      //--- Average volume
      if(InpShowAvg)
         AvgData[pos] = AvgVolume(tick_volume, volume, pos, rates_total);
      else
         AvgData[pos] = EMPTY_VALUE;
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Get volume value based on input type                              |
//+------------------------------------------------------------------+
double GetVolume(const long &tick_vol[], const long &real_vol[], int bar)
{
   if(InpVolumeType == VOLUME_REAL && real_vol[bar] > 0)
      return (double)real_vol[bar];
   return (double)tick_vol[bar];
}

//+------------------------------------------------------------------+
//| Estimate buying and selling volume                                |
//+------------------------------------------------------------------+
void EstimateBuySell(const double &open[], const double &high[],
                     const double &low[], const double &close[],
                     const long &tick_vol[], const long &real_vol[],
                     int bar, double &buyVol, double &sellVol)
{
   double totalVol = GetVolume(tick_vol, real_vol, bar);
   double range = high[bar] - low[bar];

   if(range <= 0)
   {
      //--- Doji / zero range
      buyVol  = totalVol * 0.5;
      sellVol = totalVol * 0.5;
      return;
   }

   double o = open[bar], c = close[bar];

   if(c > o)
   {
      //--- Bullish bar
      double denom = 2.0 * range + o - c;
      if(denom <= 0) denom = range;
      buyVol = (range / denom) * totalVol;
   }
   else if(c < o)
   {
      //--- Bearish bar
      double denom = 2.0 * range + c - o;
      if(denom <= 0) denom = range;
      buyVol = ((range + c - o) / denom) * totalVol;
   }
   else
   {
      //--- Doji
      buyVol = totalVol * 0.5;
   }

   sellVol = totalVol - buyVol;
}

//+------------------------------------------------------------------+
//| Classify bar volume                                               |
//+------------------------------------------------------------------+
ENUM_VOL_CLASS ClassifyBar(const double &open[], const double &high[],
                           const double &low[], const double &close[],
                           const long &tick_vol[], const long &real_vol[],
                           int bar, double buyVol, double sellVol)
{
   double totalVol = GetVolume(tick_vol, real_vol, bar);
   double range    = high[bar] - low[bar];
   if(range <= 0) range = _Point;

   //--- Current bar metrics
   double buyRange  = buyVol * range;
   double sellRange = sellVol * range;
   double volDivR   = totalVol / range;
   double sellDivR  = (range > 0) ? sellVol / range : 0;
   double buyDivR   = (range > 0) ? buyVol / range : 0;

   //--- Find lookback extremes (1-bar)
   double highBuyRange  = 0, highSellRange = 0, highVolDivR = 0;
   double lowSellDivR   = DBL_MAX, lowBuyDivR = DBL_MAX, lowTotalVol = DBL_MAX;

   for(int i = 0; i < InpLookback; i++)
   {
      int b = bar + 1 + i;
      if(b >= ArraySize(open)) break;
      double bv, sv;
      EstimateBuySell(open, high, low, close, tick_vol, real_vol, b, bv, sv);
      double r = high[b] - low[b];
      if(r <= 0) r = _Point;
      double v = GetVolume(tick_vol, real_vol, b);

      double br = bv * r;
      double sr = sv * r;
      double vr = v / r;
      double sdr = sv / r;
      double bdr = bv / r;

      if(br > highBuyRange)   highBuyRange  = br;
      if(sr > highSellRange)  highSellRange = sr;
      if(vr > highVolDivR)    highVolDivR   = vr;
      if(sdr < lowSellDivR)   lowSellDivR   = sdr;
      if(bdr < lowBuyDivR)    lowBuyDivR    = bdr;
      if(v < lowTotalVol)     lowTotalVol   = v;
   }

   //--- 1-bar classification flags
   bool isClimaxUp  = false, isClimaxDn = false, isChurn = false, isLowVol = false;

   //--- Low Volume
   if(InpEnableLowVol && totalVol <= lowTotalVol)
      isLowVol = true;

   //--- Climax Up: (buyVol*range == highest) OR (sellVol/range == lowest), C > O
   if(InpEnableClimax && close[bar] > open[bar])
   {
      if(buyRange >= highBuyRange || sellDivR <= lowSellDivR)
         isClimaxUp = true;
   }

   //--- Climax Down: (sellVol*range == highest) OR (buyVol/range == lowest), C < O
   if(InpEnableClimax && close[bar] < open[bar])
   {
      if(sellRange >= highSellRange || buyDivR <= lowBuyDivR)
         isClimaxDn = true;
   }

   //--- Churn: totalVol/range == highest
   if(InpEnableChurn && volDivR >= highVolDivR)
      isChurn = true;

   //--- 2-bar analysis
   if(InpUse2Bars && bar + 1 < ArraySize(open))
   {
      Apply2BarConditions(open, high, low, close, tick_vol, real_vol, bar,
                          buyVol, sellVol, isClimaxUp, isClimaxDn, isChurn, isLowVol);
   }

   //--- Priority: ClimaxChurn > LowVol > ClimaxUp > ClimaxDown > Churn > Normal
   if(InpEnableClimaxChurn && (isClimaxUp || isClimaxDn) && isChurn)
      return VOL_CLIMAX_CHURN;

   if(isLowVol)
      return VOL_LOW;

   if(isClimaxUp)
      return VOL_CLIMAX_UP;

   if(isClimaxDn)
      return VOL_CLIMAX_DN;

   if(isChurn)
      return VOL_CHURN;

   return VOL_NORMAL;
}

//+------------------------------------------------------------------+
//| 2-bar combined analysis                                           |
//+------------------------------------------------------------------+
void Apply2BarConditions(const double &open[], const double &high[],
                         const double &low[], const double &close[],
                         const long &tick_vol[], const long &real_vol[],
                         int bar, double bv1, double sv1,
                         bool &isClimaxUp, bool &isClimaxDn,
                         bool &isChurn, bool &isLowVol)
{
   int bar2 = bar + 1;

   //--- 2-bar combined metrics (bv1/sv1 passed in, only compute bar2)
   double bv2, sv2;
   EstimateBuySell(open, high, low, close, tick_vol, real_vol, bar2, bv2, sv2);

   double totalBuy  = bv1 + bv2;
   double totalSell = sv1 + sv2;
   double totalVol2 = GetVolume(tick_vol, real_vol, bar) + GetVolume(tick_vol, real_vol, bar2);
   double range2    = MathMax(high[bar], high[bar2]) - MathMin(low[bar], low[bar2]);
   if(range2 <= 0) range2 = _Point;

   double buyRange2  = totalBuy * range2;
   double sellRange2 = totalSell * range2;
   double volDivR2   = totalVol2 / range2;
   double sellDivR2  = totalSell / range2;
   double buyDivR2   = totalBuy / range2;

   //--- Find 2-bar lookback extremes
   double highBuyR2 = 0, highSellR2 = 0, highVdR2 = 0;
   double lowSdR2 = DBL_MAX, lowBdR2 = DBL_MAX, lowVol2 = DBL_MAX;

   for(int i = 0; i < InpLookback; i++)
   {
      int b1 = bar + 1 + i;
      int b2 = b1 + 1;
      if(b2 >= ArraySize(open)) break;

      double bva, sva, bvb, svb;
      EstimateBuySell(open, high, low, close, tick_vol, real_vol, b1, bva, sva);
      EstimateBuySell(open, high, low, close, tick_vol, real_vol, b2, bvb, svb);

      double tb = bva + bvb;
      double ts = sva + svb;
      double tv = GetVolume(tick_vol, real_vol, b1) + GetVolume(tick_vol, real_vol, b2);
      double r2 = MathMax(high[b1], high[b2]) - MathMin(low[b1], low[b2]);
      if(r2 <= 0) r2 = _Point;

      double br2 = tb * r2;
      double sr2 = ts * r2;
      double vr2 = tv / r2;
      double sdr2 = ts / r2;
      double bdr2 = tb / r2;

      if(br2 > highBuyR2)   highBuyR2  = br2;
      if(sr2 > highSellR2)  highSellR2 = sr2;
      if(vr2 > highVdR2)    highVdR2   = vr2;
      if(sdr2 < lowSdR2)    lowSdR2    = sdr2;
      if(bdr2 < lowBdR2)    lowBdR2    = bdr2;
      if(tv < lowVol2)      lowVol2    = tv;
   }

   //--- 2-bar low volume
   if(InpEnableLowVol && totalVol2 <= lowVol2)
      isLowVol = true;

   //--- 2-bar climax up
   if(InpEnableClimax && close[bar] > open[bar])
   {
      if(buyRange2 >= highBuyR2 || sellDivR2 <= lowSdR2)
         isClimaxUp = true;
   }

   //--- 2-bar climax down
   if(InpEnableClimax && close[bar] < open[bar])
   {
      if(sellRange2 >= highSellR2 || buyDivR2 <= lowBdR2)
         isClimaxDn = true;
   }

   //--- 2-bar churn
   if(InpEnableChurn && volDivR2 >= highVdR2)
      isChurn = true;
}

//+------------------------------------------------------------------+
//| Simple moving average of volume                                   |
//+------------------------------------------------------------------+
double AvgVolume(const long &tick_vol[], const long &real_vol[],
                 int bar, int total)
{
   if(bar + InpAvgPeriod > total) return EMPTY_VALUE;

   double sum = 0;
   for(int i = 0; i < InpAvgPeriod; i++)
      sum += GetVolume(tick_vol, real_vol, bar + i);
   return sum / InpAvgPeriod;
}
//+------------------------------------------------------------------+
