#include <Trade\Trade.mqh>
input double Lots = 1000; // Input for the number of lots to sell per order
double TotalLotsToSell = 21000000; // Total lots to sell (1000 units)
double LotsSold = 0.0; // Variable to keep track of the total lots sold
CTrade trade; // Create an instance of the trade class
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialization code here
   if (!CheckTradingConditions())
   {
       Print("Trading conditions not met. EA initialization failed.");
       return(INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Cleanup code here
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Main loop to sell up to TotalLotsToSell
   while(LotsSold < TotalLotsToSell)
   {
      if(!PlaceSellOrder())
      {
         Print("Exiting loop due to failed order placement.");
         break; // Exit the loop if the order placement fails
      }
   }
}
bool PlaceSellOrder()
{
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Get the current bid price
   double slippage = 2; // Slippage in points
   double stopLoss = 0; // No stop loss
   double takeProfit = 0; // No take profit
   int deviation = (int)slippage; // Slippage as an integer
   Print("Attempting to place a sell order at price: ", price);
   // Try to place a sell order
   if(trade.Sell(Lots, _Symbol, price, stopLoss, takeProfit, "Sell 1000 lots"))
     {
      LotsSold += Lots; // Update the total lots sold
      Print("Sell order placed successfully. Total lots sold: ", LotsSold);
      return true;
     }
   else
     {
      Print("Failed to place sell order. Error: ", GetLastError());
      return false;
     }
  }
bool CheckTradingConditions()
{
   if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print("Trading is not allowed in the terminal settings.");
      return false;
   }
   
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("Trading is not allowed for this account.");
      return false;
   }
   return true;
}
