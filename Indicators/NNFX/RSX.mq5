//+------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "Corrected RSX"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_label1  "RSX"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepSkyBlue,clrLightSalmon
#property indicator_style1  STYLE_DOT
#property indicator_label2  "Corrected RSX"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDarkGray,clrDeepSkyBlue,clrLightSalmon
#property indicator_width2  2
//--- input parameters
input int                inpRsiPeriod  =  14;         // RSX period
input ENUM_APPLIED_PRICE inpPrice      = PRICE_CLOSE; // Price 
//--- buffers declarations
double val[],valc[],rsi[],rsic[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,rsi,INDICATOR_DATA);
   SetIndexBuffer(1,rsic,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,val,INDICATOR_DATA);
   SetIndexBuffer(3,valc,INDICATOR_COLOR_INDEX);
//--- indicator short name assignment
   IndicatorSetString(INDICATOR_SHORTNAME,"Corrected RSX ("+(string)inpRsiPeriod+")");
//---
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   double _rsiVal[1];
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      rsi[i]  = iRsx(getPrice(inpPrice,open,close,high,low,i,rates_total),inpRsiPeriod,i);
      val[i]  = iCorrMa(rsi[i],rsi[i],inpRsiPeriod,i,rates_total);
      valc[i] = (i>0) ? (val[i]>val[i-1]) ? 1 :(val[i]<val[i-1]) ? 2 : valc[i-1] : 0;
      rsic[i] = (i>0) ? (rsi[i]>rsi[i-1]) ? 1 : (rsi[i]<rsi[i-1]) ? 2 : rsic[i-1] : 0;
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
#define _corrMaInstances 1
#define _corrMaInstancesSize 3
double workCorrMa[][_corrMaInstances*_corrMaInstancesSize];
#define _price 0
#define _orig  1
#define _corr  2
//
//---
//
double iCorrMa(double _avg, double price, int period, int i, int _bars, int instanceNo=0)
{
   if (ArrayRange(workCorrMa,0)!= _bars) ArrayResize(workCorrMa,_bars); instanceNo*=_corrMaInstancesSize;
      workCorrMa[i][_price] = price;
      workCorrMa[i][_orig]  = _avg;

      //
      //---
      //
      
      double oldMean   = price;
      double newMean   = price;
      double squares   = 0; int k=1;
      for (; k<period && (i-k)>=0; k++)
      {
         newMean  = (workCorrMa[i-k][_price]-oldMean)/(k+1)+oldMean;
         squares += (workCorrMa[i-k][_price]-oldMean)*(workCorrMa[i-k][_price]-newMean);
         oldMean  = newMean;
      }
      double _deviation = MathSqrt(squares/k);
      double v1         = MathPow(_deviation,2);
      double v2         = (i>0) ? MathPow(workCorrMa[i-1][_corr]-workCorrMa[i][_orig],2) : 0;
      double c          = (v2<v1||v2==0) ? 0 : 1-v1/v2;
          workCorrMa[i][_corr] = (i>0) ? workCorrMa[i-1][_corr]+c*(workCorrMa[i][_orig]-workCorrMa[i-1][_corr]) : workCorrMa[i][_orig];
   return(workCorrMa[i][_corr]);
   #undef _price
   #undef _orig
   #undef _corr
}
//
//---
//
#define _rsxInstances      1
#define _rsxInstancesSize 13
#define _rsxRingSize       5
double workRsi[_rsxRingSize][_rsxInstances*_rsxInstancesSize];
//
//---
//
double iRsx(double price,double period,int i, int instance=0)
{
   int _indP = (int)MathMod(i-1,_rsxRingSize);
   int _indC = (int)MathMod(i  ,_rsxRingSize);
   int _inst = instance*_rsxInstancesSize;
   
      workRsi[_indC][_inst]=price; if(i<period) { for(int k=1; k<_rsxInstancesSize; k++) workRsi[_indC][_inst+k]=0; return(50); }
      
      //
      //
      //

      double Kg  = (3.0)/(2.0+period), Hg = 1.0-Kg;
      double mom = workRsi[_indC][_inst]-workRsi[_indP][_inst];
      double moa = MathAbs(mom);
      for(int k=0; k<3; k++)
      {
         int kk=_inst+k*2;
         workRsi[_indC][kk+1] = Kg*mom                  + Hg*workRsi[_indP][kk+1];
         workRsi[_indC][kk+2] = Kg*workRsi[_indC][kk+1] + Hg*workRsi[_indP][kk+2]; mom = 1.5*workRsi[_indC][kk+1] - 0.5 * workRsi[_indC][kk+2];
         workRsi[_indC][kk+7] = Kg*moa                  + Hg*workRsi[_indP][kk+7];
         workRsi[_indC][kk+8] = Kg*workRsi[_indC][kk+7] + Hg*workRsi[_indP][kk+8]; moa = 1.5*workRsi[_indC][kk+7] - 0.5 * workRsi[_indC][kk+8];
     }
   return(MathMax(MathMin((mom/MathMax(moa,DBL_MIN)+1.0)*50.0,100.00),0.00));
}//
//---
//
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   if(i>=0)
      switch(tprice)
        {
         case PRICE_CLOSE:     return(close[i]);
         case PRICE_OPEN:      return(open[i]);
         case PRICE_HIGH:      return(high[i]);
         case PRICE_LOW:       return(low[i]);
         case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
         case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
         case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
        }
   return(0);
  }
//+------------------------------------------------------------------+
