#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Blue
#property indicator_color2 Yellow

extern int    autoTimeFrame = 30;
extern int    autoTrendPeriod = 12;
extern int    autoTrendRange = 24;
extern double autoTrendLevel = 2.2;
//extern int CountBars = 300;
double BufferHasTrend[];
double BufferNoTrend[];
//double BufferTrend[];

int init() {
IndicatorBuffers(indicator_buffers);
SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
SetIndexBuffer(0, BufferHasTrend);
SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 2);
SetIndexBuffer(1, BufferNoTrend);
IndicatorShortName("#Signal006-myATRTrend(" + autoTimeFrame + "," + autoTrendPeriod+","+autoTrendRange+","+DoubleToStr(autoTrendLevel,1)+ ")");
return (0);
}

int deinit() {
return (0);
}

double myATR(int t, int s, int p)
{
   int i;
   double c1, max, tmax;
   max = 0;
   tmax = 0;
   for( i = s; i <= p+s; i++)
   {
      max = iHigh(NULL, t, i) - iLow(NULL, t, i);
      c1 = MathAbs(iHigh(NULL, t, i) - iClose(NULL, t, i+1));
      if( max < c1) max = c1;
      c1 = MathAbs(iLow(NULL, t, i) - iClose(NULL, t, i+1));
      if( max < c1) max = c1;
      tmax += max; 
   }
   return(tmax / p);
}

int start() {
int limit;
int counted_bars=IndicatorCounted();
//---- last counted bar will be recounted
if(counted_bars>0) counted_bars--;
limit=Bars-counted_bars;

//limit = 280;
//SetIndexDrawBegin(0, limit-autoTrendRange);
//SetIndexDrawBegin(1, limit-autoTrendRange);
int calPeriod = autoTimeFrame;
for(int i=limit; i>=0; i--)
{
      int trend;
      //int d = i/2 + i/24/8;  //adjust for SFA
      //int d = i/2+i/24/10; //adjust for AETOS
      int d = i/2;  //adjust for FXCM
      //double sum = 0;
      //for( int j = 0; j < autoTrendRange; j++)
         //sum += myATR(calPeriod, d+j, autoTrendPeriod);
      //if( sum / autoTrendRange > autoTrendLevel) trend = 1;  
      double myatr = myATR(calPeriod, d, autoTrendPeriod);
      if(myatr > autoTrendLevel) trend = 1;
      else trend = 0;
      BufferHasTrend[i] = EMPTY_VALUE;
      BufferNoTrend[i] = EMPTY_VALUE;
      //if( StringFind(TimeToStr(Time[i], TIME_DATE|TIME_MINUTES), "2014.01.02 0") >= 0) 
      //      Print("xxxxi=",i,"xxxxxd=",i/2,"ATRTrend=", myatr,"-[",iATR(NULL, calPeriod, autoTrendPeriod, i/2),"]-",iATR(NULL, 30, autoTrendPeriod, i/2+i/24/10),"@",TimeToStr(Time[i], TIME_DATE|TIME_MINUTES));
      if( trend == 1) BufferHasTrend[i] = myatr;//iATR(NULL, 30, autoTrendPeriod, d); //sum / autoTrendRange;
      else BufferNoTrend[i] = myatr;//iATR(NULL, 30, autoTrendPeriod, d);// sum / autoTrendRange;
}
return (0);
}

