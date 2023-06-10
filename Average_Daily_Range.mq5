//+------------------------------------------------------------------------------------------------+
//|                                                                        Average_Daily_Range.mq5 |
//| Original code from https://www.forexfactory.com/thread/697128-adr-average-daily-range-indicator|
//| Modified by TyphooN                                                                            |
//+------------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0
#property version "4.20"
int                     NumOfDays_D                   =  1;
input bool              Print_Historical_HL_lines     =  false;
input int               Historical_HL_line_Bars       =  5;
input color             ADR_color_above               =  clrLime;
input color             ADR_color_below               =  clrRed;
input int               TimeZoneOfData                =  0;
input bool              ADR_Alert_Sound               =  false;
input bool              ADR_Line                      =  true;
input ENUM_LINE_STYLE   ADR_linestyle                 =  STYLE_DOT;
input int               ADR_Linethickness             =  3;
input color             ADR_Line_Color                =  clrYellow;
input int               NumOfDays_W                   =  5;
input int               NumOfDays_M                   =  20;
input int               NumOfDays_6M                  =  120;
input bool              M6_Trading_Weighting          =  false;
input int               Recent_Days_Weighting         =  5;
input bool              Weighting_to_ADR_percentage   =  true;
input string            FontName                      =  "Courier New";
input int               FontSize                      =  8;
input color             FontColor                     =  clrOrange;
input color             FontColor2                    =  clrLime;
input int               Window                        =  0;
const ENUM_BASE_CORNER  Corner                        =  CORNER_RIGHT_UPPER;
input int               HorizPos                      =  20;
input int               VertPos                       =  140;
int    Distance6Mv,Distance6M,DistanceMv,DistanceM,DistanceWv,DistanceW,DistanceYv,DistanceY,DistanceADRv,DistanceADR;
double pnt;
int    dig;
string objname="DRPE";
string Y, W, M, M6, ADR;
double w, m, m6, l, h;
class CSumDays
{
public:
   double            m_sum;
   int               m_days;
                     CSumDays(double sum,int days)
   {
      m_sum = sum;
      m_days = days;
   }
};
int OnInit()
{
   pnt =      SymbolInfoDouble (_Symbol,SYMBOL_POINT);
   dig = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   if(dig==3 || dig==5)
   {
      pnt*=10;
   }
   ObjectCreate(0,objname+"ADR",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"%",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"Y",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"Y-value",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"M",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"M-value",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"6M",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"6M-value",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"W",OBJ_LABEL,Window,0,0);
   ObjectCreate(0,objname+"W-value",OBJ_LABEL,Window,0,0);
   return(INIT_SUCCEEDED);
}
void OnDeinit( const int pReason )
{
   ObjectsDeleteAll(0,objname);
}
int  OnCalculate( const int        rates_total,       // grandezza delle timeseries input
                  const int        prev_calculated,   // numero di barre gestite alla precedente chiamata
                  const datetime&  time[],            // array Time
                  const double&    open[],            // array Open
                  const double&    high[],            // array High
                  const double&    low[],             // array Low
                  const double&    close[],           // array Close
                  const long&      tick_volume[],     // array Tick Volume
                  const long&      volume[],          // array Real Volume
                  const int&       spread[])          // array Spread
{
   int counted_bars= prev_calculated;
   if (counted_bars>0) counted_bars--;
   else
      counted_bars=1;
   double Bid =SymbolInfoDouble(_Symbol,SYMBOL_BID);
   CSumDays sum_day(0,0);
   CSumDays sum_m(0,0);
   CSumDays sum_w(0,0);
   CSumDays sum_6m(0,0);
   CSumDays sum_6m_add(0,0);
   range(NumOfDays_D,sum_day);
   range(NumOfDays_W,sum_w);
   range(NumOfDays_M,sum_m);
   range(NumOfDays_6M,sum_6m);
   range(Recent_Days_Weighting,sum_6m_add);
   if(sum_day.m_days==0 || sum_m.m_days==0 || sum_6m.m_days==0 || sum_6m_add.m_days==0) return rates_total;
   double hi = iHigh(NULL,PERIOD_D1,0);
   double lo = iLow(NULL,PERIOD_D1,0);
   if(pnt>0)
   {
      Y = DoubleToString(sum_day.m_sum/sum_day.m_days/pnt,0);
      m = sum_m.m_sum/sum_m.m_days/pnt;
      w = sum_w.m_sum/sum_m.m_days/pnt;
      W = DoubleToString(sum_w.m_sum/sum_m.m_days/pnt,0);
      M = DoubleToString(sum_m.m_sum/sum_m.m_days/pnt,0);
      m6 = sum_6m.m_sum / sum_6m.m_days;
      h = (hi-Bid)/pnt;
      l = (Bid-lo)/pnt;
      if(m6 == 0) return rates_total;
      double ADR_val;
if (Weighting_to_ADR_percentage) {
    double WADR = ((iHigh(NULL, PERIOD_D1, 0) - iLow(NULL, PERIOD_D1, 0)) + (iHigh(NULL, PERIOD_D1, 1) - iLow(NULL, PERIOD_D1, 1)) + (iHigh(NULL, PERIOD_D1, 2) - iLow(NULL, PERIOD_D1, 2)) +
                  (iHigh(NULL, PERIOD_D1, 3) - iLow(NULL, PERIOD_D1, 3)) + (iHigh(NULL, PERIOD_D1, 4) - iLow(NULL, PERIOD_D1, 4))) / 5;
    double val = (m6 + WADR) / 2 / pnt;
    ADR_val = (h + l) / val * 100;
    ADR = DoubleToString(ADR_val, 0);
}
      else
      {
         ADR_val=(h + l) / (m6 /pnt)* 100;
         ADR = DoubleToString(ADR_val, 0);
      }
      if(M6_Trading_Weighting)
      {
         m6 = (m6 + sum_6m_add.m_sum / sum_6m_add.m_days) / 2;
      }
      if(ADR_Line)
      {
         for(int k=0; k<Historical_HL_line_Bars; k++)
         {
            range(NumOfDays_M, sum_m,k+1);
            range(NumOfDays_6M, sum_6m,k+1);
            hi = iHigh(NULL, PERIOD_D1, k);
            lo = iLow(NULL, PERIOD_D1, k);
            double m6x=sum_6m.m_sum / sum_6m.m_days;
            if(M6_Trading_Weighting)
            {
               m6x = (m6x + sum_6m_add.m_sum / sum_6m_add.m_days) / 2;
            }
            datetime t1=iTime(_Symbol,PERIOD_D1,k)+86400+TimeZoneOfData*3600;
            if(k>0) t1 = iTime(_Symbol, PERIOD_D1, k-1)+TimeZoneOfData*3600;
            ObjectCreate(0,objname+"ADR low line"+(string)k,OBJ_TREND,0,0,hi-m6x);
            ObjectSetInteger(0,objname+"ADR low line"+(string)k,OBJPROP_TIME,0,iTime(_Symbol,PERIOD_D1,k)+TimeZoneOfData * 3600);
            ObjectSetInteger(0,objname+"ADR low line"+(string)k,OBJPROP_TIME,1,t1);
            ObjectSetDouble(0,objname+"ADR low line"+(string)k,OBJPROP_PRICE,0,hi-m6x);
            ObjectSetDouble(0,objname+"ADR low line"+(string)k,OBJPROP_PRICE,1,hi-m6x);
            ObjectSetInteger(0,objname+"ADR low line"+(string)k,OBJPROP_COLOR,ADR_Line_Color);
            ObjectSetInteger(0,objname+"ADR low line"+(string)k,OBJPROP_STYLE,ADR_linestyle);
            ObjectSetInteger(0,objname+"ADR low line"+(string)k,OBJPROP_WIDTH,ADR_Linethickness);
            ObjectSetInteger(0,objname+"ADR low line"+(string)k,OBJPROP_RAY,false);
            ObjectCreate(0,objname+"ADR high line"+(string)k,OBJ_TREND,0,0,lo+m6x);
            ObjectSetInteger(0,objname+"ADR high line"+(string)k,OBJPROP_TIME,0,iTime(_Symbol,PERIOD_D1,k)+TimeZoneOfData * 3600);
            ObjectSetInteger(0,objname+"ADR high line"+(string)k,OBJPROP_TIME,1,t1);
            ObjectSetDouble(0,objname+"ADR high line"+(string)k,OBJPROP_PRICE,0,lo+m6x);
            ObjectSetDouble(0,objname+"ADR high line"+(string)k,OBJPROP_PRICE,1,lo+m6x);
            ObjectSetInteger(0,objname+"ADR high line"+(string)k,OBJPROP_COLOR,ADR_Line_Color);
            ObjectSetInteger(0,objname+"ADR high line"+(string)k,OBJPROP_STYLE,ADR_linestyle);
            ObjectSetInteger(0,objname+"ADR high line"+(string)k,OBJPROP_WIDTH,ADR_Linethickness);
            ObjectSetInteger(0,objname+"ADR high line"+(string)k,OBJPROP_RAY,false);
            ObjectSetString(0,objname+"ADR low line"+(string)k,OBJPROP_TOOLTIP,"ADR Low Line "+DoubleToString(hi-m6x,_Digits));
            ObjectSetString(0,objname+"ADR high line"+(string)k,OBJPROP_TOOLTIP,"ADR High Line "+DoubleToString(lo+m6x,_Digits));
            if(!Print_Historical_HL_lines) break;
         }
      }
      m6 = m6 / pnt;
      M6 = DoubleToString(m6, 0);
      uint h2;
      TextSetFont(FontName, -10 * FontSize);
      TextGetSize(M6+" ",Distance6M,h2);
      TextGetSize(M+" ",DistanceM,h2);
      TextGetSize(W+" ",DistanceW,h2);
      TextGetSize(Y+" ",DistanceY,h2);
      TextGetSize(ADR+" % ",DistanceADR,h2);
      TextSetFont(FontName, -10 * FontSize);
      TextGetSize("6M:",Distance6Mv,h2);
      TextGetSize("M:",DistanceMv,h2);
      TextGetSize("W:",DistanceWv,h2);
      TextGetSize("Y:",DistanceYv,h2);
      TextGetSize("ADR",DistanceADRv,h2);
      ObjectSetInteger(0,objname+"ADR",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"ADR",OBJPROP_XDISTANCE,HorizPos+DistanceW+DistanceWv+Distance6Mv+Distance6M+DistanceMv+DistanceM+DistanceYv+DistanceY+DistanceADRv+DistanceADR);
      ObjectSetInteger(0,objname+"ADR",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"ADR",OBJPROP_TEXT,"ADR");
      ObjectSetString(0,objname+"ADR",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"ADR",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"ADR",OBJPROP_COLOR,FontColor);
      ObjectSetInteger(0,objname+"%",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"%",OBJPROP_XDISTANCE,HorizPos+DistanceW+DistanceWv+Distance6Mv+Distance6M+DistanceMv+DistanceM+DistanceYv+DistanceY+DistanceADR);
      ObjectSetInteger(0,objname+"%",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"%",OBJPROP_TEXT," " + ADR + "%");
      ObjectSetString(0,objname+"%",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"%",OBJPROP_FONTSIZE,FontSize);
      static bool oneTime=true;
      if(ADR_val < 100)
      {
         ObjectSetInteger(0,objname+"%",OBJPROP_COLOR,ADR_color_below);
         oneTime=true;
      }
      else
      {
         if(ADR_Alert_Sound && oneTime)
         {
            Alert(_Symbol+" ADX >= 100%");
            oneTime=false;
         }
         ObjectSetInteger(0,objname+"%",OBJPROP_COLOR,ADR_color_above);
      }
      ObjectSetInteger(0,objname+"Y",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"Y",OBJPROP_XDISTANCE,HorizPos+DistanceW+DistanceWv+Distance6Mv+Distance6M+DistanceMv+DistanceM+DistanceYv+DistanceY);
      ObjectSetInteger(0,objname+"Y",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"Y",OBJPROP_TEXT,"Y:");
      ObjectSetString(0,objname+"Y",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"Y",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"Y",OBJPROP_COLOR,FontColor);
      ObjectSetInteger(0,objname+"Y-value",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"Y-value",OBJPROP_XDISTANCE,HorizPos+DistanceW+DistanceWv+Distance6Mv+Distance6M+DistanceMv+DistanceM+DistanceY);
      ObjectSetInteger(0,objname+"Y-value",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"Y-value",OBJPROP_TEXT,Y);
      ObjectSetString(0,objname+"Y-value",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"Y-value",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"Y-value",OBJPROP_COLOR,FontColor2);
      ObjectSetInteger(0,objname+"W",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"W",OBJPROP_XDISTANCE,HorizPos+Distance6Mv+Distance6M+DistanceMv+DistanceM+DistanceYv+DistanceY);
      ObjectSetInteger(0,objname+"W",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"W",OBJPROP_TEXT,"W:");
      ObjectSetString(0,objname+"W",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"W",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"W",OBJPROP_COLOR,FontColor);
      ObjectSetInteger(0,objname+"W-value",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"W-value",OBJPROP_XDISTANCE,HorizPos+Distance6Mv+Distance6M+DistanceMv+DistanceM+DistanceY);
      ObjectSetInteger(0,objname+"W-value",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"W-value",OBJPROP_TEXT,W);
      ObjectSetString(0,objname+"W-value",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"W-value",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"W-value",OBJPROP_COLOR,FontColor2);
      ObjectSetInteger(0,objname+"M",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"M",OBJPROP_XDISTANCE,HorizPos+Distance6Mv+Distance6M+DistanceMv+DistanceM);
      ObjectSetInteger(0,objname+"M",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"M",OBJPROP_TEXT,"M:");
      ObjectSetString(0,objname+"M",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"M",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"M",OBJPROP_COLOR,FontColor);
      ObjectSetInteger(0,objname+"M-value",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"M-value",OBJPROP_XDISTANCE,HorizPos+Distance6Mv+Distance6M+DistanceM);
      ObjectSetInteger(0,objname+"M-value",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"M-value",OBJPROP_TEXT,M);
      ObjectSetString(0,objname+"M-value",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"M-value",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"M-value",OBJPROP_COLOR,FontColor2);
      ObjectSetInteger(0,objname+"6M",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"6M",OBJPROP_XDISTANCE,HorizPos+Distance6Mv+Distance6M);
      ObjectSetInteger(0,objname+"6M",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"6M",OBJPROP_TEXT,"6M:");
      ObjectSetString(0,objname+"6M",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"6M",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"6M",OBJPROP_COLOR,FontColor);
      ObjectSetInteger(0,objname+"6M-value",OBJPROP_CORNER,Corner);
      ObjectSetInteger(0,objname+"6M-value",OBJPROP_XDISTANCE,HorizPos+Distance6M);
      ObjectSetInteger(0,objname+"6M-value",OBJPROP_YDISTANCE,VertPos);
      ObjectSetString(0,objname+"6M-value",OBJPROP_TEXT,M6);
      ObjectSetString(0,objname+"6M-value",OBJPROP_FONT,FontName);
      ObjectSetInteger(0,objname+"6M-value",OBJPROP_FONTSIZE,FontSize);
      ObjectSetInteger(0,objname+"6M-value",OBJPROP_COLOR,FontColor2);
      }
      return(rates_total);
}
int TimeDayOfWeek(datetime date)
{
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.day_of_week);
}
void range(int days, CSumDays &sumdays, int k=1)
{
   sumdays.m_days=0;
   sumdays.m_sum=0;
   for(int i=k; i<Bars(_Symbol,PERIOD_CURRENT)-1; i++)
   {
      double hi = iHigh(NULL,PERIOD_D1,i);
      double lo = iLow(NULL,PERIOD_D1,i);
      datetime dt=iTime(NULL,PERIOD_D1,i);
      if(TimeDayOfWeek(dt)>0 && TimeDayOfWeek(dt)<6)
      {
         sumdays.m_sum+=hi-lo;
         sumdays.m_days = sumdays.m_days + 1;
         if(sumdays.m_days>=days) break;
      }
   }
}
