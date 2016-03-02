require 'httparty'
require 'csv'
require_relative 'quote'

class YahooClient

  HISTORICAL_MODES = {
    :daily => "d",
    :weekly => "w",
    :monthly => "m",
    :dividends => "v"
  }

  def self.read_historical(symbol, start_date, end_date, period)
    url = "http://ichart.finance.yahoo.com/table.csv?s=#{URI.escape(symbol)}&d=#{end_date.month-1}&e=#{end_date.day}&f=#{end_date.year}&g=#{HISTORICAL_MODES[period]}&a=#{start_date.month-1}&b=#{start_date.day}&c=#{start_date.year}&ignore=.csv"

    begin
      response = HTTParty.get(url)
      body = response.body if response.code == 200
    rescue
      body = nil
    end
    body
  end

  def self.fetch_quotes(options={})
    symbol = options[:symbol]
    start_date = options[:start_date]
    end_date = options[:end_date]

    string = read_historical(symbol, start_date, end_date, 'daily')

    raw_array = CSV.parse(string, headers: false).to_a
    raw_array.shift

    raw_array.map do |row|
      quote = Quote.new(row)
    end.reverse
  end

end
