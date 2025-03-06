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
#property link      "http://marketwizardry.info/"
#property version   "1.369"
#property description "TyphooN's MQL5 Risk Management System"
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Orchard\RiskCalc.mqh>
#include <Darwinex\DWEX Portfolio Risk Man.mqh>
#define XRGB(r,g,b)    (0xFF000000|(uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define GETRGB(clr)    ((clr)&0xFFFFFF)
// Classes
CPositionInfo     Position; // Trade wrapper
CTrade            Trade;    // Trade wrapper
COrderInfo        Order;    // Order wrapper
CAccountInfo      Account;  // Account wrapper
CSymbolInfo       Symbol;   // Symbol wrapper
// orchard compat functions
string BaseCurrency() { return ( AccountInfoString( ACCOUNT_CURRENCY ) ); }
double Point( string symbol ) { return ( SymbolInfoDouble( symbol, SYMBOL_POINT ) ); }
double TickSize( string symbol ) { return ( SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE ) ); }
double TickValue( string symbol ) { return ( SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_VALUE ) ); }
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
   return -1;
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
input bool            EnableAutoProtect          = false;
input double          APRRLevel                  = 1.0;
input bool            EnableEquityTP             = false;
input double          TargetEquityTP             = 110200;
input bool            EnableEquitySL             = false;
input double          TargetEquitySL             = 98000;
input group           "[PYRAMID MODE SETTINGS]"
input bool            EnablePyramid = false;
input double          PyramidLotSize = 1.0;
input double          PyramidFreeMarginTrigger = 31337;
input double          PyramidFreeMarginBuffer = 9001;
input double          PyramidTargetLots = 69;
input int             PyramidCooldown = 420;
input string          PyramidComment = "420 Pyramid";
input group           "[DISCORD ANNOUNCEMENT SETTINGS]"
input string          DiscordAPIKey =  "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
input bool            EnableBroadcast = false;
CPortfolioRiskMan PortfolioRisk(VaRTimeframe, StdDevPeriods); // Darwinex VaR wrapper
// global vars
datetime LastPyramidTime = 0;
double PyramidLotsOpened = 0, TP = 0, SL = 0, Bid = 0, Ask = 0, prevBidPrice = 0.0,
       prevAskPrice = 0.0, order_risk_money = 0, DynamicRisk = 0, AccountBalance = 0,
       required_margin = 0, AccountEquity = 0, percent_risk = 0;
bool AutoProtectCalled = false, LimitLineExists = false, EquityTPCalled = false,
     EquitySLCalled = false, HasOpenPosition = false, breakEvenFound = false;
int OrderDigits = 0;
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
      CButton           buttonLimit;
      CButton           buttonBuyLines;
      CButton           buttonSellLines;
      CButton           buttonDestroyLines;
      CButton           buttonProtect;
      CButton           buttonCloseAll;
      CButton           buttonClosePartial;
      CButton           buttonSetSL;
      CButton           buttonSetTP;
   public:
      TyWindow(void);
      ~TyWindow(void);
      void ExecuteBuyLimitOrder(double lots, double Limit_Price);
      void ExecuteSellLimitOrder(double lots, double Limit_Price);
      void ExecuteBuyOrder(double lots);
      void ExecuteSellOrder(double lots);
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
      bool              CreateButtonLimit(void);
      bool              CreateButtonBuyLines(void);
      bool              CreateButtonSellLines(void);
      bool              CreateButtonDestroyLines(void);
      bool              CreateButtonProtect(void);
      bool              CreateButtonCloseAll(void);
      bool              CreateButtonClosePartial(void);
      bool              CreateButtonSetSL(void);
      bool              CreateButtonSetTP(void);
      // handlers of the dependent controls events
      void              OnClickTrade(void);
      void              OnClickLimit(void);
      void              OnClickBuyLines(void);
      void              OnClickSellLines(void);
      void              OnClickDestroyLines(void);
      void              OnClickProtect(void);
      void              OnClickCloseAll(void);
      void              OnClickClosePartial(void);
      void              OnClickSetSL(void);
      void              OnClickSetTP(void);
};
// Event Handling
EVENT_MAP_BEGIN(TyWindow)
ON_EVENT(ON_CLICK, buttonTrade, OnClickTrade)
ON_EVENT(ON_CLICK, buttonLimit, OnClickLimit)
ON_EVENT(ON_CLICK, buttonBuyLines, OnClickBuyLines)
ON_EVENT(ON_CLICK, buttonSellLines, OnClickSellLines)
ON_EVENT(ON_CLICK, buttonDestroyLines, OnClickDestroyLines)
ON_EVENT(ON_CLICK, buttonProtect, OnClickProtect)
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
   if(!CreateButtonLimit()){ return(false); }
   if(!CreateButtonBuyLines()){ return(false); }
   if(!CreateButtonSellLines()){ return(false); }
   if(!CreateButtonDestroyLines()){ return(false); }
   if(!CreateButtonProtect()) { return(false); }
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
   }
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
string arrayToString(uchar &arr[])
{
   string result = "";
   for(int i = 0; i < ArraySize(arr); i++)
   {
      result += IntegerToString(arr[i], 16) + " ";  // Using hex representation
   }
   return result;
}
string TimeTilNextBar(ENUM_TIMEFRAMES tf=PERIOD_CURRENT)
{
   datetime now = TimeCurrent();
   datetime bartime = iTime(NULL, tf, 0);
   long remainingTime = (long)(bartime + PeriodSeconds(tf) - now);
   // Ensure non-negativity
   remainingTime = MathAbs(remainingTime);
   long days = remainingTime / 86400; // 86400 seconds in a day
   long hours = (remainingTime % 86400) / 3600; // 3600 seconds in an hour
   long minutes = (remainingTime % 3600) / 60; // 60 seconds in a minute
   long seconds = remainingTime % 60;
   if (days > 0) return StringFormat("%ldD %ldH %ldM", days, hours, minutes);
   if (hours > 0) return StringFormat("%ldH %ldM %lds", hours, minutes, seconds);
   if (minutes > 0) return StringFormat("%ldM %lds", minutes, seconds);
   // If less than 24 hours, consider it as hours and minutes until the new bar
   return StringFormat("%ldH %ldM %lds", hours, minutes, seconds);
}
double PointValue()
{
   double tickSize      = TickSize( _Symbol );
   double tickValue     = TickValue( _Symbol );
   double point         = Point( _Symbol );
   double ticksPerPoint = tickSize / point;
   double pointValue    = tickValue / ticksPerPoint;
 //  PrintFormat( "tickSize=%f, tickValue=%f, point=%f, ticksPerPoint=%f, pointValue=%f",
 //               tickSize, tickValue, point, ticksPerPoint, pointValue );
   return ( pointValue );
}
bool CloseAllPositionsOnAllSymbols()
{
   Trade.SetAsyncMode(true);
   int totalPositions = PositionsTotal();
   if (totalPositions == 0)
   {
      Print("No open positions to close.");
      return true;  // No need to proceed if there are no positions
   }
   int closedPositions = 0; // Variable to keep track of the number of closed positions
   for (int i = 0; i < totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double positionProfit = PositionGetDouble(POSITION_PROFIT);
      double lotSize = PositionGetDouble(POSITION_VOLUME);
      string symbol = PositionGetString(POSITION_SYMBOL);
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
         closedPositions++; // Increment closedPositions when a position is successfully closed
      }
      else
      {
         Print("[" + symbol + "] Position #", ticket, " close failed asynchronously with error ", GetLastError());
         // Do not return false immediately for asynchronous processing
      }
   }
   // Wait for the asynchronous operations to complete
   int timeout = 3000; // Set a timeout (in milliseconds) to wait for order execution
   uint startTime = GetTickCount();
   while (closedPositions < totalPositions && (GetTickCount() - startTime) < (uint) timeout)
   {
      Sleep(100); // Sleep for a short duration
   }
   if (closedPositions == totalPositions)
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
bool IsNewTick(const double LastTick)
{
   static double PrevTick = 0;
   if (LastTick != PrevTick)
   {
      PrevTick = LastTick;
      return true;
   }
   return false;
}
void GetSLTPFromAnotherPosition(ulong ticket, double &sl, double &tp)
{
   for (int j = 0; j < PositionsTotal(); j++)
   {
      ulong other_ticket = PositionGetTicket(j);
      if (other_ticket != ticket && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
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
// Function to tally up the lots on all open positions and return the results
LotsInfo TallyPositionLots()
{
   LotsInfo lotsInfo;
   lotsInfo.longLots = 0.0;
   lotsInfo.shortLots = 0.0;
   string currentSymbol = Symbol(); // Get the symbol of the chart the EA is attached to
   // Loop through all open positions
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol) // Check if the position's symbol matches the current chart symbol
         {
            // Get the type of the position
            int posType = (int)PositionGetInteger(POSITION_TYPE);
            // Get the lot size of the position
            double lotSize = PositionGetDouble(POSITION_VOLUME);
            // Check if it's a buy position
            if(posType == POSITION_TYPE_BUY)
            {
               lotsInfo.longLots += lotSize;
            }
            else if(posType == POSITION_TYPE_SELL)
            {
               lotsInfo.shortLots += lotSize;
            }
         }
      }
   }
   return lotsInfo;
}
bool IsTradeAllowed(const string symbol)
{
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("Trading is not allowed on this account.");
      return false;
   }
   if (!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
   {
      Print("Trading is not allowed for symbol: ", symbol);
      return false;
   }
   return true;
}
bool PlacePyramidOrders()
{
   // Check if pyramid orders are enabled
   if (!EnablePyramid)
   {
      // Print("Pyramid orders are not enabled.");
      return false;
   }
   // Check if the currently open lots is above the PyramidTargetLots
   if (GetTotalVolumeForSymbol(_Symbol) >= PyramidTargetLots)
   {
      Print("No need to open more Pyramid orders (Lots open:", GetTotalVolumeForSymbol(_Symbol), " <= PyramidTargetLots:", PyramidTargetLots, ")");
      return false;
   }
   // Check if enough time has passed since the last pyramid order
   if (TimeCurrent() - LastPyramidTime < PyramidCooldown)
   {
      // Print("Pyramid order cooldown period not met.");
      return false;
   }
   // Check if free margin exceeds the trigger
   double freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   if (freeMargin < PyramidFreeMarginTrigger)
   {
      // Print("Free margin is less than the trigger.");
      return false;
   }
   // Determine whether it's a buy or sell order based on current position
   ENUM_ORDER_TYPE orderType = (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   // Get current bid or ask price
   double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   // Check if SymbolInfoDouble returns a valid price
   if (price <= 0)
   {
      Print("Invalid price for symbol: ", _Symbol, " Price: ", price);
      return false;
   }
   // Validate the price with market info
   double MarketPriceDeviation = 20;
   double minPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID) * (1 - MarketPriceDeviation);
   double maxPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK) * (1 + MarketPriceDeviation);
   if (price < minPrice || price > maxPrice)
   {
      Print("Price out of acceptable range. Price: ", price, " Min: ", minPrice, " Max: ", maxPrice);
      return false;
   }
   double stopLoss = 0;
   double takeProfit = 0;
   if (PositionSelect(_Symbol))
   {
      stopLoss = PositionGetDouble(POSITION_SL);
      takeProfit = PositionGetDouble(POSITION_TP);
   }
   // Pre-check for enough margin before placing the order
   double PyramidRequiredMargin = 0.0;
   double OrderLots = PyramidLotSize;
   OrderLots = NormalizeDouble(OrderLots, _Digits);
   MqlTradeRequest request;
   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = OrderLots;
   request.price = price;
   request.sl = stopLoss;
   request.tp = takeProfit;
   request.deviation = (ulong)MarketPriceDeviation;
   request.magic = MagicNumber;
   request.type = orderType;
   request.comment = PyramidComment;
   request.type_filling = SelectFillingMode();
   MqlTradeCheckResult check_result;
   required_margin = PerformOrderCheck(request, check_result, OrderLots);
   if (required_margin < 0)
   {
      Print("Order check failed, skipping order placement.");
      return false;
   }
   if (freeMargin < required_margin)
   {
      Print("Not enough free margin to place the order. Required: ", required_margin, " Available: ", freeMargin);
      return false;
   }
   while (freeMargin >= (PyramidFreeMarginTrigger - PyramidFreeMarginBuffer))
   {
      bool orderPlaced = false;
      bool orderIntended = false; // Track if an order is intended to clean up debug logging
      Trade.SetExpertMagicNumber(MagicNumber);
      // Additional checks before placing the order
      if (GetTotalVolumeForSymbol(_Symbol) >= PyramidTargetLots)
      {
         Print("No need to open more Pyramid orders (Lots open:", GetTotalVolumeForSymbol(_Symbol), " <= PyramidTargetLots:", PyramidTargetLots, ")");
         break;
      }
      if (TimeCurrent() - LastPyramidTime < PyramidCooldown)
      {
       //  Print("Pyramid order cooldown period not met.");
         break;
      }
      freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
      if (freeMargin < required_margin)
      {
       //  Print("Not enough free margin to place the order. Required: ", required_margin, " Available: ", freeMargin);
         break;
      }
      if (orderType == ORDER_TYPE_BUY)
      {
         orderIntended = true;
         orderPlaced = Trade.Buy(OrderLots, _Symbol, 0, stopLoss, takeProfit, PyramidComment);
      }
      if (orderType == ORDER_TYPE_SELL)
      {
         orderIntended = true;
         orderPlaced = Trade.Sell(OrderLots, _Symbol, 0, stopLoss, takeProfit, PyramidComment);
      }
      if (orderIntended) // Check if an order was intended before proceeding
      {
         if (orderPlaced)
         {
            PyramidLotsOpened += OrderLots; // Update the total lots added 
            if (orderType == ORDER_TYPE_BUY)
            {
               Print("Order details: Lots: ", OrderLots, " (Long), SL: ", stopLoss, ", TP: ", takeProfit, ", Pyramid Lots opened: ", PyramidLotsOpened, ", Current Lots Open: ", GetTotalVolumeForSymbol(_Symbol), " Pyramid Target Lots: ", PyramidTargetLots);
            }
            if (orderType == ORDER_TYPE_SELL)
            {
               Print("Order details: Lots: ", OrderLots, " (Short), SL: ", stopLoss, ", TP: ", takeProfit, ", Total Pyramid lots opened: ", PyramidLotsOpened, ", Current Lots Open: ", GetTotalVolumeForSymbol(_Symbol), " Pyramid Target Lots: ", PyramidTargetLots);
            }
         }
         else
         {
            int error = GetLastError();
            Print("Failed to place order. Error: ", error);
            // Detailed logging for troubleshooting
            //  Print("Request Details - Action: ", request.action, ", Symbol: ", request.symbol, ", Volume: ", request.volume, ", Price: ", request.price, ", SL: ", request.sl, ", TP: ", request.tp, ", Deviation: ", request.deviation, ", Magic: ", request.magic, ", Type: ", request.type, ", Comment: ", request.comment);
            //  Print("Account Trade Allowed: ", AccountInfoInteger(ACCOUNT_TRADE_ALLOWED));
            long tradeMode;
            if (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE, tradeMode))
            {
               if (tradeMode == SYMBOL_TRADE_MODE_DISABLED)
               {
                  Print("Symbol trading is disabled.");
                  return false;
               }
            }
            break;
         }
      }
      freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   }
   LastPyramidTime = TimeCurrent();
   return true;
}
void OnTick()
{
   HasOpenPosition = false;
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   // Check if both bid and ask prices have changed from the previous tick
   if (Bid == prevBidPrice && Ask == prevAskPrice)
   {
      return;
   }
   PlacePyramidOrders();
   prevBidPrice = Bid;
   prevAskPrice = Ask;
   double total_risk = 0;
   double total_tpprofit = 0;
   double total_pl = 0;
   double total_tp = 0;
   double total_margin = 0;
   double rr = 0;
   double tprr = 0;
   double sl_risk = 0;
   double CurrentTick = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
   if (AccountEquity >= TargetEquityTP && EnableEquityTP == true && EquityTPCalled == false)
   {
      Print("Closing all positions across all symbols because Equity >= TargetEquityTP ($" + DoubleToString(TargetEquityTP, 2) + ").");
      if (CloseAllPositionsOnAllSymbols())
      {
        EquityTPCalled = true;
        AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        Alert("EquityTP closed all positions on all symbols. New account balance: " + DoubleToString(AccountBalance, 2));
      }
   }
   if (AccountEquity < TargetEquitySL && EnableEquitySL == true && EquitySLCalled == false)
   {
      Print("Closing all positions across all symbols because Equity < TargetEquitySL ($" + DoubleToString(TargetEquitySL, 2) + ").");
      if (CloseAllPositionsOnAllSymbols())
      {
         EquitySLCalled = true;
         AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         Alert("EquitySL closed all positions on all symbols. New account balance: " + DoubleToString(AccountBalance, 2));
      }
   }
   if (OrderMode == Standard)
   {
      if (breakEvenFound == true)
      {
         order_risk_money = (AccountInfoDouble(ACCOUNT_BALANCE) * ((Risk / 100) * AdditionalRiskRatio));
      }
      if (breakEvenFound == false)
      {
         order_risk_money = (AccountInfoDouble(ACCOUNT_BALANCE) * (Risk / 100));
      }
   }
   if (OrderMode == Dynamic)
   {
      if (breakEvenFound == true)
      {
         order_risk_money = ((AccountBalance - MinAccountBalance) / (LossesToMinBalance / AdditionalRiskRatio));
      }
      if (breakEvenFound == false)
      {
         order_risk_money = ((AccountBalance - MinAccountBalance) / LossesToMinBalance);
      }
   }
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
      {
         HasOpenPosition = true;
         double profit = PositionGetDouble(POSITION_PROFIT);
         double swap = PositionGetDouble(POSITION_SWAP);
         profit += swap;
         double risk = 0;
         double tpprofit = 0;
         double margin = 0;
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         if (sl == 0 && tp == 0 && EnableUpdateEmptySLTP == true) // If no SL and TP are set
         {
            GetSLTPFromAnotherPosition(ticket, sl, tp);
            if (sl != 0 || tp != 0)
            {
               if (!Trade.PositionModify(ticket, sl, tp))
               {
                  Print("Failed to modify position SL/TP: ", GetLastError());
               }
            }
         }
         if (sl == PositionGetDouble(POSITION_PRICE_OPEN) && PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            breakEvenFound = true;
         }
         else
         {  
            breakEvenFound = false;
         }
         if (tp > sl)
         {
            if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
            {
               Print("Error in OrderCalcMargin: ", GetLastError());
            }
            if (tp != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), tp, tpprofit))
               {
                  Print("Error in OrderCalcProfit (TP): ", GetLastError());
               }
            }
            if (sl != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), sl, risk))
               {
                  Print("Error in OrderCalcProfit (SL): ", GetLastError());
               }
            }
         }
         if (sl > tp)
         {
            if (!OrderCalcMargin(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
            {
               Print("Error in OrderCalcMargin: ", GetLastError());
            }
            if (tp != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), tp, tpprofit))
               {
                  Print("Error in OrderCalcProfit (TP): ", GetLastError());
               }
            }
            if (sl != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), sl, risk))
               {
                  Print("Error in OrderCalcProfit (SL): ", GetLastError());
               }
            }
         }
         if (risk <= 0)
         {
            sl_risk += risk; // Add risk
         }
         if (swap > 0)
         {
            total_risk += swap;
         }
         // Include swap in stop-loss risk calculation if swap is greater than zero
         if (swap > 0 && risk <= 0)
         {
            sl_risk += swap;
         }
         total_risk += risk; // Add profit to total risk
         total_pl += profit;
         total_tp += tpprofit;
         total_margin += margin;
         tprr = total_tp/MathAbs(total_risk);
         rr = total_pl/MathAbs(total_risk);
         percent_risk = MathAbs((sl_risk / AccountBalance) * 100);
      }
   }
   if (EnableAutoProtect == true && AutoProtectCalled == false && breakEvenFound == false)
   {
         if (rr >= APRRLevel && sl_risk < 0)
         {
            Print ("Auto Protect has removed risk as RR >= " + DoubleToString(APRRLevel,8));
            Protect();
            AutoProtectCalled = true;
         }
   }
   string infoRisk;
   string infoPL;
   string infoRR;
   if (rr >= 0)
   {
      infoRR = "RR : " + DoubleToString(rr, 2);
   }
   if (rr <= 0)
   {
      infoRR = "RR : N/A";
   }
   if (total_pl >= MathAbs(total_risk))
   {
      double floatingRisk = MathAbs(total_pl - total_risk);
      double floatingRiskPercent = MathAbs((total_pl - total_risk) / AccountBalance) * 100;
      infoRisk = "Risk: $" + DoubleToString(floatingRisk, 0) + " (" + DoubleToString(floatingRiskPercent, 1) + "%)";
   }
   else
   {
      infoRisk = "Risk: $" + DoubleToString(MathAbs(sl_risk), 0) + " (" + DoubleToString(MathAbs(percent_risk), 1) + "%)";
   }
   if (total_pl < 0)
   {
      infoPL = "Total P/L: -$" + DoubleToString(MathAbs(total_pl), 2); 
   }
   if (total_pl == 0)
   {
      infoPL = "Total P/L: $" + DoubleToString(MathAbs(total_pl), 2); 
   }
   if (total_pl > 0)
   {
      infoPL = "Total P/L: $" + DoubleToString(total_pl, 2);
   }
   string infoSLPL = "SL P/L: $" + DoubleToString(total_risk, 2);
   if (total_risk < 0)
   {
      infoSLPL = "SL P/L: -$" + DoubleToString(MathAbs(total_risk), 2);
   }
   if (!HasOpenPosition)
   {
      sl_risk = 0;
      percent_risk = 0;
   }
   ObjectSetString(0,"infoRR",OBJPROP_TEXT,infoRR);
   ObjectSetString(0,"infoPL",OBJPROP_TEXT,infoPL);
   ObjectSetString(0,"infoSLPL",OBJPROP_TEXT,infoSLPL);
   string infoTP = "TP P/L : $" + DoubleToString(total_tp, 2);
   ObjectSetString(0,"infoTP",OBJPROP_TEXT,infoTP);
   ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk);
   string infoTPRR = "TP RR: " + DoubleToString(tprr, 2);
   ObjectSetString(0,"infoTPRR",OBJPROP_TEXT,infoTPRR);
   string infoH4 = "H4 : " + TimeTilNextBar(PERIOD_H4);
   ObjectSetString(0,"infoH4",OBJPROP_TEXT,infoH4);
   string infoW1 = "W1 : " + TimeTilNextBar(PERIOD_W1);
   ObjectSetString(0,"infoW1",OBJPROP_TEXT,infoW1);
   string infoD1 = "D1 : " + TimeTilNextBar(PERIOD_D1);
   ObjectSetString(0,"infoD1",OBJPROP_TEXT,infoD1);
   string infoMN1 = "MN1: " + TimeTilNextBar(PERIOD_MN1);
   ObjectSetString(0,"infoMN1",OBJPROP_TEXT,infoMN1);
   LotsInfo lots = TallyPositionLots();
   string infoPosition;
   if(HasOpenPosition(_Symbol, POSITION_TYPE_BUY) || HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
   {
      if (lots.longLots > 0 && lots.shortLots == 0)
      {
         infoPosition = "Long " + DoubleToString(lots.longLots, Digits()) + " Lots";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrLime);
         ObjectSetInteger(0,"infoVaR",OBJPROP_COLOR,clrLime);
         ObjectSetString(0,"infoPosition",OBJPROP_TEXT,infoPosition);
         if(PortfolioRisk.CalculateVaR(_Symbol, lots.longLots))
         {
            string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity  * 100), 2);
            ObjectSetString(0,"infoVaR",OBJPROP_TEXT,infoVaR);
         }
      }
      if (lots.shortLots > 0 && lots.longLots == 0)
      {
         infoPosition = "Short " + DoubleToString(lots.shortLots, Digits()) + " Lots";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,"infoVaR",OBJPROP_COLOR,clrRed);
         ObjectSetString(0,"infoPosition",OBJPROP_TEXT,infoPosition);
         if(PortfolioRisk.CalculateVaR(_Symbol, lots.shortLots))
         {
            string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity  * 100), 2);
            ObjectSetString(0,"infoVaR",OBJPROP_TEXT,infoVaR);
         }
      }
      if (lots.shortLots > 0 && lots.longLots > 0)
      {
         infoPosition = DoubleToString(lots.longLots, Digits()) + " Long / " + DoubleToString(lots.shortLots, Digits()) + " Short";
         ObjectSetInteger(0,"infoPosition",OBJPROP_COLOR,clrWhite);
         ObjectSetString(0,"infoPosition",OBJPROP_TEXT,infoPosition);
         if(PortfolioRisk.CalculateVaR(_Symbol, (lots.longLots + lots.shortLots)))
         {
            string infoVaR = "VaR %: " + DoubleToString((PortfolioRisk.SinglePositionVaR/AccountEquity * 100), 2);
            ObjectSetString(0,"infoVaR",OBJPROP_TEXT,infoVaR);
         }
      }
   }
   if (GetTotalVolumeForSymbol(_Symbol) == 0)
   {
      double var_1_lot = 0.0;
      if(PortfolioRisk.CalculateVaR(_Symbol, 1.0))
      {
         var_1_lot = PortfolioRisk.SinglePositionVaR;
         infoPosition = "VaR 1 lot: " + DoubleToString(var_1_lot, 2);
      }
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
bool TyWindow::CreateButtonLimit(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonLimit.Create(0,"Limit Line",0,x1,y1,x2,y2))
      return(false);
   if(!buttonLimit.Text("Limit Line"))
      return(false);
   if(!Add(buttonLimit))
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
bool TyWindow::CreateButtonProtect(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 2 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonProtect.Create(0,"PROTECT",0,x1,y1,x2,y2))
      return(false);
   if(!buttonProtect.Text("PROTECT"))
      return(false);
   if(!Add(buttonProtect))
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
   string headers = "Content-Type: application/json";
   uchar result[];
   string result_headers;
   string json = "{\"content\":\""+ announcement +"\"}";
   char jsonArray[];
   StringToCharArray(json, jsonArray);
   // Remove null-terminator if any
   int arrSize = ArraySize(jsonArray);
   if(jsonArray[arrSize - 1] == '\0')
   {
      ArrayResize(jsonArray, arrSize - 1);
   }
   int res = WebRequest("POST", DiscordAPIKey, headers, 10, jsonArray, result, result_headers);
   // Get the error immediately after WebRequest
   //int lastError = GetLastError();
   string resultString = CharArrayToString(result);
   //Print("Debug - HTTP response code: ", res);
   //Print("Debug - Result: ", resultString);
   //Print("Debug - JSON as uchar array: ", arrayToString(jsonArray));
   //Print("Debug - Length of Result: ", StringLen(resultString));
   //if(lastError != 0)
   //{
   //   Print("WebRequest Error Code: ", lastError);
   //}
   if (DiscordAPIKey == "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token")
   {
      Print("You cannot broadcast to Discord with the Default API key.  Create a webhook in your own Discord or contact TyphooN if you would like to broadcast in the Market Wizardry Discord.");
      return;
   }
}
void TyWindow::ExecuteBuyLimitOrder(double lots, double Limit_Price)
{
   if (Trade.BuyLimit(lots, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
   {
      string BuyLimitText = "[" + _Symbol + "] Buy limit order opened. Price: " + DoubleToString(Limit_Price, _Digits) + 
            ", Lots: " + DoubleToString(lots, 2) + ", SL: " + DoubleToString(SL, _Digits) + ", TP: " + DoubleToString(TP, _Digits);
      Print(BuyLimitText);
      if(EnableBroadcast == true)
      {
         BroadcastDiscordAnnouncement(BuyLimitText);
      }
   }
   else
   {
      Print("Failed to open buy limit order, error: ", GetLastError());
   }
}
void TyWindow::ExecuteSellLimitOrder(double lots, double Limit_Price)
{
   if (Trade.SellLimit(lots, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
   {
      string SellLimitText = "[" + _Symbol + "] Sell limit order opened. Price: " + DoubleToString(Limit_Price, _Digits) + 
      ", Lots: " + DoubleToString(lots, 2) + ", SL: " + DoubleToString(SL, _Digits) + ", TP: " + DoubleToString(TP, _Digits);
      Print(SellLimitText);
      if(EnableBroadcast == true)
      {
         BroadcastDiscordAnnouncement(SellLimitText);
      }
   }
   else
   {
      Print("Failed to open sell limit order, error: ", GetLastError());
   }
}
void TyWindow::ExecuteBuyOrder(double lots)
{
   if (Trade.Buy(lots, _Symbol, 0, SL, TP, NULL))
   {
      string MarketBuyText = "[" + _Symbol + "] Market Buy position opened. Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits) + 
      ", Lots: " + DoubleToString(lots, 2) + ", SL: " +  DoubleToString(SL, _Digits) + ", TP: " + DoubleToString(TP, _Digits);
      Print(MarketBuyText);
      if(EnableBroadcast == true)
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
      string MarketSellText = "[" + _Symbol + "] Market Sell position opened. Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + 
         ", Lots: " + DoubleToString(lots, 2) + ", SL: " + DoubleToString(SL, _Digits) + ", TP: " + DoubleToString(TP, _Digits);
      Print(MarketSellText);
      if(EnableBroadcast == true)
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
    bool ShouldProcessPosition = false;
    if (ManageAllPositions)
    {
        if (PositionGetString(POSITION_SYMBOL) == symbol)
        {
            ShouldProcessPosition = true;
        }
    }
    else
    {
        if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber)
        {
            ShouldProcessPosition = true;
        }
    }
    return ShouldProcessPosition;
}
bool HasOpenPosition(string sym, int orderType) 
{
   for(int i = 0; i < PositionsTotal(); i++) 
   {
   if (ManageAllPositions)
   {
      if(PositionGetSymbol(i) == sym && PositionGetInteger(POSITION_TYPE) == orderType)
      {
         return true;
      }
   }
   else
   {
      if(PositionGetSymbol(i) == sym && PositionGetInteger(POSITION_TYPE) == orderType && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         return true;
      }
   }
   }
   return false;
}
double GetTotalVolumeForSymbol(string symbol)
{
   double totalVolume = 0;

   for(int i=PositionsTotal()-1; i >= 0; i--)
   {
      string positionSymbol = PositionGetSymbol(i);
      if(positionSymbol == symbol)
      {
         totalVolume += PositionGetDouble(POSITION_VOLUME);
      }
   }
   return totalVolume;
}
double PerformOrderCheck(const MqlTradeRequest &request, MqlTradeCheckResult &check_result, double &OrderLots)
{
   // Check if the original order passes the order check
   if (!Trade.OrderCheck(request, check_result))
   {
      int retcode = (int)check_result.retcode;
      if (retcode == 10013)
      {
         // Handle error code 10013 (Invalid request)
         Print("Invalid request. Check the request parameters.");
         return -1.0; // Return -1.0 to indicate failure
      }
      if (retcode == 10019)
      {
         return -1.0;
      }
      if (retcode == 10030)
      {
         return -1.0;
      }
      else
      {
         Print("OrderCheck failed with retcode ", retcode);
         Print("Check result: ", check_result.comment);
         return -1.0; // Return -1.0 to indicate failure
      }
      }
      else
      {
         // OrderCheck successful, calculate and return the required margin
         if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY || request.type == ORDER_TYPE_BUY_LIMIT) ? Ask : Bid, required_margin))
         {
            Print("Failed to calculate required margin after successful OrderCheck. Error:", GetLastError());
            return -1.0; // Return -1.0 to indicate failure
         }
         MqlTradeRequest Request = request;
         Request.volume = OrderLots;
         return required_margin;
   }
   return -1.0;
}
void TyWindow::OnClickTrade(void)
{
   SL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
   TP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   double tickSize = TickSize(_Symbol);
   SL = MathRound(SL / tickSize) * tickSize;
   TP = MathRound(TP / tickSize) * tickSize;
   double max_volume = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), _Digits);
   double limit_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   double existing_volume = GetTotalVolumeForSymbol(_Symbol);
   double usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
   double potentialRisk = -1;
   double OrderRisk;
   if (OrderMode == Standard)
   {
      if (breakEvenFound == true)
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
         potentialRisk = OrderRisk + percent_risk;
         order_risk_money = (AccountBalance * (OrderRisk / 100));
      }
      if (breakEvenFound == true && percent_risk > 0)
      {
         Print("Break Even positions found, and a risk position already placed. Not placing additional order.");
         return;
      }
   }
   if (OrderMode == Dynamic)
   {
      if (breakEvenFound == true)
      {
         order_risk_money = ((AccountBalance - MinAccountBalance) / (LossesToMinBalance * AdditionalRiskRatio));
      }
      if (breakEvenFound == false)
      {
         order_risk_money = ((AccountBalance - MinAccountBalance) / LossesToMinBalance);
      }
      if (!breakEvenFound)
      {
         if (HasOpenPosition(_Symbol, (TP > SL) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         {
            Print("Another position is already open with the same order type on the symbol. Not placing additional order.");
            return;
         }
      }
      if (breakEvenFound == true && percent_risk > 0)
      {
         Print("Break Even positions found, and a risk position already placed. Not placing additional order.");
         return;
      }
   }
   double available_volume;
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if (limit_volume == 0)
   {
      available_volume = max_volume;
   }
   else if (limit_volume > 0 && existing_volume == limit_volume)
   {
      Print("Existing volume is equal to the limit volume. Not placing additional order.");
      return;
   }
   else
   {
      available_volume = limit_volume - existing_volume;
   }
   Trade.SetExpertMagicNumber(MagicNumber);
   double Limit_Price = 0;
   if (LimitLineExists == true)
   {
      Limit_Price = ObjectGetDouble(0, "Limit_Line", OBJPROP_PRICE, 0);
   }
   double OrderLots = 0.0;
   if (OrderMode == Fixed)
   {
      OrderLots = FixedLots;
   }
   if (OrderMode == Standard || OrderMode == Dynamic)
   {
      OrderLots = TP > SL ? NormalizeDouble(RiskLots(_Symbol, order_risk_money, Ask - SL), OrderDigits)
                          : NormalizeDouble(RiskLots(_Symbol, order_risk_money, SL - Bid), OrderDigits);
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
      double zScore = PortfolioRisk.PublicInverseCumulativeNormal(VaRConfidence);
      double nominalValuePerUnitPerLot = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double currentPrice = iClose(_Symbol, PERIOD_M1, 0);
      double stdDevReturns;
      if (PortfolioRisk.PublicGetAssetStdDevReturns(_Symbol, stdDevReturns))
      {
         double unitVaR = zScore * stdDevReturns * nominalValuePerUnitPerLot * currentPrice;
         OrderLots = RiskVaRNotional / unitVaR;
         OrderLots = NormalizeDouble(OrderLots, OrderDigits);
      }
      else
      {
         Print("Failed to get asset standard deviation of returns.");
      }
   }
   if (OrderLots > available_volume)
   {
      OrderLots = available_volume;
   }
   if (available_volume > max_volume && OrderLots > max_volume)
   {
      OrderLots = max_volume;
   }
   if (OrderLots < min_volume)
   {
      OrderLots = min_volume;
   }
   else if (OrderLots > max_volume)
   {
      OrderLots = max_volume;
   }
   OrderLots = NormalizeDouble(OrderLots, OrderDigits);
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol = _Symbol;
   request.volume = OrderLots;
   request.deviation = 20;
   request.magic = MagicNumber;
   request.sl = SL;
   request.tp = TP;
   request.type_filling = SelectFillingMode();
   if (TP > SL)
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_BUY;
   }
   else if (SL > TP)
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_SELL;
   }
   MqlTradeCheckResult check_result;
   MqlTick latest_tick;
   int retcode = 0;
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
   if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY || request.type == ORDER_TYPE_BUY_LIMIT) ? Ask : Bid, required_margin))
   {
      Print("Failed to calculate required margin before the loop. Error:", GetLastError());
      return;
   }
   while (required_margin > usable_margin && OrderLots > min_volume)
   {
      OrderLots -= min_volume;
      usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
      if (!PerformOrderCheck(request, check_result, OrderLots))
      {
         Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
         return;
      }
      if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY || request.type == ORDER_TYPE_BUY_LIMIT) ? Ask : Bid, required_margin))
      {
         Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
         return;
      }
      if (OrderLots < min_volume)
      {
         OrderLots = min_volume;
      }
   }
   usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
   if (!PerformOrderCheck(request, check_result, OrderLots))
   {
      Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
      return;
   }
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
   if (potentialRisk <= (MaxRisk))
   {
      if (FixedOrdersToPlace >= 2)
      {
         Trade.SetAsyncMode(true);
      }
      else
      {
         Trade.SetAsyncMode(false);
      }
      int numOrders = (OrderMode == Fixed && FixedOrdersToPlace >= 2) ? FixedOrdersToPlace : 1;
      for (int i = 0; i < numOrders; i++)
      {
         if (LimitLineExists == true)
         {
            if (TP > SL)
            {
               if (HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
               {
                  Print("Sell position is already open. Cannot place Buy Limit order.");
                  return;
               }
               request.action = TRADE_ACTION_PENDING;
               request.type = ORDER_TYPE_BUY_LIMIT;
               request.price = Limit_Price;
               if (!PerformOrderCheck(request, check_result, OrderLots))
               {
                  Print("Buy Limit OrderCheck failed, retcode=", check_result.retcode);
                  return;
               }
               ExecuteBuyLimitOrder(OrderLots, Limit_Price);
            }
            else if (SL > TP)
            {
               if (HasOpenPosition(_Symbol, POSITION_TYPE_BUY))
               {
                  Print("Buy position is already open. Cannot place Sell Limit order.");
                  return;
               }
               request.action = TRADE_ACTION_PENDING;
               request.type = ORDER_TYPE_SELL_LIMIT;
               request.price = Limit_Price;
               if (!PerformOrderCheck(request, check_result, OrderLots))
               {
                  Print("Sell Limit OrderCheck failed, retcode=", check_result.retcode);
                  return;
               }
               ExecuteSellLimitOrder(OrderLots, Limit_Price);
            }
         }
         else
         {
            if (TP > SL)
            {
               if (HasOpenPosition(_Symbol, POSITION_TYPE_SELL))
               {
                  Print("Sell position is already open. Cannot place Buy order.");
                  return;
               }
               if (SymbolInfoTick(_Symbol, latest_tick))
               {
                  request.action = TRADE_ACTION_DEAL;
                  request.type = ORDER_TYPE_BUY;
               }
               if (!PerformOrderCheck(request, check_result, OrderLots))
               {
                  Print("Buy OrderCheck failed, retcode=", check_result.retcode);
                  return;
               }
               ExecuteBuyOrder(OrderLots);
            }
            else if (SL > TP)
            {
               if (HasOpenPosition(_Symbol, POSITION_TYPE_BUY))
               {
                  Print("Buy position is already open. Cannot place Sell order.");
                  return;
               }
               if (SymbolInfoTick(_Symbol, latest_tick))
               {
                  request.action = TRADE_ACTION_DEAL;
                  request.type = ORDER_TYPE_SELL;
               }
               if (!PerformOrderCheck(request, check_result, OrderLots))
               {
                  Print("Sell OrderCheck failed, retcode=", check_result.retcode);
                  return;
               }
               ExecuteSellOrder(OrderLots);
            }
         }
      }
   }
   else
   {
      Print("Cannot open order, as risk would be beyond MaxRisk.");
   }
}
void TyWindow::OnClickLimit(void)
{
   if (!LimitLineExists)
   {
      ObjectCreate(0, "Limit_Line", OBJ_HLINE, 0, TimeCurrent(), Ask);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_WIDTH, HorizontalLineThickness);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_SELECTABLE, 1);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_BACK, true);
      LimitLineExists = true;
   }
   else
   {
      ObjectDelete(0, "Limit_Line");
      LimitLineExists = false;
   }
}
void OrderLines(bool isBuy)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   double slPrice = 0.0, tpPrice = 0.0;
   // Calculate the number of visible candles
   int VisibleCandles = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   // Create arrays to store historical low and high prices
   double LowArray[];
   double HighArray[];
   ArrayResize(LowArray, VisibleCandles);
   ArrayResize(HighArray, VisibleCandles);
   CopyLow(Symbol(), Period(), 0, VisibleCandles, LowArray);
   CopyHigh(Symbol(), Period(), 0, VisibleCandles, HighArray);
   // Calculate the lowest and highest prices within the visible range
   double LowestPrice = LowArray[0];
   double HighestPrice = HighArray[0];
   for (int i = 1; i < VisibleCandles; i++)
   {
      if (LowArray[i] < LowestPrice)
      {
         LowestPrice = LowArray[i];
      }
      if (HighArray[i] > HighestPrice)
      {
         HighestPrice = HighArray[i];
      }
   }
   // Check if there's an active position on the symbol
   if (PositionSelect(Symbol()))
   {
      double positionSL = PositionGetDouble(POSITION_SL);
      double positionTP = PositionGetDouble(POSITION_TP);
      if ((positionSL == 0.0 || !(positionSL == positionSL)) && (positionTP == 0.0 || !(positionTP == positionTP)))
      {
         slPrice = isBuy ? LowestPrice : HighestPrice;
         tpPrice = isBuy ? HighestPrice : LowestPrice;
      }
      else
      {
         slPrice = positionSL;
         tpPrice = positionTP;
      }
   }
   else
   {
      slPrice = isBuy ? LowestPrice : HighestPrice;
      tpPrice = isBuy ? HighestPrice : LowestPrice;
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
   ObjectDelete(0, "Limit_Line");
   LimitLineExists = false;
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
};
void BubbleSort(PositionInfo &arr[])
{
   for (int i = 0; i < ArraySize(arr); i++)
   {
      for (int j = 0; j < ArraySize(arr) - i - 1; j++)
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
void TyWindow::OnClickProtect(void)
{
   Protect();
}
void TyWindow::OnClickCloseAll(void)
{
   bool HasOpenLimitOrder = false;
   // Check for open limit orders
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(Order.SelectByIndex(i) && Order.Magic() == MagicNumber && Order.Symbol() == _Symbol)
      {
         HasOpenLimitOrder = true;
         break;
      }
   }
   // Check for open positions
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(ProcessPositionCheck(PositionGetTicket(i), _Symbol, MagicNumber))
      {
         HasOpenPosition = true;
         break;
      }
   }
   if(!HasOpenLimitOrder && !HasOpenPosition)
   {
      Print("There are no positions or limit orders to close on ", _Symbol, ".");
      return;
   }
   // Close limit orders logic
   if(HasOpenLimitOrder)
   {
      int result = MessageBox("Do you want to close all limit orders?", "Close Limit Orders", MB_YESNO | MB_ICONQUESTION);
      if (result == IDYES)
      {
         for(int i = OrdersTotal() - 1; i >= 0; i--)
         {
            if(Order.SelectByIndex(i) && Order.Magic() == MagicNumber && Order.Symbol() == _Symbol)
            {
               if (Trade.OrderDelete(Order.Ticket()))
               {
                  Print("Order #", Order.Ticket(), " closed");
               }
               else
               {
                  Print("Order #", Order.Ticket(), " close failed with error ", GetLastError());
               }
            }
         }
         // Wait for the asynchronous operations to complete
         int timeout = 3000; // Set a timeout (in milliseconds) to wait for order execution
         uint startTime = GetTickCount();
         while (OrdersTotal() > 0 && (GetTickCount() - startTime) < (uint) timeout)
         {
            Sleep(100); // Sleep for a short duration
         }
         if (OrdersTotal() == 0)
         {
            Print("All limit orders closed successfully.");
         }
         else
         {
            Print("Failed to close all limit orders within the specified timeout.");
         }
      }
      else if(result == IDNO)
      {
         Print("Limit orders not closed.");
      }
   }
   // Close open positions logic
   if(HasOpenPosition)
   {
      int result = MessageBox("Do you want to close all positions on " + _Symbol + "?", "Close Positions", MB_YESNO | MB_ICONQUESTION);
      if (result == IDYES)
      {
         Trade.SetAsyncMode(true);
         double TotalPL = 0.0;
         for (int i = PositionsTotal() - 1; i >= 0; i--)
         {
            if (ProcessPositionCheck(PositionGetTicket(i), _Symbol, MagicNumber))
            {
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               double positionProfit = PositionGetDouble(POSITION_PROFIT);
               double swap = PositionGetDouble(POSITION_SWAP);
               double totalProfitWithSwap = positionProfit + swap; // Include swap in total profit/loss
               double lotSize = PositionGetDouble(POSITION_VOLUME);
               if (Trade.PositionClose(PositionGetInteger(POSITION_TICKET)))
               {
                  TotalPL += totalProfitWithSwap;
                  if (totalProfitWithSwap >= 0)
                  {
                     Print("Closed Position #", PositionGetInteger(POSITION_TICKET), " (lot size: ", lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a profit of $", DoubleToString(totalProfitWithSwap, 2));
                  }
                  else
                  {
                     Print("Closed Position #", PositionGetInteger(POSITION_TICKET), " (lot size: ", lotSize, " entry price: ", entryPrice, " close price: ", currentPrice, ") with a loss of -$", MathAbs(totalProfitWithSwap));
                  }
               }
               else
               {
                  Print("Position #", PositionGetInteger(POSITION_TICKET), " close failed asynchronously with error ", GetLastError());
               }
            }
         }
         // Wait for the asynchronous operations to complete
         int timeout = 3000; // Set a timeout (in milliseconds) to wait for order execution
         uint startTime = GetTickCount();
         while (PositionsTotal() > 0 && (GetTickCount() - startTime) < (uint) timeout)
         {
            Sleep(100); // Sleep for a short duration
         }
         if (PositionsTotal() == 0)
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
   for (int i = 0; i < PositionsTotal(); i++)
   {
      if (ProcessPositionCheck(PositionGetTicket(i), _Symbol, MagicNumber))
      {
         PositionInfo pos;
         pos.ticket = PositionGetInteger(POSITION_TICKET);
         pos.lotSize = PositionGetDouble(POSITION_VOLUME);
         pos.diff = 0;
         ArrayResize(positions, ArraySize(positions) + 1);
         positions[ArraySize(positions) - 1] = pos;
      }
   }
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
void ModifyPosition(double newLevel, int modificationType)
{
    Trade.SetAsyncMode(true);
    int modifiedPositions = 0; // Variable to keep track of the number of modified positions
    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
        {
            double originalLevel = (modificationType == POSITION_SL) ? PositionGetDouble(POSITION_SL) : PositionGetDouble(POSITION_TP);
            // Round the original level to the tick size
            double tickSize = TickSize(_Symbol);
            originalLevel = MathRound(originalLevel / tickSize) * tickSize;
            // If newLevel is the same as originalLevel, skip modification
            if (originalLevel == newLevel)
            {
                Print((modificationType == POSITION_SL) ? "SL" : "TP", " for Position #", ticket, " is already at the desired level.");
                continue;
            }
            if (!Trade.PositionModify(ticket, (modificationType == POSITION_SL) ? newLevel : PositionGetDouble(POSITION_SL), (modificationType == POSITION_TP) ? newLevel : PositionGetDouble(POSITION_TP)))
            {
                Print("Failed to modify ", (modificationType == POSITION_SL) ? "SL" : "TP", ". Error code: ", GetLastError());
                return;
            }
            else
            {
                Print((modificationType == POSITION_SL) ? "SL" : "TP", " modified for Position #", ticket, ". Original level: ", originalLevel, " | New level: ", newLevel);
                modifiedPositions++; // Increment modifiedPositions when a position is successfully modified
            }
        }
    }
    // Wait for the asynchronous operations to complete
    int timeout = 3000; // Set a timeout (in milliseconds) to wait for order execution
    uint startTime = GetTickCount();
    while (modifiedPositions < PositionsTotal() && (GetTickCount() - startTime) < (uint)timeout)
    {
        Sleep(100); // Sleep for a short duration
    }
    if (modifiedPositions == PositionsTotal())
    {
        Print((modificationType == POSITION_SL) ? "SL" : "TP", " modification for all positions completed successfully.");
    }
    else
    {
        Print("Failed to modify ", (modificationType == POSITION_SL) ? "SL" : "TP", " for all positions within the specified timeout.");
    }
}
void TyWindow::OnClickSetSL(void)
{
    double newSL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
    if (newSL != SL && newSL != 0) // Check if SL value is changed and not equal to 0
    {
        // Get tick size of the symbol
        double tickSize = TickSize(_Symbol);
        // Round SL value to the tick size
        newSL = MathRound(newSL / tickSize) * tickSize;
        SL = newSL;
        ModifyPosition(SL, POSITION_SL);
    }
    AutoProtectCalled = false;
}
void TyWindow::OnClickSetTP(void)
{
   double newTP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   if (newTP != TP && newTP != 0) // Check if TP value is changed and not equal to 0
   {
      double tickSize = TickSize(_Symbol);
      // Round TP value to the tick size
      newTP = MathRound(newTP / tickSize) * tickSize;
      TP = newTP;
      ModifyPosition(TP, POSITION_TP);
   }
}
void Protect()
{
   Trade.SetAsyncMode(false);
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
      {
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double originalSL = PositionGetDouble(POSITION_SL);
         // Round the original SL to the tick size
         double tickSize = TickSize(_Symbol);
         originalSL = MathRound(originalSL / tickSize) * tickSize;
         if (originalSL != entryPrice)
         {
            ModifyPosition(entryPrice, POSITION_SL);
         }
         else
         {
            Print("SL for Position #", ticket, " is already at breakeven.");
         }
      }
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
         ChartRedraw();
      }
      if(name==prefix+"Back")
      {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(clrNONE);
         ChartRedraw();
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
               ChartRedraw();
            }
         }
         ChartRedraw();
      }
   }
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
         ChartRedraw();
      }
      if(name==prefix+"Back")
      {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(CONTROLS_DIALOG_COLOR_BG);
         color border=(m_panel_flag) ? CONTROLS_DIALOG_COLOR_BG : CONTROLS_DIALOG_COLOR_BORDER_DARK;
         panel.ColorBorder(border);
         ChartRedraw();
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
               ChartRedraw();
            }
      }
      }
   }
   return(CDialog::OnDialogDragEnd());
}
