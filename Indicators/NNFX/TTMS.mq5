//+------------------------------------------------------------------+
//|                                                         TTMS.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "John Carter TTM Squeeze Indicator"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   3
//--- plot TTMS
#property indicator_label1  "TTMS"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLimeGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Sig
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot NoSig
#property indicator_label3  "No Signal"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input uint     InpPeriodBB       =  20;         // BB period
input double   InpDevBB          =  2.0;        // BB deviation
input uint     InpPeriodKL       =  20;         // Keltner period
input uint     InpPeriodSmoothKL =  20;         // Keltner smooth period
input ENUM_MA_METHOD InpMethodKL =  MODE_SMA;   // Keltner smooth method
input double   InpDevKL          =  2.0;        // Keltner deviation
input uchar    InpSizeSig        =  1;          // Signal label size
//--- indicator buffers
double         BufferTTMS[];
double         BufferTTMSColors[];
double         BufferSig[];
double         BufferNoSig[];
//---
double         BufferMABB[];
double         BufferMAKL[];
double         BufferDEV[];
double         BufferATR[];
//--- global variables
double         dev_bb;
double         dev_kl;
int            period_bb;
int            period_kl;
int            period_sm;
int            size_sig;
int            handle_mabb;
int            handle_makl;
int            handle_dev;
int            handle_atr;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- setting global variables
   period_bb=int(InpPeriodBB<1 ? 1 : InpPeriodBB);
   period_kl=int(InpPeriodKL<1 ? 1 : InpPeriodKL);
   period_sm=int(InpPeriodSmoothKL<1 ? 1 : InpPeriodSmoothKL);
   dev_bb=(InpDevBB<0.1 ? 0.1 : InpDevBB);
   dev_kl=(InpDevKL<0.1 ? 0.1 : InpDevKL);
   size_sig=int(InpSizeSig<1 ? 1 : InpSizeSig);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferTTMS,INDICATOR_DATA);
   SetIndexBuffer(1,BufferTTMSColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BufferSig,INDICATOR_DATA);
   SetIndexBuffer(3,BufferNoSig,INDICATOR_DATA);
   SetIndexBuffer(4,BufferMABB,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufferMAKL,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BufferDEV,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,BufferATR,INDICATOR_CALCULATIONS);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(1,PLOT_ARROW,119);
   PlotIndexSetInteger(2,PLOT_ARROW,119);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,size_sig);
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,size_sig);
   PlotIndexSetInteger(2,PLOT_SHOW_DATA,false);
//--- settings indicators parameters
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetString(INDICATOR_SHORTNAME,"TTM Squeeze");
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferTTMS,true);
   ArraySetAsSeries(BufferTTMSColors,true);
   ArraySetAsSeries(BufferSig,true);
   ArraySetAsSeries(BufferNoSig,true);
   ArraySetAsSeries(BufferMABB,true);
   ArraySetAsSeries(BufferMAKL,true);
   ArraySetAsSeries(BufferDEV,true);
   ArraySetAsSeries(BufferATR,true);
//--- create MA's handles
   ResetLastError();
   handle_mabb=iMA(NULL,PERIOD_CURRENT,period_bb,0,MODE_SMA,PRICE_CLOSE);
   if(handle_mabb==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_bb,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   ResetLastError();
   handle_makl=iMA(NULL,PERIOD_CURRENT,period_kl,0,InpMethodKL,PRICE_CLOSE);
   if(handle_makl==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_kl,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   ResetLastError();
   handle_dev=iStdDev(NULL,PERIOD_CURRENT,period_bb,0,MODE_SMA,PRICE_CLOSE);
   if(handle_dev==INVALID_HANDLE)
     {
      Print("The iStdDev(",(string)period_bb,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   ResetLastError();
   handle_atr=iATR(NULL,PERIOD_CURRENT,period_sm);
   if(handle_atr==INVALID_HANDLE)
     {
      Print("The iATR(",(string)period_sm,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle_mabb!=INVALID_HANDLE) IndicatorRelease(handle_mabb);
   if(handle_makl!=INVALID_HANDLE) IndicatorRelease(handle_makl);
   if(handle_dev!=INVALID_HANDLE)  IndicatorRelease(handle_dev);
   if(handle_atr!=INVALID_HANDLE)  IndicatorRelease(handle_atr);
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
//--- Проверка на минимальное количество баров для расчёта
   if(rates_total<4 || Point()==0) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(BufferTTMS,EMPTY_VALUE);
      ArrayInitialize(BufferTTMSColors,EMPTY_VALUE);
      ArrayInitialize(BufferSig,EMPTY_VALUE);
      ArrayInitialize(BufferNoSig,EMPTY_VALUE);
      ArrayInitialize(BufferMABB,EMPTY_VALUE);
      ArrayInitialize(BufferMAKL,EMPTY_VALUE);
      ArrayInitialize(BufferDEV,EMPTY_VALUE);
      ArrayInitialize(BufferATR,EMPTY_VALUE);
     }
//--- Подготовка данных
   int copied=0,count=(limit==0 ? 1 : rates_total);
   copied=CopyBuffer(handle_atr,0,0,count,BufferATR);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_dev,0,0,count,BufferDEV);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_mabb,0,0,count,BufferMABB);
   if(copied!=count) return 0;
   copied=CopyBuffer(handle_makl,0,0,count,BufferMAKL);
   if(copied!=count) return 0;
//--- Расчёт индикатора
   for(int i=limit; i>=0; i--)
     {
      double H=BufferMAKL[i]+BufferATR[i]*dev_kl;
      double L=BufferMAKL[i]-BufferATR[i]*dev_kl;
      double D=BufferDEV[i];
      double TL=BufferMABB[i]+dev_bb*D;
      double BL=BufferMABB[i]-dev_bb*D;
      BufferTTMS[i]=(TL!=BL ? (H-L)/(TL-BL)-1 : 0);
      BufferTTMSColors[i]=(BufferTTMS[i+1]==EMPTY_VALUE ? 0 : (BufferTTMS[i]>BufferTTMS[i+1] ? 0 : 1));
      if(TL<H && BL>L)
        {
         BufferSig[i]=0;
         BufferNoSig[i]=EMPTY_VALUE;
        }
      else
        {
         BufferSig[i]=EMPTY_VALUE;
         BufferNoSig[i]=0;
        }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
