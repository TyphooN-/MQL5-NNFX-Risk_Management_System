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

   BarsRequired = MALong + Cycle * 2;

   hMAShort = iMA(NULL, 0, MAShort, 0, MODE_EMA, PRICE_CLOSE);
   if(hMAShort == INVALID_HANDLE) { Print("Failed to create iMA(",MAShort,") handle"); return INIT_FAILED; }
   hMALong = iMA(NULL, 0, MALong, 0, MODE_EMA, PRICE_CLOSE);
   if(hMALong == INVALID_HANDLE) { Print("Failed to create iMA(",MALong,") handle"); return INIT_FAILED; }

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
   int shift, n = 1, i;
   // Static variables are used to flag that we already have calculated curves from the previous indicator run.
   static bool st1_pass = false;
   static bool st2_pass = false;
   int st1_count = 0;
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

   if(CopyBuffer(hMAShort, 0, 0, rates_total, MAShortBuf) != rates_total) return(0);
   if(CopyBuffer(hMALong, 0, 0, rates_total, MALongBuf) != rates_total) return(0);

   while (shift < rates_total)
   {
	   MACD[shift] = MAShortBuf[shift] - MALongBuf[shift];
	   
      if (n >= Cycle) check_st1 = true;
      else n++;
	
      if (check_st1)  
      {
         // Finding Max and Min on Cycle of MA differences (MACD).
         for (i = 0; i < Cycle; i++)
         {	
            if (i == 0)
            {
               LLV = MACD[shift - i];
               HHV = MACD[shift - i];
            }
            else
            {
               if (LLV > MACD[shift - i]) LLV = MACD[shift - i];
               if (HHV < MACD[shift - i]) HHV = MACD[shift - i];
            }
         }
         // Calculating first Stochastic.
         if (HHV - LLV != 0) ST[shift] = ((MACD[shift] - LLV) / (HHV - LLV)) * 100;
         else ST[shift] = ST[shift - 1];
         
         // Smoothing first Stochastic
         if (st1_pass) ST[shift] = Factor * (ST[shift] - ST[shift - 1]) + ST[shift - 1];
         st1_pass = true;
                  
         // Have enough elements of first Stochastic to proceed to second.
         if (st1_count >= Cycle) check_st2 = true;
         else st1_count++;
         
         if (check_st2)
         {
            // Finding Max and Min on Cycle of first smoothed Stochastic.
            for (i = 0; i < Cycle; i++)
            {	
               if (i == 0)
               {
                  LLV = ST[shift - i];
                  HHV = ST[shift - i];
               }
               else
               {
                  if (LLV > ST[shift - i]) LLV = ST[shift - i];
                  if (HHV < ST[shift - i]) HHV = ST[shift - i];
               }
            }
            // Calculating second Stochastic.
            if (HHV - LLV != 0) ST2[shift] = ((ST[shift] - LLV) / (HHV - LLV)) * 100;
            else ST2[shift] = ST2[shift - 1];
            
            // Smoothing second Stochastic.
            if (st2_pass) ST2[shift] = Factor * (ST2[shift] - ST2[shift - 1]) + ST2[shift - 1];
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
	      		ObjectCreate(0, name, OBJ_ARROW, 0, Time[shift], High[shift] + offset + spread[shift] * Point());
	      		ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234);
	      		ObjectSetInteger(0, name, OBJPROP_COLOR, DownColor);
	      		ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
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
	      		ObjectCreate(0, name, OBJ_ARROW, 0, Time[shift], Low[shift] - offset);
	      		ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233);
	      		ObjectSetInteger(0, name, OBJPROP_COLOR, UpColor);
	      		ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
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