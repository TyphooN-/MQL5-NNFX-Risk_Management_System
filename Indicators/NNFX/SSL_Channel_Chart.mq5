//+------------------------------------------------------------------+
//|                                            SSL Channel Chart.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_label1  "Bears"
#property indicator_color1 clrOrange
#property indicator_type1   DRAW_LINE
#property indicator_width1  2
#property indicator_label2  "Bulls"
#property indicator_color2 clrAqua
#property indicator_type2   DRAW_LINE
#property indicator_width2  2


//------------------------------------------------------------------

//---- input parameters
input ENUM_MA_METHOD MA_Method = MODE_SMA;  // Method
input int Lb = 10;
//---- buffers

double ssld[];
double sslu[];
double Hlv[];
double MAHigh[];
double MALow[];

int hMAHigh;
int hMALow;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0, ssld, INDICATOR_DATA);
   SetIndexBuffer(1, sslu, INDICATOR_DATA);
   SetIndexBuffer(2, Hlv, INDICATOR_CALCULATIONS);

   hMAHigh = iMA(_Symbol, PERIOD_CURRENT, Lb, 0, MA_Method, PRICE_HIGH);
   hMALow = iMA(_Symbol, PERIOD_CURRENT, Lb, 0, MA_Method, PRICE_LOW);


   if(hMAHigh==INVALID_HANDLE)Print(" Failed to get handle of the iMA indicator");
   if(hMALow==INVALID_HANDLE)Print(" Failed to get handle of the iMA indicator");

   ArraySetAsSeries(ssld,true);
   ArraySetAsSeries(sslu,true);
   ArraySetAsSeries(Hlv,true);
   ArraySetAsSeries(MAHigh,true);
   ArraySetAsSeries(MALow,true);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(hMAHigh!=INVALID_HANDLE) IndicatorRelease(hMAHigh);
   if(hMALow!=INVALID_HANDLE)  IndicatorRelease(hMALow);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---
   int counted_bars = prev_calculated;
   int i,limit;

   ArraySetAsSeries(close, true);

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;

   limit = MathMax(rates_total - counted_bars - Lb, 1);

   if(CopyBuffer(hMAHigh, 0, 0, limit+1, MAHigh) != limit+1) return 0;
   if(CopyBuffer(hMALow, 0, 0, limit+1, MALow) != limit+1) return 0;

   for(i=limit; i>=0; i--)
   {
      Hlv[i]=Hlv[i+1];

      if (close[i] > MAHigh[i]) Hlv[i]= 1;
      if (close[i] < MALow[i]) Hlv[i]= -1;

      if(Hlv[i]==-1)
      {
         ssld[i] = MAHigh[i];
         sslu[i] = MALow[i];
      }
      else
      {
         ssld[i] = MALow[i];
         sslu[i] = MAHigh[i];
      }
   }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
