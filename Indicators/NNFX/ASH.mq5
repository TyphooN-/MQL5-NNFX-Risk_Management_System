//+------------------------------------------------------------------+
//|                                                          ASH.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "Absolute Strength Histogram oscillator"
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   1
//--- plot ASH
#property indicator_label1  "ASH"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrBlue,clrRed,clrDarkGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- enums
enum ENUM_MODE
  {
   MODE_RSI,   // RSI
   MODE_STO    // Stochastic
  };
//--- input parameters
input uint                 InpPeriod         =  9;             // Period
input uint                 InpPeriodSm       =  2;             // Smoothing
input ENUM_MODE            InpMode           =  MODE_RSI;      // Mode
input ENUM_MA_METHOD       InpMethod         =  MODE_SMA;      // Method
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Applied price
//--- indicator buffers
double         BufferASH[];
double         BufferColors[];
double         BufferBL[];
double         BufferBR[];
double         BufferAvgBL[];
double         BufferAvgBR[];
double         BufferAvgSmBL[];
double         BufferAvgSmBR[];
double         BufferMA[];
//--- global variables
int            period_ind;
int            period_sm;
int            period_max;
int            handle_ma;
int            weight_sum_bl;
int            weight_sum_br;
int            weight_sum_sbl;
int            weight_sum_sbr;
//--- includes
#include <MovingAverages.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_ind=int(InpPeriod<1 ? 1 : InpPeriod);
   period_sm=int(InpPeriodSm<2 ? 2 : InpPeriodSm);
   period_max=fmax(period_ind,period_sm);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferASH,INDICATOR_DATA);
   SetIndexBuffer(1,BufferColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BufferBL,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BufferBR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferAvgBL,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufferAvgBR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BufferAvgSmBL,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,BufferAvgSmBR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BufferMA,INDICATOR_CALCULATIONS);
//--- setting indicator parameters
   string method=StringSubstr(EnumToString(InpMode),5);
   IndicatorSetString(INDICATOR_SHORTNAME,"ASH ("+(string)period_ind+","+(string)period_sm+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferASH,true);
   ArraySetAsSeries(BufferColors,true);
   ArraySetAsSeries(BufferBL,true);
   ArraySetAsSeries(BufferBR,true);
   ArraySetAsSeries(BufferAvgBL,true);
   ArraySetAsSeries(BufferAvgBR,true);
   ArraySetAsSeries(BufferAvgSmBL,true);
   ArraySetAsSeries(BufferAvgSmBR,true);
   ArraySetAsSeries(BufferMA,true);
//--- create MA's handles
   ResetLastError();
   handle_ma=iMA(NULL,PERIOD_CURRENT,1,0,MODE_SMA,InpAppliedPrice);
   if(handle_ma==INVALID_HANDLE)
     {
      Print("The iMA(1) object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle_ma!=INVALID_HANDLE) IndicatorRelease(handle_ma);
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
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<fmax(period_max,4) || Point()==0) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(BufferASH,EMPTY_VALUE);
      ArrayInitialize(BufferBL,0);
      ArrayInitialize(BufferBR,0);
      ArrayInitialize(BufferAvgBL,0);
      ArrayInitialize(BufferAvgBR,0);
      ArrayInitialize(BufferAvgSmBL,0);
      ArrayInitialize(BufferAvgSmBR,0);
      ArrayInitialize(BufferMA,0);
     }
//--- Подготовка данных
   int bars=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_ma,0,0,bars,BufferMA);
   if(copied!=bars) return 0;
   
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      double Pr0=BufferMA[i];
      double Pr1=BufferMA[i+1];

      if(InpMode==MODE_RSI)
        {
         BufferBL[i]=0.5*fabs(Pr0-Pr1)+Pr0-Pr1;
         BufferBR[i]=0.5*fabs(Pr0-Pr1)-Pr0+Pr1;
        }
      else
        {
         int bh=Highest(high,period_ind,i);
         int bl=Lowest(low,period_ind,i);
         if(bh==WRONG_VALUE || bl==WRONG_VALUE)
            continue;
         double max=high[bh];
         double min=low[bl];
         BufferBL[i]=Pr0-min;
         BufferBR[i]=max-Pr0;
        }
     }
   switch(InpMethod)
     {
      case MODE_EMA  :
        if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBL,BufferAvgBL)==0) return 0;
        if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBR,BufferAvgBR)==0) return 0;
        break;
      case MODE_SMMA :
        if(SmoothedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBL,BufferAvgBL)==0) return 0;
        if(SmoothedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBR,BufferAvgBR)==0) return 0;
        break;
      case MODE_LWMA :
        if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBL,BufferAvgBL,weight_sum_bl)==0) return 0;
        if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBR,BufferAvgBR,weight_sum_br)==0) return 0;
        break;
      //---MODE_SMA
      default        :
        if(SimpleMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBL,BufferAvgBL)==0) return 0;
        if(SimpleMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBR,BufferAvgBR)==0) return 0;
        break;
     }
   switch(InpMethod)
     {
      case MODE_EMA  :
        if(ExponentialMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBL,BufferAvgSmBL)==0) return 0;
        if(ExponentialMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBR,BufferAvgSmBR)==0) return 0;
        break;
      case MODE_SMMA :
        if(SmoothedMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBL,BufferAvgSmBL)==0) return 0;
        if(SmoothedMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBR,BufferAvgSmBR)==0) return 0;
        break;
      case MODE_LWMA :
        if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBL,BufferAvgSmBL,weight_sum_sbl)==0) return 0;
        if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBR,BufferAvgSmBR,weight_sum_sbr)==0) return 0;
        break;
      //---MODE_SMA
      default        :
        if(SimpleMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBL,BufferAvgSmBL)==0) return 0;
        if(SimpleMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferAvgBR,BufferAvgSmBR)==0) return 0;
        break;
     }

//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      BufferASH[i]=(BufferAvgSmBL[i]-BufferAvgSmBR[i])/Point();
      BufferColors[i]=(BufferASH[i]>BufferASH[i+1] ? 0 : BufferASH[i]<BufferASH[i+1] ? 1 : 2);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Возвращает индекс максимального значения таймсерии High          |
//+------------------------------------------------------------------+
int Highest(const double &h[],const int count,const int start)
  {
   int idx=start;
   double mx=h[start];
   for(int i=1; i<count; i++)
      if(h[start+i]>mx) { mx=h[start+i]; idx=start+i; }
   return idx;
  }
//+------------------------------------------------------------------+
//| Возвращает индекс минимального значения таймсерии Low            |
//+------------------------------------------------------------------+
int Lowest(const double &l[],const int count,const int start)
  {
   int idx=start;
   double mn=l[start];
   for(int i=1; i<count; i++)
      if(l[start+i]<mn) { mn=l[start+i]; idx=start+i; }
   return idx;
  }
//+------------------------------------------------------------------+
