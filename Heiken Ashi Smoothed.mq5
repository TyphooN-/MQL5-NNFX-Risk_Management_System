//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "mod by Botan626, 2022"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_label1  "HA Open;HA High;HA Low;HA Close"
#property indicator_type1   DRAW_COLOR_CANDLES 
#property indicator_color1  clrNONE,clrNONE,clrNONE
//
//---
//
enum enT3Type
{
   t3_tillson  = (int)true,  // Tim Tillson way of calculation
   t3_fulksmat = (int)false  // Fulks/Matulich way of calculation
};
//---
enum enMaTypes
  {
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma,   // Linear weighted MA
   t3         // T3
  };
//---
input int             inpMaPeriod         = 3;              // Smoothing period
input enMaTypes       inpMaMethod         = t3;             // Smoothing method
input double          inpT3Hot            = 1.0;            // T3 volume factor
input enT3Type        inpT3Original       = t3_fulksmat;    // T3 calculation mode
input bool            inpSortedValues     = true;           // Use sorted values?
input bool            inpBetterFormula    = true;           // Use better formula?
input int             inpStep             = 0;              // Step size (in pips) 
input color           inpBullColor        = clrLimeGreen;   // Bullish candle color
input color           inpBearColor        = clrDarkOrange;  // Bearish candle color
input int             inpIndDigits        = 5;              // Values accuracy in Data Window
//---
//
double hao[],hah[],hal[],hac[],haC[];
//------------------------------------------------------------------
//
//------------------------------------------------------------------
int OnInit()
  {
   IndicatorSetInteger(INDICATOR_DIGITS,inpIndDigits);
//---
   SetIndexBuffer(0,hao,INDICATOR_DATA);
   SetIndexBuffer(1,hah,INDICATOR_DATA);
   SetIndexBuffer(2,hal,INDICATOR_DATA);
   SetIndexBuffer(3,hac,INDICATOR_DATA);
   SetIndexBuffer(4,haC,INDICATOR_COLOR_INDEX);
//---
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,clrSilver);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,inpBullColor);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,2,inpBearColor);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
   
   //
   //
   //
   double _pointModifier = MathPow(10,SymbolInfoInteger(_Symbol,SYMBOL_DIGITS)%2);
//---
   int limit = prev_calculated>0 ? prev_calculated-1 : 0;
   for(int i=limit; i<rates_total && !_StopFlag; i++)
     {
      double maOpen, maHigh, maLow, maClose;
//---
      if(inpMaMethod==t3){
      maOpen  = iT3(open[i], inpMaPeriod,inpT3Hot,inpT3Original,i,rates_total,0);
      maHigh  = iT3(high[i], inpMaPeriod,inpT3Hot,inpT3Original,i,rates_total,1);
      maLow   = iT3(low[i],  inpMaPeriod,inpT3Hot,inpT3Original,i,rates_total,2);
      maClose = iT3(close[i],inpMaPeriod,inpT3Hot,inpT3Original,i,rates_total,3);}
//---
      else{
      maOpen  = iCustomMa(inpMaMethod,open[i] ,inpMaPeriod,i,rates_total,0);
      maHigh  = iCustomMa(inpMaMethod,high[i] ,inpMaPeriod,i,rates_total,1);
      maLow   = iCustomMa(inpMaMethod,low[i]  ,inpMaPeriod,i,rates_total,2);
      maClose = iCustomMa(inpMaMethod,close[i],inpMaPeriod,i,rates_total,3);}
//---
      if(inpSortedValues)
         {
            double sort[4];
                   sort[0] = maOpen;
                   sort[1] = maClose;
                   sort[2] = maLow;
                   sort[3] = maHigh;
                     ArraySort(sort);
                        maLow  = sort[0];
                        maHigh = sort[3];
                        if (open[i]>close[i])
                              { maOpen = sort[2]; maClose = sort[1]; }
                        else  { maOpen = sort[1]; maClose = sort[2]; }
         }
//---
      double haClose = (inpBetterFormula) ? (maHigh!=maLow) ? (maOpen+maClose)/2+(((maClose-maOpen)/(maHigh-maLow))*MathAbs((maClose-maOpen)/2)) : (maOpen+maClose)/2 : (maOpen+maHigh+maLow+maClose)/4;
      double haOpen  = (i>0) ? (hao[i-1]+hac[i-1])/2 : open[i];
      double haHigh  = MathMax(maHigh, MathMax(haOpen,haClose));
      double haLow   = MathMin(maLow,  MathMin(haOpen,haClose));
//---
      hao[i]=haOpen;
      hah[i]=haHigh;
      hal[i]=haLow;
      hac[i]=haClose;
//---
      if(i>0 && inpStep>0)
        {
         if(MathAbs(hah[i]-hah[i-1]) < inpStep*_pointModifier*_Point) hah[i]=hah[i-1];
         if(MathAbs(hal[i]-hal[i-1]) < inpStep*_pointModifier*_Point) hal[i]=hal[i-1];
         if(MathAbs(hao[i]-hao[i-1]) < inpStep*_pointModifier*_Point) hao[i]=hao[i-1];
         if(MathAbs(hac[i]-hac[i-1]) < inpStep*_pointModifier*_Point) hac[i]=hac[i-1];
        }
//---
      haC[i] = hao[i]>hac[i] ? 2 : (hao[i]<hac[i] ? 1 : (i>0 ? haC[i-1] : 0));
     }
   return rates_total;
  }

//------------------------------------------------------------------
// custom functions
//------------------------------------------------------------------
#define _maInstances 4
#define _maWorkBufferx1 1*_maInstances
//
//
//
double iCustomMa(int mode,double price,double length,int r,int bars,int instanceNo=0)
  {
   switch(mode)
     {
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
     }
  }
//
//---
//
double workSma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iSma(double price,int period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSma,0)!=_bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo]=price;
   double avg=price; int k=1; for(; k<period && (r-k)>=0; k++) avg+=workSma[r-k][instanceNo];  avg/=(double)k;
   return(avg);
  }
//
//---
//
double workEma[][_maWorkBufferx1];
//
//
//
double iEma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=_bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }
//
//---
//
double workSmma[][_maWorkBufferx1];
//
//
//
double iSmma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSmma,0)!=_bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo]=price;
   if(r>1 && period>1)
      workSmma[r][instanceNo]=workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
  }
//
//---
//
double workLwma[][_maWorkBufferx1];
//
//
//
double iLwma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workLwma,0)!=_bars) ArrayResize(workLwma,_bars);

   workLwma[r][instanceNo] = price; if(period<1) return(price);
   double sumw = period;
   double sum  = period*price;

   for(int k=1; k<period && (r-k)>=0; k++)
     {
      double weight = period-k;
      sumw  += weight;
      sum   += weight*workLwma[r-k][instanceNo];
     }
   return(sum/sumw);
  }
//+------------------------------------------------------------------+
//
//---
//
#define _maT3Instances 4
double iT3(double value, double period, double volumeFactor, bool original, int r, int bars, int instanceNo=0)
{
   struct sCoeffStruct
         {
            double volumeFactor;
            double volumePlus;
            double period;
            double alpha;
            double result;
            bool   original;
               sCoeffStruct() : period(EMPTY_VALUE) {}
         };
   static sCoeffStruct m_coeffs[_maT3Instances];
   struct sDataStruct
         {
            double val[7];
         };
   struct sWorkStruct { sDataStruct data[_maT3Instances]; };
   static sWorkStruct m_array[];
   static int         m_arraySize = -1;
                  if (m_arraySize<=bars) m_arraySize = ArrayResize(m_array,bars+500,2000);
                  if (m_coeffs[instanceNo].period       != (period)  ||
                      m_coeffs[instanceNo].volumeFactor != volumeFactor)
                      {
                        m_coeffs[instanceNo].period       = (period > 1) ? period : 1;
                        m_coeffs[instanceNo].alpha        = (original) ? 2.0/(1.0+m_coeffs[instanceNo].period) : 2.0/(2.0+(m_coeffs[instanceNo].period-1.0)/2.0);
                        m_coeffs[instanceNo].volumeFactor = (volumeFactor>0) ? (volumeFactor>1) ? 1 : volumeFactor : DBL_MIN;
                        m_coeffs[instanceNo].volumePlus   = (m_coeffs[instanceNo].volumeFactor+1);
                      }

      //
      //
      //

         if (r>0)
         {
               #define _gdema(_part1,_part2) (m_array[r].data[instanceNo].val[_part1]*m_coeffs[instanceNo].volumePlus - m_array[r].data[instanceNo].val[_part2]*m_coeffs[instanceNo].volumeFactor)
                     m_array[r].data[instanceNo].val[0] = m_array[r-1].data[instanceNo].val[0]+m_coeffs[instanceNo].alpha*(value                             -m_array[r-1].data[instanceNo].val[0]);
                     m_array[r].data[instanceNo].val[1] = m_array[r-1].data[instanceNo].val[1]+m_coeffs[instanceNo].alpha*(m_array[r].data[instanceNo].val[0]-m_array[r-1].data[instanceNo].val[1]);
                     m_array[r].data[instanceNo].val[2] = m_array[r-1].data[instanceNo].val[2]+m_coeffs[instanceNo].alpha*(_gdema(0,1)                       -m_array[r-1].data[instanceNo].val[2]);
                     m_array[r].data[instanceNo].val[3] = m_array[r-1].data[instanceNo].val[3]+m_coeffs[instanceNo].alpha*(m_array[r].data[instanceNo].val[2]-m_array[r-1].data[instanceNo].val[3]);
                     m_array[r].data[instanceNo].val[4] = m_array[r-1].data[instanceNo].val[4]+m_coeffs[instanceNo].alpha*(_gdema(2,3)                       -m_array[r-1].data[instanceNo].val[4]);
                     m_array[r].data[instanceNo].val[5] = m_array[r-1].data[instanceNo].val[5]+m_coeffs[instanceNo].alpha*(m_array[r].data[instanceNo].val[4]-m_array[r-1].data[instanceNo].val[5]);
                     m_array[r].data[instanceNo].val[6] =                             _gdema(4,5);
               #undef _gdema
         }
         else   ArrayInitialize(m_array[r].data[instanceNo].val,value);
         return(m_array[r].data[instanceNo].val[6]);
}         
//+------------------------------------------------------------------+
