/**=             TyphooN.mq5  (TyphooN's MQL5 Risk Management System)
 *               Copyright 2023, TyphooN (https://www.decapool.net/)
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
#property copyright "Copyright 2023 TyphooN (Decapool.net)"
#property link      "http://www.mql5.com"
#property version   "1.123"
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
input group    "User Vars";
input double   Risk                    = 0.5;
input int      OrdersToPlace           = 3;
input int      ProtectPositionsToClose = 1;
input bool     EnableAutoProtect       = true;
input double   AutoProtectRRLevel      = 2.69666420;
input double   SLPips                  = 4.0;
input double   TPPips                  = 13.0;
input int      MagicNumber             = 13;
input int      HorizontalLineThickness = 3;
// global vars
double TP = 0;
double SL = 0;
double Bid = 0;
double Ask = 0;
double risk_money = 0;
double lotsglobal = 0;
bool LimitLineExists = false;
// defines
#define INDENT_LEFT       (10)      // indent from left (with allowance for border width)
#define INDENT_TOP        (10)      // indent from top (with allowance for border width)
#define CONTROLS_GAP_X    (5)       // gap by X coordinate
#define BUTTON_WIDTH      (100)     // size by X coordinate
#define BUTTON_HEIGHT     (20)      // size by Y coordinate
#define CONTROLS_GAP_Y    (23)      // gap by Y coordinate
// Class CControlsDialog
// Usage: main dialog of the Controls application
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
      CButton           buttonClosePositions;
      CButton           buttonCloseLimits;
      CButton           buttonSetTP;
      CButton           buttonSetSL;
   public:
                              TyWindow(void);
                              ~TyWindow(void);
      // create
      virtual bool            Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
      // handlers of drag
      virtual bool      OnDialogDragStart(void);
      virtual bool      OnDialogDragProcess(void);
      virtual bool      OnDialogDragEnd(void);
      // chart event handler
      virtual bool            OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   protected:
      // create dependent controls
      bool              CreateButtonTrade(void);
      bool              CreateButtonLimit(void);
      bool              CreateButtonBuyLines(void);
      bool              CreateButtonSellLines(void);
      bool              CreateButtonDestroyLines(void);
      bool              CreateButtonProtect(void);
      bool              CreateButtonClosePositions(void);
      bool              CreateButtonCloseLimits(void);
      bool              CreateButtonSetTP(void);
      bool              CreateButtonSetSL(void);
      // handlers of the dependent controls events
      void              OnClickTrade(void);
      void              OnClickLimit(void);
      void              OnClickBuyLines(void);
      void              OnClickSellLines(void);
      void              OnClickDestroyLines(void);
      void              OnClickProtect(void);
      void              OnClickClosePositions(void);
      void              OnClickCloseLimits(void);
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
ON_EVENT(ON_CLICK, buttonClosePositions, OnClickClosePositions)
ON_EVENT(ON_CLICK, buttonCloseLimits, OnClickCloseLimits)
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
// Create
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
   if(!CreateButtonClosePositions())
      return(false);
   if(!CreateButtonCloseLimits())
      return(false);
      if(!CreateButtonSetTP())
   return(false);
      if(!CreateButtonSetSL())
   return(false);
   // succeed
   return(true);
}
// Global Variable
TyWindow ExtDialog;
// Expert initialization function
int OnInit()
{
// create application dialog
if(!ExtDialog.Create(0,"TyphooN Risk Management",0,40,40,272,200))
   return(INIT_FAILED);
   // run application
   ExtDialog.Run();
   // succeed
   return(INIT_SUCCEEDED);
  }
// Expert deinitialization function
void OnDeinit(const int reason)
{
   ExtDialog.Destroy(reason);
   //ObjectsDeleteAll(0, "info");
}
string TimeTilNextBar(ENUM_TIMEFRAMES tf=PERIOD_CURRENT)
{
   datetime now=TimeCurrent();
   datetime bartime=iTime(NULL,tf,0);
   datetime remainingTime=bartime+PeriodSeconds(tf)-now;
   MqlDateTime mdt;
   TimeToStruct(remainingTime,mdt);
   if(mdt.day_of_year>0) return StringFormat("%dD %dH %dM",mdt.day_of_year,mdt.hour,mdt.min);
   if(mdt.hour>0) return StringFormat("%dH %dM %ds",mdt.hour,mdt.min,mdt.sec);
   if(mdt.min>0) return StringFormat("%dM %ds",mdt.min,mdt.sec);
   return StringFormat("%ds",mdt.sec);
}
double PointValue() {
   double tickSize      = TickSize( _Symbol );
   double tickValue     = TickValue( _Symbol );
   double point         = Point( _Symbol );
   double ticksPerPoint = tickSize / point;
   double pointValue    = tickValue / ticksPerPoint;
 //  PrintFormat( "tickSize=%f, tickValue=%f, point=%f, ticksPerPoint=%f, pointValue=%f",
 //               tickSize, tickValue, point, ticksPerPoint, pointValue );
   return ( pointValue );
}
void OnTick()
{
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   risk_money = (AccountInfoDouble(ACCOUNT_BALANCE) * (Risk / 100));
   double total_risk = 0;
   double total_tpprofit = 0;
   double total_pl = 0;
   double total_tp = 0;
   double total_margin = 0;
   double rr = 0;
   double tprr = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetSymbol(i) != _Symbol) continue;
         double profit = PositionGetDouble(POSITION_PROFIT);
         double risk = 0;
         double tpprofit = 0;
         double margin = 0;
         if (PositionGetDouble(POSITION_TP) > PositionGetDouble(POSITION_SL))
         {
            if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
            {
               Print(GetLastError());
            }
            if (!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP), tpprofit))
            {
               Print(GetLastError());
            }
            if (!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_SL), risk))
            {
               Print(GetLastError());
            }
         }
         if (PositionGetDouble(POSITION_SL) > PositionGetDouble(POSITION_TP))
         {
            if (!OrderCalcMargin(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), margin))
            {
               Print(GetLastError());
            }
            if (!OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP), tpprofit))
            {
               Print(GetLastError());
            }
            if (!OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_SL), risk))
            {
               Print(GetLastError());
            }
         }
         total_pl += profit;
         total_risk += risk;
         total_tp += tpprofit;
         total_margin += margin;
         tprr = total_tp/MathAbs(total_risk);
         rr = total_pl/MathAbs(total_risk);
      }
   }
   if (EnableAutoProtect==true)
   {
         if (rr >= AutoProtectRRLevel && total_risk < 0)
         {
            Print ("Auto Protect has removed risk due to RR >= " + DoubleToString(AutoProtectRRLevel,8));
            AutoProtect();
         }
   }
   string FontName="Courier New";
   int FontSize=8;
   int LeftColumnX=310;
   int RightColumnX=150;
   int YRowWidth = 13;
   string infoPL;
   string infoRR;
   if (rr >= 0 )
   {
      infoRR = "RR : " + DoubleToString(rr, 2);
   }
   if (rr <= 0)
   {
      infoRR = "RR : N/A";
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
   ObjectCreate(0,"infoPL", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoPL",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoPL",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoPL",OBJPROP_TEXT,infoPL);
   ObjectSetInteger(0,"infoPL", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoPL",OBJPROP_YDISTANCE,(YRowWidth * 2));
   ObjectSetInteger(0,"infoPL",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoPL",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoRisk = "Risk: $" + DoubleToString(MathAbs(total_risk), 2);
   string infoTPRR = "TP RR: " + DoubleToString(tprr, 2);
   if (total_risk <= 0)
   {
      infoRisk = "Risk: $" + DoubleToString(MathAbs(total_risk), 2);
   }
   else if (total_risk > 0)
   {
      infoRisk = "SL Profit: $" + DoubleToString(total_risk, 2);
   }
   ObjectCreate(0,"infoRisk", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoRisk",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoRisk",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk);
   ObjectSetInteger(0,"infoRisk", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoRisk",OBJPROP_YDISTANCE,(YRowWidth * 2));
   ObjectSetInteger(0,"infoRisk",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoRisk",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoTP = "Total TP : $" + DoubleToString(total_tp, 2);
   ObjectCreate(0,"infoTP", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoTP",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoTP",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoTP",OBJPROP_TEXT,infoTP);
   ObjectSetInteger(0,"infoTP", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoTP",OBJPROP_YDISTANCE,(YRowWidth * 3));
   ObjectSetInteger(0,"infoTP",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoTP",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoMargin = "Margin: $" + DoubleToString(total_margin, 2);
   ObjectCreate(0,"infoMargin", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoMargin",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoMargin",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoMargin",OBJPROP_TEXT,infoMargin);
   ObjectSetInteger(0,"infoMargin", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoMargin",OBJPROP_YDISTANCE,(YRowWidth * 3));
   ObjectSetInteger(0,"infoMargin",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoMargin",OBJPROP_CORNER,CORNER_RIGHT_UPPER); 
   ObjectCreate(0,"infoTPRR", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoTPRR",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoTPRR",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoTPRR",OBJPROP_TEXT,infoTPRR);
   ObjectSetInteger(0,"infoTPRR", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoTPRR",OBJPROP_YDISTANCE,(YRowWidth * 4));
   ObjectSetInteger(0,"infoTPRR",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoTPRR",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectCreate(0,"infoRR", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoRR",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoRR",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoRR",OBJPROP_TEXT,infoRR);
   ObjectSetInteger(0,"infoRR", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoRR",OBJPROP_YDISTANCE,(YRowWidth * 4));
   ObjectSetInteger(0,"infoRR",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoRR",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoM15 = "M15: " + TimeTilNextBar(PERIOD_M15);
   ObjectCreate(0,"infoM15", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoM15",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoM15",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoM15",OBJPROP_TEXT,infoM15);
   ObjectSetInteger(0,"infoM15", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoM15",OBJPROP_YDISTANCE,(YRowWidth * 5));
   ObjectSetInteger(0,"infoM15",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoM15",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoH4 = "H4 : " + TimeTilNextBar(PERIOD_H4);
   ObjectCreate(0,"infoH4", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoH4",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoH4",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoH4",OBJPROP_TEXT,infoH4);
   ObjectSetInteger(0,"infoH4", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoH4",OBJPROP_YDISTANCE,(YRowWidth * 6));
   ObjectSetInteger(0,"infoH4",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoH4",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoW1 = "W1 : " + TimeTilNextBar(PERIOD_W1);
   ObjectCreate(0,"infoW1", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoW1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoW1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoW1",OBJPROP_TEXT,infoW1);
   ObjectSetInteger(0,"infoW1", OBJPROP_XDISTANCE, LeftColumnX);
   ObjectSetInteger(0,"infoW1",OBJPROP_YDISTANCE,(YRowWidth * 7));
   ObjectSetInteger(0,"infoW1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoW1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoH1 ="H1 : " + TimeTilNextBar(PERIOD_H1);
   ObjectCreate(0,"infoH1", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoH1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoH1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoH1",OBJPROP_TEXT,infoH1);
   ObjectSetInteger(0,"infoH1", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoH1",OBJPROP_YDISTANCE,(YRowWidth * 5));
   ObjectSetInteger(0,"infoH1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoH1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoD1 = "D1 : " + TimeTilNextBar(PERIOD_D1);
   ObjectCreate(0,"infoD1", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoD1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoD1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoD1",OBJPROP_TEXT,infoD1);
   ObjectSetInteger(0,"infoD1", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoD1",OBJPROP_YDISTANCE,(YRowWidth * 6));
   ObjectSetInteger(0,"infoD1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoD1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string infoMN1 = "MN1: " + TimeTilNextBar(PERIOD_MN1);
   ObjectCreate(0,"infoMN1", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"infoMN1",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoMN1",OBJPROP_FONTSIZE,FontSize);
   ObjectSetString(0,"infoMN1",OBJPROP_TEXT,infoMN1);
   ObjectSetInteger(0,"infoMN1", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoMN1",OBJPROP_YDISTANCE,(YRowWidth * 7));
   ObjectSetInteger(0,"infoMN1",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoMN1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
}
// Expert chart event function
void OnChartEvent(const int id,         // event ID  
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
{
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
}
bool TyWindow::CreateButtonTrade(void)
{
   // coordinates
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonTrade.Create(0,"Open Trade",0,x1,y1,x2,y2))
      return(false);
   if(!buttonTrade.Text("Open Trade"))
      return(false);
   if(!Add(buttonTrade))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonLimit(void)
{
   // coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonLimit.Create(0,"Limit Line",0,x1,y1,x2,y2))
      return(false);
   if(!buttonLimit.Text("Limit Line"))
      return(false);
   if(!Add(buttonLimit))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonBuyLines(void)
{
   // coordinates
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonBuyLines.Create(0,"Buy Lines",0,x1,y1,x2,y2))
      return(false);
   if(!buttonBuyLines.Text("Buy Lines"))
      return(false);
   if(!Add(buttonBuyLines))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonSellLines(void)
{
   // coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonSellLines.Create(0,"Sell Lines",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSellLines.Text("Sell Lines"))
      return(false);
   if(!Add(buttonSellLines))
      return(false);
   // succeed
   return(true);
} 
bool TyWindow::CreateButtonDestroyLines(void)
{
   // coordinates
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 2 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonDestroyLines.Create(0,"Destroy Lines",0,x1,y1,x2,y2))
      return(false);
   if(!buttonDestroyLines.Text("Destroy Lines"))
      return(false);
   if(!Add(buttonDestroyLines))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonProtect(void)
{
   // coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 2 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonProtect.Create(0,"PROTECT",0,x1,y1,x2,y2))
      return(false);
   if(!buttonProtect.Text("PROTECT"))
      return(false);
   if(!Add(buttonProtect))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonClosePositions(void)
{
   // coordinates
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 3 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonClosePositions.Create(0,"Close Positions",0,x1,y1,x2,y2))
      return(false);
   if(!buttonClosePositions.Text("Close Positions"))
      return(false);
   if(!Add(buttonClosePositions))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonCloseLimits(void)
{
   // coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 3 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonCloseLimits.Create(0,"Close Limits",0,x1,y1,x2,y2))
      return(false);
   if(!buttonCloseLimits.Text("Close Limits"))
      return(false);
   if(!Add(buttonCloseLimits))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonSetTP(void)
{
   // coordinates
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 4 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 +BUTTON_HEIGHT;
   // create
   if(!buttonSetTP.Create(0,"Set TP",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetTP.Text("Set TP"))
      return(false);
   if(!Add(buttonSetTP))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonSetSL(void)
{
   // coordinates
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 4 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   // create
   if(!buttonSetSL.Create(0,"Set SL",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetSL.Text("Set SL"))
      return(false);
   if(!Add(buttonSetSL))
      return(false);
   // succeed
   return(true);
}
void TyWindow::OnClickTrade(void)
{
   SL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
   TP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   double max_volume = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),_Digits);
   double min_volume = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   Trade.SetExpertMagicNumber(MagicNumber);
   int OrderDigits = 0;
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
   if (LimitLineExists == true) {
      double Limit_Price = ObjectGetDouble(0, "Limit_Line", OBJPROP_PRICE, 0);
      if(TP > SL){
         lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, Ask - SL)/OrdersToPlace,OrderDigits);
         if(lotsglobal > max_volume)
         {
            lotsglobal = max_volume;
         }
         for(int i=0; i<OrdersToPlace; i++){
             if (Trade.BuyLimit(lotsglobal, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
             {
                Print("Buy Limit opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(OrdersToPlace));
             }
             else
             {
                Print("Failed to open buy limit, error: " + IntegerToString(Trade.ResultRetcode()) + " | " + Trade.ResultRetcodeDescription());
             }
         }
      }
      else if (SL > TP){
         lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, SL - Bid)/OrdersToPlace,OrderDigits);
         if(lotsglobal > max_volume)
         {
            lotsglobal = max_volume;
         }
         for(int i=0; i<OrdersToPlace; i++){
             if (Trade.SellLimit(lotsglobal, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
             {
                Print("Sell Limit opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(OrdersToPlace));
             }
             else
             {
                Print("Failed to open sell limit, error: " + IntegerToString(Trade.ResultRetcode()) + " | " + Trade.ResultRetcodeDescription());
             }
         }
      }
   }
   else if (LimitLineExists == false){
      if(TP > SL){
         lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, Ask - SL)/OrdersToPlace,OrderDigits);
         if(lotsglobal > max_volume)
         {
              lotsglobal = max_volume;
         }
         for(int i=0; i<OrdersToPlace; i++){
            if(Trade.Buy(lotsglobal, NULL, 0, SL, TP, NULL))
            {
                Print("Buy trade opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(OrdersToPlace));
            }
            else
            {
                Print("Failed to open buy trade, error: " + IntegerToString(Trade.ResultRetcode()) + " | " + Trade.ResultRetcodeDescription());
            }
         }
      }
      else if (SL > TP){
      lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, SL - Bid)/OrdersToPlace,OrderDigits);
         if(lotsglobal > max_volume)
         {
             lotsglobal = max_volume;
         }
         for(int i=0; i<OrdersToPlace; i++){
             if(Trade.Sell(lotsglobal, NULL, 0, SL, TP, NULL))
             {
              Print("Sell trade opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(OrdersToPlace));
             }
             else
             {
                Print("Failed to open sell trade, error: " + IntegerToString(Trade.ResultRetcode()) + " | " + Trade.ResultRetcodeDescription());
             }
         }
         ObjectDelete(0, "Limit_Line");  
   }
   }
}
void TyWindow::OnClickLimit(void)
{
   if (!LimitLineExists) {
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
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double DigitMulti = 0;
   if (_Digits == 2)
   {
      if (_Symbol == "XAUUSD")
      {
         DigitMulti = 1;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
      }
      if (_Symbol == "LTCUSD")
      {
         DigitMulti = 10;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
      }
      else
      {
         DigitMulti = 1000;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
      }
   }
   if(_Digits == 3)
   {
      if (_Symbol == "XAGUSD")
      {
         DigitMulti = 0.0001;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
      }
      if (_Symbol == "USOIL.cash" || _Symbol == "UKOIL.cash" || _Symbol == "USOUSD" || _Symbol == "UKOUSD")
      {
         DigitMulti = 1;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
      }
      else
      {
         DigitMulti = 0.001;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
      }
   }
   if(_Digits == 4)
   {
      DigitMulti = 1;
      ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
      ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
   }
   if(_Digits == 5)
   {
      DigitMulti = 0.0002;
      ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
      ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
   }
   if(_Digits == 7)
   {
      DigitMulti = 1000;
      ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
      ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
   }
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "SL_Line", OBJPROP_SELECTABLE, 1);
   ObjectSetInteger(0, "SL_Line", OBJPROP_BACK, true);
   ObjectSetInteger(0, "TP_Line", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "TP_Line", OBJPROP_SELECTABLE, 1);
   ObjectSetInteger(0, "TP_Line", OBJPROP_BACK, true);
}
void TyWindow::OnClickSellLines(void)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double DigitMulti = 0;
   if (_Digits == 2)
   {
      if (_Symbol == "XAUUSD")
      {
         DigitMulti = 1;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
      }
      if (_Symbol == "LTCUSD")
      {
         DigitMulti = 10;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
      }
      else
      {
         DigitMulti = 1000;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
      }
   }
   if (_Digits == 3)
   {
      if (_Symbol == "XAGUSD")
      {
         DigitMulti = 0.0001;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
      }
      if (_Symbol == "USOIL.cash" || _Symbol == "UKOIL.cash" || _Symbol == "USOUSD" || _Symbol == "UKOUSD")
      {
         DigitMulti = 1;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
      }
      else
      {
         DigitMulti = 0.001;
         ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
         ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
      }
   }
   if(_Digits == 4)
   {
      DigitMulti = 1;
      ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
      ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));  
   }
   if(_Digits == 5)
   {
      DigitMulti = 0.0002;
      ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
      ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));  
   }
   if(_Digits == 7)
   {
      DigitMulti = 1000;
      ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
      ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));  
   }
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "SL_Line", OBJPROP_SELECTABLE, 1);
   ObjectSetInteger(0, "SL_Line", OBJPROP_BACK, true);
   ObjectSetInteger(0, "TP_Line", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_Line", OBJPROP_WIDTH,HorizontalLineThickness);
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
struct PositionInfo {
   ulong ticket;
   double diff;
};
void BubbleSort(PositionInfo &arr[]) {
   for (int i = 0; i < ArraySize(arr); i++) {
      for (int j = 0; j < ArraySize(arr) - i - 1; j++) {
         if (arr[j].diff > arr[j+1].diff) {
            PositionInfo temp = arr[j];
            arr[j] = arr[j+1];
            arr[j+1] = temp;
         }
      }
   }
}
void AutoProtect()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   PositionInfo positionsArray[];
   ArrayResize(positionsArray, PositionsTotal());
   for (int i = 0; i < PositionsTotal(); i++) {
      if (PositionSelectByTicket(PositionGetTicket(i))) {
         if (PositionGetSymbol(i) != _Symbol) continue;
         if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         double diff = MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - currentPrice);
         positionsArray[i].diff = diff;
         positionsArray[i].ticket = PositionGetTicket(i);
      }
   }
   BubbleSort(positionsArray);
   int ClosedPositions=0;
   int PositionsToClose = (int)MathCeil(((double)ArraySize(positionsArray)) * ((double)ProtectPositionsToClose/OrdersToPlace));
   if(PositionsTotal() == 1) {
      SL = PositionGetDouble(POSITION_PRICE_OPEN);
      if (!Trade.PositionModify(positionsArray[0].ticket, SL, PositionGetDouble(POSITION_TP))) {
         Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
      }
   } else {
      for (int i = 0; i < ArraySize(positionsArray); i++) {
         if (PositionSelectByTicket(positionsArray[i].ticket)) {
            if (ClosedPositions < PositionsToClose) {
               Print("Closing Position " + IntegerToString(i+1) + "/" + IntegerToString(PositionsToClose) + ".");
               if (!Trade.PositionClose(positionsArray[i].ticket)) {
                  Print("Failed to close position " + IntegerToString(i+1) + "/" + IntegerToString(PositionsToClose) + ". Error code: ", GetLastError());
               } else {
                  Print("Position " + IntegerToString(i+1) + "/" + IntegerToString(PositionsToClose) + " closed successfully.");
                  ClosedPositions++;
                  PositionsToClose = PositionsToClose - 1;  // ensure we decrease the PositionsToClose after successful closure
               }
            }
            else {
               SL = PositionGetDouble(POSITION_PRICE_OPEN);
               if (!Trade.PositionModify(positionsArray[i].ticket, SL, PositionGetDouble(POSITION_TP))) {
                  Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
               }
            }
         }
      }
   }
}
void Protect()
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
      if (PositionGetSymbol(i) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      SL = PositionGetDouble(POSITION_PRICE_OPEN);
      if(!Trade.PositionModify(PositionGetTicket(i), SL, PositionGetDouble(POSITION_TP)))
         Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
      }
      }
}
void TyWindow::OnClickProtect(void)
{
   Protect();
}
void TyWindow::OnClickClosePositions(void)
{
int result = MessageBox("Do you want to close all positions on " + _Symbol + "?", "Close Positions", MB_YESNO | MB_ICONQUESTION);
   if (result == IDNO)
   {
      Print("Positions not closed.");
   }
   if (result == IDYES)
   {
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
   if (PositionGetSymbol(i) != _Symbol) continue;
   if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
   {
      if(Trade.PositionClose(Position.Ticket()))
      {
         Print("Position #", Position.Ticket(), " closed");
      }
      else
      {
         Print("Position #", Position.Ticket(), " close failed with error ", GetLastError());
      }
    }
    }
    }
}
void TyWindow::OnClickCloseLimits(void)
{
   int result = MessageBox("Do you want to close all limit orders?", "Close Limit Orders", MB_YESNO | MB_ICONQUESTION);
   if (result == IDNO)
   {
      Print("Limit orders not closed.");
   }
   if (result == IDYES)
   {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
         if(Order.SelectByIndex(i))
         {
           if(Order.Magic() != MagicNumber ) continue;
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
}
void TyWindow::OnClickSetTP(void)
{
   TP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   if (TP != 0)
   {
      for (int i = 0; i < PositionsTotal(); i++)
      {
         if (PositionSelectByTicket(PositionGetTicket(i)))
         {
            if (PositionGetSymbol(i) != _Symbol) continue;
            if (PositionGetInteger(POSITION_MAGIC)!= MagicNumber) continue;
            if (!Trade.PositionModify(PositionGetTicket(i), PositionGetDouble(POSITION_SL), TP))
            {
               Print("Failed to modify TP. Error code: ", GetLastError());
            }
         }
      }
   }
}
void TyWindow::OnClickSetSL(void)
{
   SL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
   if (SL != 0)
   {
      for (int i = 0; i < PositionsTotal(); i++)
      {
         if (PositionSelectByTicket(PositionGetTicket(i)))
         {
            if (PositionGetSymbol(i) != _Symbol) continue;
            if (PositionGetInteger(POSITION_MAGIC)!= MagicNumber) continue;
            if (!Trade.PositionModify(PositionGetTicket(i), SL, PositionGetDouble(POSITION_TP)))
            {
               Print("Failed to modify SL. Error code: ", GetLastError());
            }
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
         ChartRedraw();
      }
   }
   return(CDialog::OnDialogDragEnd());
}
