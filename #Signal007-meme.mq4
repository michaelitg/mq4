#property indicator_chart_window

//#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Aqua//Lime
#property indicator_color2 Red


double buffer10[];
double buffer20[];
extern int period=79;//10;
extern int price=5; // 0 or other = (H+L)/2
            // 1 = Open
            // 2 = Close
            // 3 = High
            // 4 = Low
            // 5 = (H+L+C)/3
            // 6 = (O+C+H+L)/4
            // 7 = (O+C)/2
extern double lwei= 0.67;
bool Mode_Fast= true;

int init()
{
  SetIndexArrow(0,67);//200);
  SetIndexArrow(1,68);//202);  
  SetIndexBuffer(0,buffer10);
  SetIndexBuffer(1,buffer20);
return(0);
}


int deinit()
{
int i;
return(0);
}


double Value=0,Value1=0,Value2=0,Fish=0,Fish1=0,Fish2=0;

double _price;
double MinL=0;
double MaxH=0;            


void getprice0(int i)
{
MaxH = High[iHighest(NULL,0,MODE_HIGH,period,i)];
  MinL = Low[iLowest(NULL,0,MODE_LOW,period,i)];
  switch (price)
  {
  case 1: _price = Open[i]; break;
  case 2: _price = Close[i]; break;
  case 3: _price = High[i]; break;
  case 4: _price = Low[i]; break;
  case 5: _price = (High[i]+Low[i]+Close[i])/3; break;
  case 6: _price = (Open[i]+High[i]+Low[i]+Close[i])/4; break;
  case 7: _price = (Open[i]+Close[i])/2; break;
  default: _price = (High[i]+Low[i])/2; break;
  }
 
}
datetime lasttime = NULL;
int start()
{

int i;
int barras;
if ((lasttime != NULL ) && ((Time[0] - lasttime) < Period( ) )) return;
lasttime = Time[0];
SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3);
SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3);

barras = Bars;
if (Mode_Fast)
  barras = 50; //100;
i = 0;
while(i<barras)
  {
  getprice0(i);
// Value = 0.33*2*((_price-MinL)/(MaxH-MinL)-0.5) + 0.67*Value1;  
  Value = (1-lwei)*2*((_price-MinL)/(MaxH-MinL)-0.5) + lwei*Value1;  
  Value=MathMin(MathMax(Value,-0.999),0.999);
  Fish = 0.5*MathLog((1+Value)/(1-Value))+0.5*Fish1;

   
  buffer10[i] = EMPTY_VALUE;
  buffer20[i] = EMPTY_VALUE;

  if ( (Fish<0) && (Fish1>0))
  {
  buffer10[i] = Low[i];

  }  
  if ((Fish>0) && (Fish1<0))
  { buffer20[i] = High[i];
 
  }    
  Value1 = Value;
  Fish2 = Fish1;
  Fish1 = Fish;
i++;
  }
return(0);
}
//+------------------------------------------------------------------+


