//+------------------------------------------------------------------+
//|                                                      Scalper.mq5 |
//|                      Arsen Anay. Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Arsen Anay. Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

   input group "=== Trading Inputs ==="
      input double   RiskPercent = 1.0; // Risk as % of Trading 
      input int      Tppoints    = 200; // Take Profit (10 points = 1 pip)
      input int      Slpoints    = 200; // Stoploss Points (10 points = 1 pip)
      input int      TslTrigger  = 15;  // Points in profit before Trailing SL is activated (10 points = 1 pip)
      input int      TslPoints   = 10;  // Trailing Stop Loss (10 points = 1 pip)
      input ENUM_TIMEFRAMES TF   = PERIOD_CURRENT; // Timeframe to run
      input int      InpMagic    = 111; // EA identification number
      input string   TradeComment= "Scalping Robot"; // Trade Comment 
      enum StartHour {Inactive=0, _0100=1, _0200=2, _0300=3, _0400=4, _0500=5, _0600=6, _0700=7, _0800=8, _0900=9,
                      _1000=10, _1100=11, _1200=12, _1300=13, _1400=14, _1500=15,
                      _1600=16, _1700=17, _1800=18, _1900=19, _2000=20, _2100=21,
                      _2200=22, _2300=23};
      input StartHour SHInput = 0; // Start Hour
      
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
