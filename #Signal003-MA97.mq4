//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                      Copyright ?2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright 2013 michael."
//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1 Blue
#property indicator_color2 Yellow
#property indicator_color3 Blue
#property indicator_color4 Red
#property indicator_color5 Lime

#include <common.mqh>

//---- indicator parameters
extern int MA_Period    =99;   //ma 
extern double TakeProfit = 150;
extern double StopLoss = 170;
extern double AddRate = 0.4;   //Add Plan mark position
extern int MA1_Period    = 48;   //ma 
extern int MA2_Period    = 96;   //ma 
extern int MA3_Period    = 240;   //ma setting
extern double TakeProfit1 = 100;
extern double StopLoss1 = 100;
extern double updownLevel = 0.3;
extern int autoTrendTrade = 0;
extern int    shortma = 7;
extern int    shortmashift = 3;
extern double trendLevel = 2.2;
double point;

   bool IsAlerted = false;
//---- indicator buffers
double     buyBuffer[];
double     sellBuffer[];
double     tkBuffer[];
double     slBuffer[];
double     addBuffer[];
double p;
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
SetIndexStyle(2, DRAW_ARROW, DRAW_ARROW,2);
SetIndexArrow(2, 108); //242
SetIndexBuffer(2, tkBuffer);
SetIndexStyle(3, DRAW_ARROW, DRAW_ARROW,2);
SetIndexArrow(3, 108); //242
SetIndexBuffer(3, slBuffer);
SetIndexStyle(4, DRAW_ARROW, DRAW_ARROW,2);
SetIndexArrow(4, 108); //242
SetIndexBuffer(4, addBuffer);
IndicatorShortName("MA97 Signal");
return (0);
  }

void calc(int s)
{
   p = iMA(NULL,0,MA_Period,0,MODE_SMA,PRICE_CLOSE, s);
}

bool isUp(int s)
{

   for( int i = 0; i < 3; i++)
   {
      if(Close[i+s] < p - 0.0001) break;  
   }
   /*
   if( StringFind(TimeToStr(Time[s], TIME_DATE|TIME_MINUTES), "2013.08.02 12") >= 0) 
   {
     Print("isUp ======",pd,"-",s,"--i=--",i,"---MA--",p,"-Close--",Close[s],"-",Close[s+1],"-",Close[s+2],"-",Close[s+3],"@",TimeToStr(Time[s],TIME_DATE|TIME_MINUTES));
   }
   */
   if( i == 3)
   { 
     //if(Close[i+s] < p) return(true);  //org version
     if(Close[i+s] < p && Close[s] > p + updownLevel)
     {
                //飞吻行情过滤
         if( shortma > 0)
         {
            double ss = iMA(NULL,0, shortma,0,MODE_SMA,PRICE_CLOSE, s+shortmashift);
            if( ss > p ){
               if( TimeCurrent() - ptime3 > 360)
               {
                  ptime3 = TimeCurrent();
                  Print("xxxxxxxshortma skip this Up signal @",TimeToStr(TimeCurrent(), TIME_DATE | TIME_MINUTES));
               }
               return(false);
            }
         }
         return(true);  //add updownLevel
     }
   }
   return(false);
}

bool isDown(int s)
{
   for( int i = 0; i < 3; i++)
   {
      if(Close[i+s] > p + 0.0001) break;  
   }
   if( i == 3)
   {
     //if(Close[i+s] > p) return(true);  //org version 
     if(Close[i+s] > p && Close[s] < p - updownLevel)
     {
              //飞吻行情过滤
         if( shortma > 0)
         {
            double ss = iMA(NULL,0, shortma,0,MODE_SMA,PRICE_CLOSE, s+shortmashift);
            if( ss < p ){
               if( TimeCurrent() - ptime4 > 360)
               {
                  ptime4 = TimeCurrent();
                  Print("xxxxxxxshortma skip this Down signal @",TimeToStr(TimeCurrent(), TIME_DATE | TIME_MINUTES));
               }
               return(false);
            }    
         }
         return(true);  //add updownLevel
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
   int oType;
   int counted_bars=IndicatorCounted();
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- macd counted in the 1-st buffer
   point=getPoint();

      //if( Period() == 15) p = 60;
      //if( Period() <= 30) p = 240;  //2013/10/8 XAU的30分钟信号必须服从4小时均线排列
      
//---- macd counted in the 1-st buffer
   //limit = 100;
   for(int i=limit-1; i>=0; i--)
   {
      buyBuffer[i] = EMPTY_VALUE;
      sellBuffer[i] = EMPTY_VALUE;
      if( tkBuffer[i+1] != EMPTY_VALUE) tkBuffer[i] = tkBuffer[i+1];
      if( slBuffer[i+1] != EMPTY_VALUE) slBuffer[i] = slBuffer[i+1];
      if( addBuffer[i+1] != EMPTY_VALUE) addBuffer[i] = addBuffer[i+1];
      calc(i);
      double trend;
      trend = iCustom(NULL, 0, "#Signal006-myATRTrend", 30,12,24, trendLevel, 0, i);
      //if( i >= 50 && i <= 70) Print("MA97: i=",i,"time=",TimeToStr(Time[i]),"trend=",trend);
      if( trend != EMPTY_VALUE)
      {
               if (isUp(i)) {
                  buyBuffer[i] = Low[i] - 5*point;
                  tkBuffer[i] = Close[i] + TakeProfit*point;
                  slBuffer[i] = Close[i] - StopLoss*point;
                  addBuffer[i] = Close[i] + AddRate * TakeProfit*point;
               }
               else if (isDown(i)) {
                  sellBuffer[i] = High[i] + 5*point;
                  tkBuffer[i] = Close[i] - TakeProfit*point;
                  slBuffer[i] = Close[i] + StopLoss*point;
                  addBuffer[i] = Close[i] - AddRate*TakeProfit*point;
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

     if ( (buyBuffer[0] != EMPTY_VALUE || sellBuffer[0] != EMPTY_VALUE ) && !IsAlerted) 
     {
               Alert("MA97: ", Symbol(), Period(),"分钟", "buy", buyBuffer[0], "sell",sellBuffer[0]);
               IsAlerted = true;
     }
     if ( !(buyBuffer[0] == EMPTY_VALUE || sellBuffer[0] == EMPTY_VALUE ) && IsAlerted) 
     {
               IsAlerted = false;
     }
     
 
   return(0);
  }
 
  
  int deinit()
  {
  }
 

