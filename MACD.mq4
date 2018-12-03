//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Averages Convergence/Divergence"
#property strict

#include <MovingAverages.mqh>

//--- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  Silver
#property  indicator_color2  Red
#property  indicator_width1  2
//--- indicator parameters
input int InpFastEMA=100;   // Fast EMA Period
input int InpSlowEMA=200;   // Slow EMA Period
input int InpSignalSMA=30;  // Signal SMA Period
input int peak_length = 3;  // peak or valey length
input int peak_depth = 5;  //peak or valey depth
input int TrendEMAN = 5;   //EMA for trend limit
input int forceReverse = 300;  //first k for double peak/valey
input int forceTrend = -1;   //current trend 0 bull 1 bear
input int nofilter = 0; //straight signal, not filter
//--- indicator buffers
double    ExtMacdBuffer[50000];
double    ExtSignalBuffer[50000];
double    ExtSignalBuffer2[50000];
//--- right input parameters flag
bool      ExtParameters=false;
int space = 20;
int Cal = 300;       //how many candles to calculate
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   if(Period() > 60) Cal = 1000;
   if(Period() > 60*24) Cal = 100;
   Print(InpFastEMA, "/", Cal, "/", space);
   IndicatorDigits(Digits+1);
//--- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexDrawBegin(1,InpSignalSMA);
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer);
   SetIndexBuffer(1,ExtSignalBuffer);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexBuffer(2,ExtSignalBuffer2);
//--- name for DataWindow and indicator subwindow label
   IndicatorShortName("MACD("+IntegerToString(InpFastEMA)+","+IntegerToString(InpSlowEMA)+","+IntegerToString(InpSignalSMA)+")");
   SetIndexLabel(0,"MACD");
   SetIndexLabel(1,"Signal");
//--- check for input parameters
   if(InpFastEMA<=1 || InpSlowEMA<=1 || InpSignalSMA<=1 || InpFastEMA>=InpSlowEMA)
     {
      Print("Wrong input parameters");
      ExtParameters=false;
      return(INIT_FAILED);
     }
   else
      ExtParameters=true;

//--- initialization done
   return(INIT_SUCCEEDED);
  }

  void OnDeinit(const int reason)
  {
     for( int i = 0; i <= Cal; i++)
      {
         ObjectDelete(0, "MACDKR"+i);
      }
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const datetime& time[],
                 const double& open[],
                 const double& high[],
                 const double& low[],
                 const double& close[],
                 const long& tick_volume[],
                 const long& volume[],
                 const int& spread[])
  {
   int i,limit;

//---
   if(rates_total<= Cal || !ExtParameters)
      return(0);
   for( i = 0; i < Cal; i++)
      {
         ExtSignalBuffer2[i] = 0;
      }
//--- last counted bar will be recounted
   limit=rates_total-prev_calculated;

   if(prev_calculated>0)
      limit++;
//--- macd counted in the 1-st buffer
   for(i=0; i<limit; i++)
      ExtMacdBuffer[i]=iMA(NULL,0,InpFastEMA,0,MODE_EMA,PRICE_CLOSE,i)-
                    iMA(NULL,0,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
//--- signal line counted in the 2-nd buffer
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
//--- done
   int cause, found,prev_signal;
   int j;
   double s = space * Point;
   string causestring[3] = {"peak/valley pattern","cross zero","cross signal line"};
   color color1[3] = {clrBlue, clrDarkViolet, clrLightSeaGreen};
   color color2[3] = {clrRed, clrMagenta, clrDarkOrchid};
   for( i = Cal-10; i > 10; i--)
   {
      prev_signal = 0;
      //if( i < Cal - 40)
      {
         for( j = i + 1; j <= i+20; j++){
          if( ExtSignalBuffer2[j] != 0) {prev_signal = ExtSignalBuffer2[j]; break;}
         }
      }

      cause = 0;

      if( nofilter || ( forceTrend != 0 )) {  //sell signals
         if( ((nofilter || ExtMacdBuffer[i] > TrendEMAN) && ExtMacdBuffer[i+peak_length] < ExtMacdBuffer[i]-peak_depth && ExtMacdBuffer[i-peak_length] < ExtMacdBuffer[i] - peak_depth) ||
             (ExtMacdBuffer[i-3] < 0 && ExtMacdBuffer[i] < 0 && ExtMacdBuffer[i+3] > 0) ||
             ((nofilter || ExtMacdBuffer[i] > TrendEMAN)&& ExtMacdBuffer[i-3] < ExtSignalBuffer[i-3] && ExtMacdBuffer[i] < ExtSignalBuffer[i] && ExtMacdBuffer[i+3] > ExtSignalBuffer[i+3]))
         {
               if(prev_signal < 0) continue;  //too close same signal
               if((nofilter || ExtMacdBuffer[i] > TrendEMAN) && ExtMacdBuffer[i+peak_length] < ExtMacdBuffer[i]-peak_depth && ExtMacdBuffer[i-peak_length] < ExtMacdBuffer[i] - peak_depth) cause = 1;
               else if(ExtMacdBuffer[i-3] < ExtSignalBuffer[i-3] && ExtMacdBuffer[i] < ExtSignalBuffer[i] && ExtMacdBuffer[i+3] > ExtSignalBuffer[i+3]) cause = 2; //why ? continue; //cause = 2;
               ObjectCreate("MACDKR"+i, OBJ_ARROW, 0, Time[i], High[i]+2*s);//OBJ_ARROW_DOWN
               ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,242);
               ObjectSet("MACDKR"+i, OBJPROP_WIDTH, 3);
               ObjectSetString(0, "MACDKR"+i, OBJPROP_TEXT, causestring[cause]);
               ObjectSet("MACDKR"+i, OBJPROP_COLOR, color2[cause]);
               ExtSignalBuffer2[i] = -1;
               if( nofilter || forceTrend == 1 ){ ExtSignalBuffer2[i] = -2;ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,68);}
               else if( i < Cal - forceReverse){
                  found = 0;
                  for( j = i + 1; j < i+forceReverse; j++){
                   //if( i == 188 && Symbol() == "US30" && Period() == 1 )Print(j, "=", ExtSignalBuffer2[j]);
                   if( ExtSignalBuffer2[j] != 0) {found = ExtSignalBuffer2[j]; break;}
                  }
                  if( found < 0){  //found first peak
                     ExtSignalBuffer2[i] = -2;
                     ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,68);
                  }
               }
         }
      }
      //if( i == 150 && Symbol() == "GER30" && Period() == 15 )Print(ExtMacdBuffer[i-3],"signal=",ExtSignalBuffer[i+12],"prev_signal="+prev_signal,"no filter=",nofilter);
      if( nofilter || ( forceTrend != 1))  //buy signals
      {
        if(prev_signal > 0) continue;//too close same signal
        if( ((nofilter || ExtMacdBuffer[i] < -TrendEMAN) && ExtMacdBuffer[i+peak_length] > ExtMacdBuffer[i]+peak_depth && ExtMacdBuffer[i-peak_length] > ExtMacdBuffer[i]+peak_depth) ||
          (ExtMacdBuffer[i-3] > 0 && ExtMacdBuffer[i] > 0 && ExtMacdBuffer[i+3] < 0) ||
          ((nofilter || ExtMacdBuffer[i] < -TrendEMAN)&& ExtMacdBuffer[i-3] > ExtSignalBuffer[i-3] && ExtMacdBuffer[i] > ExtSignalBuffer[i] && ExtMacdBuffer[i+3] < ExtSignalBuffer[i+3]))
         {
            if((nofilter || ExtMacdBuffer[i] < -TrendEMAN) && ExtMacdBuffer[i+peak_length] > ExtMacdBuffer[i]+peak_depth && ExtMacdBuffer[i-peak_length] > ExtMacdBuffer[i]+peak_depth) cause = 1;
            else if(ExtMacdBuffer[i-3] > ExtSignalBuffer[i-3] && ExtMacdBuffer[i] > ExtSignalBuffer[i] && ExtMacdBuffer[i+3] < ExtSignalBuffer[i+3]) cause = 2; //why ? continue; //cause = 2;
            ObjectCreate("MACDKR"+i, OBJ_ARROW, 0, Time[i], Low[i]); //OBJ_ARROW_UP
            ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,241);
            ObjectSet("MACDKR"+i, OBJPROP_WIDTH, 3);
            ObjectSetString(0, "MACDKR"+i, OBJPROP_TEXT, causestring[cause]);
            ObjectSet("MACDKR"+i, OBJPROP_COLOR, color1[cause]);
            ExtSignalBuffer2[i] = 1;
            if( nofilter || forceTrend == 0){ ExtSignalBuffer2[i] = 2;ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,67);}
            else if( i < Cal - forceReverse){
               found = 0;
               for( j = i + 1; j < i+forceReverse; j++){
                //if( i == 188 && Symbol() == "US30" && Period() == 1 )Print(j, "=", ExtSignalBuffer2[j]);
                if( ExtSignalBuffer2[j] != 0) {found = ExtSignalBuffer2[j]; break;}
               }
               if( found > 0){
                  ExtSignalBuffer2[i] = 2;
                  ObjectSet("MACDKR"+i,OBJPROP_ARROWCODE,67);
                  //if( i < 18 && Symbol() == "US30" && Period() == 1 )Print(i, "=", ExtSignalBuffer2[i]);
               }
            }
         }
      }
   }
   return(rates_total);
  }
//+------------------------------------------------------------------+