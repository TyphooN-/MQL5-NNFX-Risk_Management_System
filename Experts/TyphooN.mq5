/**=             TyphooN.mq5  (TyphooN's MQL5 Risk Management System)
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
#property link      "https://www.marketwizardry.org/"
#property version   "1.405"
#property description "TyphooN's MQL5 Risk Management System"
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Trade\Trade.mqh>
#include <Orchard\RiskCalc.mqh>
#include <Darwinex\DWEX Portfolio Risk Man.mqh>
#define XRGB(r,g,b)    (0xFF000000|(uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define GETRGB(clr)    ((clr)&0xFFFFFF)
// Classes
CTrade            Trade;    // Trade wrapper
// orchard compat function
double TickSize( string symbol ) { return ( SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE ) ); }
enum OrderModeEnum { Standard, Fixed, Dynamic, VaR };
enum VaRModeEnum { PercentVaR, NotionalVaR };
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
// input vars
input group           "[EXPERT ADVISOR SETTINGS]";
input int             MagicNumber                = 13;
input int             HorizontalLineThickness    = 3;
input bool            ManageAllPositions         = false;
input int             FontSize                   = 8;
input group           "[ORDER PLACEMENT SETTINGS]";
input int             MarginBufferPercent        = 1;
input double          AdditionalRiskRatio        = 0.25;
input OrderModeEnum   OrderMode = VaR;
input group           "[VALUE AT RISK (VaR) RISK MODE]"
input VaRModeEnum     VaRRiskMode = PercentVaR;
input double          RiskVaRPercent  = 0.9;
input double          RiskVaRNotional = 9001;
input ENUM_TIMEFRAMES VaRTimeframe   = PERIOD_D1;
input int             StdDevPeriods  = 21;
input double          VaRConfidence  = 0.95;
input group           "[FIXED LOTS MODE]";
input double          FixedLots                  = 20;
input int             FixedOrdersToPlace         = 2;
input group           "[STANDARD RISK MODE]";
input double          MaxRisk                    = 1.0;
input double          Risk                       = 0.5;
input group           "[DYNAMIC RISK MODE]";
input double          MinAccountBalance          = 96100;
input int             LossesToMinBalance         = 10;
input group           "[ACCOUNT PROTECTION SETTINGS]";
input bool            EnableUpdateEmptySLTP      = false;
input bool            EnableEquityTP             = false;
input double          TargetEquityTP             = 110200;
input bool            EnableEquitySL             = false;
input double          TargetEquitySL             = 98000;
input group           "[MARTINGALE MODE SETTINGS]"
input double          MartingaleCloseChunkSize = 50;  // lots per partial close
input int             MartingaleCooldown = 30;        // seconds between orders
input double          MartingaleEquityTP = 0;         // $ profit target (0 = disabled)
input double          MartingaleUnwindLotSize = 1;    // lots per hedge unwind close
input double          MartingaleUnwindMarginPct = 0;  // % margin usage — unwind hedges above this (0=off)
input double          MartingaleDangerMarginPct = 0;  // % margin usage — protective bias close above this (0=off)
input double          MartingaleHarvestMarginPct = 0; // % margin — harvest profits above this (0=off)
input double          MartingaleHarvestLotSize = 1;   // lots per harvest close
input group           "[DISCORD ANNOUNCEMENT SETTINGS]"
input string          DiscordAPIKey =  "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
input bool            EnableBroadcast = false;
CPortfolioRiskMan PortfolioRisk(VaRTimeframe, StdDevPeriods, VaRConfidence); // Darwinex VaR wrapper
// global vars
double TP = 0, SL = 0, Bid = 0, Ask = 0, prevBidPrice = 0.0,
       prevAskPrice = 0.0, order_risk_money = 0, AccountBalance = 0,
       required_margin = 0, AccountEquity = 0, percent_risk = 0;
bool EquityTPCalled = false,
     EquitySLCalled = false, breakEvenFoundLong = false, breakEvenFoundShort = false,
     breakEvenFound = false;
int OrderDigits = 0;
ENUM_ORDER_TYPE_FILLING g_cachedFillMode = (ENUM_ORDER_TYPE_FILLING)-1;
// Dashboard cache (file-scope for reset on reinit)
string g_prevInfoRR = "", g_prevInfoPL = "", g_prevInfoSLPL = "",
       g_prevInfoTP = "", g_prevInfoRisk = "", g_prevInfoTPRR = "",
       g_prevInfoH4 = "", g_prevInfoW1 = "", g_prevInfoD1 = "", g_prevInfoMN1 = "";
datetime g_lastTimerUpdate = 0;
double g_prevLongLots = -1, g_prevShortLots = -1;
string g_cachedVaRStr = "VaR %: 0.00", g_cachedPositionStr = "";
enum MartingaleState { MG_OFF, MG_LONG, MG_SHORT, MG_UNWIND };
MartingaleState MartingaleMode = MG_OFF;
datetime LastMartingaleTime = 0;
datetime g_lastMGLogTime = 0;
int MartingaleHedgeCloses = 0;
int MartingaleBiasCloses = 0;
bool HarvestEnabled = false;
int MartingaleHarvestCloses = 0;
datetime g_lastOppCloseTime = 0;
double g_cachedChunkSize = 0, g_cachedUnwindLots = 0, g_cachedHarvestLots = 0;
#define INDENT_LEFT       (10)      // indent from left (with allowance for border width)
#define INDENT_TOP        (10)      // indent from top (with allowance for border width)
#define CONTROLS_GAP_X    (5)       // gap by X coordinate
#define BUTTON_WIDTH      (100)     // size by X coordinate
#define BUTTON_HEIGHT     (20)      // size by Y coordinate
#define CONTROLS_GAP_Y    (23)      // gap by Y coordinate
class TyWindow : public CAppDialog
{
   protected:
   private:
      CButton           buttonTrade;
      CButton           buttonMartingale;
      CButton           buttonBuyLines;
      CButton           buttonSellLines;
      CButton           buttonDestroyLines;
      CButton           buttonHarvest;
      CButton           buttonCloseAll;
      CButton           buttonClosePartial;
      CButton           buttonSetSL;
      CButton           buttonSetTP;
   public:
      TyWindow(void);
      ~TyWindow(void);
      void ExecuteBuyOrder(double lots);
      void ExecuteSellOrder(double lots);
      void MartingaleButtonText(string text);
      void MartingaleButtonColor(color clr);
      void HarvestButtonText(string text);
      void HarvestButtonColor(color clr);
      virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
      // handlers of drag
      virtual bool      OnDialogDragStart(void);
      virtual bool      OnDialogDragProcess(void);
      virtual bool      OnDialogDragEnd(void);
      // chart event handler
      virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   protected:
      // create dependent controls
      bool              CreateButtonTrade(void);
      bool              CreateButtonMartingale(void);
      bool              CreateButtonBuyLines(void);
      bool              CreateButtonSellLines(void);
      bool              CreateButtonDestroyLines(void);
      bool              CreateButtonHarvest(void);
      bool              CreateButtonCloseAll(void);
      bool              CreateButtonClosePartial(void);
      bool              CreateButtonSetSL(void);
      bool              CreateButtonSetTP(void);
      // handlers of the dependent controls events
      void              OnClickTrade(void);
      void              OnClickMartingale(void);
      void              OnClickBuyLines(void);
      void              OnClickSellLines(void);
      void              OnClickDestroyLines(void);
      void              OnClickHarvest(void);
      void              OnClickCloseAll(void);
      void              OnClickClosePartial(void);
      void              OnClickSetSL(void);
      void              OnClickSetTP(void);
};
// Event Handling
EVENT_MAP_BEGIN(TyWindow)
ON_EVENT(ON_CLICK, buttonTrade, OnClickTrade)
ON_EVENT(ON_CLICK, buttonMartingale, OnClickMartingale)
ON_EVENT(ON_CLICK, buttonBuyLines, OnClickBuyLines)
ON_EVENT(ON_CLICK, buttonSellLines, OnClickSellLines)
ON_EVENT(ON_CLICK, buttonDestroyLines, OnClickDestroyLines)
ON_EVENT(ON_CLICK, buttonHarvest, OnClickHarvest)
ON_EVENT(ON_CLICK, buttonCloseAll, OnClickCloseAll)
ON_EVENT(ON_CLICK, buttonClosePartial, OnClickClosePartial)
ON_EVENT(ON_CLICK, buttonSetSL, OnClickSetSL)
ON_EVENT(ON_CLICK, buttonSetTP, OnClickSetTP)
EVENT_MAP_END(CAppDialog)
// Constructor
TyWindow::TyWindow(void){}
// Destructor
TyWindow::~TyWindow(void){}
bool TyWindow::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
{
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2)){ return(false); }
   // create dependent controls
   if(!CreateButtonTrade()) { return(false); }
   if(!CreateButtonMartingale()){ return(false); }
   if(!CreateButtonBuyLines()){ return(false); }
   if(!CreateButtonSellLines()){ return(false); }
   if(!CreateButtonDestroyLines()){ return(false); }
   if(!CreateButtonHarvest()) { return(false); }
   if(!CreateButtonCloseAll()){ return(false); }
   if(!CreateButtonClosePartial()){ return(false); }
   if(!CreateButtonSetSL()){ return(false); }
   if(!CreateButtonSetTP()){ return(false); }
   return(true);
}
// Global Variable
TyWindow ExtDialog;
void CreateAndSetObjectProperties(string name, int xDistance, int yDistance, int corner = CORNER_RIGHT_UPPER, color textColor = clrWhite)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_FONT, "Courier New");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xDistance);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yDistance);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
}
int OnInit()
{
   if (!IsTradeAllowed(_Symbol))
   {
      return INIT_FAILED; // Exit if trading is not allowed
   }
   if (MartingaleCloseChunkSize <= 0)
   {
      Print("MartingaleCloseChunkSize must be > 0");
      return INIT_FAILED;
   }
   if (MartingaleCooldown < 1)
   {
      Print("MartingaleCooldown must be >= 1");
      return INIT_FAILED;
   }
   if (MartingaleUnwindLotSize <= 0)
   {
      Print("MartingaleUnwindLotSize must be > 0");
      return INIT_FAILED;
   }
   if (MartingaleHarvestLotSize <= 0)
   {
      Print("MartingaleHarvestLotSize must be > 0");
      return INIT_FAILED;
   }
   if (MarginBufferPercent < 0 || MarginBufferPercent >= 100)
   {
      Print("MarginBufferPercent must be >= 0 and < 100");
      return INIT_FAILED;
   }
   if (VaRConfidence <= 0 || VaRConfidence >= 1)
   {
      Print("VaRConfidence must be between 0 and 1 exclusive");
      return INIT_FAILED;
   }
   if (StdDevPeriods < 2)
   {
      Print("StdDevPeriods must be >= 2");
      return INIT_FAILED;
   }
   g_cachedFillMode = SelectFillingMode();
   if ((int)g_cachedFillMode != -1)
      Trade.SetTypeFilling(g_cachedFillMode);
   Trade.SetExpertMagicNumber(MagicNumber);
   // Get the volume step for the current symbol
   double volumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   // Convert the volume step to a string
   string volumeStepStr = DoubleToString(volumeStep, 8); // 8 decimal places should be enough
   // Find the position of the decimal point
   int decimalPos = StringFind(volumeStepStr, ".");
   // If there is a decimal point, calculate the number of digits after it
   if (decimalPos >= 0)
   {
      // Calculate the number of digits after the decimal point
      OrderDigits = StringLen(volumeStepStr) - decimalPos - 1;
      // Trim trailing zeros to get the exact number of digits
      while (StringSubstr(volumeStepStr, StringLen(volumeStepStr) - 1, 1) == "0")
      {
         volumeStepStr = StringSubstr(volumeStepStr, 0, StringLen(volumeStepStr) - 1);
         OrderDigits--;
      }
      if (OrderDigits < 0) OrderDigits = 0;
   }
   // Cache NormalizeDouble on input constants (invariant at runtime)
   g_cachedChunkSize = NormalizeDouble(MartingaleCloseChunkSize, OrderDigits);
   g_cachedUnwindLots = NormalizeDouble(MartingaleUnwindLotSize, OrderDigits);
   g_cachedHarvestLots = NormalizeDouble(MartingaleHarvestLotSize, OrderDigits);
   g_lastOppCloseTime = 0;
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   int LeftColumnX = 310;
   int RightColumnX = 150;
   int YRowWidth = 13;
   CreateAndSetObjectProperties("infoPosition", LeftColumnX, YRowWidth * 2);
   CreateAndSetObjectProperties("infoVaR", RightColumnX, YRowWidth * 2);
   CreateAndSetObjectProperties("infoRisk", RightColumnX, YRowWidth * 3);
   CreateAndSetObjectProperties("infoPL", LeftColumnX, YRowWidth * 3);
   CreateAndSetObjectProperties("infoSLPL", RightColumnX, YRowWidth * 4);
   CreateAndSetObjectProperties("infoTP", LeftColumnX, YRowWidth * 4);
   CreateAndSetObjectProperties("infoTPRR", RightColumnX, YRowWidth * 5);
   CreateAndSetObjectProperties("infoRR", LeftColumnX, YRowWidth * 5);
   CreateAndSetObjectProperties("infoH4", LeftColumnX, YRowWidth * 6);
   CreateAndSetObjectProperties("infoW1", LeftColumnX, YRowWidth * 7);
   CreateAndSetObjectProperties("infoD1", RightColumnX, YRowWidth * 6);
   CreateAndSetObjectProperties("infoMN1", RightColumnX, YRowWidth * 7);
   string infoPosition = "No Positions Detected";
   ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
   ObjectSetString(0, "infoVaR", OBJPROP_TEXT, "VaR %: 0.00");
   ObjectSetString(0, "infoRisk", OBJPROP_TEXT, "Risk: $0.00");
   ObjectSetString(0, "infoPL", OBJPROP_TEXT, "Total P/L: $0.00");
   ObjectSetString(0, "infoSLPL", OBJPROP_TEXT, "SL P/L: $0.00");
   ObjectSetString(0, "infoTP", OBJPROP_TEXT, "TP P/L : $0.00");
   ObjectSetString(0, "infoTPRR", OBJPROP_TEXT, "TP RR: N/A");
   ObjectSetString(0, "infoRR", OBJPROP_TEXT, "RR : N/A");
   ObjectSetString(0, "infoH4", OBJPROP_TEXT, "H4 : " + TimeTilNextBar(PERIOD_H4));
   ObjectSetString(0, "infoW1", OBJPROP_TEXT, "W1 : " + TimeTilNextBar(PERIOD_W1));
   ObjectSetString(0, "infoD1", OBJPROP_TEXT, "D1 : " + TimeTilNextBar(PERIOD_D1));
   ObjectSetString(0, "infoMN1", OBJPROP_TEXT, "MN1: " + TimeTilNextBar(PERIOD_MN1));
   // Reset dashboard cache on reinit
   g_prevInfoRR = ""; g_prevInfoPL = ""; g_prevInfoSLPL = "";
   g_prevInfoTP = ""; g_prevInfoRisk = ""; g_prevInfoTPRR = "";
   g_prevInfoH4 = ""; g_prevInfoW1 = ""; g_prevInfoD1 = ""; g_prevInfoMN1 = "";
   g_lastTimerUpdate = 0;
   g_prevLongLots = -1; g_prevShortLots = -1;
   g_cachedVaRStr = "VaR %: 0.00"; g_cachedPositionStr = "";
   g_lastMGLogTime = 0;
   EquityTPCalled = false; EquitySLCalled = false;
   double var_1_lot = 0.0;
   if(PortfolioRisk.CalculateVaR(_Symbol, 1.0))
   {
      var_1_lot = PortfolioRisk.SinglePositionVaR;
      infoPosition = "VaR 1 lot: " + DoubleToString(var_1_lot, 2);
      ObjectSetString(0, "infoPosition", OBJPROP_TEXT, infoPosition);
   }
   if(!ExtDialog.Create(0,"TyphooN Risk Management",0,40,40,272,200))
      return(INIT_FAILED);
   ExtDialog.Run();
      return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   ExtDialog.Destroy(reason);
   ObjectsDeleteAll(0, "info");
}
string TimeTilNextBar(ENUM_TIMEFRAMES tf=PERIOD_CURRENT)
{
   datetime now = TimeCurrent();
   datetime bartime = iTime(NULL, tf, 0);
   if (bartime == 0) return "N/A";
   long remainingTime = (long)(bartime + PeriodSeconds(tf) - now);
   // Ensure non-negativity
   if (remainingTime < 0) remainingTime = 0;
   long days = remainingTime / 86400; // 86400 seconds in a day
   long hours = (remainingTime % 86400) / 3600; // 3600 seconds in an hour
   long minutes = (remainingTime % 3600) / 60; // 60 seconds in a minute
   long seconds = remainingTime % 60;
   if (days > 0) return StringFormat("%ldD %ldH %ldM", days, hours, minutes);
   if (hours > 0) return StringFormat("%ldH %ldM %lds", hours, minutes, seconds);
   if (minutes > 0) return StringFormat("%ldM %lds", minutes, seconds);
   return StringFormat("%lds", seconds);
}
bool CloseAllPositionsOnAllSymbols()
{
   Trade.SetAsyncMode(true);
   int totalPositions = PositionsTotal();
   if (totalPositions == 0)
   {
      Trade.SetAsyncMode(false);
      Print("No open positions to close.");
      return true;  // No need to proceed if there are no positions
   }
   for (int i = totalPositions - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      string symbol = PositionGetString(POSITION_SYMBOL);
      double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
      double positionProfit = PositionGetDouble(POSITION_PROFIT);
      double lotSize = PositionGetDouble(POSITION_VOLUME);
      if (Trade.PositionClose(ticket))
      {
         if (positionProfit >= 0)
         {
            Print("Closing [" + symbol + "] Position #", ticket, " (lot size: ", lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a profit of $", DoubleToString(positionProfit, 2));
         }
         else
         {
            Print("Closing [" + symbol + "] Position #", ticket, " (lot size: ", lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a loss of -$", MathAbs(positionProfit));
         }
      }
      else
      {
         Print("[" + symbol + "] Position #", ticket, " close failed asynchronously with error ", GetLastError());
         // Do not return false immediately for asynchronous processing
      }
   }
   // Wait for the asynchronous operations to complete by polling filtered position count
   int timeout = 3000;
   uint startTime = GetTickCount();
   while ((GetTickCount() - startTime) < (uint) timeout)
   {
      int remaining = 0;
      for (int j = PositionsTotal() - 1; j >= 0; j--)
      {
         ulong t = PositionGetTicket(j);
         if (t == 0) continue;
         if (!PositionSelectByTicket(t)) continue;
         if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         remaining++;
      }
      if (remaining == 0) break;
      Sleep(100);
   }
   Trade.SetAsyncMode(false);
   // Final filtered count check
   int finalRemaining = 0;
   for (int j = PositionsTotal() - 1; j >= 0; j--)
   {
      ulong t = PositionGetTicket(j);
      if (t == 0) continue;
      if (!PositionSelectByTicket(t)) continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      finalRemaining++;
   }
   if (finalRemaining == 0)
   {
      Print("All positions closed successfully.");
      return true;
   }
   else
   {
      Print("Failed to close all positions within the specified timeout.");
      return false;
   }
}
void GetSLTPFromAnotherPosition(ulong ticket, double &sl, double &tp, int positionTypeFilter = -1)
{
   int total = PositionsTotal();
   for (int j = 0; j < total; j++)
   {
      ulong other_ticket = PositionGetTicket(j);
      if (other_ticket == 0) continue;
      if (other_ticket != ticket && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
         // Only copy SL/TP from same-direction positions when filter is specified
         if (positionTypeFilter != -1 && (int)PositionGetInteger(POSITION_TYPE) != positionTypeFilter)
            continue;
         sl = PositionGetDouble(POSITION_SL);
         tp = PositionGetDouble(POSITION_TP);
         if (sl != 0 || tp != 0)
         {
            Print("SL/TP modified for ticket ", ticket, ": SL=", sl, ", TP=", tp, " based on another position ticket ", other_ticket);
            break; // Stop if a valid SL or TP is found
         }
      }
   }
}
// Define a structure to hold the lots information
struct LotsInfo
{
   double longLots;
   double shortLots;
};
bool IsTradeAllowed(const string symbol)
{
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("Trading is not allowed on this account.");
      return false;
   }
   if (SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
   {
      Print("Trading is not allowed for symbol: ", symbol);
      return false;
   }
   return true;
}
void OnTick()
{
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // Check if both bid and ask prices have changed from the previous tick
   if (Bid == prevBidPrice && Ask == prevAskPrice)
   {
      return;
   }
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   ProcessMartingale();
   prevBidPrice = Bid;
   prevAskPrice = Ask;
   double total_risk = 0;
   double total_pl = 0;
   double total_tp = 0;
   double rr = 0;
   double tprr = 0;
   double sl_risk = 0;
   if (AccountEquity >= TargetEquityTP && EnableEquityTP && !EquityTPCalled)
   {
      Print("Closing all positions across all symbols because Equity >= TargetEquityTP ($" + DoubleToString(TargetEquityTP, 2) + ").");
      if (CloseAllPositionsOnAllSymbols())
      {
        EquityTPCalled = true;
        AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        Alert("EquityTP closed all positions on all symbols. New account balance: " + DoubleToString(AccountBalance, 2));
      }
   }
   if (AccountEquity < TargetEquitySL && EnableEquitySL && !EquitySLCalled)
   {
      Print("Closing all positions across all symbols because Equity < TargetEquitySL ($" + DoubleToString(TargetEquitySL, 2) + ").");
      if (CloseAllPositionsOnAllSymbols())
      {
         EquitySLCalled = true;
         AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         Alert("EquitySL closed all positions on all symbols. New account balance: " + DoubleToString(AccountBalance, 2));
      }
   }
   // Reset per-direction break-even flags before the position loop
   breakEvenFoundLong = false;
   breakEvenFoundShort = false;
   LotsInfo lots;
   lots.longLots = 0.0;
   lots.shortLots = 0.0;
   double tickSz = TickSize(_Symbol);
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
      {
         // Cache position properties to avoid redundant calls
         double posVolume = PositionGetDouble(POSITION_VOLUME);
         double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double swap = PositionGetDouble(POSITION_SWAP);
         profit += swap;
         double risk = 0;
         double tpprofit = 0;
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         int posType = (int)PositionGetInteger(POSITION_TYPE);
         if (posType == POSITION_TYPE_BUY) lots.longLots += posVolume;
         else if (posType == POSITION_TYPE_SELL) lots.shortLots += posVolume;
         if (sl == 0 && tp == 0 && EnableUpdateEmptySLTP)
         {
            GetSLTPFromAnotherPosition(ticket, sl, tp, posType);
            if (sl != 0 || tp != 0)
            {
               if (!Trade.PositionModify(ticket, sl, tp))
               {
                  Print("Failed to modify position SL/TP: ", GetLastError());
               }
            }
         }
         // Track break-even per direction (flags reset above at start of tick)
         // Tick-round both sides to avoid ECN sub-tick fill mismatches
         double roundedSL = (tickSz > 0) ? MathRound(sl / tickSz) * tickSz : sl;
         double roundedOpen = (tickSz > 0) ? MathRound(posOpenPrice / tickSz) * tickSz : posOpenPrice;
         if (MathAbs(roundedSL - roundedOpen) < tickSz * 0.5)
         {
            if (posType == POSITION_TYPE_BUY)
               breakEvenFoundLong = true;
            else if (posType == POSITION_TYPE_SELL)
               breakEvenFoundShort = true;
         }
         if (sl != 0 || tp != 0)
         {
            ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            if (tp != 0)
            {
               if (!OrderCalcProfit(orderType, _Symbol, posVolume, posOpenPrice, tp, tpprofit))
                  Print("Error in OrderCalcProfit (TP): ", GetLastError());
            }
            if (sl != 0)
            {
               if (!OrderCalcProfit(orderType, _Symbol, posVolume, posOpenPrice, sl, risk))
                  Print("Error in OrderCalcProfit (SL): ", GetLastError());
            }
         }
         // Always include swap in total_risk (positive reduces risk, negative increases it)
         total_risk += swap;
         total_risk += risk;
         if (risk <= 0)
         {
            sl_risk += risk;
            sl_risk += swap;
         }
         total_pl += profit;
         total_tp += tpprofit;
      }
   }
   bool hasLongs = (lots.longLots > 0);
   bool hasShorts = (lots.shortLots > 0);
   double absRisk = MathAbs(total_risk);
   if (absRisk > 0)
   {
      tprr = total_tp / absRisk;
      rr = total_pl / absRisk;
   }
   if (AccountBalance > 0)
      percent_risk = MathAbs((sl_risk / AccountBalance) * 100);
   else
      percent_risk = 0;
   breakEvenFound = (breakEvenFoundLong || breakEvenFoundShort);
   // order_risk_money is computed direction-specifically in OnClickTrade before use
   string infoRisk;
   string infoPL;
   string infoRR;
   if (rr > 0)
      infoRR = "RR : " + DoubleToString(rr, 2);
   else
      infoRR = "RR : N/A";
   if (total_pl >= absRisk)
   {
      double floatingRisk = MathAbs(total_pl - total_risk);
      double floatingRiskPercent = (AccountBalance > 0) ? (floatingRisk / AccountBalance) * 100 : 0;
      infoRisk = "Risk: $" + DoubleToString(floatingRisk, 0) + " (" + DoubleToString(floatingRiskPercent, 1) + "%)";
   }
   else
   {
      infoRisk = "Risk: $" + DoubleToString(MathAbs(sl_risk), 0) + " (" + DoubleToString(percent_risk, 1) + "%)";
   }
   if (total_pl < 0)
      infoPL = "Total P/L: -$" + DoubleToString(MathAbs(total_pl), 2);
   else if (total_pl > 0)
      infoPL = "Total P/L: $" + DoubleToString(total_pl, 2);
   else
      infoPL = "Total P/L: $0.00";
   string infoSLPL;
   if (total_risk < 0)
      infoSLPL = "SL P/L: -$" + DoubleToString(absRisk, 2);
   else
      infoSLPL = "SL P/L: $" + DoubleToString(total_risk, 2);
   if(!hasLongs && !hasShorts)
      percent_risk = 0;
   // Only update labels when text actually changes (avoid redundant ObjectSetString calls)
   if (infoRR != g_prevInfoRR) { ObjectSetString(0,"infoRR",OBJPROP_TEXT,infoRR); g_prevInfoRR = infoRR; }
   if (infoPL != g_prevInfoPL) { ObjectSetString(0,"infoPL",OBJPROP_TEXT,infoPL); g_prevInfoPL = infoPL; }
   if (infoSLPL != g_prevInfoSLPL) { ObjectSetString(0,"infoSLPL",OBJPROP_TEXT,infoSLPL); g_prevInfoSLPL = infoSLPL; }
   string infoTP = "TP P/L : $" + DoubleToString(total_tp, 2);
   if (infoTP != g_prevInfoTP) { ObjectSetString(0,"infoTP",OBJPROP_TEXT,infoTP); g_prevInfoTP = infoTP; }
   if (infoRisk != g_prevInfoRisk) { ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk); g_prevInfoRisk = infoRisk; }
   string infoTPRR = "TP RR: " + DoubleToString(tprr, 2);
   if (infoTPRR != g_prevInfoTPRR) { ObjectSetString(0,"infoTPRR",OBJPROP_TEXT,infoTPRR); g_prevInfoTPRR = infoTPRR; }
   // Only update countdown timers once per second (iTime is expensive)
   datetime now = TimeCurrent();
   if (now != g_lastTimerUpdate)
   {
      g_lastTimerUpdate = now;
      string infoH4 = "H4 : " + TimeTilNextBar(PERIOD_H4);
      if (infoH4 != g_prevInfoH4) { ObjectSetString(0,"infoH4",OBJPROP_TEXT,infoH4); g_prevInfoH4 = infoH4; }
      string infoW1 = "W1 : " + TimeTilNextBar(PERIOD_W1);
      if (infoW1 != g_prevInfoW1) { ObjectSetString(0,"infoW1",OBJPROP_TEXT,infoW1); g_prevInfoW1 = infoW1; }
      string infoD1 = "D1 : " + TimeTilNextBar(PERIOD_D1);
      if (infoD1 != g_prevInfoD1) { ObjectSetString(0,"infoD1",OBJPROP_TEXT,infoD1); g_prevInfoD1 = infoD1; }
      string infoMN1 = "MN1: " + TimeTilNextBar(PERIOD_MN1);
      if (infoMN1 != g_prevInfoMN1) { ObjectSetString(0,"infoMN1",OBJPROP_TEXT,infoMN1); g_prevInfoMN1 = infoMN1; }
   }
   // Cache position display and VaR: only update when lot sizes change
   bool lotsChanged = (lots.longLots != g_prevLongLots || lots.shortLots != g_prevShortLots);
   if (lotsChanged)
   {
      if (lots.longLots > 0 && lots.shortLots == 0)
      {
         g_cachedPositionStr = "Long " + DoubleToString(lots.longLots, OrderDigits) + " Lots";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrLime);
         ObjectSetInteger(0,"infoVaR",OBJPROP_COLOR,clrLime);
         if (AccountEquity > 0 && PortfolioRisk.CalculateVaR(_Symbol, lots.longLots))
            g_cachedVaRStr = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity * 100), 2);
      }
      else if (lots.shortLots > 0 && lots.longLots == 0)
      {
         g_cachedPositionStr = "Short " + DoubleToString(lots.shortLots, OrderDigits) + " Lots";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,"infoVaR",OBJPROP_COLOR,clrRed);
         if (AccountEquity > 0 && PortfolioRisk.CalculateVaR(_Symbol, lots.shortLots))
            g_cachedVaRStr = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity * 100), 2);
      }
      else if (lots.shortLots > 0 && lots.longLots > 0)
      {
         double netExposure = MathAbs(lots.longLots - lots.shortLots);
         g_cachedPositionStr = DoubleToString(lots.longLots, OrderDigits) + " Long / " + DoubleToString(lots.shortLots, OrderDigits) + " Short";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrWhite);
         ObjectSetInteger(0,"infoVaR",OBJPROP_COLOR,clrWhite);
         if (netExposure > 0 && AccountEquity > 0 && PortfolioRisk.CalculateVaR(_Symbol, netExposure))
            g_cachedVaRStr = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity * 100), 2) + " (net)";
         else
            g_cachedVaRStr = "VaR %: 0.00 (hedged)";
      }
      else
      {
         double var_1_lot = 0.0;
         if(PortfolioRisk.CalculateVaR(_Symbol, 1.0))
         {
            var_1_lot = PortfolioRisk.SinglePositionVaR;
            g_cachedPositionStr = "VaR 1 lot: " + DoubleToString(var_1_lot, 2);
         }
         else
            g_cachedPositionStr = "No Positions Detected";
         g_cachedVaRStr = "VaR %: 0.00";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrWhite);
         ObjectSetInteger(0,"infoVaR",OBJPROP_COLOR,clrWhite);
      }
      ObjectSetString(0,"infoPosition",OBJPROP_TEXT,g_cachedPositionStr);
      ObjectSetString(0,"infoVaR",OBJPROP_TEXT,g_cachedVaRStr);
      g_prevLongLots = lots.longLots;
      g_prevShortLots = lots.shortLots;
   }
}
void OnChartEvent(const int id,         // event ID  
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
{
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
}
bool TyWindow::CreateButtonTrade(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonTrade.Create(0,"Open Trade",0,x1,y1,x2,y2))
      return(false);
   if(!buttonTrade.Text("Open Trade"))
      return(false);
   if(!Add(buttonTrade))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonMartingale(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonMartingale.Create(0,"MG: OFF",0,x1,y1,x2,y2))
      return(false);
   if(!buttonMartingale.Text("MG: OFF"))
      return(false);
   buttonMartingale.ColorBackground(clrDarkGray);
   if(!Add(buttonMartingale))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonBuyLines(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonBuyLines.Create(0,"Buy Lines",0,x1,y1,x2,y2))
      return(false);
   if(!buttonBuyLines.Text("Buy Lines"))
      return(false);
   if(!Add(buttonBuyLines))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonSellLines(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonSellLines.Create(0,"Sell Lines",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSellLines.Text("Sell Lines"))
      return(false);
   if(!Add(buttonSellLines))
      return(false);
   return(true);
} 
bool TyWindow::CreateButtonDestroyLines(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 2 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonDestroyLines.Create(0,"Destroy Lines",0,x1,y1,x2,y2))
      return(false);
   if(!buttonDestroyLines.Text("Destroy Lines"))
      return(false);
   if(!Add(buttonDestroyLines))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonHarvest(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 2 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonHarvest.Create(0,"HV: OFF",0,x1,y1,x2,y2))
      return(false);
   if(!buttonHarvest.Text("HV: OFF"))
      return(false);
   buttonHarvest.ColorBackground(clrDarkGray);
   if(!Add(buttonHarvest))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonCloseAll(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 3 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonCloseAll.Create(0,"Close All",0,x1,y1,x2,y2))
      return(false);
   if(!buttonCloseAll.Text("Close All"))
      return(false);
   if(!Add(buttonCloseAll))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonClosePartial(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 3 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonClosePartial.Create(0,"Close Partial",0,x1,y1,x2,y2))
      return(false);
   if(!buttonClosePartial.Text("Close Partial"))
      return(false);
   if(!Add(buttonClosePartial))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonSetSL(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 4 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 +BUTTON_HEIGHT;
   if(!buttonSetSL.Create(0,"Set SL",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetSL.Text("Set SL"))
      return(false);
   if(!Add(buttonSetSL))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonSetTP(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 4 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonSetTP.Create(0,"Set TP",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetTP.Text("Set TP"))
      return(false);
   if(!Add(buttonSetTP))
      return(false);
   return(true);
}
void BroadcastDiscordAnnouncement(string announcement)
{
   if (DiscordAPIKey == "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token")
   {
      Print("You cannot broadcast to Discord with the Default API key.  Create a webhook in your own Discord or contact TyphooN if you would like to broadcast in the Market Wizardry Discord.");
      return;
   }
   string headers = "Content-Type: application/json";
   uchar result[];
   string result_headers;
   string escaped = announcement;
   StringReplace(escaped, "\\", "\\\\");
   StringReplace(escaped, "\"", "\\\"");
   StringReplace(escaped, "\n", "\\n");
   StringReplace(escaped, "\r", "\\r");
   StringReplace(escaped, "\t", "\\t");
   string json = "{\"content\":\""+ escaped +"\"}";
   char jsonArray[];
   StringToCharArray(json, jsonArray);
   // Remove null-terminator if any
   int arrSize = ArraySize(jsonArray);
   if(arrSize > 0 && jsonArray[arrSize - 1] == '\0')
   {
      ArrayResize(jsonArray, arrSize - 1);
   }
   int httpCode = WebRequest("POST", DiscordAPIKey, headers, 5000, jsonArray, result, result_headers);
   if (httpCode == -1)
      Print("Discord webhook failed: ", GetLastError());
   else if (httpCode != 200 && httpCode != 204)
      Print("Discord webhook returned HTTP ", httpCode);
}
void TyWindow::ExecuteBuyOrder(double lots)
{
   if (Trade.Buy(lots, _Symbol, 0, SL, TP, NULL))
   {
      string MarketBuyText = "[" + _Symbol + "] Market Buy position opened. Price: " + DoubleToString(Ask, _Digits) +
      ", Lots: " + DoubleToString(lots, 2) + ", SL: " +  DoubleToString(SL, _Digits) + ", TP: " + DoubleToString(TP, _Digits);
      Print(MarketBuyText);
      if(EnableBroadcast)
      {
         BroadcastDiscordAnnouncement(MarketBuyText);
      }
   }
   else
   {
      Print("Failed to open buy trade, error: ", GetLastError());
   }
}
void TyWindow::ExecuteSellOrder(double lots)
{
   if (Trade.Sell(lots, _Symbol, 0, SL, TP, NULL))
   {
      string MarketSellText = "[" + _Symbol + "] Market Sell position opened. Price: " + DoubleToString(Bid, _Digits) +
         ", Lots: " + DoubleToString(lots, 2) + ", SL: " + DoubleToString(SL, _Digits) + ", TP: " + DoubleToString(TP, _Digits);
      Print(MarketSellText);
      if(EnableBroadcast)
      {
         BroadcastDiscordAnnouncement(MarketSellText);
      }
   }
   else
   {
      Print("Failed to open sell position, error: ", GetLastError());
   }
}
bool ProcessPositionCheck(ulong ticket, string symbol, int magicNumber)
{
    if (!PositionSelectByTicket(ticket))
        return false;
    if (PositionGetString(POSITION_SYMBOL) != symbol)
        return false;
    return ManageAllPositions || (PositionGetInteger(POSITION_MAGIC) == magicNumber);
}
bool HasOpenPosition(string sym, int orderType)
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != sym) continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if (PositionGetInteger(POSITION_TYPE) == orderType)
         return true;
   }
   return false;
}
double GetTotalVolumeForSymbol(string symbol)
{
   double totalVolume = 0;
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) == symbol)
      {
         if (ManageAllPositions || PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            totalVolume += PositionGetDouble(POSITION_VOLUME);
      }
   }
   return totalVolume;
}
double PerformOrderCheck(const MqlTradeRequest &request, MqlTradeCheckResult &check_result, double &OrderLots)
{
   if (!Trade.OrderCheck(request, check_result))
   {
      int retcode = (int)check_result.retcode;
      if (retcode == 10013)
      {
         Print("Invalid request. Check the request parameters.");
         return -1.0;
      }
      if (retcode == 10019 || retcode == 10030)
         return -1.0;
      Print("OrderCheck failed with retcode ", retcode, ": ", check_result.comment);
      return -1.0;
   }
   // OrderCheck successful, calculate and return the required margin
   double checkAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double checkBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double margin = 0;
   if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY) ? checkAsk : checkBid, margin))
   {
      Print("Failed to calculate required margin after successful OrderCheck. Error:", GetLastError());
      return -1.0;
   }
   return margin;
}
double CalculateMartingalePL()
{
   double totalPL = 0;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      totalPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return totalPL;
}
void CloseAllSymbolPositions()
{
   Trade.SetAsyncMode(true);
   int total = PositionsTotal();
   for (int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if (Trade.PositionClose(ticket))
         Print("Martingale equity TP: closed position #", ticket);
      else
         Print("Martingale equity TP: failed to close #", ticket, " error ", GetLastError());
   }
   // Poll for async completion
   uint startTime = GetTickCount();
   while ((GetTickCount() - startTime) < 3000)
   {
      int remaining = 0;
      for (int j = PositionsTotal() - 1; j >= 0; j--)
      {
         ulong t = PositionGetTicket(j);
         if (t == 0) continue;
         if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         remaining++;
      }
      if (remaining == 0) break;
      Sleep(100);
   }
   Trade.SetAsyncMode(false);
}
bool CloseProfitableOppositePositions()
{
   if (TimeCurrent() - g_lastOppCloseTime < MartingaleCooldown) return false;
   int closeType;
   if (MartingaleMode == MG_LONG)
      closeType = POSITION_TYPE_SELL;
   else if (MartingaleMode == MG_SHORT)
      closeType = POSITION_TYPE_BUY;
   else
      return false;
   bool closedAny = false;
   Trade.SetAsyncMode(true);
   int total = PositionsTotal();
   for (int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if ((int)PositionGetInteger(POSITION_TYPE) != closeType)
         continue;
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if (pl > 0)
      {
         double posVolume = PositionGetDouble(POSITION_VOLUME);
         string dir = (closeType == POSITION_TYPE_BUY) ? "LONG" : "SHORT";
         if (posVolume <= g_cachedChunkSize)
         {
            if (Trade.PositionClose(ticket))
            {
               Print("Martingale: closed ", dir, " #", ticket, " (", posVolume, " lots) P/L: $", DoubleToString(pl, 2));
               g_lastOppCloseTime = TimeCurrent();
               closedAny = true;
            }
            else
               Print("Martingale: failed to close #", ticket, " error ", GetLastError());
         }
         else
         {
            if (Trade.PositionClosePartial(ticket, g_cachedChunkSize))
            {
               Print("Martingale: partial close ", dir, " #", ticket, " (", g_cachedChunkSize, " of ", posVolume, " lots)");
               g_lastOppCloseTime = TimeCurrent();
               closedAny = true;
            }
            else
               Print("Martingale: failed to partial close #", ticket, " error ", GetLastError());
         }
      }
   }
   if (closedAny)
   {
      for (int poll = 0; poll < 50; poll++)
      {
         int remaining = 0;
         int posTotal = PositionsTotal();
         for (int j = posTotal - 1; j >= 0; j--)
         {
            ulong t = PositionGetTicket(j);
            if (t == 0) continue;
            if (!PositionSelectByTicket(t)) continue;
            if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
            if ((int)PositionGetInteger(POSITION_TYPE) == closeType)
            {
               double pl2 = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
               if (pl2 > 0) remaining++;
            }
         }
         if (remaining == 0) break;
         Sleep(100);
      }
   }
   Trade.SetAsyncMode(false);
   return closedAny;
}
void UnwindMartingale()
{
   if (TimeCurrent() - LastMartingaleTime < MartingaleCooldown)
      return;
   ulong worstTicket = 0;
   double worstPL = DBL_MAX;
   bool found = false;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if (pl < worstPL)
      {
         worstPL = pl;
         worstTicket = ticket;
         found = true;
      }
   }
   if (!found)
   {
      MartingaleMode = MG_OFF;
      UpdateMartingaleButton();
      Print("Martingale unwind complete — no positions remain.");
      return;
   }
   if (Trade.PositionClose(worstTicket))
      Print("Martingale unwind: closed #", worstTicket, " P/L: $", DoubleToString(worstPL, 2));
   else
      Print("Martingale unwind: failed to close #", worstTicket, " error ", GetLastError());
   LastMartingaleTime = TimeCurrent();
}
double CalculateMarginUsagePct()
{
   double freshEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if (freshEquity <= 0.01) return 100.0;
   return AccountInfoDouble(ACCOUNT_MARGIN) / freshEquity * 100.0;
}
bool UnwindHedgeByMargin()
{
   // Determine hedge type: MG_SHORT → hedges are BUYs, MG_LONG → hedges are SELLs
   int hedgeType;
   if (MartingaleMode == MG_SHORT)
      hedgeType = POSITION_TYPE_BUY;
   else if (MartingaleMode == MG_LONG)
      hedgeType = POSITION_TYPE_SELL;
   else
      return false;
   // Find largest hedge position (frees the most margin when closed), open price as tiebreaker
   ulong bestTicket = 0;
   double highestOpen = -1;
   double bestVolume = 0;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if ((int)PositionGetInteger(POSITION_TYPE) != hedgeType)
         continue;
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double vol = PositionGetDouble(POSITION_VOLUME);
      if (vol > bestVolume || (vol == bestVolume && openPrice > highestOpen))
      {
         highestOpen = openPrice;
         bestTicket = ticket;
         bestVolume = vol;
      }
   }
   if (bestTicket == 0)
      return false;
   string dir = (hedgeType == POSITION_TYPE_BUY) ? "LONG hedge" : "SHORT hedge";
   bool result;
   if (bestVolume <= g_cachedUnwindLots)
      result = Trade.PositionClose(bestTicket);
   else
      result = Trade.PositionClosePartial(bestTicket, g_cachedUnwindLots);
   if (result)
   {
      MartingaleHedgeCloses++;
      double marginPct = CalculateMarginUsagePct();
      Print("Martingale TRIM: closed ", dir, " #", bestTicket,
            " (", (bestVolume <= g_cachedUnwindLots) ? bestVolume : g_cachedUnwindLots, " lots, entry: ", DoubleToString(highestOpen, _Digits),
            ") margin: ", DoubleToString(marginPct, 1), "% | trim closes: ", MartingaleHedgeCloses);
   }
   else
      Print("Martingale TRIM: failed to close ", dir, " #", bestTicket, " error ", GetLastError());
   return result;
}
bool ProtectivePartialCloseBias()
{
   // Determine bias type: MG_SHORT → bias is SELLs, MG_LONG → bias is BUYs
   int biasType;
   if (MartingaleMode == MG_SHORT)
      biasType = POSITION_TYPE_SELL;
   else if (MartingaleMode == MG_LONG)
      biasType = POSITION_TYPE_BUY;
   else
      return false;
   // Find largest bias position (frees the most margin when closed), open price as tiebreaker
   ulong bestTicket = 0;
   double highestOpen = -1;
   double bestVolume = 0;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if ((int)PositionGetInteger(POSITION_TYPE) != biasType)
         continue;
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double vol = PositionGetDouble(POSITION_VOLUME);
      if (vol > bestVolume || (vol == bestVolume && openPrice > highestOpen))
      {
         highestOpen = openPrice;
         bestTicket = ticket;
         bestVolume = vol;
      }
   }
   if (bestTicket == 0)
      return false;
   string dir = (biasType == POSITION_TYPE_BUY) ? "LONG bias" : "SHORT bias";
   bool result;
   if (bestVolume <= g_cachedChunkSize)
      result = Trade.PositionClose(bestTicket);
   else
      result = Trade.PositionClosePartial(bestTicket, g_cachedChunkSize);
   if (result)
   {
      MartingaleBiasCloses++;
      double marginPct = CalculateMarginUsagePct();
      Print("Martingale PROTECT: closed ", dir, " #", bestTicket,
            " (", (bestVolume <= g_cachedChunkSize) ? bestVolume : g_cachedChunkSize, " of ", bestVolume, " lots, entry: ", DoubleToString(highestOpen, _Digits),
            ") margin: ", DoubleToString(marginPct, 1), "% | protect closes: ", MartingaleBiasCloses);
   }
   else
      Print("Martingale PROTECT: failed to close ", dir, " #", bestTicket, " error ", GetLastError());
   return result;
}
bool HarvestProfitableBias()
{
   int biasType;
   if (MartingaleMode == MG_SHORT)
      biasType = POSITION_TYPE_SELL;
   else if (MartingaleMode == MG_LONG)
      biasType = POSITION_TYPE_BUY;
   else
      return false;
   ulong bestTicket = 0;
   double bestProfit = 0;
   double bestVolume = 0;
   double bestOpen = 0;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if ((int)PositionGetInteger(POSITION_TYPE) != biasType)
         continue;
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if (pl > bestProfit)
      {
         bestProfit = pl;
         bestTicket = ticket;
         bestVolume = PositionGetDouble(POSITION_VOLUME);
         bestOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      }
   }
   if (bestTicket == 0)
      return false;
   string dir = (biasType == POSITION_TYPE_BUY) ? "LONG bias" : "SHORT bias";
   bool result;
   if (bestVolume <= g_cachedHarvestLots)
      result = Trade.PositionClose(bestTicket);
   else
      result = Trade.PositionClosePartial(bestTicket, g_cachedHarvestLots);
   if (result)
   {
      MartingaleHarvestCloses++;
      double marginPct = CalculateMarginUsagePct();
      Print("Martingale HARVEST: closed ", dir, " #", bestTicket,
            " (", (bestVolume <= g_cachedHarvestLots) ? bestVolume : g_cachedHarvestLots, " of ", bestVolume, " lots, entry: ", DoubleToString(bestOpen, _Digits),
            ", P/L: $", DoubleToString(bestProfit, 2),
            ") margin: ", DoubleToString(marginPct, 1), "% | harvest closes: ", MartingaleHarvestCloses);
   }
   else
      Print("Martingale HARVEST: failed to close ", dir, " #", bestTicket, " error ", GetLastError());
   return result;
}
void LogMartingaleUnwindStatus(double marginPctArg = -1)
{
   if (TimeCurrent() - g_lastMGLogTime < 60)
      return;
   g_lastMGLogTime = TimeCurrent();
   string biasDir = (MartingaleMode == MG_LONG) ? "LONG" : "SHORT";
   int hedgeType = (MartingaleMode == MG_SHORT) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   int biasType = (MartingaleMode == MG_SHORT) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   int hedgeCount = 0, biasCount = 0;
   double hedgeLots = 0, biasLots = 0;
   int total = PositionsTotal();
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      int pType = (int)PositionGetInteger(POSITION_TYPE);
      double vol = PositionGetDouble(POSITION_VOLUME);
      if (pType == hedgeType) { hedgeCount++; hedgeLots += vol; }
      else if (pType == biasType) { biasCount++; biasLots += vol; }
   }
   double marginPct = (marginPctArg >= 0) ? marginPctArg : CalculateMarginUsagePct();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   Print("=== Martingale Unwind Status [", biasDir, "] ===",
         " | Margin: ", DoubleToString(marginPct, 1), "%",
         " (TRIM>=", DoubleToString(MartingaleUnwindMarginPct, 1),
         "% HARVEST>=", DoubleToString(MartingaleHarvestMarginPct, 1),
         "% PROTECT>=", DoubleToString(MartingaleDangerMarginPct, 1), "%)",
         " | Hedge: ", hedgeCount, " pos / ", DoubleToString(hedgeLots, OrderDigits), " lots",
         " | Bias: ", biasCount, " pos / ", DoubleToString(biasLots, OrderDigits), " lots",
         " | Closes: trim=", MartingaleHedgeCloses, " harvest=", MartingaleHarvestCloses, " protect=", MartingaleBiasCloses,
         " | Equity: $", DoubleToString(equity, 2), " Margin: $", DoubleToString(margin, 2));
}
void PrintMartingaleStrategyBriefing(MartingaleState state)
{
   string biasDir = (state == MG_LONG) ? "LONG" : "SHORT";
   string coreType = (state == MG_LONG) ? "BUY" : "SELL";
   string hedgeType = (state == MG_LONG) ? "SELL" : "BUY";
   double marginPct = CalculateMarginUsagePct();
   // Dry run detection: check if market is closed
   datetime lastTick = (datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
   bool marketClosed = (TimeCurrent() - lastTick > 60);
   if (marketClosed)
      Print("[DRY RUN — Market closed] Strategy preview only, no trades will execute.");
   Print("=== MARTINGALE STRATEGY ENABLED: ", biasDir, " on ", _Symbol, " ===");
   Print("Bias direction : ", biasDir, " — we hold ", coreType, " positions as core");
   Print("Hedge direction: ", hedgeType, " — opposite positions to be trimmed");
   Print("");
   Print("TRIM  (hedge removal):");
   if (MartingaleUnwindMarginPct > 0)
      Print("  Threshold : margin >= ", DoubleToString(MartingaleUnwindMarginPct, 1), "%");
   else
      Print("  Threshold : DISABLED (MartingaleUnwindMarginPct=0)");
   Print("  Action    : partial close ", DoubleToString(MartingaleUnwindLotSize, OrderDigits), " lots of highest-cost ", hedgeType);
   Print("  Goal      : reduce margin usage by removing expensive hedges");
   Print("");
   Print("HARVEST (profit banking — post-trim):");
   if (MartingaleHarvestMarginPct > 0)
      Print("  Threshold : margin >= ", DoubleToString(MartingaleHarvestMarginPct, 1), "%");
   else
      Print("  Threshold : DISABLED (MartingaleHarvestMarginPct=0)");
   Print("  Action    : partial close ", DoubleToString(MartingaleHarvestLotSize, OrderDigits), " lots of most profitable ", coreType);
   Print("  Goal      : bank profits and reduce margin after hedges exhausted");
   Print("  Toggle    : ", (HarvestEnabled ? "ENABLED" : "DISABLED"), " (button controlled)");
   Print("");
   Print("PROTECT (bias closure — emergency):");
   if (MartingaleDangerMarginPct > 0)
      Print("  Threshold : margin >= ", DoubleToString(MartingaleDangerMarginPct, 1), "%");
   else
      Print("  Threshold : DISABLED (MartingaleDangerMarginPct=0)");
   Print("  Action    : partial close ", DoubleToString(MartingaleCloseChunkSize, OrderDigits), " lots of highest-cost ", coreType);
   Print("  Goal      : prevent margin call by reducing core position size");
   Print("");
   Print("Profit banking : close profitable ", hedgeType, " positions every tick");
   if (MartingaleEquityTP > 0)
      Print("Equity TP      : close all at $", DoubleToString(MartingaleEquityTP, 2), " profit");
   else
      Print("Equity TP      : DISABLED (MartingaleEquityTP=0)");
   Print("Cooldown       : ", MartingaleCooldown, "s between margin operations");
   Print("Current margin : ", DoubleToString(marginPct, 1), "%");
}
void ProcessMartingale()
{
   if (MartingaleMode == MG_OFF)
      return;
   if (MartingaleMode == MG_UNWIND)
   {
      UnwindMartingale();
      return;
   }
   // Bank profit on opposite-direction positions every tick
   bool closedOpposites = CloseProfitableOppositePositions();
   // Equity TP on all symbol positions (skip if async closes in flight — P/L is stale)
   if (MartingaleEquityTP > 0 && !closedOpposites)
   {
      double mgPL = CalculateMartingalePL();
      if (mgPL >= MartingaleEquityTP)
      {
         Print("Martingale equity TP reached: $", DoubleToString(mgPL, 2),
               " >= $", DoubleToString(MartingaleEquityTP, 2));
         CloseAllSymbolPositions();
         MartingaleMode = MG_OFF;
         UpdateMartingaleButton();
         return;
      }
   }
   // Cooldown gate for margin-based operations
   if (TimeCurrent() - LastMartingaleTime < MartingaleCooldown)
      return;
   // Periodic status log + single margin fetch for this tick
   double marginUsage = CalculateMarginUsagePct();
   LogMartingaleUnwindStatus(marginUsage);
   // Tier 2: emergency bias close (check first — higher priority)
   if (MartingaleDangerMarginPct > 0 && marginUsage >= MartingaleDangerMarginPct)
   {
      if (ProtectivePartialCloseBias())
      {
         LastMartingaleTime = TimeCurrent();
         return;
      }
   }
   // Tier 1: unwind hedges
   if (MartingaleUnwindMarginPct > 0 && marginUsage >= MartingaleUnwindMarginPct)
   {
      if (UnwindHedgeByMargin())
      {
         LastMartingaleTime = TimeCurrent();
         return;
      }
      // TRIM found no hedges — fall through to HARVEST
   }
   // HARVEST: bank profit on bias positions when no hedges remain
   if (HarvestEnabled && MartingaleHarvestMarginPct > 0 && marginUsage >= MartingaleHarvestMarginPct)
   {
      if (HarvestProfitableBias())
      {
         LastMartingaleTime = TimeCurrent();
         return;
      }
   }
}
void TyWindow::OnClickTrade(void)
{
   SL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
   TP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   if (SL <= 0 || TP <= 0)
   {
      Print("SL and TP lines must both be placed on the chart before opening a trade.");
      return;
   }
   // Refresh account state (may be stale if no ticks since last OnTick)
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double tickSize = TickSize(_Symbol);
   if (tickSize <= 0) { Print("Invalid tick size"); return; }
   SL = MathRound(SL / tickSize) * tickSize;
   TP = MathRound(TP / tickSize) * tickSize;
   double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double limit_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   double existing_volume = GetTotalVolumeForSymbol(_Symbol);
   double usable_margin = 0;
   double potentialRisk = 0; // Only meaningful for Standard mode; other modes bypass MaxRisk check
   // Use direction-specific breakeven flag for the trade being placed
   bool dirBreakEven = (TP > SL) ? breakEvenFoundLong : breakEvenFoundShort;
   if (OrderMode == Standard)
   {
      double OrderRisk;
      if (dirBreakEven)
      {
         potentialRisk = (Risk * AdditionalRiskRatio);
         OrderRisk = (Risk * AdditionalRiskRatio);
      }
      else
      {
         potentialRisk = Risk + percent_risk;
         OrderRisk = Risk;
      }
      if (potentialRisk > MaxRisk)
      {
         OrderRisk = (MaxRisk - percent_risk);
         if (OrderRisk <= 0)
         {
            Print("MaxRisk ", MaxRisk, "% already consumed by current risk ", DoubleToString(percent_risk, 2), "%. Not placing order.");
            return;
         }
         potentialRisk = OrderRisk + percent_risk;
      }
      order_risk_money = (AccountBalance * (OrderRisk / 100));
      if (dirBreakEven && percent_risk > 0)
      {
         Print("Break Even positions found, and a risk position already placed. Not placing additional order.");
         return;
      }
   }
   if (OrderMode == Dynamic)
   {
      if (AccountBalance <= MinAccountBalance)
      {
         Print("Account balance (", DoubleToString(AccountBalance, 2), ") at or below MinAccountBalance (", DoubleToString(MinAccountBalance, 2), "). Not placing order.");
         return;
      }
      if (dirBreakEven)
      {
         order_risk_money = (AdditionalRiskRatio > 0 && LossesToMinBalance > 0) ? ((AccountBalance - MinAccountBalance) / (LossesToMinBalance / AdditionalRiskRatio)) : 0;
      }
      else
      {
         order_risk_money = (LossesToMinBalance > 0) ? ((AccountBalance - MinAccountBalance) / LossesToMinBalance) : 0;
      }
      if (!dirBreakEven)
      {
         if (HasOpenPosition(_Symbol, (TP > SL) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         {
            Print("Another position is already open with the same order type on the symbol. Not placing additional order.");
            return;
         }
      }
      if (dirBreakEven && percent_risk > 0)
      {
         Print("Break Even positions found, and a risk position already placed. Not placing additional order.");
         return;
      }
   }
   double available_volume;
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if (min_volume <= 0)
   {
      Print("SYMBOL_VOLUME_MIN is zero or negative. Cannot place order.");
      return;
   }
   if (limit_volume > 0 && existing_volume >= limit_volume)
   {
      Print("Existing volume (", existing_volume, ") already at or above limit volume (", limit_volume, "). Not placing additional order.");
      return;
   }
   if (limit_volume > 0)
      available_volume = limit_volume - existing_volume;
   else
      available_volume = max_volume;
   double OrderLots = 0.0;
   if (OrderMode == Fixed)
   {
      OrderLots = FixedLots;
   }
   double freshAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double freshBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if (OrderMode == Standard || OrderMode == Dynamic)
   {
      double slDistance = TP > SL ? (freshAsk - SL) : (SL - freshBid);
      if (slDistance <= 0)
      {
         Print("SL distance is zero or negative. Cannot calculate lot size.");
         return;
      }
      OrderLots = NormalizeDouble(RiskLots(_Symbol, order_risk_money, slDistance), OrderDigits);
   }
   if (OrderMode == VaR && VaRRiskMode == PercentVaR)
   {
      if (PortfolioRisk.CalculateLotSizeBasedOnVaR(_Symbol, VaRConfidence, AccountEquity, RiskVaRPercent, OrderLots))
      {
         OrderLots = NormalizeDouble(OrderLots, OrderDigits);
      }
   }
   if (OrderMode == VaR && VaRRiskMode == NotionalVaR)
   {
      double var_1_lot = 0.0;
      if (PortfolioRisk.CalculateVaR(_Symbol, 1.0))
      {
         var_1_lot = PortfolioRisk.SinglePositionVaR;
         if (var_1_lot > 0)
         {
            OrderLots = RiskVaRNotional / var_1_lot;
            OrderLots = NormalizeDouble(OrderLots, OrderDigits);
         }
         else
         {
            Print("VaR for 1 lot is not positive, cannot calculate Notional VaR lots.");
         }
      }
      else
      {
         Print("Failed to calculate VaR for 1 lot.");
      }
   }
   // Clamp to broker per-order max
   if (OrderLots > max_volume)
      OrderLots = max_volume;
   // Clamp to SYMBOL_VOLUME_LIMIT (total position limit)
   if (OrderLots > available_volume)
      OrderLots = available_volume;
   OrderLots = NormalizeDouble(OrderLots, OrderDigits);
   // If clamped below minimum tradeable volume, reject order
   if (OrderLots < min_volume)
   {
      Print("Computed lot size (", OrderLots, ") is below minimum volume (", min_volume, "). Not placing order.");
      return;
   }
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol = _Symbol;
   request.volume = OrderLots;
   request.deviation = 20;
   request.magic = MagicNumber;
   request.sl = SL;
   request.tp = TP;
   if ((int)g_cachedFillMode == -1)
   {
      Print("No valid filling mode available. Cannot place order.");
      return;
   }
   request.type_filling = g_cachedFillMode;
   if (TP == SL)
   {
      Print("TP and SL are at the same price. Cannot determine order direction.");
      return;
   }
   if (TP > SL)
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_BUY;
      request.price = freshAsk;
   }
   else
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_SELL;
      request.price = freshBid;
   }
   MqlTradeCheckResult check_result;
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double marginBudget = AccountBalance * (1.0 - MarginBufferPercent / 100.0);
   usable_margin = marginBudget - AccountInfoDouble(ACCOUNT_MARGIN);
   if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY) ? freshAsk : freshBid, required_margin))
   {
      Print("Failed to calculate required margin before the loop. Error:", GetLastError());
      return;
   }
   // Proportional estimate to skip most loop iterations
   if (required_margin > usable_margin && required_margin > 0)
   {
      double ratio = usable_margin / required_margin;
      double estimated = NormalizeDouble(OrderLots * ratio * 0.95, OrderDigits);
      if (estimated >= min_volume)
         OrderLots = estimated;
   }
   double volumeStepLocal = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if (volumeStepLocal <= 0) volumeStepLocal = min_volume;
   int marginLoopIter = 0;
   int marginLoopMax = (int)MathMin(MathCeil(OrderLots / min_volume) + 10, 1000);
   while (required_margin > usable_margin && OrderLots > min_volume)
   {
      if (IsStopped()) return;
      if (++marginLoopIter > marginLoopMax)
      {
         Print("Margin adjustment loop exceeded max iterations (", marginLoopMax, "). Aborting order.");
         return;
      }
      OrderLots = NormalizeDouble(MathFloor((OrderLots - volumeStepLocal) / volumeStepLocal) * volumeStepLocal, OrderDigits);
      if (OrderLots < min_volume) { OrderLots = min_volume; break; }
      request.volume = OrderLots;
      usable_margin = marginBudget - AccountInfoDouble(ACCOUNT_MARGIN);
      double marginResult = PerformOrderCheck(request, check_result, OrderLots);
      if (marginResult < 0)
      {
         Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
         return;
      }
      required_margin = marginResult;
      if (OrderLots <= min_volume)
      {
         OrderLots = min_volume;
         break;
      }
   }
   request.volume = OrderLots;
   usable_margin = marginBudget - AccountInfoDouble(ACCOUNT_MARGIN);
   double finalMargin = PerformOrderCheck(request, check_result, OrderLots);
   if (finalMargin < 0)
   {
      Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
      return;
   }
   required_margin = finalMargin;
   if (required_margin >= usable_margin)
   {
      Print("Insufficient margin to place the order. Cannot proceed.");
      return;
   }
   if (OrderLots < min_volume)
   {
      Print("Order size adjusted to zero due to insufficient margin. Cannot place order.");
      return;
   }
   if (OrderMode != Standard || potentialRisk <= MaxRisk)
   {
      if (TP > SL && HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
      {
         Print("Sell position is already open. Cannot place Buy order.");
         return;
      }
      if (SL > TP && HasOpenPosition(_Symbol, POSITION_TYPE_BUY))
      {
         Print("Buy position is already open. Cannot place Sell order.");
         return;
      }
      bool useAsync = (OrderMode == Fixed && FixedOrdersToPlace >= 2);
      Trade.SetAsyncMode(useAsync);
      int numOrders = useAsync ? FixedOrdersToPlace : 1;
      for (int i = 0; i < numOrders; i++)
      {
         if (TP > SL)
         {
            if (PerformOrderCheck(request, check_result, OrderLots) < 0)
            {
               Print("Buy OrderCheck failed, retcode=", check_result.retcode);
               break;
            }
            ExecuteBuyOrder(OrderLots);
         }
         else if (SL > TP)
         {
            if (PerformOrderCheck(request, check_result, OrderLots) < 0)
            {
               Print("Sell OrderCheck failed, retcode=", check_result.retcode);
               break;
            }
            ExecuteSellOrder(OrderLots);
         }
      }
      Trade.SetAsyncMode(false);
   }
   else
   {
      Print("Cannot open order, as risk would be beyond MaxRisk.");
   }
}
void UpdateMartingaleButton()
{
   string label;
   color clr;
   switch (MartingaleMode)
   {
      case MG_LONG:   label = "MG: LONG";   clr = clrLime;     break;
      case MG_SHORT:  label = "MG: SHORT";  clr = clrRed;      break;
      case MG_UNWIND: label = "MG: UNWIND"; clr = clrYellow;   break;
      default:        label = "MG: OFF";    clr = clrDarkGray;  break;
   }
   ExtDialog.MartingaleButtonText(label);
   ExtDialog.MartingaleButtonColor(clr);
   UpdateHarvestButton();
}
void TyWindow::MartingaleButtonText(string text)
{
   buttonMartingale.Text(text);
}
void TyWindow::MartingaleButtonColor(color clr)
{
   buttonMartingale.ColorBackground(clr);
}
void TyWindow::HarvestButtonText(string text)
{
   buttonHarvest.Text(text);
}
void TyWindow::HarvestButtonColor(color clr)
{
   buttonHarvest.ColorBackground(clr);
}
void UpdateHarvestButton()
{
   string label;
   color clr;
   if (MartingaleMode == MG_OFF || MartingaleMode == MG_UNWIND)
   {
      label = "HV: OFF";
      clr = clrDarkGray;
   }
   else if (HarvestEnabled)
   {
      label = "HV: ON";
      clr = clrLime;
   }
   else
   {
      label = "HV: OFF";
      clr = clrGray;
   }
   ExtDialog.HarvestButtonText(label);
   ExtDialog.HarvestButtonColor(clr);
}
void TyWindow::OnClickMartingale(void)
{
   MartingaleState nextState;
   string prompt;
   if (MartingaleMode == MG_OFF)
   {
      // Auto-detect bias from open positions
      int longCount = 0, shortCount = 0;
      int total = PositionsTotal();
      for (int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if (ticket == 0) continue;
         if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            longCount++;
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            shortCount++;
      }
      if (longCount > 0 && shortCount == 0)
      {
         nextState = MG_LONG;
         prompt = "Enable Martingale LONG on " + _Symbol + "? (auto-detected from open longs)";
      }
      else if (shortCount > 0 && longCount == 0)
      {
         nextState = MG_SHORT;
         prompt = "Enable Martingale SHORT on " + _Symbol + "? (auto-detected from open shorts)";
      }
      else
      {
         nextState = MG_LONG;
         prompt = "Enable Martingale LONG on " + _Symbol + "?";
      }
   }
   else if (MartingaleMode == MG_LONG)
   {
      nextState = MG_SHORT;
      prompt = "Switch Martingale to SHORT on " + _Symbol + "?";
   }
   else if (MartingaleMode == MG_SHORT)
   {
      nextState = MG_UNWIND;
      prompt = "Disable Martingale and start UNWINDING on " + _Symbol + "?";
   }
   else // MG_UNWIND
   {
      nextState = MG_OFF;
      prompt = "Stop unwinding on " + _Symbol + "?";
   }
   int result = MessageBox(prompt, "Martingale Mode", MB_YESNO | MB_ICONQUESTION);
   if (result == IDYES)
   {
      MartingaleMode = nextState;
      MartingaleHedgeCloses = 0;
      MartingaleBiasCloses = 0;
      MartingaleHarvestCloses = 0;
      HarvestEnabled = false;
      g_lastOppCloseTime = 0;
      UpdateMartingaleButton();
      Print("Martingale mode changed to ", EnumToString(MartingaleMode), " on ", _Symbol);
      if (nextState == MG_LONG || nextState == MG_SHORT)
         PrintMartingaleStrategyBriefing(nextState);
   }
}
void OrderLines(bool isBuy)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   double slPrice = 0.0, tpPrice = 0.0;
   // Calculate the number of visible candles
   int VisibleCandles = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   if (VisibleCandles <= 0) { Print("No visible bars on chart"); return; }
   // Create arrays to store historical low and high prices
   double LowArray[];
   double HighArray[];
   if (CopyLow(Symbol(), Period(), 0, VisibleCandles, LowArray) <= 0 ||
       CopyHigh(Symbol(), Period(), 0, VisibleCandles, HighArray) <= 0)
   {
      Print("Failed to copy price data for order lines");
      return;
   }
   double LowestPrice = LowArray[ArrayMinimum(LowArray)];
   double HighestPrice = HighArray[ArrayMaximum(HighArray)];
   // Check if there's an active position on the symbol with valid SL/TP
   slPrice = isBuy ? LowestPrice : HighestPrice;
   tpPrice = isBuy ? HighestPrice : LowestPrice;
   for (int p = PositionsTotal() - 1; p >= 0; p--)
   {
      if (PositionGetTicket(p) == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      double positionSL = PositionGetDouble(POSITION_SL);
      double positionTP = PositionGetDouble(POSITION_TP);
      if (positionSL != 0.0 || positionTP != 0.0)
      {
         slPrice = positionSL;
         tpPrice = positionTP;
         break;
      }
   }
   ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, slPrice);
   ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, tpPrice);
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH, HorizontalLineThickness);
   ObjectSetInteger(0, "SL_Line", OBJPROP_SELECTABLE, 1);
   ObjectSetInteger(0, "SL_Line", OBJPROP_BACK, true);
   ObjectSetInteger(0, "TP_Line", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_Line", OBJPROP_WIDTH, HorizontalLineThickness);
   ObjectSetInteger(0, "TP_Line", OBJPROP_SELECTABLE, 1);
   ObjectSetInteger(0, "TP_Line", OBJPROP_BACK, true);
}

void TyWindow::OnClickBuyLines()
{
    OrderLines(true);
}

void TyWindow::OnClickSellLines()
{
    OrderLines(false);
}
void DestroyLines()
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
}
void TyWindow::OnClickDestroyLines(void)
{
   DestroyLines();
}
struct PositionInfo
{
   ulong ticket;
   double diff;
   double lotSize;
   // Copy constructor
   PositionInfo(const PositionInfo &other)
   {
      ticket = other.ticket;
      diff = other.diff;
      lotSize = other.lotSize;
   }
   // Default constructor
   PositionInfo()
   {
      ticket = 0;
      diff = 0.0;
      lotSize = 0.0;
   }
   // Assignment operator
   void operator=(const PositionInfo &other)
   {
      ticket = other.ticket;
      diff = other.diff;
      lotSize = other.lotSize;
   }
};
void BubbleSort(PositionInfo &arr[])
{
   int size = ArraySize(arr);
   for (int i = 0; i < size; i++)
   {
      for (int j = 0; j < size - i - 1; j++)
      {
         // Compare based on price difference first and then lot size
         if (arr[j].diff > arr[j+1].diff || (arr[j].diff == arr[j+1].diff && arr[j].lotSize > arr[j+1].lotSize))
         {
            PositionInfo temp = arr[j];
            arr[j] = arr[j+1];
            arr[j+1] = temp;
         }
      }
   }
}
void TyWindow::OnClickHarvest(void)
{
   if (MartingaleMode == MG_OFF || MartingaleMode == MG_UNWIND)
      return;
   HarvestEnabled = !HarvestEnabled;
   UpdateHarvestButton();
   Print("HARVEST ", (HarvestEnabled ? "ENABLED" : "DISABLED"), " on ", _Symbol);
}
void TyWindow::OnClickCloseAll(void)
{
   bool hasOpenPosition = false;
   int total = PositionsTotal();
   for(int i=0; i<total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
      {
         hasOpenPosition = true;
         break;
      }
   }

   if(!hasOpenPosition)
   {
      Print("There are no positions to close on ", _Symbol, ".");
      return;
   }

   // Close open positions logic
   {
      int result = MessageBox("Do you want to close all positions on " + _Symbol + "?", "Close Positions", MB_YESNO | MB_ICONQUESTION);
      if (result == IDYES)
      {
         Trade.SetAsyncMode(true);
         double TotalPL = 0.0;
         int closeTotal = PositionsTotal();
         for (int i = closeTotal - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
            {
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               double positionProfit = PositionGetDouble(POSITION_PROFIT);
               double swap = PositionGetDouble(POSITION_SWAP);
               double totalProfitWithSwap = positionProfit + swap; // Include swap in total profit/loss
               double lotSize = PositionGetDouble(POSITION_VOLUME);
               if (Trade.PositionClose(ticket))
               {
                  TotalPL += totalProfitWithSwap;
                  if (totalProfitWithSwap >= 0)
                  {
                     Print("Closed Position #", ticket, " (lot size: ", lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a profit of $", DoubleToString(totalProfitWithSwap, 2));
                  }
                  else
                  {
                     Print("Closed Position #", ticket, " (lot size: ", lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a loss of -$", MathAbs(totalProfitWithSwap));
                  }
               }
               else
               {
                  Print("Position #", ticket, " close failed asynchronously with error ", GetLastError());
               }
            }
         }
         // Wait for the asynchronous operations to complete
         int timeout = 3000;
         uint startTime = GetTickCount();
         while ((GetTickCount() - startTime) < (uint) timeout)
         {
            bool stillOpen = false;
            for (int w = PositionsTotal() - 1; w >= 0; w--)
            {
               if (PositionGetTicket(w) > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
               {
                  if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
                     continue;
                  stillOpen = true; break;
               }
            }
            if (!stillOpen) break;
            Sleep(100);
         }
         bool allClosed = true;
         for (int w = PositionsTotal() - 1; w >= 0; w--)
         {
            if (PositionGetTicket(w) > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
               if (!ManageAllPositions && PositionGetInteger(POSITION_MAGIC) != MagicNumber)
                  continue;
               allClosed = false; break;
            }
         }
         if (allClosed)
         {
            Print("All positions closed successfully.");
         }
         else
         {
            Print("Failed to close all positions within the specified timeout.");
         }
         if (TotalPL >= 0)
         {
            Print("Total profit of closed positions: $", DoubleToString(TotalPL, 2));
         }
         else
         {
            Print("Total loss of closed positions: -$", DoubleToString(MathAbs(TotalPL), 2));
         }
         Trade.SetAsyncMode(false);
      }
      else if(result == IDNO)
      {
         Print("Positions not closed as user answered no.");
      }
   }
}
void TyWindow::OnClickClosePartial(void)
{
   PositionInfo positions[];
   int total = PositionsTotal();
   ArrayResize(positions, total);
   int count = 0;
   for (int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
      {
         positions[count].ticket = ticket;
         positions[count].lotSize = PositionGetDouble(POSITION_VOLUME);
         positions[count].diff = 0;
         count++;
      }
   }
   ArrayResize(positions, count);
   if(ArraySize(positions) == 0)
   {
      Print("There are no positions to close on ", _Symbol + ".");
      return;
   }
   // Sort the positions array by lot size
   BubbleSort(positions);
   int result = MessageBox("Do you want to close the smallest lot order on " + _Symbol + "?", "Close Smallest Lot Order", MB_YESNO | MB_ICONQUESTION);
   if (result == IDYES)
   {
      if (!PositionSelectByTicket(positions[0].ticket))
      {
         Print("Position #", positions[0].ticket, " no longer exists.");
         return;
      }
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double positionProfit = PositionGetDouble(POSITION_PROFIT);
      double swap = PositionGetDouble(POSITION_SWAP);
      double totalProfitWithSwap = positionProfit + swap; // Include swap in total profit/loss
      if(Trade.PositionClose(positions[0].ticket))
      {
         if (totalProfitWithSwap >= 0)
         {
            Print("Closed Position #", positions[0].ticket, " (lots: ", positions[0].lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a profit of $", totalProfitWithSwap, ".");
         }
         else
         {
            Print("Position #", positions[0].ticket, " (lots: ", positions[0].lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a loss of -$", MathAbs(totalProfitWithSwap), ".");
         }
      }
      else
      {
         Print("Failed to close position with ticket #", positions[0].ticket, ". Error:", GetLastError());
      }
   }
   else if(result == IDNO)
   {
      Print("User chose not to close the smallest lot order.");
   }
}
void ModifyPosition(double newLevel, int modificationType, int positionTypeFilter = -1)
{
    Trade.SetAsyncMode(true);
    string modLabel = (modificationType == POSITION_SL) ? "SL" : "TP";
    double tickSize = TickSize(_Symbol);
    if (tickSize <= 0) { Print("Invalid tick size"); Trade.SetAsyncMode(false); return; }
    int modifiedPositions = 0;
    int targetPositions = 0;
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
        {
            // Skip positions that don't match the direction filter
            if (positionTypeFilter != -1 && (int)PositionGetInteger(POSITION_TYPE) != positionTypeFilter)
                continue;
            targetPositions++;
            double originalLevel = (modificationType == POSITION_SL) ? PositionGetDouble(POSITION_SL) : PositionGetDouble(POSITION_TP);
            originalLevel = MathRound(originalLevel / tickSize) * tickSize;
            if (MathAbs(originalLevel - newLevel) < tickSize * 0.5)
            {
                Print(modLabel, " for Position #", ticket, " is already at the desired level.");
                continue;
            }
            if (!Trade.PositionModify(ticket, (modificationType == POSITION_SL) ? newLevel : PositionGetDouble(POSITION_SL), (modificationType == POSITION_TP) ? newLevel : PositionGetDouble(POSITION_TP)))
            {
                Print("Failed to modify ", modLabel, ". Error code: ", GetLastError());
                Trade.SetAsyncMode(false);
                return;
            }
            else
            {
                Print(modLabel, " modified for Position #", ticket, ". Original level: ", originalLevel, " | New level: ", newLevel);
                modifiedPositions++;
            }
        }
    }
    Trade.SetAsyncMode(false);
    if (modifiedPositions == targetPositions)
        Print(modLabel, " modification for all positions completed successfully.");
    else
        Print("Modified ", modifiedPositions, " of ", targetPositions, " positions for ", modLabel, ".");
}
void TyWindow::OnClickSetSL(void)
{
    double newSL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
    if (newSL > 0)
    {
        double tickSize = TickSize(_Symbol);
        if (tickSize <= 0) { Print("Invalid tick size"); return; }
        newSL = MathRound(newSL / tickSize) * tickSize;
        SL = newSL;
        // Determine direction from TP/SL line orientation for hedging support
        double tpLine = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
        if (tpLine > 0) tpLine = MathRound(tpLine / tickSize) * tickSize;
        int dirFilter = -1; // default: modify all
        if (tpLine > 0 && newSL > 0)
        {
            if (tpLine > newSL)
                dirFilter = POSITION_TYPE_BUY;
            else if (newSL > tpLine)
                dirFilter = POSITION_TYPE_SELL;
        }
        ModifyPosition(SL, POSITION_SL, dirFilter);
    }
}
void TyWindow::OnClickSetTP(void)
{
   double newTP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   if (newTP > 0)
   {
      double tickSize = TickSize(_Symbol);
      if (tickSize <= 0) { Print("Invalid tick size"); return; }
      newTP = MathRound(newTP / tickSize) * tickSize;
      TP = newTP;
      // Determine direction from TP/SL line orientation for hedging support
      double slLine = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
      if (slLine > 0) slLine = MathRound(slLine / tickSize) * tickSize;
      int dirFilter = -1; // default: modify all
      if (newTP > 0 && slLine > 0)
      {
         if (newTP > slLine)
            dirFilter = POSITION_TYPE_BUY;
         else if (slLine > newTP)
            dirFilter = POSITION_TYPE_SELL;
      }
      ModifyPosition(TP, POSITION_TP, dirFilter);
   }
}
bool TyWindow::OnDialogDragStart(void)
{
   string prefix=Name();
   int total=ExtDialog.ControlsTotal();
   for(int i=0;i<total;i++)
   {
      CWnd*obj=ExtDialog.Control(i);
      string name=obj.Name();
      if(name==prefix+"Border")
      {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(clrNONE);
      }
      if(name==prefix+"Back")
      {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(clrNONE);
      }
      if(name==prefix+"Client")
      {
         CWndClient *wndclient=(CWndClient*) obj;
         wndclient.ColorBackground(clrNONE);
         wndclient.ColorBorder(clrNONE);
         int client_total=wndclient.ControlsTotal();
         for(int j=0;j<client_total;j++)
         {
            CWnd*client_obj=wndclient.Control(j);
            string client_name=client_obj.Name();
            if(client_name=="Button1")
            {
               CButton *button=(CButton*) client_obj;
               button.ColorBackground(clrNONE);
            }
         }
      }
   }
   ChartRedraw();
   return(CDialog::OnDialogDragStart());
}
bool TyWindow::OnDialogDragProcess(void)
{
   string prefix=Name();
   int total=ExtDialog.ControlsTotal();
   for(int i=0;i<total;i++)
   {
      CWnd*obj=ExtDialog.Control(i);
      string name=obj.Name();
      if(name==prefix+"Back")
      {
         CPanel *panel=(CPanel*) obj;
         color clr=(color)GETRGB(XRGB(rand()%255,rand()%255,rand()%255));
         panel.ColorBorder(clr);
         ChartRedraw();
      }
   }
   return(CDialog::OnDialogDragProcess());
}
bool TyWindow::OnDialogDragEnd(void)
{
   string prefix=Name();
   int total=ExtDialog.ControlsTotal();
   for(int i=0;i<total;i++)
   {
      CWnd*obj=ExtDialog.Control(i);
      string name=obj.Name();
      if(name==prefix+"Border")
      {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(CONTROLS_DIALOG_COLOR_BG);
         panel.ColorBorder(CONTROLS_DIALOG_COLOR_BORDER_LIGHT);
      }
      if(name==prefix+"Back")
      {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(CONTROLS_DIALOG_COLOR_BG);
         color border=(m_panel_flag) ? CONTROLS_DIALOG_COLOR_BG : CONTROLS_DIALOG_COLOR_BORDER_DARK;
         panel.ColorBorder(border);
      }
      if(name==prefix+"Client")
      {
         CWndClient *wndclient=(CWndClient*) obj;
         wndclient.ColorBackground(CONTROLS_DIALOG_COLOR_CLIENT_BG);
         wndclient.ColorBorder(CONTROLS_DIALOG_COLOR_CLIENT_BORDER);
         int client_total=wndclient.ControlsTotal();
         for(int j=0;j<client_total;j++)
         {
            CWnd*client_obj=wndclient.Control(j);
            string client_name=client_obj.Name();
            if(client_name=="Button1")
            {
               CButton *button=(CButton*) client_obj;
               button.ColorBackground(CONTROLS_BUTTON_COLOR_BG);
            }
         }
      }
   }
   ChartRedraw();
   return(CDialog::OnDialogDragEnd());
}
