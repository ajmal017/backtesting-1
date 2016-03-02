require 'bigdecimal'

class StockSplit

  attr_accessor :top, :bottom, :date

  def initialize(options={})
    @top = (options[:top] || 1).to_d
    @bottom = (options[:bottom] || 1).to_d
    @date = Date.strptime(options[:date], '%m/%d/%Y')
  end

  def factor
    top / bottom
  end

end
