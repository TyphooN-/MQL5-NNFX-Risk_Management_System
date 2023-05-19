/**=             TyphooN.mqh  (TyphooN's MQL5 Risk Management System)
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
#property version   "1.012"
#property description "TyphooN's MQL5 Risk Management System"
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Orchard\RiskCalc.mqh>
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
input double   Risk                    = 0.3;
input int      MagicNumber             = 13;
input double   ProtectionATRMulti      = 1.337;
input double   SLATRMulti              = 0.3;
input double   TPATRMulti              = 0.9;
input int      HorizontalLineThickness = 3;
// global vars
double TP = 0;
double SL = 0;
double Bid = 0;
double Ask = 0;
double risk_money = 0;
double lotsglobal = 0;
double ATR = 0;
double InfoMulti = 0;
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
   // destroy dialog
   ExtDialog.Destroy(reason);
}
string TimeTilNextBar(ENUM_TIMEFRAMES tf=PERIOD_CURRENT)
{
   datetime now=TimeCurrent();
   datetime bartime=iTime(NULL,tf,0);
   datetime remainingTime=bartime+PeriodSeconds(tf)-now;
   MqlDateTime mdt;
   TimeToStruct(remainingTime,mdt);
   if(mdt.day_of_year>0) return StringFormat("%d d %d h %d m",mdt.day_of_year,mdt.hour,mdt.min);
   if(mdt.hour>0) return StringFormat("%d h %d m %d s",mdt.hour,mdt.min,mdt.sec);
   if(mdt.min>0) return StringFormat("%d m %d s",mdt.min,mdt.sec);
   return StringFormat("%d s",mdt.sec);
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
   ATR = iATR(_Symbol, PERIOD_CURRENT, 14);
   double total_risk = 0;
   double total_tpprofit = 0;
   double total_pl = 0;
   double total_tp = 0;
   double rr = 0;
   double point = PointValue();
   long calcmode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
   string symbolcurrencyprofit = SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT);
   string symbolcurrencybase = SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE);
   // calcmode 4 is SYMBOL_CALC_MODE_CFDLEVERAGE
   // calcmode 0 is SYMBOL_CALC_MODE_FOREX
   // Print (symbolcurrencybase);
    Print (point);
   if (point == 0.001 && calcmode == 4 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // XRPUSD FTMO
      InfoMulti = 10;
   }
   else if (point == 0.01 && calcmode == 4 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // US30, US100, US500, US2000, XPDUSD, XPTUSD | BTCUSD, DASHUSD, DOGEUSD, DOTUSD, ETHUSD, LTCUSD, NEOUSD, XMRUSD FTMO
     // AAPL, AMZN, BABA, BAC, GOOG, META, MSFT, NFLX, NVDA, PFE, RACE, T, TSLA, V, WMT, ZM FTMO
      InfoMulti = 100;
      if (_Symbol == "DOGEUSD")
      {
         InfoMulti = 0.1;
      }
      if (_Symbol == "DOTUSD")
      {
         InfoMulti =10;
      }
   }
   else if (point == 0.1 && calcmode == 4 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // DX.f, UKOIL, USOIL FTMO
      InfoMulti = 0.1;
   }
   else if (point == 0.009999999999999998 && calcmode == 4 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // ADAUSD FTMO
      InfoMulti = 1;
   }   
   else if (point == 1 && calcmode == 4 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // NATGAS.f, USTN10.f, XAUUSD FTMO
      InfoMulti = 0.01;
      if (_Symbol == "NATGAS.f")
      {
         InfoMulti =0.001;
      }
   }
   else if (point == 1 && calcmode == 0 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // AUDUSD, ERBN.f, EURUSD, GBPUSD, NZDUSD FTMO
      InfoMulti = 0.00001;
   }
   else if (point == 5 && calcmode == 4 && symbolcurrencyprofit == "USD" && symbolcurrencybase== "USD")
   { // XAGUSD FTMO
      InfoMulti=0.00004;
   }
   //  Symbols below have fluctuating point values
   //  Info text is 90-99% accurate on all pairs that need further tweaking with correct digits
   else if (symbolcurrencyprofit == "AUD" && symbolcurrencybase == "AUD" && calcmode == 4)
   { // AUS200 FTMO -- needs further tweaking
      InfoMulti = 220;
   }
   else if (symbolcurrencyprofit == "EUR" && symbolcurrencybase == "EUR" && calcmode == 4)
   { // AIRF, ALVG, BAYGn, DBKGn, IBE, LVMH, VOWG_p, EU50, FRA40, GER40, SPN35 FTMO -- needs further tweaking
      InfoMulti = 85;
   }
   else if (symbolcurrencyprofit == "HKD" && symbolcurrencybase == "HKD" && calcmode == 4)
   { // HK50 FTMO -- needs further tweaking
      InfoMulti = 6100;
   }
   else if (symbolcurrencyprofit == "JPY" && symbolcurrencybase == "JPY" && calcmode == 4)
   { // JP225 FTMO -- needs further tweaking
      InfoMulti = 1910000;
   }
   else if (symbolcurrencyprofit == "GBP" && symbolcurrencybase == "GBP" && calcmode == 4)
   { // UK100 FTMO -- needs further tweaking
      InfoMulti = 64;
   }
   else if (symbolcurrencyprofit == "AUD" && symbolcurrencybase == "USD" && calcmode == 4)
   { // XAAAUD / XAGAUD -- needs further tweaking
      if (_Symbol == "XAUAUD")
      {
         InfoMulti = 0.0225;
      }
      if (_Symbol == "XAGAUD")
      {
         InfoMulti = 0.00009;
      }
   }
   else if (symbolcurrencyprofit == "EUR" && symbolcurrencybase == "USD" && calcmode == 4)
   { // XAUEUR / XAGEUR -- needs further tweaking
      if (_Symbol == "XAUEUR")
      {
         InfoMulti = 0.0085;
      }
      if (_Symbol == "XAGEUR")
      {
         InfoMulti = 0.000034;
      }
   }
   else if (symbolcurrencybase == "USD" &&symbolcurrencyprofit == "CAD" && calcmode == 0)
   { // USDCAD FTMO -- needs further tweaking
      InfoMulti = .0000165;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "CHF" && calcmode == 0)
   { // USDCHF FTMO -- untested
      InfoMulti = 0.000009;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "CZK" && calcmode == 0)
   { // USDCZK FTMO -- needs further tweaking
      InfoMulti = 0.0004;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "HKD" && calcmode == 0)
   { // USDHKD FTMO -- needs further tweaking
      InfoMulti = 0.002;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "HUF" && calcmode == 0)
   { // USDHUF FTMO -- needs further tweaking
      InfoMulti = 0.01;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "ILS" && calcmode == 0)
   { // USDILS FTMO -- needs further tweaking
      InfoMulti = 0.000011;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "JPY" && calcmode == 0)
   { // USDJPY FTMO -- needs further tweaking
      InfoMulti = 0.00149;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "MXN" && calcmode == 0)
   { // USDMXN FTMO -- needs further tweaking
      InfoMulti = .003;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "NOK" && calcmode == 0)
   { // USDNOK FTMO -- needs further tweaking
      InfoMulti = .00119;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "PLN" && calcmode == 0)
   { // USDPLN FTMO -- needs further tweaking
      InfoMulti = .00016;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "SEK" && calcmode == 0)
   { // USDSEK FTMO -- needs further tweaking
      InfoMulti = 0.00085;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "TRY" && calcmode == 0)
   { // USDTRY FTMO -- needs further tweaking
      InfoMulti = 0.0038;
   }
   else if (symbolcurrencybase == "USD" && symbolcurrencyprofit == "ZAR" && calcmode == 0)
   { // USDZAR FTMO -- needs further tweaking
      InfoMulti = 0.0033;
   }
   else if (symbolcurrencybase == "EUR" && symbolcurrencyprofit == "CZK" && calcmode == 0)
   { // EURCZK FTMO -- needs further tweaking
      InfoMulti = 0.000483785;
   }
   else if (symbolcurrencybase == "EUR" && symbolcurrencyprofit == "GBP" && calcmode == 0)
   { // EURGBP FTMO -- needs further tweaking
      InfoMulti = 0.000006454;
   }
   else if (symbolcurrencybase == "EUR" && symbolcurrencyprofit == "HUF" && calcmode == 0)
   { // EURHUF FTMO -- needs further tweaking
      InfoMulti = 0.012081;
   }
   else if (symbolcurrencybase == "EUR" && symbolcurrencyprofit == "NOK" && calcmode == 0)
   { // EURNOK FTMO -- needs further tweaking
      InfoMulti = 0.0011835;
   }
   else if (symbolcurrencybase == "EUR" && symbolcurrencyprofit == "PLN" && calcmode == 0)
   { // EURPLN FTMO -- needs further tweaking
      InfoMulti = 0.0001765;
   }
   else if ((symbolcurrencybase == "AUD" || symbolcurrencybase == "EUR" || symbolcurrencybase == "GBP") && symbolcurrencyprofit == "NZD" && calcmode == 0)
   { // AUDNZD, EURNZD, GBPNZD FTMO -- needs further tweaking
      InfoMulti = 0.000025365;
   }
   else if ((symbolcurrencybase == "EUR" || symbolcurrencybase == "GBP") && symbolcurrencyprofit == "AUD" && calcmode == 0)
   { // EURAUD, GBPAUD FTMO -- needs further tweaking
      InfoMulti = 0.000022515;
   }
   else if ((symbolcurrencybase == "AUD" || symbolcurrencybase == "EUR" || symbolcurrencybase == "GBP" || symbolcurrencybase == "NZD") && symbolcurrencyprofit == "CAD" && calcmode == 0)
   { // AUDCAD, EURCAD, GBPCAD, NZDCAD FTMO -- needs further tweaking
      InfoMulti = 0.000018245;
   }
   else if ((symbolcurrencybase == "AUD" || symbolcurrencybase == "CAD" || symbolcurrencybase == "EUR" || symbolcurrencybase == "GBP" || symbolcurrencybase == "NZD") && symbolcurrencyprofit == "CHF" && calcmode == 0)
   { // AUDCHF, CADCHF, EURCHF, GBPCHF, NZDCHF FTMO -- needs further tweaking
      InfoMulti = 0.000008082;
   }
   else if ((symbolcurrencybase == "AUD" || symbolcurrencybase == "CAD" || symbolcurrencybase == "CHF" || symbolcurrencybase == "EUR" || symbolcurrencybase == "GBP" || symbolcurrencybase == "NZD") && symbolcurrencyprofit == "JPY" && calcmode == 0)
   { // AUDJPY, CADJPY, CHFJPY, EURJPY, GBPJPY, NZDJPY FTMO -- needs further tweaking
      InfoMulti = 0.0019;
   }
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetSymbol(i) != _Symbol) continue;
         double profit = PositionGetDouble(POSITION_PROFIT);
         double risk = 0;
         double tpprofit = 0;
         if (PositionGetDouble(POSITION_TP) > PositionGetDouble(POSITION_SL))
         {
            tpprofit = ( (PositionGetDouble(POSITION_VOLUME) * ((PositionGetDouble(POSITION_TP) - PositionGetDouble(POSITION_PRICE_OPEN)) / (point * InfoMulti))));
            risk = ( (PositionGetDouble(POSITION_VOLUME) * ((PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)) / (point * InfoMulti))));
         }
         if (PositionGetDouble(POSITION_SL) > PositionGetDouble(POSITION_TP))
         {
            tpprofit = ( (PositionGetDouble(POSITION_VOLUME) * ((PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_TP)) / (point * InfoMulti))));
            risk = ( (PositionGetDouble(POSITION_VOLUME) * ((PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)) / (point * InfoMulti))));
         }
         total_pl += profit;
         total_risk += risk;
         total_tp += tpprofit;
         rr = total_tp/MathAbs(total_risk);
      }
   }
   string info1 = "Total P/L: $ " + DoubleToString(total_pl, 2) + " / Risk: $" + DoubleToString(total_risk, 2); 
   ObjectCreate(0,"info1Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info1Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info1Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info1Label",OBJPROP_TEXT,info1);
   ObjectSetInteger(0,"info1Label", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0,"info1Label",OBJPROP_YDISTANCE,20);
   ObjectSetInteger(0,"info1Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info1Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info2 = "Total TP: $ " + DoubleToString(total_tp, 2) + " / RR: " + DoubleToString(rr, 2);
   ObjectCreate(0,"info2Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info2Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info2Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info2Label",OBJPROP_TEXT,info2);
   ObjectSetInteger(0,"info2Label", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0,"info2Label",OBJPROP_YDISTANCE,40);
   ObjectSetInteger(0,"info2Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info2Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info3 = "M15: " + TimeTilNextBar(PERIOD_M15);
   ObjectCreate(0,"info3Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info3Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info3Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info3Label",OBJPROP_TEXT,info3);
   ObjectSetInteger(0,"info3Label", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0,"info3Label",OBJPROP_YDISTANCE,60);
   ObjectSetInteger(0,"info3Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info3Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info4 = "H1 : " + TimeTilNextBar(PERIOD_H1);
   ObjectCreate(0,"info4Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info4Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info4Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info4Label",OBJPROP_TEXT,info4);
   ObjectSetInteger(0,"info4Label", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0,"info4Label",OBJPROP_YDISTANCE,80);
   ObjectSetInteger(0,"info4Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info4Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info5 = "D1 : " + TimeTilNextBar(PERIOD_D1);
   ObjectCreate(0,"info5Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info5Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info5Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info5Label",OBJPROP_TEXT,info5);
   ObjectSetInteger(0,"info5Label", OBJPROP_XDISTANCE, 320);
   ObjectSetInteger(0,"info5Label",OBJPROP_YDISTANCE,100);
   ObjectSetInteger(0,"info5Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info5Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info6 ="M30: " + TimeTilNextBar(PERIOD_M30);
   ObjectCreate(0,"info6Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info6Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info6Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info6Label",OBJPROP_TEXT,info6);
   ObjectSetInteger(0,"info6Label", OBJPROP_XDISTANCE, 160);
   ObjectSetInteger(0,"info6Label",OBJPROP_YDISTANCE,60);
   ObjectSetInteger(0,"info6Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info6Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info7 = "H4 : " + TimeTilNextBar(PERIOD_H4);
   ObjectCreate(0,"info7Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info7Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info7Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info7Label",OBJPROP_TEXT,info7);
   ObjectSetInteger(0,"info7Label", OBJPROP_XDISTANCE, 160);
   ObjectSetInteger(0,"info7Label",OBJPROP_YDISTANCE,80);
   ObjectSetInteger(0,"info7Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info7Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   string info8 = "W1 : " + TimeTilNextBar(PERIOD_W1);
   ObjectCreate(0,"info8Label", OBJ_LABEL,0,0,0);
   ObjectSetString(0,"info8Label",OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,"info8Label",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"info8Label",OBJPROP_TEXT,info8);
   ObjectSetInteger(0,"info8Label", OBJPROP_XDISTANCE, 160);
   ObjectSetInteger(0,"info8Label",OBJPROP_YDISTANCE,100);
   ObjectSetInteger(0,"info8Label",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"info8Label",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
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
   else if (min_volume == 1)
   {
      OrderDigits = 0;
   }
   if (LimitLineExists == true) {
        double Limit_Price = ObjectGetDouble(0, "Limit_Line", OBJPROP_PRICE, 0);
        if(TP > SL){
        lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, Ask - SL),OrderDigits);
            if(lotsglobal > max_volume)
            {
               lotsglobal = max_volume;
            }
               if (Trade.BuyLimit(lotsglobal, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
               {
                  Print("Buy Limit opened successfully");
               }
               else
                {
                  Print("Failed to open buy limit, error: " + Trade.ResultRetcode() + " | " + Trade.ResultRetcodeDescription());
                }
            }
            else if (SL > TP){
            lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, SL - Bid),OrderDigits);
               if(lotsglobal > max_volume)
               {
                  lotsglobal = max_volume;
               }
               if (Trade.SellLimit(lotsglobal, Limit_Price, _Symbol, SL, TP, 0, 0, NULL))
               {
                  Print("Sell Limit opened successfully");
               }
               else
               {
                  Print("Failed to open sell limit, error: " + Trade.ResultRetcode() + " | " + Trade.ResultRetcodeDescription());
               }
            }
   }
   else if (LimitLineExists == false){
      if(TP > SL){
      lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, Ask - SL),OrderDigits);
         if(lotsglobal > max_volume)
         {
              lotsglobal = max_volume;
         }
         if(Trade.Buy(lotsglobal, NULL, 0, SL, TP, NULL))
         {
            Print("Buy trade opened successfully");
         }
         else
         {
            Print("Failed to open buy trade, error: " + Trade.ResultRetcode() + " | " + Trade.ResultRetcodeDescription());
         }
      }
      else if (SL > TP){
      lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, SL - Bid),OrderDigits);

         if(lotsglobal > max_volume)
         {
             lotsglobal = max_volume;
         }
         if(Trade.Sell(lotsglobal, NULL, 0, SL, TP, NULL))
         {
          Print("Sell trade opened successfully");
         }
         else
         {
            Print("Failed to open sell trade, error: " + Trade.ResultRetcode() + " | " + Trade.ResultRetcodeDescription());
      }
         ObjectDelete(0, "Limit_Line");  
    }
   }
}
void TyWindow::OnClickLimit()
{
   if (!LimitLineExists) {
      ObjectCreate(0, "Limit_Line", OBJ_HLINE, 0, TimeCurrent(), Ask);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_WIDTH, HorizontalLineThickness);
      ObjectSetInteger(0, "Limit_Line", OBJPROP_SELECTABLE, 1);
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
   ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Bid - (ATR * SLATRMulti)));
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "SL_Line", OBJPROP_SELECTABLE, 1);
   ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Ask + (ATR * TPATRMulti)));
   ObjectSetInteger(0, "TP_Line", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "TP_Line", OBJPROP_SELECTABLE, 1);
}
void TyWindow::OnClickSellLines(void)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ObjectCreate(0, "SL_Line", OBJ_HLINE, 0, 0, (Ask + (ATR * SLATRMulti)));
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "SL_Line", OBJPROP_SELECTABLE, 1);
   ObjectCreate(0, "TP_Line", OBJ_HLINE, 0, 0, (Bid - (ATR * TPATRMulti)));
   ObjectSetInteger(0, "TP_Line", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_Line", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "TP_Line", OBJPROP_SELECTABLE, 1);
}
void TyWindow::OnClickDestroyLines(void)
{
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "TP_Line");
   ObjectDelete(0, "Limit_Line");
   LimitLineExists = false;
}
void TyWindow::OnClickProtect(void)
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
      if (PositionGetSymbol(i) != _Symbol) continue;
      if(Position.Magic() != MagicNumber ) continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         SL = PositionGetDouble(POSITION_PRICE_OPEN) + ( ATR * ProtectionATRMulti * _Point );
      }
      else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         SL = PositionGetDouble(POSITION_PRICE_OPEN) - ( ATR * ProtectionATRMulti *  _Point );
      }
      if(!Trade.PositionModify(PositionGetTicket(i), SL, PositionGetDouble(POSITION_TP)))
         Print("Failed to modify SL via PROTECT. Error code: ", GetLastError());
      }
      }
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
   if(Position.Magic() != MagicNumber ) continue;
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
void TyWindow::OnClickCloseLimits()
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
   if (TP !=0)
   {
      for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
      if (PositionGetSymbol(i) != _Symbol) continue;
      if(Position.Magic() != MagicNumber ) continue;
         Trade.PositionModify(PositionGetTicket(i), PositionGetDouble(POSITION_SL), TP);
         if(!Trade.PositionModify(PositionGetTicket(i), PositionGetDouble(POSITION_SL), TP)) {
            Print("Failed to modify TP. Error code: ", GetLastError());
            }
            }
      }
   }
}
void TyWindow::OnClickSetSL(void)
{
   SL = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
   if (SL !=0)
   {
      for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
      if (PositionGetSymbol(i) != _Symbol) continue;
      if(Position.Magic() != MagicNumber ) continue;
         Trade.PositionModify(PositionGetTicket(i), SL, PositionGetDouble(POSITION_TP));
         if(!Trade.PositionModify(PositionGetTicket(i), SL, PositionGetDouble(POSITION_TP))) {
            Print("Failed to modify TP. Error code: ", GetLastError());
            }
            }
      }
   }
}
