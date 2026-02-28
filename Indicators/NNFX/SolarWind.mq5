//+------------------------------------------------------------------+
// Solar Winds Indicator re-write for MQ5.                           |
// Demonstrates Paint and non-repaint                                |
//   Solar Winds MQ4 original Author appears to be:                  |
//   #property  copyright "Copyright ? 2005, Yura Prokofiev"         |
//   #property  link      "Yura.prokofiev@gmail.com"                 |
//+------------------------------------------------------------------+
string g_shortName="SolarWinds";
#property copyright   "Copyright © LukeB"
#property link        "https://www.mql5.com/en/users/lukeb"
#property version     "1.02";
#property description "Solar Winds for MQL5"
#property description "Demonstrates classic for-loop construction for re-painting and non-repainting"
#property description "Has choice for using Custom Events or not"
#property strict
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots  2
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_style1  STYLE_SOLID
#property indicator_color1  clrLimeGreen,clrRed
#property indicator_width1  2
#property indicator_type2   DRAW_COLOR_HISTOGRAM
#property indicator_style2  STYLE_SOLID
#property indicator_color2  clrLimeGreen,clrRed
#property indicator_width2  1
// ====== Begin indicator Global Values =====
enum ENUM_CUSTOM_EVENT  // Custom Event Values must be in the range of a positive ushort (0-32K). 
 {
   CUSTOM_EVENT_RUN_INDICATOR     = 130,
   CUSTOM_EVENT_DO_ALERTS         = 150
 };
enum ENUM_ON_OFF {ENUM_OFF, ENUM_ON};
int g_minBars, g_maxBars;
string g_msgString, g_strUniquifier;
bool g_isTesting;
//
input ENUM_ON_OFF       NRP = ENUM_OFF;  // Non-Repainting (NPR) ON/OFF
input ENUM_ON_OFF UseEvents = ENUM_OFF;  // Use Custom Events ON/OFF
input int   period       = 35;
input int   smooth       = 15; 
input bool  DoAlert      = true;
input bool  alertMail    = false;
input color lngLineClr   = clrLimeGreen;   // Long Side Line Color
input color shrtLineClr  = clrRed;         // Short Side Line Color
input color lngHistClor  = clrDarkMagenta; // Long Side Histogram Color
input color shrtHistClor = clrBrown;       // Short Side Histogram Color
input uint  Uniquifier   = 176;            // Make this instance unique
//
double g_windLine[];
double g_windLineClrIdx[];
double g_histogram[];
double g_histogramClrIdx[];
double g_calcZero[];
double g_calcOne[];
double g_calcTwo[];
// CrossOver state (reset on full recalc to avoid stale values)
double g_swValue=0, g_swValue1=0, g_swFish=0;
//--- References for Indicator Coloring ----------
enum EnumPlotClrs          { ENUM_LONG_CLR,     ENUM_SHORT_CLR };
//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
 {
   ENUM_INIT_RETCODE retCode = INIT_SUCCEEDED;
   g_shortName += IntegerToString(Uniquifier)+(NRP==ENUM_OFF?"_RP":"_NRP");
   IndicatorSetString(INDICATOR_SHORTNAME,g_shortName);
   g_minBars = period;
   g_maxBars=30000-g_minBars;  // should be a number < (99,9999-g_minBars)
   g_strUniquifier = IntegerToString(Uniquifier);
   g_isTesting = MQLInfoInteger(MQL_TESTER);
   //---- initialize the indicator buffers ---------------
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   //
   ArraySetAsSeries(g_windLine,true);
   ArraySetAsSeries(g_windLineClrIdx,true);
   ArraySetAsSeries(g_histogram,true);
   ArraySetAsSeries(g_histogramClrIdx,true);
   ArraySetAsSeries(g_calcZero,true);
   ArraySetAsSeries(g_calcOne,true);
   ArraySetAsSeries(g_calcTwo,true);
   //
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   SetIndexBuffer(0,g_windLine,INDICATOR_DATA);
   SetIndexBuffer(1,g_windLineClrIdx,INDICATOR_COLOR_INDEX); // "buffer is used for storing color indexes for the previous indicator buffer"
       PlotIndexSetString(0,PLOT_LABEL,"WIND_LINE"+g_strUniquifier);
   SetIndexBuffer(2,g_histogram,INDICATOR_DATA);
   SetIndexBuffer(3,g_histogramClrIdx,INDICATOR_COLOR_INDEX); // "buffer is used for storing color indexes for the previous indicator buffer"
       PlotIndexSetString(1,PLOT_LABEL,"HISTO_DECO"+g_strUniquifier);
   SetIndexBuffer(4,g_calcZero,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,g_calcOne,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,g_calcTwo,INDICATOR_CALCULATIONS);
   //---- initialization done
   return retCode;
 }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
 {
   if(StringLen(g_msgString) > 0) // remove comments made by this indicator
    {
      g_msgString="";
      Comment(g_msgString);
    }
 }
//+------------------------------------------------------------------+
//| Indicaor chart event function                                    |
//+------------------------------------------------------------------+
bool PostCustomEvent(const ENUM_CUSTOM_EVENT customEvent, const long longParm, const double doubleParm, const string stringParm)
 {
   bool postSucceeded=true;
   if( IsStopped() )
    {
      postSucceeded=false;
    } else if (!EventChartCustom(ChartID(),(ushort)customEvent, longParm, doubleParm, stringParm) )
    {
      int errCode = GetLastError();
      g_msgString="Post CUSTOM_EVENT "+IntegerToString(customEvent)+" Failed with error "+IntegerToString(errCode)+"."; // +", "+ErrorDescription(errCode);
      Comment(g_msgString); Print(g_msgString);
      postSucceeded = false;
    }
   return postSucceeded;
 }
void OnChartEvent( const int id, const long &lparam, const double &dparam, const string &sparam )
 {
   if( (id==CHARTEVENT_CUSTOM+CUSTOM_EVENT_RUN_INDICATOR) && (sparam==g_strUniquifier) ){
      int firstWorkBar = (int) lparam;
      RunTheIndicator( firstWorkBar );
    }
   else if( (id==CHARTEVENT_CUSTOM+CUSTOM_EVENT_DO_ALERTS) && (sparam==g_strUniquifier) ){
      DoTheAlerts(g_windLine);
    }
 }
//-------------------------------------------------------------
//---------- OnCalculate Utilities ----------------------------
bool GetTheFirstWorkBar( int& firstWorkBar, const int& rates_total, const int& prev_calculated, const int& maxBars, const int & minBars)
 {
   static bool firstRun=true;
   if( (prev_calculated<1)||(firstRun==true)){ // First run
      firstWorkBar=rates_total-(minBars+1);
      if( firstWorkBar > maxBars-(minBars+1) ){
         firstWorkBar = maxBars-(minBars+1);
         PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,firstWorkBar);
         PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,firstWorkBar);
       }else if(firstWorkBar<(minBars+1)){
         return false;  // Not enough bars
       }
      g_swValue=0; g_swValue1=0; g_swFish=0;
      firstRun=false;
    }else{
      firstWorkBar = rates_total - prev_calculated;
    }
   return true;
 }
//+------------------------------------------------------------------+
//|  Solar Wind - Custom indicator iteration function        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long& tick_volume[], const long& volume[], const int& spread[])
 {
   int firstWorkBar;
   // Set the limits for what bars need to be evaluated
   if( true!=GetTheFirstWorkBar(firstWorkBar, rates_total, prev_calculated, g_maxBars, g_minBars) )  // Not true if good first work bar is not obtained.
    {
      g_msgString=__FUNCTION__+" Failed to calculate the first work bar.  Bars total: "+IntegerToString(rates_total)+", Minimum required bars: "+IntegerToString(g_minBars+1);
      Comment(g_msgString); Print(g_msgString);
      return prev_calculated;  // Always Zero here.
    }
   //
   if((true==g_isTesting) || (UseEvents==ENUM_OFF)){  // If true, don't use events much as the strategy tester fails (locks up)
      if(!RunTheIndicator(firstWorkBar))
         return prev_calculated; // Didn't run
    }else{
      if( !PostCustomEvent(CUSTOM_EVENT_RUN_INDICATOR,firstWorkBar,0,g_strUniquifier) ) {
         return prev_calculated;  // Post Event Failed.
       }
    }
   return rates_total;
 }
//
bool RunTheIndicator(const int& firstWorkBar) // main indicator calculations
 {
   bool run_succeeded = true;
   if( !IsStopped() )
    {
      // Pre-fetch price data to avoid per-bar iHigh/iLow/iHighest/iLowest API calls
      int needBars = firstWorkBar + period + 1;
      double highBuf[], lowBuf[];
      ArraySetAsSeries(highBuf, true);
      ArraySetAsSeries(lowBuf, true);
      if (CopyHigh(_Symbol, 0, 0, needBars, highBuf) < needBars) return false;
      if (CopyLow(_Symbol, 0, 0, needBars, lowBuf) < needBars) return false;
      SetCrossOverValue( firstWorkBar, g_calcZero, g_calcOne, highBuf, lowBuf );
      MakeWindLine( firstWorkBar, g_calcOne, g_calcTwo, g_windLine, g_windLineClrIdx, g_histogram, g_histogramClrIdx);
      //
      if((true==g_isTesting) || (UseEvents==ENUM_OFF)){  // If true, don't use events much as the strategy tester fails (locks up)
         DoTheAlerts(g_windLine);
       }else{
         PostCustomEvent(CUSTOM_EVENT_DO_ALERTS,0,0,g_strUniquifier);
       }
    }
   else
    {
      run_succeeded = false;
    }
   return run_succeeded;
 }
//
void SetCrossOverValue(const int& firstWorkBar, double& calcZero[], double& calcOne[], const double& highBuf[], const double& lowBuf[])
 {
   //===== Select Re-paint or No Re-Paint
   if( NRP==ENUM_ON)  // Decide if using the original, repainting, Solar Wind or calculate without repainting
    {
      for( int i=firstWorkBar; i>=0; i--)    // No Re-Paint
       {
         DoTheCrossOverCalc(i, calcZero, calcOne, highBuf, lowBuf);
       }
    } else
    {
      for( int i=0; i<=firstWorkBar; i++)     // Classic Re-Paint
       {
         DoTheCrossOverCalc(i, calcZero, calcOne, highBuf, lowBuf);
       }
    }
 }
void DoTheCrossOverCalc(const int& workBar, double& calcZero[], double& calcOne[], const double& highBuf[], const double& lowBuf[])
 {
   double &Value=g_swValue, &Value1=g_swValue1, &Fish=g_swFish;
   double price, MinL, MaxH;
   MaxH = highBuf[workBar];
   MinL = lowBuf[workBar];
   for (int k = 1; k < period; k++)
   {
      if (highBuf[workBar + k] > MaxH) MaxH = highBuf[workBar + k];
      if (lowBuf[workBar + k] < MinL) MinL = lowBuf[workBar + k];
   }
   price = (highBuf[workBar] + lowBuf[workBar]) / 2;
   if(MaxH - MinL > 0)
      Value = 0.33*2*((price-MinL)/(MaxH-MinL)-0.5) + 0.67*Value1;
   else
      Value = Value1;
   Value=MathMin(MathMax(Value,-0.999),0.999); 
   calcZero[workBar]=0.5*MathLog((1+Value)/(1-Value))+0.5*Fish;
   Value1=Value;
   Fish=calcZero[workBar];
   if (calcZero[workBar]>0)
   {
    calcOne[workBar]=10; 
   }else{ // Includes Zero, but not often.
    calcOne[workBar]=-10; 
   }      
 }
//
void MakeWindLine(const int& firstWorkBar, const double& calcOne[], double& calcTwo[], double& windLine[], double& windClr[], double& histogram[], double& histoClr[])
 {
   double sum, sumw, weight;
   int i, k;
   for( i=firstWorkBar; i>=0; i--)
   {
      sum=0; sumw=0;
      for( k=0; k<smooth && (i+k)<=firstWorkBar; k++)
      {
         weight = smooth-k;
         sumw  += weight;
         sum   += weight*calcOne[i+k];
      }             
      if( sumw!=0 ) // Prevent Divide by Zero
      {
         calcTwo[i] = sum/sumw;
      }else
      {
         calcTwo[i] = 0;
      }
   }
   for( i=0; i<=firstWorkBar; i++)    // these are in the re-paint direction, but do not impact the crossover indication.
   {
      sum=0; sumw=0;
      for( k=0; k<smooth && (i-k)>=0; k++)   // these are in the re-paint direction, but do not impact the crossover indication.
      {
         weight = smooth-k;
         sumw  += weight;
         sum   += weight*calcTwo[i-k];
      }             
      if( sumw!=0 ) // Prevent Divide by Zero
      {
         windLine[i]  = sum/sumw;
         histogram[i] = windLine[i];
         windClr[i]   = windLine[i]>0?ENUM_LONG_CLR:ENUM_SHORT_CLR;
         histoClr[i]   = windLine[i]>0?ENUM_LONG_CLR:ENUM_SHORT_CLR;
      }else
      {
         windLine[i]  = 0;
         histogram[i] = windLine[i];
         windClr[i]   = windClr[i+1]; // No Color Change
         histoClr[i]  = histoClr[i+1]; 
      }
   }
 } //----===== END MakeWindLine =====
//
void DoTheAlerts(const double& windLine[])
 {
    static datetime lastAlertTime = NULL;
    datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
    string sAlertMsg;
    if( lastAlertTime != currentTime )
    {
      if (windLine[1] <= 0 && windLine[0] > 0)  // Crossed to Positive
      {
         if (DoAlert)
         {
            sAlertMsg="Solar Wind "+g_strUniquifier+" MQ5- "+_Symbol+" "+TF2Str(Period())+": cross UP";
            if (DoAlert)     Alert(sAlertMsg); 
            if (alertMail)   SendMail(sAlertMsg, " Alert!\n" + TimeToString(currentTime,TIME_DATE|TIME_SECONDS )+"\n"+sAlertMsg);   
         }
         lastAlertTime = currentTime;
      }
      else if( windLine[1] >= 0 && windLine[0] < 0)  // Crossed to Negative
      {
         if (DoAlert)
         {
            sAlertMsg="Solar Wind "+g_strUniquifier+" MQ5- "+_Symbol+" "+TF2Str(Period())+": cross DOWN";
            if (DoAlert)     Alert(sAlertMsg);
            if (alertMail)   SendMail(sAlertMsg, " Alert!\n" + TimeToString(currentTime,TIME_DATE|TIME_SECONDS )+"\n"+sAlertMsg);
         }
         lastAlertTime = currentTime;
      }
    }
 } //----===== END DoTheAlerts =====
//+-------------------------------------------------------------------------------------------+
//| Utility to provide ENUM_TIMEFRAMES strings                                                |
//+-------------------------------------------------------------------------------------------+
string TF2Str(int iPeriod) // Time Frame To String
 {
   string retStr;
   switch(iPeriod) {
      case PERIOD_M1:  retStr = "M1";   break;
      case PERIOD_M5:  retStr = "M5";   break;
      case PERIOD_M15: retStr = "M15";  break;
      case PERIOD_M30: retStr = "M30";  break;
      case PERIOD_H1:  retStr = "H1";   break;
      case PERIOD_H4:  retStr = "H4";   break;
      case PERIOD_D1:  retStr = "D1";   break;
      case PERIOD_W1:  retStr = "W1";   break;
      case PERIOD_MN1: retStr = "MN1";  break;
      default: retStr = "M"+IntegerToString(iPeriod); break;
    }
   return retStr;
 } //----===== END TF2Str =====
//+------------------------------------------------------------------+
//+----------------------- END --------------------------------------+
