//+------------------------------------------------------------------+
//|                                                         VPCI.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "Volume price confirmation indicator"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
//--- plot VPCI
#property indicator_label1  "VPCI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrSteelBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input uint     InpPeriodSlow  =  50;   // Slow MA period
input uint     InpPeriodFast  =  10;   // Fast MA period
//--- indicator buffers
double         BufferVPCI[];
double         BufferFMA[];
double         BufferSMA[];
double         BufferVol[];
double         BufferCV[];
//--- global variables
int            period_fast;
int            period_slow;
int            period_max;
int            handle_fma;
int            handle_sma;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_fast=int(InpPeriodFast<1 ? 1 : InpPeriodFast);
   period_slow=int(InpPeriodSlow<1 ? 1 : InpPeriodSlow);
   period_max=fmax(period_fast,period_slow);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferVPCI,INDICATOR_DATA);
   SetIndexBuffer(1,BufferFMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,BufferSMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BufferVol,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferCV,INDICATOR_CALCULATIONS);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"VPCI ("+(string)period_slow+","+(string)period_fast+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferVPCI,true);
   ArraySetAsSeries(BufferFMA,true);
   ArraySetAsSeries(BufferSMA,true);
   ArraySetAsSeries(BufferVol,true);
   ArraySetAsSeries(BufferCV,true);
//--- create MA's handles
   ResetLastError();
   handle_fma=iMA(NULL,PERIOD_CURRENT,period_fast,0,MODE_SMA,PRICE_CLOSE);
   if(handle_fma==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_fast,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   handle_sma=iMA(NULL,PERIOD_CURRENT,period_slow,0,MODE_SMA,PRICE_CLOSE);
   if(handle_sma==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_slow,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle_fma!=INVALID_HANDLE) IndicatorRelease(handle_fma);
   if(handle_sma!=INVALID_HANDLE) IndicatorRelease(handle_sma);
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
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<fmax(period_max,4) || Point()==0) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-period_max-1;
      ArrayInitialize(BufferVPCI,EMPTY_VALUE);
      ArrayInitialize(BufferFMA,0);
      ArrayInitialize(BufferSMA,0);
      ArrayInitialize(BufferVol,0);
      ArrayInitialize(BufferCV,0);
     }
//--- Подготовка данных
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_fma,0,0,count,BufferFMA);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_sma,0,0,count,BufferSMA);
   if(copied!=count) return 0;

   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      BufferVol[i]=(double)tick_volume[i];
      BufferCV[i]=close[i]*BufferVol[i];
     }

//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      double Volume_Slow=GetSMA(rates_total,i,period_slow,BufferVol)*period_slow;
      double Volume_Fast=GetSMA(rates_total,i,period_fast,BufferVol)*period_fast;
      
      double VWMA_Slow=(Volume_Slow!=0 ? GetSMA(rates_total,i,period_slow,BufferCV)*period_slow/Volume_Slow : 0);
      double VWMA_Fast=(Volume_Fast!=0 ? GetSMA(rates_total,i,period_fast,BufferCV)*period_fast/Volume_Fast : 0);
      double SMA_Fast=BufferFMA[i];

      double VPC=VWMA_Slow-BufferSMA[i];
      double VPR=(SMA_Fast!=0 ? VWMA_Fast/SMA_Fast : 1);
      double VM=(Volume_Slow!=0 ? (Volume_Fast*period_slow)/(Volume_Slow*period_fast) : 1);

      BufferVPCI[i]=VPC*VPR*VM/(Point()*Point());
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Simple Moving Average                                            |
//+------------------------------------------------------------------+
double GetSMA(const int rates_total,const int index,const int period,const double &price[],const bool as_series=true)
  {
//---
   double result=0.0;
//--- check position
   bool check_index=(as_series ? index<=rates_total-period-1 : index>=period-1);
   if(period<1 || !check_index)
      return 0;
//--- calculate value
   for(int i=0; i<period; i++)
      result=result+(as_series ? price[index+i]: price[index-i]);
//---
   return(result/period);
  }
//+------------------------------------------------------------------+
