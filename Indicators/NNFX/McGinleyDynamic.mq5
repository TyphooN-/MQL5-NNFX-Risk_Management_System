//------------------------------------------------------------------
#property copyright   "© mladen, 2020"
#property link        "mladenfx@gmail.com"
#property description "McGinley dynamic average"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "McGinley dynamic average"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrOrangeRed
#property indicator_width1  2

//
//
//

input int                inpPeriod = 14;          // Period

input ENUM_APPLIED_PRICE inpPrice  = PRICE_CLOSE; // Price
      enum enMcgType
         {
            mcg_original, // Original formula
            mcg_faster,   // "Improved" formula
         };
input enMcgType          inpType   = mcg_original; // Calculation type

//
//
//

double val[],valc[],mcgMultiplier; 

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

int OnInit()
{
   SetIndexBuffer(0,val ,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
      mcgMultiplier = (inpType==mcg_original) ? 1.0 : 0.6;

   //
   //
   //
   
   IndicatorSetString(INDICATOR_SHORTNAME,"McGinley dynamic ("+(string)inpPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//---
//

#define _setPrice(_priceType,_target,_index) \
   { \
   switch(_priceType) \
   { \
      case PRICE_CLOSE:    _target = close[_index];                                              break; \
      case PRICE_OPEN:     _target = open[_index];                                               break; \
      case PRICE_HIGH:     _target = high[_index];                                               break; \
      case PRICE_LOW:      _target = low[_index];                                                break; \
      case PRICE_MEDIAN:   _target = (high[_index]+low[_index])/2.0;                             break; \
      case PRICE_TYPICAL:  _target = (high[_index]+low[_index]+close[_index])/3.0;               break; \
      case PRICE_WEIGHTED: _target = (high[_index]+low[_index]+close[_index]+close[_index])/4.0; break; \
      default : _target = 0; \
   }}
   
//
//---
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
   int limit = (prev_calculated ? prev_calculated-1 : 0);

   //
   //
   //
  
   for (int i=limit; i<rates_total && !_StopFlag; i++)
   {
      double _price; _setPrice(inpPrice,_price,i);
      if (i>0 && inpPeriod>1)
      {
          double _pow = inpPeriod*mcgMultiplier*MathPow((val[i-1]!=0 && _price!=0 ? _price/val[i-1] : 0),4);
             val[i] = (_pow) ? val[i-1]+(_price-val[i-1])/_pow : _price;
      }
      else val[i] = _price;
           valc[i] = (i>0) ?(val[i]>val[i-1]) ? 1 :(val[i]<val[i-1]) ? 2 : valc[i-1]: 0;
   }
   return(rates_total);
}