//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
#property version   "1.0"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Kijun-sen"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDeepSkyBlue,clrSandyBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

input int   Kijun           = 26;       // Calculation period
input bool  alertsOn        = false;    // Turn alerts on?
input bool  alertsOnCurrent = true;     // Alert on current bar?
input bool  alertsMessage   = true;     // Display messageas on alerts?
input bool  alertsSound     = false;    // Play sound on alerts?
input bool  alertsEmail     = false;    // Send email on alerts?
input bool  alertsNotify    = false;    // Send push notification on alerts?

double MaBuffer[],ColorBuffer[];

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
   SetIndexBuffer(0,MaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME,"Kijun-Sen ("+(string)Kijun+")");
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
   
   //
   //
   //
   //
   //
      
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      if  (i<Kijun) continue;
      double khi = high[i];
      double klo = low[i];
        for (int k = 1; k<Kijun && (i-k)>=0; k++)
        {
           if(khi < high[i-k]) khi = high[i-k];
           if(klo > low [i-k]) klo = low[i-k];
        }
        if ((khi+klo) > 0.0) 
             MaBuffer[i] = (khi + klo)/2; 
        else MaBuffer[i] = 0;
        
        //
        //
        //
        //
        //
        
        ColorBuffer[i] = (close[i]>MaBuffer[i]) ? 0 : (close[i]<MaBuffer[i]) ? 1 : (i > 0 ? ColorBuffer[i-1] : 0);
   }
   manageAlerts(time,ColorBuffer,rates_total);
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

void manageAlerts(const datetime& time[], double& trend[], int bars)
{
   if (alertsOn)
   {
      int whichBar = bars-1; if (!alertsOnCurrent) whichBar = bars-2; datetime time1 = time[whichBar];
         
      //
      //
      //
      //
      //
         
      if (whichBar > 0 && trend[whichBar] != trend[whichBar-1])
      {
         if (trend[whichBar] == 0) doAlert(time1,"up");
         if (trend[whichBar] == 1) doAlert(time1,"down");
      }         
   }
}   

//
//
//
//
//

void doAlert(datetime forTime, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      message = TimeToString(TimeLocal(),TIME_SECONDS)+" "+_Symbol+" Kijun-Sen signal "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" Kijun-Sen",message);
         if (alertsNotify)  SendNotification(message);
         if (alertsSound)   PlaySound("alert2.wav");
   }
}