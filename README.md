# Instructions

Proof of concept script to test CAN SLIM style breakouts. You can find more information about CAN SLIM at [Investors.com](http://education.investors.com/default.aspx).

## How do You Run it?

#### Install Dependencies
`bundle install`

#### Run the Script
`ruby backtesting.rb -f positions/test.yml`

#### More Options
`ruby backtesting.rb -h`

The script uses a YAML file to receive all the positions you want to test.

### Positions

The file defines an array of positions using the following format.

You can find an example in `positions/test.yml`

``` YAML
positions:
  -
    symbol: SYMBOL
    breakout_date: MM/DD/YYYY # The day the stock broke out of a sound base (Cup w/ Handle, Flat Base or Double Bottom)
    buy_date: MM/DD/YYYY # The day you bought the stock (Optional)
    buy_point: 99.99 # The Ideal Buy Point for the Base
    buy_price: 100.0 # The price you paid for the stock (Optional)
```

### Configuration

Configuration file found in `settings/configuration.yml`. The options are mostly used as parameters for the exit strategy.

``` YAML
stop_loss: 0.07 # Maximum Stop Loss (Percentage)
profit_target: 0.2 # Used to Calculate my Breakeven Threshold (Percentage)
decline_from_peak: 0.1 # Decline below the Highest High since the breakout date (Percentage)
use_market_pulse: true # Flag to display or hide IBD's Market Pulse at the beginning of the day
```

## Exit Strategy

The script will exit a position based on the following rules.

1. **Maximum Stop Loss:** The **CLOSE** for the day is below the **Maximum Stop Loss**
2. **Buy Point Stop Loss:** The **Stop Loss** is moved up to the **Buy Point** when the Highest High above the **Buy Point** is greater than or equal to the Breakeven Threshold.
3. **Breakeven Stop Loss:** The **Stop Loss** is moved up to **Breakeven** when the Highest High above the **Buy Price** is greater than or equal to the Breakeven Threshold.
4. **Decline From the Peak Rule:** Exit when the **CLOSE** for the day meets the **Decline From Peak** percentage and is below the 20-day simple moving average or **SMA(20)**. *By using the close below the SMA(20) I give the stock some room to make its move.*
5. **Market In Correction:** Exit when **IBD's Market Pulse** changes to **Market in Correction** and the position is sitting at a loss.

*Note: The Breakeven Threshold is the Profit Target Divided by 2. Example: If my Profit Target is 20%, I move my Stop Loss to Breakeven when the Highest High since the day of the Breakout is greater than or equal to 10% above my Buy Price*

## Yahoo Finance

The script uses historical data from Yahoo Finance.

### IMPORTANT NOTE

Yahoo Finance doesn't adjust historical price data for Splits and Dividends. Instead they give you an adjusted close that you can use to your own calculations. The adjusted close takes into account Splits and Dividends. My chart service provider doesn't seem to adjust historical price for dividends. I only adjust historical prices for splits by adding them manually in the positions file. Look for an example in `positions/test.yml`.

## Notes

The script is a proof of concept to test my ideas and it should NOT BE CONSIDERED INVESTMENT ADVICE.
