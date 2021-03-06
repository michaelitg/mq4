#property copyright "鱼儿编程 QQ：276687220"
#property link      "http://babelfish.taobao.com/"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Red
#property indicator_color2 Blue
#property indicator_width1 2
#property indicator_width2 2

extern int    BandsPeriod1=20;
extern int    BandsShift1=0;
extern double BandsDeviations1=2.0;
//--- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(8); 
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer1);
   //SetIndexStyle(1,DRAW_LINE);
   //SetIndexBuffer(1,ExtMapBuffer2);
   SetLevelValue(0,0) ;
   SetLevelValue(1,1) ;
   SetLevelValue(2,0.5) ;

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
  
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {


   int    counted=IndicatorCounted();
   if(counted<0)return(-1);
   if(counted>0)counted--;
   int i=Bars-counted;
   for(int m=0;m<i;m++)
   {
   double MovingBuffer=iCustom(Symbol(),0,"Bands",BandsPeriod1,BandsShift1,BandsDeviations1,0,m);
   double UpperBuffer=iCustom(Symbol(),0,"Bands",BandsPeriod1,BandsShift1,BandsDeviations1,1,m);
   double LowerBuffer=iCustom(Symbol(),0,"Bands",BandsPeriod1,BandsShift1,BandsDeviations1,2,m);
   
   ExtMapBuffer1[m]=EMPTY;
   ExtMapBuffer2[m]=EMPTY;
   
   if(UpperBuffer-LowerBuffer!=0)
   ExtMapBuffer1[m]=(UpperBuffer-LowerBuffer); //(Close[m]-LowerBuffer)/(UpperBuffer-LowerBuffer);  
   if(MovingBuffer!=0)
   ExtMapBuffer2[m]=(UpperBuffer-LowerBuffer)/MovingBuffer*100;
   }

         
   return(0);
  }
//+------------------------------------------------------------------+

