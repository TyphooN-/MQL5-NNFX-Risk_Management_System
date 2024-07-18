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
#property copyright "Copyright 2023 TyphooN (MarketWizardry.org)"
#property link      "http://marketwizardry.info/"
#property version   "1.000"
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
string FormatInfoString(string label, double value, int digits = 2, string prefix = "$")
{
   return label + ": " + (value >= 0 ? "" : "-") + prefix + DoubleToString(MathAbs(value), digits);
}
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
void OnTick()
{
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double total_risk = 0, total_tpprofit = 0, total_pl = 0, total_tp = 0, total_margin = 0, rr = 0, tprr = 0, sl_risk = 0;
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
   string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity  * 100), 2);
   ObjectSetString(0,"infoVaR",OBJPROP_TEXT,infoVaR);
   ObjectSetString(0, "infoRisk", OBJPROP_TEXT, infoRisk);
   ObjectSetString(0, "infoPL", OBJPROP_TEXT, infoPL);
   ObjectSetString(0, "infoSLPL", OBJPROP_TEXT, FormatInfoString("SL P/L", total_risk));
   ObjectSetString(0, "infoTP", OBJPROP_TEXT, FormatInfoString("TP P/L", total_tp));
   ObjectSetString(0, "infoTPRR", OBJPROP_TEXT, FormatInfoString("TP RR", tprr, 2, ""));
   ObjectSetString(0, "infoRR", OBJPROP_TEXT, infoRR);
}
