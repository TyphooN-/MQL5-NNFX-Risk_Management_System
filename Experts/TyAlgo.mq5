/**=             TyphooN.mq5  (TyphooN's MQL5 Algo EA)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.org/)
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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/
#property copyright "Copyright 2023 TyphooN (MarketWizardry.org)"
#property link      "http://marketwizardry.info/"
#property version   "1.002"
#property description "TyphooN's MQL5 Algo EA"
#include <Trade\Trade.mqh>
#include <Darwinex\DWEX Portfolio Risk Man.mqh>
// Input parameters
input double          RiskVaRPercent  = 1;
input ENUM_TIMEFRAMES VaRTimeframe   = PERIOD_D1;
input int             StdDevPeriods  = 21;
input double          VaRConfidence  = 0.95;
// Global variables
double SL = 0, TP = 0, AccountEquity = 0, AccountBalance = 0, percent_risk = 0;
int OrderDigits = 0;
bool HasOpenPosition = false;
CTrade Trade;
CPortfolioRiskMan PortfolioRisk(VaRTimeframe, StdDevPeriods);
// Function declarations
ENUM_ORDER_TYPE_FILLING SelectFillingMode();
void CreateAndSetObject(string name, int x_dist, int y_dist, color clr, int corner, string font = "Courier New", int size = 8);
string FormatInfoString(string label, double value, int digits = 2, string prefix = "$");
// Structure to store lots information
struct LotsInfo
{
   double longLots;
   double shortLots;
};
LotsInfo TallyPositionLots();
bool HasOpenPosition(string sym, int orderType);
// OnInit function
void OnInit()
{
   double volumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   string volumeStepStr = DoubleToString(volumeStep, 8);
   int decimalPos = StringFind(volumeStepStr, ".");
   if (decimalPos >= 0)
   {
      OrderDigits = StringLen(volumeStepStr) - decimalPos - 1;
      while (StringSubstr(volumeStepStr, StringLen(volumeStepStr) - 1, 1) == "0")
      {
         volumeStepStr = StringSubstr(volumeStepStr, 0, StringLen(volumeStepStr) - 1);
         OrderDigits--;
      }
   }
   int LeftColumnX = 310, RightColumnX = 150, YRowWidth = 13;
   CreateAndSetObject("infoPosition", LeftColumnX, YRowWidth * 2, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoVaR", RightColumnX, YRowWidth * 2, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoRisk", RightColumnX, YRowWidth * 3, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoPL", LeftColumnX, YRowWidth * 3, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoSLPL", RightColumnX, YRowWidth * 4, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoTP", LeftColumnX, YRowWidth * 4, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoTPRR", RightColumnX, YRowWidth * 5, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoRR", LeftColumnX, YRowWidth * 5, clrWhite, CORNER_RIGHT_UPPER);
   string infoPosition = "No Positions Detected";
   double var_1_lot = 0.0;
   if (PortfolioRisk.CalculateVaR(_Symbol, 1.0))
   {
      var_1_lot = PortfolioRisk.SinglePositionVaR;
      infoPosition = "VaR 1 lot: " + DoubleToString(var_1_lot, 2);
   }
   ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
   ObjectSetString(0, "infoVaR", OBJPROP_TEXT, "VaR %: 0.00");
   ObjectSetString(0, "infoRisk", OBJPROP_TEXT, "Risk: $0.00");
   ObjectSetString(0, "infoPL", OBJPROP_TEXT, "Total P/L: $0.00");
   ObjectSetString(0, "infoSLPL", OBJPROP_TEXT, "SL P/L: $0.00");
   ObjectSetString(0, "infoTP", OBJPROP_TEXT, "TP P/L : $0.00");
   ObjectSetString(0, "infoTPRR", OBJPROP_TEXT, "TP RR: N/A");
   ObjectSetString(0, "infoRR", OBJPROP_TEXT, "RR : N/A");
}
// OnTick function
void OnTick()
{
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double total_risk = 0, total_tpprofit = 0, total_pl = 0, total_tp = 0, total_margin = 0, rr = 0, tprr = 0, sl_risk = 0;
   // Check Fisher Transform Bias
   double fisherBias = GlobalVariableGet("FisherBias");
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double risk = 0, tpprofit = 0, margin = 0, sl = PositionGetDouble(POSITION_SL), tp = PositionGetDouble(POSITION_TP);
      ENUM_ORDER_TYPE orderType = (tp > sl) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      if (!OrderCalcMargin(orderType, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
      {
         Print("Error in OrderCalcMargin: ", GetLastError());
      }
      if (tp != 0 && !OrderCalcProfit(orderType, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), tp, tpprofit))
      {
         Print("Error in OrderCalcProfit (TP): ", GetLastError());
      }
      if (sl != 0 && !OrderCalcProfit(orderType, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), sl, risk))
      {
         Print("Error in OrderCalcProfit (SL): ", GetLastError());
      }
      if (risk <= 0)
      {
         sl_risk += risk;
      }
      if (PositionGetDouble(POSITION_SWAP) > 0)
      {
         total_risk += PositionGetDouble(POSITION_SWAP);
      }
      if (PositionGetDouble(POSITION_SWAP) > 0 && risk <= 0)
      {
         sl_risk += PositionGetDouble(POSITION_SWAP);
      }
      total_risk += risk;
      total_pl += profit;
      total_tp += tpprofit;
      total_margin += margin;
      tprr = total_tp / MathAbs(total_risk);
      rr = total_pl / MathAbs(total_risk);
      percent_risk = MathAbs((sl_risk / AccountBalance) * 100);
    }
    string infoRisk, infoPL, infoRR = (rr >= 0) ? "RR : " + DoubleToString(rr, 2) : "RR : N/A";
    if (total_pl >= MathAbs(total_risk))
    {
      double floatingRisk = MathAbs(total_pl - total_risk);
      double floatingRiskPercent = MathAbs((total_pl - total_risk) / AccountBalance) * 100;
      infoRisk = "Risk: $" + DoubleToString(floatingRisk, 0) + " (" + DoubleToString(floatingRiskPercent, 2) + "%)";
      infoPL = "Total P/L: $" + DoubleToString(total_pl, 0) + " (" + DoubleToString((total_pl / AccountBalance) * 100, 2) + "%)";
   }
   else
   {
      infoRisk = "Risk: $" + DoubleToString(MathAbs(total_risk), 0) + " (" + DoubleToString(percent_risk, 2) + "%)";
      infoPL = "Total P/L: $" + DoubleToString(total_pl, 0) + " (" + DoubleToString((total_pl / AccountBalance) * 100, 2) + "%)";
   }
   ObjectSetString(0, "infoRisk", OBJPROP_TEXT, infoRisk);
   ObjectSetString(0, "infoPL", OBJPROP_TEXT, infoPL);
   ObjectSetString(0, "infoSLPL", OBJPROP_TEXT, FormatInfoString("SL P/L", total_risk));
   ObjectSetString(0, "infoTP", OBJPROP_TEXT, FormatInfoString("TP P/L", total_tp));
   ObjectSetString(0, "infoTPRR", OBJPROP_TEXT, FormatInfoString("TP RR", tprr, 2, ""));
   ObjectSetString(0, "infoRR", OBJPROP_TEXT, infoRR);
   // Position Handling based on Fisher Transform
   LotsInfo lots = TallyPositionLots();
   string infoPosition;
   if (HasOpenPosition(_Symbol, POSITION_TYPE_BUY) || HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
   {
      if (lots.longLots > 0 && lots.shortLots == 0)
      {
         infoPosition = "Long " + DoubleToString(lots.longLots, Digits()) + " Lots";
         ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, "infoVaR", OBJPROP_COLOR, clrLime);
         ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
         if (PortfolioRisk.CalculateVaR(_Symbol, lots.longLots))
         {
            string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR / AccountEquity * 100), 2);
            ObjectSetString(0, "infoVaR", OBJPROP_TEXT, infoVaR);
         }
      }
      if (lots.shortLots > 0 && lots.longLots == 0)
      {
         infoPosition = "Short " + DoubleToString(lots.shortLots, Digits()) + " Lots";
         ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, "infoVaR", OBJPROP_COLOR, clrRed);
         ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
         if (PortfolioRisk.CalculateVaR(_Symbol, lots.shortLots))
         {
            string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR / AccountEquity * 100), 2);
            ObjectSetString(0, "infoVaR", OBJPROP_TEXT, infoVaR);
         }
      }
      if (lots.shortLots > 0 && lots.longLots > 0)
      {
         infoPosition = DoubleToString(lots.longLots, Digits()) + " Long / " + DoubleToString(lots.shortLots, Digits()) + " Short";
         ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
         if (PortfolioRisk.CalculateVaR(_Symbol, (lots.longLots + lots.shortLots)))
         {
            string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR / AccountEquity * 100), 2);
            ObjectSetString(0, "infoVaR", OBJPROP_TEXT, infoVaR);
         }
      }
   }
   // Fisher Transform Entry and Exit Logic
   double lotSize = 0;
   if (PortfolioRisk.CalculateLotSizeBasedOnVaR(_Symbol, VaRConfidence, AccountEquity, RiskVaRPercent, lotSize))
   {
      lotSize = NormalizeDouble(lotSize, OrderDigits);
   }
   // Enter Buy Position
   if (fisherBias > 0 && !HasOpenPosition(_Symbol, POSITION_TYPE_BUY))
   {
      if (Trade.Buy(lotSize))
      {
         Print("Buy position opened with lot size: ", lotSize);
      }
      else
      {
         Print("Error opening Buy position: ", GetLastError());
      }
   }
   // Enter Sell Position
   if (fisherBias < 0 && !HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
   {
      if (Trade.Sell(lotSize))
      {
         Print("Sell position opened with lot size: ", lotSize);
      }
      else
      {
         Print("Error opening Sell position: ", GetLastError());
      }
   }
   // Exit Buy Position
   if (fisherBias < 0 && HasOpenPosition(_Symbol, POSITION_TYPE_BUY))
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            if (Trade.PositionClose(PositionGetTicket(i)))
            {
               Print("Closed Buy position with ticket: ", PositionGetTicket(i));
            }
            else
            {
               Print("Error closing Buy position: ", GetLastError());
            }
         }
      }
   }
   // Exit Sell Position
   if (fisherBias > 0 && HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (PositionSelectByTicket(i) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            if (Trade.PositionClose(PositionGetTicket(i)))
            {
               Print("Closed Sell position with ticket: ", PositionGetTicket(i));
            }
            else
            {
               Print("Error closing Sell position: ", GetLastError());
            }
         }
      }
   }
}
// Function to select the filling mode
ENUM_ORDER_TYPE_FILLING SelectFillingMode()
{
   long filling_modes = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if ((filling_modes & ORDER_FILLING_IOC) != 0) return ORDER_FILLING_IOC;
   if ((filling_modes & ORDER_FILLING_FOK) != 0) return ORDER_FILLING_FOK;
   if ((filling_modes & ORDER_FILLING_BOC) != 0) return ORDER_FILLING_BOC;
   if ((filling_modes & ORDER_FILLING_RETURN) != 0) return ORDER_FILLING_RETURN;
   Print("None of the desired filling modes are supported. Unable to adjust filling mode.");
   return -1;
}
// Function to create and set properties of an object
void CreateAndSetObject(string name, int x_dist, int y_dist, color clr, int corner, string font = "Courier New", int size = 8)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x_dist);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y_dist);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
}
// Function to format information string
string FormatInfoString(string label, double value, int digits = 2, string prefix = "$")
{
   return label + ": " + (value >= 0 ? "" : "-") + prefix + DoubleToString(MathAbs(value), digits);
}
// Function to tally up the lots on all open positions and return the results
LotsInfo TallyPositionLots()
{
   LotsInfo lotsInfo;
   lotsInfo.longLots = 0.0;
   lotsInfo.shortLots = 0.0;
   string currentSymbol = Symbol(); // Get the symbol of the chart the EA is attached to
   // Loop through all open positions
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetString(POSITION_SYMBOL) == _Symbol) // Check if the position's symbol matches the current chart symbol
         {
            // Get the type of the position
            int posType = (int)PositionGetInteger(POSITION_TYPE);
            // Get the lot size of the position
            double lotSize = PositionGetDouble(POSITION_VOLUME);
            // Check if it's a buy position
            if (posType == POSITION_TYPE_BUY)
            {
               lotsInfo.longLots += lotSize;
            }
            else if (posType == POSITION_TYPE_SELL)
            {
               lotsInfo.shortLots += lotSize;
            }
         }
      }
   }
   return lotsInfo;
}
// Function to check if there is an open position of the specified type for the given symbol
bool HasOpenPosition(string sym, int orderType)
{
   for (int i = 0; i < PositionsTotal(); i++)
   {
      if (PositionGetSymbol(i) == sym && PositionGetInteger(POSITION_TYPE) == orderType)
      {
         return true;
      }
   }
   return false;
}
