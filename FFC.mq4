//+-------------------------------------------------------------------------------------------------------+
//|                                                                                               FFC.mq4 |
//|                                                                         Copyright ?2016, DerkWehler, |
//|                                                                                          traderathome,| 
//|                                                                                           deVries,    |
//|                                                                                           qFish,      |
//|                                                                                           atstrader,  |
//|                                                                                           awran5      |
//|                                                                              Last Modifications, 2016 |
//|-------------------------------------------------------------------------------------------------------+
/*
ACKNOWLEDGEMENTS:

derkwehler and other contributors - the core code of the FFCal indicator,
                                    FFCal_v20 dated 07/07/2009, Copyright @ 2006 derkwehler 
                                    http://www.forexfactory.com/showthread.php?t=19293
                                    email: derkwehler@gmail.com 
                                    
deVries   - for his excellent donated work that significantly altered and streamlined the file 
            handling coding to establish compatibility with the new release of MT4 Build 600+,
            and which has resulted in faster code execution.                                     
            (Jobs for deVries  www.mql5.com/en/job/new?prefered=deVries) 
qFish     - for his generously given time and help during the effort to improve this indicator.
atstrader - For a neat new option controlling for what pair/pairs(s) news is shown.
                                                                       
                                                                              - Traderathome, 03-17-2014       
                                                                                email: traderathome@msn.com 

-------------------------------------------- MAIN MODIFICATIONS --------------------------------------------
------------------------------------------------------------------------------------------------------------

These modifications were applied to 03-17-2014 release founded here: http://www.forexfactory.com/showthread.php?t=114792

    Added: #property strict for compatibility with MT4 Build 600+ and better code quality.
    Added: Show event Previous/Forecast. (colored impact)
    Added: Option to show events related to active chart only (override other parameters)
    Added: Keyword filter. Find or Ignore a specific one word, i.e. "NFP", will filter out all events with/without only that word. (case-sensitive)
    Added: Option to show currency strength / bar time left / spread value.
    Added: Option to control the time for display of past events  (in minutes).
    Added: Option to set panel location in 4 chart corners.
    Added: Tool-tip on mouse hover that shows event title, impact and event time left.
    Added: Panel title. You can use it as a reminder note :)
    Modified: Show event in "Date/Time format" instead of minutes left (you can show minutes left through Tool-tip)
    Modified: Vertical lines for the upcoming events. (You may need to modify the "time offset" input depending on your broker time).
    Modified: Buffers that holds the upcoming event minute and impact (see examples below)
    Modified: Revised order of external inputs.
    Improved: Replaced DownLoadWebPageToFile() function with native Windows URLDownloadToFileW() function.
    Improved: Placed (download/read XML file) and related codes into a functions so we can call them when needed.
    Improved: Replaced "GlobalVariables" that used to update XML file with FILE_MODIFY_DATE - OnTimer() set by "AllowUpdates", "UpdateHour" inputs.
    Improved: Time GMT offset, now the events will show in your local time automatically.
    Improved: Justify the panel/text when set to right/left.
    Improved: Alert function, Now it will send beside the Popup Alert: sound alert, Push notification and Emails. (two separate alerts)
    Improved: Code quality, now the indicator is lighter and faster than ever.
    Fixed: Various bug fixes, some unnecessary/unused codes or variables removed, placed some variables inside their related functions.

-------------------------------------------- HOW TO USE BUFFERS --------------------------------------------
------------------------------------------------------------------------------------------------------------

For use in an EA, the indicator holds 2 buffers: 
- Buffer (0) Contains minutes until the most recent event 
- Buffer (1) Contains impact value for the most recent event (Low = 1, Medium = 2, High = 3)
  
*Please note that the indicator will not work on strategy tester

------------------------------------------------- EXAMPLES -------------------------------------------------
------------------------------------------------------------------------------------------------------------
Simple call: 
-------------
NOTE: if you use the simple call method, default values will be applied 

int EventMinute = (int)iCustom(NULL,0,"FFC",0,0);
if(EventMinute == 30) { .. YOUR CODE .. } 30 minutes before the event

int EventImpact = (int)iCustom(NULL,0,"FFC",1,0);
if(EventImpact == 3)  { .. YOUR CODE .. } High impact event

Advanced call:
-------------
iCustom(
        string       NULL,            // symbol 
        int          0,               // timeframe 
        string       "FFC",           // path/name of the custom indicator compiled program 
        bool         true,            // true/false: Active chart only 
        bool         true,            // true/false: Include High impact
        bool         true,            // true/false: Include Medium impact
        bool         true,            // true/false: Include Low impact
        bool         true,            // true/false: Include Speaks
        bool         false,           // true/false: Include Holidays
        string       "",              // Find keyword
        string       "",              // Ignore keyword
        bool         true,            // true/false: Allow Updates
        int          4,               // Update every (in hours)
        int          0,               // Buffers: (0) Minutes, (1) Impact
        int          0                // shift 
        );

                                                                                  - Awran5, 08-14-2016
                                                                                    email: awran5@yahoo.com
                                                                                    
-------------------------------------------------- HEADER ----------------------------------------------------
--------------------------------------------------------------------------------------------------------------
*/
#property copyright "Copyright ?2009-2016, traderathome, deVries, qFish, atstrader, awran5."
#property link "awran5@yahoo.com"
#property description "Modified version of FF Calendar Indicator with new features"
#property version "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2

#include <clock.mqh>
#include <common.mqh>

//--- to download the xml
#import "urlmon.dll"
int URLDownloadToFileW(int pCaller,string szURL,string szFileName,int dwReserved,int Callback);
#import
//---
#define INAME     "FFC"
#define TITLE		0
#define COUNTRY	1
#define DATE		2
#define TIME		3
#define IMPACT		4
#define FORECAST	5
#define PREVIOUS	6
//-------------------------------------------- EXTERNAL VARIABLE ---------------------------------------------
//------------------------------------------------------------------------------------------------------------
extern bool    ReportActive      = false;                // Report for active chart only (override other inputs)
extern bool    IncludeHigh       = true;                 // Include high
extern bool    IncludeMedium     = false;                 // Include medium
extern bool    IncludeLow        = false;                 // Include low
extern bool    IncludeSpeaks     = true;                 // Include speaks
extern bool    IncludeHolidays   = false;                // Include holidays
extern string  FindKeyword       = "";                   // Find keyword
extern string  IgnoreKeyword     = "";                   // Ignore keyword
extern bool    AllowUpdates      = true;                 // Allow updates
extern int     UpdateHour        = 4;                    // Update every (in hours)
input string   lb_0              = "";                   // ------------------------------------------------------------
input string   lb_1              = "";                   // ------> PANEL SETTINGS
extern bool    ShowPanel         = true;                 // Show panel
extern bool    AllowSubwindow    = false;                // Show Panel in sub window
extern ENUM_BASE_CORNER Corner   = 2;                    // Panel side
extern string  PanelTitle="Forex Calendar @ Forex Factory"; // Panel title
extern color   TitleColor        = C'46,188,46';         // Title color
extern bool    ShowPanelBG       = true;                 // Show panel backgroud
extern color   Pbgc              = C'25,25,25';          // Panel backgroud color
extern color   LowImpactColor    = C'91,192,222';        // Low impact color 
extern color   MediumImpactColor = C'255,185,83';        // Medium impact color      
extern color   HighImpactColor   = C'217,83,79';         // High impact color
extern color   HolidayColor      = clrOrchid;            // Holidays color
extern color   RemarksColor      = clrGray;              // Remarks color
extern color   PreviousColor     = C'170,170,170';       // Forecast color
extern color   PositiveColor     = C'46,188,46';         // Positive forecast color
extern color   NegativeColor     = clrTomato;            // Negative forecast color
extern bool    ShowVerticalNews  = true;                 // Show vertical lines
extern int     ChartTimeOffset   = 0;                    // Chart time offset (in hours)
extern int     EventDisplay      = 10;                   // Hide event after (in minutes)
input string   lb_2              = "";                   // ------------------------------------------------------------
input string   lb_3              = "";                   // ------> SYMBOL SETTINGS
extern bool    ReportForUSD      = true;                 // Report for USD
extern bool    ReportForEUR      = true;                 // Report for EUR
extern bool    ReportForGBP      = true;                 // Report for GBP
extern bool    ReportForNZD      = true;                 // Report for NZD
extern bool    ReportForJPY      = true;                 // Report for JPY
extern bool    ReportForAUD      = true;                 // Report for AUD
extern bool    ReportForCHF      = true;                 // Report for CHF
extern bool    ReportForCAD      = true;                 // Report for CAD
extern bool    ReportForCNY      = false;                // Report for CNY
input string   lb_4              = "";                   // ------------------------------------------------------------
input string   lb_5              = "";                   // ------> INFO SETTINGS
extern bool    ShowInfo          = true;                 // Show Symbol info ( Strength / Bar Time / Spread )
extern color   InfoColor         = C'0,0,255';        // Info color
extern int     InfoFontSize      = 10;                    // Info font size
input string   lb_6              = "";                   // ------------------------------------------------------------
input string   lb_7              = "";                   // ------> NOTIFICATION
input string   lb_8              = "";                   // *Note: Set (-1) to disable the Alert
extern int     Alert1Minutes     = 30;                   // Minutes before first Alert 
extern int     Alert2Minutes     = -1;                   // Minutes before second Alert
extern bool    PopupAlerts       = false;                // Popup Alerts
extern bool    SoundAlerts       = true;                 // Sound Alerts
extern string  AlertSoundFile    = "news.wav";           // Sound file name
extern bool    EmailAlerts       = false;                // Send email
extern bool    NotificationAlerts= false;                // Send push notification
//---------------------------------------------------
//---- input parameters clock
int           Clockcorner=0;
extern string input_parameters = "for the clock";
extern int       godown=0;
extern int       goright=0;
//Colors clock
extern color     labelColor=DarkSlateGray;
extern color     clockColor=DarkSlateGray;
extern color     ClockMktOpenColor=Red;
extern color     ClockMktHolidayClr=PaleTurquoise;// Blue;
bool     show12HourTime=false; //YOU CAN CHANGE IT BUT I LIKE THIS MORE
bool      ShowSpreadChart=true;
bool      ShowBarTime=true;
bool      ShowLocal=true;
bool      ShowBroker=true;
bool      ShowGMT=true;
//FOUND THE TIMES WHEN THE MARKETS WERE OPEN AT
//World Financial Markets   http://www.2011.worldmarkethours.com/Forex/index1024.htm
bool      Show_NEW_ZEALAND=false;//Auckland GMT+12
bool      Show_AUSTRALIA=true;//Sydney GMT+12
bool      Show_JAPAN=true;//Tokyo GMT+9
bool      Show_HONG_KONG=false;//    GMT+8
bool      Show_EUROPE=true;//Frankfurt GMT+1
bool      Show_LONDON=true;//GMT+0
bool      Show_NEW_YORK=true;//GMT-5
//------------------------------------------------------------------------------------------------------------
//--------------------------------------------- INTERNAL VARIABLE --------------------------------------------
//---clock
color  session_upcoming_title_color = Purple;
color  session_closing_color = Red;
datetime NZDHoliday =0;
datetime AUDHoliday =0;
datetime JPYHoliday =0;
datetime CNYHoliday =0;
datetime EURHoliday =0;
datetime GBPHoliday =0;
datetime USDHoliday =0; 

#import "kernel32.dll"

void GetLocalTime(int& TimeArray[]);
void GetSystemTime(int& TimeArray[]);
int  GetTimeZoneInformation(int& TZInfoArray[]);
#import
//---- buffers
int LondonTZ = 0;
int TokyoTZ = 9;
int NewYorkTZ = -5;
int SydneyTZ = 11;
int BerlinTZ = 1;
int AucklandTZ = 13;
int HongKongTZ = 8;
datetime newyork,london,frankfurt,tokyo,sydney,auckland,hongkong,GMT;

//--- Vars and arrays
string xmlFileName;
string sData;
string Event[200][7];
string eTitle[10],eCountry[10],eImpact[10],eForecast[10],ePrevious[10];
int eMinutes[10];
datetime eTime[10];
int anchor,x0,x1,x2,xf,xp;
int Factor;
//--- Alert
bool FirstAlert;
bool SecondAlert;
datetime AlertTime;
//--- Buffers
double MinuteBuffer[];
double ImpactBuffer[];
//--- time
datetime xmlModifed;
int TimeOfDay;
datetime Midnight;
bool IsEvent;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void initClock()
{
   int top = godown+20;
   int left2 = 70+goright;
   int left =left2;
   if (show12HourTime) left = left2-20;

   if (ShowLocal) 
   {
      ObjectMakeLabel(Clockcorner,"locl", left2, top);
      ObjectMakeLabel(Clockcorner,"loct", left-45, top);
      top += 15;
   }
   if (ShowBroker)
   {
      ObjectMakeLabel(Clockcorner,"brol", left2, top);
      ObjectMakeLabel(Clockcorner,"brot", left-45, top);
      top += 15;
   }
   if (ShowGMT)
   {       
      ObjectMakeLabel(Clockcorner,"gmtl", left2, top);
      ObjectMakeLabel(Clockcorner,"gmtt", left-45, top);
      top += 15;
   }
   top += 5;
   if (Show_NEW_ZEALAND)
   {
      ObjectMakeLabel(Clockcorner,"NZDl", left2, top);
      ObjectMakeLabel(Clockcorner,"NZDt", left-45, top);
      top += 15;      
   }
   if (Show_AUSTRALIA)
   {
      ObjectMakeLabel(Clockcorner,"sydl", left2, top);
      ObjectMakeLabel(Clockcorner,"sydt", left-45, top);
      top += 15;      
   }
   if (Show_JAPAN)
   {
      ObjectMakeLabel(Clockcorner,"tokl", left2, top);
      ObjectMakeLabel(Clockcorner,"tokt", left-45, top);
      top += 15;      
   }
   if (Show_HONG_KONG)
   {
      ObjectMakeLabel(Clockcorner,"HKl", left2, top);
      ObjectMakeLabel(Clockcorner,"HKt", left-45, top);
      top += 15;      
   }         
   if (Show_EUROPE)
   {
      ObjectMakeLabel(Clockcorner,"berl", left2, top);
      ObjectMakeLabel(Clockcorner,"bert", left-45, top);
      top += 15;      
   }   
   if (Show_LONDON)
   {
      ObjectMakeLabel(Clockcorner,"lonl", left2, top);
      ObjectMakeLabel(Clockcorner,"lont", left-45, top);
      top += 15;      
   }
   if (Show_NEW_YORK)
   {
      ObjectMakeLabel(Clockcorner,"nyl", left2, top);
      ObjectMakeLabel(Clockcorner,"nyt", left-45, top);
      top += 15;      
   }
      ObjectMakeLabel(Clockcorner,"session_opent", left-45, top);
      top += 15; 
      ObjectMakeLabel(Clockcorner,"session_closet", left-45, top);
      top += 15; 
}

int OnInit()
  {
//--- check for DLL
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED))
     {
      Alert(INAME+": Please Allow DLL Imports!");
      return(INIT_FAILED);
     }
     initClock();

//--- indicator buffers mapping
   SetIndexBuffer(0,MinuteBuffer);
   SetIndexBuffer(1,ImpactBuffer);
   SetIndexStyle(0,DRAW_NONE);
   SetIndexStyle(1,DRAW_NONE);
//--- 0 value will not be displayed 
   SetIndexEmptyValue(0,0.0);
   SetIndexEmptyValue(1,0.0);
//--- 4/5 digit brokers                         
   if(Digits%2==1) Factor=10;
   else Factor=1;
//--- get today time
   TimeOfDay=(int)TimeLocal()%86400;
   Midnight=TimeLocal()-TimeOfDay;
//--- set xml file name ffcal_week_this (fixed name)
   xmlFileName=INAME+"-ffcal_week_this.xml";
//--- checks the existence of the file.
   if(!FileIsExist(xmlFileName))
     {
      xmlDownload();
      sData=xmlRead(xmlFileName);
     }
//--- else just read it 
   else sData=xmlRead(xmlFileName);
//--- get last modification time
   xmlModifed=(datetime)FileGetInteger(xmlFileName,FILE_MODIFY_DATE,false);
//--- check for updates
   if(AllowUpdates)
     {
      if(xmlModifed<TimeLocal()-(UpdateHour*3600))
        {
         Print(INAME+": xml file is out of date");
         xmlUpdate();
        }
      //--- set timer to update old xml file every x hours  
      else EventSetTimer(UpdateHour*3600);
     }
//--- set panel corner 
   switch(Corner)
     {
      case CORNER_LEFT_UPPER:  x0=5;   x1=165; x2=15;  xf=340; xp=390; anchor=0; break;
      case CORNER_RIGHT_UPPER: x0=455; x1=265; x2=440; xf=110; xp=60;  anchor=0; break;
      case CORNER_RIGHT_LOWER: x0=455; x1=265; x2=440; xf=110; xp=60;  anchor=2; break;
      case CORNER_LEFT_LOWER:  x0=5;   x1=165; x2=15;  xf=340; xp=390; anchor=2; break;
     }
//--- indicator name
   IndicatorShortName(INAME);
//---
   return(INIT_SUCCEEDED);
  }
  
  // -----------------------------------------------------------------------------------------------------------------------------
int deinitClock() 
{ 
//----
   ObjectDelete("locl");
   ObjectDelete("loct");
   ObjectDelete("nyl");
   ObjectDelete("nyt");
   ObjectDelete("gmtl");
   ObjectDelete("gmtt");
   ObjectDelete("berl");
   ObjectDelete("bert");
   ObjectDelete("NZDl");
   ObjectDelete("NZDt");   
   ObjectDelete("lonl");
   ObjectDelete("lont");
   ObjectDelete("tokl");
   ObjectDelete("tokt");
   ObjectDelete("HKl");
   ObjectDelete("HKt");   
   ObjectDelete("sydl");
   ObjectDelete("sydt");   
   ObjectDelete("brol");
   ObjectDelete("brot");

   ObjectDelete("session_opent");
   ObjectDelete("session_closet");
   return(0); 
} 

void ShowClock()
{
   int    TimeArray[4];
   int    TZInfoArray[43];
   int    nYear,nMonth,nDay,nHour,nMin,nSec,nMilliSec;
   
   GetLocalTime(TimeArray);
//---- parse date and time from array
   nYear=TimeArray[0]&0x0000FFFF;
   nMonth=TimeArray[0]>>16;
   nDay=TimeArray[1]>>16;
   nHour=TimeArray[2]&0x0000FFFF;
   nMin=TimeArray[2]>>16;
   nSec=TimeArray[3]&0x0000FFFF;
   nMilliSec=TimeArray[3]>>16;
   string LocalTimeS = FormatDateTime(nYear,nMonth,nDay,nHour,nMin,nSec);
   datetime localTime = StrToTime( LocalTimeS );
   //-----------------------------------------------------  
   string GMTs = myTimeToString(show12HourTime, GMT );
   string locals = myTimeToString(show12HourTime, localTime  );
   string londons = myTimeToString(show12HourTime, london  );
   string frankfurts = myTimeToString(show12HourTime, frankfurt );
   string tokyos = myTimeToString(show12HourTime, tokyo  );
   string newyorks = myTimeToString(show12HourTime, newyork  );
   string sydneys = myTimeToString (show12HourTime, sydney );
   string aucklands = myTimeToString(show12HourTime, auckland );
   string hongkongs = myTimeToString(show12HourTime, hongkong );
   string brokers = myTimeToString(show12HourTime, CurTime() );

   //-----------------------------------------------------
   LondonTZ = GMT_Offset("LONDON",localTime);   //GBP
   TokyoTZ = GMT_Offset("TOKYO",localTime);     //JPY
   NewYorkTZ = GMT_Offset("US",localTime);      //USD
   SydneyTZ = GMT_Offset("SYDNEY",localTime);   //AUD
   BerlinTZ = GMT_Offset("FRANKFURT",localTime);//EUR
   AucklandTZ = GMT_Offset("AUCKLAND",localTime);//NZD
   HongKongTZ = GMT_Offset("HONGKONG",localTime);//CNY
   //-----------------------------------------------------

   int gmt_shift=4;
   int dst=GetTimeZoneInformation(TZInfoArray);
   if(dst!=0) gmt_shift=TZInfoArray[0];
   if(dst==2) gmt_shift+=TZInfoArray[42];

   GMT = localTime - gmt_shift * 3600;
   
   london = GMT + 3600 * LondonTZ;
   tokyo = GMT + 3600 * TokyoTZ;
   newyork = GMT + 3600 * NewYorkTZ;
   sydney = GMT + 3600 * SydneyTZ;
   frankfurt = GMT + 3600 * BerlinTZ;
   auckland = GMT +3600 * AucklandTZ;
   hongkong = GMT + 3600 * HongKongTZ;
  
   if ( ShowLocal ) {
      ObjectSetText( "locl", "Local time", 10, "Arial Black", labelColor );
      ObjectSetText( "loct", locals, 10, "Arial Black", ClockMktOpenColor );
     }
   if ( ShowBroker ) {
      ObjectSetText( "brol", "Broker time", 10, "Arial Black", labelColor );
      ObjectSetText( "brot", brokers, 10, "Arial Black", ClockMktOpenColor );
     }      
   if ( ShowGMT ) {
      ObjectSetText( "gmtl", "GMT", 10, "Arial Black", labelColor );
      ObjectSetText( "gmtt", GMTs, 10, "Arial Black", ClockMktOpenColor );
     }

//---------------------------   
//--------------------------
   if( Show_NEW_ZEALAND )
   {
    if (NZDHoliday < TimeCurrent())
    {
     if ((auckland > StrToTime ("10:00"))&& (auckland <  StrToTime("16:45"))&& TimeDayOfWeek(auckland) != 0 && TimeDayOfWeek(auckland) != 6)          
          {
           ObjectSetText( "NZDl", "New Zealand ", 10, "Arial Black", ClockMktOpenColor );
           ObjectSetText( "NZDt", aucklands, 10, "Arial Black", ClockMktOpenColor );   
          }
   	 else
          {
           ObjectSetText( "NZDl", "New Zealand ", 10, "Arial Black", labelColor );
           ObjectSetText( "NZDt", aucklands, 10, "Arial Black", clockColor );   
          }
    }
    if (NZDHoliday > TimeCurrent())
          {
           ObjectSetText( "NZDl", "New Zealand market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "NZDt", aucklands, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
//---------------------------
   if ( Show_AUSTRALIA )
   {
    if (AUDHoliday < TimeCurrent())    
   {
    if ((sydney > StrToTime ("10:00"))&& (sydney <  StrToTime("17:00"))&& TimeDayOfWeek(sydney) != 0 && TimeDayOfWeek(sydney) != 6)          
         {
          ObjectSetText( "sydl", "Australia ", 10, "Arial Black", ClockMktOpenColor );   
          ObjectSetText( "sydt", sydneys, 10, "Arial Black", ClockMktOpenColor );
         }
   	else
   	{
       ObjectSetText( "sydl", "Australia ", 10, "Arial Black", labelColor );
       ObjectSetText( "sydt", sydneys, 10, "Arial Black", clockColor );        
   	}
   }
    if (AUDHoliday > TimeCurrent())
          {
           ObjectSetText( "sydl", "Australia market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "sydt", sydneys, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
//---------------------------      
   if ( Show_JAPAN ) 
   {
    if (JPYHoliday < TimeCurrent())
   {
    if ((tokyo > StrToTime ("9:00"))&& (tokyo <  StrToTime("12:30"))&& TimeDayOfWeek(tokyo) != 0 && TimeDayOfWeek(tokyo) != 6)
         {
          ObjectSetText( "tokl", "Japan ", 10, "Arial Black", ClockMktOpenColor );
          ObjectSetText( "tokt", tokyos, 10, "Arial Black", ClockMktOpenColor );   
         }
      else
       if ((tokyo > StrToTime ("14:00"))&& (tokyo <  StrToTime("17:00"))&& TimeDayOfWeek(tokyo) != 0 && TimeDayOfWeek(tokyo) != 6)
         {
          ObjectSetText( "tokl", "Japan ", 10, "Arial Black", ClockMktOpenColor );
          ObjectSetText( "tokt", tokyos, 10, "Arial Black", ClockMktOpenColor );   
         }      
      else
      {
       ObjectSetText( "tokl", "Japan ", 10, "Arial Black", labelColor );
       ObjectSetText( "tokt", tokyos, 10, "Arial Black", clockColor );   
      }
   }
    if (JPYHoliday > TimeCurrent())
          {
           ObjectSetText( "tokl", "Japan market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "tokt", tokyos, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
//---------------------------         
   if (Show_HONG_KONG) 
   {
    if (CNYHoliday < TimeCurrent())
    {
     if ((hongkong > StrToTime ("10:00"))&& (hongkong <  StrToTime("17:00"))&& TimeDayOfWeek(hongkong) != 0 && TimeDayOfWeek(hongkong) != 6)   
         {
          ObjectSetText( "HKl", "Hong Kong ", 10, "Arial Black", ClockMktOpenColor );
          ObjectSetText( "HKt", hongkongs, 10, "Arial Black", ClockMktOpenColor );   
         }
   	else
   	{         
       ObjectSetText( "HKl", "Hong Kong ", 10, "Arial Black", labelColor );
       ObjectSetText( "HKt", hongkongs, 10, "Arial Black", clockColor );
      }
   }   
    if (CNYHoliday > TimeCurrent())
          {
           ObjectSetText( "HKl", "Hong Kong market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "HKt", hongkongs, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
   //--------------------------- 
   if (Show_EUROPE)
   {
    if (EURHoliday < TimeCurrent())
   {
    if ((frankfurt > StrToTime ("9:00"))&& (frankfurt <  StrToTime("17:30"))&& TimeDayOfWeek(frankfurt) != 0 && TimeDayOfWeek(frankfurt) != 6)
         {
          ObjectSetText( "berl", "Europe ", 10, "Arial Black", ClockMktOpenColor );
          ObjectSetText( "bert", frankfurts, 10, "Arial Black", ClockMktOpenColor );   
         }
   	else
   	{
       ObjectSetText( "berl", "Europe ", 10, "Arial Black", labelColor );
       ObjectSetText( "bert", frankfurts, 10, "Arial Black", clockColor );   
   	}
   }   
    if (EURHoliday > TimeCurrent())
          {
           ObjectSetText( "berl", "European market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "bert", frankfurts, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
//---------------------------      
   if (Show_LONDON)
   {
    if (GBPHoliday < TimeCurrent())
   {
    if ((london > StrToTime ("8:00"))&& (london <  StrToTime("17:00"))&& TimeDayOfWeek(london) != 0 && TimeDayOfWeek(london) != 6)          
         {
          ObjectSetText( "lonl", "UK ", 10, "Arial Black",ClockMktOpenColor );
          ObjectSetText( "lont", londons, 10, "Arial Black",ClockMktOpenColor );   
         }
   	else
   	{
       ObjectSetText( "lonl", "UK ", 10, "Arial Black", labelColor );
       ObjectSetText( "lont", londons, 10, "Arial Black", clockColor );  
   	}
   }
    if (GBPHoliday > TimeCurrent())
          {
           ObjectSetText( "lonl", "London market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "lont", londons, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
//---------------------------               
   if (Show_NEW_YORK)
   {
    if (USDHoliday < TimeCurrent())
   {
    if ((newyork > StrToTime ("8:00"))&& (newyork <  StrToTime("17:00"))&& TimeDayOfWeek(newyork) != 0 && TimeDayOfWeek(newyork) != 6)          
         {
          ObjectSetText( "nyl", "North America ", 10, "Arial Black",ClockMktOpenColor );
          ObjectSetText( "nyt", newyorks, 10, "Arial Black",ClockMktOpenColor );   
         }
   	else
   	{
       ObjectSetText( "nyl", "North America ", 10, "Arial Black", labelColor );
       ObjectSetText( "nyt", newyorks, 10, "Arial Black", clockColor ); 
   	}
   }
    if (USDHoliday > TimeCurrent())
          {
           ObjectSetText( "nyl", "New York market Holiday ", 10, "Arial Black", ClockMktHolidayClr );
           ObjectSetText( "nyt", newyorks, 10, "Arial Black", ClockMktHolidayClr );   
          }    
   }
   
   DisplaySessionInfo();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplaySessionInfo()
{
   string openSessions = "Active sessions: ";
   string closingSession = "";
//----
// info from http://www.2011.worldmarkethours.com/Forex/index1024.htm 
// New Zealand/Auckland.............: 10.00 - 16.45   localtimes timezone country
// Australia/Sydney local session...: 10.00 - 17.00
// Japan/Tokyo......................:  9.00 - 12.30    Re-opens  14.00 - 17.00 
// Hong Kong........................: 10.00 - 17.00
// Europe...........................:  9.00 - 17.30
// London local session.............: 08.00 - 17.00
// New York local session...........: 08.00 - 17.00


//New Zealand....: 10.00 - 16.45
if(NZDHoliday < TimeCurrent()){
  if ((auckland > StrToTime ("9:45"))&& (auckland <  StrToTime("10:00"))&& TimeDayOfWeek(auckland) != 0 && TimeDayOfWeek(auckland) != 6)
      {closingSession = "New Zealand opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}
  if ((auckland > StrToTime ("10:00"))&& (auckland <  StrToTime("16:45"))&& TimeDayOfWeek(auckland) != 0 && TimeDayOfWeek(auckland) != 6)
   {
      openSessions = openSessions + " New Zealand";
      if(TimeHour(auckland) == 16 && TimeMinute(auckland)>14 && TimeMinute(auckland)<45)
       {
         closingSession = "New Zealand closing in " + (string)(45 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }     
//Australia...: 10.00 - 17.00
if(AUDHoliday < TimeCurrent()){   
  if ((sydney > StrToTime ("9:45"))&& (sydney <  StrToTime("10:00"))&& TimeDayOfWeek(sydney) != 0 && TimeDayOfWeek(sydney) != 6)
      {closingSession = "Australia opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}
  if ((sydney > StrToTime ("10:00"))&& (sydney <  StrToTime("17:00"))&& TimeDayOfWeek(sydney) != 0 && TimeDayOfWeek(sydney) != 6)
   {
       openSessions = openSessions + " Australia";
       if(TimeHour(sydney) == 16 && TimeMinute(sydney)>29)
       {
         closingSession = "Australia closing in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }    
//Japan ....:  9.00 - 12.30    Re-opens  14.00 - 17.00
if(JPYHoliday < TimeCurrent()){
   if (tokyo >= StrToTime ("8:45") && tokyo <  StrToTime("9:00") && TimeDayOfWeek(tokyo) > 0 && TimeDayOfWeek(tokyo) < 6 )   
        {closingSession = "Tokyo first session opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}
   if (TimeHour(tokyo) >= 9 && TimeHour(tokyo) < 17 && TimeDayOfWeek(tokyo) > 0 && TimeDayOfWeek(tokyo) < 6 )
   {   
    if ((tokyo > StrToTime ("9:00"))&& (tokyo <  StrToTime("12:30"))&& TimeDayOfWeek(tokyo) != 0 && TimeDayOfWeek(tokyo) != 6)
       {openSessions = openSessions + " Tokyo";}
    if (tokyo >= StrToTime ("13:45") && tokyo <  StrToTime("14:00") && TimeDayOfWeek(tokyo) > 0 && TimeDayOfWeek(tokyo) < 6 )
       {closingSession = "Tokyo second session opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}          
    if ((tokyo > StrToTime ("14:00"))&& (tokyo <  StrToTime("17:00"))&& TimeDayOfWeek(tokyo) != 0 && TimeDayOfWeek(tokyo) != 6)       
       {openSessions = openSessions + " Tokyo";}
       if(TimeHour(tokyo) == 16 && TimeMinute(tokyo)>29)
       {
         closingSession = "Tokyo final closing in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }     
//Hong Kong..: 10.00 - 17.00
if(CNYHoliday < TimeCurrent()){
    if ((hongkong > StrToTime ("10:00"))&& (hongkong <  StrToTime("17:00"))&& TimeDayOfWeek(hongkong) != 0 && TimeDayOfWeek(hongkong) != 6)
   {
       openSessions = openSessions + " Hong Kong";
       if(TimeHour(hongkong) == 16 && TimeMinute(hongkong)>29)
       {
         closingSession = "Hong Kong closing in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }    
//Europe...:  9.00 - 17.30
if(EURHoliday < TimeCurrent()){
   if (frankfurt >= StrToTime ("8:45") && frankfurt <  StrToTime("9:00") && TimeDayOfWeek(london) > 0 && TimeDayOfWeek(london) < 6 )   
        {closingSession = "Europe opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}
    if ((frankfurt > StrToTime ("9:00"))&& (frankfurt <  StrToTime("17:30"))&& TimeDayOfWeek(frankfurt) != 0 && TimeDayOfWeek(frankfurt) != 6)
   {
       openSessions = openSessions + " Europe";
       if(TimeHour(frankfurt) == 17 && TimeMinute(frankfurt)<30)
       {
         closingSession = "Europe closing in " + (string)(30 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }     
// London....: 08.00 - 17.00
if(GBPHoliday < TimeCurrent()){
   if (london >= StrToTime ("7:45") && london <  StrToTime("8:00") && TimeDayOfWeek(london) > 0 && TimeDayOfWeek(london) < 6 )   
        {closingSession = "London opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}
   if (TimeHour(london) >= 8 && TimeHour(london) < 17 && TimeDayOfWeek(london) > 0 && TimeDayOfWeek(london) < 6 )
   {      
         openSessions = openSessions + " London";
         if(TimeHour(london) == 16 && TimeMinute(london)>29)
       {
         closingSession = "London closing in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }  
// New York....: 08.00 - 17.00
if(USDHoliday < TimeCurrent()){
   if (newyork >= StrToTime ("7:45") && newyork <  StrToTime("8:00") && TimeDayOfWeek(newyork) > 0 && TimeDayOfWeek(newyork) < 6 )   
        {closingSession = "New York opens in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";}  
   if (TimeHour(newyork) >= 8 && TimeHour(newyork) < 17 && TimeDayOfWeek(newyork) > 0 && TimeDayOfWeek(newyork) < 6 )
   {
       openSessions = openSessions + " New York";
       if(TimeHour(newyork) == 16)
       {
         closingSession = "New York closing in " + (string)(60 - TimeMinute(TimeLocal()))+ " mins";
       } 
   }
 }  
   
//----
   if(openSessions == "Active sessions: ") openSessions = "Markets Closed";
   ObjectSetText("session_opent", openSessions,12, "Arial Black", session_upcoming_title_color);
   ObjectSetText("session_closet",closingSession ,10, "Arial Black", session_closing_color);

}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   ShowClock();
   
//--- BY AUTHORS WITH SOME MODIFICATIONS
//--- define the XML Tags, Vars
   string sTags[7]={"<title>","<country>","<date><![CDATA[","<time><![CDATA[","<impact><![CDATA[","<forecast><![CDATA[","<previous><![CDATA["};
   string eTags[7]={"</title>","</country>","]]></date>","]]></time>","]]></impact>","]]></forecast>","]]></previous>"};
   int index=0;
   int next=-1;
   int BoEvent=0,begin=0,end=0;
   string myEvent="";
//--- Minutes calculation
   datetime EventTime=0;
   int EventMinute=0;
//--- split the currencies into the two parts 
   string MainSymbol=StringSubstr(Symbol(),0,3);
   string SecondSymbol=StringSubstr(Symbol(),3,3);
//--- loop to get the data from xml tags
   while(true)
     {
      BoEvent=StringFind(sData,"<event>",BoEvent);
      if(BoEvent==-1) break;
      BoEvent+=7;
      next=StringFind(sData,"</event>",BoEvent);
      if(next == -1) break;
      myEvent = StringSubstr(sData,BoEvent,next-BoEvent);
      BoEvent = next;
      begin=0;
      for(int i=0; i<7; i++)
        {
         Event[index][i]="";
         next=StringFind(myEvent,sTags[i],begin);
         //--- Within this event, if tag not found, then it must be missing; skip it
         if(next==-1) continue;
         else
           {
            //--- We must have found the sTag okay...
            //--- Advance past the start tag
            begin=next+StringLen(sTags[i]);
            end=StringFind(myEvent,eTags[i],begin);
            //---Find start of end tag and Get data between start and end tag
            if(end>begin && end!=-1)
               Event[index][i]=StringSubstr(myEvent,begin,end-begin);
           }
        }
      //--- filters that define whether we want to skip this particular currencies or events
      if(ReportActive && MainSymbol!=Event[index][COUNTRY] && SecondSymbol!=Event[index][COUNTRY])
         continue;
      if(!IsCurrency(Event[index][COUNTRY]))
         continue;
      if(!IncludeHigh && Event[index][IMPACT]=="High")
         continue;
      if(!IncludeMedium && Event[index][IMPACT]=="Medium")
         continue;
      if(!IncludeLow && Event[index][IMPACT]=="Low")
         continue;
      if(!IncludeSpeaks && StringFind(Event[index][TITLE],"Speaks")!=-1)
         continue;
      if(!IncludeHolidays && Event[index][IMPACT]=="Holiday")
         continue;
      if(Event[index][TIME]=="All Day" ||
         Event[index][TIME]=="Tentative" ||
         Event[index][TIME]=="")
         continue;
      if(FindKeyword!="")
        {
         if(StringFind(Event[index][TITLE],FindKeyword)==-1)
            continue;
        }
      if(IgnoreKeyword!="")
        {
         if(StringFind(Event[index][TITLE],IgnoreKeyword)!=-1)
            continue;
        }
      //--- sometimes they forget to remove the tags :)
      if(StringFind(Event[index][TITLE],"<![CDATA[")!=-1)
         StringReplace(Event[index][TITLE],"<![CDATA[","");
      if(StringFind(Event[index][TITLE],"]]>")!=-1)
         StringReplace(Event[index][TITLE],"]]>","");
      if(StringFind(Event[index][TITLE],"]]>")!=-1)
         StringReplace(Event[index][TITLE],"]]>","");
      //---
      if(StringFind(Event[index][FORECAST],"&lt;")!=-1)
         StringReplace(Event[index][FORECAST],"&lt;","");
      if(StringFind(Event[index][PREVIOUS],"&lt;")!=-1)
         StringReplace(Event[index][PREVIOUS],"&lt;","");

      //--- set some values (dashes) if empty
      if(Event[index][FORECAST]=="") Event[index][FORECAST]="---";
      if(Event[index][PREVIOUS]=="") Event[index][PREVIOUS]="---";
      //--- Convert Event time to MT4 time
      EventTime=datetime(MakeDateTime(Event[index][DATE],Event[index][TIME]));
      //--- calculate how many minutes before the event (may be negative)
      EventMinute=int(EventTime-TimeGMT())/60;
      //--- only Alert once
      if(EventMinute==0 && AlertTime!=EventTime)
        {
         FirstAlert =false;
         SecondAlert=false;
         AlertTime=EventTime;
        }
      //--- Remove the event after x minutes
      if(EventMinute+EventDisplay<0) continue;
      //--- Set buffers
      MinuteBuffer[index]=EventMinute;
      ImpactBuffer[index]=ImpactToNumber(Event[index][IMPACT]);
      index++;
     }
//--- loop to set arrays/buffers that uses to draw objects and alert
   for(int i=0; i<index; i++)
     {
      for(int n=i; n<10; n++)
        {
         eTitle[n]    = Event[i][TITLE];
         eCountry[n]  = Event[i][COUNTRY];
         eImpact[n]   = Event[i][IMPACT];
         eForecast[n] = Event[i][FORECAST];
         ePrevious[n] = Event[i][PREVIOUS];
         eTime[n]     = datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]))-TimeGMTOffset();
         eMinutes[n]  = (int)MinuteBuffer[i];
         //--- Check if there are any events
         if(ObjectFind(eTitle[n])!=0) IsEvent=true;
        }
     }
//--- check then call draw / alert function
   if(IsEvent) DrawEvents();
   else Draw("no more events","NO MORE EVENTS",14,"Arial Black",RemarksColor,2,10,30,"Get some rest!");
//--- call info function
   if(ShowInfo) SymbolInfo();
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//--- 
   Print(INAME+": xml file is out of date");
   xmlUpdate();
//---
  }
//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  deinitClock();
//---
   for(int i=ObjectsTotal(); i>=0; i--)
     {
      string name=ObjectName(i);
      if(StringFind(name,INAME)==0) ObjectDelete(name);
     }
//--- Kill update timer only if removed 
   if(reason==1) EventKillTimer();
//---
  }
//+-------------------------------------------------------------------------------------------+
//| Download XML file from forexfactory                                                       |
//| for windows 7 and later file path would be:                                               |           
//| C:\Users\xxx\AppData\Roaming\MetaQuotes\Terminal\xxxxxxxxxxxxxxx\MQL4\Files\xmlFileName   |
//+-------------------------------------------------------------------------------------------+
void xmlDownload()
  {
//---
   ResetLastError();
   string sUrl="http://www.forexfactory.com/ff_calendar_thisweek.xml";
   string FilePath=StringConcatenate(TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\files\\",xmlFileName);
   int FileGet=URLDownloadToFileW(NULL,sUrl,FilePath,0,NULL);
   if(FileGet==0) PrintFormat(INAME+": %s file downloaded successfully!",xmlFileName);
//--- check for errors   
   else PrintFormat(INAME+": failed to download %s file, Error code = %d",xmlFileName,GetLastError());
//---
  }

//+------------------------------------------------------------------+
//| Check for update XML                                             |
//+------------------------------------------------------------------+
void xmlUpdate()
  {
//--- do not download on saturday
   if(TimeDayOfWeek(Midnight)==6) return;
   else
     {
      Print(INAME+": check for updates...");
      Print(INAME+": delete old file");
      FileDelete(xmlFileName);
      xmlDownload();
      sData=xmlRead(xmlFileName);
      xmlModifed=(datetime)FileGetInteger(xmlFileName,FILE_MODIFY_DATE,false);
      PrintFormat(INAME+": updated successfully! last modified: %s",(string)xmlModifed);
     }
//---
  }
//+------------------------------------------------------------------+
//| Draw panel and events on the chart                               |
//+------------------------------------------------------------------+
void DrawEvents()
  {
   string FontName = "Arial";
   int    FontSize = 10;
   string eToolTip = "";
//--- draw backbround / date / special note
   if(ShowPanel && ShowPanelBG)
     {
      eToolTip="Hover on the Event!";
      Draw("BG","gggg",105,"Webdings",Pbgc,Corner,x0,3,eToolTip);
      Draw("Date",DayToStr(Midnight)+", "+MonthToStr()+" "+(string)TimeDay(Midnight),FontSize+1,"Arial Black",TitleColor,Corner,x2,110,"Today");
      Draw("Title",PanelTitle,FontSize,FontName,TitleColor,Corner,x1,110,"Panel Title");
      Draw("Spreator","------",10,"Arial",RemarksColor,Corner,x2,98,eToolTip);
     }
//--- draw objects / alert functions
   for(int i=0; i<6; i++)
     {
      eToolTip=eTitle[i]+"\nCurrency: "+eCountry[i]+"\nTime left: "+(string)eMinutes[i]+" Minutes"+"\nImpact: "+eImpact[i];
      //--- impact color
      color EventColor=ImpactToColor(eImpact[i]);
      //--- previous/forecast color 
      color ForecastColor=PreviousColor;
      if(ePrevious[i]>eForecast[i]) ForecastColor=NegativeColor;
      else if(ePrevious[i]<eForecast[i]) ForecastColor=PositiveColor;
      //--- past event color
      if(eMinutes[i]<0)
         EventColor=ForecastColor=PreviousColor=RemarksColor;
      //--- panel
      if(ShowPanel)
        {
         //--- date/time / title / currency
         Draw("Event "+(string)i,
              DayToStr(eTime[i])+"  |  "+
              TimeToStr(eTime[i],TIME_MINUTES)+"  |  "+
              eCountry[i]+"  |  "+
              eTitle[i],FontSize,FontName,EventColor,Corner,x2,85-i*15,eToolTip);
         //--- forecast
         Draw("Event Forecast "+(string)i,"[ "+eForecast[i]+" ]",FontSize,FontName,ForecastColor,Corner,xf,85-i*15,
              "Forecast: "+eForecast[i]);
         //--- previous
         Draw("Event Previous "+(string)i,"[ "+ePrevious[i]+" ]",FontSize,FontName,PreviousColor,Corner,xp,85-i*15,
              "Previous: "+ePrevious[i]);
        }
      //--- vertical news
      if(ShowVerticalNews)
         DrawLine("Event Line "+(string)i,eTime[i]+(ChartTimeOffset*3600),EventColor,eToolTip);
      //--- Set alert message
      string AlertMessage=(string)eMinutes[i]+" Minutes until ["+eTitle[i]+"] Event on "+eCountry[i]+
                          "\nImpact: "+eImpact[i]+
                          "\nForecast: "+eForecast[i]+
                          "\nPrevious: "+ePrevious[i];
      //--- first alert   
      if(Alert1Minutes!=-1 && eMinutes[i]==Alert1Minutes && !FirstAlert)
        {
         setAlerts("First Alert! "+AlertMessage);
         FirstAlert=true;
        }
      //--- second alert    
      if(Alert2Minutes!=-1 && eMinutes[i]==Alert2Minutes && !SecondAlert)
        {
         setAlerts("Second Alert! "+AlertMessage);
         SecondAlert=true;
        }
      //--- break if no more data
      if(eTitle[i]==eTitle[i+1])
        {
         Draw(INAME+" no more events","NO MORE EVENTS",8,"Arial",RemarksColor,Corner,x2,65-i*15,"Get some rest!");
         break;
        }
     }
//---
  }
//+-----------------------------------------------------------------------------------------------+
//| Subroutine: to ID currency even if broker has added a prefix to the symbol, and is used to    |
//| determine the news to show, based on the users external inputs - by authors (Modified)        |
//+-----------------------------------------------------------------------------------------------+  
bool IsCurrency(string symbol)
  {
//---
   if(ReportForUSD && symbol == "USD") return(true);
   else if(ReportForGBP && symbol == "GBP") return(true);
   else if(ReportForEUR && symbol == "EUR") return(true);
   else if(ReportForCAD && symbol == "CAD") return(true);
   else if(ReportForAUD && symbol == "AUD") return(true);
   else if(ReportForCHF && symbol == "CHF") return(true);
   else if(ReportForJPY && symbol == "JPY") return(true);
   else if(ReportForNZD && symbol == "NZD") return(true);
   else if(ReportForCNY && symbol == "CNY") return(true);
   return(false);
//---
  }
//+------------------------------------------------------------------+
//| Converts ff time & date into yyyy.mm.dd hh:mm - by deVries       |
//+------------------------------------------------------------------+
string MakeDateTime(string strDate,string strTime)
  {
//---
   int n1stDash=StringFind(strDate, "-");
   int n2ndDash=StringFind(strDate, "-", n1stDash+1);

   string strMonth=StringSubstr(strDate,0,2);
   string strDay=StringSubstr(strDate,3,2);
   string strYear=StringSubstr(strDate,6,4);

   int nTimeColonPos=StringFind(strTime,":");
   string strHour=StringSubstr(strTime,0,nTimeColonPos);
   string strMinute=StringSubstr(strTime,nTimeColonPos+1,2);
   string strAM_PM=StringSubstr(strTime,StringLen(strTime)-2);

   int nHour24=StrToInteger(strHour);
   if((strAM_PM=="pm" || strAM_PM=="PM") && nHour24!=12) nHour24+=12;
   if((strAM_PM=="am" || strAM_PM=="AM") && nHour24==12) nHour24=0;
   string strHourPad="";
   if(nHour24<10) strHourPad="0";
   return(StringConcatenate(strYear, ".", strMonth, ".", strDay, " ", strHourPad, nHour24, ":", strMinute));
//---
  }
//+------------------------------------------------------------------+
//| set impact Color - by authors                                    |  
//+------------------------------------------------------------------+
color ImpactToColor(string impact)
  {
//---
   if(impact == "High") return (HighImpactColor);
   else if(impact == "Medium") return (MediumImpactColor);
   else if(impact == "Low") return (LowImpactColor);
   else if(impact == "Holiday") return (HolidayColor);
   else return (RemarksColor);
//---
  }
//+------------------------------------------------------------------+
//| Impact to number - by authors                                    |
//+------------------------------------------------------------------+
int ImpactToNumber(string impact)
  {
//---
   if(impact == "High") return(3);
   else if(impact == "Medium") return(2);
   else if(impact == "Low") return(1);
   else return(0);
//---
  }
//+------------------------------------------------------------------+
//| Convert day of the week to text                                  |
//+------------------------------------------------------------------+
string DayToStr(datetime time)
  {
   int ThisDay=TimeDayOfWeek(time);
   string day="";
   switch(ThisDay)
     {
      case 0: day="Sun"; break;
      case 1: day="Mon"; break;
      case 2: day="Tue"; break;
      case 3: day="Wed"; break;
      case 4: day="Thu"; break;
      case 5: day="Fri"; break;
      case 6: day="Sat"; break;
     }
   return(day);
  }
//+------------------------------------------------------------------+
//| Convert months to text                                           |
//+------------------------------------------------------------------+
string MonthToStr()
  {
   int ThisMonth=Month();
   string month="";
   switch(ThisMonth)
     {
      case 1: month="Jan"; break;
      case 2: month="Feb"; break;
      case 3: month="Mar"; break;
      case 4: month="Apr"; break;
      case 5: month="May"; break;
      case 6: month="Jun"; break;
      case 7: month="Jul"; break;
      case 8: month="Aug"; break;
      case 9: month="Sep"; break;
      case 10: month="Oct"; break;
      case 11: month="Nov"; break;
      case 12: month="Dec"; break;
     }
   return(month);
  }
//+------------------------------------------------------------------+
//| Candle Time Left / Spread                                        |
//+------------------------------------------------------------------+
void SymbolInfo()
  {
//---
   string TimeLeft=TimeToStr(Time[0]+Period()*60-TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
   string Spread=DoubleToStr(MarketInfo(Symbol(),MODE_SPREAD)/Factor,1);
   double DayClose=iClose(NULL,PERIOD_D1,1);
   if(DayClose!=0)
     {
      double Strength=((Bid-DayClose)/DayClose)*100;
      string Label=DoubleToStr(Strength,2)+"%"+" / "+Spread+" / "+TimeLeft;
      ENUM_BASE_CORNER corner=1;
      if(Corner==1) corner=3;
      string arrow="q";
      if(Strength>0) arrow="p";
      string tooltip="Strength / Spread / Candle Time";
      Draw(INAME+": info",Label,InfoFontSize,"Calibri",InfoColor,corner,120,20,tooltip);
      Draw(INAME+": info arrow",arrow,InfoFontSize-2,"Wingdings 3",InfoColor,corner,130,18,tooltip);
     }
//---
  }
//+------------------------------------------------------------------+
//| draw event text                                                  |
//+------------------------------------------------------------------+
void Draw(string name,string label,int size,string font,color clr,ENUM_BASE_CORNER c,int x,int y,string tooltip)
  {
//---
   name=INAME+": "+name;
   int windows=0;
   if(AllowSubwindow && WindowsTotal()>1) windows=1;
   ObjectDelete(name);
   ObjectCreate(name,OBJ_LABEL,windows,0,0);
   ObjectSetText(name,label,size,font,clr);
   ObjectSet(name,OBJPROP_CORNER,c);
   ObjectSet(name,OBJPROP_XDISTANCE,x);
   ObjectSet(name,OBJPROP_YDISTANCE,y);
//--- justify text
   ObjectSet(name,OBJPROP_ANCHOR,anchor);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
   ObjectSet(name,OBJPROP_SELECTABLE,0);
   //ObjectSet(name,OBJPROP_FONTSIZE,12);
//---
  }
//+------------------------------------------------------------------+
//| draw vertical lines                                              |
//+------------------------------------------------------------------+
void DrawLine(string name,datetime time,color clr,string tooltip)
  {
//---
   name=INAME+": "+name;
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,time,0);
   ObjectSet(name,OBJPROP_COLOR,clr);
   ObjectSet(name,OBJPROP_STYLE,2);
   ObjectSet(name,OBJPROP_WIDTH,0);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
//---
  }
//+------------------------------------------------------------------+
//| Notifications                                                    |
//+------------------------------------------------------------------+
void setAlerts(string message)
  {
//---
   if(PopupAlerts) Alert(message);
   if(SoundAlerts) PlaySound(AlertSoundFile);
   if(NotificationAlerts) SendNotification(message);
   if(EmailAlerts) SendMail(INAME,message);
//---
  }
//+--------------------------- END ----------------------------------+
