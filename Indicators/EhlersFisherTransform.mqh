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

#ifdef __MQL5__
// MQL5: 5 buffers -- val (INDICATOR_DATA) + valc (COLOR_INDEX) + signal + prices + work
double val[],valc[],signal[],prices[],work[];
#else
// MQL4: 6 buffers -- valGreen + valRed + valGray (3 overlapping DRAW_LINE) + signal + prices + work
double valGreen[],valRed[],valGray[],signal[],prices[],work[];
#endif

double g_prevBias = -999;
string g_fisherGVName = "";

int OnInit()
{
   g_fisherGVName = "FisherBias_" + _Symbol + "_" + IntegerToString(Period());

#ifdef __MQL5__
   SetIndexBuffer(0,val   ,INDICATOR_DATA);
   SetIndexBuffer(1,valc  ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,signal,INDICATOR_DATA);
   SetIndexBuffer(3,prices,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,work  ,INDICATOR_CALCULATIONS);
#else
   SetIndexBuffer(0, valGreen);
   SetIndexBuffer(1, valRed);
   SetIndexBuffer(2, valGray);
   SetIndexBuffer(3, signal);
   SetIndexBuffer(4, prices);
   SetIndexBuffer(5, work);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrMediumSeaGreen);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrOrangeRed);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, clrDarkGray);
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 1, clrDarkGray);
   SetIndexLabel(0, "Fisher Green");
   SetIndexLabel(1, "Fisher Red");
   SetIndexLabel(2, "Fisher Gray");
   SetIndexLabel(3, "Signal");
#endif

   if (inpPeriod <= 0)
   {
      Print("Period must be > 0");
      return INIT_FAILED;
   }

#ifdef __MQL5__
   IndicatorSetString(INDICATOR_SHORTNAME,"Ehlers Fisher transform ("+(string)inpPeriod+")");
#else
   IndicatorShortName("Ehlers Fisher transform ("+(string)inpPeriod+")");
#endif
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
    for (; i < rates_total && !IsStopped(); i++)
    {
        _setPrice(inpPrice, prices[i], i);
        int _start = i - inpPeriod + 1;
        if (_start < 0) _start = 0;
        int _count = i - _start + 1;
#ifdef __MQL5__
        double _hi = inpCalcMode == calc_hl ? MathMax(high[i], prices[ArrayMaximum(prices, _start, _count)]) : prices[ArrayMaximum(prices, _start, _count)];
        double _lo = inpCalcMode == calc_hl ? MathMin(low[i], prices[ArrayMinimum(prices, _start, _count)]) : prices[ArrayMinimum(prices, _start, _count)];
#else
        // MQL4 ArrayMaximum/ArrayMinimum: (array, count, start) -- param order swapped
        double _hi = inpCalcMode == calc_hl ? MathMax(high[i], prices[ArrayMaximum(prices, _count, _start)]) : prices[ArrayMaximum(prices, _count, _start)];
        double _lo = inpCalcMode == calc_hl ? MathMin(low[i], prices[ArrayMinimum(prices, _count, _start)]) : prices[ArrayMinimum(prices, _count, _start)];
#endif
        double _os = (_hi != _lo) ? 2.0 * ((prices[i] - _lo) / (_hi - _lo) - 0.5) : 0;

#ifdef __MQL5__
        double _sm = (i > 0) ? 0.5 * _os + 0.5 * work[i - 1] : _os;
        work[i] = MathMax(MathMin(_sm, 0.999), -0.999);
        val[i] = 0.25 * MathLog((1 + work[i]) / (1 - work[i])) + (i > 0 ? 0.5 * val[i - 1] : 0);
        signal[i] = (i > 0) ? val[i - 1] : val[i];
        valc[i] = (val[i] > signal[i]) ? 1 : (val[i] < signal[i]) ? 2 : (i > 0) ? valc[i - 1] : 0;
#else
        double _sm = (i > 0) ? 0.5 * _os + 0.5 * work[i - 1] : _os;
        work[i] = MathMax(MathMin(_sm, 0.999), -0.999);
        double fisher_val = 0.25 * MathLog((1 + work[i]) / (1 - work[i]));
        if (i > 0) fisher_val += 0.5 * _getPrevVal(i - 1);
        signal[i] = (i > 0) ? _getPrevVal(i - 1) : fisher_val;
        // Determine color: 1=green (bullish), 2=red (bearish), 0=gray (neutral)
        int colorIdx;
        if (fisher_val > signal[i])
            colorIdx = 1;
        else if (fisher_val < signal[i])
            colorIdx = 2;
        else
            colorIdx = (i > 0) ? _getPrevColor(i - 1) : 0;
        // Route to color-specific buffer
        if (colorIdx == 1)
        {
            valGreen[i] = fisher_val;
            valRed[i]   = EMPTY_VALUE;
            valGray[i]  = EMPTY_VALUE;
            // Connect from previous bar to avoid gap
            if (i > 0 && valGreen[i - 1] == EMPTY_VALUE)
                valGreen[i - 1] = _getPrevVal(i - 1);
        }
        else if (colorIdx == 2)
        {
            valGreen[i] = EMPTY_VALUE;
            valRed[i]   = fisher_val;
            valGray[i]  = EMPTY_VALUE;
            if (i > 0 && valRed[i - 1] == EMPTY_VALUE)
                valRed[i - 1] = _getPrevVal(i - 1);
        }
        else
        {
            valGreen[i] = EMPTY_VALUE;
            valRed[i]   = EMPTY_VALUE;
            valGray[i]  = fisher_val;
            if (i > 0 && valGray[i - 1] == EMPTY_VALUE)
                valGray[i - 1] = _getPrevVal(i - 1);
        }
#endif
    }
    // Only update FisherBias GlobalVariable when loop completed fully
    if (i == rates_total && i > 0)
    {
#ifdef __MQL5__
        double lastValc = valc[i - 1];
#else
        double lastValc = (double)_getPrevColor(i - 1);
#endif
        double newBias;
        if (lastValc == 1)
            newBias = 1;
        else if (lastValc == 2)
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

#ifdef __MQL4__
// Helper: get the fisher value from whichever color buffer holds it at bar idx
double _getPrevVal(int idx)
{
    if (valGreen[idx] != EMPTY_VALUE) return valGreen[idx];
    if (valRed[idx]   != EMPTY_VALUE) return valRed[idx];
    if (valGray[idx]  != EMPTY_VALUE) return valGray[idx];
    return 0;
}
// Helper: get the color index (1=green, 2=red, 0=gray) at bar idx
int _getPrevColor(int idx)
{
    if (valGreen[idx] != EMPTY_VALUE) return 1;
    if (valRed[idx]   != EMPTY_VALUE) return 2;
    if (valGray[idx]  != EMPTY_VALUE) return 0;
    return 0;
}
#endif
