/**=             EhlersCommon.mqh  (Shared Ehlers Indicator Utilities)
 *               Original algorithms: Copyright 2013, John F. Ehlers
 *               MQL5 conversion: thetestspecimen (https://github.com/thetestspecimen)
 *               Refactored shared library: TyphooN (https://www.marketwizardry.org/)
 *
 * Licence: GNU General Public License v3
 **/
#ifndef _EHLERS_COMMON_MQH_
#define _EHLERS_COMMON_MQH_

#define EHLERS_PI 3.14159265358979323846264338327950288
#define EHLERS_SQRT2 1.41421356237309504880168872420969808

// ── Price Type Enum ─────────────────────────────────────────────────────────
enum enPrices {
    pr_close,          // Close
    pr_open,           // Open
    pr_high,           // High
    pr_low,            // Low
    pr_median,         // Median
    pr_typical,        // Typical
    pr_weighted,       // Weighted
    pr_average,        // Average (high+low+open+close)/4
    pr_medianbody,     // Average median body (open+close)/2
    pr_trendbiased,    // Trend biased price
    pr_ha_close,       // Heiken ashi close
    pr_ha_open,        // Heiken ashi open
    pr_ha_high,        // Heiken ashi high
    pr_ha_low,         // Heiken ashi low
    pr_ha_median,      // Heiken ashi median
    pr_ha_typical,     // Heiken ashi typical
    pr_ha_weighted,    // Heiken ashi weighted
    pr_ha_average,     // Heiken ashi average
    pr_ha_medianbody,  // Heiken ashi median body
    pr_ha_trendbiased  // Heiken ashi trend biased price
};

// ── Heiken Ashi Work Array ──────────────────────────────────────────────────
double g_workHa[][4];

// ── Price Selection ─────────────────────────────────────────────────────────
double getPrice(int priceType, const double &open[], const double &close[],
                const double &high[], const double &low[], int i, int bars)
{
   if (priceType >= pr_ha_close)
   {
      if (ArrayRange(g_workHa, 0) != bars)
         ArrayResize(g_workHa, bars);

      double haOpen = (i > 0) ? (g_workHa[i-1][2] + g_workHa[i-1][3]) / 2.0
                               : (open[i] + close[i]) / 2.0;
      double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
      double haHigh  = MathMax(high[i], MathMax(haOpen, haClose));
      double haLow   = MathMin(low[i],  MathMin(haOpen, haClose));

      g_workHa[i][0] = haLow;
      g_workHa[i][1] = haHigh;
      g_workHa[i][2] = haOpen;
      g_workHa[i][3] = haClose;

      switch (priceType)
      {
         case pr_ha_close:       return haClose;
         case pr_ha_open:        return haOpen;
         case pr_ha_high:        return haHigh;
         case pr_ha_low:         return haLow;
         case pr_ha_median:      return (haHigh + haLow) / 2.0;
         case pr_ha_medianbody:  return (haOpen + haClose) / 2.0;
         case pr_ha_typical:     return (haHigh + haLow + haClose) / 3.0;
         case pr_ha_weighted:    return (haHigh + haLow + haClose + haClose) / 4.0;
         case pr_ha_average:     return (haHigh + haLow + haClose + haOpen) / 4.0;
         case pr_ha_trendbiased: return (haClose > haOpen) ? (haHigh + haClose) / 2.0
                                                           : (haLow  + haClose) / 2.0;
      }
   }
   else
   {
      switch (priceType)
      {
         case pr_close:      return close[i];
         case pr_open:       return open[i];
         case pr_high:       return high[i];
         case pr_low:        return low[i];
         case pr_median:     return (high[i] + low[i]) / 2.0;
         case pr_medianbody: return (open[i] + close[i]) / 2.0;
         case pr_typical:    return (high[i] + low[i] + close[i]) / 3.0;
         case pr_weighted:   return (high[i] + low[i] + close[i] + close[i]) / 4.0;
         case pr_average:    return (high[i] + low[i] + close[i] + open[i]) / 4.0;
         case pr_trendbiased: return (close[i] > open[i]) ? (high[i] + close[i]) / 2.0
                                                           : (low[i]  + close[i]) / 2.0;
      }
   }
   return 0;
}

// ── High Pass Filter (2-pole Butterworth) ───────────────────────────────────
// Coefficients struct for caching in OnInit
struct EhlersHPCoeffs
{
   double alpha1;
   double oneMinusAlphaHalf2; // (1 - alpha1/2)^2
   double twoOneMinusAlpha;   // 2*(1 - alpha1)
   double oneMinusAlpha2;     // (1 - alpha1)^2
};

void ComputeHPCoeffs(int period, EhlersHPCoeffs &c)
{
   double ang = EHLERS_SQRT2 * EHLERS_PI / period;
   c.alpha1 = (MathCos(ang) + MathSin(ang) - 1.0) / MathCos(ang);
   c.oneMinusAlphaHalf2 = (1.0 - c.alpha1 / 2.0) * (1.0 - c.alpha1 / 2.0);
   c.twoOneMinusAlpha   = 2.0 * (1.0 - c.alpha1);
   c.oneMinusAlpha2     = (1.0 - c.alpha1) * (1.0 - c.alpha1);
}

double HighPass(const EhlersHPCoeffs &c, const double &in[], const double &out[], int i)
{
   if (i < 3)
      return c.oneMinusAlphaHalf2 * in[i];
   return c.oneMinusAlphaHalf2 * (in[i] - 2.0 * in[i-1] + in[i-2])
          + c.twoOneMinusAlpha * out[i-1]
          - c.oneMinusAlpha2 * out[i-2];
}

// ── Low Pass Filter (Supersmoother) ─────────────────────────────────────────
struct EhlersLPCoeffs
{
   double c1, c2, c3;
};

void ComputeLPCoeffs(int period, EhlersLPCoeffs &c)
{
   double a1 = MathExp(-EHLERS_SQRT2 * EHLERS_PI / period);
   double b1 = 2.0 * a1 * MathCos(EHLERS_SQRT2 * EHLERS_PI / period);
   c.c2 = b1;
   c.c3 = -a1 * a1;
   c.c1 = 1.0 - c.c2 - c.c3;
}

double LowPass(const EhlersLPCoeffs &c, const double &in[], const double &out[], int i)
{
   if (i < 3)
      return c.c1 * in[i];
   return c.c1 * (in[i] + in[i-1]) / 2.0 + c.c2 * out[i-1] + c.c3 * out[i-2];
}

// ── Dominant Cycle Detection (Pearson + DFT + AGC) ──────────────────────────
struct DominantCycleState
{
   double corr[];
   double sqSum[];
   double r[][2];
   double pwr[];
   double maxPwr;
   int    lpPeriod;
   int    hpPeriod;
};

void InitDominantCycle(DominantCycleState &s, int lp, int hp)
{
   s.lpPeriod = lp;
   s.hpPeriod = hp;
   s.maxPwr   = 0;
   ArrayResize(s.corr,  hp + 1);
   ArrayResize(s.sqSum, hp + 1);
   ArrayResize(s.r,     hp + 1);
   ArrayResize(s.pwr,   hp + 1);
   ArrayInitialize(s.corr,  0);
   ArrayInitialize(s.sqSum, 0);
   ArrayInitialize(s.pwr,   0);
   // Zero out the 2D array
   for (int j = 0; j <= hp; j++) { s.r[j][0] = 0; s.r[j][1] = 0; }
}

double ComputeDominantCycle(DominantCycleState &s, const double &filt[], int i, int avgLength)
{
   int lp = s.lpPeriod;
   int hp = s.hpPeriod;
   int avLen = (avgLength == 0) ? hp : avgLength;

   // Pearson correlation
   if (i > hp + 1 + avLen)
   {
      for (int lag = 0; lag <= hp; lag++)
      {
         double m = (avgLength == 0) ? (double)lag : (double)avgLength;
         double Sx=0, Sy=0, Sxx=0, Syy=0, Sxy=0;
         for (int c = 0; c < (int)m; c++)
         {
            double X = filt[i - c];
            double Y = filt[i - lag - c];
            Sx  += X;     Sy  += Y;
            Sxx += X * X; Sxy += X * Y;
            Syy += Y * Y;
         }
         double denom = (m * Sxx - Sx * Sx) * (m * Syy - Sy * Sy);
         if (denom > 0)
            s.corr[lag] = (m * Sxy - Sx * Sy) / MathSqrt(denom);
      }
   }

   // DFT
   for (int period = lp; period <= hp; period++)
   {
      double cosPart = 0, sinPart = 0;
      for (int n = 3; n <= hp; n++)
      {
         double ang = 2.0 * EHLERS_PI * n / period;
         cosPart += s.corr[n] * MathCos(ang);
         sinPart += s.corr[n] * MathSin(ang);
      }
      s.sqSum[period] = cosPart * cosPart + sinPart * sinPart;
   }

   // EMA smoothing
   for (int period = lp; period <= hp; period++)
   {
      s.r[period][1] = s.r[period][0];
      s.r[period][0] = 0.2 * s.sqSum[period] * s.sqSum[period] + 0.8 * s.r[period][1];
   }

   // AGC
   s.maxPwr *= 0.991;
   for (int period = lp; period <= hp; period++)
      if (s.r[period][0] > s.maxPwr) s.maxPwr = s.r[period][0];

   if (s.maxPwr != 0)
      for (int p = 3; p <= hp; p++) s.pwr[p] = s.r[p][0] / s.maxPwr;
   else
      for (int p = 3; p <= hp; p++) s.pwr[p] = 0;

   // CG of spectrum
   double Spx = 0, Sp = 0;
   for (int period = lp; period <= hp; period++)
   {
      if (s.pwr[period] >= 0.5)
      {
         Spx += period * s.pwr[period];
         Sp  += s.pwr[period];
      }
   }

   double domCycle = (Sp != 0) ? Spx / Sp : 0;
   if (domCycle < lp) domCycle = lp;
   if (domCycle > hp) domCycle = hp;
   return domCycle;
}

#endif // _EHLERS_COMMON_MQH_
