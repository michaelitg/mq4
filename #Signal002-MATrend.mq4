#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Yellow

extern int MA1_Period    =48;   //ma 
extern int MA2_Period    =96;   //ma 
extern int MA3_Period    =240;   //ma setting

double BufferUp[];
double BufferDown[];
double BufferSwing[];
double BufferSignal[];
//double BufferTrend[];

//return -1: no trend   1: down 0: up
int trend_ma(int frametime, int MA1_Period, int MA2_Period, int MA3_Period, int n, int rate)
{
    int r = -1;
    double MA1=iMA(NULL,frametime,MA1_Period,0,MODE_SMA,PRICE_CLOSE,n/rate);
    double MA2=iMA(NULL,frametime,MA2_Period,0,MODE_SMA,PRICE_CLOSE,n/rate);
    double MA3=iMA(NULL,frametime,MA3_Period,0,MODE_SMA,PRICE_CLOSE,n/rate);
    
    if ( ((MA1<MA2)&&(MA2<MA3))) r = 1;
    if( ((MA1>MA2)&&(MA2>MA3))) r = 0;
    //if( StringFind(TimeToStr(Time[n], TIME_DATE|TIME_MINUTES), "2012.11.26 00") >= 0) 
    //{
     //Print("trend_ma ======",frametime,"-",n,"-",n/rate,"[",r,"]----",MA1,"-",MA2,"-",MA3,"@",TimeToStr(Time[n],TIME_DATE|TIME_MINUTES),"-",MA1_Period,"-",MA2_Period,"-",MA3_Period);
     //2013.10.15 12:19:45	#Signal002-MATrend AUDUSDs,M15: 60-279[-1]----0.9361-0.938-0.938@2013.10.10 08:30
     //alert = 1;
    //}
    return(r);
}

int init() {
IndicatorBuffers(indicator_buffers);
SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
SetIndexBuffer(0, BufferUp);
SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 2);
SetIndexBuffer(1, BufferDown);
SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 2);
SetIndexBuffer(2, BufferSwing);
SetIndexStyle(3, DRAW_NONE);
SetIndexBuffer(3, BufferSignal);
IndicatorShortName("#Signal002-MATrend(" + MA1_Period+","+MA2_Period+","+MA3_Period+ ")");
return (0);
}

int deinit() {
return (0);
}

int start() {
int limit;
int counted_bars=IndicatorCounted();
//---- last counted bar will be recounted
if(counted_bars>0) counted_bars--;
limit=Bars-counted_bars;

int p = Period();
if( Period() <= 30){
    p = 60;
}
else if(Period() == 60)
{
   p = 240;
}
else if(Period() >= 240)
{
   p = 240;
}
int rate = p / Period(); 
//limit = 280;
//SetIndexDrawBegin(0, limit);
//SetIndexDrawBegin(1, limit);
for(int i=limit; i>=0; i--)
{
      BufferSwing[i] = EMPTY_VALUE;
      BufferUp[i] = EMPTY_VALUE;
      BufferDown[i] = EMPTY_VALUE;
      int t = trend_ma(p, MA1_Period, MA2_Period, MA3_Period, i, rate);
      //if( StringFind(TimeToStr(Time[i], TIME_DATE|TIME_MINUTES), "2012.11.26 00") >= 0) 
      //      Print("xxxxxxxxxnn-",i,"-ssssssxxxxx",t,"-",p,"-",i/rate,"-",MA1_Period,"-",MA2_Period,"-",MA3_Period,"@",TimeToStr(Time[i], TIME_DATE|TIME_MINUTES));
      if( t == -1) BufferSwing[i] = Close[i]-Close[i+1];
      if( t == 1) BufferDown[i] = Close[i+1]-Close[i];
      if( t == 0)  BufferUp[i] = Close[i]-Close[i+1];
      BufferSignal[i] = t;
}
return (0);
}

