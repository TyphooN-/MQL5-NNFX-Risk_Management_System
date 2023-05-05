/*
   TyphooN.mqh
   Copyright 2003, TyphooN (Decapool.net)
   https://www.decapool.net/
*/

/**=
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
#property version   "1.000"
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

// input vars
input group    "User Vars";
input double   Risk=0.3;
input int      MagicNumber=13;
input double   ProtectionPips=10;
input double   SLInitialPips=10;
input double   TPInitialPips=20;
input int   OrderDigitNormalization=2;
input group    "Appearance";
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
   CButton           buttonSetTPSL;
   CButton           buttonClosePositions;
   CButton           buttonCloseLimits;
   CButton           buttonProtect;

public:
                     TyWindow(void);
                    ~TyWindow(void);
   // create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   // chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

protected:
   // create dependent controls
   bool              CreateButtonTrade(void);
   bool              CreateButtonLimit(void);
   bool              CreateButtonBuyLines(void);
   bool              CreateButtonSellLines(void);
   bool              CreateButtonDestroyLines(void);
   bool              CreateButtonSetTPSL(void);
   bool              CreateButtonClosePositions(void);
   bool              CreateButtonCloseLimits(void);
   bool              CreateButtonProtect(void);

   // handlers of the dependent controls events
   void              OnClickTrade(void);
   void              OnClickLimit(void);
   void              OnClickBuyLines(void);
   void              OnClickSellLines(void);
   void              OnClickDestroyLines(void);
   void              OnClickSetTPSL(void);
   void              OnClickClosePositions(void);
   void              OnClickCloseLimits(void);
   void              OnClickProtect(void);
};
// Event Handling
EVENT_MAP_BEGIN(TyWindow)
ON_EVENT(ON_CLICK, buttonTrade, OnClickTrade)
ON_EVENT(ON_CLICK, buttonLimit, OnClickLimit)
ON_EVENT(ON_CLICK, buttonBuyLines, OnClickBuyLines)
ON_EVENT(ON_CLICK, buttonSellLines, OnClickSellLines)
ON_EVENT(ON_CLICK, buttonDestroyLines, OnClickDestroyLines)
ON_EVENT(ON_CLICK, buttonSetTPSL, OnClickSetTPSL)
ON_EVENT(ON_CLICK, buttonClosePositions, OnClickClosePositions)
ON_EVENT(ON_CLICK, buttonCloseLimits, OnClickCloseLimits)
ON_EVENT(ON_CLICK, buttonProtect, OnClickProtect)
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
   if(!CreateButtonSetTPSL())
      return(false);
   if(!CreateButtonClosePositions())
      return(false);
   if(!CreateButtonCloseLimits())
      return(false);
   if(!CreateButtonProtect())
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
if(!ExtDialog.Create(0,"TyphooN Risk Management",0,40,40,276,200))
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
void OnTick()
{
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   risk_money = (AccountInfoDouble(ACCOUNT_BALANCE) * (Risk / 100));
}
// Expert chart event function
void OnChartEvent(const int id,         // event ID  
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
{
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
}
// OnTrade function
void OnTrade()
{

}

bool TyWindow::CreateButtonTrade(void)
  {
   // coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+2*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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
bool TyWindow::CreateButtonSetTPSL(void)
{
   // coordinates
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+2*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   // create
   if(!buttonSetTPSL.Create(0,"Set TP/SL",0,x1,y1,x2,y2))
      return(false);
   if(!buttonSetTPSL.Text("Set TP/SL"))
      return(false);
   if(!Add(buttonSetTPSL))
      return(false);
   // succeed
   return(true);
}
bool TyWindow::CreateButtonClosePositions(void)
{
   // coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+3*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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
   int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+3*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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


bool TyWindow::CreateButtonProtect(void)
{
   // coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+4*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
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

void TyWindow::OnClickTrade(void)
{
   SL = ObjectGetDouble(0, "SL_LINE", OBJPROP_PRICE, 0);
   TP = ObjectGetDouble(0, "TP_LINE", OBJPROP_PRICE, 0);
   double max_volume = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),_Digits);

   Trade.SetExpertMagicNumber(MagicNumber);
   if (LimitLineExists==true) {
        double Limit_Price = ObjectGetDouble(0, "Limit_Line", OBJPROP_PRICE, 0);
        if(TP>SL){
        lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, Ask - SL),OrderDigitNormalization);
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
                  Print("Failed to open buy limit, error: ", Trade.ResultRetcode());
                }
            }
            else if (SL>TP){
            lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, SL - Bid),OrderDigitNormalization);
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
                  Print("Failed to open sell limit, error: ", Trade.ResultRetcode());
               }
            }
   }
   else if (LimitLineExists==false){
      if(TP>SL){
      lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, Ask - SL),OrderDigitNormalization);
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
            Print("Failed to open buy trade, error: ", Trade.ResultRetcode());
          }
      }
      else if (SL>TP){
      lotsglobal = NormalizeDouble(RiskLots(_Symbol, risk_money, SL - Bid),OrderDigitNormalization);

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
            Print("Failed to open sell trade, error: ", Trade.ResultRetcode());
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
   ObjectsDeleteAll(0,-1,OBJ_HLINE);
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   ObjectCreate(0, "SL_LINE", OBJ_HLINE, 0, 0, (Ask - SLInitialPips));
   ObjectSetInteger(0, "SL_LINE", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_LINE", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "SL_LINE", OBJPROP_SELECTABLE, 1);
   ObjectCreate(0, "TP_LINE", OBJ_HLINE, 0, 0, (Ask + TPInitialPips));
   ObjectSetInteger(0, "TP_LINE", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_LINE", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "TP_LINE", OBJPROP_SELECTABLE, 1);
  }
void TyWindow::OnClickSellLines(void)
  {
   ObjectsDeleteAll(0,-1,OBJ_HLINE);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ObjectCreate(0, "SL_LINE", OBJ_HLINE, 0, 0, (Bid + SLInitialPips));
   ObjectSetInteger(0, "SL_LINE", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_LINE", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "SL_LINE", OBJPROP_SELECTABLE, 1);
   ObjectCreate(0, "TP_LINE", OBJ_HLINE, 0, 0, (Bid - TPInitialPips));
   ObjectSetInteger(0, "TP_LINE", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "TP_LINE", OBJPROP_WIDTH,HorizontalLineThickness);
   ObjectSetInteger(0, "TP_LINE", OBJPROP_SELECTABLE, 1);
  }

void TyWindow::OnClickProtect(void)
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
          if (PositionGetSymbol(i) != _Symbol) continue;
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               SL = (PositionGetDouble(POSITION_PRICE_OPEN) + (ProtectionPips*(SYMBOL_DIGITS/100)));
            }
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
               SL = (PositionGetDouble(POSITION_PRICE_OPEN) - (ProtectionPips*(SYMBOL_DIGITS/100)));
            }
            double ProtectTP = PositionGetDouble(POSITION_TP);
            Trade.PositionModify(PositionGetTicket(i), SL, ProtectTP);
         }
      }
   }
}

void TyWindow::OnClickDestroyLines(void)
{
   ObjectsDeleteAll(0,-1,OBJ_HLINE);
   LimitLineExists = false;
}

void TyWindow::OnClickSetTPSL(void)
{
   SL = ObjectGetDouble(0, "SL_LINE", OBJPROP_PRICE, 0);
   TP = ObjectGetDouble(0, "TP_LINE", OBJPROP_PRICE, 0);
   
   
   if (SL !=0 || TP !=0)
   {
      for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i))) {
      if (PositionGetSymbol(i) != _Symbol) continue;
      if(Position.Magic() != MagicNumber ) continue;
                        if(!Trade.PositionModify(PositionGetTicket(i), SL, TP)) {
                            Print("Failed to modify TP/SL. Error code: ", GetLastError());
                        }
      }
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
