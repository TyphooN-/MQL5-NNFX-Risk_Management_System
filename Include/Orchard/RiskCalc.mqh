/*
   RiskCalc.mqh

   Copyright 2013-2022, Orchard Forex
   https://www.orchardforex.com

   Functions to support the Scale In tutorial

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

//	Has a new bar been opened
bool NewBar( string symbol = NULL, int timeframe = 0, bool initToNow = false ) {

   datetime        currentBarTime  = iTime( symbol, ( ENUM_TIMEFRAMES )timeframe, 0 );
   if ( currentBarTime == 0 ) return ( false ); // iTime failed (server disconnect, symbol unavailable)
   static datetime previousBarTime = initToNow ? currentBarTime : 0;
   if ( previousBarTime == currentBarTime ) return ( false );
   previousBarTime = currentBarTime;
   return ( true );
}

double DoubleToTicks( string symbol, double value ) {
   double tickSize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
   if ( tickSize == 0 ) return ( 0 );
   return ( value / tickSize );
}

double RiskLots( string symbol, double riskAmount, double slSize ) { // Amount in account currency

   double ticks = DoubleToTicks( symbol, slSize );
   double tickValue =
      SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_VALUE ); // value of 1 tick for 1 lot
   double lotRisk  = ticks * tickValue;
   if ( lotRisk == 0 ) return ( 0 );
   double riskLots = riskAmount / lotRisk;
   return ( riskLots );
}
