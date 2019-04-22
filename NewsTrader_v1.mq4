//+------------------------------------------------------------------+
//|                                            ScheduleTrader_v1.mq4 |
//|                           Copyright © 2007, TrendLaboratory Ltd. |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                   E-mail: igorad2003@yahoo.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, TrendLaboratory Ltd."
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"

#include <stdlib.mqh>

//---- input parameters
extern string     ExpertName       = "ScheduleTrader_v1";

extern int        Magic            =  111111;
extern int        Slippage         =       6;

extern string     Main_Parameters  = " Trade Volume & Trade Method";
extern string     FileName         ="Schedule.csv"; // Name of Schedule's File
extern double     Lots             =     0.1; // Lot size
extern int        MaxOrders        =      10; // Max Number of orders
extern double     TakeProfit       =      30; // Take Profit in pips       	
extern double     StopLoss         =      20; // Initial Stop in pips 
extern double     TrailingStop     =      10; // Trailing Stop in pips 
extern double     BreakEven        =      15; // Breakeven in pips  
extern int        UseExtSets       =       0; // Use External Settings for TP and IS (0-off,1-on)
extern int        DelOpposite      =       0; // Switch of opposite orders deleting: 0-off,1-on
extern int        CheckSchedule    =       0; // Check of Schedule in Experts Window 
extern int        ScheduleMode     =       0; // Schedule Mode: 0-daily,1-any date  

extern string     Time_Inputs       = " Timing parameters ";
extern int        ProcessTime      =       5; // Order processing Time in min
extern int        UseNewSigClose   =       1; // Use Order Close after new signal(0-off,1-on) 
extern int        UseEODClose      =       1; // Use EOD Close (0-off,1-on) 
extern int        SessionEnd       =      23; // Session End Time
extern int        FridayEnd        =      22; // Session End Time in Friday

extern string     MM_Parameters    = " MoneyManagement";
extern bool       MM               =   false; // ÌÌ Switch
extern double     MaxRisk          =    0.05; // Risk Factor



datetime FinTime=0;
string   sDate[1000];          
string   sTime[1000];          
string   sSymbol[1000];        
string   sOrder[1000];         
string   sPrice[1000];        
string   sStopLoss[1000];      
string   sTakeProfit[1000];    
string   sDuration[1000];
 
datetime dt[1000];
int      TypeOrder[1000],OrderDuration[1000],OK[1000];

int      BEvent=0, EventNum, TriesNum=5;
string   ScheduleName;
bool     fTime;
datetime prevTime,OpenTime=0,prevOpenTime=0;
int      totalPips=0, TimeZone = 0;
double   totalProfits=0;
double   OrderPrice,OrderSL,OrderTP;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
//---- 
   fTime = true;
   
//----
return(0);
}
  
// ---- Money Management
//---- Calculation of Position Volume
double MoneyManagement()
{
   double lot_min =MarketInfo(Symbol(),MODE_MINLOT);
   double lot_max =MarketInfo(Symbol(),MODE_MAXLOT);
   double lot_step=MarketInfo(Symbol(),MODE_LOTSTEP);
   double contract=MarketInfo(Symbol(),MODE_LOTSIZE);
   double vol;
//--- check data
   if(lot_min<0 || lot_max<=0.0 || lot_step<=0.0) 
   {
   Print("CalculateVolume: invalid MarketInfo() results [",lot_min,",",lot_max,",",lot_step,"]");
   return(0);
   }
   if(AccountLeverage()<=0)
   {
   Print("CalculateVolume: invalid AccountLeverage() [",AccountLeverage(),"]");
   return(0);
   }
//--- basic formula
   if ( MM )
   {
   vol=NormalizeDouble(AccountFreeMargin()*MaxRisk*AccountLeverage()/contract,2);
   }
   else
   vol=Lots;
//--- check min, max and step
   vol=NormalizeDouble(vol/lot_step,0)*lot_step;
   if(vol<lot_min) vol=lot_min;
   if(vol>lot_max) vol=lot_max;
//---
   return(vol);
}   

// ---- Trailing Stops
void TrailStop()
{
   int    error;  
   bool   result=false;
   double Gain = 0;
    
   for (int cnt=0;cnt<OrdersTotal();cnt++)
   { 
   OrderSelect(cnt, SELECT_BY_POS);   
   int mode=OrderType();    
      if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
      {
         if (mode==OP_BUY) 
         {
			   if ( BreakEven > TrailingStop && BEvent==0 )
			   {
			   Gain = (MarketInfo(Symbol(),MODE_BID) - OrderOpenPrice())/Point;
			      if( Gain >= BreakEven && OrderStopLoss()<=OrderOpenPrice()+1*Point) 
			      {
			      double BuyStop = NormalizeDouble(OrderOpenPrice()+1*Point,Digits);
			      BEvent=1;
			      }
			   }
			   else 			   
			   if( TrailingStop > 0) BuyStop = NormalizeDouble(MarketInfo(Symbol(),MODE_BID) - TrailingStop*Point,Digits);
			   
			   if( NormalizeDouble(OrderOpenPrice(),Digits)<= BuyStop || OrderStopLoss() == 0) 
            {   
			      if ( BuyStop > NormalizeDouble(OrderStopLoss(),Digits)) 
			      {
			         for(int k = 0 ; k < TriesNum; k++)
                  {
                  result = OrderModify(OrderTicket(),OrderOpenPrice(),
			                              BuyStop,
			                              OrderTakeProfit(),0,Lime);
                  error=GetLastError();
                     if(error==0) break;
                     else {Sleep(5000); RefreshRates(); continue;}
                  }   		 
               }            
            }
         }   
// - SELL Orders          
         if (mode==OP_SELL)
         {
            if ( BreakEven > TrailingStop && BEvent==0)
			   {
			   Gain = (OrderOpenPrice()-MarketInfo(Symbol(),MODE_ASK))/Point;
			      if( Gain >= BreakEven && OrderStopLoss()>=OrderOpenPrice()-1*Point) 
			      {
			      double SellStop = NormalizeDouble(OrderOpenPrice()-1*Point,Digits);
			      BEvent=-1;
			      }
			   }
			   else 
			   if( TrailingStop > 0) SellStop = NormalizeDouble(MarketInfo(Symbol(),MODE_ASK) + TrailingStop*Point,Digits);   
            
            if((NormalizeDouble(OrderOpenPrice(),Digits) >= SellStop && SellStop>0) || OrderStopLoss() == 0) 
            {
               if( SellStop < NormalizeDouble(OrderStopLoss(),Digits)) 
               {
                  for( k = 0 ; k < TriesNum; k++)
                  {
                  result = OrderModify(OrderTicket(),OrderOpenPrice(),
			                              SellStop,
			                              OrderTakeProfit(),0,Orange);
                  error=GetLastError();
                     if(error==0) break;
                     else {Sleep(5000); RefreshRates(); continue;}
                  }
               }   
   			}	    
         }
      }
   }     
}

// ---- Open Sell Orders
int SellOrdOpen(int ord,double price,double sl,double tp,int dur,int num) 
{		     
   int ticket = 0;
   int tr = 1;
   if (dur > 0 && ord >= 3) int exp = TimeCurrent()+dur*60; else exp = 0; 
      
   while ( ticket <= 0 && tr <= TriesNum)
   {
   ticket = OrderSend( Symbol(),ord,MoneyManagement(),
	                    NormalizeDouble(price , Digits),
	                    Slippage,
	                    NormalizeDouble(sl, Digits),
	                    NormalizeDouble(tp, Digits),
	                    ExpertName+" SELL",Magic,
	                    exp,Red);
      
      if(ticket > 0) 
      {
      BEvent=0;   
         if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
         {Print("SELL order opened : ", OrderOpenPrice());OK[num] = -1;}
      }
	   else 	
      if(ticket < 0)
	   { 	
      Sleep(5000);
      RefreshRates();
      tr += 1;
      if(GetLastError()>0)
      Print("SELL: OrderSend failed with error #",ErrorDescription(GetLastError()));
      }
   }   
   return(ticket);
}

// ---- Open Buy Orders
int BuyOrdOpen(int ord,double price,double sl,double tp,int dur,int num)
{		     
   int ticket = 0;
   int tr = 1;
   if (dur > 0 && ord >= 2) int exp = TimeCurrent()+dur*60; else exp = 0; 
      
   while ( ticket <= 0 && tr <= TriesNum)
   {
   ticket = OrderSend(Symbol(),ord,MoneyManagement(),
	                   NormalizeDouble(price , Digits),
	                   Slippage,
	                   NormalizeDouble(sl, Digits), 
	                   NormalizeDouble(tp, Digits),
	                   ExpertName+" BUY",Magic,
	                   exp,Blue);
      
      if(ticket > 0) 
      {
      BEvent=0;
         if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
         {Print("BUY order opened : ", OrderOpenPrice()); OK[num] = 1;}
      
      }
      else 
	   if(ticket < 0)
	   { 	
      Sleep(5000);
      RefreshRates();
      tr += 1;
      if(GetLastError()>0)      
      Print("BUY : OrderSend failed with error #",ErrorDescription(GetLastError()));
      }
   }   
   return(ticket);
} 

// ---- Scan Trades

int ScanTrades(int ord,int mode)
{   
   int total = OrdersTotal();
   int numords = 0;
   bool type = false; 
   int trd = 0;
   
   for(int cnt=0; cnt<total; cnt++) 
   {        
   OrderSelect(cnt, SELECT_BY_POS);            
   if ( ord != 0 )
   {
   if ( OrderType()==0 || OrderType()==2 || OrderType()==4 ) trd =  1;
   if ( OrderType()==1 || OrderType()==3 || OrderType()==5 ) trd =  2;      
   } else trd=0;
   
   if (mode == 0) type = OrderType()<=OP_SELLSTOP;
   if (mode == 1) type = OrderType()<=OP_SELL;   
   if (mode == 2) type = OrderType()>OP_SELL && OrderType()<=OP_SELLSTOP; 
   
   if(OrderSymbol() == Symbol() && type && trd==ord && OrderMagicNumber() == Magic)  
   numords++;
   }
   return(numords);
}  

datetime FinishTime(int Duration)
{   
   int total = OrdersTotal();
   datetime ftime=0;
         
   for(int i=0; i<total; i++) 
   {        
   OrderSelect(i, SELECT_BY_POS);            
   if(OrderSymbol() == Symbol() && OrderType()<=OP_SELLSTOP && OrderMagicNumber() == Magic) 
   ftime=OrderOpenTime()+ Duration*60;
   }
   return(ftime);
}

// Closing of Pending Orders      
void PendOrdDel(int mode)
{
   bool result = false;
   
   for (int i=0; i<OrdersTotal(); i++)  
   {
   OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)     
      {
         if((mode==0 || mode==1) && OrderType()==OP_BUYSTOP)
         {     
         result = OrderDelete(OrderTicket());
         if(!result) Print("BUY: OrderDelete failed with error #",GetLastError());
         }
         else
         if((mode==0 || mode==2) && OrderType()==OP_SELLSTOP)
         {     
         result = OrderDelete( OrderTicket() );  
         if(!result) Print("SELL: OrderDelete failed with error #",GetLastError());
         }
      }
   }
}    

//-----
void ReadSchedule(string fName)
{    
   int i, handle;
   bool rates=false;
   
   handle=FileOpen(fName,FILE_CSV|FILE_READ,';');
   
      if(handle<1)
      {
      Print("File not found ", GetLastError());
      return(false);
      }
      else
      if(handle>=1)
      {
      i=0;
         while(!FileIsEnding(handle))
         {
         sDate[i]=FileReadString(handle);          
         sTime[i]=FileReadString(handle);             
         sSymbol[i]=FileReadString(handle);  
         sOrder[i]=FileReadString(handle);   
         sPrice[i]=FileReadString(handle);       
         sStopLoss[i]=FileReadString(handle);      
         sTakeProfit[i]=FileReadString(handle);      
         sDuration[i]=FileReadString(handle);   
         FileReadString(handle); // null
         
            if (Symbol() == sSymbol[i]) 
            {
               if (ScheduleMode == 0)
               string sday = TimeToStr(TimeCurrent(),TIME_DATE);
               else
               sday = sDate[i];
              
            dt[i] = StrToTime(sday +" "+sTime[i])+TimeZone*3600;
                       
            if (sOrder[i] == "BuyStop") TypeOrder[i] = OP_BUYSTOP; 
            else
            if (sOrder[i] == "SellStop") TypeOrder[i] = OP_SELLSTOP; 
            else
            if (sOrder[i] == "BuyLimit") TypeOrder[i] = OP_BUYLIMIT; 
            else
            if (sOrder[i] == "SellLimit") TypeOrder[i] = OP_SELLLIMIT;
            else
            if (sOrder[i] == "Buy") TypeOrder[i] = OP_BUY; 
            else
            if (sOrder[i] == "Sell") TypeOrder[i] = OP_SELL;
            else
            TypeOrder[i] = -1;           
               if(CheckSchedule>0)
               {
               string info = (i+1)+"_"+TimeToStr(dt[i])+" "+sSymbol[i]+" "+" "+TypeOrder[i]+
               " "+sPrice[i]+" "+sStopLoss[i]+" "+sTakeProfit[i]+" "+sDuration[i];
               Print( info );
               }
            }
         i++;
         }
      FileClose(handle);
      }
   EventNum = i;
   
return(0);
}


//---- Close of Orders

void CloseOrder(int mode)  
{
   bool result=false; 
   int  total=OrdersTotal();
   
   for (int i=0; i<=total; i++)  
   {
   OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == Magic && OrderSymbol() == Symbol()) 
      {
      if ((mode == 0 || mode ==1) && OrderType()==OP_BUY ) result=CloseAtMarket(OrderTicket(),OrderLots(),Aqua);
      if ((mode == 0 || mode ==2) && OrderType()==OP_SELL) result=CloseAtMarket(OrderTicket(),OrderLots(),Pink);
      }
   }
}


bool CloseAtMarket(int ticket,double lot,color clr) 
{
   bool result = false; 
   int  ntr;
      
   int tries=0;
   while (!result && tries < TriesNum) 
   {
      ntr=0; 
      while (ntr<5 && !IsTradeAllowed()) { ntr++; Sleep(5000); }
      RefreshRates();
      result=OrderClose(ticket,lot,OrderClosePrice(),Slippage,clr);
      tries++;
   }
   if (!result) Print("Error closing order : ",ErrorDescription(GetLastError()));
   return(result);
}

bool TimeToOpen(int i)
{
   bool result = false;
   
   OpenTime = dt[i];
   //Print("i=",i," OpTime=",TimeToStr(OpenTime)," Num=",EventNum);
   if((TimeCurrent()>= OpenTime && TimeCurrent() <= OpenTime+ProcessTime*60)/* && OpenTime > prevOpenTime*/)
   {
   if ( TypeOrder[i]>=2 ) OrderPrice = StrToDouble(sPrice[i]); 
   if ( sSymbol[i]!="" && Symbol() == sSymbol[i]) result=true; 
         
      if ( UseExtSets > 0) 
      {
      OrderSL = StrToDouble(sStopLoss[i]); 
      OrderTP = StrToDouble(sTakeProfit[i]);
      }  
      else {OrderSL = 0; OrderTP = 0;}  
   //Print("i=",i, " price=",OrderPrice," Sym=",sSymbol[i]," res=",result);  
   }
   return(result);
}

void ChartComment()
{
   
   string sComment   = "";
   string sp         = "---------------------------------------------------\n";
   string NL         = "\n";
   
   TotalProfit();    
     
   sComment = sp;
   sComment = sComment+"ExpertName : "+ExpertName+NL;
        
   sComment = sComment+"Orders: Open= "+ScanTrades(0,1)+" Pending= "+ScanTrades(0,2)+" All= "+ScanTrades(0,0)+NL;
   sComment = sComment+"Current Profit(pips)= " + totalPips + NL;
   sComment = sComment+"Current Profit(USD) = " + DoubleToStr(totalProfits,2) + NL; 
    
   Comment(sComment);
}      

void TotalProfit()
{
   int total=OrdersTotal();
   totalPips = 0;
   totalProfits = 0;
   for (int cnt=0;cnt<total;cnt++)
   { 
   OrderSelect(cnt, SELECT_BY_POS);   
   int mode=OrderType();
   bool condition = false;
   if ( Magic>0 && OrderMagicNumber()==Magic && OrderSymbol() == Symbol()) condition = true;
   else if ( Magic==0 ) condition = true;   
      if (condition)
      {      
         switch (mode)
         {
         case OP_BUY:
            totalPips += MathRound((MarketInfo(Symbol(),MODE_BID)-OrderOpenPrice())/MarketInfo(Symbol(),MODE_POINT));
            totalProfits += OrderProfit();
            break;
            
         case OP_SELL:
            totalPips += MathRound((OrderOpenPrice()-MarketInfo(Symbol(),MODE_ASK))/MarketInfo(Symbol(),MODE_POINT));
            totalProfits += OrderProfit();
            break;
         }
      }            
	}
}               
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
 
//----
   
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   if(Bars < 1) {Print("Not enough bars for this strategy");return(0);}
   
   if(AccountFreeMargin()<(1000*Lots)){
   Print("We have no money. Free Margin = ", AccountFreeMargin());
   return(0);}
//---- 
   double sPoint = MarketInfo(Symbol(),MODE_POINT);
   datetime cTime = iTime(NULL,0,0);
   bool EOD = false;
   
   if (fTime || (TimeCurrent() >= cTime && cTime > prevTime))
   {
     
   ScheduleName = FileName;  
      
      if(ScheduleName != "")
      {   
      ReadSchedule(ScheduleName);
      fTime = false;
      prevTime = cTime;
      }
      else 
      {
      Print("Attention! Wrong Shedule:",ScheduleName,"time=",TimeToStr(TimeCurrent())); 
      return(0);
      }
   }
   
   ChartComment();
   //Print("Trades=",ScanTrades(0,0));
   if (ScanTrades(0,0) > 0)
   {
      if (DelOpposite > 0)
      {
         if (ScanTrades(1,1) > 0 && ScanTrades(2,2) > 0) PendOrdDel(2);
         if (ScanTrades(2,1) > 0 && ScanTrades(1,2) > 0) PendOrdDel(1);
      }      
   
      if(UseEODClose > 0)
      {
      if(DayOfWeek()!=5) datetime EndTime = StrToTime(SessionEnd+":00")-Period()*60; 
      else EndTime = StrToTime(FridayEnd+":00")-Period()*60;
      EOD = TimeCurrent()>= EndTime;
      }   
       
      for (int i=0;i<EventNum;i++)
      {
         if ((UseNewSigClose>0 && TimeToOpen(i) && TimeCurrent()>=FinishTime(ProcessTime)) || EOD)
         {
         while (ScanTrades(0,1) > 0) CloseOrder(0);
         while (ScanTrades(0,2) > 0) PendOrdDel(0);
         }
      }
   
   if (ScanTrades(0,1) > 0 && (TrailingStop>0 || BreakEven>0)) TrailStop();
   }
      
   if (EventNum==0 || ScanTrades(0,0)==0 /*|| EventNum - ScanTrades(0,0)<=0 || dt[EventNum-1]<TimeCurrent()*/)
   for (i=0;i<MaxOrders;i++) OK[i]=0;
   
   if (ScanTrades(0,0)<MaxOrders)
   { 
      for ( i=0;i<EventNum;i++)
      {                  
      //Print(" TO=",TimeToOpen(i)," OT=",TypeOrder[i]," OK=",OK[i]);  
         if(TimeToOpen(i) && TypeOrder[i]>=0 && OK[i]==0)
         {
            if (TypeOrder[i] == 0 || TypeOrder[i] == 2 || TypeOrder[i] == 4 )
            {   
            if (TypeOrder[i] == 0) double BuyPrice = MarketInfo(Symbol(),MODE_ASK);
            else BuyPrice = OrderPrice;
		      
               if (UseExtSets > 0)
               {
                  if (OrderSL > 0) double BuyStop = OrderSL;
		            else BuyStop = 0; 
		            if (OrderTP > 0) double BuyProfit = OrderTP;
                  else BuyProfit = 0;
		         } 
		         else
		         {
		            if (StopLoss > 0) BuyStop =  BuyPrice - StopLoss*sPoint; 
		            else BuyStop=0;
                  if (TakeProfit  > 0) BuyProfit = BuyPrice + TakeProfit*sPoint; 
                  else BuyProfit=0;   
               }
            int ldur = StrToInteger(sDuration[i]); 
            BuyOrdOpen(TypeOrder[i],BuyPrice,BuyStop,BuyProfit,ldur,i); 
            }
         
         
            if (TypeOrder[i] == 1 || TypeOrder[i] == 3 || TypeOrder[i] == 5 )
            {   
            if (TypeOrder[i] == 1) double SellPrice= MarketInfo(Symbol(),MODE_BID);
            else SellPrice = OrderPrice;
            
               if (UseExtSets > 0)
               {
                  if (OrderSL > 0) double SellStop = OrderSL;
		            else SellStop = 0; 
		            if (OrderTP > 0) double SellProfit = OrderTP;
                  else SellProfit = 0; 
		         }
		         else
		         {
                  if (StopLoss > 0) SellStop  = SellPrice + StopLoss*sPoint; 
                  else SellStop=0;
                  if (TakeProfit  > 0) SellProfit = SellPrice - TakeProfit*sPoint; 
                  else SellProfit=0;
               }                  
            int sdur = StrToInteger(sDuration[i]);
            SellOrdOpen(TypeOrder[i],SellPrice,SellStop,SellProfit,sdur,i);
            }
         }         
      }
   }
      
 return(0);
}//int start
//+------------------------------------------------------------------+





