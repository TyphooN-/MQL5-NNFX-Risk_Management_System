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
#property version   "1.00"
double LastBullPower = -1;
double LastBearPower = -1;
datetime LastPowerNotification = 0;
const int NotificationCoolDown = 900;
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
void OnTick()
{
   if(GlobalVariableCheck("GlobalBullPower") || GlobalVariableCheck("GlobalBearPower"))
   {
      double CurrentBullPower = GlobalVariableGet("GlobalBullPower");
      double CurrentBearPower = GlobalVariableGet("GlobalBearPower");
      if((CurrentBullPower != LastBullPower || CurrentBearPower != LastBearPower) && (TimeCurrent() - LastPowerNotification >= NotificationCoolDown) && (CurrentBullPower + CurrentBearPower == 70))
      {
         // Update the stored values
         LastBullPower = CurrentBullPower;
         LastBearPower = CurrentBearPower;
         string url;
         if ( _Symbol == "USOUSD" || _Symbol == "UKOUSD" )
         {
            url = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
         }
         if ( _Symbol == "BTCUSD" || _Symbol == "LINKUSD" || _Symbol == "BCHUSD" || _Symbol == "ETHUSD" )
         {
            url = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
         }
         if ( _Symbol == "XAUUSD" || _Symbol == "XAGUSD" || _Symbol == "XPTUSD" || _Symbol == "XPDUSD" )
         {
            url = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
         }
         if ( _Symbol == "AUDCAD.i" || _Symbol == "AUDCHF.i" || _Symbol == "AUDJPY.i" || _Symbol == "AUDUSD.i" || _Symbol == "CADCHF.i" || _Symbol == "CADJPY.i" || _Symbol == "CHFJPY.i"
         || _Symbol == "EURAUD.i" || _Symbol == "EURCAD.i" || _Symbol == "EURCHF.i" || _Symbol == "EURGBP.i" || _Symbol == "EURJPY.i" || _Symbol == "EURUSD.i" || _Symbol == "GBPAUD.i"
         || _Symbol == "GBPCAD.i" || _Symbol == "GBPCHF.i" || _Symbol == "GBPJPY.i" || _Symbol == "GBPUSD.i" || _Symbol == "USDCAD.i" || _Symbol == "USDCHF.i" || _Symbol == "USDJPY.i" )
         {
            url = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
         }
         if ( _Symbol == "NDX100" || _Symbol == "SPX500" || _Symbol == "US30" || _Symbol == "UK100" || _Symbol == "GER30" )
         {
            url = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
         }
         string headers = "Content-Type: application/json";
         uchar result[];
         string result_headers;
         double TotalScore = CurrentBullPower + CurrentBearPower;
         double BullPowerPercent = CurrentBullPower/TotalScore;
         double BearPowerPercent = CurrentBearPower/TotalScore;
         string PowerText = "[" + _Symbol + "] [Bull Power " + DoubleToString(CurrentBullPower, 0) + " (" + DoubleToString(BullPowerPercent * 100, 1) + "%)]" + " [Bear Power " + DoubleToString(CurrentBearPower, 0) + " (" + DoubleToString(BearPowerPercent * 100, 1) + "%)]";
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
//Print("Debug - HTTP response code: ", res);
//Print("Debug - Result: ", resultString);
//Print("Debug - JSON as uchar array: ", arrayToString(jsonArray));
//Print("Debug - Length of Result: ", StringLen(resultString));
