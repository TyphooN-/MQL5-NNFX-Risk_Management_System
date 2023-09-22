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
#property version   "1.167"
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
input double   MaxRisk                    = 1.5;
input double   Risk                       = 1.0;
input int      InitialOrdersToPlace       = 3;
input group    "[ACCOUNT PROTECTION SETTINGS]";
input bool     EnableAutoProtect          = true;
input int      APCloseDivider             = 3;
input int      APPositionsToClose         = 1;
input int      APStartHour                = 20;
input int      APStopHour                 = 24;
input double   APRRLevel                  = 3.1415926535897932384626433832795;
input group    "[POSITION MANAGEMENT SETTINGS]";
input int      SLPips                     = 4;
input int      TPPips                     = 13;
input group    "[EXPERT ADVISOR SETTINGS]";
input int      MagicNumber                = 13;
input int      HorizontalLineThickness    = 3;
input bool     ManageAllPositions         = false;
// global vars
double TP = 0;
double SL = 0;
double Bid = 0;
double Ask = 0;
double order_risk_money = 0;
bool LimitLineExists = false;
bool AutoProtectCalled = false;
double DigitMulti = 0;
double percent_risk = 0;
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
      CButton           buttonClosePositions;
      CButton           buttonCloseLimits;
      CButton           buttonSetTP;
      CButton           buttonSetSL;
   public:
      TyWindow(void);
      ~TyWindow(void);
      void ExecuteBuyLimitOrders(double lots, double Limit_Price, int Orders);
      void ExecuteSellLimitOrders(double lots, double Limit_Price, int Orders);
      void ExecuteBuyOrders(double lots, int Orders);
      void ExecuteSellOrders(double lots, int Orders);
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
   return(true);
}
// Global Variable
TyWindow ExtDialog;
int OnInit()
{
   if (_Digits == 2)
   {
      if (_Symbol == "XAUUSD")
      {
         DigitMulti = 0.1;
      }
      else if (_Symbol == "US30.cash" || _Symbol == "US500.cash" || _Symbol == "US100.cash" || _Symbol == "NDX100" || _Symbol == "SPX500" || _Symbol == "US30")
      {
         DigitMulti = 100;
      }
      else
      {
         DigitMulti = 10;
      }
   }
   if (_Digits == 3)
   {
      if (_Symbol == "XAGUSD")
      {
         DigitMulti = 0.0001;
      }
      if (_Symbol == "USOIL.cash" || _Symbol == "UKOIL.cash" || _Symbol == "USOUSD" || _Symbol == "UKOUSD")
      {
         DigitMulti = 1;
      }
      else
      {
         DigitMulti = 0.001;
      }
   }
   if (_Digits == 4)
   {
      DigitMulti = 1;
   }
   if (_Digits == 5)
   {
      DigitMulti = 0.0002;
   }
   if (_Digits == 7)
   {
      DigitMulti = 1000;
   }
   string FontName="Courier New";
   int FontSize=8;
   int LeftColumnX=310;
   int RightColumnX=150;
   int YRowWidth = 13;
   // Create background rectangle
   //CreateLabelBackground("info", 469, 105, 312, 160);
   ObjectCreate(0,"infoSLPL", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoTP", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoMargin", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoTPRR", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoRR", OBJ_LABEL,0,0,0);
   ObjectCreate(0,"infoSLP", OBJ_LABEL,0,0,0);
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
   ObjectSetString(0,"infoSLP",OBJPROP_FONT,FontName);
   ObjectSetInteger(0,"infoSLP",OBJPROP_FONTSIZE,FontSize);
   ObjectSetInteger(0,"infoSLP", OBJPROP_XDISTANCE, RightColumnX);
   ObjectSetInteger(0,"infoSLP",OBJPROP_YDISTANCE,(YRowWidth * 4));
   ObjectSetInteger(0,"infoSLP",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"infoSLP",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
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
   string infoTP = "Total TP : $0.00";
   ObjectSetString(0,"infoTP",OBJPROP_TEXT,infoTP);
   string infoMargin = "Margin: $0.00";
   ObjectSetString(0,"infoMargin",OBJPROP_TEXT,infoMargin);
   string infoRisk = "Risk: $0.00";
   ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk);
   string infoSLP = "SL Profit: $0.00";
   ObjectSetString(0,"infoSLP",OBJPROP_TEXT,infoSLP);
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
   // set ZORDER for supporting indicators
   //SetZOrder("MTF_MA_", 1);
   //SetZOrder("Projected ATR", 1);
   //SetZOrder("info", 1);
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
void CreateLabelBackground(string objName, int x, int y, int width, int height, color colour = clrBlack)
{
   ObjectCreate(0, objName + "_bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_COLOR, colour);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_BGCOLOR, colour);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_BORDER_COLOR, colour);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_XDISTANCE, x - width / 2);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_YDISTANCE, y - height / 2);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_YSIZE, height);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, objName + "_bg", OBJPROP_ZORDER, 0);
   // set ZORDER for supporting indicators
   //SetZOrder("MTF_MA_", 1);
   //SetZOrder("Projected ATR", 1);
   //SetZOrder("info", 1);
}
void SetZOrder(string prefix, int zorder)
{
   int totalObjects = ObjectsTotal(0);
   for (int i = 0; i < totalObjects; i++)
   {
      string objName = ObjectName(0, i);
      if (StringFind(objName, prefix) == 0)
      {
         ObjectSetInteger(0, objName, OBJPROP_ZORDER, zorder);
      }
   }
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
void OnTick()
{
   // Filter AutoProtect to only execute during user defined window
   MqlDateTime time;TimeCurrent(time);
   bool APFilter=(APStartHour < APStopHour && (time.hour >= APStartHour && time.hour < APStopHour )) || (APStartHour > APStopHour && (time.hour >= APStartHour || time.hour < APStopHour));
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   order_risk_money = (AccountInfoDouble(ACCOUNT_BALANCE) * (Risk / 100));
   double total_risk = 0;
   double total_tpprofit = 0;
   double total_pl = 0;
   double total_tp = 0;
   double total_margin = 0;
   double rr = 0;
   double tprr = 0;
   double sl_profit = 0;
   double sl_risk = 0;
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   bool breakEvenFound = false;
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         bool ShouldProcessPosition = ProcessPositionCheck(ticket, _Symbol, MagicNumber, ManageAllPositions);
         if (!ShouldProcessPosition) continue;
         double profit = PositionGetDouble(POSITION_PROFIT);
         double risk = 0;
         double tpprofit = 0;
         double margin = 0;
         if (PositionGetDouble(POSITION_SL) == PositionGetDouble(POSITION_PRICE_OPEN))
         {
            breakEvenFound = true;
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
         if (risk < 0)
         {
            sl_risk += risk;
         }
         else if (risk > 0)
         {
            sl_profit += risk;
         }
         total_pl += profit;
         total_risk += risk;
         total_tp += tpprofit;
         total_margin += margin;
         tprr = total_tp/MathAbs(total_risk);
         rr = total_pl/MathAbs(total_risk);
         percent_risk = MathAbs((sl_risk / account_balance) * 100);
      }
   }
   if (EnableAutoProtect == true && AutoProtectCalled == false && breakEvenFound == false && APFilter == true)
   {
         if (rr >= APRRLevel && sl_risk < 0)
         {
            Print ("Auto Protect has removed risk and taken a piece of the Pi as RR >= " + DoubleToString(APRRLevel,8));
            AutoProtect();
            AutoProtectCalled = true;
         }
   }
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
   ObjectSetString(0,"infoRR",OBJPROP_TEXT,infoRR);
   ObjectSetString(0,"infoPL",OBJPROP_TEXT,infoPL);
   ObjectSetString(0,"infoSLPL",OBJPROP_TEXT,infoSLPL);
   string infoTP = "Total TP : $" + DoubleToString(total_tp, 2);
   ObjectSetString(0,"infoTP",OBJPROP_TEXT,infoTP);
   string infoMargin = "Margin: $" + DoubleToString(total_margin, 2);
   ObjectSetString(0,"infoMargin",OBJPROP_TEXT,infoMargin);
   string infoRisk = "Risk: $" + DoubleToString(MathAbs(sl_risk), 2) + " ("+DoubleToString(percent_risk,2)+"%)";
   ObjectSetString(0,"infoRisk",OBJPROP_TEXT,infoRisk);
   string infoSLP = "SL Profit: $" + DoubleToString(sl_profit, 2);
   ObjectSetString(0,"infoSLP",OBJPROP_TEXT,infoSLP);
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
   // set ZORDER for supporting indicators
   //SetZOrder("MTF_MA_", 1);
   //SetZOrder("Projected ATR", 1);
   //SetZOrder("info", 1);
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
bool TyWindow::CreateButtonClosePositions(void)
{
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP + 3 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonClosePositions.Create(0,"Close Positions",0,x1,y1,x2,y2))
      return(false);
   if(!buttonClosePositions.Text("Close Positions"))
      return(false);
   if(!Add(buttonClosePositions))
      return(false);
   return(true);
}
bool TyWindow::CreateButtonCloseLimits(void)
{
   int x1 = INDENT_LEFT + (BUTTON_WIDTH + CONTROLS_GAP_X);
   int y1 = INDENT_TOP + 3 * CONTROLS_GAP_Y;
   int x2 = x1 + BUTTON_WIDTH;
   int y2 = y1 + BUTTON_HEIGHT;
   if(!buttonCloseLimits.Create(0,"Close Limits",0,x1,y1,x2,y2))
      return(false);
   if(!buttonCloseLimits.Text("Close Limits"))
      return(false);
   if(!Add(buttonCloseLimits))
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
void TyWindow::ExecuteBuyLimitOrders(double lots, double Limit_Price, int Orders)
{
   for (int i = 0; i < Orders; i++)
   {
      if (Trade.BuyLimit(lots, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
      {
         Print("Buy limit order opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(Orders));
      }
      else
      {
         Print("Failed to open buy limit order, error: ", GetLastError());
      }
   }
}
void TyWindow::ExecuteSellLimitOrders(double lots, double Limit_Price, int Orders)
{
   for (int i = 0; i < Orders; i++)
   {
      if (Trade.SellLimit(lots, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
      {
         Print("Sell limit order opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(Orders));
      }
      else
      {
         Print("Failed to open sell limit order, error: ", GetLastError());
      }
   }
}
void TyWindow::ExecuteBuyOrders(double lots, int Orders)
{
   for (int i = 0; i < Orders; i++)
   {
      if (Trade.Buy(lots, _Symbol, 0, SL, TP, NULL))
      {
         Print("Buy trade opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(Orders));
      }
      else
      {
         Print("Failed to open buy trade, error: ", GetLastError());
      }
   }
}
void TyWindow::ExecuteSellOrders(double lots, int Orders)
{

   for (int i = 0; i < Orders; i++)
   {
      if (Trade.Sell(lots, _Symbol, 0, SL, TP, NULL))
      {
         Print("Sell position opened successfully, Order " + IntegerToString(i+1) + "/" + IntegerToString(Orders));
      }
      else
      {
          Print("Failed to open sell position, error: ", GetLastError());
      }
   }
}
int GetOrdersForSymbol(string symbol)
{
   int totalOrders = 0;
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if (ManageAllPositions || (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber))
         {
            totalOrders++;
         }
      }
   }
   return totalOrders;
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
bool ProcessPositionCheck(ulong ticket, string symbol, int magicNumber, bool manageAllPositions)
{
    bool ShouldProcessPosition = false;
    if (manageAllPositions)
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
void TyWindow::OnClickTrade(void)
{
   SL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
   TP = ObjectGetDouble(0, "TP_Line", OBJPROP_PRICE, 0);
   double max_volume = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), _Digits);
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double existing_volume = GetTotalVolumeForSymbol(_Symbol);
   double potentialRisk = Risk + percent_risk;
   double OrderRisk = Risk;
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
   double Limit_Price = 0;
   if (LimitLineExists == true)
   {
      Limit_Price = ObjectGetDouble(0, "Limit_Line", OBJPROP_PRICE, 0);
   }
   if (potentialRisk > MaxRisk)
   {
      OrderRisk = (MaxRisk - percent_risk);  // Adjust the risk for the next order
      potentialRisk = OrderRisk + percent_risk;  // Recalculate potential risk after adjusting
      order_risk_money = (AccountInfoDouble(ACCOUNT_BALANCE) * (OrderRisk / 100));
   }
   double TotalLots   = TP > SL ? NormalizeDouble(RiskLots(_Symbol, order_risk_money, Ask - SL), OrderDigits)
                              : NormalizeDouble(RiskLots(_Symbol, order_risk_money, SL - Bid), OrderDigits);
   double PartialLots = TP > SL ? NormalizeDouble(RiskLots(_Symbol, order_risk_money, Ask - SL) / InitialOrdersToPlace, OrderDigits)
                              : NormalizeDouble(RiskLots(_Symbol, order_risk_money, SL - Bid) / InitialOrdersToPlace, OrderDigits);
   if (TotalLots > max_volume)
   {
      TotalLots = max_volume;
   }
   double total_volume = existing_volume + TotalLots;
   if (total_volume > max_volume)
   {
      TotalLots = (max_volume - existing_volume);
   }
   if ((PartialLots * InitialOrdersToPlace) > max_volume)
   {
      PartialLots = NormalizeDouble((max_volume / InitialOrdersToPlace),OrderDigits);
   }
   int ExistingOrders = GetOrdersForSymbol(_Symbol);
   int OrdersToPlaceNow = ExistingOrders >= InitialOrdersToPlace ? 1 : InitialOrdersToPlace;
   double OrderLots = ExistingOrders > 1 ? TotalLots : PartialLots;
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol = _Symbol;
   request.volume = OrderLots;
   request.deviation = 20;
   request.magic = MagicNumber;
   request.sl = SL;
   request.tp = TP;
   MqlTradeCheckResult check_result;
   MqlTick latest_tick;
   //Print("Current Risk: ", Risk, ", percent_risk: ", percent_risk, ", Combined Risk: ", potentialRisk, ", MaxRisk: ", MaxRisk);
   double lotSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double marginRequirement = SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_INITIAL);
   double symbolPrice = (request.type == ORDER_TYPE_BUY || request.type == ORDER_TYPE_BUY_LIMIT) ? Ask : Bid;
   double required_margin = OrderLots * lotSize * symbolPrice * marginRequirement;
   double free_margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   while (required_margin >= (free_margin - 500) && OrderLots > min_volume)
   {
      OrderLots -= min_volume;  // Decrease the order size by the minimum volume increment.
      required_margin = OrderLots * lotSize * symbolPrice * marginRequirement;  // Recalculate the required margin.
   }
   if (OrderLots < min_volume)
   {
      Print("Order size adjusted to zero due to insufficient margin. Cannot place order.");
      return;
   }
   if (potentialRisk <= (MaxRisk + 0.05))
   {
      if (LimitLineExists == true)
      {
         if (TP > SL)
         {
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_BUY_LIMIT;
            request.price = Limit_Price;
            if (!Trade.OrderCheck(request, check_result))
            {
               Print("Buy Limit OrderCheck failed, retcode=", check_result.retcode);
               return;
            }
            ExecuteBuyLimitOrders(OrderLots, Limit_Price, OrdersToPlaceNow);
         }
         else if (SL > TP)
         {
            request.action = TRADE_ACTION_PENDING;
            request.type = ORDER_TYPE_SELL_LIMIT;
            request.price = Limit_Price;
            if (!Trade.OrderCheck(request, check_result))
            {
               Print("Sell Limit OrderCheck failed, retcode=", check_result.retcode);
               return;
            }
            ExecuteSellLimitOrders(OrderLots, Limit_Price, OrdersToPlaceNow);
         }
      }
      else
      {
         if (TP > SL)
         {
            if (SymbolInfoTick(_Symbol, latest_tick))
            {
            request.action = TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_BUY;
            }
            if (!Trade.OrderCheck(request, check_result))
            {
               Print("Buy OrderCheck failed, retcode=", check_result.retcode);
               return;
            }
            ExecuteBuyOrders(OrderLots, OrdersToPlaceNow);
         }
         else if (SL > TP)
         {
            if (SymbolInfoTick(_Symbol, latest_tick))
            {
               request.action = TRADE_ACTION_DEAL;
               request.type = ORDER_TYPE_SELL;
            }
            if (!Trade.OrderCheck(request, check_result))
            {
               Print("Sell OrderCheck failed, retcode=", check_result.retcode);
               return;
            }
            ExecuteSellOrders(OrderLots, OrdersToPlaceNow);
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
   ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (SLPips * PointValue() * DigitMulti)));
   ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (TPPips * PointValue() * DigitMulti)));
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
   ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (SLPips * PointValue() * DigitMulti)));
   ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (TPPips * PointValue() * DigitMulti)));
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
         if (arr[j].lotSize > arr[j+1].lotSize || (arr[j].lotSize == arr[j+1].lotSize && arr[j].diff > arr[j+1].diff))
         {
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
   int totalPositions = 0;
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket))
      {
         bool ShouldProcessPosition = ProcessPositionCheck(ticket, _Symbol, MagicNumber, ManageAllPositions);
         if (!ShouldProcessPosition) continue;
            totalPositions++;
      }
   }
   ArrayResize(positionsArray, totalPositions);
   int j = 0;  // Index for positionsArray
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket))
      {
         bool ShouldProcessPosition = ProcessPositionCheck(ticket, _Symbol, MagicNumber, ManageAllPositions);
         if (!ShouldProcessPosition) continue;
         double diff = MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - currentPrice);
         positionsArray[j].diff = diff;
         positionsArray[j].ticket = ticket;
         j++;
      }
   }
   BubbleSort(positionsArray);
   int ClosedPositions = 0;
   int PositionsToClose = (int)MathFloor(((double)ArraySize(positionsArray)) * ((double)APPositionsToClose / APCloseDivider));
   if (totalPositions == 1)
   {
      SL = PositionGetDouble(POSITION_PRICE_OPEN);
      if (!Trade.PositionModify(positionsArray[0].ticket, SL, PositionGetDouble(POSITION_TP)))
      {
         Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
      }
      else
      {
         Print("SL moved to break even for Position #", positionsArray[0].ticket);
      }
   }
   else
   {
      for (int i = 0; i < ArraySize(positionsArray); i++)
      {
         if (PositionSelectByTicket(positionsArray[i].ticket))
         {
            if (ClosedPositions < PositionsToClose)
            {
               Print("Closing Position " + IntegerToString(i + 1) + "/" + IntegerToString(PositionsToClose) + ".");
               double positionProfit = PositionGetDouble(POSITION_PROFIT);
               if (!Trade.PositionClose(positionsArray[i].ticket))
               {
                  Print("Failed to close position " + IntegerToString(i + 1) + "/" + IntegerToString(PositionsToClose) + ". Error code: ", GetLastError());
               }
               else
               {
                  Print("Position " + IntegerToString(i + 1) + "/" + IntegerToString(PositionsToClose) + " closed successfully.");
                  Print("Order #", positionsArray[i].ticket, " realized a profit of ", positionProfit, ". Open Price: ", PositionGetDouble(POSITION_PRICE_OPEN), ". Close Price: ", currentPrice);
                  ClosedPositions++;
               }
            }
            else
            {
               SL = PositionGetDouble(POSITION_PRICE_OPEN);
               if (!Trade.PositionModify(positionsArray[i].ticket, SL, PositionGetDouble(POSITION_TP)))
               {
                  Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
               }
               else
               {
                  Print("SL moved to break even for Position #", positionsArray[i].ticket);
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
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         bool ShouldProcessPosition = ProcessPositionCheck(ticket, _Symbol, MagicNumber, ManageAllPositions);
         if (!ShouldProcessPosition) continue;
         SL = PositionGetDouble(POSITION_PRICE_OPEN);
         if(!Trade.PositionModify(ticket, SL, PositionGetDouble(POSITION_TP)))
         {
            Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
         }
      }
   }
}
void TyWindow::OnClickProtect(void)
{
   Protect();
}
void TyWindow::OnClickClosePositions(void)
{
   double TotalPL = 0.0; // Track the total profit or loss of closed positions
   int result = MessageBox("Do you want to close positions on " + _Symbol + "?", "Close Positions", MB_YESNO | MB_ICONQUESTION);
   if (result == IDNO)
   {
      Print("Positions not closed.");
   }
   if (result == IDYES)
   {
      for(int i=PositionsTotal()-1; i>=0 ;i--)
      {
         if (PositionGetSymbol(i) == _Symbol && (ManageAllPositions || PositionGetInteger(POSITION_MAGIC) == MagicNumber))
         {
            // Get profit of the position before closing
            double positionProfit = PositionGetDouble(POSITION_PROFIT);
            TotalPL += positionProfit;
            if(Trade.PositionClose(PositionGetInteger(POSITION_TICKET)))
            {
               Print("Position #", PositionGetInteger(POSITION_TICKET), " closed with profit/loss of ", positionProfit);
            }
            else
            {
               Print("Position #", PositionGetInteger(POSITION_TICKET), " close failed with error ", GetLastError());
            }
         }
      }
      // Print the total profit or loss after closing all positions
      Print("Total profit/loss of closed positions: ", TotalPL);
   }
}
void TyWindow::OnClickCloseLimits(void)
{
   int result = MessageBox("Do you want to close limit orders?", "Close Limit Orders", MB_YESNO | MB_ICONQUESTION);
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
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            bool ShouldProcessPosition = ProcessPositionCheck(ticket, _Symbol, MagicNumber, ManageAllPositions);
            if (!ShouldProcessPosition) continue;
               double OriginalTP = PositionGetDouble(POSITION_TP);
               if (!Trade.PositionModify(PositionGetTicket(i), PositionGetDouble(POSITION_SL), TP))
               {
                  Print("Failed to modify TP. Error code: ", GetLastError());
               }
               else
               {
                  Print("TP modified for Position #", PositionGetTicket(i), ". Original TP: ", OriginalTP, " | New TP: ", TP);
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
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
         {
            bool ShouldProcessPosition = ProcessPositionCheck(ticket, _Symbol, MagicNumber, ManageAllPositions);
            if (!ShouldProcessPosition) continue;
            double OriginalSL = PositionGetDouble(POSITION_SL);
            if (!Trade.PositionModify(PositionGetTicket(i), SL, PositionGetDouble(POSITION_TP)))
            {
               Print("Failed to modify SL. Error code: ", GetLastError());
            }
            else
            {
               Print("SL modified for Order #", PositionGetTicket(i), ". Original SL: ", OriginalSL, " | New SL: ", SL);
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
