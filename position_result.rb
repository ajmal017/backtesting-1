require 'bigdecimal'
require_relative 'quote'
require_relative 'market_pulse'
require_relative 'position'

class PositionResult

  attr_accessor :buy_point, :buy_price
  attr_accessor :breakout_date, :buy_date
  attr_accessor :profit_target_percent, :stop_loss_percent, :decline_from_peak_percent
  attr_accessor :highest_high, :sma20
  attr_accessor :quote

  def initialize(options={})
    position = options[:position]

    @buy_point = position.buy_point
    @buy_price = position.buy_price
    @breakout_date = position.breakout_date
    @buy_date = position.buy_date
    @profit_target_percent = position.profit_target_percent
    @stop_loss_percent = position.stop_loss_percent
    @decline_from_peak_percent = position.decline_from_peak_percent
    @quote = options[:quote]
    @highest_high = 0.to_d
    @sma20 = 0.to_d
  end

  def high_above_buy_point_percent
    return buy_point if buy_point == 0.to_d

    (highest_high - buy_point) / buy_point
  end

  def high_above_buy_price_percent
    return buy_price if buy_price == 0.to_d

    (highest_high - buy_price) / buy_price
  end

  def close_above_buy_point_percent
    return buy_point if buy_point == 0.to_d

    (quote.close - buy_point) / buy_point
  end

  def gain_loss_percent
    return buy_price if buy_price == 0.to_d

    (quote.close - buy_price) / buy_price
  end

  def breakeven_threshold
    profit_target_percent / 2.to_d
  end

  def buy_point_stop?
    high_above_buy_point_percent >= breakeven_threshold
  end

  def breakeven_stop?
    high_above_buy_price_percent >= breakeven_threshold
  end

  def max_stop_loss
    return buy_price if buy_price == 0.to_d

    buy_price * (1.to_d - stop_loss_percent)
  end

  def stop_loss
    return buy_point * (1.to_d - stop_loss_percent) if buy_price == 0.to_d
    return buy_price if breakeven_stop?

    buy_point_stop? ? buy_point : max_stop_loss
  end

  def current_decline_from_peak
    return highest_high if highest_high == 0.to_d

    (quote.close - highest_high) / highest_high
  end

  def negative_decline_from_peak_percent
    decline_from_peak_percent * -1.to_d
  end

  def meets_decline_from_peak?
    if buy_price == 0.to_d || high_above_buy_price_percent < decline_from_peak_percent
      return false
    end

    current_decline_from_peak <= negative_decline_from_peak_percent && quote.close < sma20
  end

  def meets_stop_loss?
    return false if buy_price == 0.to_d
    return false if quote.close == 0.to_d

    quote.close <= stop_loss
  end

  def meets_market_correction?
    return false if buy_price == 0.to_d
    return false if quote.close == 0.to_d

    market_pulse == :correction && gain_loss_percent <= 0.to_d
  end

  def exit?
    meets_stop_loss? || meets_decline_from_peak? || meets_market_correction?
  end

  def week_number
    ((quote.date - buy_date).to_f / 7.0).round(0) + 1
  end

  def formatted_date
    return quote.date.strftime('%m/%d/%Y')
  end

  def stop_loss_type
    return :breakeven if breakeven_stop?
    return :buy_point if buy_point_stop?

    :max_stop_loss
  end

  def stop_loss_string
    {
      breakeven: "Breakeven",
      buy_point: "Buy Point",
      max_stop_loss: "Maximum"
    }[stop_loss_type]
  end

  def summary_report_string
    string = "#{formatted_date},#{week_number},#{buy_price.round(2)},#{quote.close.round(2)},#{sma20.round(2)},#{(gain_loss_percent * 100).round(2)},#{(high_above_buy_price_percent * 100).round(2)},#{stop_loss.round(2)},#{stop_loss_string},#{(current_decline_from_peak * 100).round(2)}"

    configuration = Configuration.values
    if configuration[:use_market_pulse] || false
      string << ",#{market_pulse_string}"
    end

    string
  end

  def report_string
    string = "#{week_number},#{formatted_date},#{buy_price.round(2)},#{quote.open.round(2)},#{quote.high.round(2)},#{quote.low.round(2)},#{quote.close.round(2)},#{sma20.round(2)},#{(close_above_buy_point_percent * 100).round(2)},#{(gain_loss_percent * 100).round(2)},#{high_above_buy_price_percent.round(4) * 100},#{stop_loss.round(2)},#{stop_loss_string},#{(current_decline_from_peak * 100).round(2)}"

    configuration = Configuration.values
    if configuration[:use_market_pulse] || false
      string << ",#{market_pulse_string}"
    end

    string
  end

  def market_pulse
    configuration = Configuration.values
    return nil unless configuration[:use_market_pulse].present? && configuration[:use_market_pulse]
    MarketPulse.market_pulse_for_date(quote.date)
  end

  def market_pulse_string
    configuration = Configuration.values
    return nil unless configuration[:use_market_pulse].present? && configuration[:use_market_pulse]
    MarketPulse.market_pulse_for_date_string(quote.date)
  end

end
