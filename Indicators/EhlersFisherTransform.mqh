/**=             EhlersFisherTransform.mqh  (Ehlers' Fisher Transform)
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
enum enCalcMode
{
   calc_hl, // Include current high and low in calculation
   calc_no  // Don't include current high and low in calculation
};
input int                inpPeriod   = 32;           // Period
input enCalcMode         inpCalcMode = calc_no;      // Calculation mode
input ENUM_APPLIED_PRICE inpPrice    = PRICE_MEDIAN; // Price
double val[],valc[],signal[],prices[],work[];
double g_prevBias = -999;
string g_fisherGVName = "";
int OnInit()
{
   g_fisherGVName = "FisherBias_" + _Symbol + "_" + IntegerToString(Period());
   SetIndexBuffer(0,val   ,INDICATOR_DATA);
   SetIndexBuffer(1,valc  ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,signal,INDICATOR_DATA);
   SetIndexBuffer(3,prices,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,work  ,INDICATOR_CALCULATIONS);
   if (inpPeriod <= 0)
   {
      Print("Period must be > 0");
      return INIT_FAILED;
   }
   IndicatorSetString(INDICATOR_SHORTNAME,"Ehlers Fisher transform ("+(string)inpPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   GlobalVariableDel(g_fisherGVName);
   g_prevBias = -999;
}
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
    if (rates_total <= 0) return 0;
    int i = prev_calculated - 1;
    if (i < 0) i = 0;
    for (; i < rates_total && !_StopFlag; i++)
    {
        _setPrice(inpPrice, prices[i], i);
        int _start = i - inpPeriod + 1;
        if (_start < 0) _start = 0;
        int _count = i - _start + 1;
        double _hi = inpCalcMode == calc_hl ? MathMax(high[i], prices[ArrayMaximum(prices, _start, _count)]) : prices[ArrayMaximum(prices, _start, _count)];
        double _lo = inpCalcMode == calc_hl ? MathMin(low[i], prices[ArrayMinimum(prices, _start, _count)]) : prices[ArrayMinimum(prices, _start, _count)];
        double _os = (_hi != _lo) ? 2.0 * ((prices[i] - _lo) / (_hi - _lo) - 0.5) : 0;
        double _sm = (i > 0) ? 0.5 * _os + 0.5 * work[i - 1] : _os;
        work[i] = MathMax(MathMin(_sm, 0.999), -0.999);
        val[i] = 0.25 * MathLog((1 + work[i]) / (1 - work[i])) + (i > 0 ? 0.5 * val[i - 1] : 0);
        signal[i] = (i > 0) ? val[i - 1] : val[i];
        valc[i] = (val[i] > signal[i]) ? 1 : (val[i] < signal[i]) ? 2 : (i > 0) ? valc[i - 1] : 0;
    }
    // Only update FisherBias GlobalVariable when loop completed fully
    if (i == rates_total && i > 0)
    {
        double newBias;
        if (valc[i - 1] == 1)
            newBias = 1;
        else if (valc[i - 1] == 2)
            newBias = -1;
        else
            newBias = 0;
        if (newBias != g_prevBias)
        {
            GlobalVariableSet(g_fisherGVName, newBias);
            g_prevBias = newBias;
        }
    }
    return (i);
}
