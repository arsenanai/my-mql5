//+------------------------------------------------------------------+
//|                     EMA Strategy EA                              |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property version   "1.00"
#property strict

//--- Input parameters
input int EMA12_Period = 12;
input int EMA25_Period = 25;
input int EMA50_Period = 50;
input int EMA100_Period = 100;
input int EMA200_Period = 200;
input double RiskPercent = 1.0; // Risk % per trade
input double BufferPips = 15;  // SL Buffer (pips)

//--- Global variables
int ema12_handle, ema25_handle, ema50_handle, ema100_handle, ema200_handle;
datetime lastAlertTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize EMA indicator handles
   ema12_handle = iMA(_Symbol, _Period, EMA12_Period, 0, MODE_EMA, PRICE_CLOSE);
   ema25_handle = iMA(_Symbol, _Period, EMA25_Period, 0, MODE_EMA, PRICE_CLOSE);
   ema50_handle = iMA(_Symbol, _Period, EMA50_Period, 0, MODE_EMA, PRICE_CLOSE);
   ema100_handle = iMA(_Symbol, _Period, EMA100_Period, 0, MODE_EMA, PRICE_CLOSE);
   ema200_handle = iMA(_Symbol, _Period, EMA200_Period, 0, MODE_EMA, PRICE_CLOSE);

   // Check if handles are valid
   if (ema12_handle == INVALID_HANDLE || ema25_handle == INVALID_HANDLE || ema50_handle == INVALID_HANDLE ||
       ema100_handle == INVALID_HANDLE || ema200_handle == INVALID_HANDLE)
   {
      Print("Failed to initialize EMA indicators.");
      return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   double ema12 = 0.0, ema25 = 0.0, ema50 = 0.0, ema100 = 0.0, ema200 = 0.0;
   double emaBuffer[1];

   // Retrieve EMA values
   if (CopyBuffer(ema12_handle, 0, 0, 1, emaBuffer) > 0)
      ema12 = emaBuffer[0];
   if (CopyBuffer(ema25_handle, 0, 0, 1, emaBuffer) > 0)
      ema25 = emaBuffer[0];
   if (CopyBuffer(ema50_handle, 0, 0, 1, emaBuffer) > 0)
      ema50 = emaBuffer[0];
   if (CopyBuffer(ema100_handle, 0, 0, 1, emaBuffer) > 0)
      ema100 = emaBuffer[0];
   if (CopyBuffer(ema200_handle, 0, 0, 1, emaBuffer) > 0)
      ema200 = emaBuffer[0];

   // Ensure EMA values are valid
   if (ema12 == 0.0 || ema25 == 0.0 || ema50 == 0.0 || ema100 == 0.0 || ema200 == 0.0)
   {
      Print("Failed to retrieve EMA values.");
      return;
   }

   // Get current price
   double close = iClose(_Symbol, _Period, 0);

   // Check for bullish conditions
   if (CheckBullishConditions(close, ema12, ema25, ema50, ema100, ema200))
   {
      if (TimeCurrent() - lastAlertTime > 60) // Avoid duplicate alerts within 1 minute
      {
         Alert("Potential bullish entry detected.");
         SendNotification("Potential bullish entry detected.");
         lastAlertTime = TimeCurrent();

         // Place trade
         PlaceTrade(ORDER_TYPE_BUY, close, ema200);
      }
   }

   // Check for bearish conditions
   if (CheckBearishConditions(close, ema12, ema25, ema50, ema100, ema200))
   {
      if (TimeCurrent() - lastAlertTime > 60) // Avoid duplicate alerts within 1 minute
      {
         Alert("Potential bearish entry detected.");
         SendNotification("Potential bearish entry detected.");
         lastAlertTime = TimeCurrent();

         // Place trade
         PlaceTrade(ORDER_TYPE_SELL, close, ema200);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Bullish Conditions                                         |
//+------------------------------------------------------------------+
bool CheckBullishConditions(double close, double ema12, double ema25, double ema50, double ema100, double ema200)
{
   if (ema12 > ema25 && ema25 > ema50 && ema50 > ema100 && ema100 > ema200 && close > ema12)
   {
      if (close < ema12 && ema12 < ema25 && close < ema50 && close < ema100 && close > ema200)
      {
         if (close > ema12 && ema12 > ema25 && close > ema100)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check Bearish Conditions                                         |
//+------------------------------------------------------------------+
bool CheckBearishConditions(double close, double ema12, double ema25, double ema50, double ema100, double ema200)
{
   if (ema12 < ema25 && ema25 < ema50 && ema50 < ema100 && ema100 < ema200 && close < ema12)
   {
      if (close > ema12 && ema12 > ema25 && close > ema50 && close > ema100 && close < ema200)
      {
         if (close < ema12 && ema12 < ema25 && close < ema100)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Place Trade                                                      |
//+------------------------------------------------------------------+
void PlaceTrade(ENUM_ORDER_TYPE type, double entryPrice, double ema200)
{
   double sl, tp;
   double lotSize = CalculateLotSize();
   int barsBack = 10;

   if (type == ORDER_TYPE_BUY)
   {
      double swingLow = FindSwingLow(barsBack);
      sl = MathMin(swingLow, ema200 - BufferPips * _Point);
      tp = entryPrice + 3 * (entryPrice - sl);
   }
   else
   {
      double swingHigh = FindSwingHigh(barsBack);
      sl = MathMax(swingHigh, ema200 + BufferPips * _Point);
      tp = entryPrice - 3 * (sl - entryPrice);
   }

   MqlTradeRequest request;
   MqlTradeResult result;

   // Initialize the request structure
   ZeroMemory(request);
   ZeroMemory(result);

   // Set up the trade request
   request.action = TRADE_ACTION_DEAL; // Correct ENUM_TRADE_REQUEST_ACTIONS value
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = type;
   request.price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.type_filling = ORDER_FILLING_FOK;

   // Send the trade request
   if (!OrderSend(request, result))
   {
      Print("Trade failed: ", result.retcode);
   }
   else
   {
      Print("Trade placed successfully. Ticket: ", result.order);
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * RiskPercent / 100;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   return NormalizeDouble(riskAmount / (tickValue / tickSize), 2);
}

//+------------------------------------------------------------------+
//| Find Recent Swing Low                                            |
//+------------------------------------------------------------------+
double FindSwingLow(int barsBack)
{
   double swingLow = iLow(_Symbol, _Period, 0);
   for (int i = 1; i <= barsBack; i++)
   {
      double low = iLow(_Symbol, _Period, i);
      if (low < swingLow)
         swingLow = low;
   }
   return swingLow;
}

//+------------------------------------------------------------------+
//| Find Recent Swing High                                           |
//+------------------------------------------------------------------+
double FindSwingHigh(int barsBack)
{
   double swingHigh = iHigh(_Symbol, _Period, 0);
   for (int i = 1; i <= barsBack; i++)
   {
      double high = iHigh(_Symbol, _Period, i);
      if (high > swingHigh)
         swingHigh = high;
   }
   return swingHigh;
}