/*

   SSL Channel.mq5
   Copyright 2013-2022, Novateq Pty Ltd
   https://www.novateq.com.au

*/

#property copyright "Copyright 2013-2022, Novateq Pty Ltd"
#property link "https://www.novateq.com.au"
#property version "1.00"

#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots 2

#property indicator_color1 clrYellow
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID

#property indicator_color2 clrWhite
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID

// Indicator parameters
input int                  InpPeriod = 10; // Period

double                     LeadingBuffer[];
double                     TrailingBuffer[];
double                     DirectionBuffer[];

int                        HighHandle;
int                        LowHandle;

int OnInit() {

   SetIndexBuffer( 0, LeadingBuffer, INDICATOR_DATA );
   PlotIndexSetInteger( 0, PLOT_DRAW_TYPE, DRAW_LINE );
   PlotIndexSetString( 0, PLOT_LABEL, "Leading" );
   ArraySetAsSeries( LeadingBuffer, true );

   SetIndexBuffer( 1, TrailingBuffer, INDICATOR_DATA );
   PlotIndexSetInteger( 1, PLOT_DRAW_TYPE, DRAW_LINE );
   PlotIndexSetString( 1, PLOT_LABEL, "Trailing" );
   ArraySetAsSeries( TrailingBuffer, true );

   SetIndexBuffer( 2, DirectionBuffer );
   ArraySetAsSeries( DirectionBuffer, true );

   HighHandle = iMA( Symbol(), Period(), InpPeriod, 0, MODE_SMA, PRICE_HIGH );
   LowHandle  = iMA( Symbol(), Period(), InpPeriod, 0, MODE_SMA, PRICE_LOW );

   return ( INIT_SUCCEEDED );
}

void OnDeinit(const int reason) {
   if(HighHandle != INVALID_HANDLE) IndicatorRelease(HighHandle);
   if(LowHandle != INVALID_HANDLE)  IndicatorRelease(LowHandle);
}

int OnCalculate( const int       rates_total,     //
                 const int       prev_calculated, //
                 const datetime &time[],          //
                 const double   &open[],          //
                 const double   &high[],          //
                 const double   &low[],           //
                 const double   &close[],         //
                 const long     &tick_volume[],   //
                 const long     &volume[],        //
                 const int      &spread[] ) {

   //	Need a minimum number of available rates to function
   if ( rates_total < InpPeriod ) return ( 0 );

   //	Housekeeping to release asap
   if ( IsStopped() ) return ( 0 );

   // Skip values already calculated
   int    limit = ( prev_calculated == 0 ) ? rates_total - InpPeriod - 1 : rates_total - prev_calculated;

   double highValues[];
   double lowValues[];
   ArraySetAsSeries( highValues, true );
   ArraySetAsSeries( lowValues, true );
   ArraySetAsSeries( close, true );

   if(CopyBuffer( HighHandle, 0, 0, limit + 1, highValues ) != limit + 1) return 0;
   if(CopyBuffer( LowHandle, 0, 0, limit + 1, lowValues ) != limit + 1) return 0;

   //	Loop through bars
   for ( int i = limit; i >= 0 && !IsStopped(); i-- ) {

      double hi          = highValues[i];
      double lo          = lowValues[i];

      DirectionBuffer[i] = close[i] > hi ? 1 : close[i] < lo ? -1 : DirectionBuffer[i + 1];
      LeadingBuffer[i]   = DirectionBuffer[i] < 0 ? lo : hi;
      TrailingBuffer[i]  = DirectionBuffer[i] > 0 ? lo : hi;
   }

   return ( rates_total );
}
