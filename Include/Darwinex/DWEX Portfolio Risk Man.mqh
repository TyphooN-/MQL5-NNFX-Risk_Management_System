//+--------------------------------------------------------------------------------+
//| DWEX Portfolio Risk Man.mqh                                                    |
//|                                                                                |
//| THIS CODE IS PROVIDED FOR ILLUSTRATIVE PURPOSES ONLY. ALWAYS THOUROUGHLY TEST  |
//| ANY CODE BEFORE THEN ADAPTING TO YOUR OWN PERSONAL RISK OBJECTIVES AND RISK    |
//| APPETITE.                                                                      |
//|                                                                                |
//| DISCLAIMER AND TERMS OF USE OF THIS CODE                                       |
//| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"    |
//| AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE      |
//| IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE |
//| DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE   |
//| FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL     |
//| DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR     |
//| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER     |
//| CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  |
//| OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  |
//| OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.           |
//|                                                                                |
//+--------------------------------------------------------------------------------+

//+--------------------------------------------------------------------------------+
//| THIS CODE EXAMPLE IS SUPPLIED AS PART OF THE FOLLOWING YOUTUBE SERIES TITLED   | 
//| 'INSTITUTIONAL-GRADE RISK MANAGEMENT TECHNIQUES':                              |
//|                                                                                |
//| https://www.youtube.com/playlist?list=PLv-cA-4O3y979Ltr9wQ2lRJu1INve3RCM       |
//+--------------------------------------------------------------------------------+

#property copyright     "Copyright 2022, Darwinex / TyphooN (v1.01+)"
#property link          "https://www.darwinex.com"
#property description   "Portfolio Risk Management Module"
#property version       "1.06"
#property strict

class CPortfolioRiskMan
{
public:
    double SinglePositionVaR;
    void CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTimeframe, int StdDevPeriods, double ConfidenceLevel = 0.95); //CONSTRUCTOR
   ~CPortfolioRiskMan() { ClearCache(); }
    bool CalculateVaR(string Asset, double AssetPosSize);
    bool CalculateLotSizeBasedOnVaR(string Asset, double confidenceLevel, double accountEquity, double VaRPercent, double &lotSize);
    void ReserveCache(int size);
    void ClearCache();

private:
    ENUM_TIMEFRAMES ValueAtRiskTimeframe;
    int StandardDeviationPeriods;
    double VaRConfidenceLevel;
    double m_stdDevReturnsCache[];
    string m_symbolCache[];
    datetime m_cacheTimestamp[];
    int    m_cacheCount;
    // Reusable work arrays — avoid heap alloc/free per symbol
    double m_returns[];
    double m_dailyReturns[];

    bool GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns);
    double InverseCumulativeNormal(double p);
    double StdDev(const double &arr[], int count);
};
//CONSTRUCTOR
void CPortfolioRiskMan::CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTF, int SDPeriods, double ConfidenceLevel)
{
   ValueAtRiskTimeframe     = VaRTF;
   StandardDeviationPeriods = SDPeriods;
   VaRConfidenceLevel       = ConfidenceLevel;
   m_cacheCount             = 0;
   // Pre-allocate work arrays to avoid per-call heap churn
   ArrayResize(m_returns, SDPeriods + 1);
   ArrayResize(m_dailyReturns, SDPeriods);
}
void CPortfolioRiskMan::ClearCache()
{
   ArrayFree(m_stdDevReturnsCache);
   ArrayFree(m_symbolCache);
   ArrayFree(m_cacheTimestamp);
   ArrayFree(m_returns);
   ArrayFree(m_dailyReturns);
   m_cacheCount = 0;
}
void CPortfolioRiskMan::ReserveCache(int size)
{
   ArrayResize(m_symbolCache, size);
   ArrayResize(m_stdDevReturnsCache, size);
   ArrayResize(m_cacheTimestamp, size);
   m_cacheCount = 0;
}
// Inline StdDev — avoids #include <Math\Stat\Math.mqh> (heavy)
double CPortfolioRiskMan::StdDev(const double &arr[], int count)
{
   if (count < 2) return 0;
   double sum = 0, sumSq = 0;
   for (int i = 0; i < count; i++)
   {
      sum   += arr[i];
      sumSq += arr[i] * arr[i];
   }
   double mean = sum / count;
   double variance = (sumSq / count) - (mean * mean);
   return (variance > 0) ? MathSqrt(variance) : 0;
}
bool CPortfolioRiskMan::CalculateVaR(string Asset, double AssetPosSize) //N.B. ProposedPosSize should be +ve for a LONG pos and -ve for a SHORT pos                 
{  
   //CALCULATE STD DEV OF RETURNS FOR POSITION
   double stdDevReturns;
   if(!GetAssetStdDevReturns(Asset, stdDevReturns)) //2nd param passed by ref
   {
      Print("Error calculating Std Dev of Returns for " + Asset + " in: " + __FUNCTION__ + "()");
      return false;
   }
   //GET NOMINAL VALUE FOR PROPOSED POSITION
   //TODO: THIS ASSUMES ALL ASSETS CALCULATED USING ACCOUNT CURRENCY. FOR OTHERS E.G. SPX500 NEED TO DO CURRENCY CONVERSION
   double tickSize = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_SIZE);
   if (tickSize <= 0) { return false; }
   double nominalValuePerUnitPerLot = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_VALUE) / tickSize;
   if (nominalValuePerUnitPerLot <= 0) return false;
   double closePrice = SymbolInfoDouble(Asset, SYMBOL_BID);
   if (closePrice <= 0) return false;
   double nominalValue              = MathAbs(AssetPosSize) * nominalValuePerUnitPerLot * closePrice;
   //CALCULATE THE VaR VALUES FOR THIS IND PROPOSED POSITION
   double zScore = InverseCumulativeNormal(VaRConfidenceLevel);
   if(zScore == 0) return false;
   SinglePositionVaR = zScore * stdDevReturns * nominalValue; //nominalValue is always +ve because of MathAbs(AssetPosSize) above
   return true;
}
bool CPortfolioRiskMan::CalculateLotSizeBasedOnVaR(string Asset, double confidenceLevel, double accountEquity, double VaRPercent, double &lotSize)
{
   //CALCULATE STD DEV OF RETURNS FOR POSITION
   double stdDevReturns;
   if(!GetAssetStdDevReturns(Asset, stdDevReturns)) //2nd param passed by ref
   {
      Print("Error calculating Std Dev of Returns for " + Asset + " in: " + __FUNCTION__ + "()");
      return false;
   }
   //GET NOMINAL VALUE PER UNIT PER LOT
   double tickSize = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_SIZE);
   if (tickSize <= 0) { return false; }
   double nominalValuePerUnitPerLot = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_VALUE) / tickSize;
   if (nominalValuePerUnitPerLot <= 0) { lotSize = 0; return false; }
   double currentPrice = SymbolInfoDouble(Asset, SYMBOL_BID);
   if (currentPrice <= 0) { lotSize = 0; return false; }
   //CALCULATE THE Z-SCORE FOR THE GIVEN CONFIDENCE LEVEL
   double zScore = InverseCumulativeNormal(confidenceLevel);
   if(zScore == 0) { lotSize = 0; return false; }
   //CALCULATE THE VaR FOR A SINGLE UNIT OF THE ASSET
   double unitVaR = zScore * stdDevReturns * nominalValuePerUnitPerLot * currentPrice;
   //CALCULATE THE MAXIMUM VaR BASED ON THE ACCOUNT EQUITY AND VaR PERCENTAGE
   if (accountEquity <= 0) { lotSize = 0; return false; }
   double maxVaR = (VaRPercent / 100.0) * accountEquity;
   //CALCULATE THE LOT SIZE BASED ON THE MAXIMUM VaR
   if (unitVaR < 1e-10) { lotSize = 0; return false; }
   lotSize = maxVaR / unitVaR;
   return true;
}
double CPortfolioRiskMan::InverseCumulativeNormal(double p)
{
   // Coefficients in rational approximations
   const double a1 = -39.6968302866538;
   const double a2 = 220.946098424521;
   const double a3 = -275.928510446969;
   const double a4 = 138.357751867269;
   const double a5 = -30.6647980661472;
   const double a6 = 2.50662827745924;
   const double b1 = -54.4760987982241;
   const double b2 = 161.585836858041;
   const double b3 = -155.698979859887;
   const double b4 = 66.8013118877197;
   const double b5 = -13.2806815528857;
   const double c1 = -0.00778489400243029;
   const double c2 = -0.322396458041136;
   const double c3 = -2.40075827716184;
   const double c4 = -2.54973253934373;
   const double c5 = 4.37466414146497;
   const double c6 = 2.93816398269878;
   const double d1 = 0.00778469570904146;
   const double d2 = 0.32246712907004;
   const double d3 = 2.445134137143;
   const double d4 = 3.75440866190742;
   const double p_low = 0.02425;
   const double p_high = 1.0 - p_low;
   double q, r;
   if ((0 < p) && (p < p_low))
   {
      q = sqrt(-2 * log(p));
      return (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
             ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
   }
   else if ((p_low <= p) && (p <= p_high))
   {
      q = p - 0.5;
      r = q * q;
      return (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
             (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
   }
   else if ((p_high < p) && (p < 1))
   {
      q = sqrt(-2 * log(1 - p));
      return -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
             ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
   }
   // If p is outside the valid range
   Print("Error: p is out of range in InverseCumulativeNormal");
   return 0;
}
bool CPortfolioRiskMan::GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns)
{
    // Cache lookup — linear scan (sufficient for typical use; batch callers should ClearCache between batches)
    for (int i = 0; i < m_cacheCount; i++)
    {
        if (m_symbolCache[i] == VolSymbolName)
        {
            if (TimeCurrent() - m_cacheTimestamp[i] < 300) // 5 minutes
            {
                StandardDevOfReturns = m_stdDevReturnsCache[i];
                return true;
            }
            // Stale — recompute and update in place
            break;
        }
    }

    // CopyClose into pre-allocated work array (avoids heap alloc per call)
    int needed = StandardDeviationPeriods + 1;
    int copied = CopyClose(VolSymbolName, ValueAtRiskTimeframe, 1, needed, m_returns);
    if (copied < needed)
    {
        Print("Failed to copy enough close prices for ", VolSymbolName, " (got ", copied, ", need ", needed, ")");
        return false;
    }

    // Compute daily returns into pre-allocated work array
    int numReturns = copied - 1;
    if (ArraySize(m_dailyReturns) < numReturns)
        ArrayResize(m_dailyReturns, numReturns);

    for (int i = 0; i < numReturns; i++)
    {
        if (m_returns[i] == 0.0 || m_returns[i+1] == 0.0) { m_dailyReturns[i] = 0.0; continue; }
        m_dailyReturns[i] = (m_returns[i+1] / m_returns[i]) - 1.0;
    }

    StandardDevOfReturns = StdDev(m_dailyReturns, numReturns);
    if (StandardDevOfReturns == 0 || !MathIsValidNumber(StandardDevOfReturns))
    {
        Print("StdDev of returns is zero or invalid for ", VolSymbolName);
        return false;
    }

    // Update or append cache entry
    int slot = -1;
    for (int i = 0; i < m_cacheCount; i++)
    {
        if (m_symbolCache[i] == VolSymbolName) { slot = i; break; }
    }
    if (slot == -1)
    {
        int capacity = ArraySize(m_symbolCache);
        if (m_cacheCount >= capacity)
        {
            int newCap = (capacity == 0) ? 256 : capacity * 2;
            ArrayResize(m_symbolCache, newCap);
            ArrayResize(m_stdDevReturnsCache, newCap);
            ArrayResize(m_cacheTimestamp, newCap);
        }
        slot = m_cacheCount++;
    }
    m_symbolCache[slot] = VolSymbolName;
    m_stdDevReturnsCache[slot] = StandardDevOfReturns;
    m_cacheTimestamp[slot] = TimeCurrent();

    return true;
}
