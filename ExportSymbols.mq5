#property strict
// Input parameter for the output CSV file path
input string CSVFilePath = "SymbolsList.csv";
// Indicator initialization function
int OnInit()
{
   // Call the function to export symbols to CSV
   ExportSymbolsToCSV();
   
   // Terminate the indicator after initialization
   return(INIT_SUCCEEDED);
}
// Function to export symbols to CSV
void ExportSymbolsToCSV()
{
   // Open the CSV file for writing
   int file_handle = FileOpen(CSVFilePath, FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(file_handle == INVALID_HANDLE)
   {
      Print("Failed to open file: ", CSVFilePath);
      return;
   }
   // Write the header row
   FileWrite(file_handle, "Symbol,BaseCurrency,QuoteCurrency,Description,Digits,Point,Spread,TickSize,TickValue,TradeContractSize,TradeMode,TradeExecutionMode,VolumeMin,VolumeMax,VolumeStep,MarginInitial,MarginMaintenance,MarginHedged,MarginRate,MarginCurrency,StartDate,ExpirationDate,SwapLong,SwapShort,SwapType,Swap3Days,TradeSessions");
   // Get the total number of symbols
   int total_symbols = SymbolsTotal(false);
   // Loop through all symbols and write their details to the CSV file
   for(int i = 0; i < total_symbols; i++)
   {
      string symbol = SymbolName(i, false);
      if(symbol != "")
      {
         string base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
         string quote_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
         string description = SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
         int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         int spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
         double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
         double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         double trade_contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         int trade_mode = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
         int trade_execution_mode = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE);
         double volume_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
         double volume_max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
         double volume_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
         double margin_initial = SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL);
         double margin_maintenance = SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE);
         double margin_hedged = SymbolInfoDouble(symbol, SYMBOL_MARGIN_HEDGED);
         double margin_long = SymbolInfoDouble(symbol, SYMBOL_MARGIN_LONG);
         double margin_short = SymbolInfoDouble(symbol, SYMBOL_MARGIN_SHORT);
         string margin_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN);
         datetime start_date = (datetime)SymbolInfoInteger(symbol, SYMBOL_START_TIME);
         datetime expiration_date = (datetime)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME);
         double swap_long = SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
         double swap_short = SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);
         int swap_type = (int)SymbolInfoInteger(symbol, SYMBOL_SWAP_MODE);
         int swap_3days = (int)SymbolInfoInteger(symbol, SYMBOL_SWAP_ROLLOVER3DAYS);
         string trade_sessions = GetTradeSessions(symbol);
         // Write symbol details to the CSV file
         FileWrite(file_handle, 
                   symbol, base_currency, quote_currency, description, digits, point, spread, 
                   tick_size, tick_value, trade_contract_size, trade_mode, trade_execution_mode, 
                   volume_min, volume_max, volume_step, margin_long, margin_short, margin_maintenance, 
                   margin_hedged, margin_currency, start_date, expiration_date, 
                   swap_long, swap_short, swap_type, swap_3days, trade_sessions);
      }
   }
   // Close the CSV file
   FileClose(file_handle);
   Print("Export completed. File saved at: ", CSVFilePath);
}
// Function to get the trade session information as a formatted string
string GetTradeSessions(string symbol)
{
   string result = "";
   for(int day=0; day<7; day++)
   {
      for(int session=0; session<3; session++)
      {
         datetime open_time, close_time;
         if(SymbolInfoSessionQuote(symbol, ENUM_DAY_OF_WEEK(day), session, open_time, close_time))
         {
            if(open_time != 0 && close_time != 0)
            {
               result += StringFormat("%d-%d:%s-%s;", day, session, TimeToString(open_time, TIME_MINUTES), TimeToString(close_time, TIME_MINUTES));
            }
         }
      }
   }
   return result;
}
// Indicator deinitialization function
void OnDeinit(const int reason)
{
}
// Indicator calculation function (not used in this script)
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
   // No calculations needed for this script
   return(rates_total);
}
