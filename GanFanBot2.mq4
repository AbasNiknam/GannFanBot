//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input int intervalInput = 4;           // Interval in hours

input double StopOrderDistance = 5;    // Distance to Place Buy/Sell Stop Order
input double StopLoss = 100;           // Distance to Place Stop Loss
input double TP = 200;                 // Distance to Place TP
double LotsBuy;                        // Lots
double LotsSell;                       // Lots
input double Lots1 = 0.01;             // Lots1
input double Lots2 = 0.02;             // Lots2
input double Lots3 = 0.03;             // Lots3
input double Lots4 = 0.04;             // Lots4
input double DistanceToCheck = 135;    // Distance to Check and Send New Order

datetime nyCloseTime;
double nyClosePrice;
double highPrice;
double lowPrice;
datetime highTime;
datetime lowTime;
bool nyCloseInitialized = false;
bool gannFanDrawn = false;
datetime lastResetTime = 0; // To track the last reset time

// My Parameters:
int barsTotal;


int lineNumber;                  //lineNumber 
bool findLineNumber = false;     //search for find Line Number
double tickSize;                 //tickSize
bool firstRunBuy = true;
bool firstRunSell = true;
string orderType;                // order Type

input int MaxNumOfBuy = 4;       // Max allowed Num of Buy Position
input int MaxNumOfSell = 4;      // Max allowed Num of Sell Position
 
input bool OnTickMode = false;   // OnTick or OnBar?

input bool CloseAtEnd = true;    // Close Positions at End of Day

int numOfBuyPosition;            // Num of Buy Position
int numOfSellPosition;           // Num of Sell Position

int numOfBuyOrder;               // Num of Buy Order
int numOfSellOrder;              // Num of Sell Order

double lastBuyEntry;             // last Buy Entry
double lastSellEntry;            // last Sell Entry

//double oldClose;
//double newClose;

double newBid = 0.0;             // Define to run Bot on tick instead of newClose
double oldBid = 0.0;             // Define to run Bot on tick instead of oldClose

double linePrice[32,2];          // Save current and last all line price



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   barsTotal = iBars(_Symbol,PERIOD_M1);
   
   ArrayInitialize(linePrice,0);
   tickSize = MarketInfo(_Symbol,MODE_TICKSIZE);
   Print(tickSize);
   ResetForNewDay();
   
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   int bars = iBars(_Symbol,PERIOD_M1);

   if(!OnTickMode)
   {
      if (barsTotal != bars)
      { 
         barsTotal = bars;
         oldBid = iClose(_Symbol,PERIOD_M1,2);
         newBid = iClose(_Symbol,PERIOD_M1,1);
      } 
   }
   else if (OnTickMode)
   {
      if(Bid != oldBid)
      {
         newBid = Bid;
      }
   }



   
   numOfBuyPosition  = GetNumofBuyPosition();
   numOfSellPosition = GetNumofSellPosition();
   
   numOfBuyOrder  = GetNumofBuyOrder();
   numOfSellOrder = GetNumofSellOrder();
   
   Print("-----------------------------------------------------------");   
   Print("-----------------------------------------------------------");   
   Print("# Buy Position",numOfBuyPosition, " # Buy Order",numOfBuyOrder);
   Print("# Sell Position",numOfSellPosition, " # SellOrder",numOfSellOrder);
      
   if( (numOfSellPosition == 0) && ((numOfSellOrder == 0)) )
   {
      firstRunSell = true;
   }
   
   if( (numOfBuyPosition == 0) && ((numOfBuyOrder == 0)) )
   {
      firstRunBuy = true;
   }
  
   ReadLinesData();
   
   
   if(!findLineNumber) 
   {
      FindLineNumber();
   }
   
   
   if(numOfSellPosition<MaxNumOfSell)
   {
      Print("Search For Sell Signal...");
      SearchForSell();
   }
   else if (numOfSellPosition>=MaxNumOfSell)
   {
      Print("Reach Max # of Sell Position.");
   } 
   
   if(numOfBuyPosition<MaxNumOfBuy)
   {
      Print("Search For Buy Signal...");
      SearchForBuy();
   }
   else if (numOfBuyPosition>=MaxNumOfBuy)
   {
      Print("Reach Max # of Buy Position.");
   } 
   
   if (OnTickMode)
   {
      oldBid = newBid;
   }
   

   
   datetime currentTime = TimeCurrent();
   
      
   // Check if a new day has started
   if (TimeDay(lastResetTime) != TimeDay(currentTime))
   {
      if(CloseAtEnd)
      {
         CloseAllOrders();
      }
      
      findLineNumber = false;     
      firstRunBuy = true;
      firstRunSell = true;

      
      ResetForNewDay();
   }

   if (!nyCloseInitialized || gannFanDrawn) return;

   UpdateHighLow();

   if ( currentTime >= nyCloseTime + intervalInput * 3600)
   {
      DrawGannFan(nyCloseTime, nyClosePrice, highTime, highPrice, lowTime, lowPrice);
      gannFanDrawn = true; // Set the flag to true after drawing the Gann Fan
      
      Print("*******  DrawGannFan  *********");

      
   }

}



//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void SearchForSell()
{
   orderType = "Sell";
   if(lineNumber>=0 && lineNumber<17 && findLineNumber)
   {
     
      if( (newBid>linePrice[lineNumber,0]) && (oldBid<linePrice[lineNumber,1]) )
      {
         if(CheckDistance(orderType) || firstRunSell)
         {
            if(CheckAnyPendingOrder())
            {
               DeletePendingOrder(orderType);
            }
            sendSellStop();
         }
      }
      findLineNumber = false;
   }
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   for (int i = OrdersTotal()-1; i>=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS)) //&& OrderSymbol()==_Symbol ) //&& OrderMagicNumber()==MagicNum
      {
         if (OrderType() == OP_BUY)
         {
            int OrderClsBuy = OrderClose(OrderTicket(),OrderLots(),MarketInfo (OrderSymbol(), MODE_BID), 1000, clrBlack);
            Print("Order #",OrderTicket()," was closed @ end of day.");
         } 
         else if (OrderType() == OP_SELL)
         {
            int OrderClsSell = OrderClose(OrderTicket(),OrderLots(),MarketInfo (OrderSymbol(), MODE_ASK), 1000, clrBlack);
            Print("Order #",OrderTicket()," was closed @ end of day.");
         }
      }         
   }
   Print("All Order Closed!");
}
         

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void SearchForBuy()
{
   orderType = "Buy";
   if(lineNumber>16 && lineNumber<32 && findLineNumber)
   {
      if( (newBid<linePrice[lineNumber-1,0]) && (oldBid>linePrice[lineNumber-1,1]))
      {
         Print("Buy Line #",lineNumber-1,"is Crossed.");
         if(CheckDistance(orderType) || firstRunBuy)
         {
            Print("First Run or Reach Distance.");
            if(CheckAnyPendingOrder())
            {
               Print("Delete Not Deal Order.");
               DeletePendingOrder(orderType);
            }
            Print("Send BuyStop Order.");
            sendBuyStop();
         }
      }
      findLineNumber = false;
   }
}




//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
int GetNumofBuyPosition()
{
   int countBuy = 0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderType()==OP_BUY)
         {
            countBuy ++;
            lastBuyEntry = OrderOpenPrice();
         }
      }
   }
   return countBuy;
}

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
int GetNumofBuyOrder()
{
   int countBuy = 0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderType()==OP_BUYSTOP)
         {
            countBuy ++;
         }
      }
   }
   return countBuy;
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
int GetNumofSellPosition()
{
   int countSell = 0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderType()==OP_SELL)
         {
            countSell ++;
            lastSellEntry = OrderOpenPrice();
         }
      }
   }
   return countSell;

}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
int GetNumofSellOrder()
{
   int countSell = 0;
   for(int i=0;i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderType()==OP_SELLSTOP)
         {
            countSell ++;
         }
      }
   }
   return countSell;

}

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void ReadLinesData()
{
   for(int i = 0; i<32; i++)
   {
      string objectName = "GannFan" + IntegerToString(i);
      //Print(objectName);
      linePrice[i,0] = ObjectGetValueByTime(0,objectName,TimeCurrent(),0);
      linePrice[i,1] = ObjectGetValueByTime(0,objectName,TimeCurrent()-60,0);
   }
}



//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void FindLineNumber()
{
   //Print("newClose: ", newClose);
   for(int i =0;i<32;i++)
   {
      //Print("linePrice[i,0]: ", linePrice[i,0]);

      if(newBid>linePrice[i,0] && linePrice[i,0]>0)
      {
         lineNumber = i;
         findLineNumber = true;
         i=32;
      }
   }
   //Print("*************************************");
   //Print("Bar: ",barsTotal);
   //Print("Line Number: ",lineNumber);
}

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void ResetForNewDay()
{
   // Initialize variables at the New York close time
   nyCloseTime = GetNYCloseTime();
   nyClosePrice = GetNYClosePrice(nyCloseTime);
   nyCloseInitialized = true;
   highPrice = nyClosePrice;
   lowPrice = nyClosePrice;
   highTime = nyCloseTime;
   lowTime = nyCloseTime;
   gannFanDrawn = false; // Reset the drawn flag
   lastResetTime = TimeCurrent(); // Update the last reset time

   Print(nyCloseTime);
   // Clear previous Gann Fan lines
   for (int i = 1; i <= 32; i++) // Clear up to 32 lines
   {
      ObjectDelete("GannFan" + IntegerToString(i));
   }
}



//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
bool CheckAnyPendingOrder()
{
   for(int i=OrdersTotal()-1; i >=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderType()==OP_BUYSTOP)
         {
            return true;
         }
         else if(OrderType()==OP_SELLSTOP)
         {
            return true;
         }
         return false;
      }
   }
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
int sendBuyStop()
{
   
   double entry = Ask + StopOrderDistance*tickSize;
   entry = NormalizeDouble(entry,_Digits);
   
   double sl = entry - StopLoss*tickSize;
   sl = NormalizeDouble(sl,_Digits);
   
   double tp = entry + TP*tickSize;
   tp = NormalizeDouble(tp,_Digits);
   
   CalculateLots();
   
   firstRunBuy = false;
   lastBuyEntry = entry;
   return OrderSend(_Symbol,OP_BUYSTOP,LotsBuy,entry,100000,sl,tp,"Buy Stop Order",0,0,clrBlue);
}



//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
int sendSellStop()
{
   double entry = Bid - StopOrderDistance*tickSize;
   entry = NormalizeDouble(entry,_Digits);
   
    
   double sl = entry + StopLoss*tickSize;
   sl = NormalizeDouble(sl,_Digits);
   
   double tp = entry - TP*tickSize;
   tp = NormalizeDouble(tp,_Digits);
   
   CalculateLots();
   
   firstRunSell = false;
   lastSellEntry = entry;
   
   return OrderSend(_Symbol,OP_SELLSTOP,LotsSell,entry,100000,sl,tp,"Sell Stop Order",0,0,clrRed);
}

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void CalculateLots()
{
   if(numOfBuyPosition <1)
   {
      LotsBuy = Lots1;
   }
   else if (numOfBuyPosition == 1)
   {
      LotsBuy = Lots2;
   }
   else if (numOfBuyPosition == 2)
   {
      LotsBuy = Lots3;
   }
   else if (numOfBuyPosition == 3)
   {
      LotsBuy = Lots4;
   }
   
   if(numOfSellPosition <1)
   {
      LotsSell = Lots1;
   }
   else if (numOfSellPosition == 1)
   {
      LotsSell = Lots2;
   }
   else if (numOfSellPosition == 2)
   {
      LotsSell = Lots3;
   }
   else if (numOfSellPosition == 3)
   {
      LotsSell = Lots4;
   }

}
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
bool CheckDistance(string type)
{
   
   double bid = Bid;
   double ask = Ask;
   
   if(type == "Sell")
   {
      double distanceSell = bid - lastSellEntry;
      distanceSell = NormalizeDouble(distanceSell,_Digits);
      
      if(distanceSell>DistanceToCheck*tickSize)
      {
         return true;
      }
   }
   else if(type == "Buy")
   {
      double distanceBuy = lastBuyEntry-ask;
      distanceBuy = NormalizeDouble(distanceBuy,_Digits);
      
      if(distanceBuy>DistanceToCheck*tickSize)
      {
         return true;
      }
   }
   return false;
}















//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void DeletePendingOrder(string type)
{
   for(int i=OrdersTotal()-1; i >=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(type == "Sell" && OrderType() == OP_SELLSTOP)
         {
            int orderTicketSell = OrderTicket();
            OrderDelete(orderTicketSell,clrGreen);
            Print("Sell Stop Order Deleted");
         }
         else if(type == "Buy" && OrderType() == OP_BUYSTOP)
         {
            int orderTicketBuy = OrderTicket();
            OrderDelete(orderTicketBuy,clrGreen);
            Print("Buy Stop Order Deleted");
         }
      }
   }
}






//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
datetime GetNYCloseTime()
{
   datetime currentDay = iTime(_Symbol, PERIOD_D1, 0);
   return currentDay + 0 * 3600; // 12 AM (midnight)
   Print(currentDay);
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
double GetNYClosePrice(datetime closeTime)
{
   return iClose(_Symbol, PERIOD_H1, iBarShift(_Symbol, PERIOD_H1, closeTime));
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void UpdateHighLow()
{
   // Update high and low prices based on the current Bid price
   if (Bid > highPrice)
   {
      highPrice = Bid;
      highTime = TimeCurrent();
   }
   if (Bid < lowPrice)
   {
      lowPrice = Bid;
      lowTime = TimeCurrent();
   }
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
void DrawGannFan(datetime startTime, double startPrice, datetime highTime, double highPrice, datetime lowTime, double lowPrice)
{
   // Drawing Gann Fan lines using the correct prices and time intervals
   
   
   // New high angle line (6/1 angle)
   ObjectCreate(0, "GannFan0", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 6 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan0", OBJPROP_COLOR, clrMediumBlue);
   
   ObjectCreate(0, "GannFan1", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 5 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan1", OBJPROP_COLOR, clrSteelBlue);
  
   ObjectCreate(0, "GannFan2", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 4 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan2", OBJPROP_COLOR, clrRoyalBlue);

  
   // New high angle lines above the blue line
   ObjectCreate(0, "GannFan3", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 3 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan3", OBJPROP_COLOR, clrDodgerBlue);

   ObjectCreate(0, "GannFan4", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 2 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan4", OBJPROP_COLOR, clrCyan);

   ObjectCreate(0, "GannFan5", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 1.5 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan5", OBJPROP_COLOR, clrDarkBlue);

   // High Price Lines
   ObjectCreate(0, "GannFan6", OBJ_TREND, 0, startTime, startPrice, highTime, highPrice);
   ObjectSetInteger(0, "GannFan6", OBJPROP_COLOR, clrBlue);
   
   ObjectCreate(0, "GannFan7", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + 0.75 * (highPrice - startPrice));
   ObjectSetInteger(0, "GannFan7", OBJPROP_COLOR, clrDarkRed);

   // Additional high angle lines
   ObjectCreate(0, "GannFan8", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 2);
   ObjectSetInteger(0, "GannFan8", OBJPROP_COLOR, clrPurple);

   ObjectCreate(0, "GannFan9", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 3);
   ObjectSetInteger(0, "GannFan9", OBJPROP_COLOR, clrGreen);

   ObjectCreate(0, "GannFan10", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 4);
   ObjectSetInteger(0, "GannFan10", OBJPROP_COLOR, clrYellow);

   ObjectCreate(0, "GannFan11", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 5);
   ObjectSetInteger(0, "GannFan11", OBJPROP_COLOR, clrAqua);

   ObjectCreate(0, "GannFan12", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 6);
   ObjectSetInteger(0, "GannFan12", OBJPROP_COLOR, clrPink);

   ObjectCreate(0, "GannFan13", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 7);
   ObjectSetInteger(0, "GannFan13", OBJPROP_COLOR, clrBrown);

   ObjectCreate(0, "GannFan14", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 8);
   ObjectSetInteger(0, "GannFan14", OBJPROP_COLOR, clrRed);

   ObjectCreate(0, "GannFan15", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 12);
   ObjectSetInteger(0, "GannFan15", OBJPROP_COLOR, clrOrange);

   ObjectCreate(0, "GannFan16", OBJ_TREND, 0, startTime, startPrice, highTime, startPrice + (highPrice - startPrice) / 16);
   ObjectSetInteger(0, "GannFan16", OBJPROP_COLOR, clrMagenta);

   
   // Low Price Lines
 
   ObjectCreate(0, "GannFan17", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 16);
   ObjectSetInteger(0, "GannFan17", OBJPROP_COLOR, clrMagenta);
   
   ObjectCreate(0, "GannFan18", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 12);
   ObjectSetInteger(0, "GannFan18", OBJPROP_COLOR, clrOrange);
   
   ObjectCreate(0, "GannFan19", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 8);
   ObjectSetInteger(0, "GannFan19", OBJPROP_COLOR, clrRed);
   
   ObjectCreate(0, "GannFan20", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 7);
   ObjectSetInteger(0, "GannFan20", OBJPROP_COLOR, clrBrown);
   
   ObjectCreate(0, "GannFan21", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 6);
   ObjectSetInteger(0, "GannFan21", OBJPROP_COLOR, clrPink);
   
   ObjectCreate(0, "GannFan22", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 5);
   ObjectSetInteger(0, "GannFan22", OBJPROP_COLOR, clrAqua);
   
   ObjectCreate(0, "GannFan23", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 4);
   ObjectSetInteger(0, "GannFan23", OBJPROP_COLOR, clrYellow);
   
   ObjectCreate(0, "GannFan24", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 3);
   ObjectSetInteger(0, "GannFan24", OBJPROP_COLOR, clrGreen);
   
   ObjectCreate(0, "GannFan25", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) / 2);
   ObjectSetInteger(0, "GannFan25", OBJPROP_COLOR, clrCyan);
   
   // Additional low angle lines
   ObjectCreate(0, "GannFan26", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + 0.75 * (lowPrice - startPrice));
   ObjectSetInteger(0, "GannFan26", OBJPROP_COLOR, clrCyan);

   ObjectCreate(0, "GannFan27", OBJ_TREND, 0, startTime, startPrice, lowTime, lowPrice);
   ObjectSetInteger(0, "GannFan27", OBJPROP_COLOR, clrBlue);

   // New low angle line (midway between blue and gold, which is 1/2 angle)
   ObjectCreate(0, "GannFan28", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) * 1.5);
   ObjectSetInteger(0, "GannFan28", OBJPROP_COLOR, clrSilver);

   // New low angle line (1/3 angle)
   ObjectCreate(0, "GannFan29", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) * 3);
   ObjectSetInteger(0, "GannFan29", OBJPROP_COLOR, clrGold);

   // Additional low angle line (1/4 angle below gold line)
   ObjectCreate(0, "GannFan30", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) * 4);
   ObjectSetInteger(0, "GannFan30", OBJPROP_COLOR, clrDarkGoldenrod);

   // New low angle line (1/5 angle below the previous line)
   ObjectCreate(0, "GannFan31", OBJ_TREND, 0, startTime, startPrice, lowTime, startPrice + (lowPrice - startPrice) * 5);
   ObjectSetInteger(0, "GannFan31", OBJPROP_COLOR, clrDarkOliveGreen);
}