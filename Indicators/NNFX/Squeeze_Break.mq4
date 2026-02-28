//+------------------------------------------------------------------+
//|                                             Des_Squeeze_Play.mq4 |
//|                                                       DesO'Regan |
//|                                   mailto: oregan_des@hotmail.com |
//+------------------------------------------------------------------+
// ===========================================================================================================
// This indicator is based on a strategy mentioned in John Carter's book, Mastering the Trade. The basic idea 
// behind the strategy is that markets tend to move from periods of low volatility to high volatility and
// visa versa. The strategy aims to capture moves from low to high volatility. For gauging this he uses two 
// common indicators - Bollinger Bands and Keltner Channels (ok, not so common!). He also uses the Momentum 
// indicator to provide a trade bias as soon as the Bollinger Bands come back outside the Keltner Channels.
// 
// The Squeeze_Break indicator combines this into a signal indicator and has the following components:
// 	1. A positive green histogram means that the Bollinger Bands are outside the Keltner Channels
// 	and the market is lightly to be trending or volatile. The stronger the histogram the stronger 
// 	the directional price move.
// 	2. A negative red histogram means that the Bollinger Bands are inside the Keltner Channels 
// 	and the market is lightly to be consolidating. The stronger the red histogram the tighter
// 	price action is becoming.
// 	3. Incorporated into the indicator is a Momentum indicator. According to the strategy J. Carter
// 	goes long when the Bollinger Bands break outside the Keltner Bands and the Momentum indicator 
// 	is above the zero line. He goes short when the Momentum indicator is below the zero line on the 
//    break.
// 	4. I've also added other indicator info in the top left hand corner to give a broader idea 
// 	of current market conditions.
// 	5. The indicator provides audio alerts when a potential breakout is occurring.  
// 
// This indicator tends to be better with the larger timeframes. Personally I don't trade on an alert 
// signal alone. It's just a handy tool for warning me of potential breakout trades. 
// ===========================================================================================================

#property copyright "DesORegan"
#property link      "mailto: oregan_des@hotmail.com"



// ====================
// indicator properties
// ====================
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 ForestGreen
#property indicator_color2 Red
#property indicator_color3 Blue


// ===================
// User Inputs
// ===================
extern int       Boll_Period=20;
extern double    Boll_Dev=2.0;
extern int       Keltner_Period=20;
extern double    Keltner_Mul=1.5;
extern int       Momentum_Period=12;
extern int       Back_Bars=1000;
extern bool      Alert_On=true;
extern bool      On_Screen_Info=true;

// =========================
// Buffer Array Declarations
// =========================
double Pos_Diff[];   // Pos Histogram
double Neg_Diff[];   // Neg Histogram
double Momentum[];   // Momentum Indicator 


                     // ===========================
// Internal Array Declarations
// ===========================
double   Squeeze[];  // Used to track which "i" (index value) is above 
                     // and below zero line. 0 followed by 1 triggers alert 

// =========================                        
// Internal Global Variables
// =========================

datetime    Last_Alert_Time=0;  // Used to prevent continuous alerts on current bar                         
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorDigits(4);  // indicator value precision

                        //======================
// Indicator Setup
//======================
   SetIndexStyle(0,DRAW_HISTOGRAM,EMPTY,3);
   SetIndexBuffer(0,Pos_Diff);
   SetIndexStyle(1,DRAW_HISTOGRAM,EMPTY,3);
   SetIndexBuffer(1,Neg_Diff);
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT);
   SetIndexBuffer(2,Momentum);

// ===================
// Indicator Labels
// ===================
   IndicatorShortName("Squeeze_Break (Boll:"+Boll_Period+","+DoubleToStr(Boll_Dev,1)+";Kelt:"+Keltner_Period+","+DoubleToStr(Keltner_Mul,1)+";Mom:"+Momentum_Period+")");

// ====================
// Array Initialization
// ====================
   ArrayResize(Squeeze,Back_Bars); // Stores whether histogram is above/below zero line
   ArrayInitialize(Squeeze,0);  // initialises array with 0's

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {

   ObjectsDeleteAll();
   Comment("                                          ","\n",
           "                                          ","\n",
           "                                          ","\n",
           "                                          ","\n",
           "                                          ");

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {

//=======================
// Indicator Optimization
//=======================
   int Counted_Bars=IndicatorCounted();
   if(Counted_Bars < 0)  return(-1);
   if(Counted_Bars>0) Counted_Bars--;
   int limit=Bars-Counted_Bars;
   if(Counted_Bars==0) limit-=1+MathMax(Momentum_Period,Keltner_Period);

   ArrayResize(Squeeze,ArraySize(Momentum));

//=======================
// On-Screen Information
//=======================  
   if(On_Screen_Info==true)
     {
      double ATR=iATR(Symbol(),PERIOD_D1,14,0);
      double Todays_Range=iHigh(Symbol(),PERIOD_D1,0)-iLow(Symbol(),PERIOD_D1,0);
      double ADX = iADX(Symbol(),0,12,PRICE_CLOSE,MODE_MAIN,0);
      double RSI = iRSI(Symbol(),0,12,PRICE_CLOSE,0);
      double MACD_Main=iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
      double MACD_Signal=iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
      double Sto_Main=iStochastic(Symbol(),0,10,3,3,MODE_SMA,1,MODE_MAIN,0);
      double Sto_Signal=iStochastic(Symbol(),0,10,3,3,MODE_SMA,1,MODE_SIGNAL,0);

      Comment("-----------------------------------------------------------------",
              "\nDaily ATR(14): ",ATR," Todays Range: ",Todays_Range,
              "\nADX(12): ",NormalizeDouble(ADX,2)," RSI(12): ",NormalizeDouble(RSI,2),
              "\nMACD(12,26,9): ",MACD_Main,", ",MACD_Signal,
              "\nStochastic(10,3,3): ",NormalizeDouble(Sto_Main,2),", ",NormalizeDouble(Sto_Signal,2),
              "\n-----------------------------------------------------------------");
     }

//======================
// Main Indicator Loop
//======================
   for(int i=limit; i>=0; i--) //main indicator FOR loop
     {
      // ======================
      // Indicator Calculations
      // ======================
      double MA_Hi = iMA(Symbol(),0,Keltner_Period,0,MODE_SMA,PRICE_HIGH,i);
      double MA_Lo = iMA(Symbol(),0,Keltner_Period,0,MODE_SMA,PRICE_LOW,i);
      double Kelt_Mid_Band=iMA(Symbol(),0,Keltner_Period,0,MODE_SMA,PRICE_TYPICAL,i);
      double Kelt_Upper_Band = Kelt_Mid_Band + ((MA_Hi - MA_Lo)*Keltner_Mul);
      double Kelt_Lower_Band = Kelt_Mid_Band - ((MA_Hi - MA_Lo)*Keltner_Mul);
      double Boll_Upper_Band = iBands(Symbol(),0, Boll_Period,Boll_Dev,0,PRICE_CLOSE, MODE_UPPER,i);
      double Boll_Lower_Band = iBands(Symbol(),0, Boll_Period,Boll_Dev,0,PRICE_CLOSE, MODE_LOWER,i);


      // ======================
      // Buffer Calculations
      // ======================
      Momentum[i]=(Close[i]-Close[i+Momentum_Period]);

      if(Boll_Upper_Band>=Kelt_Upper_Band || Boll_Lower_Band<=Kelt_Lower_Band)
        {
         Pos_Diff[i]=(MathAbs(Boll_Upper_Band-Kelt_Upper_Band)+MathAbs(Boll_Lower_Band-Kelt_Lower_Band));
         Squeeze[i] = 1;
        }
      else
        {
         Pos_Diff[i]=0;
        }

      if(Boll_Upper_Band<Kelt_Upper_Band && Boll_Lower_Band>Kelt_Lower_Band)
        {
         Neg_Diff[i]= -(MathAbs(Boll_Upper_Band-Kelt_Upper_Band)+MathAbs(Boll_Lower_Band-Kelt_Lower_Band));
         Squeeze[i] = 0;
        }
      else
        {
         Neg_Diff[i]=0;
        }

      // ======================
      // Trigger Check
      // ======================
      if(Squeeze[i]==1 && Squeeze[i+1]==0 && Momentum[i]>0 && i==0) // a cross above zero line and Mom > 0
        {
         if(Last_Alert_Time!=Time[0])
           {
            if(Alert_On==true) Alert("Alert: Possible Breakout - "+Symbol()+" - "+TimeToStr(TimeLocal()));
            Last_Alert_Time=Time[0];
            ObjectCreate("Breakout"+Time[0],OBJ_ARROW,0,Time[0],Ask);
            ObjectSet("Breakout"+Time[0],OBJPROP_ARROWCODE,1);
            ObjectSet("Breakout"+Time[0],OBJPROP_COLOR,Blue);
            ObjectSet("Breakout"+Time[0],OBJPROP_WIDTH,2);
           }
        }

      if(Squeeze[i]==1 && Squeeze[i+1]==0 && Momentum[i]<0 && i==0) // a cross above zero line and Mom < 0
        {
         if(Last_Alert_Time!=Time[0])
           {
            if(Alert_On==true) Alert("Alert: Possible Breakout - "+Symbol()+" - "+TimeToStr(TimeLocal()));
            Last_Alert_Time=Time[0];
            ObjectCreate("Breakout"+Time[0],OBJ_ARROW,0,Time[0],Bid);
            ObjectSet("Breakout"+Time[0],OBJPROP_ARROWCODE,1);
            ObjectSet("Breakout"+Time[0],OBJPROP_COLOR,Red);
            ObjectSet("Breakout"+Time[0],OBJPROP_WIDTH,2);
           }
        }

     } // end of main indicator FOR loop



   return(0);
  }

//+------------------------------------------------------------------+
