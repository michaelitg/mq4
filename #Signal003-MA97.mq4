//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                      Copyright ?2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright 2013 michael."
//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Pink
#property indicator_color4 Red
#property indicator_color5 Lime

#include <common.mqh>

//---- indicator parameters
extern int MA_Period    = 500;   //ma
extern double TakeProfit = 700;
extern double StopLoss = 200;
extern double AddRate = 0.1;   //Add Plan mark position
extern double updownLevel = 11;
extern int    updowncount = 3;
extern int    shortma = 7;
extern int    shortmashift = 3;
extern int    cbars = 300;
double trendLevel = 2.2;
int autoTrendTrade = 0;
int MA1_Period    = 48;   //ma 
int MA2_Period    = 96;   //ma 
int MA3_Period    = 240;   //ma setting
double TakeProfit1 = 100;
double StopLoss1 = 100;
double point;
double maValue1 = 0;
double maValue2 = 0;

bool IsAlerted = false;
//---- indicator buffers
double     buyBuffer[];
double     sellBuffer[];
double     tkBuffer[];
double     slBuffer[];
double     addBuffer[];
double     signalBuffer[];

datetime ptime3 = 0;
datetime ptime4 = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {  
IndicatorBuffers(indicator_buffers);
SetIndexStyle(0, DRAW_ARROW, DRAW_ARROW,2);
SetIndexArrow(0, 233); //241
SetIndexBuffer(0, buyBuffer);
SetIndexStyle(1, DRAW_ARROW, DRAW_ARROW,2);
SetIndexArrow(1, 234); //242
SetIndexBuffer(1, sellBuffer);
SetIndexStyle(2, DRAW_ARROW, DRAW_ARROW,1);
SetIndexArrow(2, 108); //242
SetIndexBuffer(2, tkBuffer);
SetIndexStyle(3, DRAW_ARROW, DRAW_ARROW,1);
SetIndexArrow(3, 108); //242
SetIndexBuffer(3, slBuffer);
SetIndexStyle(4, DRAW_ARROW, DRAW_ARROW,1);
SetIndexArrow(4, 108); //242
SetIndexBuffer(4, addBuffer);
SetIndexStyle(5, DRAW_NONE);
SetIndexBuffer(5, signalBuffer);
IndicatorShortName("MA97 Signal");
return (0);
  }

bool isUp(int index)
{
   double p = maValue1;

   for( int i = index; i < index+updowncount; i++)
   {
      //double t = Open[i];
      //if( t < Close[i]) t = Close[i];
      //if( High[i] - t > factor*MathAbs(Open[i] - Close[i])) break;
      if(Close[i] <= p ) break;
      //test if(Close[i+1] <= p ) break;
      //if(Close[i] < p + 0.1) break;
   }
   if( i == index+updowncount)
   {
     if(Close[i] < p && Close[index] > p + updownLevel)
     //test if(Close[i+1] < p && Close[0+1] > p + updownLevel)
     {
          //飞吻行情过滤
         if( shortma > 0)
         {
            double s = maValue2;
            if( s > p ){
               if( TimeCurrent() - ptime3 > 360)
               {
                  ptime3 = TimeCurrent();
                  Print("xxxxxxxshortma skip this Up signal @",TimeToStr(Time[index], TIME_DATE | TIME_MINUTES));
               }
               return(false);
            }
         }

         return(true);
     }
  }
     //if( Day() == 17 && TimeCurrent() - dp3 > 360){
     //       dp3 = TimeCurrent();
      //      Print("==================i=",i,"p=",p,"c0=",Close[0],"ci=",Close[i]);
     //}

   return(false);
}

bool isDown(int index)
{
   double p = maValue1;

   for( int i = index; i < index+updowncount; i++)
   {
      //double t = Open[i];
      //if( t > Close[i]) t = Close[i];
      //if( t - Low[i] > factor*MathAbs(Open[i] - Close[i])) break;
      if(Close[i] >= p ) break;
      //test if(Close[i+1] >= p ) break;
      //if(Close[i] > p - 0.1) break;
   }
   if( i == index+updowncount)
   {
     if(Close[i] > p && Close[index] < p - updownLevel)
     //test if(Close[i+1] > p && Close[0+1] < p - updownLevel)
     {

         //飞吻行情过滤
         if( shortma > 0)
         {
            double s = maValue2;
            if( s < p ){
               if( TimeCurrent() - ptime4 > 360)
               {
                  ptime4 = TimeCurrent();
                  Print("xxxxxxxshortma skip this Down signal @",TimeToStr(Time[index], TIME_DATE | TIME_MINUTES));
               }
               return(false);
            }
         }
         return(true);
      }
   }

   return(false);
}

//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
   limit=cbars;
//---- macd counted in the 1-st buffer
   point=getPoint();

      //if( Period() == 15) p = 60;
      //if( Period() <= 30) p = 240;  //2013/10/8 XAU��30�����źű������4Сʱ��������
      
//---- macd counted in the 1-st buffer
   //limit = 100;
   for(int i=limit-1; i>=0; i--)
   {
      buyBuffer[i] = EMPTY_VALUE;
      sellBuffer[i] = EMPTY_VALUE;
      signalBuffer[i] = EMPTY_VALUE;
      if( tkBuffer[i+1] != EMPTY_VALUE) tkBuffer[i] = tkBuffer[i+1];
      if( slBuffer[i+1] != EMPTY_VALUE) slBuffer[i] = slBuffer[i+1];
      if( addBuffer[i+1] != EMPTY_VALUE) addBuffer[i] = addBuffer[i+1];

      //double trend;
      //trend = iCustom(NULL, 0, "#Signal006-myATRTrend", 30,12,24, trendLevel, 0, i);
      //if( trend != EMPTY_VALUE)
      if( true )
      {
               maValue1 = iMA(NULL,0, MA_Period,i,MODE_SMA,PRICE_CLOSE, 0);
               maValue2 = iMA(NULL,0, shortma,i,MODE_SMA,PRICE_CLOSE, shortmashift);
               if (isUp(i)) {
                  buyBuffer[i] = Low[i] - 5*point;
                  tkBuffer[i] = Close[i] + TakeProfit*point;
                  slBuffer[i] = Close[i] - StopLoss*point;
                  addBuffer[i] = Close[i] + AddRate * TakeProfit*point;
                  signalBuffer[i] = 0;
                  //Print(i," buy signal: ",buyBuffer[i]);
               }
               else if (isDown(i)) {
                  sellBuffer[i] = High[i] + 5*point;
                  tkBuffer[i] = Close[i] - TakeProfit*point;
                  slBuffer[i] = Close[i] + StopLoss*point;
                  addBuffer[i] = Close[i] - AddRate*TakeProfit*point;
                  signalBuffer[i] = 1;
                  //Print(i," sell signal: ",sellBuffer[i]);
               }
       }
       else if(autoTrendTrade == 1){
             int period = 30;
             double s = iCustom(NULL, period, "#Signal001-5SMAS", MA1_Period, MA2_Period, MA3_Period, 0, i);

      
             if( s == EMPTY_VALUE){
               s = iCustom(NULL, period, "#Signal001-5SMAS", MA1_Period, MA2_Period, MA3_Period, 1, i);
               if( s != EMPTY_VALUE)
               { 
                  //op = OP_SELL;
                  sellBuffer[i] = High[i] + 5*point;
                  tkBuffer[i] = Close[i] - TakeProfit1*point;
                  slBuffer[i] = Close[i] + StopLoss1*point;
               }
             }
             else{
               // op = OP_BUY;
                  buyBuffer[i] = Low[i] - 5*point;
                  tkBuffer[i] = Close[i] + TakeProfit1*point;
                  slBuffer[i] = Close[i] - StopLoss1*point;
             }
       }
   }
   
//---- done
    /*
     if ( (buyBuffer[0] != EMPTY_VALUE || sellBuffer[0] != EMPTY_VALUE ) && !IsAlerted) 
     {
               //Alert("MA97: ", Symbol(), Period(),"new order", "buy", buyBuffer[0], "sell",sellBuffer[0]);
               IsAlerted = true;
     }
     if ( !(buyBuffer[0] == EMPTY_VALUE || sellBuffer[0] == EMPTY_VALUE ) && IsAlerted) 
     {
               IsAlerted = false;
     }
     */
 
   return(0);
  }
 
