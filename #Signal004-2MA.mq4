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
extern int MA1 = 172;
extern int MA2 = 3;
extern double TakeProfit = 200;
extern double StopLoss = 90;
extern double AddRate = 0.4;   //Add Plan mark position
double point;

   bool IsAlerted = false;
   bool IsDownTrend = false;
   bool IsUpTrend = false;  
//---- indicator buffers
double     buyBuffer[];
double     sellBuffer[];
double     tkBuffer[];
double     slBuffer[];
double     addBuffer[];
double p1,p2;
double q1,q2;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   if(Symbol() == "XAUUSDs")
   {  //best for M15
      MA1 = 84;
      TakeProfit = 230;
   }
   if(Symbol() == "AUDUSDs")
   {
      MA1 = 174;
      TakeProfit = 100;
      StopLoss = 50;
   }
   
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
   p1 = iMA(NULL,0, MA1,0,MODE_SMA,PRICE_CLOSE, s+1);
   p2 = iMA(NULL,0, MA1,0,MODE_SMA,PRICE_CLOSE, s);
   q1 = iMA(NULL,0, MA2,0,MODE_SMA,PRICE_CLOSE, s+1);
   q2 = iMA(NULL,0, MA2,0,MODE_SMA,PRICE_CLOSE, s);
}

bool isUp()
{
   if( q1 <= p1 && q2 >= p2 ) return(true);
   return(false); 
   /*datetime now = TimeCurrent();
   if( now - pt > 60)
   {  pt = now;
      Print("************",p,"-",Close[0],"-",Close[1],"-",Close[2],"-",Close[3]);
   }
   */
}

bool isDown()
{   
   if( q1 >= p1 && q2 <= p2 ) return(true);
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
               if (isUp()) {
                  buyBuffer[i] = Low[i] - 5*point;
                  tkBuffer[i] = Close[i] + TakeProfit*point;
                  slBuffer[i] = Close[i] - StopLoss*point;
                  addBuffer[i] = Close[i] + AddRate * TakeProfit*point;
               }
               else if (isDown()) {
                  sellBuffer[i] = High[i] + 5*point;
                  tkBuffer[i] = Close[i] - TakeProfit*point;
                  slBuffer[i] = Close[i] + StopLoss*point;
                  addBuffer[i] = Close[i] - AddRate*TakeProfit*point;
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
 

