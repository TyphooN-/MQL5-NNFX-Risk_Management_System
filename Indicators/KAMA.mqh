//+------------------------------------------------------------------+
//|                                                          KAMA.mqh |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
//--- input parameters
input int      InpPeriodAMA=10;      // AMA period
input int      InpFastPeriodEMA=2;   // Fast EMA period
input int      InpSlowPeriodEMA=30;  // Slow EMA period
int      InpShiftAMA=0;        // AMA shift
//--- indicator buffers
double         ExtAMABuffer[];
//--- global variables
double         ExtFastSC;
double         ExtSlowSC;
int            ExtPeriodAMA;
int            ExtSlowPeriodEMA;
int            ExtFastPeriodEMA;
//+------------------------------------------------------------------+
//| AMA initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- check for input values
   if(InpPeriodAMA<=0)
     {
      ExtPeriodAMA=10;
      printf("Input parameter InpPeriodAMA has incorrect value (%d). Indicator will use value %d for calculations.",
             InpPeriodAMA,ExtPeriodAMA);
     }
   else ExtPeriodAMA=InpPeriodAMA;
   if(InpSlowPeriodEMA<=0)
     {
      ExtSlowPeriodEMA=30;
      printf("Input parameter InpSlowPeriodEMA has incorrect value (%d). Indicator will use value %d for calculations.",
             InpSlowPeriodEMA,ExtSlowPeriodEMA);
     }
   else ExtSlowPeriodEMA=InpSlowPeriodEMA;
   if(InpFastPeriodEMA<=0)
     {
      ExtFastPeriodEMA=2;
      printf("Input parameter InpFastPeriodEMA has incorrect value (%d). Indicator will use value %d for calculations.",
             InpFastPeriodEMA,ExtFastPeriodEMA);
     }
   else ExtFastPeriodEMA=InpFastPeriodEMA;
//--- indicator buffers mapping
#ifdef __MQL5__
   SetIndexBuffer(0,ExtAMABuffer,INDICATOR_DATA);
#else
   #ifdef __MQL4__
   SetIndexBuffer(0,ExtAMABuffer);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrWhite);
   SetIndexLabel(0,"KAMA");
   #endif
#endif
//--- set shortname and change label
   string short_name="KAMA("+IntegerToString(ExtPeriodAMA)+","+
                      IntegerToString(ExtFastPeriodEMA)+","+
                      IntegerToString(ExtSlowPeriodEMA)+")";
#ifdef __MQL5__
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   PlotIndexSetString(0,PLOT_LABEL,short_name);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodAMA);
//--- set index shift
   PlotIndexSetInteger(0,PLOT_SHIFT,InpShiftAMA);
#else
   #ifdef __MQL4__
   IndicatorShortName(short_name);
   IndicatorDigits(Digits+1);
   SetIndexDrawBegin(0,ExtPeriodAMA);
   SetIndexShift(0,InpShiftAMA);
   #endif
#endif
//--- calculate ExtFastSC & ExtSlowSC
   ExtFastSC=2.0/(ExtFastPeriodEMA+1.0);
   ExtSlowSC=2.0/(ExtSlowPeriodEMA+1.0);
//--- OnInit done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Calculate ER value                                               |
//+------------------------------------------------------------------+
double CalculateER(const int nPosition,const double &PriceData[])
  {
   double dSignal=fabs(PriceData[nPosition]-PriceData[nPosition-ExtPeriodAMA]);
   double dNoise=0.0;
   for(int delta=0;delta<ExtPeriodAMA;delta++)
      dNoise+=fabs(PriceData[nPosition-delta]-PriceData[nPosition-delta-1]);
   if(dNoise!=0.0)
      return(dSignal/dNoise);
   return(0.0);
  }
//+------------------------------------------------------------------+
//| AMA iteration function                                           |
//+------------------------------------------------------------------+
#ifdef __MQL5__
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int i;
//--- check for rates count
   if(rates_total<ExtPeriodAMA+begin)
      return(0);
//--- draw begin may be corrected
   if(begin!=0) PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodAMA+begin);
//--- detect position
   int pos=prev_calculated-1;
//--- first calculations
   if(pos<ExtPeriodAMA+begin)
     {
      pos=ExtPeriodAMA+begin;
      for(i=0;i<pos-1;i++) ExtAMABuffer[i]=0.0;
      ExtAMABuffer[pos-1]=price[pos-1];
     }
//--- main cycle
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      //--- calculate SSC
      double dCurrentSSC=(CalculateER(i,price)*(ExtFastSC-ExtSlowSC))+ExtSlowSC;
      //--- calculate AMA
      double dPrevAMA=ExtAMABuffer[i-1];
      ExtAMABuffer[i]=dCurrentSSC*dCurrentSSC*(price[i]-dPrevAMA)+dPrevAMA;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
#else
#ifdef __MQL4__
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
   int i;
//--- check for rates count
   if(rates_total<ExtPeriodAMA)
      return(0);
//--- detect position
   int pos=prev_calculated-1;
//--- first calculations
   if(pos<ExtPeriodAMA)
     {
      pos=ExtPeriodAMA;
      for(i=0;i<pos-1;i++) ExtAMABuffer[i]=0.0;
      ExtAMABuffer[pos-1]=close[pos-1];
     }
//--- main cycle
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      //--- calculate SSC
      double dCurrentSSC=(CalculateER(i,close)*(ExtFastSC-ExtSlowSC))+ExtSlowSC;
      //--- calculate AMA
      double dPrevAMA=ExtAMABuffer[i-1];
      ExtAMABuffer[i]=dCurrentSSC*dCurrentSSC*(close[i]-dPrevAMA)+dPrevAMA;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
#endif
#endif
//+------------------------------------------------------------------+
