//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"
#property version   "1.0"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers    4
#property indicator_plots      1
#property indicator_label1     "tdfi"
#property indicator_type1      DRAW_LINE
#property indicator_color1     clrDeepSkyBlue
#property indicator_style1     STYLE_SOLID
#property indicator_width1     2
#property indicator_levelcolor clrMediumOrchid
//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enMaTypes
{
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma    // Linear weighted MA
};

input int        trendPeriod = 20;       // Period

input enMaTypes  trendMaType = ma_ema;   // Moving average method
input enPrices   trendPrice  = pr_close; // Price
input double     SmoothLength = 20;      // Smoothing period
input double     SmoothPhase  = 0;       // Smoothing phase
input double    dead_zone    =  0.05;   // Dead-zone

double TrendBuffer[],MMABuffer[],SMMABuffer[],TDFBuffer[];

//--- Monotone max-deque over |TDFBuffer| for O(1) amortized sliding window max
int g_absDq[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,TrendBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MMABuffer,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,SMMABuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,TDFBuffer,  INDICATOR_CALCULATIONS);
   IndicatorSetInteger(INDICATOR_LEVELS,0);
   IndicatorSetString(INDICATOR_SHORTNAME,"trend direction and force ("+(string)trendPeriod+")");
   int dqCap = trendPeriod * 3 + 1;
   if(ArrayResize(g_absDq, dqCap) == -1) return INIT_FAILED;
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{
   if (Bars(_Symbol,_Period)<rates_total) return(-1);

   //--- Monotone max-deque over |TDFBuffer| for O(1) amortized sliding max
   int dqCap = trendPeriod * 3 + 1;
   int window = trendPeriod * 3;
   int firstOutput = (int)fmax(prev_calculated - 1, 0);
   int startBar    = (int)fmax(firstOutput - window + 1, 0);
   int maxH = 0, maxT = 0;

   //--- Pre-warmup: seed deque using already-computed TDFBuffer[] values
   for (int b = startBar; b < firstOutput; b++)
   {
      double va = MathAbs(TDFBuffer[b]);
      while (maxT > maxH && MathAbs(TDFBuffer[g_absDq[(maxT - 1) % dqCap]]) <= va) maxT--;
      g_absDq[maxT % dqCap] = b; maxT++;
      while (maxH < maxT && g_absDq[maxH % dqCap] < b - window + 1) maxH++;
   }

   double alpha = 2.0 /(trendPeriod+1.0);
   for (int i = firstOutput; i < rates_total && !IsStopped(); i++)
   {
       double price  = getPrice(trendPrice,open,close,high,low,i,rates_total);
       MMABuffer[i]  = iCustomMa(trendMaType,price,trendPeriod,i,rates_total,0);
       SMMABuffer[i] = (i>0) ? SMMABuffer[i-1]+alpha*(MMABuffer[i]-SMMABuffer[i-1]) : MMABuffer[i];
             double impetmma   = (i>0) ? MMABuffer[i]  - MMABuffer[i-1]  : 0;
              double impetsmma = (i>0) ? SMMABuffer[i] - SMMABuffer[i-1] : 0;
              double ptSize    = (_Point > 0) ? _Point : 1e-5;
              double divma     = fabs(MMABuffer[i]-SMMABuffer[i])/ptSize;
              double averimpet = (impetmma+impetsmma)/(2*ptSize);
        TDFBuffer[i] = divma*MathPow(averimpet,3);

        //--- Push |TDFBuffer[i]| onto max-deque and evict expired indices
        double vi = MathAbs(TDFBuffer[i]);
        while (maxT > maxH && MathAbs(TDFBuffer[g_absDq[(maxT - 1) % dqCap]]) <= vi) maxT--;
        g_absDq[maxT % dqCap] = i; maxT++;
        while (maxH < maxT && g_absDq[maxH % dqCap] < i - window + 1) maxH++;

        double absValue = MathAbs(TDFBuffer[g_absDq[maxH % dqCap]]);
        if (absValue > 0)
              TrendBuffer[i] = iSmooth(TDFBuffer[i]/absValue,SmoothLength,SmoothPhase,i,rates_total,0);
        else  TrendBuffer[i] = iSmooth(0.00,                 SmoothLength,SmoothPhase,i,rates_total,0);

        TrendBuffer[i] = MathAbs(TrendBuffer[i]) - dead_zone;
   }
   return(rates_total);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

#define _maInstances 1
#define _maWorkBufferx1 1*_maInstances
double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//
//
//

double workSma[][_maWorkBufferx1];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= _bars) { if (ArrayResize(workSma,_bars)==-1) return(0); }

   //--- O(1) running sum (instanceNo=0 fast path; non-zero falls back to O(period))
   static double s_sum = 0;
   static int    s_lastR = -2;
   static int    s_period = -1;
   if (instanceNo == 0)
     {
      if (s_period != period || r != s_lastR + 1)
        {
         s_sum = 0;
         int start = MathMax(0, r - period + 1);
         for (int j = start; j < r; j++) s_sum += workSma[j][0];
         s_sum += price;
         s_period = period;
        }
      else
        {
         s_sum += price;
         if (r - period >= 0) s_sum -= workSma[r - period][0];
        }
      workSma[r][0] = price;
      s_lastR = r;
      int n = (r + 1 < period) ? (r + 1) : period;
      return s_sum / (double)n;
     }
   //--- Fallback (O(period)) for non-default instanceNo
   workSma[r][instanceNo] = price;
   double avg = price; int k = 1;
   for (; k<period && (r-k)>=0; k++) avg += workSma[r-k][instanceNo];
   return avg / (double)k;
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) { if (ArrayResize(workEma,_bars)==-1) return(0); }

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= _bars) { if (ArrayResize(workSmma,_bars)==-1) return(0); }

   workSmma[r][instanceNo] = price;
   if (r>1 && period>1)
          workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= _bars) { if (ArrayResize(workLwma,_bars)==-1) return(0); }
   if (period<1) { workLwma[r][instanceNo] = price; return(price); }

   //--- O(1) via two running sums: A=Σwork[j], B=Σj·work[j] over window
   //--- numerator = Σ(period-k)·work[r-k] = (period-r)·A + B
   int iper = (int)period;
   static double s_A = 0, s_B = 0;
   static int    s_lastR = -2;
   static int    s_period = -1;
   if (instanceNo == 0)
     {
      if (s_period != iper || r != s_lastR + 1)
        {
         s_A = 0; s_B = 0;
         int start = MathMax(0, r - iper + 1);
         for (int j = start; j < r; j++)
           {
            s_A += workLwma[j][0];
            s_B += (double)j * workLwma[j][0];
           }
         s_A += price;
         s_B += (double)r * price;
         s_period = iper;
        }
      else
        {
         s_A += price;
         s_B += (double)r * price;
         if (r - iper >= 0)
           {
            double drop = workLwma[r - iper][0];
            s_A -= drop;
            s_B -= (double)(r - iper) * drop;
           }
        }
      workLwma[r][0] = price;
      s_lastR = r;
      int n_used = (r + 1 < iper) ? (r + 1) : iper;
      //--- Partial window (r < period-1): sumw = (n+1)·(2·period-n)/2 with n=r
      //--- Full window    (r >= period-1): sumw = period·(period+1)/2
      double sumw = (double)n_used * (2.0 * period - (double)(n_used - 1)) / 2.0;
      double num  = (period - (double)r) * s_A + s_B;
      return num / sumw;
     }
   //--- Fallback (O(period)) for non-default instanceNo
   workLwma[r][instanceNo] = price;
   double sumw = period;
   double sum  = period*price;
   for(int k=1; k<period && (r-k)>=0; k++)
     {
      double weight = period-k;
      sumw  += weight;
      sum   += weight*workLwma[r-k][instanceNo];
     }
   return sum / sumw;
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//

#define _pricesInstances 1
#define _pricesSize      4
double workHa[][_pricesInstances*_pricesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) { if (ArrayResize(workHa,_bars)==-1) return(0); } instanceNo*=_pricesSize;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

#define _smoothInstances     1
#define _smoothInstancesSize 10
double  _smthWork[][_smoothInstances*_smoothInstancesSize];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iSmooth(double price, double length, double phase, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(_smthWork,0)!=bars) { if (ArrayResize(_smthWork,bars)==-1) return(0); } instanceNo*=_smoothInstancesSize;
   if (price==EMPTY_VALUE) price=0;

   int k = 0; if (r==0) { for(; k<7; k++) _smthWork[0][instanceNo+k]=price; for(; k<10; k++) _smthWork[0][instanceNo+k]=0; return(price); }

      //
      //
      //
      //
      //
  
      double len1   = fmax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = fmax(len1-2.0,0.5);
      double del1   = price - _smthWork[r-1][instanceNo+bsmax];
      double del2   = price - _smthWork[r-1][instanceNo+bsmin];
      double div    = 1.0/(10.0+10.0*(fmin(fmax(length-10,0),100))/100);
      int    forBar = (int)fmin(r,10);

         _smthWork[r][instanceNo+volty] = (fabs(del1)>fabs(del2)) ? fabs(del1): (fabs(del1)<fabs(del2)) ? fabs(del2) : 0;
         _smthWork[r][instanceNo+vsum]  = _smthWork[r-1][instanceNo+vsum] + (_smthWork[r][instanceNo+volty]-_smthWork[r-forBar][instanceNo+volty])*div;
        
         //
         //
         //
         //
         //
              
         _smthWork[r][instanceNo+avolty] = _smthWork[r-1][instanceNo+avolty]+(2.0/(fmax(4.0*length,30)+1.0))*(_smthWork[r][instanceNo+vsum]-_smthWork[r-1][instanceNo+avolty]);
         double dVolty = (_smthWork[r][instanceNo+avolty] > 0) ? _smthWork[r][instanceNo+volty]/_smthWork[r][instanceNo+avolty] : 0;  
            if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
            if (dVolty < 1)                      dVolty = 1.0;

         //
         //
         //
         //
         //
        
         double pow2 = MathPow(dVolty, pow1);
         double len2 = MathSqrt(0.5*(length-1))*len1;
         double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

            if (del1 > 0) _smthWork[r][instanceNo+bsmax] = price; else _smthWork[r][instanceNo+bsmax] = price - Kv*del1;
            if (del2 < 0) _smthWork[r][instanceNo+bsmin] = price; else _smthWork[r][instanceNo+bsmin] = price - Kv*del2;

      //
      //
      //
      //
      //
      
      double R     = fmax(fmin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         _smthWork[r][instanceNo+0] = price + alpha*(_smthWork[r-1][instanceNo+0]-price);
         _smthWork[r][instanceNo+1] = (price - _smthWork[r][instanceNo+0])*(1-beta) + beta*_smthWork[r-1][instanceNo+1];
         _smthWork[r][instanceNo+2] = (_smthWork[r][instanceNo+0] + R*_smthWork[r][instanceNo+1]);
         _smthWork[r][instanceNo+3] = (_smthWork[r][instanceNo+2] - _smthWork[r-1][instanceNo+4])*MathPow((1-alpha),2) + MathPow(alpha,2)*_smthWork[r-1][instanceNo+3];
         _smthWork[r][instanceNo+4] = (_smthWork[r-1][instanceNo+4] + _smthWork[r][instanceNo+3]);

   //
   //
   //
   //
   //

   return(_smthWork[r][instanceNo+4]);
}
