//+------------------------------------------------------------------+
//|                         EhlersMotherOfAdaptiveMovingAverages.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|                                (v1.01+ by TyphooN)               |
//|  Main Site: http://fxstill.com                                   |
//|  Telegram:  https://t.me/fxstill (Literature on cryptocurrencies,| 
//|                                   development and code. )        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Andrei Novichkov."
#property link      "http://fxstill.com"
#property version   "1.03"
#property description "Telegram Channel: https://t.me/fxstill\n"
#property description "The Mother Of Adaptive Moving Averages:\nJohn Ehlers, \"Rocket Science For Traders\", pg.182-183"
#property indicator_chart_window
#property indicator_applied_price PRICE_MEDIAN
#property indicator_buffers 3
#property indicator_plots   2
//--- plot mama
#property indicator_label1  "mama"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlueViolet
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot fama
#property indicator_label2  "fama"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMediumBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- input parameters
input double   FastLimit = 0.5;
input double   SlowLimit = 0.05;
//--- indicator buffers
double         mb[];
double         fb[];
double         phase[];
static const int MINBAR = 5;
int h;
int OnInit()
{
   h = iCustom(NULL,0,"EhlersHilbertTransform");
   if (h == INVALID_HANDLE)
   {
      Print("Error while creating \"EhlersHilbertTransform\"");
      return (INIT_FAILED);
   }
   // Set the drawing order for the indicator
   ChartSetInteger(0, CHART_BRING_TO_TOP, 1);
   //--- indicator buffers mapping
   SetIndexBuffer(0,mb,INDICATOR_DATA);
   SetIndexBuffer(1,fb,INDICATOR_DATA);
   SetIndexBuffer(2,phase,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(mb,true);
   ArraySetAsSeries(fb,true);    
   ArraySetAsSeries(phase, true);
   IndicatorSetString(INDICATOR_SHORTNAME,"EhlersMotherOfAdaptiveMovingAverages");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);  
   return(INIT_SUCCEEDED);
}
void GetValue(const double& high[], const double& low[], int shift)
{
   double q1[1], i1[1];
   if (CopyBuffer(h, 4, shift, 1, i1) <= 0 || CopyBuffer(h, 5, shift, 1, q1) <= 0) return;
   phase[shift] = (i1[0] != 0) ? MathArctan(NormalizeDouble(q1[0]/i1[0],6)) : 0;
   double deltaPhase = phase[shift + 1] - phase[shift];
   deltaPhase = (deltaPhase < 1) ? 1 : deltaPhase;
   double alpha = FastLimit / deltaPhase;
   alpha = (alpha < SlowLimit) ? SlowLimit : alpha;
   double m = ZeroIfEmpty(mb[shift + 1]);
   double f = ZeroIfEmpty(fb[shift + 1]);
   mb[shift] = alpha * (high[shift] + low[shift])/2 + (1 - alpha) * m;
   fb[shift] = 0.5 * alpha * mb[shift] + (1 - 0.5 * alpha) * f;   
}  
double ZeroIfEmpty(double value)
{
   return (value == EMPTY_VALUE) ? 0.0 : value;
}  
void OnDeinit(const int reason)
{
   Comment("");   
  if (h != INVALID_HANDLE)
      IndicatorRelease(h);
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
   if (rates_total <= MINBAR) return 0;
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);       
   int limit = rates_total - prev_calculated;
   if (limit == 1)
   { // New bar formed
      GetValue(high, low, 1);          
      return rates_total;      
   }
   else if (limit > 1)
   {   // First call of the indicator, timeframe change, loading data from history
      ArrayInitialize(mb,   EMPTY_VALUE);
      ArrayInitialize(fb,   EMPTY_VALUE);
      ArrayInitialize(phase, 0);
      limit = rates_total - MINBAR;
      for (int i = limit; i >= 1 && !IsStopped(); i--)
      {
         GetValue(high, low, i);
      }
      return rates_total;         
   }
   GetValue(high, low, 0);          
   return rates_total;
}
