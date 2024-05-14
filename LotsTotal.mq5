/**=             MTF_MA.mq5  (TyphooN's LotsTotal Indicator)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.info)
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
#property copyright "TyphooN"
#property link      "https://www.marketwizardry.info"
#property version   "1.001"
#property indicator_chart_window
#property strict
double GetTotalLongVolumeForSymbol(string symbol)
{
   double totalVolume = 0;
   for(int i=PositionsTotal()-1; i >= 0; i--)
   {
      string positionSymbol = PositionGetSymbol(i);
      if(positionSymbol == symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         totalVolume += PositionGetDouble(POSITION_VOLUME);
      }
   }
   return totalVolume;
}
double GetTotalShortVolumeForSymbol(string symbol)
{
   double totalVolume = 0;

   for(int i=PositionsTotal()-1; i >= 0; i--)
   {
      string positionSymbol = PositionGetSymbol(i);
      if(positionSymbol == symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         totalVolume += PositionGetDouble(POSITION_VOLUME);
      }
   }
   return totalVolume;
}
void CalculatePriceChangePerTick(string symbol)
{

}
int OnInit()
{
   double totalLotsLong = GetTotalLongVolumeForSymbol(_Symbol);
   double totalLotsShort = GetTotalShortVolumeForSymbol(_Symbol);
   Print("Total Lots Long for ", _Symbol, ": ", totalLotsLong);
   Print("Total Lots Short for ", _Symbol, ": ", totalLotsShort);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double priceChangeLong = totalLotsLong * tickSize;
   double priceChangeShort = totalLotsShort * tickSize;
   double totalPriceChange = priceChangeLong - priceChangeShort;
   Print("Price Change per Tick (Long): ", priceChangeLong);
   Print("Price Change per Tick (Short): ", priceChangeShort);
   Print("Total Price Change per Tick (Long - Short): ", totalPriceChange);
   return(INIT_SUCCEEDED);
}
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    return(rates_total);
}
