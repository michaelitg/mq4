//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                      Copyright ?2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright 2013 michael."
//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Black
#property indicator_color2 Black
#property indicator_color3 Black

//---- indicator parameters
#define MAGICMA  20130610

extern int MA1_Period    =48;   //ma 
extern int MA2_Period    =96;   //ma 
extern int MA3_Period    =240;   //ma setting

double point;

   bool IsAlerted = false;
   bool IsDownTrend = false;
   bool IsUpTrend = false;  
//---- indicator buffers
double     buyBuffer[];
double     sellBuffer[];
double     signalBuffer[];


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
SetIndexStyle(2, DRAW_NONE);
SetIndexBuffer(2, signalBuffer);
IndicatorShortName("5SMAS Signal");
ObjectCreate("junxian", OBJ_TEXT, 0, Time[0], High[0]*1.001); 
return (0);
  }

double getPoint()
{
      double point=MarketInfo(Symbol(),MODE_POINT);
      if( point <= 0.0001) point = 0.0001;
      else point = 0.01;
      if( Ask > 800) point = 0.1;  //gold
      
      return(point);
}

double avg_wpr(int start, int calPeriod)
{
   int i;
   double a = 0;
   for( i = start; i < start + calPeriod; i++)
   {
      a = a + iCustom(NULL,0,"WPR", 12, 48, false, 1, i);
   }
   return(a / calPeriod);
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
   
   double MA1_c, MA2_c, MA3_c, MA1, MA2, MA3, t;
//---- macd counted in the 1-st buffer
   //limit = 100;
   for(int i=limit; i>=0; i--)
   {
      buyBuffer[i] = EMPTY_VALUE;
      sellBuffer[i] = EMPTY_VALUE;
      signalBuffer[i] = -1;
      t = iCustom(NULL, 0, "#Signal002-MATrend", MA1_Period, MA2_Period, MA3_Period, 3, i);
      double aa1 = avg_wpr(i, 36);      
      double aa2 = avg_wpr(i+1, 1);
      double wpra =iCustom(NULL,0,"WPR", 12, 48, false, 1, i);
      //if( i == 100 ) Print("i=",i,"wpr1=",aa1,"wpr2=",aa2,"wpra=",wpra,"signal=",signalBuffer[i],"@",TimeToStr(Time[i], TIME_DATE|TIME_MINUTES));
      if( wpra > -50){
         if( wpra < -20 && aa1 < -30 && aa2 >= -20 && t > 0 )
         { sellBuffer[i] = High[i] + 5 * point; signalBuffer[i] = 1; }
         //if( wpra < -20 && aa1 < -30 && aa2 >= -20 && t < 0 && curt < 0) sellBuffer[i] = High[i] + 5 * point; 
         //if( aa1 < -30 && aa2 >= -20 && t < 0) sellBuffer[i] = High[i] + 10 * point; 
      }   
      else{
         if( wpra > -80  && aa1 > -70 && aa2 <= -80 && t == 0 )
         { buyBuffer[i] = Low[i] - 5 * point; signalBuffer[i] = 0; }
         //if( wpra < -20 && aa1 < -30 && aa2 >= -20 && t < 0 && curt < 0) sellBuffer[i] = High[i] + 5 * point; 
         //if( aa1 > -70 && aa2 <= -80 && t > 0) buyBuffer[i] = Low[i] - 10 * point;
      }
   }
   {
      MA1_c=iMA(NULL,0,MA1_Period,0,MODE_SMA,PRICE_CLOSE,0);
      MA2_c=iMA(NULL,0,MA2_Period,0,MODE_SMA,PRICE_CLOSE,0);
      MA3_c=iMA(NULL,0,MA3_Period,0,MODE_SMA,PRICE_CLOSE,0);
   }
   
//---- done

     if ( (buyBuffer[1] > 0 || sellBuffer[1] >0 ) && !IsAlerted) 
     {
               //Alert("5SMAS Signal: ", Symbol(), Period(),"分钟", "buy", buyBuffer[1], "sell",sellBuffer[1]);
               IsAlerted = true;
     }
     if ( !(buyBuffer[1] > 0 || sellBuffer[1] >0 ) && IsAlerted) 
     {
               IsAlerted = false;
     }
     
     //if(totalOrder > 0) 
         //Comment("5SMAS Profit: ", BufferProfit/point, "Order: ",totalOrderProfit,"/",totalOrder," ",totalOrderProfit/totalOrder*100,"%", " Add: ", totalAddProfit,"/",totalAdd, " ",r*100,"%"); 
    string c1 = "(当前震荡)"; //当前周期的排列，只能起参考作用，必须看上一级周期的排列
    if ( ((MA1_c<MA2_c)&&(MA2_c<MA3_c))) c1 = "(当前空头)";
    if( ((MA1_c>MA2_c)&&(MA2_c>MA3_c))) c1 = "(当前多头)";

    //t = getTrend(MA1_Period, MA2_Period, MA3_Period, 0);
    string c = "均线震荡"+c1;
    if ( t > 0 ) c = "均线空头"+c1+"排列";
    else if( t == 0) c = "均线多头"+c1+"排列";
    
    ObjectMove("junxian", 0, Time[0], High[0]*1.001); 
    double a1 = avg_wpr(0, 24);
    double a2 = avg_wpr(1, 1);
    double wpr =iCustom(NULL,0,"WPR", 12, 48, false, 1, 0);
    string w = "短线等待";
    if( wpr > -50){
       if( a1 < -30 && a2 >= -20 ) w = "做空信号！"; 
       else w = w + "做空";
    }   
    else{
       if( a1 > -70 && a2 <= -80) w = "做多信号！"; 
       else w = w + "做多";
    }
    if( wpr >= -20) w = "短线做空";
    if( wpr <= -80) w = "短线做多";
    

    string s = c + "," + w + "("+DoubleToStr(a1,0)+","+DoubleToStr(a2,0)+")";
    ObjectSetText("junxian", s, 10);
    c = ">";
    if( MA1_c < MA2_c) c = "<";
    s = ">";
    if( MA2_c < MA3_c) s = "<";
    Comment("5SMAS@",TerminalName(),":", DoubleToStr(MA1_c,Digits), c, DoubleToStr(MA2_c,Digits), s, DoubleToStr(MA3_c,Digits));
   return(0);
  }
 
  
  int deinit()
  {
      ObjectDelete("junxian");
  }
 

