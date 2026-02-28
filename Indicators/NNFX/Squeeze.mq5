//------------------------------------------------------------------
#property copyright "© mladen, 2019"
#property link      "mladenfx@gmail.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_label1  "Squeeze"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrOrangeRed
#property indicator_width1  2
#property indicator_label2  "Squeeze line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGray
#property indicator_width2  0

//
//
//

input int     inpPeriod        = 20; // Period
input double  inpDevMultiplier = 1;  // Deviation multiplier
input double  inpAtrMultiplier = 1;  // ATR multiplier

//
//
//
double val[],vall[],valc[];

//------------------------------------------------------------------
// 
//------------------------------------------------------------------
//
//
//

int OnInit()
{
   //
   //
   //
         SetIndexBuffer(0,val ,INDICATOR_DATA);
         SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
         SetIndexBuffer(2,vall,INDICATOR_DATA);
            iSqueeze.init(inpPeriod,inpDevMultiplier,inpAtrMultiplier);
   //
   //
   //
   IndicatorSetString(INDICATOR_SHORTNAME,"Squeeze ("+(string)inpPeriod+","+(string)inpDevMultiplier+","+(string)inpAtrMultiplier+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}

//------------------------------------------------------------------
// 
//------------------------------------------------------------------
//
//
//

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
      val[i]  = vall[i] = iSqueeze.calculate(close,high,low,i,rates_total);
      valc[i] = (val[i]==1) ? 1 : (val[i]==-1) ? 2 : 0;
   }
   return(i);
}

//------------------------------------------------------------------
// 
//------------------------------------------------------------------
//
//---
//

class cSqueeze
{
   private :
      int    m_period;
      int    m_arraySize;
      double m_devMultiplier;
      double m_atrMultiplier;
         struct sSqueezeStruct
         {
            public :
               double price;
               double price2;
               double sum;
               double sum2;
               double tr;
               double sumtr;
         };
      sSqueezeStruct m_array[];
   public:
      cSqueeze() : m_period(1), m_arraySize(-1), m_devMultiplier(2) {                     }
     ~cSqueeze()                                                    { ArrayFree(m_array); }

      ///
      ///
      ///

      void init(int period, double devMultiplier, double atrMultiplier)
      {
         m_period        = (period>1) ? period : 1;
         m_devMultiplier = devMultiplier;
         m_atrMultiplier = atrMultiplier;
      }
      
      template <typename T>
      double calculate(T& close[], T& high[], T& low[], int i, int bars)
      {
         if (m_arraySize<bars) { m_arraySize=ArrayResize(m_array,bars+500); if (m_arraySize<bars) return(0); }
         
            m_array[i].price  = close[i];
            m_array[i].price2 = close[i]*close[i];
            m_array[i].tr     = (i>0) ? (close[i-1] < high[i] ? high[i] : close[i-1]) - (close[i-1] > low[i] ? low[i] : close[i-1]) : high[i]-low[i];
            
            //
            //---
            //
            
            if (i>m_period)
            {
               m_array[i].sum   = m_array[i-1].sum  +m_array[i].price -m_array[i-m_period].price;
               m_array[i].sum2  = m_array[i-1].sum2 +m_array[i].price2-m_array[i-m_period].price2;
               m_array[i].sumtr = m_array[i-1].sumtr+m_array[i].tr    -m_array[i-m_period].tr;
            }
            else  
            {
               m_array[i].sum   = m_array[i].price;
               m_array[i].sum2  = m_array[i].price2; 
               m_array[i].sumtr = m_array[i].tr; 
               for(int k=1; k<m_period && i>=k; k++) 
               {
                  m_array[i].sum   += m_array[i-k].price; 
                  m_array[i].sum2  += m_array[i-k].price2; 
                  m_array[i].sumtr += m_array[i-k].tr; 
               }                  
            }       
            double _dev = MathSqrt((m_array[i].sum2-m_array[i].sum*m_array[i].sum/(double)m_period)/(double)m_period);
            double _atr = m_array[i].sumtr/(double)m_period;
            double _avg = m_array[i].sum  /(double)m_period;
            return ((m_devMultiplier*_dev)>(m_atrMultiplier*_atr) ? (high[i]+low[i])/2.0>_avg ? 1 : -1 : 0);
      }
};
cSqueeze iSqueeze;
//------------------------------------------------------------------