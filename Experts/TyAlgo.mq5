/**=             TyAlgo.mq5  (TyphooN's MQL5 Algo EA)
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
#property version   "2.100"
#property description "NNFX Confluence Algo EA — Modular Signal Slots"
#include <Trade\Trade.mqh>
#include <Orchard\RiskCalc.mqh>
#include <Darwinex\DWEX Portfolio Risk Man.mqh>
#include <TyAlgo\SignalSlots.mqh>
// ── Input Parameters ─────────────────────────────────────────────────────────
input group              "[BASELINE SLOT]";
input ENUM_BASELINE_TYPE BaselineType   = BL_KAMA;
input ENUM_TIMEFRAMES    BL_KAMA_TF     = PERIOD_D1;
input string             BL_CustomGV    = ""; // Custom GV name (BL_CUSTOM_GV only)
input group              "[CONFIRMATION 1 SLOT]";
input ENUM_CONFIRM_TYPE  Confirm1Type      = CF_FISHER;
input double             C1_MTF_MinBullHTF = 10;
input double             C1_MTF_MinBearHTF = 10;
input string             C1_CustomGV       = ""; // Custom GV name (CF_CUSTOM_GV only)
input group              "[CONFIRMATION 2 SLOT]";
input ENUM_CONFIRM_TYPE  Confirm2Type   = CF_MTF_MA;
input double             C2_MTF_MinBullHTF = 10;
input double             C2_MTF_MinBearHTF = 10;
input string             C2_CustomGV    = ""; // Custom GV name (CF_CUSTOM_GV only)
input group              "[VOLUME SLOT]";
input ENUM_VOLUME_TYPE   VolumeType     = VL_RVOL;
input double             VL_MinRVOL     = 0.8;
input int                VL_RVOL_Days   = 10;
input string             VL_CustomGV    = ""; // Custom GV name (VL_CUSTOM_GV only)
input group              "[EXIT SLOT]";
input ENUM_EXIT_TYPE     ExitType       = EX_FISHER;
input string             EX_CustomGV    = ""; // Custom GV name (EX_CUSTOM_GV only)
input group              "[EA SETTINGS]";
input int                MagicNumber    = 42;
input group              "[VAR POSITION SIZING]";
input double             RiskVaRPercent = 1;
input ENUM_TIMEFRAMES    VaRTimeframe   = PERIOD_D1;
input int                StdDevPeriods  = 21;
input double             VaRConfidence  = 0.95;
input group              "[ATR SL/TP]";
input int                ATR_Period     = 14;
input double             SL_ATR_Multi   = 1.5;
input double             TP_ATR_Multi   = 1.0;
input group              "[SPREAD FILTER]";
input double             MaxSpreadATRPct = 50.0; // Max spread as % of ATR (0=disabled)
// ── Global Variables ─────────────────────────────────────────────────────────
CTrade Trade;
CPortfolioRiskMan PortfolioRisk(VaRTimeframe, StdDevPeriods, VaRConfidence);
double AccountEquity = 0, AccountBalance = 0, percent_risk = 0;
int OrderDigits = 0;
int handle_iATR = INVALID_HANDLE;
SlotState g_slotBaseline, g_slotConfirm1, g_slotConfirm2, g_slotVolume, g_slotExit;
// Structure to store lots information
struct LotsInfo
{
   double longLots;
   double shortLots;
};
// Forward declarations
void ClosePositionsByType(int posType);
void UpdateDashboard(LotsInfo &lots, double total_risk, double total_tp, double total_pl, double sl_risk);
ENUM_ORDER_TYPE_FILLING SelectFillingMode();
void CreateAndSetObject(string name, int x_dist, int y_dist, color clr, int corner, string font = "Courier New", int size = 8);
string FormatInfoString(string label, double value, int digits = 2, string prefix = "$");
// ── OnInit ───────────────────────────────────────────────────────────────────
int OnInit()
{
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("Trading not allowed on this account.");
      return INIT_FAILED;
   }
   ENUM_ORDER_TYPE_FILLING fillMode = SelectFillingMode();
   if ((int)fillMode != -1)
      Trade.SetTypeFilling(fillMode);
   Trade.SetExpertMagicNumber(MagicNumber);
   // Compute OrderDigits from volume step
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
   // ATR handle (always needed for SL/TP)
   handle_iATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   if (handle_iATR == INVALID_HANDLE)
   {
      Print("Failed to create ATR indicator handle: ", GetLastError());
      return INIT_FAILED;
   }
   // Init signal slots
   if (!InitBaselineSlot(BaselineType, BL_KAMA_TF, BL_CustomGV, g_slotBaseline))
   {
      Print("Baseline slot init failed");
      return INIT_FAILED;
   }
   if (!InitConfirmSlot(Confirm1Type, C1_CustomGV, g_slotConfirm1))
   {
      Print("Confirmation 1 slot init failed");
      return INIT_FAILED;
   }
   if (!InitConfirmSlot(Confirm2Type, C2_CustomGV, g_slotConfirm2))
   {
      Print("Confirmation 2 slot init failed");
      return INIT_FAILED;
   }
   if (!InitVolumeSlot(VolumeType, VL_RVOL_Days, VL_CustomGV, g_slotVolume))
   {
      Print("Volume slot init failed");
      return INIT_FAILED;
   }
   if (!InitExitSlot(ExitType, EX_CustomGV, g_slotExit))
   {
      Print("Exit slot init failed");
      return INIT_FAILED;
   }
   // Init NewBar static to avoid false trigger on first tick
   NewBar(NULL, 0, true);
   // Create dashboard objects
   int LeftColumnX = 310, RightColumnX = 150, YRowWidth = 13;
   CreateAndSetObject("infoPosition", LeftColumnX, YRowWidth * 2, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoVaR", RightColumnX, YRowWidth * 2, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoRisk", RightColumnX, YRowWidth * 3, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoPL", LeftColumnX, YRowWidth * 3, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoSLPL", RightColumnX, YRowWidth * 4, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoTP", LeftColumnX, YRowWidth * 4, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoTPRR", RightColumnX, YRowWidth * 5, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoRR", LeftColumnX, YRowWidth * 5, clrWhite, CORNER_RIGHT_UPPER);
   CreateAndSetObject("infoConfluence", LeftColumnX, YRowWidth * 6, clrYellow, CORNER_RIGHT_UPPER);
   // Init dashboard text
   ObjectSetString(0, "infoPosition", OBJPROP_TEXT, "No Positions Detected");
   ObjectSetString(0, "infoVaR", OBJPROP_TEXT, "VaR %: 0.00");
   ObjectSetString(0, "infoRisk", OBJPROP_TEXT, "Risk: $0.00");
   ObjectSetString(0, "infoPL", OBJPROP_TEXT, "Total P/L: $0.00");
   ObjectSetString(0, "infoSLPL", OBJPROP_TEXT, "SL P/L: $0.00");
   ObjectSetString(0, "infoTP", OBJPROP_TEXT, "TP P/L : $0.00");
   ObjectSetString(0, "infoTPRR", OBJPROP_TEXT, "TP RR: N/A");
   ObjectSetString(0, "infoRR", OBJPROP_TEXT, "RR : N/A");
   ObjectSetString(0, "infoConfluence", OBJPROP_TEXT, "Confluence: Waiting...");
   return INIT_SUCCEEDED;
}
// ── OnDeinit ─────────────────────────────────────────────────────────────────
void OnDeinit(const int reason)
{
   if (handle_iATR != INVALID_HANDLE)
      IndicatorRelease(handle_iATR);
   DeinitSlot(g_slotBaseline);
   DeinitSlot(g_slotConfirm1);
   DeinitSlot(g_slotConfirm2);
   DeinitSlot(g_slotVolume);
   DeinitSlot(g_slotExit);
   ObjectsDeleteAll(0, "info");
}
// ── OnTick ───────────────────────────────────────────────────────────────────
void OnTick()
{
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   // Phase A: Position monitoring (every tick) — single merged loop
   LotsInfo lots;
   lots.longLots = 0.0;
   lots.shortLots = 0.0;
   double total_risk = 0, total_tpprofit = 0, total_pl = 0, sl_risk = 0;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (!PositionSelectByTicket(ticket)) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      int posType = (int)PositionGetInteger(POSITION_TYPE);
      double posVolume = PositionGetDouble(POSITION_VOLUME);
      double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double swap = PositionGetDouble(POSITION_SWAP);
      double profit = PositionGetDouble(POSITION_PROFIT) + swap;
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double risk = 0, tpprofit = 0;
      // Accumulate lots
      if (posType == POSITION_TYPE_BUY)
         lots.longLots += posVolume;
      else if (posType == POSITION_TYPE_SELL)
         lots.shortLots += posVolume;
      // Calculate risk, tpprofit, margin
      ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      if (tp != 0 && !OrderCalcProfit(orderType, _Symbol, posVolume, posOpenPrice, tp, tpprofit))
         Print("Error in OrderCalcProfit (TP): ", GetLastError());
      if (sl != 0 && !OrderCalcProfit(orderType, _Symbol, posVolume, posOpenPrice, sl, risk))
         Print("Error in OrderCalcProfit (SL): ", GetLastError());
      if (risk <= 0)
         sl_risk += risk;
      if (swap > 0)
         total_risk += swap;
      if (swap > 0 && risk <= 0)
         sl_risk += swap;
      total_risk += risk;
      total_pl += profit;
      total_tpprofit += tpprofit;
   }
   bool hasBuy = lots.longLots > 0;
   bool hasSell = lots.shortLots > 0;
   // Update dashboard (every tick)
   UpdateDashboard(lots, total_risk, total_tpprofit, total_pl, sl_risk);
   // Phase B: Signal evaluation (new bar only)
   if (!NewBar()) return;
   // Read ATR from completed bar (bar[1])
   double atrBuffer[];
   if (CopyBuffer(handle_iATR, 0, 1, 1, atrBuffer) != 1)
   {
      Print("Failed to read ATR buffer: ", GetLastError());
      return;
   }
   double atrValue = atrBuffer[0];
   // ── Read all signal slots ─────────────────────────────────────────────
   SignalResult sigBaseline = ReadBaselineSignal(BaselineType, g_slotBaseline);
   SignalResult sigConfirm1 = ReadConfirmSignal(Confirm1Type, g_slotConfirm1, C1_MTF_MinBullHTF, C1_MTF_MinBearHTF);
   SignalResult sigConfirm2 = ReadConfirmSignal(Confirm2Type, g_slotConfirm2, C2_MTF_MinBullHTF, C2_MTF_MinBearHTF);
   SignalResult sigVolume   = ReadVolumeSignal(VolumeType, g_slotVolume, VL_MinRVOL);
   SignalResult sigExit     = ReadExitSignal(ExitType, g_slotExit);
   // ── Exit slot — independent of confluence, spread, and volume ─────────
   if (g_slotExit.active && sigExit.valid)
   {
      if (sigExit.direction < 0 && hasBuy)
         ClosePositionsByType(POSITION_TYPE_BUY);
      if (sigExit.direction > 0 && hasSell)
         ClosePositionsByType(POSITION_TYPE_SELL);
   }
   // Check for data errors on entry slots
   if ((g_slotBaseline.active && !sigBaseline.valid) ||
       (g_slotConfirm1.active && !sigConfirm1.valid) ||
       (g_slotConfirm2.active && !sigConfirm2.valid) ||
       (g_slotVolume.active   && !sigVolume.valid))
   {
      ObjectSetString(0, "infoConfluence", OBJPROP_TEXT, "Confluence: Data Error");
      return;
   }
   // Get current prices
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // Spread filter (entry gate — exits already processed above)
   if (MaxSpreadATRPct > 0 && atrValue > 0)
   {
      double spread = ask - bid;
      double spreadPct = (spread / atrValue) * 100;
      if (spreadPct > MaxSpreadATRPct)
      {
         ObjectSetString(0, "infoConfluence", OBJPROP_TEXT, "Confluence: Spread too wide");
         return;
      }
   }
   // ── Consensus confluence engine ───────────────────────────────────────
   // Active slots returning neutral (0) block entry
   bool hasNeutral = false;
   if (g_slotBaseline.active && sigBaseline.direction == 0) hasNeutral = true;
   if (g_slotConfirm1.active && sigConfirm1.direction == 0) hasNeutral = true;
   if (g_slotConfirm2.active && sigConfirm2.direction == 0) hasNeutral = true;
   // Collect non-zero directions from active directional slots
   int directions[3];
   int dirCount = 0;
   if (g_slotBaseline.active && sigBaseline.direction != 0)
      directions[dirCount++] = sigBaseline.direction;
   if (g_slotConfirm1.active && sigConfirm1.direction != 0)
      directions[dirCount++] = sigConfirm1.direction;
   if (g_slotConfirm2.active && sigConfirm2.direction != 0)
      directions[dirCount++] = sigConfirm2.direction;
   // Consensus: all non-zero must agree, no active neutrals
   int consensusDir = 0;
   if (!hasNeutral && dirCount > 0)
   {
      bool allAgree = true;
      int firstDir = directions[0];
      for (int i = 1; i < dirCount; i++)
      {
         if (directions[i] != firstDir)
         {
            allAgree = false;
            break;
         }
      }
      if (allAgree)
         consensusDir = firstDir;
   }
   // Volume gate
   bool volumePass = (sigVolume.direction == 1);
   // Build confluence status display
   string confStatus = "";
   if (g_slotBaseline.active) confStatus += sigBaseline.label + " ";
   if (g_slotConfirm1.active) confStatus += sigConfirm1.label + " ";
   if (g_slotConfirm2.active) confStatus += sigConfirm2.label + " ";
   if (g_slotVolume.active)   confStatus += sigVolume.label + " ";
   if (g_slotExit.active)     confStatus += sigExit.label;
   if (g_slotVolume.active && !volumePass)
      confStatus += " [Low RVOL]";
   ObjectSetString(0, "infoConfluence", OBJPROP_TEXT, "Confluence: " + confStatus);
   // Entry signals
   bool buySignal  = (consensusDir == +1) && volumePass;
   bool sellSignal = (consensusDir == -1) && volumePass;
   if ((buySignal && !hasBuy) || (sellSignal && !hasSell))
   {
      // VaR lot sizing (only computed when entry signal exists)
      double lotSize = 0;
      if (AccountEquity > 0 && PortfolioRisk.CalculateLotSizeBasedOnVaR(_Symbol, VaRConfidence, AccountEquity, RiskVaRPercent, lotSize))
      {
         lotSize = NormalizeDouble(lotSize, OrderDigits);
      }
      double volumeMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if (lotSize < volumeMin)
      {
         ObjectSetString(0, "infoConfluence", OBJPROP_TEXT, "Confluence: Lot size below minimum");
         return;
      }
      // Entry with ATR-based SL/TP (normalized to tick size)
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      if (tickSize <= 0) tickSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if (buySignal && !hasBuy)
      {
         double slPrice = MathRound((ask - (atrValue * SL_ATR_Multi)) / tickSize) * tickSize;
         double tpPrice = MathRound((ask + (atrValue * TP_ATR_Multi)) / tickSize) * tickSize;
         if (Trade.Buy(lotSize, _Symbol, ask, slPrice, tpPrice, "NNFX Buy"))
            Print("Buy position opened: ", lotSize, " lots, SL=", slPrice, " TP=", tpPrice);
         else
            Print("Error opening Buy position: ", GetLastError());
      }
      else if (sellSignal && !hasSell)
      {
         double slPrice = MathRound((bid + (atrValue * SL_ATR_Multi)) / tickSize) * tickSize;
         double tpPrice = MathRound((bid - (atrValue * TP_ATR_Multi)) / tickSize) * tickSize;
         if (Trade.Sell(lotSize, _Symbol, bid, slPrice, tpPrice, "NNFX Sell"))
            Print("Sell position opened: ", lotSize, " lots, SL=", slPrice, " TP=", tpPrice);
         else
            Print("Error opening Sell position: ", GetLastError());
      }
   }
}
// Update dashboard display
void UpdateDashboard(LotsInfo &lots, double total_risk, double total_tp, double total_pl, double sl_risk)
{
   double absRisk = MathAbs(total_risk);
   double tprr = 0, rr = 0;
   if (absRisk > 0)
   {
      tprr = total_tp / absRisk;
      rr = total_pl / absRisk;
   }
   if (AccountBalance > 0)
      percent_risk = MathAbs((sl_risk / AccountBalance) * 100);
   string infoRisk, infoPL, infoRR = (rr >= 0) ? "RR : " + DoubleToString(rr, 2) : "RR : N/A";
   if (total_pl >= absRisk)
   {
      double floatingRisk = MathAbs(total_pl - total_risk);
      double floatingRiskPercent = (AccountBalance > 0) ? MathAbs((total_pl - total_risk) / AccountBalance) * 100 : 0;
      double plPercent = (AccountBalance > 0) ? (total_pl / AccountBalance) * 100 : 0;
      infoRisk = "Risk: $" + DoubleToString(floatingRisk, 0) + " (" + DoubleToString(floatingRiskPercent, 2) + "%)";
      infoPL = "Total P/L: $" + DoubleToString(total_pl, 0) + " (" + DoubleToString(plPercent, 2) + "%)";
   }
   else
   {
      double plPercent = (AccountBalance > 0) ? (total_pl / AccountBalance) * 100 : 0;
      infoRisk = "Risk: $" + DoubleToString(MathAbs(total_risk), 0) + " (" + DoubleToString(percent_risk, 2) + "%)";
      infoPL = "Total P/L: $" + DoubleToString(total_pl, 0) + " (" + DoubleToString(plPercent, 2) + "%)";
   }
   ObjectSetString(0, "infoRisk", OBJPROP_TEXT, infoRisk);
   ObjectSetString(0, "infoPL", OBJPROP_TEXT, infoPL);
   ObjectSetString(0, "infoSLPL", OBJPROP_TEXT, FormatInfoString("SL P/L", total_risk));
   ObjectSetString(0, "infoTP", OBJPROP_TEXT, FormatInfoString("TP P/L", total_tp));
   ObjectSetString(0, "infoTPRR", OBJPROP_TEXT, FormatInfoString("TP RR", tprr, 2, ""));
   ObjectSetString(0, "infoRR", OBJPROP_TEXT, infoRR);
   // Position/VaR display — only recalculate VaR when lot sizes change
   static double prevLongLots = -1, prevShortLots = -1;
   static string cachedVaRStr = "VaR %: 0.00";
   bool hasBuy = lots.longLots > 0;
   bool hasSell = lots.shortLots > 0;
   bool lotsChanged = (lots.longLots != prevLongLots || lots.shortLots != prevShortLots);
   if (hasBuy || hasSell)
   {
      string infoPosition;
      if (hasBuy && !hasSell)
      {
         infoPosition = "Long " + DoubleToString(lots.longLots, OrderDigits) + " Lots";
         ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, "infoVaR", OBJPROP_COLOR, clrLime);
         ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
         if (lotsChanged && AccountEquity > 0 && PortfolioRisk.CalculateVaR(_Symbol, lots.longLots))
            cachedVaRStr = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR / AccountEquity * 100), 2);
      }
      else if (hasSell && !hasBuy)
      {
         infoPosition = "Short " + DoubleToString(lots.shortLots, OrderDigits) + " Lots";
         ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, "infoVaR", OBJPROP_COLOR, clrRed);
         ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
         if (lotsChanged && AccountEquity > 0 && PortfolioRisk.CalculateVaR(_Symbol, lots.shortLots))
            cachedVaRStr = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR / AccountEquity * 100), 2);
      }
      else
      {
         infoPosition = DoubleToString(lots.longLots, OrderDigits) + " Long / " + DoubleToString(lots.shortLots, OrderDigits) + " Short";
         ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
         double netExposure = MathAbs(lots.longLots - lots.shortLots);
         if (lotsChanged && netExposure > 0 && AccountEquity > 0 && PortfolioRisk.CalculateVaR(_Symbol, netExposure))
            cachedVaRStr = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR / AccountEquity * 100), 2) + " (net)";
         else if (lotsChanged && netExposure == 0)
            cachedVaRStr = "VaR %: 0.00 (hedged)";
      }
      ObjectSetString(0, "infoVaR", OBJPROP_TEXT, cachedVaRStr);
   }
   else
   {
      ObjectSetInteger(0, "infoPosition", OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, "infoPosition", OBJPROP_TEXT, "No Positions Detected");
      if (lotsChanged) cachedVaRStr = "VaR %: 0.00";
      ObjectSetString(0, "infoVaR", OBJPROP_TEXT, cachedVaRStr);
   }
   prevLongLots = lots.longLots;
   prevShortLots = lots.shortLots;
}
// Close all positions of specified type for this symbol and magic number
void ClosePositionsByType(int posType)
{
   int total = PositionsTotal();
   for (int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (!PositionSelectByTicket(ticket)) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if ((int)PositionGetInteger(POSITION_TYPE) != posType) continue;
      if (Trade.PositionClose(ticket))
         Print("Closed position ticket: ", ticket);
      else
         Print("Error closing position: ", GetLastError());
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
   return (ENUM_ORDER_TYPE_FILLING)-1;
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
