//+------------------------------------------------------------------+
//|                                       EhlersHilbertTransform.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|                                (v1.01+ by TyphooN)               |
//|  Main Site: http://fxstill.com                                   |
//|  Telegram:  https://t.me/fxstill (Literature on cryptocurrencies,| 
//|                                   development and code. )        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Andrei Novichkov."
#property link      "http://fxstill.com"
#property version   "1.01"
#property description "Telegram Channel: https://t.me/fxstill\n"
#property description "The Hilbert Transform:\nJohn Ehlers, \"Rocket Science for Traders.\", pg.51"
#property indicator_separate_window
#property indicator_applied_price PRICE_MEDIAN
#property indicator_buffers 14
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_width1  1
#property indicator_style1  STYLE_SOLID
#property indicator_color1  clrOrange //InPhase
#property indicator_type2   DRAW_LINE
#property indicator_width2  1
#property indicator_style2  STYLE_SOLID
#property indicator_color2  clrGreen  //Quadrature
double InPhase[], Quadrature[];
double Smooth[], Detrender[], I1[], Q1[], jI[], jQ[], I2[], Q2[], Re[], Im[], Per[], SmoothPeriod[]; 
static const int MINBAR = 7;
int OnInit()
{
   SetIndexBuffer(0, InPhase, INDICATOR_DATA);
   SetIndexBuffer(1, Quadrature, INDICATOR_DATA);
   SetIndexBuffer(2, Smooth, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, Detrender, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, I1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, Q1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, jI, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, jQ, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, I2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, Q2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, Re, INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, Im, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, Per, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, SmoothPeriod, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(InPhase, true);
   ArraySetAsSeries(Quadrature, true);
   ArraySetAsSeries(Smooth, true);
   ArraySetAsSeries(Detrender, true);
   ArraySetAsSeries(I1, true);
   ArraySetAsSeries(Q1, true);
   ArraySetAsSeries(jI, true);
   ArraySetAsSeries(jQ, true);
   ArraySetAsSeries(I2, true);
   ArraySetAsSeries(Q2, true);
   ArraySetAsSeries(Re, true);
   ArraySetAsSeries(Im, true);
   ArraySetAsSeries(Per, true);
   ArraySetAsSeries(SmoothPeriod, true);
   IndicatorSetString(INDICATOR_SHORTNAME, "EhlersHilbertTransform");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   return INIT_SUCCEEDED;
}
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
   if (rates_total < MINBAR) return 0;
   int limit = rates_total - prev_calculated;
   if (limit == 0 || limit == 1)
   {
      Hilbert(high, low, limit);
      return rates_total;
   }
   else if (limit > 1)
   {
      ArrayInitialize(InPhase, EMPTY_VALUE);
      ArrayInitialize(Quadrature, EMPTY_VALUE);
      ArrayInitialize(Smooth, 0);
      ArrayInitialize(Detrender, 0);
      ArrayInitialize(I1, 0);
      ArrayInitialize(Q1, 0);
      ArrayInitialize(jI, 0);
      ArrayInitialize(jQ, 0);
      ArrayInitialize(I2, 0);
      ArrayInitialize(Q2, 0);
      ArrayInitialize(Re, 0);
      ArrayInitialize(Im, 0);
      ArrayInitialize(Per, 0);
      ArrayInitialize(SmoothPeriod, 0);
      limit = rates_total - MINBAR;
      for (int i = limit; i >= 1 && !IsStopped(); i--)
      {
         Hilbert(high, low, i);
      }
      return rates_total;
   }
   Hilbert(high, low, 0);
   return rates_total;
}
void Hilbert(const double& high[], const double& low[], int i)
{
   double p0 = (high[i] + low[i]) / 2;
   double p1 = (high[i + 1] + low[i + 1]) / 2;
   double p2 = (high[i + 2] + low[i + 2]) / 2;
   double p3 = (high[i + 3] + low[i + 3]) / 2;
   Smooth[i] = (4 * p0 + 3 * p1 + 2 * p2 + p3) / 10;
   Detrender[i] = (0.0962 * Smooth[i] + 0.5769 * Smooth[i + 2] - 
                    0.5769 * Smooth[i + 4] - 0.0962 * Smooth[i + 6]) * (0.075 + 0.54);
   Q1[i] = (0.0962 * Detrender[i] + 0.5769 * Detrender[i + 2] - 
            0.5769 * Detrender[i + 4] - 0.0962 * Detrender[i + 6]) * (0.075 + 0.54);
   I1[i] = Detrender[i + 3];    
   jI[i] = (0.0962 * I1[i] + 0.5769 * I1[i + 2] - 
            0.5769 * I1[i + 4] - 0.0962 * I1[i + 6]) * (0.075 + 0.54); 
   jQ[i] = (0.0962 * Q1[i] + 0.5769 * Q1[i + 2] - 
            0.5769 * Q1[i + 4] - 0.0962 * Q1[i + 6]) * (0.075 + 0.54);		    	                
   I2[i] = I1[i] - jQ[i]; 
   Q2[i] = Q1[i] + jI[i]; 	
   Re[i] = I2[i] * I2[i] + Q2[i] * Q2[i + 1]; 
   Im[i] = I2[i] * Q2[i + 1]  - Q2[i] * I2[i + 1]; 
   Re[i] = NormalizeDouble(0.2 * Re[i] + 0.8 * Re[i + 1], 8); 
   Im[i] = NormalizeDouble(0.2 * Im[i] + 0.8 * Im[i + 1], 8); 
   if (Im[i] != 0 && Re[i] != 0)
   {
      Per[i] = 2 * M_PI / (MathArctan(Im[i] / Re[i]));
   }
   else
   { 
      Per[i] = 0;
   }
   Per[i] = MathMin(50.0, MathMax(6.0, Per[i]));
   Per[i] = 0.2 * Per[i] + 0.8 * Per[i + 1]; 
   SmoothPeriod[i] = 0.33 * Per[i] + 0.67 * SmoothPeriod[i + 1]; 	
   InPhase[i] = I1[i]; 
   Quadrature[i] = Q1[i];	
}
