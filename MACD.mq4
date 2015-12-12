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
#property  indicator_buffers 2
#property  indicator_color1  Silver
#property  indicator_color2  Red
#property  indicator_width1  2
//--- indicator parameters
input int InpFastEMA=120;   // Fast EMA Period
input int InpSlowEMA=260;   // Slow EMA Period
input int InpSignalSMA=90;  // Signal SMA Period

extern bool DST=True;   //-----夏令时
extern string comm = "FXCM 3 FOREX-USA 9 FOREX AU 1";
extern int BrokerTimeZone=3;
datetime alarmtime = 0;

//--- indicator buffers
double    ExtMacdBuffer[];
double    ExtSignalBuffer[];
//--- right input parameters flag
bool      ExtParameters=false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   IndicatorDigits(Digits+1);
//--- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexDrawBegin(1,InpSignalSMA);
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer);
   SetIndexBuffer(1,ExtSignalBuffer);
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
   MakeAllLabels();
//--- initialization done
   return(INIT_SUCCEEDED);
  }
  
int deinit()
{
   //---- 
   ObjectDelete(0, "time");
   ObjectDelete(0, "msg");
   ObjectDelete(0, "伦敦");
   ObjectDelete(0, "伦敦时间");
   ObjectDelete(0, "纽约");
   ObjectDelete(0, "纽约时间");
   ObjectDelete(0, "insurance");
   ObjectDelete(0, "悉尼");
   ObjectDelete(0, "悉尼时间");
   ObjectDelete(0, "北京");
   ObjectDelete(0, "北京时间");
   ObjectDelete(0, "policy");
   //----
   return(0);
}

void MakeAllLabels()
{
   ObjectMakeLabel ("time",15,15, 0, 1);
   ObjectMakeLabel( "msg", 15,35, 0, 1 );
   //----------------------------------------------
   ObjectMakeLabel( "北京", 15,35 );
   ObjectMakeLabel( "北京时间", 75, 35 );
   ObjectMakeLabel( "伦敦", 15, 52 );
   ObjectMakeLabel( "伦敦时间", 75, 52 );
   ObjectMakeLabel( "纽约", 15,69 );
   ObjectMakeLabel( "纽约时间", 75,69 );
   ObjectMakeLabel( "insurance", 15,15);
   ObjectMakeLabel( "悉尼", 15,69 +17);
   ObjectMakeLabel( "悉尼时间", 75,69+17 );
   ObjectMakeLabel( "policy", 15,69+35);

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
   if(rates_total<=InpSignalSMA || !ExtParameters)
      return(0);
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
   timecall();
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void timecall()
{

color        LabelColor=Blue;
color        ClockColor=Blue;
string       Font="Verdana";
int          FontSize=13;
int          Corner=0;
int BeiJingTZ =8;
int LondonTZ = 0;
int NewYorkTZ = -5;
int SydneyTZ = 10;

   int dstDelta=0;
   if ( DST )
      dstDelta = 1;
  
   datetime GMT = CurTime() - (BrokerTimeZone- dstDelta)*3600;
   datetime BeiJing = GMT + ( BeiJingTZ ) * 3600;
   datetime London = GMT + (LondonTZ ) * 3600;
   datetime NewYork = GMT + (NewYorkTZ ) * 3600;
   datetime Sydney = GMT + (SydneyTZ + dstDelta) * 3600;
   
   //Print( brokerTime, " ", GMT, " ", local, " ", london, " ", tokyo, " ", newyork  );
  
   string BeiJingTime = TimeToStr(BeiJing, TIME_MINUTES  );
   string LondonTime = TimeToStr(London, TIME_MINUTES  );
   string NewYorkTime = TimeToStr(NewYork, TIME_MINUTES  );
   string SydneyTime = TimeToStr(Sydney, TIME_MINUTES  );
   
   if( ObjectFind(ChartID(), "msg") == false)
     {
         MakeAllLabels();
     } 
   ObjectSetText( "北京", "北京:",FontSize,Font, LabelColor );  
   ObjectSetText( "北京时间",BeiJingTime,FontSize,Font, ClockColor );
   ObjectSetText( "伦敦", "伦敦:", FontSize,Font, LabelColor );
   ObjectSetText( "伦敦时间",LondonTime,FontSize,Font, ClockColor );
   ObjectSetText( "纽约", "纽约:",FontSize, Font, LabelColor );
   ObjectSetText( "纽约时间",NewYorkTime ,FontSize,Font, ClockColor );
   ObjectSetText( "悉尼", "悉尼:",FontSize, Font, LabelColor );
   ObjectSetText( "悉尼时间",SydneyTime ,FontSize,Font, ClockColor );
   double marginValue=MarketInfo(Symbol(),MODE_MARGINREQUIRED);
   ObjectSetText( "insurance","一手保证金:"+DoubleToStr(marginValue,0),FontSize,Font, ClockColor );
   ObjectSetText( "policy", "红线下逢高做空，红线上逢低做多",FontSize,Font, ClockColor);
   CandleTime();
}

void CandleTime()
{
	double i;
   int mi,m,s;
   m=Time[0]+Period()*60-CurTime();
   i=m/60.0;
   s=m%60;
   mi=(m-m%60)/60;
   int a = 0;
   bool r = isReverse(1,0);
	if(  Period() >= 15 && (mi == a || r) && alarmtime == 0)
	{
	   string as = "阳线";
	   if( Open[0] > Close[0]) as = "阴线";
	   int d = 4;
	   if( Ask > 10) d = 2;
	   if( r ) PlaySound("reverse.wav");
	   else if(Symbol() == "AUDUSD") PlaySound("alert2.wav");
	   if( r || Symbol() == "AUDUSD") Print(Symbol()+Period()," alarm , reverse=",r,"@",TimeToStr(TimeCurrent()));
	   if( r || Symbol() == "AUDUSD" ) Alert(Symbol()+Period()+"["+DoubleToString(Ask,d)+"],"+as+" reverse="+r+"@"+TimeToStr(TimeCurrent()));
	   alarmtime = CurTime();
	}
   else
   {
      if(  alarmtime > 0 && CurTime() - alarmtime > MathMax(120, mi*60/2 )) alarmtime = 0;
   }
   string msg="ATR="+ DoubleToStr( iATR(Symbol(),PERIOD_D1,14,0)/Point/10,0)
                +" ["+ DoubleToStr( iLow(Symbol(),PERIOD_D1,0),4)
                +"-"+ DoubleToStr( iHigh(Symbol(),PERIOD_D1,0),4)
                +"] 往上:"+ DoubleToStr( (iLow(Symbol(),PERIOD_D1,0)+iATR(Symbol(),PERIOD_D1,14,0)),4)
                +"往下:"+ DoubleToStr( (iHigh(Symbol(),PERIOD_D1,0)- iATR(Symbol(),PERIOD_D1,14,0)),4);
   //ObjectSetText("time", TimeToStr(Time[1])+"xx"+TimeToStr(TimeCurrent())+StringFormat("--%d",Period()*60)+StringFormat("--%02d",m)+"K线"+StringFormat("%02d",mi)+"分"+StringFormat("%02d",s)+"秒"+" 平均成本:"+DoubleToStr(GetOrderAvg(),4)+" 当前价："+DoubleToStr(Bid,4)+"/"+DoubleToStr(Ask,4), 13, "Verdana", Blue);
   ObjectSetText("time", "K线"+StringFormat("%02d",mi)+"分"+StringFormat("%02d",s)+"秒"+" 平均成本:"+DoubleToStr(GetOrderAvg(),4)+" 当前价："+DoubleToStr(Bid,4)+"/"+DoubleToStr(Ask,4), 13, "Verdana", Blue);
   ObjectSetText("msg", msg, 13, "Verdana", Blue);


}

void ObjectMakeLabel( string n, int xoff, int yoff, int window = 1, int Corner=0 ) 
  {
   {
      ObjectCreate( ChartID(), n, OBJ_LABEL, window, 0, 0 );
      ObjectSet( n, OBJPROP_CORNER, Corner );
      ObjectSet( n, OBJPROP_XDISTANCE, xoff );
      ObjectSet( n, OBJPROP_YDISTANCE, yoff );
      ObjectSet( n, OBJPROP_BACK, false );
    }
  }
  
bool isReverse(int m, int n)
{
   if( (ExtSignalBuffer[n] >= ExtMacdBuffer[n] && ExtSignalBuffer[m] < ExtMacdBuffer[m])
      || ( ExtSignalBuffer[n] <= ExtMacdBuffer[n] && ExtSignalBuffer[m] > ExtMacdBuffer[m]))
   {
      return true;
   }
  
   return false;
}

  bool isReverse2(int m, int n)
{
   if(MathAbs(Open[m] - Close[m]) < 3*Point)  return false;
   
   if( Open[m] < Close[m])
   {
      if( Open[n] > Close[n] && Close[n] < Open[m]) return true;
   }
   else
   {
      if( Open[n] < Close[n] && Close[n] > Open[m]) return true;
   }   
   return false;
}
double GetOrderAvg()
{
   double avg = 0;
   int n = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( OrderSymbol()!=Symbol() || OrderType() > OP_SELL) continue;
      //---- check order type 
      avg += OrderOpenPrice();
      n++;
     }
     if( n == 0) return 0;
     return avg/n;
}

