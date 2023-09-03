/**=             Discord.mq5  (TyphooN's Discord Message Demo/Debug)
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
int OnInit()
{
   string url = "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token";
   // JSON payload
   string json = "{\"content\":\"Hello, World!\"}";
   char jsonArray[];
   StringToCharArray(json, jsonArray);
   // Remove null-terminator if any
   int arrSize = ArraySize(jsonArray);
   if(jsonArray[arrSize - 1] == '\0')
   {
      ArrayResize(jsonArray, arrSize - 1);
   }
   // Headers
   string headers = "Content-Type: application/json";
   // Result variables
   uchar result[];
   string result_headers;
   // Make the request
   int res = WebRequest("POST", url, headers, 10, jsonArray, result, result_headers);
   // Debugging
   Print("Debug - HTTP response code: ", res);
   string resultString = CharArrayToString(result);
   Print("Debug - Result: ", resultString);
   Print("Debug - Response headers: ", result_headers);
   Print("Debug - JSON as uchar array: ", arrayToString(jsonArray));
   Print("Debug - Length of Result: ", StringLen(resultString));
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
