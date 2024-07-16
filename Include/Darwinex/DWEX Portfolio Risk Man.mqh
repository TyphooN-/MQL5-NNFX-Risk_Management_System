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
#property version       "1.02"
#property strict
#include <Math\Stat\Math.mqh>

class CPortfolioRiskMan
{
   public:   
      double SinglePositionVaR; 
      void   CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTimeframe, int StdDevPeriods); //CONSTRUCTOR
      bool   CalculateVaR(string Asset, double AssetPosSize);
      bool   CalculateLotSizeBasedOnVaR(string Asset, double confidenceLevel, double accountEquity, double VaRPercent, double &lotSize);
      double PublicInverseCumulativeNormal(double confidenceLevel)
      {
         return InverseCumulativeNormal(confidenceLevel);
      }
      bool PublicGetAssetStdDevReturns(const string &symbol, double &stdDevReturns)
      {
         return GetAssetStdDevReturns(symbol, stdDevReturns);
      }
   private:
      ENUM_TIMEFRAMES ValueAtRiskTimeframe;
      int   StandardDeviationPeriods;
      bool  GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns);
      double InverseCumulativeNormal(double p);
};
//CONSTRUCTOR
void CPortfolioRiskMan::CPortfolioRiskMan(ENUM_TIMEFRAMES VaRTF, int SDPeriods)  
{
   ValueAtRiskTimeframe     = VaRTF;
   StandardDeviationPeriods = SDPeriods;
}
bool CPortfolioRiskMan::CalculateVaR(string Asset, double AssetPosSize) //N.B. ProposedPosSize should be +ve for a LONG pos and -ve for a SHORT pos                 
{  
   //CALCULATE STD DEV OF RETURNS FOR POSITION
   double stdDevReturns;
   if(!GetAssetStdDevReturns(Asset, stdDevReturns)) //2nd param passed by ref
   {
      Alert("Error calculating Std Dev of Returns for " + Asset + " in: " + __FUNCTION__ + "()");
      return false;
   }
   //GET NOMINAL VALUE FOR PROPOSED POSITION
   //TODO: THIS ASSUMES ALL ASSETS CALCULATED USING ACCOUNT CURRENCY. FOR OTHERS E.G. SPX500 NEED TO DO CURRENCY CONVERSION
   double nominalValuePerUnitPerLot = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_SIZE);
   double nominalValue              = MathAbs(AssetPosSize) * nominalValuePerUnitPerLot * iClose(Asset, PERIOD_M1, 0);  //RATIONALE: This calculates how much would be lost on a position that moved from its current price to a 0 price. This is equivalent to the nominal amount invested if we were trading with 1:1 leverage, i.e. the total amount you would lose if the asset's price went to 0
   //CALCULATE THE VaR VALUES FOR THIS IND PROPOSED POSITION
   //VaR Calculated on basis of "max expected loss in 1-day" at a "95% confidence level" (This value will be exceeded 1 day out of 20). The value of 1.65 is the 95% Z-Score for a one-tailed test
   SinglePositionVaR = 1.65 * stdDevReturns * nominalValue; //nominalValue is always +ve because of MathAbs(AssetPosSize) above
   return true;
}
bool CPortfolioRiskMan::CalculateLotSizeBasedOnVaR(string Asset, double confidenceLevel, double accountEquity, double VaRPercent, double &lotSize)
{
   //CALCULATE STD DEV OF RETURNS FOR POSITION
   double stdDevReturns;
   if(!GetAssetStdDevReturns(Asset, stdDevReturns)) //2nd param passed by ref
   {
      Alert("Error calculating Std Dev of Returns for " + Asset + " in: " + __FUNCTION__ + "()");
      return false;
   }
   //GET NOMINAL VALUE PER UNIT PER LOT
   double nominalValuePerUnitPerLot = SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Asset, SYMBOL_TRADE_TICK_SIZE);
   double currentPrice = iClose(Asset, PERIOD_M1, 0);
   //CALCULATE THE Z-SCORE FOR THE GIVEN CONFIDENCE LEVEL
   double zScore = InverseCumulativeNormal(confidenceLevel);
   //CALCULATE THE VaR FOR A SINGLE UNIT OF THE ASSET
   double unitVaR = zScore * stdDevReturns * nominalValuePerUnitPerLot * currentPrice;
   //CALCULATE THE MAXIMUM VaR BASED ON THE ACCOUNT EQUITY AND VaR PERCENTAGE
   double maxVaR = (VaRPercent / 100.0) * accountEquity;
   //CALCULATE THE LOT SIZE BASED ON THE MAXIMUM VaR
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
   Alert("Error: p is out of range in InverseCumulativeNormal");
   return 0;
}
bool CPortfolioRiskMan::GetAssetStdDevReturns(string VolSymbolName, double &StandardDevOfReturns)
{
   double returns[];
   ArrayResize(returns, StandardDeviationPeriods);
   //STORE 'CHANGE' IN CLOSE PRICES TO ARRAY
   for(int calcLoop=0; calcLoop < StandardDeviationPeriods; calcLoop++) //START LOOP AT 1 BECAUSE DON'T WANT TO INCLUDE CURRENT BAR (WHICH MIGHT NOT BE COMPLETE) IN CALC.
   {
      //USE calcLoop + 1 BECAUSE DON'T WANT TO INCLUDE CURRENT BAR (WHICH WILL NOT BE COMPLETE) IN CALC.  CALCULATE RETURN AS A RATIO. i.e. 0.01 IS A 1% INCREASE, AND -0.01 IS A 1% DECREASE
      returns[calcLoop] = (iClose(VolSymbolName, ValueAtRiskTimeframe, calcLoop + 1) / iClose(VolSymbolName, ValueAtRiskTimeframe, calcLoop + 2)) - 1.0;
   }
   //CALCULATE THE STD DEV OF ALL RETURNS (MathStandardDeviation() IN #include <Math\Stat\Math.mqh>)
   StandardDevOfReturns = MathStandardDeviation(returns);
   return true;
}
