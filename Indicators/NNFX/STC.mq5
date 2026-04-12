//+------------------------------------------------------------------+
//                                              SchaffTrendCycle.mq5 |
//|                             Copyright © 2011-2019, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011-2019, EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Schaff-Trend-Cycle/"
#property version   "1.04"

#property description "Schaff Trend Cycle - Cyclical Stochastic over Stochastic over MACD."
#property description "Falling below 75 is a sell signal."
#property description "Rising above 25 is a buy signal."
#property description "Four kinds of alert: arrows, text, sound, email, and push."
#property description "Developed by Doug Schaff."
#property description "Code adapted from the original TradeStation EasyLanguage version."

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots 1
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 25
#property indicator_level2 75
#property indicator_width1 2
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_color1 clrDarkOrchid
#property indicator_label1 "Schaff Trend Cycle"

//---- Input Parameters
input int MAShort = 23;
input int MALong = 50;
input int Cycle = 10;

input bool ShowArrows = false;
input color UpColor = clrBlue;
input color DownColor = clrRed;
input bool ShowAlerts = false;
input bool SoundAlerts = false;
input bool EmailAlerts = false;
input bool PushAlerts = false;

//---- Global Variables
double Factor = 0.5;
int BarsRequired;
datetime LastAlert = D'1980.01.01';

//---- Buffers
double MACD[];
double ST[];
double ST2[];

//---- MA Buffers
double MAShortBuf[];
double MALongBuf[];

//---- MA Handles
int hMAShort;
int hMALong;

//---- Monotone deques for O(1) amortized sliding HHV/LLV (MACD and ST windows)
int g_maxMACDDq[], g_minMACDDq[];
int g_maxSTDq[],   g_minSTDq[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "STC(" + IntegerToString(MAShort) + "," + IntegerToString(MALong) + "," + IntegerToString(Cycle) + ")");

   SetIndexBuffer(0, ST2, INDICATOR_DATA);
   SetIndexBuffer(1, ST, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, MACD, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MALong + Cycle * 2);
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   if (Cycle < 2) { Print("Cycle must be >= 2"); return INIT_PARAMETERS_INCORRECT; }

   BarsRequired = MALong + Cycle * 2;

   hMAShort = iMA(NULL, 0, MAShort, 0, MODE_EMA, PRICE_CLOSE);
   if(hMAShort == INVALID_HANDLE) { Print("Failed to create iMA(",MAShort,") handle"); return INIT_FAILED; }
   hMALong = iMA(NULL, 0, MALong, 0, MODE_EMA, PRICE_CLOSE);
   if(hMALong == INVALID_HANDLE) { Print("Failed to create iMA(",MALong,") handle"); return INIT_FAILED; }

   int dqCap = Cycle + 1;
   if(ArrayResize(g_maxMACDDq, dqCap) == -1 || ArrayResize(g_minMACDDq, dqCap) == -1 ||
      ArrayResize(g_maxSTDq,   dqCap) == -1 || ArrayResize(g_minSTDq,   dqCap) == -1)
      return INIT_FAILED;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "ST_down_");
   ObjectsDeleteAll(0, "ST_up_");
   if(hMAShort != INVALID_HANDLE) IndicatorRelease(hMAShort);
   if(hMALong != INVALID_HANDLE) IndicatorRelease(hMALong);
}

//+------------------------------------------------------------------+
//| Schaff Trend Cycle                                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if (rates_total <= BarsRequired) return(rates_total);

   int counted_bars = prev_calculated;

   double LLV = 0, HHV = 0;
   int shift, i;
   int n_macd = 0, n_st = 0;
   // Static variables are used to flag that we already have calculated curves from the previous indicator run.
   static bool st1_pass = false;
   static bool st2_pass = false;
   bool check_st1 = false, check_st2 = false;

   if (counted_bars < BarsRequired)
   {
      for (i = 0; i < BarsRequired; i++) ST2[i] = 0;
      for (i = 0; i < BarsRequired; i++) ST[i] = 0;
      st1_pass = false;
      st2_pass = false;
   }

   if (counted_bars > 0) counted_bars--;

   shift = counted_bars - BarsRequired + MALong - 1;

   if (shift < 0) shift = 0;

   // Incremental MA buffer update: full copy on first run, partial on ticks
   if (counted_bars == 0 || ArraySize(MAShortBuf) < rates_total)
   {
      if(CopyBuffer(hMAShort, 0, 0, rates_total, MAShortBuf) != rates_total) return(0);
      if(CopyBuffer(hMALong, 0, 0, rates_total, MALongBuf) != rates_total) return(0);
   }
   else
   {
      int bars_to_copy = rates_total - counted_bars + 1;
      if (bars_to_copy < 1) bars_to_copy = 1;
      if (bars_to_copy > rates_total) bars_to_copy = rates_total;
      // Ensure arrays are sized to hold rates_total elements
      if (ArraySize(MAShortBuf) < rates_total) { if (ArrayResize(MAShortBuf, rates_total) == -1) return(0); }
      if (ArraySize(MALongBuf) < rates_total) { if (ArrayResize(MALongBuf, rates_total) == -1) return(0); }
      double tempS[], tempL[];
      if(CopyBuffer(hMAShort, 0, 0, bars_to_copy, tempS) != bars_to_copy) return(0);
      if(CopyBuffer(hMALong, 0, 0, bars_to_copy, tempL) != bars_to_copy) return(0);
      int base = rates_total - bars_to_copy;
      for (int j = 0; j < bars_to_copy; j++)
      {
         MAShortBuf[base + j] = tempS[j];
         MALongBuf[base + j] = tempL[j];
      }
   }

   // --- Monotone-deque O(1) sliding HHV/LLV over Cycle-sized windows ---
   int dqCap = Cycle + 1;
   int maxMH = 0, maxMT = 0, minMH = 0, minMT = 0;
   int maxSH = 0, maxST = 0, minSH = 0, minST2 = 0;

   // Pre-warmup: on incremental update, populate deques using already-stored MACD/ST values.
   int warmStart = MathMax(0, shift - Cycle + 1);
   for (int b = warmStart; b < shift; b++)
   {
      while (maxMT > maxMH && MACD[g_maxMACDDq[(maxMT - 1) % dqCap]] <= MACD[b]) maxMT--;
      g_maxMACDDq[maxMT % dqCap] = b; maxMT++;
      while (maxMH < maxMT && g_maxMACDDq[maxMH % dqCap] < b - Cycle + 1) maxMH++;
      while (minMT > minMH && MACD[g_minMACDDq[(minMT - 1) % dqCap]] >= MACD[b]) minMT--;
      g_minMACDDq[minMT % dqCap] = b; minMT++;
      while (minMH < minMT && g_minMACDDq[minMH % dqCap] < b - Cycle + 1) minMH++;
      n_macd++;

      if (st1_pass)
      {
         while (maxST > maxSH && ST[g_maxSTDq[(maxST - 1) % dqCap]] <= ST[b]) maxST--;
         g_maxSTDq[maxST % dqCap] = b; maxST++;
         while (maxSH < maxST && g_maxSTDq[maxSH % dqCap] < b - Cycle + 1) maxSH++;
         while (minST2 > minSH && ST[g_minSTDq[(minST2 - 1) % dqCap]] >= ST[b]) minST2--;
         g_minSTDq[minST2 % dqCap] = b; minST2++;
         while (minSH < minST2 && g_minSTDq[minSH % dqCap] < b - Cycle + 1) minSH++;
         n_st++;
      }
   }

   while (shift < rates_total)
   {
      MACD[shift] = MAShortBuf[shift] - MALongBuf[shift];

      // Push MACD[shift] onto deques
      while (maxMT > maxMH && MACD[g_maxMACDDq[(maxMT - 1) % dqCap]] <= MACD[shift]) maxMT--;
      g_maxMACDDq[maxMT % dqCap] = shift; maxMT++;
      while (maxMH < maxMT && g_maxMACDDq[maxMH % dqCap] < shift - Cycle + 1) maxMH++;
      while (minMT > minMH && MACD[g_minMACDDq[(minMT - 1) % dqCap]] >= MACD[shift]) minMT--;
      g_minMACDDq[minMT % dqCap] = shift; minMT++;
      while (minMH < minMT && g_minMACDDq[minMH % dqCap] < shift - Cycle + 1) minMH++;

      n_macd++;
      if (n_macd >= Cycle) check_st1 = true;

      if (check_st1)
      {
         HHV = MACD[g_maxMACDDq[maxMH % dqCap]];
         LLV = MACD[g_minMACDDq[minMH % dqCap]];
         // Calculating first Stochastic.
         if (HHV - LLV != 0) ST[shift] = ((MACD[shift] - LLV) / (HHV - LLV)) * 100;
         else ST[shift] = (shift > 0) ? ST[shift - 1] : 0;

         // Smoothing first Stochastic
         if (st1_pass && shift > 0) ST[shift] = Factor * (ST[shift] - ST[shift - 1]) + ST[shift - 1];
         st1_pass = true;

         // Push ST[shift] onto deques
         while (maxST > maxSH && ST[g_maxSTDq[(maxST - 1) % dqCap]] <= ST[shift]) maxST--;
         g_maxSTDq[maxST % dqCap] = shift; maxST++;
         while (maxSH < maxST && g_maxSTDq[maxSH % dqCap] < shift - Cycle + 1) maxSH++;
         while (minST2 > minSH && ST[g_minSTDq[(minST2 - 1) % dqCap]] >= ST[shift]) minST2--;
         g_minSTDq[minST2 % dqCap] = shift; minST2++;
         while (minSH < minST2 && g_minSTDq[minSH % dqCap] < shift - Cycle + 1) minSH++;

         n_st++;
         if (n_st >= Cycle) check_st2 = true;

         if (check_st2)
         {
            HHV = ST[g_maxSTDq[maxSH % dqCap]];
            LLV = ST[g_minSTDq[minSH % dqCap]];
            // Calculating second Stochastic.
            if (HHV - LLV != 0) ST2[shift] = ((ST[shift] - LLV) / (HHV - LLV)) * 100;
            else ST2[shift] = (shift > 0) ? ST2[shift - 1] : 0;

            // Smoothing second Stochastic.
            if (st2_pass && shift > 0) ST2[shift] = Factor * (ST2[shift] - ST2[shift - 1]) + ST2[shift - 1];
            st2_pass = true;
         }
      }
      
      if (shift > 0)
      {
      	if ((ST2[shift] < 75) && (ST2[shift - 1] >= 75))
      	{
      		if (ShowArrows)
      		{
	      		string name = "ST_down_" + TimeToString(Time[shift]);
	      		double offset = (High[shift] - Low[shift]) / 2;
	      		if (ObjectCreate(0, name, OBJ_ARROW, 0, Time[shift], High[shift] + offset + spread[shift] * Point()))
	      		{
	      		   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234);
	      		   ObjectSetInteger(0, name, OBJPROP_COLOR, DownColor);
	      		   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
	      		}
	      	}
		      if ((shift == rates_total - 2) && (LastAlert != Time[rates_total - 1]))
		      {
		      	if (ShowAlerts) Alert("Bearish signal on " + Symbol() + ".");
		      	if (SoundAlerts) PlaySound("alert.wav");
		      	if (EmailAlerts) SendMail("Schaff Trend Cycle Alert", "Bearish signal on " + TimeToString(Time[rates_total - 1]) + " on " + Symbol() + ".");
		      	if (PushAlerts) SendNotification("STC Alert: Bearish signal on " + TimeToString(Time[rates_total - 1]) + " on " + Symbol() + ".");
		      	LastAlert = Time[rates_total - 1];
				}
      	}
      	else if ((ST2[shift] > 25) && (ST2[shift - 1] <= 25))
      	{
      		if (ShowArrows)
      		{
	      		string name = "ST_up_" + TimeToString(Time[shift]);
	      		double offset = (High[shift] - Low[shift]) / 2;
	      		if (ObjectCreate(0, name, OBJ_ARROW, 0, Time[shift], Low[shift] - offset))
	      		{
	      		   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233);
	      		   ObjectSetInteger(0, name, OBJPROP_COLOR, UpColor);
	      		   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
	      		}
	      	}
		      if ((shift == rates_total - 2) && (LastAlert != Time[rates_total - 1]))
		      {
		      	if (ShowAlerts) Alert("Bullish signal on " + Symbol() + ".");
		      	if (SoundAlerts) PlaySound("alert.wav");
		      	if (EmailAlerts) SendMail("Schaff Trend Cycle Alert", "Bullish signal on " + TimeToString(Time[rates_total - 1]) + " on " + Symbol() + ".");
		      	if (PushAlerts) SendNotification("STC Alert: Bullish signal on " + TimeToString(Time[rates_total - 1]) + " on " + Symbol() + ".");
		      	LastAlert = Time[rates_total - 1];
				}
      	}
     	}
      shift++;
   }

   return(rates_total);
}
//+------------------------------------------------------------------+