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
#property version   "1.315"
#property description "TyphooN's MQL5 Risk Management System"
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Orchard\RiskCalc.mqh>
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
// input vars
input group    "[ORDER PLACEMENT SETTINGS]";
input int      MarginBufferPercent        = 1;
input double   AdditionalRiskRatio        = 0.25;
input group    "[STANDARD RISK SETTINGS]";
input bool     UseStandardRisk            = true;
input double   MaxRisk                    = 1.0;
input double   Risk                       = 0.5;
input group    "[DYNAMIC RISK SETTINGS]";
input bool     UseDynamicRisk             = false;
input double   MinAccountBalance          = 96100;
input int      LossesToMinBalance         = 10;
input group    "[ACCOUNT PROTECTION SETTINGS]";
input bool     EnableAutoProtect          = true;
input double   APRRLevel                  = 1.0;
input bool     EnableEquityTP             = false;
input double   TargetEquityTP             = 110200;
input bool     EnableEquitySL             = false;
input double   TargetEquitySL             = 98000;
input group    "[EXPERT ADVISOR SETTINGS]";
input int      MagicNumber                = 13;
input int      HorizontalLineThickness    = 3;
input bool     ManageAllPositions         = false;
input group    "[DISCORD ANNOUNCEMENT SETTINGS]"
input string   DiscordAPIKey =  "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
input bool     EnableBroadcast = false;
// global vars
double TP = 0;
double SL = 0;
double Bid = 0;
double Ask = 0;
double order_risk_money = 0;
double DynamicRisk = 0;
double AccountBalance = 0;
double required_margin = 0;
double account_equity = 0;
bool AutoProtectCalled = false;
bool LimitLineExists = false;
bool EquityTPCalled = false;
bool EquitySLCalled = false;
double percent_risk = 0;
bool HasOpenPosition = false;
bool breakEvenFound = false;
bool asyncOrderStatus[];
// defines
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
      CButton           buttonSetTP;
      CButton           buttonSetSL;
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
      bool              CreateButtonSetTP(void);
      bool              CreateButtonSetSL(void);
      // handlers of the dependent controls events
      void              OnClickTrade(void);
      void              OnClickLimit(void);
      void              OnClickBuyLines(void);
      void              OnClickSellLines(void);
      void              OnClickDestroyLines(void);
      void              OnClickProtect(void);
      void              OnClickCloseAll(void);
      void              OnClickClosePartial(void);
      void              OnClickSetTP(void);
      void              OnClickSetSL(void);
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
ON_EVENT(ON_CLICK, buttonSetTP, OnClickSetTP)
ON_EVENT(ON_CLICK, buttonSetSL, OnClickSetSL)
EVENT_MAP_END(CAppDialog)
// Constructor
TyWindow::TyWindow(void)
{
}
// Destructor
TyWindow::~TyWindow(void)
{
}
bool TyWindow::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
{
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);
   // create dependent controls
   if(!CreateButtonTrade())
      return(false);
   if(!CreateButtonLimit())
      return(false);
   if(!CreateButtonBuyLines())
      return(false);
   if(!CreateButtonSellLines())
      return(false);
   if(!CreateButtonDestroyLines())
      return(false);
   if(!CreateButtonProtect())
      return(false);
   if(!CreateButtonCloseAll())
      return(false);
   if(!CreateButtonClosePartial())
      return(false);
      if(!CreateButtonSetTP())
   return(false);
      if(!CreateButtonSetSL())
   return(false);
   return(true);
}
// Global Variable
TyWindow ExtDialog;
int OnInit()
{
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   string FontName="Courier New";
   int FontSize=8;
   int LeftColumnX=310;
   int RightColumnX=150;
   int YRowWidth = 13;
   ObjectCreate(0,"infoSLPL", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoTP", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoMargin", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoTPRR", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoRR", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoLots", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoRisk", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoH4", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoD1", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoW1", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoMN1", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoPL", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoPL",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoPL",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoPL", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoPL",OBJPROP_YDISTANCE,(YRowWidth * 2));
   ObjectSetInteger(0,"infoPL",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoPL",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoSLPL",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoSLPL",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoSLPL", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoSLPL",OBJPROP_YDISTANCE,(YRowWidth * 2));
   ObjectSetInteger(0,"infoSLPL",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoSLPL",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoTP",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoTP",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoTP", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoTP",OBJPROP_YDISTANCE,(YRowWidth * 3));
   ObjectSetInteger(0,"infoTP",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoTP",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoMargin",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoMargin",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoMargin", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoMargin",OBJPROP_YDISTANCE,(YRowWidth * 3));
   ObjectSetInteger(0,"infoMargin",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoMargin",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoRisk",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoRisk",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoRisk", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoRisk",OBJPROP_YDISTANCE,(YRowWidth * 4));
   ObjectSetInteger(0,"infoRisk",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoRisk",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoLots",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoLots",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoLots", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoLots",OBJPROP_YDISTANCE,(YRowWidth * 4));
   ObjectSetInteger(0,"infoLots",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoLots",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoTPRR",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoTPRR",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoTPRR", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoTPRR",OBJPROP_YDISTANCE,(YRowWidth * 5));
   ObjectSetInteger(0,"infoTPRR",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoTPRR",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoRR",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoRR",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoRR", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoRR",OBJPROP_YDISTANCE,(YRowWidth * 5));
   ObjectSetInteger(0,"infoRR",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoRR",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoH4",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoH4",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoH4", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoH4",OBJPROP_YDISTANCE,(YRowWidth * 6));
   ObjectSetInteger(0,"infoH4",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoH4",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoW1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoW1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoW1", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoW1",OBJPROP_YDISTANCE,(YRowWidth * 7));
   ObjectSetInteger(0,"infoW1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoW1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoD1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoD1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoD1", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoD1",OBJPROP_YDISTANCE,(YRowWidth * 6));
   ObjectSetInteger(0,"infoD1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoD1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetString(0,"infoMN1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoMN1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoMN1", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoMN1",OBJPROP_YDISTANCE,(YRowWidth * 7));
   ObjectSetInteger(0,"infoMN1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoMN1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoPL = "Total P/L: $0.00";
   string infoRR = "RR : N/A";
   string infoSLPL = "SL P/L: $0.00";
   ObjectSetString(0,"infoRR",OBJPROP_TEXT,infoRR);
   ObjectSetString(0,"infoPL",OBJPROP_TEXT,infoPL);
   ObjectSetString(0,"infoSLPL",OBJPROP_TEXT,infoSLPL);
   string infoTP = "TP P/L : $0.00";
   ObjectSetString(0,"infoTP",OBJPROP_TEXT,infoTP);
   string infoMargin = "Margin: $0.00";
   ObjectSetString(0,"infoMargin",OBJPROP_TEXT,infoMargin);
   string infoRisk = "Risk: $0.00";
   ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk);
   string infoLots = "Lots: 0.00";
   ObjectSetString(0,"infoLots",OBJPROP_TEXT,infoLots);
   string infoTPRR = "TP RR: N/A";
   ObjectSetString(0,"infoTPRR",OBJPROP_TEXT,infoTPRR);
   string infoH4 = "H4 : " + TimeTilNextBar(PERIOD_H4);
   ObjectSetString(0,"infoH4",OBJPROP_TEXT,infoH4);
   string infoW1 = "W1 : " + TimeTilNextBar(PERIOD_W1);
   ObjectSetString(0,"infoW1",OBJPROP_TEXT,infoW1);
   string infoD1 = "D1 : " + TimeTilNextBar(PERIOD_D1);
   ObjectSetString(0,"infoD1",OBJPROP_TEXT,infoD1);
   string infoMN1 = "MN1: " + TimeTilNextBar(PERIOD_MN1);
   ObjectSetString(0,"infoMN1",OBJPROP_TEXT,infoMN1);
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
void OnTick()
{
   HasOpenPosition = false;
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double total_risk = 0;
   double total_tpprofit = 0;
   double total_pl = 0;
   double total_tp = 0;
   double total_margin = 0;
   double rr = 0;
   double tprr = 0;
   double sl_risk = 0;
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double CurrentTick = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
   if (account_equity >= TargetEquityTP && EnableEquityTP == true && EquityTPCalled == false)
   {
      Print("Closing all positions across all symbols because Equity >= TargetEquityTP ($" + DoubleToString(TargetEquityTP, 2) + ").");
      if (CloseAllPositionsOnAllSymbols())
      {
        EquityTPCalled = true;
        AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        Alert("EquityTP closed all positions on all symbols. New account balance: " + DoubleToString(AccountBalance, 2));
      }
   }
   if (account_equity < TargetEquitySL && EnableEquitySL == true && EquitySLCalled == false)
   {
      Print("Closing all positions across all symbols because Equity < TargetEquitySL ($" + DoubleToString(TargetEquitySL, 2) + ").");
      if (CloseAllPositionsOnAllSymbols())
      {
         EquitySLCalled = true;
         AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         Alert("EquitySL closed all positions on all symbols. New account balance: " + DoubleToString(AccountBalance, 2));
      }
   }
   if (UseStandardRisk == true && UseDynamicRisk == false)
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
   if (UseStandardRisk == false && UseDynamicRisk == true)
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
         if (PositionGetDouble(POSITION_SL) == PositionGetDouble(POSITION_PRICE_OPEN) && PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            breakEvenFound = true;
         }
         else
         {  // Make sure to set breakEvenFound to false if no SL BE is found
            breakEvenFound = false;
         }
         if (PositionGetDouble(POSITION_TP) > PositionGetDouble(POSITION_SL))
         {
            if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
            {
               Print("Error in OrderCalcMargin: ", GetLastError());
            }
            if (PositionGetDouble(POSITION_TP) != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP), tpprofit))
               {
                  Print("Error in OrderCalcProfit (TP): ", GetLastError());
               }
            }
            if (PositionGetDouble(POSITION_SL) != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_SL), risk))
               {
                  Print("Error in OrderCalcProfit (SL): ", GetLastError());
               }
            }
         }
         if (PositionGetDouble(POSITION_SL) > PositionGetDouble(POSITION_TP))
         {
            if (!OrderCalcMargin(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
            {
               Print("Error in OrderCalcMargin: ", GetLastError());
            }
            if (PositionGetDouble(POSITION_TP) != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP), tpprofit))
               {
                  Print("Error in OrderCalcProfit (TP): ", GetLastError());
               }
            }
            if (PositionGetDouble(POSITION_SL) != 0)
            {
               if (!OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_SL), risk))
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
      infoRisk = "Risk: $" + DoubleToString(floatingRisk, 2) + "(" + DoubleToString(floatingRiskPercent, 1) + "%)";
   }
   else
   {
      infoRisk = "Risk: $" + DoubleToString(MathAbs(sl_risk), 2) + "(" + DoubleToString(MathAbs(percent_risk), 1) + "%)";
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
   string infoMargin = "Margin: $" + DoubleToString(total_margin, 2);
   ObjectSetString(0,"infoMargin",OBJPROP_TEXT,infoMargin);
   ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk);
   string infoLots = "Lots: " + DoubleToString(GetTotalVolumeForSymbol(_Symbol), 3);
   ObjectSetString(0,"infoLots",OBJPROP_TEXT,infoLots);
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
bool TyWindow::CreateButtonSetTP(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 4 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 +BUTTON_HEIGHT;
   if(!buttonSetTP.Create(0,"Set TP",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetTP.Text("Set TP"))
      return(false);
   if(!Add(buttonSetTP))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonSetSL(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 4 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonSetSL.Create(0,"Set SL",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetSL.Text("Set SL"))
      return(false);
   if(!Add(buttonSetSL))
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
double PerformOrderCheck(const MqlTradeRequest &request, MqlTradeCheckResult &check_result, double &OrderLots, int OrderDigits)
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
   // Round SL and TP values to the tick size
   SL = MathRound(SL / tickSize) * tickSize;
   TP = MathRound(TP / tickSize) * tickSize;
   double max_volume = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), _Digits);
   double limit_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   double existing_volume = GetTotalVolumeForSymbol(_Symbol);
   double usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
   double potentialRisk = -1;
   double OrderRisk;
   if (UseStandardRisk == true && UseDynamicRisk == false)
   {
      if (breakEvenFound == true)
      {
         // Use AdditionalRiskRatio instead of the normal Risk if a position is found to have SL at BE
         potentialRisk = (Risk * AdditionalRiskRatio);
         OrderRisk = (Risk * AdditionalRiskRatio);
      }
      else
      {
         // Use the normal Risk in every other situation
         potentialRisk = Risk + percent_risk;
         OrderRisk = Risk;
      }
      if (potentialRisk > MaxRisk)
      {
         OrderRisk = (MaxRisk - percent_risk);  // Adjust the risk for the next order
         potentialRisk = OrderRisk + percent_risk;  // Recalculate potential risk after adjusting
         order_risk_money = (AccountBalance * (OrderRisk / 100));
      }
      if (breakEvenFound == true && percent_risk > 0)
      {
         Print("Break Even positions found, and a risk position already placed. Not placing additional order.");
         return;
      }
   }
   if (UseStandardRisk == false && UseDynamicRisk == true)
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
         // Check if another position with the same order type is already open on the symbol
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
   if (UseStandardRisk == true && UseDynamicRisk == true)
   {
      Print("Cannot open order as both Standard and Dynamic Risk are enabled.  Please enable only 1 risk mode.");
   }
   double available_volume;
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   int OrderDigits = 0;
   if (min_volume == 0.001)
   {
      OrderDigits = 3;
   }
   if (min_volume == 0.01)
   {
      OrderDigits = 2;
   }
   if (min_volume == 0.1)
   {
      OrderDigits = 1;
   }
   if (min_volume == 1 || min_volume == 1000)
   {
      OrderDigits = 0;
   }
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
   if (potentialRisk > MaxRisk)
   {
      OrderRisk = (MaxRisk - percent_risk);  // Adjust the risk for the next order
      potentialRisk = OrderRisk + percent_risk;  // Recalculate potential risk after adjusting
      order_risk_money = (AccountBalance * (OrderRisk / 100));
   }
   double OrderLots   = TP > SL ? NormalizeDouble(RiskLots(_Symbol, order_risk_money, Ask - SL), OrderDigits)
                              : NormalizeDouble(RiskLots(_Symbol, order_risk_money, SL - Bid), OrderDigits);
   // Ensure that the calculated volumes do not exceed the available volume
   if (OrderLots > available_volume)
   {
      OrderLots = available_volume;
   }
   // Ensure that each order is max_volume if available_volume > max_volume
   if (available_volume > max_volume && OrderLots > max_volume)
   {
      OrderLots = max_volume;
   }
   if (OrderLots < min_volume)
   {
      //Print("Order size adjusted to minimum volume.");
      OrderLots = min_volume;
   }
   else if (OrderLots > max_volume)
   {
      //Print("Order size adjusted to maximum volume.");
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
   // Get supported filling modes
   long filling_modes = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   // Check if ORDER_FILLING_IOC filling mode is supported
   if ((filling_modes & ORDER_FILLING_IOC) != 0)
   {
      //Print("ORDER_FILLING_IOC filling mode is supported. Adjusting...");
      request.type_filling = ORDER_FILLING_IOC;
   }
   // Check if ORDER_FILLING_FOK filling mode is supported
   else if ((filling_modes & ORDER_FILLING_FOK) != 0)
   {
      //Print("ORDER_FILLING_FOK filling mode is supported. Adjusting...");
      request.type_filling = ORDER_FILLING_FOK;
   }
   // Check if ORDER_FILLING_BOC filling mode is supported
   else if ((filling_modes & ORDER_FILLING_BOC) != 0)
   {
      //Print("ORDER_FILLING_BOC filling mode is supported. Adjusting...");
      request.type_filling = ORDER_FILLING_BOC;
   }
   // Check if ORDER_FILLING_RETURN filling mode is supported
   else if ((filling_modes & ORDER_FILLING_RETURN) != 0)
   {
      //Print("ORDER_FILLING_RETURN filling mode is supported. Adjusting...");
      request.type_filling = ORDER_FILLING_RETURN;
   }
   // If none of the desired filling modes are supported, handle accordingly
   else
   {
      Print("None of the desired filling modes are supported. Unable to adjust filling mode.");
      return;
   }
   // Explicitly set the order type
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
   // Initial margin calculation before entering the loop
   if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY || request.type == ORDER_TYPE_BUY_LIMIT) ? Ask : Bid, required_margin))
   {
      Print("Failed to calculate required margin before the loop. Error:", GetLastError());
      return;
   }
   //Print("Before the Loop - OrderLots: ", OrderLots, " Required Margin: ", required_margin, " Usable Margin: ", usable_margin);
   while (required_margin > usable_margin && OrderLots > min_volume)
   {
      OrderLots -= min_volume;
      //Print("After adjustment - OrderLots: ", OrderLots, " Required Margin: ", required_margin, " Usable Margin: ", usable_margin);
      // Update usable_margin after adjusting OrderLots
      usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
      // Perform OrderCheck
      if (!PerformOrderCheck(request, check_result, OrderLots, OrderDigits))
      {
         Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
         return;
      }
    if (!OrderCalcMargin(request.type, _Symbol, OrderLots, (request.type == ORDER_TYPE_BUY || request.type == ORDER_TYPE_BUY_LIMIT) ? Ask : Bid, required_margin))
    {
    Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
    return;
      }
    // Ensure a minimum value for OrderLots
    if (OrderLots < min_volume)
    {
        OrderLots = min_volume;
    }
      //Print("After adjustment - OrderLots: ", OrderLots, " Required Margin: ", required_margin, " Usable Margin: ", usable_margin);
   }
   usable_margin = (AccountBalance - (AccountBalance * (MarginBufferPercent / 100.0))) - AccountInfoDouble(ACCOUNT_MARGIN);
   if (!PerformOrderCheck(request, check_result, OrderLots, OrderDigits))
   {
      Print("Failed to calculate required margin while adjusting OrderLots. Error:", GetLastError());
      return;
   }
   // Print statements to check required_margin and usable_margin after each iteration
   //Print("After adjustment - OrderLots: ", OrderLots, " Required Margin: ", required_margin, " Usable Margin: ", usable_margin);
   // Check if there's enough free margin to place the order
   if (required_margin >= usable_margin)
   {
      Print("Insufficient margin to place the order. Cannot proceed.");
      return;
   }
   // Check if the adjusted order size is too small
   if (OrderLots < min_volume)
   {
      Print("Order size adjusted to zero due to insufficient margin. Cannot place order.");
      return;
   }
   if (potentialRisk <= (MaxRisk))
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
            if (!PerformOrderCheck(request, check_result, OrderLots, OrderDigits))
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
            if (!PerformOrderCheck(request, check_result, OrderLots, OrderDigits))
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
            if (!PerformOrderCheck(request, check_result, OrderLots, OrderDigits))
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
            if (!PerformOrderCheck(request, check_result, OrderLots, OrderDigits))
            {
               Print("Sell OrderCheck failed, retcode=", check_result.retcode);
               return;
            }
            ExecuteSellOrder(OrderLots);
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
   else {
      ObjectDelete(0, "Limit_Line");
      LimitLineExists = false;
   }
}
void TyWindow::OnClickBuyLines(void)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   double slPrice, tpPrice;
   // Calculate the number of visible candles
   int VisibleCandles = (int) ChartGetInteger(0, CHART_VISIBLE_BARS);
   // Create arrays to store historical low and high prices
   double LowArray[];
   double HighArray[];
   // Copy historical low and high prices into the arrays
   ArraySetAsSeries(LowArray, true);
   ArraySetAsSeries(HighArray, true);
   CopyLow(Symbol(), Period(), 0, VisibleCandles, LowArray);
   CopyHigh(Symbol(), Period(), 0, VisibleCandles, HighArray);
   // Calculate the lowest and highest prices within the visible range
   double LowestPrice = LowArray[0];
   double HighestPrice = HighArray[0];
   for (int i = 1; i < VisibleCandles; i++)
   {
      if (LowArray[i] < LowestPrice)
         LowestPrice = LowArray[i];
      if (HighArray[i] > HighestPrice)
         HighestPrice = HighArray[i];
   }
   // Check if there's an active buy position on the symbol
   if(PositionSelect(Symbol()))
   {
      // Get the SL and TP prices of the existing position
      slPrice = PositionGetDouble(POSITION_SL);
      tpPrice = PositionGetDouble(POSITION_TP);
   }
   else 
   {
       // Use the lowest and highest prices within the visible range
       slPrice = LowestPrice;
       tpPrice = HighestPrice;
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
void TyWindow::OnClickSellLines(void)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   double slPrice, tpPrice;
   // Calculate the number of visible candles
   int VisibleCandles = (int) ChartGetInteger(0, CHART_VISIBLE_BARS);
   // Create arrays to store historical low and high prices
   double LowArray[];
   double HighArray[];
   // Copy historical low and high prices into the arrays
   ArraySetAsSeries(LowArray, true);
   ArraySetAsSeries(HighArray, true);
   CopyLow(Symbol(), Period(), 0, VisibleCandles, LowArray);
   CopyHigh(Symbol(), Period(), 0, VisibleCandles, HighArray);
   // Calculate the lowest and highest prices within the visible range
   double LowestPrice = LowArray[0];
   double HighestPrice = HighArray[0];
   for (int i = 1; i < VisibleCandles; i++)
   {
      if (LowArray[i] < LowestPrice)
         LowestPrice = LowArray[i];
      if (HighArray[i] > HighestPrice)
         HighestPrice = HighArray[i];
   }
   // Check if there's an active sell position on the symbol
   if(PositionSelect(Symbol()))
   {
      // Get the SL and TP prices of the existing position
      slPrice = PositionGetDouble(POSITION_SL);
      tpPrice = PositionGetDouble(POSITION_TP);
   }
   else
   {
      // Use the lowest and highest prices within the visible range
      slPrice = HighestPrice;
      tpPrice = LowestPrice;
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
void TyWindow::OnClickDestroyLines(void)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   LimitLineExists = false;
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
void Protect()
{
   Trade.SetAsyncMode(true);
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
      {
         double EntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double OriginalSL = PositionGetDouble(POSITION_SL);
         // Round the OriginalSL to the tick size
         double tickSize = TickSize(_Symbol);
         OriginalSL = MathRound(OriginalSL / tickSize) * tickSize;
         if (OriginalSL == EntryPrice)
         {
            Print("SL for Position #", ticket, " is already at breakeven."); // Convert ticket to string for printing
         }
         if (!Trade.PositionModify(ticket, EntryPrice, PositionGetDouble(POSITION_TP)))
         {
            Print("Failed to modify SL via PROTECT for Position #", ticket, ". Error code: ", GetLastError());
         }
         else
         {
            Print("SL for Position #", ticket, " moved to breakeven.");
         }
      }
   }
   // Wait for the asynchronous operations to complete
   int timeout = 3000; // Set a timeout (in milliseconds) to wait for order execution
   uint startTime = GetTickCount();
   while (PositionsTotal() > 0 && (GetTickCount() - startTime) < (uint) timeout)
   {
      //Print("Waiting for SL modification asynchronously...");
      Sleep(100); // Sleep for a short duration
   }
   if (PositionsTotal() == 0)
   {
      Print("SL modification for all positions completed successfully.");
   }
   else
   {
      Print("Failed to modify SL for all positions within the specified timeout.");
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
void TyWindow::OnClickSetTP(void)
{
   double newTP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   if (newTP != TP && newTP != 0) // Check if TP value is changed and not equal to 0
   {
      // Get tick size of the symbol
      double tickSize = TickSize(_Symbol);
      // Round TP value to the tick size
      newTP = MathRound(newTP / tickSize) * tickSize;
      TP = newTP;
      Trade.SetAsyncMode(true);
      int modifiedPositions = 0; // Variable to keep track of the number of modified positions
      for (int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
         {
            double OriginalTP = PositionGetDouble(POSITION_TP);
            if (OriginalTP != TP) // Check if TP value is different from the original value
            {
               if (!Trade.PositionModify(ticket, PositionGetDouble(POSITION_SL), TP))
               {
                  Print("Failed to modify TP. Error code: ", GetLastError());
               }
               else
               {
                  Print("TP modified for Position #", ticket, ". Original TP: ", OriginalTP, " | New TP: ", TP);
                  modifiedPositions++; // Increment modifiedPositions when a position is successfully modified
               }
            }
         }
      }
      // Wait for the asynchronous operations to complete
      int timeout = 3000; // Set a timeout (in milliseconds) to wait for order execution
      uint startTime = GetTickCount();
      while (modifiedPositions < PositionsTotal() && (GetTickCount() - startTime) < (uint) timeout)
      {
         Sleep(100); // Sleep for a short duration
      }
      if (modifiedPositions == PositionsTotal())
      {
         Print("TP modification for all positions completed successfully.");
      }
      else
      {
         Print("Failed to modify TP for all positions within the specified timeout.");
      }
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
      Trade.SetAsyncMode(true);
      int modifiedPositions = 0; // Variable to keep track of the number of modified positions
      for (int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if (ProcessPositionCheck(ticket, _Symbol, MagicNumber))
         {
            double OriginalSL = PositionGetDouble(POSITION_SL);
            if (OriginalSL != SL) // Check if SL value is different from the original value
            {
               if (!Trade.PositionModify(ticket, SL, PositionGetDouble(POSITION_TP)))
               {
                  Print("Failed to modify SL. Error code: ", GetLastError());
               }
               else
               {
                  Print("SL modified for Order #", ticket, ". Original SL: ", OriginalSL, " | New SL: ", SL);
                  modifiedPositions++; // Increment modifiedPositions when a position is successfully modified
               }
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
         Print("SL modification for all positions completed successfully.");
      }
      else
      {
         Print("Failed to modify SL for all positions within the specified timeout.");
      }
   }
   AutoProtectCalled = false;
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
         ChartRedraw();
      }
   }
   return(CDialog::OnDialogDragEnd());
}
