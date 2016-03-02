require 'active_support/all'
require 'bigdecimal'
require_relative 'yahoo_client'
require_relative 'position_result'
require_relative 'quote'

BUY_ZONE_THRESHOLD = 0.05

class Position

  attr_accessor :symbol
  attr_accessor :buy_point, :buy_price
  attr_accessor :breakout_date
  attr_accessor :profit_target_percent, :stop_loss_percent, :decline_from_peak_percent
  attr_accessor :quotes
  attr_accessor :results

  def initialize(options={})
    configuration = options[:configuration]
    data = options[:data]

    @symbol = data[:symbol]
    @buy_point = data[:buy_point].to_d
    @buy_price = @buy_point
    @breakout_date = Date.strptime(data[:breakout_date], '%m/%d/%Y')
    @profit_target_percent = configuration[:profit_target].to_d
    @stop_loss_percent = configuration[:stop_loss].to_d
    @decline_from_peak_percent = configuration[:decline_from_peak].to_d
    @results = []
  end

  def calculate_results
    start_date = @breakout_date - 40
    end_date = Date.today
    all_quotes = YahooClient.fetch_quotes(symbol: @symbol, start_date: start_date, end_date: end_date)
    quotes = filtered_quotes(all_quotes)

    quotes.each_with_index do |q, index|
      next if index < 19

      start = index - 19

      highs = quotes[start..index].map { |row| row.high.round(2).to_f }
      highest_high = highs.max
      sma20 = quotes[start..index].map { |row| row.close }.sum / 20

      result = PositionResult.new(position: self, quote: q)
      result.highest_high = highest_high
      result.sma20 = sma20

      @results << result

      break if result.exit?
    end
  end

  def filtered_quotes(quotes=[])
    breakout_index = 0
    quotes.each_with_index do |q, index|
      if q.date == breakout_date
        breakout_index = index

        if q.open > buy_zone
          last = q.high - ((q.high - q.low) / 2.to_d)
          @buy_price = Random.new.rand(q.open.to_f..last.to_f).to_d
        else
          start = q.open > buy_point ? q.open : buy_point
          @buy_price = Random.new.rand(start.to_f..q.high.to_f).to_d
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

  def file_date_string
    @breakout_date.strftime('%m-%d-%Y')
  end

  def report_filename
    "#{@symbol} #{file_date_string}.csv"
  end

  def summary_report_string
    "#{symbol},#{breakout_date},#{results.last.summary_report_string}"
  end

  def report_string
    header = "Week Num,Date,Open,High,Low,Close,Buy Price,Highest High,SMA(20),Close Above BP (%),G/L (%),Biggest G/L (%),Stop Loss,Peak Decline (%)"
    strings = [ header ]
    strings << results.map(&:report_string).flatten
    strings.join("\n")
  end

end
