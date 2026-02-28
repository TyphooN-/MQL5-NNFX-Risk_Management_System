//+------------------------------------------------------------------+
//|                                                          Rex.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "Rex oscillator"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
//--- plot Rex
#property indicator_label1  "Rex"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input uint           InpPeriod      =  14;         // Rex period
input ENUM_MA_METHOD InpMethod      =  MODE_SMA;   // Rex method
input uint           InpPeriodSig   =  14;         // Signal period
input ENUM_MA_METHOD InpMethodSig   =  MODE_SMA;   // Signal method
//--- indicator buffers
double         BufferRex[];
double         BufferSignal[];
double         BufferTVB[];
//--- global variables
int            period_rex;
int            period_sig;
int            weight_sum;
//--- includes
#include <MovingAverages.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_rex=int(InpPeriod<1 ? 1 : InpPeriod);
   period_sig=int(InpPeriodSig<2 ? 2 : InpPeriodSig);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferRex,INDICATOR_DATA);
   SetIndexBuffer(1,BufferSignal,INDICATOR_DATA);
   SetIndexBuffer(2,BufferTVB,INDICATOR_CALCULATIONS);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Rex ("+(string)period_rex+","+(string)period_sig+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferRex,true);
   ArraySetAsSeries(BufferSignal,true);
   ArraySetAsSeries(BufferTVB,true);
//---
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
//--- Установка массивов буферов как таймсерий
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<4 || Point()==0) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(BufferRex,EMPTY_VALUE);
      ArrayInitialize(BufferSignal,EMPTY_VALUE);
      ArrayInitialize(BufferTVB,0);
     }
//--- Подготовка данных
   for(int i=limit; i>=0 && !IsStopped(); i--)
      BufferTVB[i]=3.0*close[i]-(low[i]+open[i]+high[i]);

//--- Расчёт индикатора
   switch(InpMethod)
     {
      case MODE_EMA  :  if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_rex,BufferTVB,BufferRex)==0) return 0;               break;
      case MODE_SMMA :  if(SmoothedMAOnBuffer(rates_total,prev_calculated,0,period_rex,BufferTVB,BufferRex)==0) return 0;                  break;
      case MODE_LWMA :  if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,period_rex,BufferTVB,BufferRex,weight_sum)==0) return 0; break;
      //---MODE_SMA
      default        :  if(SimpleMAOnBuffer(rates_total,prev_calculated,0,period_rex,BufferTVB,BufferRex)==0) return 0;                    break;
     }
   switch(InpMethodSig)
     {
      case MODE_EMA  :  if(ExponentialMAOnBuffer(rates_total,prev_calculated,period_rex,period_sig,BufferRex,BufferSignal)==0) return 0;               break;
      case MODE_SMMA :  if(SmoothedMAOnBuffer(rates_total,prev_calculated,period_rex,period_sig,BufferRex,BufferSignal)==0) return 0;                  break;
      case MODE_LWMA :  if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_rex,period_sig,BufferRex,BufferSignal,weight_sum)==0) return 0; break;
      //---MODE_SMA
      default        :  if(SimpleMAOnBuffer(rates_total,prev_calculated,period_rex,period_sig,BufferRex,BufferSignal)==0) return 0;                    break;
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
