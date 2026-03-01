//+-------------------------------------------------------------------------------------+
//|                                                            Minions.BetterVolume.mq5 |
//| (CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License|
//|                                                          http://www.MinionsLabs.com |
//+-------------------------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Descriptors                                                      |
//+------------------------------------------------------------------+
#property copyright   "www.MinionsLabs.com"
#property link        "http://www.MinionsLabs.com"
#property version     "1.0"
#property description "Minions in the quest for explaining Volume in a better way."
#property description " "
#property description "(CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License"


//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_label1  "Better Volume"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrWhite, clrLime, clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  4



//+------------------------------------------------------------------+
//| INPUT Parameters                                                 |
//+------------------------------------------------------------------+
input ENUM_APPLIED_VOLUME inpAppliedVolume  = VOLUME_TICK; // Volume Type
input int                 inpBarsToAnalyze  =  20;         // N past bars to analyze



//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double bufferVolume[];
double bufferColors[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit() {
    SetIndexBuffer( 0, bufferVolume, INDICATOR_DATA );
    SetIndexBuffer( 1, bufferColors, INDICATOR_COLOR_INDEX );

    IndicatorSetString(INDICATOR_SHORTNAME,"Minions.BetterVolume ("+EnumToString(inpAppliedVolume)+", Period:"+(string)inpBarsToAnalyze+")");
    IndicatorSetInteger(INDICATOR_DIGITS,0);
}



//+------------------------------------------------------------------+
//|  Volume Calculation...                                           |
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
    int   start=prev_calculated-1;
    long  SMA;

    if (rates_total<2)  {  return(0);  }     // check for rates total

    if (start<1) {  start=1;  }              // correct position

    // calculates the volumes histogram...
    for(int i=start; i<rates_total && !IsStopped(); i++) {

        bufferVolume[i] = (double)(inpAppliedVolume==VOLUME_REAL  ?  volume[i]  :  tick_volume[i]);     // calculates the indicator...

        if(inpAppliedVolume==VOLUME_REAL) {
            SMA = SMAOnArray(volume, inpBarsToAnalyze, i );
        } else {
            SMA = SMAOnArray(tick_volume, inpBarsToAnalyze, i );
        }
        
        // change candle colors accordingly...
        if      (open[i]<close[i] && bufferVolume[i]>SMA) {  bufferColors[i]=1.0;  } 
        else if (open[i]>close[i] && bufferVolume[i]>SMA) {  bufferColors[i]=2.0;  }
        else                                              {  bufferColors[i]=0.0;  }
    
    }

    return(rates_total);
  }





//+------------------------------------------------------------------+
//| Calculates a SMA over an indicator array...                      |
//+------------------------------------------------------------------+
long SMAOnArray( const long &array[], int period, int position ) {
    long sum = 0;

    if (position-period <= 0)  {  return false;  }

    for (int i = position-period+1; i<=position; i++) {
        sum += array[i];
    }

    return sum / period;
}
//+------------------------------------------------------------------+
