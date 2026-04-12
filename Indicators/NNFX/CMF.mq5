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
     
//--- refresh Money Flow Multiplier for all bars being recalculated
   for(int k=limit;k>=0;k--)
     {
      ExtBufferTMP[k]=((close[k]==high[k] && close[k]==low[k]) || high[k]==low[k] ? 0 : ((2*close[k]-low[k]-high[k])/(high[k]-low[k]))*(InpVolume==VOLUME_TICK ? tick_volume[k] : volume[k]));
     }

//--- running-sum sliding window (window = bars [i, i+count-1], count capped at length)
   double sum_mfm=0, sum_mfv=0;
   int    window_size=0;
   int    init_count=(int)length;
   if(limit+init_count>rates_total-1)
      init_count=rates_total-1-limit;
   if(init_count<0)
      init_count=0;
   for(int k=0; k<init_count; k++)
     {
      sum_mfm += ExtBufferTMP[limit+k];
      sum_mfv += (double)(InpVolume==VOLUME_TICK ? tick_volume[limit+k] : volume[limit+k]);
     }
   window_size=init_count;
   if(window_size>0)
      ExtBufferCMF[limit]=sum_mfm/(sum_mfv!=0 ? sum_mfv : 1.0);

   for(int i=limit-1; i>=0; i--)
     {
      sum_mfm += ExtBufferTMP[i];
      sum_mfv += (double)(InpVolume==VOLUME_TICK ? tick_volume[i] : volume[i]);
      window_size++;
      if(window_size>(int)length)
        {
         int old_idx=i+(int)length;
         sum_mfm -= ExtBufferTMP[old_idx];
         sum_mfv -= (double)(InpVolume==VOLUME_TICK ? tick_volume[old_idx] : volume[old_idx]);
         window_size--;
        }
      ExtBufferCMF[i]=sum_mfm/(sum_mfv!=0 ? sum_mfv : 1.0);
     }
      
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
