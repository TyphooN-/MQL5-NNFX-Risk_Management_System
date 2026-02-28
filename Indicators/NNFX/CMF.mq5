//+------------------------------------------------------------------+
//|                                             ChaikinMoneyFlow.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot ExtCMF
#property indicator_label1  "CMF"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrForestGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- input parameters
input uint                 InpLength   =  20;            // Length
input ENUM_APPLIED_VOLUME  InpVolume   =  VOLUME_TICK;   // Applied Volume

//--- indicator buffers
double         ExtBufferCMF[];
double         ExtBufferTMP[];

//--- global variables
int            length;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBufferCMF,INDICATOR_DATA);
   SetIndexBuffer(1,ExtBufferTMP,INDICATOR_CALCULATIONS);
   
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(ExtBufferCMF,true);
   ArraySetAsSeries(ExtBufferTMP,true);
   
//--- setting the period for calculating CMF and a short name for the indicator
   length=int(InpLength<1 ? 20 : InpLength);
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("CMF(%lu)",length));
   IndicatorSetInteger(INDICATOR_LEVELS,1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,0.0);
//--- success
   return(INIT_SUCCEEDED);
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
//--- checking for the minimum number of bars for calculation
   if(rates_total<length)
      return 0;
      
//--- setting predefined indicator arrays as timeseries
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(volume,true);
   
//--- checking and calculating the number of bars to be calculated
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(ExtBufferCMF,EMPTY_VALUE);
      ArrayInitialize(ExtBufferTMP,0);
     }
     
//--- calculation Chaikin Money Flow
   double array_mfm[];
   double array_mfv[];
   for(int i=limit;i>=0;i--)
     {
      //--- find the Money Flow Multiplier and calculate Money Flow Volume (MFM * Volume)
      ExtBufferTMP[i]=((close[i]==high[i] && close[i]==low[i]) || high[i]==low[i] ? 0 : ((2*close[i]-low[i]-high[i])/(high[i]-low[i]))*(InpVolume==VOLUME_TICK ? tick_volume[i] : volume[i]));
      int count=length;
      if(i+count>rates_total-1)
         count=rates_total-1-i;
      if(count==0)
         continue;
      if(ArrayCopy(array_mfm,ExtBufferTMP,0,i,count)!=count)
         continue;
      int copied=0;
      switch(InpVolume)
        {
         case VOLUME_TICK  :  copied=ArrayCopy(array_mfv,tick_volume,0,i,count); break;
         default           :  copied=ArrayCopy(array_mfv,volume,0,i,count);      break;
        }
      if(copied==0)
         continue;
      vector vmfm;
      vector vmfv;
      vmfm.Swap(array_mfm);
      vmfv.Swap(array_mfv);
      //--- summ of Money Flow Multiplier and Money Flow Volume
      double sum_mfm=vmfm.Sum();
      double sum_mfv=vmfv.Sum();
      //--- calculate the CMF
      ExtBufferCMF[i]=sum_mfm/(sum_mfv!=0 ? sum_mfv : 1.0);
     }
      
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
