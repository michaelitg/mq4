//+------------------------------------------------------------------+
//|                                                  SHI_Channel.mq4 |
//|                                 Copyright © 2004, Shurka & Kevin |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, Shurka & Kevin"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Red
double ExtMapBuffer1[];
double TL1Buffer[];
double TL2Buffer[];
double UDBuffer[];
//---- input parameters
extern int       AllBars=240;
extern int       BarsForFract=0;
int CurrentBar=0;
double Step = 0;
int B1=-1,B2=-1;
int UpDown=0;
double P1=0,P2=0,PP=0;
int i=0,AB=300,BFF=0;
int ishift=0;
double iprice=0;
datetime T1,T2;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_ARROW,EMPTY,3);
   SetIndexArrow(0,164);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexEmptyValue(0,0.0);
   SetIndexStyle(1,DRAW_NONE);
   SetIndexBuffer(1,TL1Buffer);
   SetIndexStyle(2,DRAW_NONE);
   SetIndexBuffer(2,TL2Buffer);
   SetIndexStyle(3,DRAW_NONE);
   SetIndexBuffer(3,UDBuffer);
//----
	
	
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }

void DelObj()
{
	ObjectDelete("TL1");
	ObjectDelete("TL2");
	ObjectDelete("MIDL");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//---- 
	if ((AllBars==0) || (Bars<AllBars)) AB=Bars; else AB=AllBars;
	if (BarsForFract>0) 
		BFF=BarsForFract; 
	else
	{
		switch (Period())
		{
			case 1: BFF=12; break;
			case 5: BFF=48; break;
			case 15: BFF=24; break;
			case 30: BFF=24; break;
			case 60: BFF=12; break;
			case 240: BFF=15; break;
			case 1440: BFF=10; break;
			case 10080: BFF=6; break;
			default: DelObj(); return(-1); break;
		}
	}
	CurrentBar=2; 
	B1=-1; B2=-1; UpDown=0;
	while(((B1==-1) || (B2==-1)) && (CurrentBar<AB))
	{
		if((UpDown<1) && (CurrentBar==Lowest(Symbol(),Period(),MODE_LOW,BFF*2+1,CurrentBar-BFF))) 
		{
			if(UpDown==0) { UpDown=-1; B1=CurrentBar; P1=Low[B1]; }
			else { B2=CurrentBar; P2=Low[B2];}
		}
		if((UpDown>-1) && (CurrentBar==Highest(Symbol(),Period(),MODE_HIGH,BFF*2+1,CurrentBar-BFF))) 
		{
			if(UpDown==0) { UpDown=1; B1=CurrentBar; P1=High[B1]; }
			else { B2=CurrentBar; P2=High[B2]; }
		}
		CurrentBar++;
	}
	if((B1==-1) || (B2==-1)) {DelObj(); return(-1);} 
	Step=(P2-P1)/(B2-B1);
	P1=P1-B1*Step; B1=0;
	
	if(UpDown==1)
	{ 
		PP=Low[2]-2*Step;
		for(i=3;i<=B2;i++) 
		{
			if(Low[i]<PP+Step*i) { PP=Low[i]-i*Step; }
		}
		if(Low[0]<PP) {ishift=0; iprice=PP;}
		if(Low[1]<PP+Step) {ishift=1; iprice=PP+Step;}
		if(High[0]>P1) {ishift=0; iprice=P1;}
		if(High[1]>P1+Step) {ishift=1; iprice=P1+Step;}
	} 
	else
	{ 
		PP=High[2]-2*Step;
		for(i=3;i<=B2;i++) 
		{
			if(High[i]>PP+Step*i) { PP=High[i]-i*Step;}
		}
		if(Low[0]<P1) {ishift=0; iprice=P1;}
		if(Low[1]<P1+Step) {ishift=1; iprice=P1+Step;}
		if(High[0]>PP) {ishift=0; iprice=PP;}
		if(High[1]>PP+Step) {ishift=1; iprice=PP+Step;}
	}

	P2=P1+AB*Step;
	T1=Time[B1]; T2=Time[AB];
	if(iprice!=0) ExtMapBuffer1[ishift]=iprice;
	//if(iprice!=0) ExtMapBuffer1[0]=iprice;
	//else ExtMapBuffer1[0]=EMPTY_VALUE;
	DelObj();
	TL1Buffer[0] = PP;
	TL2Buffer[0] = P1;
	UDBuffer[0]=UpDown;

//----
   return(0);
  }
//+------------------------------------------------------------------+