//+----------------------------------------------------------------------------+
//|                                                           Braid_Filter.mq4 |
//| Braid Filter indicator of Robert Hill stocks and commodities magazine 2006 |
//| MT4 code by Max Michael 2021                                               |
//+----------------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers   4
#property indicator_color1    Green
#property indicator_width1    4 
#property indicator_color2    Red
#property indicator_width2    4
#property indicator_color3    Gray
#property indicator_width3    4
#property indicator_color4    DodgerBlue
#property indicator_width4    2
#property strict

//---- input parameters
extern int                MAperiod1 = 3;
extern int                MAperiod2 = 7;
extern int                MAperiod3 = 14;
extern int                ATRPeriod = 14;
extern double     PipsMinSepPercent = 40;
input ENUM_MA_METHOD         ModeMA = MODE_SMMA;

//---- buffers
double BufferUP[];
double BufferDN[];
double BufferZ[];
double Vfilter[];

int init()
{
   SetIndexBuffer(0,BufferUP); SetIndexStyle(0,DRAW_HISTOGRAM,EMPTY,4);
   SetIndexBuffer(1,BufferDN); SetIndexStyle(1,DRAW_HISTOGRAM,EMPTY,4);
   SetIndexBuffer(2,BufferZ); SetIndexStyle(2,DRAW_HISTOGRAM,EMPTY,4);
   SetIndexBuffer(3,Vfilter);  SetIndexStyle(3,DRAW_LINE,EMPTY,2);
   return(0);
}

int start()
{
   int MAperiod=MathMax(MathMax(MAperiod1,MAperiod2),MAperiod2);
   int limit=0, counted_bars=IndicatorCounted();
   if (counted_bars < 0) return(-1);
   if (counted_bars ==0) limit=Bars-MAperiod-1;
   if (counted_bars < 1) //initialize
   
   for(int i=1; i<MAperiod; i++) { BufferUP[Bars-i]=0; BufferDN[Bars-i]=0; BufferZ[Bars-i]=0; }
   if(counted_bars>0) limit=Bars-counted_bars;
   limit--;
   
   for(int i=limit; i>=0; i--)
   {
      double ma1=iMA(NULL,0,MAperiod1,0,ModeMA,PRICE_CLOSE,i);
      double ma2=iMA(NULL,0,MAperiod2,0,ModeMA,PRICE_OPEN,i);
      double ma3=iMA(NULL,0,MAperiod3,0,ModeMA,PRICE_CLOSE,i);
      double max=MathMax(MathMax(ma1,ma2),ma3);
      double min=MathMin(MathMin(ma1,ma2),ma3);
      double dif=max - min;
      double atr=iATR(NULL,0,ATRPeriod*2-1,i+1); //period*2-1 = wilders smoothing
      double filter=atr * PipsMinSepPercent / 100;
      
      if      (ma1>ma2 && dif>filter) { BufferUP[i]=dif; BufferDN[i]=0; BufferZ[i]=0; } //green
      else if (ma2>ma1 && dif>filter) { BufferDN[i]=dif; BufferUP[i]=0; BufferZ[i]=0; } //red
      else { BufferDN[i]=0; BufferUP[i]=0; BufferZ[i]=dif; } //gray
      Vfilter[i]=filter;
   }
   return(0);
}
