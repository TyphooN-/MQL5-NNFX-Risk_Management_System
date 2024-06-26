/**=             EhlersFisherTransform.mq5  (Ehlers' Fisher Transform)
 *               Copyright 2023, mladen/TyphooN (https://www.marketwizardry.org/)
 *
 * Disclaimer and Licence
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "Fisher transform (v1.001+ by TyphooN)"
#property version   "1.001"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_label1  "Fisher transform"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrOrangeRed
#property indicator_width1  2
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkGray
#property indicator_width2  1
enum enCalcMode
{
   calc_hl, // Include current high and low in calculation
   calc_no  // Don't include current high and low in calculation
};
input int                inpPeriod   = 32;           // Period
input enCalcMode         inpCalcMode = calc_no;      // Calculation mode 
input ENUM_APPLIED_PRICE inpPrice    = PRICE_MEDIAN; // Price
double val[],valc[],signal[],prices[],work[];
int OnInit()
{
   SetIndexBuffer(0,val   ,INDICATOR_DATA);
   SetIndexBuffer(1,valc  ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,signal,INDICATOR_DATA);
   SetIndexBuffer(3,prices,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,work  ,INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME,"Ehlers Fisher transform ("+(string)inpPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { }
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
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
    int i = prev_calculated - 1;
    if (i < 0) i = 0;
    for (; i < rates_total && !_StopFlag; i++)
    {
        _setPrice(inpPrice, prices[i], i);
        int _start = i - inpPeriod + 1;
        if (_start < 0) _start = 0;
        double _hi = inpCalcMode == calc_hl ? MathMax(high[i], prices[ArrayMaximum(prices, _start, inpPeriod)]) : prices[ArrayMaximum(prices, _start, inpPeriod)];
        double _lo = inpCalcMode == calc_hl ? MathMin(low[i], prices[ArrayMinimum(prices, _start, inpPeriod)]) : prices[ArrayMinimum(prices, _start, inpPeriod)];
        double _os = (_hi != _lo) ? 2.0 * ((prices[i] - _lo) / (_hi - _lo) - 0.5) : 0;
        double _sm = (i > 0) ? 0.5 * _os + 0.5 * work[i - 1] : _os;
        work[i] = MathMax(MathMin(_sm, 0.999), -0.999);
        val[i] = 0.25 * MathLog((1 + work[i]) / (1 - work[i])) + (i > 0 ? 0.5 * val[i - 1] : 0);
        signal[i] = (i > 0) ? val[i - 1] : val[i];
        valc[i] = (val[i] > signal[i]) ? 1 : (val[i] < signal[i]) ? 2 : (i > 0) ? valc[i - 1] : 0;
    }
    // Set the global variable in the terminal
    if (valc[rates_total - 1] == 1)
    {
        GlobalVariableSet("FisherBias", 1); // 1 for bullish
    }
    else if (valc[rates_total - 1] == 2)
    {
      GlobalVariableSet("FisherBias", -1); // -1 for bearish
    }
    else
    {
        GlobalVariableSet("FisherBias", 0); // 0 for neutral
    }
    return (i);
}
