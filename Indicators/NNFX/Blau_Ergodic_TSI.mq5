//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "Ergodic True Strength Index (William Blau)"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_label1  "TSI"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepSkyBlue,clrSandyBrown
#property indicator_width1  2
#property indicator_label2  "TSI signal line"
#property indicator_type2   DRAW_LINE
#property indicator_color3  clrDarkGray
#property indicator_style2  STYLE_DOT

//
//--- input parameters
//

enum enColorOn
{
   col_onSignalCross, // Change color on signal line cross
   col_onZeroCross,   // Change color on zero line cross
   col_onSlopeChange  // Change color TSI slope change
};
input int                inpPeriod1      = 25;                // TSI smoothing period ("s" period)
input int                inpPeriod2      = 13;                // TSI momentum smoothing period  ("r" period)
input int                inpSignalPeriod = 5;                 // Signal period
input ENUM_APPLIED_PRICE inpPrice        = PRICE_CLOSE;       // Price
input enColorOn          inpColorOn      = col_onSignalCross; // Color change type 

//
//--- buffers and global variables declarations
//

double val[],valc[],signal[],prices[],¹_signalAlpha;
//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
{
   //--- indicator buffers mapping
         SetIndexBuffer(0,val   ,INDICATOR_DATA);
         SetIndexBuffer(1,valc  ,INDICATOR_COLOR_INDEX);
         SetIndexBuffer(2,signal,INDICATOR_DATA);
         SetIndexBuffer(3,prices,INDICATOR_CALCULATIONS);
            ¹_signalAlpha = 2.0 / (1.0 + (inpSignalPeriod>1 ? inpSignalPeriod : 1));
   //---
   IndicatorSetString(INDICATOR_SHORTNAME,(inpPeriod1==5 || inpPeriod2==5?"Ergodic t":"T")+"rue strength index ("+(string)inpPeriod1+","+(string)inpPeriod2+","+(string)inpSignalPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
//
//---
//

#define _setPrice(_priceType,_where,_index) { \
   switch(_priceType) \
   { \
      case PRICE_CLOSE:    _where = close[_index];                                              break; \
      case PRICE_OPEN:     _where = open[_index];                                               break; \
      case PRICE_HIGH:     _where = high[_index];                                               break; \
      case PRICE_LOW:      _where = low[_index];                                                break; \
      case PRICE_MEDIAN:   _where = (high[_index]+low[_index])/2.0;                             break; \
      case PRICE_TYPICAL:  _where = (high[_index]+low[_index]+close[_index])/3.0;               break; \
      case PRICE_WEIGHTED: _where = (high[_index]+low[_index]+close[_index]+close[_index])/4.0; break; \
      default : _where = 0; \
   }}

//
//---
//

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
   int i=(prev_calculated>0?prev_calculated-1:0); for (; i<rates_total && !_StopFlag; i++)
   {
      _setPrice(inpPrice,prices[i],i);
         val[i]    = 100*iTsi((i>0?prices[i]-prices[i-1]:0),inpPeriod2,inpPeriod1,i);
         signal[i] = (i>0) ? signal[i-1]+¹_signalAlpha*(val[i]-signal[i-1]) : val[i];
         switch (inpColorOn)
         {
            case col_onSignalCross : valc[i] = (val[i]>signal[i]) ? 1 : (val[i]<signal[i]) ? 2 : (i>0) ? valc[i-1] : 0; break;
            case col_onSlopeChange : valc[i] = (i>0) ? (val[i]>val[i-1]) ? 1 : (val[i]<val[i-1]) ? 2 : valc[i-1] : 0; break;
            default :                valc[i] = (val[i]>0) ? 1 : (val[i]<0) ? 2 : (i>0) ? valc[i-1] : 0; break;
         }            
   }
   return (i);
}

//------------------------------------------------------------------
// Custom function(s)
//------------------------------------------------------------------
//
//---
//

double iTsi(double value, double period1, double period2, int i, int _instance=0)
{
   #define _functionInstancesSize 4
   #define _functionArrayRingSize 6
   #ifdef  _functionInstances
         static double _workArray[_functionArrayRingSize][_functionInstancesSize*_functionInstances];
   #else static double _workArray[_functionArrayRingSize][_functionInstancesSize];
   #endif 
   #ifdef  _functionInstances
         #define _winst _instance*_functionInstancesSize
   #else #define _winst _instance
   #endif
      #define _emareg1 _winst
      #define _emareg2 _winst+1
      #define _emaabs1 _winst+2
      #define _emaabs2 _winst+3
   
      //
      //---
      //
   
      int    _indC = (i  )%_functionArrayRingSize;
      int    _indP = (i-1)%_functionArrayRingSize;
      double valua = (value>0) ? value : -value;

         if (i>0 && period1>1)      
               {  
                  _workArray[_indC][_emareg1] = _workArray[_indP][_emareg1]+(2.0/(1.0+period1))*(value-_workArray[_indP][_emareg1]);
                  _workArray[_indC][_emaabs1] = _workArray[_indP][_emaabs1]+(2.0/(1.0+period1))*(valua-_workArray[_indP][_emaabs1]);
               }             
         else  {  _workArray[_indC][_emareg1] = _workArray[_indC][_emaabs1] = value; }
         if (i>0 && period2>1)      
               {  
                  _workArray[_indC][_emareg2] = _workArray[_indP][_emareg2]+(2.0/(1.0+period2))*(_workArray[_indC][_emareg1]-_workArray[_indP][_emareg2]);
                  _workArray[_indC][_emaabs2] = _workArray[_indP][_emaabs2]+(2.0/(1.0+period2))*(_workArray[_indC][_emaabs1]-_workArray[_indP][_emaabs2]);
               }             
         else  {  _workArray[_indC][_emareg2] = _workArray[_indC][_emaabs2] = value; }
         return ( _workArray[_indC][_emaabs2]!=0 ? _workArray[_indC][_emareg2]/_workArray[_indC][_emaabs2] : 0);
   
   //
   //---
   //
   
   #undef _emareg1 #undef _emareg2 #undef _emaabs1 #undef _emaabs2
   #undef _functionInstances #undef _functionArrayRingSize #undef _functionInstancesSize #undef _winst 
} 
//------------------------------------------------------------------