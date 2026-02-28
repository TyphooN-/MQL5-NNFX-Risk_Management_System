//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
#property version   "1.3"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   4

#property indicator_label2  "alma level up"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_DOT
#property indicator_label3  "alma middle level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT
#property indicator_label4  "alma level down"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSandyBrown
#property indicator_style4  STYLE_DOT
#property indicator_label1  "alma"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrSilver,clrDeepSkyBlue,clrSandyBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

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
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};
enum enColorOn
{
   cl_slope, // Change color on slope change
   cl_mid,   // Change color on middle level cross
   cl_out    // Change color on outer levels cross
};
enum enFilter
{
   flt_val, // Filter the value (alma)
   flt_prc, // Filter the price
   flt_all  // Filter all
};

input int      AlmaPeriod  = 14;       // Calculation period

input enPrices AlmaPrice   = pr_close; // Price to use
input double   AlmaSigma   = 6.0;      // Alma sigma
input double   AlmaSample  = 0.25;     // Alma sample
input enColorOn ColorOn    = cl_out;   // Color change on :  
input int      flLookBack  = 25;       // Floating levels look back period
input double   flLevelUp   = 90;       // Floating levels up level %
input double   flLevelDown = 10;       // Floating levels down level %
input int      fltPeriod   = 0;        // Filter period (<= 0 to use alma period
input double   fltFilter   = 0;        // Filter value (<=0 for no filtering)
input enFilter fltFilterOn = flt_val;  // Filter to be applied to :

//
//
//
//
//
//

double MaBuffer[],levup[],levmi[],levdn[];
double ColorBuffer[];

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
   SetIndexBuffer(2,levup,INDICATOR_DATA);
   SetIndexBuffer(3,levmi,INDICATOR_DATA);
   SetIndexBuffer(4,levdn,INDICATOR_DATA);
   SetIndexBuffer(0,MaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME,"Alma ("+(string)AlmaPeriod+","+(string)AlmaSigma+(string)AlmaSample+")");
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

int totalBars;
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
   totalBars = rates_total;
   
   //
   //
   //
   //
   //
      
      int    fperiod = fltPeriod; if (fperiod<=0)           fperiod=AlmaPeriod;
      double pfilter = fltFilter; if (fltFilterOn==flt_val) pfilter=0;
      double vfilter = fltFilter; if (fltFilterOn==flt_prc) vfilter=0;
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
      {
         double price = iFilter(getPrice(AlmaPrice,open,close,high,low,rates_total,i),pfilter,fperiod,i,rates_total,0);
                MaBuffer[i] = iFilter(iAlma(price,AlmaPeriod,AlmaSigma,AlmaSample,rates_total,i),vfilter,fperiod,i,rates_total,1);
                double min = MaBuffer[i];
                double max = MaBuffer[i];
                  for (int k=1; k<flLookBack && i-k>=0; k++)
                  {
                     min = MathMin(MaBuffer[i-k],min);
                     max = MathMax(MaBuffer[i-k],max);
                  }
                double range = max-min;
                levup[i] = min+flLevelUp*range/100.0;
                levdn[i] = min+flLevelDown*range/100.0;
                levmi[i] = min+0.5*range;
                
            //
            //
            //
            //
            //
                            
            ColorBuffer[i] = 0;
               switch (ColorOn)
               {
                  case cl_slope :
                     if (i>0)
                     {
                        if (MaBuffer[i]>MaBuffer[i-1]) ColorBuffer[i]=1;
                        if (MaBuffer[i]<MaBuffer[i-1]) ColorBuffer[i]=2;
                     }                        
                     break;
                  case cl_mid:                     
                     if (MaBuffer[i]>levmi[i]) ColorBuffer[i]=1;
                     if (MaBuffer[i]<levmi[i]) ColorBuffer[i]=2;
                     break;
                  default:                     
                     if (MaBuffer[i]>levup[i]) ColorBuffer[i]=1;
                     if (MaBuffer[i]<levdn[i]) ColorBuffer[i]=2;
                     break;
               }
      }
   
   //
   //
   //
   //
   //
   
   return(rates_total);
}

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

#define filterInstances 2
double workFil[][filterInstances*3];

#define _fchange 0
#define _fachang 1
#define _fprice  2

double iFilter(double tprice, double filter, int period, int i, int bars, int instanceNo=0)
{
   if (filter<=0) return(tprice);
   if (ArrayRange(workFil,0)!= bars) ArrayResize(workFil,bars); instanceNo*=3;
   
   //
   //
   //
   //
   //
   
   workFil[i][instanceNo+_fprice]  = tprice; if (i<1) return(tprice);
   workFil[i][instanceNo+_fchange] = MathAbs(workFil[i][instanceNo+_fprice]-workFil[i-1][instanceNo+_fprice]);
   workFil[i][instanceNo+_fachang] = workFil[i][instanceNo+_fchange];

   for (int k=1; k<period && (i-k)>=0; k++) workFil[i][instanceNo+_fachang] += workFil[i-k][instanceNo+_fchange];
                                            workFil[i][instanceNo+_fachang] /= period;
    
   double stddev = 0; for (int k=0;  k<period && (i-k)>=0; k++) stddev += MathPow(workFil[i-k][instanceNo+_fchange]-workFil[i-k][instanceNo+_fachang],2);
          stddev = MathSqrt(stddev/(double)period); 
   double filtev = filter * stddev;
   if( MathAbs(workFil[i][instanceNo+_fprice]-workFil[i-1][instanceNo+_fprice]) < filtev ) workFil[i][instanceNo+_fprice]=workFil[i-1][instanceNo+_fprice];
        return(workFil[i][instanceNo+_fprice]);
}

//
//
//
//
//

#define almaInstances 1
double  almaWork[][almaInstances];
double iAlma(double price, int period, double sigma, double sample, int bars, int r, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(almaWork,0)!=bars) ArrayResize(almaWork,bars); almaWork[r][instanceNo] = price;
   
   //
   //
   //
   //
   //

   double m = MathFloor(sample * (period - 1.0));
   double s = period/sigma, sum=0, div=0;
   for (int i=0; i<period && (r-i)>=0; i++)
      {
         double coeff = MathExp(-((i-m)*(i-m))/(2.0*s*s));
            sum += coeff*almaWork[r-i][instanceNo];
            div += coeff;
      }
   double talma = price; if (div!=0) talma = sum/div;
   return(talma);
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


double workHa[][4];
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int bars, int i,  int instanceNo=0)
{
  if (price>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars); instanceNo *= 4;
         
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
         
         switch (price)
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
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
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
   }
   return(0);
}