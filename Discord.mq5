/**=             Discord.mq5  (TyphooN's Discord EA Notification System)
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
#property copyright "TyphooN"
#property link      "https://www.decapool.net/"
#property version   "1.18"
double LastBullPower = -1;
double LastBearPower = -1;
datetime LastPowerNotification = 0;
const int NotificationCoolDown = 900;
double CurrentBullPower = 0;
double CurrentBearPower = 0;
double VerifiedBullPower1 = -1;
double VerifiedBearPower1 = -1;
double VerifiedBullPower2 = -1;
double VerifiedBearPower2 = -1;
double VerifiedBullPower3 = -1;
double VerifiedBearPower3 = -1;
input string DiscordAPIKey = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
int OnInit()
{
   return(INIT_SUCCEEDED);
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
void SendPowerNotification()
{
   if(GlobalVariableCheck("GlobalBullPower") || GlobalVariableCheck("GlobalBearPower"))
   {
      CurrentBullPower = GlobalVariableGet("GlobalBullPower");
      CurrentBearPower = GlobalVariableGet("GlobalBearPower");
      int RandomSleepDuration = 30000 + MathRand() % (13000);
      Sleep(RandomSleepDuration);
      VerifiedBullPower1 = GlobalVariableGet("GlobalBullPower");
      VerifiedBearPower1 = GlobalVariableGet("GlobalBearPower");
      Sleep(RandomSleepDuration);
      VerifiedBullPower2 = GlobalVariableGet("GlobalBullPower");
      VerifiedBearPower2 = GlobalVariableGet("GlobalBearPower");
      Sleep(RandomSleepDuration);
      VerifiedBullPower3 = GlobalVariableGet("GlobalBullPower");
      VerifiedBearPower3 = GlobalVariableGet("GlobalBearPower");
      while(CurrentBullPower != VerifiedBullPower1 ||  CurrentBullPower != VerifiedBullPower2  || CurrentBullPower != VerifiedBullPower3)
      {
         CurrentBullPower = GlobalVariableGet("GlobalBullPower");
         CurrentBearPower = GlobalVariableGet("GlobalBearPower");
         Sleep(RandomSleepDuration);
         VerifiedBullPower1 = GlobalVariableGet("GlobalBullPower");
         VerifiedBearPower1 = GlobalVariableGet("GlobalBearPower");
         Sleep(RandomSleepDuration);
         VerifiedBullPower2 = GlobalVariableGet("GlobalBullPower");
         VerifiedBearPower2 = GlobalVariableGet("GlobalBearPower");
         Sleep(RandomSleepDuration);
         VerifiedBullPower3 = GlobalVariableGet("GlobalBullPower");
         VerifiedBearPower3 = GlobalVariableGet("GlobalBearPower");
      }
      double PowerCalculated = GlobalVariableGet("PowerCalcComplete");
      if((CurrentBullPower != LastBullPower || CurrentBearPower != LastBearPower) && PowerCalculated == true && ((CurrentBullPower + CurrentBearPower == 99.999) || (CurrentBullPower + CurrentBearPower == 99.99900000000001)))
      {
         // Update the stored values
         LastBullPower = CurrentBullPower;
         LastBearPower = CurrentBearPower;
         string url;
         if ( _Symbol == "USOUSD" || _Symbol == "UKOUSD" )
         {
            url = "DiscordAPIKey";
         }
         if ( _Symbol == "BTCUSD" || _Symbol == "LINKUSD" || _Symbol == "BCHUSD" || _Symbol == "ETHUSD" || _Symbol == "AVAXUSD")
         {
            url = "DiscordAPIKey";
         }
         if ( _Symbol == "XAUUSD" || _Symbol == "XAGUSD" || _Symbol == "XPTUSD" || _Symbol == "XPDUSD" )
         {
            url = "DiscordAPIKey";
         }
         if ( _Symbol == "AUDCAD.i" || _Symbol == "AUDCHF.i" || _Symbol == "AUDJPY.i" || _Symbol == "AUDUSD.i" || _Symbol == "CADCHF.i" || _Symbol == "CADJPY.i" || _Symbol == "CHFJPY.i"
         || _Symbol == "EURAUD.i" || _Symbol == "EURCAD.i" || _Symbol == "EURCHF.i" || _Symbol == "EURGBP.i" || _Symbol == "EURJPY.i" || _Symbol == "EURUSD.i" || _Symbol == "GBPAUD.i"
         || _Symbol == "GBPCAD.i" || _Symbol == "GBPCHF.i" || _Symbol == "GBPJPY.i" || _Symbol == "GBPUSD.i" || _Symbol == "USDCAD.i" || _Symbol == "USDCHF.i" || _Symbol == "USDJPY.i" )
         {
            url = "DiscordAPIKey";
         }
         if ( _Symbol == "NDX100" || _Symbol == "SPX500" || _Symbol == "US30" || _Symbol == "UK100" || _Symbol == "GER30" || _Symbol == "ASX200"
         || _Symbol == "EUSTX50" || _Symbol == "FRA40" || _Symbol == "JPN225" || _Symbol == "HK50" || _Symbol == "USDX" )
         {
            url = "DiscordAPIKey";
         }
         if ( _Symbol == "CORN.c" || _Symbol == "COCOA.c" || _Symbol == "COFFEE.c" || _Symbol == "SOYBEAN.c" || _Symbol == "WHEAT.c" )
         {
            url = "DiscordAPIKey";
         }
         if (  _Symbol == "AAPL" || _Symbol == "AMZN" || _Symbol == "BABA" || _Symbol == "BAC" || _Symbol == "FB" || _Symbol == "GOOG" || _Symbol == "META"  || _Symbol == "MSFT"   
         || _Symbol == "NFLX" || _Symbol == "NVDA"  || _Symbol == "PFE" || _Symbol == "RACE" || _Symbol == "T" || _Symbol == "TSLA" || _Symbol == "V" || _Symbol == "WMT"  
         || _Symbol == "ZM" || _Symbol == "ALVG" || _Symbol == "BAYGn" || _Symbol == "AIRF" || _Symbol == "DBKGn" || _Symbol == "VOWG_p" || _Symbol == "IBE" || _Symbol == "LVMH" )
         {
            url = "DiscordAPIKey";
         }
         string headers = "Content-Type: application/json";
         uchar result[];
         string result_headers;
         string PowerText = "[" + _Symbol + "] [Bull Power " + DoubleToString(CurrentBullPower, 2) + "]" + " [Bear Power " + DoubleToString(CurrentBearPower, 2)+ "]";
         string json = "{\"content\":\""+PowerText+"\"}";
         char jsonArray[];
         StringToCharArray(json, jsonArray);
         // Remove null-terminator if any
         int arrSize = ArraySize(jsonArray);
         if(jsonArray[arrSize - 1] == '\0')
         {
            ArrayResize(jsonArray, arrSize - 1);
         }
         int res = WebRequest("POST", url, headers, 10, jsonArray, result, result_headers);
         string resultString = CharArrayToString(result);
         LastPowerNotification = TimeCurrent();
      }
      }
}
void OnTick()
{
   if(TimeCurrent() - LastPowerNotification >= NotificationCoolDown)
   {
      SendPowerNotification();
   }
}
//Print("Debug - HTTP response code: ", res);
//Print("Debug - Result: ", resultString);
//Print("Debug - JSON as uchar array: ", arrayToString(jsonArray));
//Print("Debug - Length of Result: ", StringLen(resultString));
