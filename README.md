# Trading-Forex-Bot
Automated forex trading bot MQL4

![Immagine](https://github.com/LegionAtol/Trading-Forex-Bot/assets/118752873/28f9834b-3bb5-4238-a065-acd9eb4c732f)

The figure above represents the BOT that is operating in backtest on MetaTrader4 platform.
The three “bands” are visible, each containing three lines (lowerHline, midHLine, upperHline)

Operation of the BOT:


-OnTick() function - called periodically by the system

The BOT operates only during the days from Monday to Friday and at certain times.
Before stopping the BOT checks if there are open orders to conclude them.
What this essentially does is dynamically build three equally spaced bands based on the current price position. Each band contains a center line, a top line and a bottom line.
These bands are constructed based on the “round” value closest to the current value of the candle.
The idea of the strategy is to observe if and when the Midlines are touched (taking into account a little margin) and then observe if there is an upward or downward break of the upperHline or lowerHline of the same band, the RSI indicator is also checked and a Buy or Sell order is sent by setting the takeProfit and a stopLoss.
The stopLoss is updated periodically (becomes dynamic) i.e. a trailingStop.
Furthermore, it is checked not to open multiple Buy or Sell orders in close proximity.
