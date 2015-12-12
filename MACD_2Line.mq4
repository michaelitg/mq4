//+------------------------------------------------------------------+
//|                                                    MACD2Line.mq4 |
//|                                Copyright (c) 2015 michael zhu    |
//|                                    mailto:michaelitg@outlook.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2015 michael zhu"
#property link      "mailto:michaelitg@outlook.com"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Green

//---- input parameters
extern int       FastMAPeriod=60;
extern int       SlowMAPeriod=130;
extern int       SignalMAPeriod=45;

datetime alarmtime = 0;

//---- buffers
double MACDLineBuffer[];
double SignalLineBuffer[];
double HistogramBuffer[];

//---- variables
double alpha = 0;
double alpha_1 = 0;

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
   int limit;
   int counted_bars = IndicatorCounted();
   //---- check for possible errors
   if (counted_bars<0) return(-1);
   //---- last counted bar will be recounted
   if (counted_bars>0) counted_bars--;
   limit = Bars - counted_bars;

   for(int i=limit; i>=0; i--)
   {
      MACDLineBuffer[i] = iMA(NULL,0,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,i) - iMA(NULL,0,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,i);
      SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
      HistogramBuffer[i] = MACDLineBuffer[i] - SignalLineBuffer[i];
   }

   for(i=1000; i>=5; i--)
   {
      if( MathAbs(HistogramBuffer[i]) < 0.01)
      {
         int s = 234; 
         int c = Green;
         double price = High[i] * 1.001; 
         bool signal = false;
         double a1 = avg(HistogramBuffer, i, 5);
         double a2 = avg(HistogramBuffer, i-5, 5);
         //int t = trend(i);
         if( a1 < 0 && a2 > 0 )
         {
            s = 233;
            c = Red;
            price  = Low[i]*0.999;
            signal = true;
         }
         if( a1 > 0 && a2 < 0 ) signal = true;
         if( signal)
         {
            int chart_ID = 0;
            string name = "macd2line_"+ TimeToStr(Time[i],TIME_DATE)+StringSubstr(TimeToStr(Time[i], TIME_MINUTES),0,2);
            ObjectCreate(chart_ID, name, OBJ_ARROW, 0, Time[i], price);
            ObjectSet(name,OBJPROP_ARROWCODE,s);
            ObjectSetInteger(chart_ID,name,OBJPROP_COLOR, c); 
            ObjectSet(name,OBJPROP_WIDTH,2);
            //Print("Macd2Line: ",name, " a1=",a1," a2=",a2," t=",t,"macdm=",iCustom(Symbol(),0,"MACD2", 120, 260, 90, 0, i),"macds=",iCustom(Symbol(),0,"MACD2", 120, 260, 90, 1, i));
            Print("Macd2Line: ",name, " a1=",a1," a2=",a2," s=",s);
         }
      }
   }
   //----
   return(0);
}

double avg(double aaa[], int start, int calPeriod)
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
   double m = iCustom(Symbol(),0,"MACD2", 120, 260, 90, 0, i);
   double s = iCustom(Symbol(),0,"MACD2", 120, 260, 90, 1, i);
   if( m < s) return -1;
   else return 1;
}
*/