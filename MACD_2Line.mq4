//+------------------------------------------------------------------+
//|                                                    MACD2Line.mq4 |
//|                                Copyright (c) 2015 michael zhu    |
//|                                    mailto:michaelitg@outlook.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2015 michael zhu"
#property link      "mailto:michaelitg@outlook.com"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Green
#property indicator_color4 Black
#property indicator_color5 Lime
#property indicator_color6 Gold

#include <MovingAverages.mqh>

//---- input parameters
extern int       FastMAPeriod=60;
extern int       SlowMAPeriod=130;
extern int       SignalMAPeriod=45;
extern int       Roc1 = 160;  //for fast current, use 80/140
extern int       Roc2 = 280;
extern double    MACDOpenLevel = 3;

datetime alarmtime = 0;

//---- buffers
double MACDLineBuffer[];
double SignalLineBuffer[];
double HistogramBuffer[];
//---- slow buffers
double ExtMacdBuffer[];
double TrendBuffer[];
double SignalBuffer[];
//double    ExtSignalBuffer[20000];
//---- variables
double alpha = 0;
double alpha_1 = 0;
double roc1, roc2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
   //---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,MACDLineBuffer);
   SetIndexDrawBegin(0,SlowMAPeriod);
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT);
   SetIndexBuffer(1,SignalLineBuffer);
   SetIndexDrawBegin(1,SlowMAPeriod+SignalMAPeriod);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(2,HistogramBuffer);
   SetIndexDrawBegin(2,SlowMAPeriod+SignalMAPeriod);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,ExtMacdBuffer);
   SetIndexDrawBegin(3,SlowMAPeriod*2);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexBuffer(4,SignalBuffer);
   SetIndexDrawBegin(4,SlowMAPeriod);
   SetIndexStyle(5,DRAW_LINE);
   SetIndexBuffer(5,TrendBuffer);
   SetIndexDrawBegin(5,SlowMAPeriod);
   //---- name for DataWindow and indicator subwindow label
   IndicatorShortName("MACD2Line0.1("+FastMAPeriod+","+SlowMAPeriod+","+SignalMAPeriod+")");
   SetIndexLabel(0,"MACD");
   SetIndexLabel(1,"Signal");
   //----
	alpha = 2.0 / (SignalMAPeriod + 1.0);
	alpha_1 = 1.0 - alpha;
   //----
   return(0);
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   //----
   int obj_total=ObjectsTotal();
   Print("Deinit total obj=",obj_total); 
   string name; 
   for(int i=0;i<obj_total;i++) 
     { 
      name=ObjectName(i); 
      if( StringFind(name, "macd2line_") >= 0){
          //Print("Delete...",name);
          ObjectDelete(0, name);
          i--;
      } 
     } 
   //----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int limit,signal;
   int counted_bars = IndicatorCounted();
   //---- check for possible errors
   if (counted_bars<0) return(-1);
   //---- last counted bar will be recounted
   if (counted_bars>0) counted_bars--;
   limit = Bars - counted_bars;
   if( limit < 20) limit = 20;

   for(int i=limit; i>=0; i--)
   {
      MACDLineBuffer[i] = iMA(NULL,0,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,i) - iMA(NULL,0,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,i);
      SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
      HistogramBuffer[i] = MACDLineBuffer[i] - SignalLineBuffer[i];
   }
   //--- macd counted in the 1-st buffer
   for(i=0; i<limit; i++)
   {
      ExtMacdBuffer[i]=iMA(NULL,0,FastMAPeriod*2,0,MODE_EMA,PRICE_CLOSE,i)-
                    iMA(NULL,0,SlowMAPeriod*2,0,MODE_EMA,PRICE_CLOSE,i);
      TrendBuffer[i] = 0;
      string namek = "macd2line_k"+ TimeToStr(Time[i],TIME_DATE)+StringSubstr(TimeToStr(Time[i], TIME_MINUTES),0,2);
      double pricek = High[i] * 1.001; 
      int ck;
      int sk = SYMBOL_ARROWUP;
      int sp = 20;
      if( MACDLineBuffer[i] - SignalLineBuffer[i] > Point * sp && SignalLineBuffer[i] - ExtMacdBuffer[i] > Point * sp)
      {
         TrendBuffer[i] = 4 * Point * 100;       
         ck = Red;
         pricek  = Low[i]*0.999;
      }
      if( MACDLineBuffer[i] - SignalLineBuffer[i] < -sp * Point && SignalLineBuffer[i] - ExtMacdBuffer[i] < -sp * Point)
      {
         TrendBuffer[i] = -4 * Point * 100;
         ck = Green;
         sk = SYMBOL_ARROWDOWN;
      }
      if( TrendBuffer[i] != 0)
      {
            if( ObjectCreate(0, namek, OBJ_ARROW, 0, Time[i], pricek) )
            {
               ObjectSet(namek,OBJPROP_ARROWCODE, sk);
               ObjectSetInteger(0,namek,OBJPROP_COLOR, ck); 
               ObjectSet(namek,OBJPROP_WIDTH,1);
               //Print("Macd2Line: ",name, " a1=",a1," a2=",a2," t=",t,"macdm=",iCustom(Symbol(),0,"MACD2", 120, 260, 90, 0, i),"macds=",iCustom(Symbol(),0,"MACD2", 120, 260, 90, 1, i));
               //if( StringFind(Symbol(), "AUDUSD") >= 0 ) Print("Macd2Line: ",name, " a1=",a1," a2=",a2," s=",s,"t=",t," [",ExtMacdBuffer[i],"]--[",SignalLineBuffer[i],"roc=",roc1,"...",roc2);
            }
      }
   }
   //--- signal line counted in the 2-nd buffer
   //SimpleMAOnBuffer(Bars, counted_bars,0,SignalMAPeriod*2,ExtMacdBuffer,ExtSignalBuffer);
   for(i=limit; i>=5; i--)
   {
      signal = -1;
      if( (MathAbs(HistogramBuffer[i]) < 0.01 || MathAbs(ExtMacdBuffer[i]-MACDLineBuffer[i]) < 0.01))
      {
         for( int k = i+1; k <= i+8; k++){ if( SignalBuffer[k] != EMPTY_VALUE && SignalBuffer[k] >= 0 ) break;}
         if( k <= i+8) continue;
         int s = 234; 
         int c = Yellow;
         double price = High[i] * 1.001; 
         double a1 = avg(HistogramBuffer, i, 5);
         double a2 = avg(HistogramBuffer, i-5, 5);
         //int t = trend(i);
         if( a1 < 0 && a2 > MACDOpenLevel*Point)  //buy
         {
            s = 233;
            //if( t == 1) 
            c = Red;
            price  = Low[i]*0.999;
            signal = 0;
         }
         if( a1 > 0 && a2 < -MACDOpenLevel*Point ){  //sell
            signal = 1;
            //if(t == -1) 
            c = Green;
         }
         
         if( signal == -1 && MathAbs(ExtMacdBuffer[i]- MACDLineBuffer[i]) < 0.01 && MathAbs(ExtMacdBuffer[i-5]- MACDLineBuffer[i-5]) > MACDOpenLevel*Point){
            if( ExtMacdBuffer[i+1] >= MACDLineBuffer[i] && ExtMacdBuffer[i] <= MACDLineBuffer[i-1] && SignalLineBuffer[i-5] >= ExtMacdBuffer[i-5]) //buy
            {
               signal = 2;
               price  = Low[i]*0.999;
               s = 233;
               c = Brown;
            }
            if(ExtMacdBuffer[i+1] <= MACDLineBuffer[i] && ExtMacdBuffer[i] >= MACDLineBuffer[i-1] && SignalLineBuffer[i-5] <= ExtMacdBuffer[i-5]) //sell
              {
                  signal = 3;
                  c = Lime;
              }
         }
         
         string name = "macd2line_"+ TimeToStr(Time[i],TIME_DATE)+StringSubstr(TimeToStr(Time[i], TIME_MINUTES),0,2);
         if( signal != -1)
         {
            int chart_ID = 0;
            if( ObjectCreate(chart_ID, name, OBJ_ARROW, 0, Time[i], price) )
            {
               ObjectSet(name,OBJPROP_ARROWCODE,s);
               ObjectSetInteger(chart_ID,name,OBJPROP_COLOR, c); 
               ObjectSet(name,OBJPROP_WIDTH,2);
               //Print("Macd2Line: ",name, " a1=",a1," a2=",a2," t=",t,"macdm=",iCustom(Symbol(),0,"MACD2", 120, 260, 90, 0, i),"macds=",iCustom(Symbol(),0,"MACD2", 120, 260, 90, 1, i));
               //if( StringFind(Symbol(), "AUDUSD") >= 0 ) Print("Macd2Line: ",name, " a1=",a1," a2=",a2," s=",s,"t=",t," [",ExtMacdBuffer[i],"]--[",SignalLineBuffer[i],"roc=",roc1,"...",roc2);
            }
         }
         
         if( ObjectFind(0, name) >= 0 ){
            if( ObjectGet(name, OBJPROP_COLOR) == Yellow) SignalBuffer[i] = -2*Point*100;
            else if( ObjectGet(name,OBJPROP_COLOR) == Red) SignalBuffer[i] = 0;
            else if( ObjectGet(name,OBJPROP_COLOR) == Brown) SignalBuffer[i] = 2*Point*100;
            else if( ObjectGet(name,OBJPROP_COLOR) == Lime) SignalBuffer[i] = 3*Point*100;
            else SignalBuffer[i] = 1*Point*100;
         }
         else 
            SignalBuffer[i] = signal*Point*100;
      }
   }
   
   //----
   return(0);
}

double avg(double& aaa[], int start, int calPeriod)
{
   int i;
   double a = 0;
   for( i = start; i < start + calPeriod; i++)
   {
      a = a + aaa[i];
   }
   return(a / calPeriod);
}
/*
int trend(int i)
{
   roc1 = iCustom(Symbol(),0,"roc2_vg", Roc1, Roc2, 0, 0, 0, i);
   roc2 = iCustom(Symbol(),0,"roc2_vg", Roc1, Roc2, 0, 0, 1, i);
   if( roc1 < roc2) return -1;
   else return 1;
}
*/