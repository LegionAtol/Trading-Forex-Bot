//+------------------------------------------------------------------+
//|                                                        Bot.mq4 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs

//#include  <CustomFunction.mqh>

datetime timeOfCurrentBar;

int numberOfMidLines=3;

double midHlines[10];
double upperHlines[10];
double lowerHlines[10];

bool isMidLineTested=false;
bool isLowerBand=false;
bool isMidBand=false;
bool isUpperBand=false;
bool isBotOffline=false;
bool isClosingLastOrders=false;

double riskPerTrade = 0.02;





//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

   Print("Starting Bot");

   timeOfCurrentBar=Time[0];
   initHorizzontalLine(Close[1]);

   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   //Alert("Stopping Strategy");
   
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   
   //Bot non deve operare di sabato e domenica. negli altri giorni solo dalle 7.00 alle 20.00
   if( (DayOfWeek()==0 || DayOfWeek()==6) || (Hour()<7 || Hour()>=20) ){
      //se ho ordini aperti, li faccio completare prima di spegnersi
      if(OrdersTotal()>0){
         isClosingLastOrders=true;
      }
      else{
         //BOT non deve operare
         isBotOffline=true;           //qunado il bot si risveglia dovrà resettarsi!
      }
   }
   //dentro l'else entreà sempre qunado è attivo il bot
   else{
      //entra nell'if solo una volta, (la prima) dopo che è stato inattivo (isBotOffline=true), inizializza i valori
      if(isBotOffline){
         isMidLineTested=false;
         isLowerBand=false;
         isMidBand=false;
         isUpperBand=false;
         isBotOffline=false;
         isClosingLastOrders=false;
         initHorizzontalLine(Close[1]);
         isBotOffline=false;
      }
   }
   
   
   //se NON è offline, il bot entra nell'if
   if(!isBotOffline){  
      
      //controllo i trailing stop e break even degli ordini aperti
      updateTrailingStop();
      
      //if serve per vedere: finchè non ho una nuova candela non fa nulla
      //seconda condizione if poteva essere un else-if a parte: se sta chiudedno gli ulti ordni aperti->non fare nulla
      //qunado ho una nuova candela (in costruzione) opero su quella precedente completa
      if(timeOfCurrentBar==Time[0] || isClosingLastOrders){
         //NON FARE NULLA, aspetta la prossima candela
      }
      else{       
         //ho una nuova candela!
         timeOfCurrentBar=Time[0];
         
         //controllo se è stata toccata(dalla candela conclusa) una Midline
         //il +- (2*_Point) serve solo per avere un po' di margine in piu' in caso la MidLine non fosse pienamente presa
         if(!isMidLineTested){        
            if(Low[1]-(2*_Point)<=midHlines[0] && midHlines[0]<=High[1]+(2*_Point)){
               Alert("Mid line bassa toccata");
               isMidLineTested=true;
               isLowerBand=true;
            }
            else if(Low[1]-(2*_Point)<=midHlines[1] && midHlines[1]<=High[1]+(2*_Point)){
               Alert("Mid line media toccata");
               isMidLineTested=true;
               isMidBand=true;
            }
            else if(Low[1]-(2*_Point)<=midHlines[2] && midHlines[2]<=High[1]+(2*_Point)){
               Alert("Mid line alta toccata");
               isMidLineTested=true;
               isUpperBand=true;
            }
            
         }
         //se una midLine è stata testa, controlla le altre linee superiore e inferiore
         //non è un else perchè devo controllare se ha anche rotto le line secondarie a rialzo o ribasso
         //le "linee secondarie" sono quelle sopra (upperHlines) o sotto (lowerHlines) la midline 
         if(isMidLineTested){   
                     
            if(isLowerBand){      
              if(Close[1]>upperHlines[0]+(2*_Point) && !isMultipleBuy()){     //il +2*_Point è solo per avere un po' di margine in più 
                 //BUY
                 
                 //controllo l'RSI, se è buono faccio il buy
                 if(iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)>=30 && iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)<=35){
                    //calcolo stopLoss e takeProfit
                    double takeProfitPrice=NormalizeDouble(lowerHlines[1],Digits);          //linea inferiore della "banda" superiore
                    //double stopLossPrice=NormalizeDouble(lowerHlines[0]-(3*_Point),Digits);//linea inferiore della "banda" corrente (meno 3 pips per evitare false fluttuazioni
                    double stopLossPrice=Close[0]-(60*_Point);
                    //double lotSize = OptimalLotSize(riskPerTrade,Ask,stopLossPrice);
                    Print("stopLossPrice"+stopLossPrice);
                    Print("takeProfit:"+takeProfitPrice);
                    
                    Alert("BUY banda bassa");
                    int openOrderID = OrderSend(Symbol(),OP_BUYLIMIT,0.03,Ask,8,stopLossPrice,takeProfitPrice,NULL,0,0,Red);
                    if(openOrderID<0)  Print("OrderSend fallito con errore :",GetLastError());
                 } 
                 //se no nulla            
              }
              else if(Close[1]<lowerHlines[0]-(2*_Point) && !isMultipleSell()){     //il -2*_Point è solo per avere un po di margine in più 
                 //SELL
                 
                 //controllo l'RSI, se è buono faccio il sell
                 if(iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)>=65 && iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)<=70){
                    double takeProfitPrice= NormalizeDouble(midHlines[0]-(25*_Point*10)+(25*_Point), _Digits);//calcolato a mano perchè non ho una banda inferiore
                    //double stopLossPrice= NormalizeDouble(upperHlines[0]+(3*_Point),_Digits);//linea superiore della "banda" bassa (piu 3 pips per evitare false fluttuazioni)
                    double stopLossPrice=Close[0]+(60*_Point);
                    //double lotSize = OptimalLotSize(riskPerTrade,Bid,stopLossPrice);
                    Print("stopLossPrice"+stopLossPrice);
                    Print("takeProfit:"+takeProfitPrice);
                    
                    Alert("SELL banda bassa");
                    int openOrderID = OrderSend(Symbol(),OP_SELLLIMIT,0.03,Bid,8,stopLossPrice,takeProfitPrice,NULL,0,0,Green);
                    if(openOrderID<0)  Print("OrderSend fallito con errore :",GetLastError());
                 }
                 //altrimneti nulla
              }
              
              //resetto valori e linee orizzontali in ogni caso in cui ha almeno chiuso a rialzo o ribasso
              if(Close[1]>upperHlines[0]+(2*_Point) || Close[1]<lowerHlines[0]-(2*_Point)){
                 //resetto i valori di default
                 isLowerBand=false;
                 isMidLineTested=false;
                 //ricalcolo le linee orizzontali
                 initHorizzontalLine(Close[1]);
              }
            }   
            else if(isMidBand){
              if(Close[1]>upperHlines[1]+(2*_Point) && !isMultipleBuy()){     //il +2*_Point è solo per avere un po di margine in più 
                 //BUY 
                 
                 //controllo l'RSI, se è buono faccio il buy
                 if(iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)>=30 && iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)<=35){                
                    //calcolo stopLoss e takeProfit
                    double takeProfitPrice= NormalizeDouble(lowerHlines[2],_Digits);//linea inferiore della "banda" alta
                    //double stopLossPrice=NormalizeDouble(lowerHlines[1]-(3*_Point),_Digits);//linea inferiore della "banda" mid (meno 3 pips per evitare false fluttuazioni)
                    double stopLossPrice=Close[0]-(60*_Point);
                    //double lotSize = OptimalLotSize(riskPerTrade,Ask,stopLossPrice);
                    Print("stopLossPrice"+stopLossPrice);
                    Print("takeProfit:"+takeProfitPrice);
                    
                    Alert("BUY banda media");
                    int openOrderID = OrderSend(Symbol(),OP_BUYLIMIT,0.03,Ask,8,stopLossPrice,takeProfitPrice,NULL,0,0,Red);
                    if(openOrderID<0)  Print("OrderSend fallito con errore :",GetLastError());
                 }
              }
              else if(Close[1]<lowerHlines[1]-(2*_Point) && !isMultipleSell()){     //il -2*_Point è solo per avere un po di margine in più 
                 //SELL    
                 
                 //controllo l'RSI, se è buono faccio il sell
                 if(iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)>=65 && iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)<=70){
                    double takeProfitPrice=NormalizeDouble(upperHlines[0],_Digits);//linea superiore banda bassa
                    //double stopLossPrice=NormalizeDouble(upperHlines[1]+(3*_Point),_Digits);//linea superiore della "banda" bassa (piu 3 pips per evitare false fluttuazioni)
                    double stopLossPrice=Close[0]+(60*_Point);
                    //double lotSize = OptimalLotSize(riskPerTrade,Bid,stopLossPrice);
                    Print("stopLossPrice"+stopLossPrice);
                    Print("takeProfit:"+takeProfitPrice);
                    
                    Alert("SELL banda media");
                    int openOrderID = OrderSend(Symbol(),OP_SELLLIMIT,0.03,Bid,8,stopLossPrice,takeProfitPrice,NULL,0,0,Green);
                    if(openOrderID<0)  Print("OrderSend fallito con errore :",GetLastError());
                 }
                 //altrimneti nulla
              }
              //resetto valori in ogni caso in cui ha almeno chiuso a rialzo o ribasso
              if( Close[1]>upperHlines[1]+(2*_Point) || Close[1]<lowerHlines[1]-(2*_Point) ){
                 //risetto i valori di default
                 isMidBand=false;
                 isMidLineTested=false;
                 
              }
            }
            
            else if(isUpperBand){
              if(Close[1]>upperHlines[2]+(2*_Point) && !isMultipleBuy()){     //il +2*_Point è solo per avere un po di margine in più 
                 //BUY
                 
                 //controllo l'RSI, se è buono faccio il buy
                 if(iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)>=30 && iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)<=35){
                    //calcolo stopLoss e takeProfit
                    double takeProfitPrice=NormalizeDouble(midHlines[2]+(25*_Point*10)-(25*_Point),_Digits); //calcolato a mano perchè non ho una banda superiore
                    //double stopLossPrice=NormalizeDouble(lowerHlines[2]-(3*_Point),_Digits);//linea inferiore della "banda" alta (meno 3 pips per evitare false fluttuazioni 
                    double stopLossPrice=Close[0]-(60*_Point);
                    Print("takeProfitPrice: "+takeProfitPrice);
                    Print("stopLossPrice"+stopLossPrice);                
                    //double lotSize = OptimalLotSize(riskPerTrade,Ask,stopLossPrice);
                                     
                    Alert("BUY banda alta");
                    int openOrderID = OrderSend(Symbol(),OP_BUYLIMIT,0.03,Ask,8,stopLossPrice,takeProfitPrice,NULL,0,0,Red);
                    if(openOrderID<0)  Print("OrderSend fallito con errore :",GetLastError());
                 }
                 //altrimneti nulla
              }
              else if(Close[1]<lowerHlines[2]-(2*_Point) && !isMultipleSell()){     //il -2*_Point è solo per avere un po di margine in più 
                 //SELL
                 
                 //controllo l'RSI, se è buono faccio il sell
                 if(iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)>=65 && iRSI(_Symbol,_Period,14,PRICE_CLOSE,0)<=70){
                    double takeProfitPrice=NormalizeDouble(upperHlines[1],_Digits);//linea superiore banda bassa
                    //double stopLossPrice=NormalizeDouble(upperHlines[2]+(3*_Point),_Digits);//linea superiore della "banda" alta (piu 3 pips per evitare false fluttuazioni)
                    double stopLossPrice=Close[0]+(60*_Point);
                    //double lotSize = OptimalLotSize(riskPerTrade,Bid,stopLossPrice);
                    Print("stopLossPrice"+stopLossPrice);
                    Print("takeProfit:"+takeProfitPrice);
                    
                    Alert("SELL banda alta");
                    int openOrderID = OrderSend(Symbol(),OP_SELLLIMIT,0.03,Bid,8,stopLossPrice,takeProfitPrice,NULL,0,0,Green);
                    if(openOrderID<0)  Print("OrderSend fallito con errore :",GetLastError());
                 }
                 //altrimneti nulla
              }
              //resetto valori e linee orizzontali in ogni caso in cui ha almeno chiuso a rialzo o ribasso
              if( Close[1]>upperHlines[2]+(2*_Point) || Close[1]<lowerHlines[2]-(2*_Point) ){
                 //e risetto i valori di default
                  isUpperBand=false;
                  isMidLineTested=false;
                  //ricalcolo le linee orizzontali
                  initHorizzontalLine(Close[1]);
              }
            }
            else{
               Print("nessuna linea secondaria toccata");
            }
         }
         
      }
      
   }   
      
}//END onTICK






//+----------------------------------------------------------------------------------------------------------+
//+----------------------------------------------------------------------------------------------------------+




   
void initHorizzontalLine(double a){
   //canecello tutte le linee orizzontali sul grafico
   ObjectsDeleteAll(ChartID(),-1,OBJ_HLINE);
   
   
   //Print(a);   
   double roundNumber = findNearestRoundNumber(a);
      
   
   // faccio shiftare di un round number in sotto(cosi creo meglio l'array dall'indice 0)
   roundNumber=roundNumber-0.0025;
   // e ripristino il valore del roundNumber considerando le cifre decimali della valuta corrente
   if(Digits()==2){
      roundNumber=roundNumber*1000;
   }
   else if(Digits()==3){
      roundNumber=roundNumber*100;
   }
   else if(Digits()==5){
      //roundNumber è già corretto
   }    
   //Print("roundNumber finale: "+roundNumber);
   
   //MathPow(10,Digits()-1) serve per tenere conto in costruzione delle linee orizzontali
   //che le diverse valute hanno un numero di decimali diverso
   //5 cifre decimali -> 25/MathPow(10,Digits()-1) = 0.0025
   //3 cifre decimali -> 25/MathPow(10,Digits()-1) = 0.25
   //2 cifre decimali -> 25/MathPow(10,Digits()-1) = 2.5
   
   //creo i valori delle MidLine
   for(int i=0;i<numberOfMidLines;i++){
      midHlines[i]=roundNumber+(25/MathPow(10,Digits()-1)*i);  
      ObjectCreate(ChartID(),"MidHLine"+i,OBJ_HLINE,0,0,midHlines[i]);
      ObjectSetInteger(ChartID(),"MidHLine"+i,OBJPROP_COLOR,clrBlue);
      //Print("Valore MidLine"+i+"= "+midHlines[i]);
   }
   
      
   //per upperHlines
   for(int i=0;i<numberOfMidLines;i++){
      upperHlines[i]=midHlines[i]+(2.5/MathPow(10,Digits()-1));   
      ObjectCreate(ChartID(),"UpperHLine"+i,OBJ_HLINE,0,0,upperHlines[i]);
      ObjectSetInteger(ChartID(),"UpperHLine"+i,OBJPROP_COLOR,clrGreen);
      //Print("Valore UpperLine"+i+"= "+upperHlines[i]);
   } 
   
      
   //per le lowerHlines
   for(int i=0;i<numberOfMidLines;i++){
      lowerHlines[i]=midHlines[i]-(2.5/MathPow(10,Digits()-1));   
      ObjectCreate(ChartID(),"LowerHLine"+i,OBJ_HLINE,0,0,lowerHlines[i]);
      ObjectSetInteger(ChartID(),"LowerHLine"+i,OBJPROP_COLOR,clrRed);
      //Print("Valore LowerHLine"+i+"= "+lowerHlines[i]);
   }  
   
}



double findNearestRoundNumber(double a){           //se do 1.13427 il nearest round number-> 1.13500  
   
   //Print("valore di a: "+a);
   if(Digits()==2){
      //mi riconduco al caso delle 4 cifre decimali
      a=a/1000;
   }
   else if(Digits()==3){
      //mi riconduco al caso delle 4 cifre decimali
      a=a/100;
   }
   else if(Digits()==5){
      //questo è già il caso giusto
   }
   //Print("a ricalcolato: "+a);
   
   double roundNumber = ((long) (a * 100) / 100.);         //tengo solo le prime due cifre decimali.Questa var alla fine conterrà il round number
   //Print("Round number iniziale: "+roundNumber);           //per es. 1.13427 -> 1.13
   
   double temp = a*100;   
   double val = ((long) (temp * 1000) / 1000.); //tengo le 3 cifre decimali
   //Print("scomposizione : "+val);
   //avrò val-> 113.427
   
   //prendo parte intera (es: 113)
   int intPart= ((int) val); 
   //Print("int part:"+intPart);
   
   //prendo la parte decimale (es: 427)
   double decimalPart= val-intPart;
   decimalPart=((long) (decimalPart * 1000) / 1000.);//tengo le 3 cifre decimali
   decimalPart=decimalPart*1000;
   int decimalPartInt = ((int) decimalPart);
   //Print("decimal part Int"+decimalPartInt);
   
   //ora calcolo la differenza in modulo per vedere il round number piu vicino
   int minDifference=1000;
   
   //0->000 1->250(25 pips) 2->500(50 pips) 3->750(75 pips) 4->1000(per andare a quello successivo es1.12947 voglio 1.13000)
   
   //sono tutti if perchè deve controllarli tutti
   int b=0;
   if(MathAbs(decimalPartInt-0)<minDifference){
      minDifference=MathAbs(decimalPartInt-0);
      b=0;
   }
   if(MathAbs(decimalPartInt-250)<minDifference){
      minDifference=MathAbs(decimalPartInt-250);
      b=1;
   }
   if(MathAbs(decimalPartInt-500)<minDifference){
      minDifference=MathAbs(decimalPartInt-500);
      b=2;
   }
   if(MathAbs(decimalPartInt-750)<minDifference){
      minDifference=MathAbs(decimalPartInt-750);
      b=3;
   }
   //per andare a quello successivo es1.12947 voglio 1.13000
   if(decimalPartInt>=875){
      b=4;
   }
 
   switch(b){
      case 0:
         roundNumber=roundNumber+0.00000;
         break;
      case 1:
         roundNumber=roundNumber+0.00250;
         break;
      case 2:
         roundNumber=roundNumber+0.00500;
         break;
      case 3:
         roundNumber=roundNumber+0.00750;
         break;   
      case 4:
         roundNumber=roundNumber+0.01;
   }
   
   //ora è esattamente il roundNumber più vicino PERO' considerando che ha 5 cifre decimali come nell'esempio sotto
   //i numeri tondi sono del tipo: 1.13000 1.13250 1.13500 1.13750 1.14000
   //Print("roundNumber (a 5 decimali !!!): "+roundNumber);
   return roundNumber;      
   
}


//funzione che controlla prima di fare un BUY se ci sono stati altri BUY vicini(se si, non lo fa)
bool isMultipleBuy(){
   if(OrdersTotal()>0){
      for(int a=OrdersTotal()-1;a>=0;a--){
         //OerderType()-> 0=OP_BUY 1=OP_SELL 2=OP_BUYLIMIT 3=OP_SELLLIMIT
         if(OrderSelect(a,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol()&& OrderType()==0){
            //se ha trovato un buy, controllo che sia distante (temporalemnte)
            //se è avvenuto entro 45 min(162000 sec) non posso farne un altro ora (+10 sec. per avere del margine)
            if( TimeCurrent()-OrderOpenTime()<=(162000+10) ){
               return true;
            }
            else{
               return false;
            }
         }
      }     
   }
   return false;     
}


//funzione che controlla prima di fare un SELL se ci sono stati altri BSELL vicini(se si non lo fa)
bool isMultipleSell(){
   if(OrdersTotal()>0){
      for(int a=OrdersTotal()-1;a>=0;a--){
         //OerderType()->  0=OP_BUY 1=OP_SELL 2=OP_BUYLIMIT 3=OP_SELLLIMIT
         if(OrderSelect(a,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderType()==1){
            //se ha trovato un sell, controllo che sia distante (temporalemnte)
            //se è avvenuto entro 45 min(162000 sec) non posso farne un altro ora (+10 sec. per avere del margine)
            if( TimeCurrent()-OrderOpenTime()<=(162000+10) ){
               return true;
            }
            else{
               return false;
            }
         }
      }     
   }
   return false;     
}



//BreakEven e trailing stop 
void updateTrailingStop(){
      //Dynamic BreakEven e trailing stop 
      for(int a=OrdersTotal();a>=0;a--){
         if(OrderSelect(a,SELECT_BY_POS,MODE_TRADES)){
         
            double orderStopLoss=OrderStopLoss();
            double orderOpenPrice=OrderOpenPrice();
            bool isStopLossChanged=false; 
            
            //per i BUY
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
               //se il prezzo è oltre i 30 punti dall'apertura        
               if( Close[0] >= OrderOpenPrice()+40*_Point ){
                  // e se stoploss è sotto per più di 20 punti dal prezzo attuale
                  //non bisogna mettere <= altimenti qunado vale = si ha errore (fa la modifica senza che stoploss sia cambiato)
                  if( orderStopLoss < Close[0]-30*_Point ){
                     orderStopLoss=Close[0]-30*_Point;
                     isStopLossChanged=true;
                  }
               }
               /*
               //per attivare break even (qunado prezzo è sopra di 30 punti)(seconda condizione è solo per farlo entrare la prima volta)
               else if( (Close[0]-30*_Point) >= orderOpenPrice && (orderStopLoss < orderOpenPrice) ){
                  Print("sono nel break even");
                  orderStopLoss=orderOpenPrice+(3*_Point);
                  isStopLossChanged=true;
               }
               */
               else{
                  isStopLossChanged=false;
               }
            
               //solo se serve faccio modifica allo stoploss
               if(isStopLossChanged) {
                     OrderModify(
                        OrderTicket(),       //per l'ordine corrente
                        OrderOpenPrice(),    //stesso prezzo di apertura
                        orderStopLoss,        //SET STOPLOSS
                        OrderTakeProfit(),   // lascio invariato il take profit
                        0,                   //no exipration 
                        CLR_NONE
                     );
               }
               
            }//end BUY
            
            //Per i SELL
            else if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
            //se il prezzo è oltre i 30 punti dall'apertura        
               if( Close[0] <= OrderOpenPrice()-40*_Point ){
                  //e se stoploss è sopra per più di 20 punti dal prezzo attuale
                  //non bisogna mettere >= altimenti qunado vale = si ha errore (fa la modifica senza che stoploss sia cambiato)
                  if( orderStopLoss > Close[0]+30*_Point ){
                     orderStopLoss=Close[0]+30*_Point;
                     isStopLossChanged=true;
                  }
                  else{isStopLossChanged=false;}
               }
               /*
               //per attivare break even (seconda condizione è solo per farlo entrare la prima volta)
               else if( (Close[0]+30*_Point) <= orderOpenPrice && (orderStopLoss > orderOpenPrice) ){
                  Print("sono nel break even");
                  orderStopLoss=orderOpenPrice-3*_Point;
                  isStopLossChanged=true;
               }
               */
               else{
                  isStopLossChanged=false;
               }
                  
               //solo se serve faccio modifica allo stoploss
               if(isStopLossChanged) {
                     OrderModify(
                        OrderTicket(),       //per l'ordine corrente
                        OrderOpenPrice(),    //stesso prezzo di apertura
                        orderStopLoss,        //SET STOPLOSS
                        OrderTakeProfit(),   // lascio invariato il take profit
                        0,                   //no exipration 
                        CLR_NONE
                     );
               }
            }//fine sell  
         }
      }
}


void checkRSI(){

}








double OptimalLotSize(double maxRiskPrc, double entryPrice, double stopLoss){
   int maxLossInPips = MathAbs(entryPrice - stopLoss)/GetPipValue();
   return OptimalLotSize(maxRiskPrc,maxLossInPips);
}




double OptimalLotSize(double maxRiskPrc, int maxLossInPips){
  double accEquity = AccountEquity();
  Print("accEquity: " + accEquity);

  double lotSize = MarketInfo(NULL,MODE_LOTSIZE);
  Print("lotSize: " + lotSize);
 

  double tickValue = MarketInfo(NULL,MODE_TICKVALUE);

  if(Digits <= 3)
  {
   tickValue = tickValue /100;
  }

  Print("tickValue: " + tickValue);
  double maxLossDollar = accEquity * maxRiskPrc;
  Print("maxLossDollar: " + maxLossDollar);
  double maxLossInQuoteCurr = maxLossDollar / tickValue;
  Print("maxLossInQuoteCurr: " + maxLossInQuoteCurr); 

  double optimalLotSize = NormalizeDouble(maxLossInQuoteCurr /(maxLossInPips * GetPipValue())/lotSize,2);

  return optimalLotSize; 

}


double GetPipValue(){
   if(_Digits >=4)
   {
      return 0.0001;
   }
   else
   {
      return 0.01;
   }
}