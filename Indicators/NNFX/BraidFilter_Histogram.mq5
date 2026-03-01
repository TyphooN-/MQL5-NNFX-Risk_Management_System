//+------------------------------------------------------------------+
//|                                                 Braid Filter.mq5 |
//|                                        Copyright © 2023, Centaur |
//|      forex-station.com/memberlist.php?mode=viewprofile&u=4948703 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2023, Centaur"
#property link      "forex-station.com/memberlist.php?mode=viewprofile&u=4948703"
#property version   "1.00"
#property indicator_separate_window
#property indicator_level1  0
#property indicator_buffers 34
#property indicator_plots   2
//--- plot Braid Histogram
#property indicator_label1  "Braid Histogram"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLimeGreen,clrOrangeRed,clrLightGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  5
//--- plot Filter Line
#property indicator_label2  "Filter Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- enumerations
enum ENUM_AVERAGES
  {
   av_2pssf,   //2 Pole Super Smoother Filter (2PSSF)
   av_aema,    //Adaptive Exponential Moving Average (AEMA)
   av_arsi,    //Adaptive Relative Strength Index (ARSI)
   av_alma,    //Arnaud Legoux Moving Average (ALMA)
   av_ammma,   //Average Modified Method Moving Average (AMMMA)
   av_bama,    //Bryant Adaptive Moving Average (BAMA)
   av_cvma,    //Chande Variable Moving Average (CVMA)
   av_cama,    //Cong Adaptive Moving Average (CAMA)
   av_dema,    //Double Exponential Moving Average (DEMA)
   av_evwma,   //Elastic Volume Weighted Moving Average (EVWMA)
   av_ema,     //Exponential Moving Average (EMA)
   av_fwma,    //Fibonacci Weighted Moving Average (FWMA)
   av_gma,     //G-Channel Moving Average (GMA)
   av_gwma,    //Guassian Weighted Moving Average (GWMA)
   av_hwma,    //Henderson Weighted Moving Average (HWMA)
   av_hma,     //Hull Moving Average (HMA)
   av_ie2,     //Integral of Linear Regression Slope + Endpoint Moving Average / 2 (IE2)
   av_jf,      //Jurik Filter (JF)
   av_kf,      //Kalman Filter (KF)
   av_kama,    //Kaufman Adaptive Moving Average (KAMA)
   av_kijun,   //Kijun Line (KIJUN)
   av_lsma,    //Least Squares Moving Average (LSMA)
   av_lma,     //Leo Moving Average (LMA)
   av_lwma,    //Linear Weighted Moving Average (LWMA)
   av_median,  //Moving Median (MEDIAN)
   av_pwma,    //Parabolic Weighted Moving Average (PWMA)
   av_ppwma,    //Pivot Point Weighted Moving Average (PPWMA)
   av_rma,     //Relative Moving Average (RMA)
   av_sma,     //Simple Moving Average (SMA)
   av_swma,    //Sine Weighted Moving Average (SWMA)
   av_smma,    //Smoothed Moving Average (SMMA)
   av_t3ma,    //T3 Moving Average (T3MA)
   av_twma,    //Triangular Weighted Moving Average (TWMA)
   av_tema,    //Triple Exponential Moving Average (TEMA)
   av_vwma,    //Volume Weighted Moving Average (VWMA)
   av_zli      //Zero Lag Indicator (ZLI)
  };
//--- input parameters
input ENUM_AVERAGES     inp_averages            = av_ema;      // Averaging Type
input int               inp_period1             = 5;           // Period 1
input int               inp_period2             = 8;           // Period 2
input int               inp_period3             = 20;          // Period 3
input int               PipsMinSepPercent       = 50;          // Filter: Percentage of ATR
//--- indicator buffers
double                  BraidHistogramBuffer[];
double                  BraidHistogramColors[];
double                  FilterLineBuffer[];
double                  average1[], average2[], average3[];
double                  atr[];
double                  rsi1[], rsi2[], rsi3[];
double                  temp11[], temp12[], temp13[], temp14[], temp15[], temp16[], temp17[], temp18[];
double                  temp21[], temp22[], temp23[], temp24[], temp25[], temp26[], temp27[], temp28[];
double                  temp31[], temp32[], temp33[], temp34[], temp35[], temp36[], temp37[], temp38[];
//--- indicator variables
int                     period1;
int                     period2;
int                     period3;
int                     percofatr;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- check input parameters
   period1 = inp_period1 < 1 ? 1 : inp_period1;
   period2 = inp_period2 < 1 ? 1 : inp_period2;
   period3 = inp_period3 < 1 ? 1 : inp_period3;
   percofatr = PipsMinSepPercent < 1 ? 1 : PipsMinSepPercent;
//--- indicator buffers mapping
   SetIndexBuffer(0, BraidHistogramBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BraidHistogramColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, FilterLineBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, average1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, average2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, average3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, atr, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, rsi1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, rsi2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, rsi3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, temp11, INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, temp12, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, temp13, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, temp14, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, temp15, INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, temp16, INDICATOR_CALCULATIONS);
   SetIndexBuffer(16, temp17, INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, temp18, INDICATOR_CALCULATIONS);
   SetIndexBuffer(18, temp21, INDICATOR_CALCULATIONS);
   SetIndexBuffer(19, temp22, INDICATOR_CALCULATIONS);
   SetIndexBuffer(20, temp23, INDICATOR_CALCULATIONS);
   SetIndexBuffer(21, temp24, INDICATOR_CALCULATIONS);
   SetIndexBuffer(22, temp25, INDICATOR_CALCULATIONS);
   SetIndexBuffer(23, temp26, INDICATOR_CALCULATIONS);
   SetIndexBuffer(24, temp27, INDICATOR_CALCULATIONS);
   SetIndexBuffer(25, temp28, INDICATOR_CALCULATIONS);
   SetIndexBuffer(26, temp31, INDICATOR_CALCULATIONS);
   SetIndexBuffer(27, temp32, INDICATOR_CALCULATIONS);
   SetIndexBuffer(28, temp33, INDICATOR_CALCULATIONS);
   SetIndexBuffer(29, temp34, INDICATOR_CALCULATIONS);
   SetIndexBuffer(30, temp35, INDICATOR_CALCULATIONS);
   SetIndexBuffer(31, temp36, INDICATOR_CALCULATIONS);
   SetIndexBuffer(32, temp37, INDICATOR_CALCULATIONS);
   SetIndexBuffer(33, temp38, INDICATOR_CALCULATIONS);
//--- set indicator accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//--- set indicator name display
   string averages_name = inp_averages == av_2pssf ? "2PSSF" : inp_averages == av_aema ? "AEMA" : inp_averages == av_alma ? "ALMA" : inp_averages == av_ammma ? "AMMMA" : inp_averages == av_arsi ? "ARSI" : inp_averages == av_bama ? "BAMA" : inp_averages == av_cama ? "CAMA" : inp_averages == av_cvma ? "CVMA" : inp_averages == av_dema ? "DEMA" : inp_averages == av_ema ? "EMA" : inp_averages == av_evwma ? "EVWMA" : inp_averages == av_fwma ? "FWMA" : inp_averages == av_gma ? "GMA" : inp_averages == av_gwma ? "GWMA" : inp_averages == av_hma ? "HMA" : inp_averages == av_hwma ? "HWMA" : inp_averages == av_ie2 ? "IE2" : inp_averages == av_jf ? "JF" : inp_averages == av_kama ? "KAMA" : inp_averages == av_kf ? "KF" : inp_averages == av_kijun ? "KIJUN" : inp_averages == av_lma ? "LMA" : inp_averages == av_lsma ? "LSMA" : inp_averages == av_lwma ? "LWMA" : inp_averages == av_median ? "MEDIAN" : inp_averages == av_ppwma ? "PPMA" : inp_averages == av_pwma ? "PWMA" : inp_averages == av_rma ? "RMA" : inp_averages == av_sma ? "SMA" : inp_averages == av_smma ? "SMMA" : inp_averages == av_swma ? "SWMA" : inp_averages == av_t3ma ? "T3MA" : inp_averages == av_tema ? "TEMA" : inp_averages == av_twma ? "TWMA" : inp_averages == av_vwma ? "VWMA" : inp_averages == av_zli ? "ZLI" : " ";
   string short_name = "Braid Filter (" + averages_name + ", " + IntegerToString(period1) + ", " + IntegerToString(period2) + ", " + IntegerToString(period3) + ", " + IntegerToString(percofatr) + ")";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
//--- sets drawing lines to empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
//--- initialization succeeded
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//--- populate average 1 buffer
   fuGetAverages(rates_total, prev_calculated, inp_averages, period1, close, high, low, close, tick_volume, temp11, temp12, temp13, temp14, temp15, temp16, temp17, temp18, average1, rsi1);
//--- populate average 2 buffer
   fuGetAverages(rates_total, prev_calculated, inp_averages, period2, open, high, low, close, tick_volume, temp21, temp22, temp23, temp24, temp25, temp26, temp27, temp28, average2, rsi2);
//--- populate average 3 buffer
   fuGetAverages(rates_total, prev_calculated, inp_averages, period3, close, high, low, close, tick_volume, temp31, temp32, temp33, temp34, temp35, temp36, temp37, temp38, average3, rsi3);
//--- populate atr buffer
   inAverageTrueRange(rates_total, prev_calculated, 14, high, low, close, atr);
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < fmax(period1, fmax(period2, period3)))
        {
         BraidHistogramBuffer[i] = EMPTY_VALUE;
         BraidHistogramColors[i] = EMPTY_VALUE;
         FilterLineBuffer[i] = EMPTY_VALUE;
        }
      else
        {
         double max = fmax(average1[i], fmax(average2[i], average3[i]));
         double min = fmin(average1[i], fmin(average2[i], average3[i]));
         double dif = max - min;
         BraidHistogramBuffer[i] = dif;
         FilterLineBuffer[i] = atr[i] * percofatr / 100.0;
         BraidHistogramColors[i] = average1[i] > average2[i] && BraidHistogramBuffer[i] > FilterLineBuffer[i] ? 0.0 : average2[i] > average1[i] && BraidHistogramBuffer[i] > FilterLineBuffer[i] ? 1.0 : BraidHistogramBuffer[i] < FilterLineBuffer[i] ? 2.0 : BraidHistogramColors[i - 1];
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Get Averages from ENUM_AVERAGES                                  |
//+------------------------------------------------------------------+
int fuGetAverages(const int rates_total,
                  const int prev_calculated,
                  const ENUM_AVERAGES list_averages,
                  const int value_length, // min val: 1; step val: 1; default val: 10
                  const double &source_price[],
                  const double &source_high[],
                  const double &source_low[],
                  const double &source_close[],
                  const long &source_volume[],
                  double &temp_arr1[],
                  double &temp_arr2[],
                  double &temp_arr3[],
                  double &temp_arr4[],
                  double &temp_arr5[],
                  double &temp_arr6[],
                  double &temp_arr7[],
                  double &temp_arr8[],
                  double &result_averages[],
                  double &result_rsi[],
                  const int value_length_rsi = 14, // Relative Strength Index> min val: 1; step val: 1; default val: 14
                  const int value_phase = 0, // Jurik Filter> min val: -100; max val: 100; step val: 1; default val: 0
                  const double value_volume_factor = 0.7, // T3 Moving Average> min val: 0.0; max val: 2.0; step val: 0.01; default val: 0.7
                  const int value_gain_limit = 50, // Zero Lag Indicator> min val: 1; step val: 1; default val: 50
                  const double value_power = 2.0, // Parabolic Weighted Moving Average> min val: 1.0; step val: 0.01; default val: 2.0
                  const double value_trend_parameter = -1.0, // Bryant Adaptive Moving Average> step val: 0.1; default val: -1.0
                  const double value_offset = 0.0, // Arnaud Legoux Moving Average> min val: 0.0; step val: 0.01; default val: 0.0
                  const int value_sigma = 10) // Arnaud Legoux Moving Average> min val: 1; step val: 1; default val: 10
  {
   switch(list_averages)
     {
      case av_2pssf:
         fil2PoleSuperSmoother(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_aema:
         maAdaptiveExponential(rates_total, prev_calculated, value_length, source_price, source_high, source_low, result_averages);
         break;
      case av_alma:
         maArnaudLegoux(rates_total, prev_calculated, value_length, value_offset, value_sigma, source_price, result_averages);
         break;
      case av_ammma:
         maAverageModifiedMethod(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_arsi:
         inRelativeStrengthIndex(rates_total, prev_calculated, value_length_rsi, source_price, temp_arr1, temp_arr2, result_rsi);
         maAdaptiveRelativeStrengthIndex(rates_total, prev_calculated, value_length, source_price, result_rsi, result_averages);
         break;
      case av_bama:
         maBryantAdaptive(rates_total, prev_calculated, value_length, value_trend_parameter, source_price, result_averages);
         break;
      case av_cama:
         maCongAdaptive(rates_total, prev_calculated, value_length, source_price, source_high, source_low, source_close, temp_arr1, result_averages);
         break;
      case av_cvma:
         maChandeVariable(rates_total, prev_calculated, value_length, source_price, temp_arr1, temp_arr2, temp_arr3, temp_arr4, temp_arr5, result_averages);
         break;
      case av_dema:
         maDoubleExponential(rates_total, prev_calculated, value_length, source_price, temp_arr1, temp_arr2, result_averages);
         break;
      case av_ema:
         maExponential(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_evwma:
         maElasticVolumeWeighted(rates_total, prev_calculated, value_length, source_price, source_volume, result_averages);
         break;
      case av_fwma:
         maFibonacciWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_gma:
         maG_Channel(rates_total, prev_calculated, value_length, source_price, temp_arr1, temp_arr2, result_averages);
         break;
      case av_gwma:
         maGuassianWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_hma:
         maHull(rates_total, prev_calculated, value_length, source_price, temp_arr1, temp_arr2, result_averages);
         break;
      case av_hwma:
         maHendersonWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_ie2:
         maIntegralEndpoint2(rates_total, prev_calculated, value_length, source_price, temp_arr1, result_averages);
         break;
      case av_jf:
         filJurik(rates_total, prev_calculated, value_length, value_phase, source_price, temp_arr1, temp_arr2, temp_arr3, temp_arr4, temp_arr5, temp_arr6, temp_arr7, temp_arr8, result_averages);
         break;
      case av_kama:
         maKaufmanAdaptive(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_kf:
         filKalman(rates_total, prev_calculated, value_length, source_price, temp_arr1, result_averages);
         break;
      case av_kijun:
         maKijunLine(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_lma:
         maLeo(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_lsma:
         maLeastSquares(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_lwma:
         maLinearWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_median:
         maMovingMedian(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_ppwma:
         maPivotPointWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_pwma:
         maParabolicWeighted(rates_total, prev_calculated, value_length, value_power, source_price, result_averages);
         break;
      case av_rma:
         maRelative(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_sma:
         maSimple(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_smma:
         maSmoothed(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_swma:
         maSineWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_t3ma:
         maT3(rates_total, prev_calculated, value_length, value_volume_factor, source_price, temp_arr1, temp_arr2, temp_arr3, temp_arr4, temp_arr5, temp_arr6, result_averages);
         break;
      case av_tema:
         maTripleExponential(rates_total, prev_calculated, value_length, source_price, temp_arr1, temp_arr2, temp_arr3, result_averages);
         break;
      case av_twma:
         maTriangularWeighted(rates_total, prev_calculated, value_length, source_price, result_averages);
         break;
      case av_vwma:
         maVolumeWeighted(rates_total, prev_calculated, value_length, source_price, source_volume, result_averages);
         break;
      case av_zli:
         maZeroLagIndicator(rates_total, prev_calculated, value_length, value_gain_limit, source_price, temp_arr1, result_averages);
         break;
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| 2 Pole Super Smoother Filter (2PSSF)                             |
//+------------------------------------------------------------------+
int fil2PoleSuperSmoother(const int rates_total,
                          const int prev_calculated,
                          const int value_length, // min val: 1; step val: 1; default val: 10
                          const double &source_price[],
                          double &result_2pssf[])
  {
//--- bar index start
   int bar_index;
   double a1 = exp(-sqrt(2.0) * M_PI / double(value_length));
   double c2 = 2.0 * a1 * cos((sqrt(2.0) * 180.0 / double(value_length)) * (M_PI / 180.0));
   double c3 = -pow(a1, 2.0);
   double c1 = 1.0 - c2 - c3;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 2)
         result_2pssf[i] = source_price[i];
      else
         result_2pssf[i] = c1 * (source_price[i] + source_price[i - 1]) / 2 + c2 * result_2pssf[i - 1] + c3 * result_2pssf[i - 2];
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Adaptive Exponential Moving Average (AEMA)                       |
//+------------------------------------------------------------------+
int maAdaptiveExponential(const int rates_total,
                          const int prev_calculated,
                          const int value_length, // min val: 1; step val: 1; default val: 10
                          const double &source_price[],
                          const double &source_high[],
                          const double &source_low[],
                          double &result_aema[])
  {
//--- bar index start
   int bar_index;
   double mltp1 = 2.0 / (double(value_length) + 1.0);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_aema[i] = source_price[i];
      else
        {
         double hh = -DBL_MAX, ll = DBL_MAX;
         for(int k = 0; k < value_length; k++)
           {
            hh = source_high[i - k] > hh ? source_high[i - k] : hh;
            ll = source_low[i - k] < ll ? source_low[i - k] : ll;
           }
         double hl_range = hh - ll;
         double mltp2 = (hl_range > 0) ? fabs((source_price[i] - ll) - (hh - source_price[i])) / hl_range : 0;
         result_aema[i] = value_length == 1 ? source_price[i] : result_aema[i - 1] + mltp1 * (1 + mltp2) * (source_price[i] - result_aema[i - 1]);
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Relative Strength Index (RSI)                                    |
//+------------------------------------------------------------------+
int inRelativeStrengthIndex(const int rates_total,
                            const int prev_calculated,
                            const int value_length,
                            const double &source_price[],
                            double &temp_avg_gain[],
                            double &temp_avg_loss[],
                            double &result_rsi[])
  {
//--- bar index start
   int bar_index;
   double alpha = 1.0 / double(value_length);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      double gain = i < 1 ? 0.0 : source_price[i] - source_price[i - 1] > 0.0 ? source_price[i] - source_price[i - 1] : 0.0;
      double loss = i < 1 ? 0.0 : source_price[i] - source_price[i - 1] < 0.0 ? fabs(source_price[i] - source_price[i - 1]) : 0.0;
      if(i < 1)
        {
         temp_avg_gain[i] = 0.0;
         temp_avg_loss[i] = 0.0;
         result_rsi[i] = EMPTY_VALUE;
        }
      else
        {
         temp_avg_gain[i] = gain * alpha + temp_avg_gain[i - 1] * (1.0 - alpha);
         temp_avg_loss[i] = loss * alpha + temp_avg_loss[i - 1] * (1.0 - alpha);
         if (temp_avg_loss[i] == 0.0)
            result_rsi[i] = 100.0;
         else
           {
            double rs = temp_avg_gain[i] / temp_avg_loss[i];
            result_rsi[i] = 100.0 - (100.0 / (1.0 + rs));
           }
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Adaptive Relative Strength Index (ARSI)                          |
//+------------------------------------------------------------------+
int maAdaptiveRelativeStrengthIndex(const int rates_total,
                                    const int prev_calculated,
                                    const int value_length, // min val: 1; step val: 1; default val: 10
                                    const double &source_price[],
                                    const double &source_rsi_value[],
                                    double &result_arsi[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_arsi[i] = source_price[i];
      else
        {
         double smoothing_constant = (fabs(source_rsi_value[i] / 100.0 - 0.5) * 2.0);
         result_arsi[i] = result_arsi[i - 1] + smoothing_constant * (source_price[i] - result_arsi[i - 1]);
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Arnaud Legoux Moving Average (ALMA)                              |
//+------------------------------------------------------------------+
int maArnaudLegoux(const int rates_total,
                   const int prev_calculated,
                   const int value_length, // min val: 1; step val: 1; default val: 10
                   const double value_offset, // min val: 0.0; step val: 0.01; default val: 0.85
                   const int value_sigma, // min val: 1; step val: 1; default val: 6
                   const double &source_price[],
                   double &result_alma[])
  {
//--- bar index start
   int bar_index;
   double m = value_offset * (double(value_length) - 1.0);
   double s = double(value_length) / double(value_sigma);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_alma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         double two_s_sq = 2.0 * s * s;
         for(int k = 0; k < value_length; k++)
           {
            double km = k - m;
            weight = (two_s_sq > 0) ? exp(-1.0 * km * km / two_s_sq) : 1.0;
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_alma[i] = (sum_weight != 0) ? sum_weight_price / sum_weight : source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Average Modified Method Moving Average (AMMMA)                   |
//+------------------------------------------------------------------+
int maAverageModifiedMethod(const int rates_total,
                            const int prev_calculated,
                            const int value_length, // min val: 1; step val: 1; default val: 30
                            const double &source_price[],
                            double &result_ammma[])
  {
//--- bar index start
   int bar_index;
   double alpha = 2.0 / (1.0 + double(value_length));
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
         result_ammma[i] = source_price[i];
      else
         result_ammma[i] = (double(value_length - 1) * result_ammma[i - 1] + source_price[i]) / double(value_length);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Bryant Adaptive Moving Average (BAMA)                            |
//+------------------------------------------------------------------+
int maBryantAdaptive(const int rates_total,
                     const int prev_calculated,
                     const int value_length, // min val: 1; step val: 1; default val: 10
                     const double value_trend_parameter, // step val: 0.1; default val: -1.0
                     const double &source_price[],
                     double &result_bama[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_bama[i] = source_price[i];
      else
        {
         double noise = 0.0;
         for(int k = 0; k < value_length; k++)
            noise += fabs(source_price[i - k] - source_price[i - k - 1]);
         double signal = fabs(source_price[i] - source_price[i - value_length]);
         double efficiency_ratio = noise != 0.0 ? signal / noise : 0.0;
         double variable_efficiency_ratio = pow(efficiency_ratio - (2.0 * efficiency_ratio - 1.0) / 2.0 * (1.0 - value_trend_parameter) + 0.5, 2.0);
         double variable_length = (double(value_length) - variable_efficiency_ratio + 1.0) / variable_efficiency_ratio;
         double variable_alpha = 2.0 / (1.0 + variable_length);
         result_bama[i] = variable_alpha * source_price[i] + (1.0 - variable_alpha) * result_bama[i - 1];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Chande Variable Moving Average (CVMA)                            |
//+------------------------------------------------------------------+
int maChandeVariable(const int rates_total,
                     const int prev_calculated,
                     const int value_length, // min val: 1; step val: 1; default val: 10
                     const double &source_price[],
                     double &temp_pdmS[],
                     double &temp_mdmS[],
                     double &temp_pdiS[],
                     double &temp_mdiS[],
                     double &temp_iS[],
                     double &result_cvma[])
  {
//--- bar index start
   int bar_index;
   double k = 1.0 / double(value_length);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
        {
         temp_pdmS[i] = source_price[i];
         temp_mdmS[i] = source_price[i];
         temp_pdiS[i] = source_price[i];
         temp_mdiS[i] = source_price[i];
         temp_iS[i] = source_price[i];
         result_cvma[i] = source_price[i];
        }
      else
        {
         temp_pdmS[i] = ((1 - k) * temp_pdmS[i - 1] + k * fmax((source_price[i] - source_price[i - 1]), 0.0));
         temp_mdmS[i] = ((1 - k) * temp_mdmS[i - 1] + k * fmax((source_price[i - 1] - source_price[i]), 0.0));
         double s = temp_pdmS[i] + temp_mdmS[i];
         if (s != 0)
           {
            temp_pdiS[i] = ((1 - k) * temp_pdiS[i - 1] + k * (temp_pdmS[i] / s));
            temp_mdiS[i] = ((1 - k) * temp_mdiS[i - 1] + k * (temp_mdmS[i] / s));
           }
         else
           {
            temp_pdiS[i] = temp_pdiS[i - 1];
            temp_mdiS[i] = temp_mdiS[i - 1];
           }
         double d = fabs(temp_pdiS[i] - temp_mdiS[i]);
         double s1 = temp_pdiS[i] + temp_mdiS[i];
         temp_iS[i] = (s1 != 0) ? ((1 - k) * temp_iS[i - 1] + k * (d / s1)) : temp_iS[i - 1];
         double hhv = -DBL_MAX, llv = DBL_MAX;
         for(int m = 0; m < value_length; m++)
           {
            hhv = temp_iS[i - m] > hhv ? temp_iS[i - m] : hhv;
            llv = temp_iS[i - m] < llv ? temp_iS[i - m] : llv;
           }
         double d1 = hhv - llv;
         double vI = (d1 != 0) ? (temp_iS[i] - llv) / d1 : 0;
         result_cvma[i] = k == 1 ? k * vI * source_price[i] : (1.0 - k * vI) * result_cvma[i - 1] + k * vI * source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Cong Adaptive Moving Average (CAMA)                              |
//+------------------------------------------------------------------+
int maCongAdaptive(const int rates_total,
                   const int prev_calculated,
                   const int value_length, // min val: 1; step val: 1; default val: 10
                   const double &source_price[],
                   const double &source_high[],
                   const double &source_low[],
                   const double &source_close[],
                   double &temp_true_range[],
                   double &result_cama[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      temp_true_range[i] = i < 1 ? source_high[i] - source_low[i] : fmax(source_high[i] - source_low[i], fmax(fabs(source_high[i] - source_close[i - 1]), fabs(source_low[i] - source_close[i - 1])));
      if(i < value_length)
         result_cama[i] = source_price[i];
      else
        {
         double effort = 0.0, hh = -DBL_MAX, ll = DBL_MAX;
         for(int k = 0; k < value_length; k++)
           {
            effort += temp_true_range[i - k];
            hh = source_high[i - k] > hh ? source_high[i - k] : hh;
            ll = source_low[i - k] < ll ? source_low[i - k] : ll;
           }
         double result = hh - ll;
         double alpha = (effort > 0) ? result / effort : 1.0;
         result_cama[i] = alpha == 1.0 ? alpha * source_price[i] : alpha * source_price[i] + (1.0 - alpha) * result_cama[i - 1];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Double Exponential Moving Average (DEMA)                         |
//+------------------------------------------------------------------+
int maDoubleExponential(const int rates_total,
                        const int prev_calculated,
                        const int value_length, // min val: 1; step val: 1; default val: 10
                        const double &source_price[],
                        double &temp_ema1[],
                        double &temp_ema2[],
                        double &result_dema[])
  {
//--- bar index start
   int bar_index;
   double alpha = 2.0 / (1.0 + double(value_length));
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
        {
         temp_ema1[i] = source_price[i];
         temp_ema2[i] = source_price[i];
         result_dema[i] = source_price[i];
        }
      else
        {
         temp_ema1[i] = source_price[i] * alpha + temp_ema1[i - 1] * (1.0 - alpha);
         temp_ema2[i] = temp_ema1[i] * alpha + temp_ema2[i - 1] * (1.0 - alpha);
         result_dema[i] = 2.0 * temp_ema1[i] - temp_ema2[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Elastic Volume Weighted Moving Average (EVWMA)                   |
//+------------------------------------------------------------------+
int maElasticVolumeWeighted(const int rates_total,
                            const int prev_calculated,
                            const int value_length, // min val: 1; step val: 1; default val: 10
                            const double &source_price[],
                            const long &source_volume[],
                            double &result_evwma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_evwma[i] = source_price[i];
      else
        {
         double sum = 0.0;
         for(int k = 0; k < value_length; k++)
            sum += double(source_volume[i - k]);
         if (sum != 0)
            result_evwma[i] = (result_evwma[i - 1] * (sum - double(source_volume[i])) / sum) + (double(source_volume[i]) * source_price[i] / sum);
         else
            result_evwma[i] = source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Exponential Moving Average (EMA)                                 |
//+------------------------------------------------------------------+
int maExponential(const int rates_total,
                  const int prev_calculated,
                  const int value_length, // min val: 1; step val: 1; default val: 10
                  const double &source_price[],
                  double &result_ema[])
  {
//--- bar index start
   int bar_index;
   double alpha = 2.0 / (1.0 + double(value_length));
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
         result_ema[i] = source_price[i];
      else
         result_ema[i] = source_price[i] * alpha + result_ema[i - 1] * (1.0 - alpha);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Fibonacci Weighted Moving Average (FWMA)                         |
//+------------------------------------------------------------------+
int maFibonacciWeighted(const int rates_total,
                        const int prev_calculated,
                        const int value_length, // min val: 1; step val: 1; default val: 10
                        const double &source_price[],
                        double &result_fwma[])
  {
//--- bar index start
   int bar_index;
   double phi = (1.0 + sqrt(5.0)) / 2.0;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_fwma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = (pow(phi, double(value_length - k)) - pow(-1.0, double(value_length - k)) / pow(phi, double(value_length - k))) / sqrt(5.0);
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_fwma[i] = (sum_weight != 0) ? sum_weight_price / sum_weight : source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| G-Channel Moving Average (GMA)                                   |
//+------------------------------------------------------------------+
int maG_Channel(const int rates_total,
                const int prev_calculated,
                const int value_length, // min val: 1; step val: 1; default val: 100
                const double &source_price[],
                double &temp_upper_band[],
                double &temp_lower_band[],
                double &result_g_channel[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
        {
         temp_upper_band[i] = 0.0;
         temp_lower_band[i] = 0.0;
         result_g_channel[i] = source_price[i];
        }
      else
        {
         temp_upper_band[i] = fmax(source_price[i], temp_upper_band[i - 1]) - (temp_upper_band[i - 1] - temp_lower_band[i - 1]) / double(value_length);
         temp_lower_band[i] = fmin(source_price[i], temp_lower_band[i - 1]) + (temp_upper_band[i - 1] - temp_lower_band[i - 1]) / double(value_length);
         result_g_channel[i] = MathIsValidNumber((temp_upper_band[i] + temp_lower_band[i]) / 2.0) ? (temp_upper_band[i] + temp_lower_band[i]) / 2.0 : source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Guassian Weighted Moving Average (GWMA)                          |
//+------------------------------------------------------------------+
int maGuassianWeighted(const int rates_total,
                       const int prev_calculated,
                       const int value_length, // min val: 1; step val: 1; default val: 10
                       const double &source_price[],
                       double &result_gwma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_gwma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = double(value_length) - pow(1.0 - ((2.0 * k) / double(value_length)), 2.0) * (3.0 / 2.0);
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_gwma[i] = sum_weight_price / sum_weight;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Henderson Weighted Moving Average (HWMA)                         |
//+------------------------------------------------------------------+
int maHendersonWeighted(const int rates_total,
                        const int prev_calculated,
                        const int value_length, // min val: 1; step val: 1; default val: 10
                        const double &source_price[],
                        double &result_hwma[])
  {
//--- bar index start
   int bar_index;
   double multiplier = floor(double(value_length - 1) / 2.0);
   double mp2 = multiplier + 2.0;
   double mp2_sq = mp2 * mp2;
   double four_mp2_sq = 4.0 * mp2_sq;
   double denominator = 8.0 * mp2 * (mp2_sq - 1.0) * (four_mp2_sq - 1.0) * (four_mp2_sq - 9.0) * (four_mp2_sq - 25.0);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_hwma[i] = source_price[i];
      else
        {
         double numerator = 0.0, weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         double mp1_sq = (multiplier + 1.0) * (multiplier + 1.0);
         double mp3_sq = (multiplier + 3.0) * (multiplier + 3.0);
         for(int k = 0; k < value_length; k++)
           {
            double km = k - multiplier;
            double km_sq = km * km;
            numerator = 315.0 * (mp1_sq - km_sq) * (mp2_sq - km_sq) * (mp3_sq - km_sq) * (3.0 * mp2_sq - 11.0 * km_sq - 16.0);
            weight = denominator == 0.0 ? 0.0 : numerator / denominator;
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_hwma[i] = (sum_weight != 0) ? sum_weight_price / sum_weight : source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Hull Moving Average (HMA)                                        |
//+------------------------------------------------------------------+
int maHull(const int rates_total,
           const int prev_calculated,
           const int value_length, // min val: 1; step val: 1; default val: 10
           const double &source_price[],
           double &temp_wma_1[],
           double &temp_wma_2[],
           double &result_hma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
        {
         temp_wma_1[i] = source_price[i];
         temp_wma_2[i] = source_price[i];
         result_hma[i] = source_price[i];
        }
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < int(floor(double(value_length) / 2.0)); k++)
           {
            weight = int(floor(double(value_length) / 2.0)) - k;
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         temp_wma_1[i] = sum_weight_price / sum_weight;
         weight = 0.0;
         sum_weight = 0.0;
         sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = value_length - k;
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         temp_wma_2[i] = sum_weight_price / sum_weight;
         weight = 0.0;
         sum_weight = 0.0;
         sum_weight_price = 0.0;
         for(int k = 0; k < int(floor(sqrt(value_length))); k++)
           {
            weight = int(floor(sqrt(value_length))) - k;
            sum_weight += weight;
            sum_weight_price += weight * (2 * temp_wma_1[i - k] - temp_wma_2[i - k]);
           }
         result_hma[i] = value_length == 1 ? source_price[i] : sum_weight_price / sum_weight;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Integral of Linear Regression Slope + Endpoint Moving Average / 2 (IE2) |
//+------------------------------------------------------------------+
int maIntegralEndpoint2(const int rates_total,
                        const int prev_calculated,
                        const int value_length, // min val: 1; step val: 1; default val: 10
                        const double &source_price[],
                        double &temp_lsma[],
                        double &result_ie2[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
        {
         temp_lsma[i] = source_price[i];
         result_ie2[i] = source_price[i];
        }
      else
        {
         double sumx = 0.0, sumy = 0.0, sumxy = 0.0, sumxx = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            sumx += (i - k);
            sumy += source_price[i - k];
            sumxy += (i - k) * source_price[i - k];
            sumxx += (i - k) * (i - k);
           }
         double lsma_denom = double(value_length) * sumxx - sumx * sumx;
         double slope = (lsma_denom != 0) ? (double(value_length) * sumxy - sumx * sumy) / lsma_denom : 0;
         double intercept = (sumy / double(value_length)) - slope * (sumx / double(value_length));
         temp_lsma[i] = slope * i + intercept;
         double sma = sumy / double(value_length);
         double m = temp_lsma[i] - temp_lsma[i - 1] + sma;
         result_ie2[i] = (m + temp_lsma[i]) / 2.0;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Jurik Filter (JF)                                                |
//+------------------------------------------------------------------+
int filJurik(const int rates_total,
             const int prev_calculated,
             const int value_length, // min val: 1; step val: 1; default val: 10
             const int value_phase, // min val: -100; max val: 100; step val: 1; default val: 0
             const double &source_price[],
             double &temp_bsmax[],
             double &temp_bsmin[],
             double &temp_volty[],
             double &temp_vsum[],
             double &temp_avolty[],
             double &temp_ma1[],
             double &temp_det0[],
             double &temp_e2[],
             double &result_jf[])
  {
//--- bar index start
   int bar_index;
   double len1 = fmax(log(sqrt(0.5 * (double(value_length) - 1.0))) / log(2.0) + 2.0, 0.0);
   double len2 = sqrt(0.5 * (double(value_length) - 1.0)) * len1;
   double pow1 = fmax(len1 - 2.0, 0.5);
   double beta = 0.45 * (double(value_length) - 1.0) / (0.45 * (double(value_length) - 1.0) + 2.0);
   double div = 1.0 / (10.0 + 10.0 * (fmin(fmax(double(value_length) - 10.0, 0.0), 100.0)) / 100.0);
   double phaseRatio = value_phase < -100 ? 0.5 : value_phase > 100 ? 2.5 : 1.5 + double(value_phase) * 0.01;
   double bet = len2 / (len2 + 1.0);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 10)
        {
         temp_bsmax[i] = source_price[i];
         temp_bsmin[i] = source_price[i];
         temp_volty[i] = 0.0;
         temp_vsum[i] = 0.0;
         temp_avolty[i] = 0.0;
         temp_ma1[i] = 0.0;
         temp_det0[i] = 0.0;
         temp_e2[i] = 0.0;
         result_jf[i] = source_price[i];
        }
      else
        {
         //--- price volatility
         double del1 = source_price[i] - temp_bsmax[i - 1];
         double del2 = source_price[i] - temp_bsmin[i - 1];
         temp_volty[i] = fabs(del1) > fabs(del2) ? fabs(del1) : fabs(del2);
         //--- relative price volatility factor
         temp_vsum[i] = temp_vsum[i - 1] + div * (temp_volty[i] - temp_volty[i - 10]);
         temp_avolty[i] = temp_avolty[i - 1] + (2.0 / (fmax(4.0 * double(value_length), 30.0) + 1.0)) * (temp_vsum[i] - temp_avolty[i - 1]);
         double dVolty = temp_avolty[i] > 0.0 ? temp_volty[i] / temp_avolty[i] : 0.0;
         dVolty = fmax(1.0, fmin(pow(len1, 1.0 / pow1), dVolty));
         //--- jurik volatility bands
         double pow2 = pow(dVolty, pow1);
         double Kv = pow(bet, sqrt(pow2));
         temp_bsmax[i] = del1 > 0.0 ? source_price[i] : source_price[i] - Kv * del1;
         temp_bsmin[i] = del2 < 0.0 ? source_price[i] : source_price[i] - Kv * del2;
         //--- jurik dynamic factor
         double alpha = pow(beta, pow2);
         //--- 1st stage - prelimimary smoothing by adaptive EMA
         temp_ma1[i] = (1.0 - alpha) * source_price[i] + alpha * temp_ma1[i - 1];
         //--- 2nd stage - one more prelimimary smoothing by kalman filter
         temp_det0[i] = (source_price[i] - temp_ma1[i]) * (1.0 - beta) + beta * temp_det0[i - 1];
         double ma2 = temp_ma1[i] + phaseRatio * temp_det0[i];
         //--- 3rd stage - final smoothing by unique jurik adaptive filter
         temp_e2[i] = (ma2 - result_jf[i - 1]) * pow(1.0 - alpha, 2.0) + pow(alpha, 2.0) * temp_e2[i - 1];
         result_jf[i] = temp_e2[i] + result_jf[i - 1];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Kalman Filter (KF)                                               |
//+------------------------------------------------------------------+
int filKalman(const int rates_total,
              const int prev_calculated,
              const int value_k, // min val: 1; max val: 2000; step val: 1; default val: 1500
              const double &source_price[],
              double &temp_velocity[],
              double &result_kf[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
        {
         temp_velocity[i] = 0.0;
         result_kf[i] = source_price[i];
        }
      else
        {
         double distance = source_price[i] - result_kf[i - 1];
         double error = result_kf[i - 1] + distance * sqrt((double(2001 - value_k) / 10000.0) * 2.0);
         temp_velocity[i] = temp_velocity[i - 1] + (distance * double(2001 - value_k) / 10000.0);
         result_kf[i] = error + temp_velocity[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Kaufman Adaptive Moving Average (KAMA)                           |
//+------------------------------------------------------------------+
int maKaufmanAdaptive(const int rates_total,
                      const int prev_calculated,
                      const int value_length, // min val: 1; step val: 1; default val: 10
                      const double &source_price[],
                      double &result_kama[])
  {
//--- bar index start
   int bar_index;
   double fast = 0.666, slow = 0.0645;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_kama[i] = source_price[i];
      else
        {
         double noise = 0.0;
         for(int k = 0; k < value_length; k++)
            noise += fabs(source_price[i - k] - source_price[i - k - 1]);
         double signal = fabs(source_price[i] - source_price[i - value_length]);
         double eff_ratio = noise != 0.0 ? signal / noise : 0.0;
         double smooth = pow(eff_ratio * (fast - slow) + slow, 2.0);
         result_kama[i] = result_kama[i - 1] + smooth * (source_price[i] - result_kama[i - 1]);
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Kijun Line aka Base Line or Kijun-sen (KIJUN)                    |
//+------------------------------------------------------------------+
int maKijunLine(const int rates_total,
                const int prev_calculated,
                const int value_length, // min val: 1; step val: 1; default val: 26
                const double &source_price[],
                double &result_kijun[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_kijun[i] = source_price[i];
      else
        {
         double max_price = -DBL_MAX, min_price = DBL_MAX;
         for(int k = 0; k < value_length; k++)
           {
            max_price = source_price[i - k] > max_price ? source_price[i - k] : max_price;
            min_price = source_price[i - k] < min_price ? source_price[i - k] : min_price;
           }
         result_kijun[i] = (max_price + min_price) * 0.5;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Least Squares Moving Average (LSMA)                              |
//+------------------------------------------------------------------+
int maLeastSquares(const int rates_total,
                   const int prev_calculated,
                   const int value_length, // min val: 1; step val: 1; default val: 10
                   const double &source_price[],
                   double &result_lsma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_lsma[i] = source_price[i];
      else
        {
         double sumx = 0.0, sumy = 0.0, sumxy = 0.0, sumxx = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            sumx += (i - k);
            sumy += source_price[i - k];
            sumxy += (i - k) * source_price[i - k];
            sumxx += (i - k) * (i - k);
           }
         double lsma_denom = double(value_length) * sumxx - sumx * sumx;
         double slope = (lsma_denom != 0) ? (double(value_length) * sumxy - sumx * sumy) / lsma_denom : 0;
         double intercept = (sumy / double(value_length)) - slope * (sumx / double(value_length));
         result_lsma[i] = slope * i + intercept;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Leo Moving Average (LMA)                                         |
//+------------------------------------------------------------------+
int maLeo(const int rates_total,
          const int prev_calculated,
          const int value_length, // min val: 1; step val: 1; default val: 10
          const double &source_price[],
          double &result_lma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_lma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0, sum_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = double(value_length - k);
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
            sum_price += source_price[i - k];
           }
         double lwma = sum_weight_price / sum_weight;
         double sma = sum_price / double(value_length);
         result_lma[i] = 2.0 * lwma - sma;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Linear Weighted Moving Average (LWMA)                            |
//+------------------------------------------------------------------+
int maLinearWeighted(const int rates_total,
                     const int prev_calculated,
                     const int value_length, // min val: 1; step val: 1; default val: 10
                     const double &source_price[],
                     double &result_lwma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_lwma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = double(value_length - k);
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_lwma[i] = sum_weight_price / sum_weight;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Moving Median (MEDIAN)                                           |
//+------------------------------------------------------------------+
int maMovingMedian(const int rates_total,
                   const int prev_calculated,
                   const int value_length, // min val: 3; step val: 1; default val: 10
                   const double &source_price[],
                   double &result_median[])
  {
//--- bar index start
   int bar_index;
   double temp_place_holder[];
   ArrayResize(temp_place_holder, value_length);
   ArrayInitialize(temp_place_holder, 0.0);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_median[i] = source_price[i];
      else
        {
         double val = 0.0;
         for(int k = 0; k < value_length; k++)
            temp_place_holder[k] = source_price[i - k];
         ArraySort(temp_place_holder);
         int position = 0;
         if(fmod(double(value_length), 2.0) == 0.0)
           {
            position = (value_length / 2) - 1;
            result_median[i] = (temp_place_holder[position] + temp_place_holder[position + 1]) / 2.0;
           }
         else
           {
            position = int(ceil(double(value_length) / 2.0)) - 1;
            result_median[i] = temp_place_holder[position];
           }
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Parabolic Weighted Moving Average (PWMA)                         |
//+------------------------------------------------------------------+
int maParabolicWeighted(const int rates_total,
                        const int prev_calculated,
                        const int value_length, // min val: 1; step val: 1; default val: 10
                        const double value_power, // min val: 1.0; step val: 0.01; default val: 2.0
                        const double &source_price[],
                        double &result_pwma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_pwma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = pow(double(value_length - k), value_power);
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_pwma[i] = sum_weight_price / sum_weight;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Pivot Point Weighted Moving Average (PPWMA)                      |
//+------------------------------------------------------------------+
int maPivotPointWeighted(const int rates_total,
                         const int prev_calculated,
                         const int value_length, // min val: 1; step val: 1; default val: 10
                         const double &source_price[],
                         double &result_ppwma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_ppwma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = 3.0 * (double(value_length) - k) - double(value_length) - 1.0;
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_ppwma[i] = (sum_weight != 0) ? sum_weight_price / sum_weight : source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Relative Moving Average aka Smoothed Moving Average (RMA)        |
//+------------------------------------------------------------------+
int maRelative(const int rates_total,
               const int prev_calculated,
               const int value_length, // min val: 1; step val: 1; default val: 10
               const double &source_price[],
               double &result_rma[])
  {
//--- bar index start
   int bar_index;
   double alpha = 1.0 / double(value_length);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
         result_rma[i] = source_price[i];
      else
         result_rma[i] = source_price[i] * alpha + result_rma[i - 1] * (1.0 - alpha);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Simple Moving Average (SMA)                                      |
//+------------------------------------------------------------------+
int maSimple(const int rates_total,
             const int prev_calculated,
             const int value_length, // min val: 1; step val: 1; default val: 10
             const double &source_price[],
             double &result_sma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_sma[i] = source_price[i];
      else
        {
         double sum = 0.0;
         for(int k = 0; k < value_length; k++)
            sum += source_price[i - k];
         result_sma[i] = sum / double(value_length);
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Sine Weighted Moving Average (SWMA)                              |
//+------------------------------------------------------------------+
int maSineWeighted(const int rates_total,
                   const int prev_calculated,
                   const int value_length, // min val: 1; step val: 1; default val: 10
                   const double &source_price[],
                   double &result_swma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_swma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = sin((k + 1) * M_PI / (double(value_length) + 1.0));
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_swma[i] = sum_weight_price / sum_weight;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Smoothed Moving Average aka Rolling Moving Average (SMMA)        |
//+------------------------------------------------------------------+
int maSmoothed(const int rates_total,
               const int prev_calculated,
               const int value_length, // min val: 1; step val: 1; default val: 10
               const double &source_price[],
               double &result_smma[])

  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_smma[i] = source_price[i];
      else
         if(i == value_length)
           {
            double sum = 0.0;
            for(int k = 0; k < value_length; k++)
               sum += source_price[i - k];
            result_smma[i] = sum / double(value_length);
           }
         else
            result_smma[i] = (result_smma[i - 1] * (double(value_length) - 1.0) + source_price[i]) / double(value_length);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| T3 Moving Average (T3MA)                                         |
//+------------------------------------------------------------------+
int maT3(const int rates_total,
         const int prev_calculated,
         const int value_length, // min val: 1; step val: 1; default val: 10
         const double value_volume_factor, // min val: 0.0; max val: 2.0; step val: 0.01; default val: 0.7
         const double &source_price[],
         double &temp_e1[],
         double &temp_e2[],
         double &temp_e3[],
         double &temp_e4[],
         double &temp_e5[],
         double &temp_e6[],
         double &result_t3ma[])
  {
//--- bar index start
   int bar_index;
   double alpha = 2.0 / (1.0 + double(value_length));
   double c1 = -pow(value_volume_factor, 3.0);
   double c2 = 3.0 * pow(value_volume_factor, 2.0) + 3.0 * pow(value_volume_factor, 3.0);
   double c3 = -6.0 * pow(value_volume_factor, 2.0) - 3.0 * value_volume_factor - 3.0 * pow(value_volume_factor, 3.0);
   double c4 = 1.0 + 3.0 * value_volume_factor + pow(value_volume_factor, 3.0) + 3.0 * pow(value_volume_factor, 2.0);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
        {
         temp_e1[i] = source_price[i];
         temp_e2[i] = source_price[i];
         temp_e3[i] = source_price[i];
         temp_e4[i] = source_price[i];
         temp_e5[i] = source_price[i];
         temp_e6[i] = source_price[i];
         result_t3ma[i] = source_price[i];
        }
      else
        {
         temp_e1[i] = source_price[i] * alpha + temp_e1[i - 1] * (1.0 - alpha);
         temp_e2[i] = temp_e1[i] * alpha + temp_e2[i - 1] * (1.0 - alpha);
         temp_e3[i] = temp_e2[i] * alpha + temp_e3[i - 1] * (1.0 - alpha);
         temp_e4[i] = temp_e3[i] * alpha + temp_e4[i - 1] * (1.0 - alpha);
         temp_e5[i] = temp_e4[i] * alpha + temp_e5[i - 1] * (1.0 - alpha);
         temp_e6[i] = temp_e5[i] * alpha + temp_e6[i - 1] * (1.0 - alpha);
         result_t3ma[i] = c1 * temp_e6[i] + c2 * temp_e5[i] + c3 * temp_e4[i] + c4 * temp_e3[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Triangular Weighted Moving Average (TWMA)                        |
//+------------------------------------------------------------------+
int maTriangularWeighted(const int rates_total,
                         const int prev_calculated,
                         const int value_length, // min val: 1; step val: 1; default val: 10
                         const double &source_price[],
                         double &result_twma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_twma[i] = source_price[i];
      else
        {
         double weight = 0.0, sum_weight = 0.0, sum_weight_price = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            weight = k < double(value_length) / 2.0 ? double(k + 1) : k == double(value_length) / 2.0 ? double(k) : (double(value_length) / 2.0) - (k - (double(value_length) / 2.0));
            sum_weight += weight;
            sum_weight_price += weight * source_price[i - k];
           }
         result_twma[i] = sum_weight_price / sum_weight;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Triple Exponential Moving Average (TEMA)                         |
//+------------------------------------------------------------------+
int maTripleExponential(const int rates_total,
                        const int prev_calculated,
                        const int value_length, // min val: 1; step val: 1; default val: 10
                        const double &source_price[],
                        double &temp_ema1[],
                        double &temp_ema2[],
                        double &temp_ema3[],
                        double &result_tema[])
  {
//--- bar index start
   int bar_index;
   double alpha = 2.0 / (1.0 + double(value_length));
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
        {
         temp_ema1[i] = source_price[i];
         temp_ema2[i] = source_price[i];
         temp_ema3[i] = source_price[i];
         result_tema[i] = source_price[i];
        }
      else
        {
         temp_ema1[i] = source_price[i] * alpha + temp_ema1[i - 1] * (1.0 - alpha);
         temp_ema2[i] = temp_ema1[i] * alpha + temp_ema2[i - 1] * (1.0 - alpha);
         temp_ema3[i] = temp_ema2[i] * alpha + temp_ema3[i - 1] * (1.0 - alpha);
         result_tema[i] = 3.0 * temp_ema1[i] - 3.0 * temp_ema2[i] + temp_ema3[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Volume Weighted Moving Average (VWMA)                            |
//+------------------------------------------------------------------+
int maVolumeWeighted(const int rates_total,
                     const int prev_calculated,
                     const int value_length, // min val: 1; step val: 1; default val: 10
                     const double &source_price[],
                     const long &source_volume[],
                     double &result_vwma[])
  {
//--- bar index start
   int bar_index;
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < value_length)
         result_vwma[i] = source_price[i];
      else
        {
         double sma_price_volume = 0.0, sma_volume = 0.0, sum_price_volume = 0.0, sum_volume = 0.0;
         for(int k = 0; k < value_length; k++)
           {
            sum_price_volume += source_price[i - k] * double(source_volume[i - k]);
            sum_volume += double(source_volume[i - k]);
           }
         sma_price_volume = sum_price_volume / double(value_length);
         sma_volume = sum_volume / double(value_length);
         result_vwma[i] = (sma_volume != 0) ? sma_price_volume / sma_volume : source_price[i];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Zero Lag Indicator (ZLI)                                         |
//+------------------------------------------------------------------+
int maZeroLagIndicator(const int rates_total,
                       const int prev_calculated,
                       const int value_length, // min val: 1; step val: 1; default val: 20
                       const int value_gain_limit, // min val: 1; step val: 1; default val: 50
                       const double &source_price[],
                       double &temp_ema[],
                       double &result_zli[])
  {
//--- bar index start
   int bar_index;
   double alpha = 2.0 / (1.0 + double(value_length));
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      if(i < 1)
        {
         temp_ema[i] = source_price[i];
         result_zli[i] = source_price[i];
        }
      else
        {
         temp_ema[i] = alpha * source_price[i] + (1.0 - alpha) * temp_ema[i - 1];
         double gain = 0.0, error = 0.0, least_error = DBL_MAX, best_gain = 0.0;
         for(int k = -value_gain_limit; k <= value_gain_limit; k++)
           {
            gain = double(k) / 10.0;
            result_zli[i] = alpha * (temp_ema[i] + gain * (source_price[i] - result_zli[i - 1])) + (1.0 - alpha) * result_zli[i - 1];
            error = source_price[i] - result_zli[i];
            if(fabs(error) < least_error)
              {
               least_error = fabs(error);
               best_gain = gain;
              }
           }
         result_zli[i] = alpha * (temp_ema[i] + best_gain * (source_price[i] - result_zli[i - 1])) + (1.0 - alpha) * result_zli[i - 1];
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Average True Range (ATR)                                         |
//+------------------------------------------------------------------+
int inAverageTrueRange(const int rates_total,
                       const int prev_calculated,
                       const int value_length,
                       const double &source_high[],
                       const double &source_low[],
                       const double &source_close[],
                       double &result_atr[])
  {
//--- bar index start
   int bar_index;
   double alpha = 1.0 / double(value_length);
   if(prev_calculated == 0)
      bar_index = 0;
   else
      bar_index = prev_calculated - 1;
//--- main loop
   for(int i = bar_index; i < rates_total && !_StopFlag; i++)
     {
      double true_range = i < 1 ? source_high[i] - source_low[i] : fmax(source_high[i] - source_low[i], fmax(fabs(source_high[i] - source_close[i - 1]), fabs(source_low[i] - source_close[i - 1])));
      if(i < 1)
         result_atr[i] = true_range;
      else
         result_atr[i] = true_range * alpha + result_atr[i - 1] * (1.0 - alpha);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
