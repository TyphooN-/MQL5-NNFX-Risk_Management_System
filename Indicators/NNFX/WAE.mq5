//+------------------------------------------------------------------+
//|                                       Waddah_Attar_Explosion.mq4 |
//|                              Copyright � 2006, Eng. Waddah Attar |
//|                                          waddahattar@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2006, Eng. Waddah Attar"
#property link "waddahattar@hotmail.com" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- only three plots are used
#property indicator_plots   2
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a three-color histogram
#property indicator_type2 DRAW_COLOR_HISTOGRAM
//---- Gray, Lime and Magenta colors are used for the three-color histogram
#property indicator_color2 Gray,Lime,Magenta
//---- indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width2 2
//---- displaying the indicator label
#property indicator_label2 "MACD"

//---- drawing the indicator as a line
#property indicator_type1 DRAW_LINE
//---- use blue color for the line
#property indicator_color1 Blue
//---- indicator line is a solid curve
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the signal line label
#property indicator_label1  "Signal Line"

//+------------------------------------+
//|  Indicator input parameters        |
//+------------------------------------+
input int Fast_MA = 20;       // Period of the fast MACD moving average

int Slow_MA = 2*Fast_MA;       // Period of the slow MACD moving average
int BBPeriod=Fast_MA;        // Bollinger period
input double BBDeviation=2.0; // Number of Bollinger deviations
input int  Sensetive=150;
input int  DeadZonePip=400;
input int  ExplosionPower=15;
input int  TrendPower=150;
input bool AlertWindow=false;
input int  AlertCount=2;
input bool AlertLong=false;
input bool AlertShort=false;
input bool AlertExitLong=false;
input bool AlertExitShort=false;
//+-----------------------------------+
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of integer variables for the indicators handles
int MACD_Handle,BB_Handle;
//---- declaration of global variables
double bask,bbid;
int LastTime1,LastTime2,LastTime3,LastTime4,Status,PrevStatus;
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double IndBuffer1[],ColorIndBuffer1[],IndBuffer2[],IndBuffer3[];
//+------------------------------------------------------------------+    
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=BBPeriod+1;
//---- initialization of variables
   LastTime1=1;
   LastTime2=1;
   LastTime3=1;
   LastTime4=1;
   Status=0;
   PrevStatus=-1;
//---- getting handle of the iMACD indicator
   MACD_Handle=iMACD(NULL,0,Fast_MA,Slow_MA,9,PRICE_CLOSE);
   if(MACD_Handle==INVALID_HANDLE) { Print("Failed to get handle of the iMACD indicator"); return INIT_FAILED; }
//---- getting handle of the iBands indicator
   BB_Handle=iBands(NULL,0,BBPeriod,0,BBDeviation,PRICE_CLOSE);
   if(BB_Handle==INVALID_HANDLE) { Print("Failed to get handle of the iBands indicator"); return INIT_FAILED; }

//---- set IndBuffer1[] dynamic array as an indicator buffer
   SetIndexBuffer(1,IndBuffer1,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(IndBuffer1,true);

//---- set ColorIndBuffer1[] as a colored index buffer   
   SetIndexBuffer(2,ColorIndBuffer1,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ColorIndBuffer1,true);

//---- set IndBuffer2[] as an indicator buffer
   SetIndexBuffer(0,IndBuffer2,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(IndBuffer2,true);

//---- set IndBuffer3[] as an indicator buffer
   SetIndexBuffer(3,IndBuffer3,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(IndBuffer3,true);

//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Waddah Attar Explosion");
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(MACD_Handle!=INVALID_HANDLE) IndicatorRelease(MACD_Handle);
   if(BB_Handle!=INVALID_HANDLE)   IndicatorRelease(BB_Handle);
  }
//+------------------------------------------------------------------+
//| MACD iteration function                                          |
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,     // number of bars in history at the current tick
                const int prev_calculated, // number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(MACD_Handle)<rates_total
      || BarsCalculated(BB_Handle)<rates_total
      || rates_total<min_rates_total)
      return(0);
//---- declarations of local variables 
   int limit,to_copy,bar;
   double MACD[],BandsUp[],BandsDn[];
   double Trend1,Trend2,Explo1,Explo2,Dead;
   double pwrt,pwre,Ask,Bid;
   string SirName;
//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(spread,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(MACD,true);
   ArraySetAsSeries(BandsUp,true);
   ArraySetAsSeries(BandsDn,true);
//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated;   // starting index for calculation of new bars
     }

   to_copy=limit+2;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(BB_Handle,1,0,to_copy,BandsUp)<=0) return(0);
   if(CopyBuffer(BB_Handle,2,0,to_copy,BandsDn)<=0) return(0);
   to_copy+=2;
   if(CopyBuffer(MACD_Handle,0,0,to_copy,MACD)<=0) return(0);

//---- main indicator calculation loop
   for(bar=limit; bar>=0; bar--)
     {
      Trend1=(MACD[bar] - MACD[bar+1])*Sensetive;
      Trend2=(MACD[bar+2] - MACD[bar+3])*Sensetive;
      Explo1=BandsUp[bar] - BandsDn[bar];
      Explo2=BandsUp[bar+1] - BandsDn[bar+1];

      Dead=_Point*DeadZonePip;

      IndBuffer1[bar]=-MathAbs(Trend1);

      Bid=close[bar];
      Ask=Bid+spread[bar];

      if(Trend1>0)      ColorIndBuffer1[bar]=1;
      else if(Trend1<0) ColorIndBuffer1[bar]=2;
      else              ColorIndBuffer1[bar]=0;
      IndBuffer2[bar]=-Explo1;
      if(bar==0)
        {
         if(Trend1>0 && Trend1>Explo1 && Trend1>Dead && 
            Explo1>Dead && Explo1>Explo2 && Trend1>Trend2 && 
            LastTime1<AlertCount && AlertLong==true && Ask!=bask)
           {
            pwrt=(Trend1!=0) ? 100*(Trend1 - Trend2)/Trend1 : 0;
            pwre=(Explo1!=0) ? 100*(Explo1 - Explo2)/Explo1 : 0;
            bask=Ask;
            if(pwre>=ExplosionPower && pwrt>=TrendPower)
              {
               SirName="";
               StringConcatenate(SirName,LastTime1,"- ",Symbol()," - BUY "," (",
                                 DoubleToString(bask,_Digits),") Trend PWR ",
                                 DoubleToString(pwrt,0)," - Exp PWR ",DoubleToString(pwre,0));

               if(AlertWindow==true) Alert(SirName);
               else                  Print(SirName);

               LastTime1++;
              }
            Status=1;
           }
         if(Trend1<0 && MathAbs(Trend1)>Explo1 && MathAbs(Trend1)>Dead &&
            Explo1>Dead && Explo1>Explo2 && MathAbs(Trend1)>MathAbs(Trend2) &&
            LastTime2<AlertCount && AlertShort==true && Bid!=bbid)
           {
            pwrt=(MathAbs(Trend1)!=0) ? 100*(MathAbs(Trend1) - MathAbs(Trend2))/MathAbs(Trend1) : 0;
            pwre=(Explo1!=0) ? 100*(Explo1 - Explo2)/Explo1 : 0;
            bbid=Bid;
            if(pwre>=ExplosionPower && pwrt>=TrendPower)
              {
               SirName="";
               StringConcatenate(SirName,LastTime2,"- ",Symbol()," - Sell "," (",
                                 DoubleToString(bask,_Digits),") Trend PWR ",
                                 DoubleToString(pwrt,0)," - Exp PWR ",DoubleToString(pwre,0));

               if(AlertWindow==true) Alert(SirName);
               else                  Print(SirName);

               LastTime2++;
              }

            Status=2;
           }
         if(Trend1>0 && Trend1<Explo1 && Trend1<Trend2 && Trend2>Explo2 && 
            Trend1>Dead && Explo1>Dead && LastTime3<=AlertCount && 
            AlertExitLong==true && Bid!=bbid)
           {
            bbid=Bid;
            SirName="";
            StringConcatenate(SirName,LastTime3,"- ",Symbol()," - Exit BUY "," ",DoubleToString(bbid,_Digits));

            if(AlertWindow==true) Alert(SirName);
            else                  Print(SirName);

            Status=3;
            LastTime3++;
           }
         if(Trend1<0 && MathAbs(Trend1)<Explo1 &&
            MathAbs(Trend1)<MathAbs(Trend2) && MathAbs(Trend2)>Explo2 &&
            MathAbs(Trend1)>Dead && Explo1>Dead && LastTime4<=AlertCount &&
            AlertExitShort==true && Ask!=bask)
           {
            bask=Ask;
            SirName="";
            StringConcatenate(SirName,LastTime4,"- ",Symbol()," - Exit SELL "," ",DoubleToString(bask,_Digits));

            if(AlertWindow==true) Alert(SirName);
            else                  Print(SirName);

            Status=4;
            LastTime4++;
           }
         PrevStatus=Status;
        }
      if(Status!=PrevStatus)
        {
         LastTime1=1;
         LastTime2=1;
         LastTime3=1;
         LastTime4=1;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
