require 'active_support/all'
require 'bigdecimal'
require_relative 'yahoo_client'
require_relative 'position_result'
require_relative 'stock_split'
require_relative 'quote'

BUY_ZONE_THRESHOLD = 0.05

class Position

  attr_accessor :symbol
  attr_accessor :buy_point, :buy_price
  attr_accessor :breakout_date, :buy_date
  attr_accessor :profit_target_percent, :stop_loss_percent, :decline_from_peak_percent
  attr_accessor :quotes
  attr_accessor :stock_splits
  attr_accessor :results
  attr_accessor :ignore_exit

  def initialize(options={})
    configuration = options[:configuration]
    data = options[:data]
    splits = data[:splits] || []
    @ignore_exit = configuration[:ignore_exit]

    @symbol = data[:symbol]
    @buy_point = data[:buy_point].to_d
    @buy_price = @ignore_exit ? @buy_point : (data[:buy_price] || 0).to_d
    @breakout_date = Date.strptime(data[:breakout_date], '%m/%d/%Y')
    @buy_date = Date.strptime(data[:buy_date] || data[:breakout_date], '%m/%d/%Y')
    @profit_target_percent = configuration[:profit_target].to_d
    @stop_loss_percent = configuration[:stop_loss].to_d
    @decline_from_peak_percent = configuration[:decline_from_peak].to_d

    @stock_splits = splits.map { |row| StockSplit.new(row) }

    @results = []
  end

  def calculate_results
    start_date = @breakout_date - 40
    end_date = Date.today
    all_quotes = YahooClient.fetch_quotes(symbol: @symbol, start_date: start_date, end_date: end_date)
    quotes = filtered_quotes(all_quotes)

    # quotes.each { |q| puts "symbol: #{symbol}, date: #{q.date}, close: #{q.close}, high: #{q.high}"}

    quotes.each_with_index do |q, index|
      next if index < 19

      range_start = 19
      start = index - 19

      highs = quotes[range_start..index].map { |row| row.high.round(2).to_f }
      lows = quotes[range_start..index].map { |row| row.low.round(2).to_f }

      highest_high = highs.max
      lowest_low = lows.min
      sma20 = quotes[start..index].map { |row| row.close }.sum / 20

      result = PositionResult.new(position: self, quote: q)
      result.highest_high = highest_high
      result.lowest_low = lowest_low
      result.sma20 = sma20

      @results << result

      break if !ignore_exit && result.exit?
    end
  end

  def filtered_quotes(quotes=[])
    breakout_index = 0

    @stock_splits.each_with_index do |s, index|
      quotes.each do |q|
        if q.date < s.date
          q.open = q.open / s.factor
          q.high = q.high / s.factor
          q.low = q.low / s.factor
          q.close = q.close / s.factor
        end
      end
    end

    quotes.each_with_index do |q, index|
      if q.date == breakout_date
        breakout_index = index

        if @buy_price == 0.to_d
          if q.open > buy_zone || q.open > buy_point
            @buy_price = q.open
          else
            @buy_price = @buy_point
          end
        end

        break
      end
    end

    start_index = 0
    if breakout_index >= 20
      start_index = breakout_index - 19
    end

    quotes.slice(start_index, quotes.count - 1)
  end

  def buy_zone
    buy_point * (1.to_d + BUY_ZONE_THRESHOLD.to_d)
  end

  def formatted_breakout_date
    return breakout_date.strftime('%m/%d/%Y')
  end

  def formatted_buy_date
    return buy_date.strftime('%m/%d/%Y')
  end

  def biggest_loss_percent
    lowest_low = results.last.lowest_low_below_buy_price
    first_low = results.first.lowest_low_below_buy_price

    return results.first.gain_loss_percent if results.count == 1
    return results.first.gain_loss_percent if first_low <= lowest_low

    lowest_low
  end

  def file_date_string
    @breakout_date.strftime('%m-%d-%Y')
  end

  def report_filename
    "#{@symbol} #{file_date_string}.csv"
  end

  def summary_report_string
    configuration = Configuration.values
    use_market_pulse = configuration[:use_market_pulse] || false
    last = results.last

    summary = []
    summary << symbol
    summary << formatted_breakout_date
    summary << MarketPulse.market_pulse_for_date_string(breakout_date) if use_market_pulse
    summary << last.formatted_date
    summary << MarketPulse.market_pulse_for_date_string(last.quote.date) if use_market_pulse
    summary << "#{last.week_number}"
    summary << "#{last.buy_price.round(2)}"
    summary << "#{last.quote.close.round(2)}"
    summary << "#{last.sma20.round(2)}"
    summary << "#{(last.gain_loss_percent * 100).round(2)}"
    summary << "#{(last.high_above_buy_price_percent * 100).round(2)}"
    summary << "#{(biggest_loss_percent * 100).round(2)}"
    summary << "#{last.stop_loss.round(2)}"
    summary << last.stop_loss_string
    summary << "#{(last.current_decline_from_peak * 100).round(2)}"

    summary.join(",")
  end

  def report_string
    header = self.class.report_header
    strings = [ header ]
    strings << results.select{ |r| r.quote.date >= @buy_date }.map(&:report_string).flatten
    strings.join("\n")
  end

  def self.report_header
    header = "Week Num,Date,Buy Price,Open,High,Low,Close,SMA(20),Close Above BP (%),G/L (%),Biggest G/L (%),Stop Loss,Stop Loss Type,Peak Decline (%)"

    configuration = Configuration.values
    if configuration[:use_market_pulse] || false
      header << ',Market Pulse'
    end

    header
  end

  def self.summary_report_header
    configuration = Configuration.values
    use_market_pulse = configuration[:use_market_pulse] || false

    header = []
    header << "Symbol"
    header << "Entry Date"
    header << "Entry Date Market Pulse" if use_market_pulse
    header << "Exit Date"
    header << "Exit Date Market Pulse" if use_market_pulse
    header << "Total Weeks"
    header << "Entry Price"
    header << "Exit Price"
    header << "SMA(20)"
    header << "G/L (%)"
    header << "Max Gain (%)"
    header << "Max Loss (%)"
    header << "Stop Loss"
    header << "Stop Loss Type"
    header << "Peak Decline (%)"

    header.join(",")
  end

end
