//+------------------------------------------------------------------+
// BraidFilterWithATR.mq5                                            |
// Braid Filter was originally designed by Robert Hill (Mr. Pips)    |
// This version uses the ATR multiplier to optimize the filter line  |
//                                                                   |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3

#property indicator_color1 clrGreen
#property indicator_label1 "Bulls"
#property indicator_color2 clrRed
#property indicator_label2 "Bears"
#property indicator_color3 clrYellow
#property indicator_label3 "Filter"
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  1

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE

#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID

input ENUM_MA_METHOD InpMAMethod = MODE_EMA;
input int InpPeriodFast = 5;
input int InpPeriodMedium = 8;
input int InpPeriodSlow = 20;
input int InpATRPeriod = 14;
input double InpATRMultiplier = 0.5;

double CrossUp[],CrossDown[],Filter[],ATRData[],EmaFast[],EmaMedium[],EmaSlow[];
int   Handle_ATR,Handle_EmaFast, Handle_EmaMedium, Handle_EmaSlow;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,CrossUp,INDICATOR_DATA);
   SetIndexBuffer(1,CrossDown,INDICATOR_DATA);
   SetIndexBuffer(2,Filter,INDICATOR_DATA);
   SetIndexBuffer(3,EmaFast,INDICATOR_DATA);
   SetIndexBuffer(4,EmaMedium,INDICATOR_DATA);
   SetIndexBuffer(5,EmaSlow,INDICATOR_DATA);

   ArraySetAsSeries(CrossUp,true);
   ArraySetAsSeries(CrossDown,true);
   ArraySetAsSeries(Filter,true);
   ArraySetAsSeries(EmaFast,true);
   ArraySetAsSeries(EmaMedium,true);
   ArraySetAsSeries(EmaSlow,true);

   if(!fnInitIndicators())
      return INIT_FAILED;

   IndicatorSetString(INDICATOR_SHORTNAME, "Braid Filter ("+(string)InpPeriodFast+","+(string)InpPeriodMedium+","+(string)InpPeriodSlow+","+ EnumToString(InpMAMethod) +")");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(Handle_ATR!=INVALID_HANDLE)       IndicatorRelease(Handle_ATR);
   if(Handle_EmaFast!=INVALID_HANDLE)   IndicatorRelease(Handle_EmaFast);
   if(Handle_EmaMedium!=INVALID_HANDLE) IndicatorRelease(Handle_EmaMedium);
   if(Handle_EmaSlow!=INVALID_HANDLE)   IndicatorRelease(Handle_EmaSlow);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool fnInitIndicators()
  {
   Handle_ATR=iATR(_Symbol, _Period, InpATRPeriod);
   Handle_EmaFast  = iMA(_Symbol, _Period, InpPeriodFast, 0,InpMAMethod, PRICE_CLOSE);
   Handle_EmaMedium  = iMA(_Symbol, _Period, InpPeriodMedium, 0,InpMAMethod, PRICE_OPEN);
   Handle_EmaSlow = iMA(_Symbol, _Period, InpPeriodSlow, 0,InpMAMethod, PRICE_CLOSE);

   if(Handle_ATR==INVALID_HANDLE ||  Handle_EmaFast==INVALID_HANDLE || Handle_EmaMedium==INVALID_HANDLE || Handle_EmaSlow==INVALID_HANDLE)
     {
      Print("Failed loading indicators. Last error: ",GetLastError());
      return false;
     }

   return true;

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

   int limit, i;
   double fastMAnow, slowMAnow;

   if(prev_calculated<0)
      return(-1);

   if(prev_calculated<2)
      limit=rates_total-2;
   else
      limit=rates_total-prev_calculated;

   if(!ReadIndicatorBufferData(Handle_ATR,0,ATRData,limit+1))
      return(-1);

   if(!ReadIndicatorBufferData(Handle_EmaFast,0,EmaFast,limit+1))
      return(-1);

   if(!ReadIndicatorBufferData(Handle_EmaMedium,0,EmaMedium,limit+1))
      return(-1);

   if(!ReadIndicatorBufferData(Handle_EmaSlow,0,EmaSlow,limit+1))
      return(-1);

   for(i = 0; i <= limit && !IsStopped(); i++)
     {

      fastMAnow = EmaFast[i];
      slowMAnow = EmaMedium[i];

      EmaFast[i] = fastMAnow;
      EmaMedium[i] = slowMAnow;
      CrossUp[i] = 0;
      CrossDown[i] = 0;
      Filter[i] = ATRData[i] *InpATRMultiplier;

      if((fastMAnow > slowMAnow))
         CrossUp[i] = GetDif(i);

      if((fastMAnow < slowMAnow))
         CrossDown[i] = GetDif(i);

     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ReadIndicatorBufferData(int IndicatorHandle,int BufferNo, double &arrData[], int MaxCount)
  {

   ArraySetAsSeries(arrData,true);
   if(CopyBuffer(IndicatorHandle,BufferNo,0,MaxCount,arrData)<=0)
      return false;

   return true;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetDif(int pos)
  {

   double ma5 = EmaFast[pos];
   double ma8 = EmaMedium[pos];
   double ma20 = EmaSlow[pos];
   double max, min;

   double dif;

   max = MathMax(ma5, ma8);
   max = MathMax(max, ma20);
   min = MathMin(ma5, ma8);
   min = MathMin(min, ma20);

   dif = max - min;
   return(dif);
  }
//+------------------------------------------------------------------+
