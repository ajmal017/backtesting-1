require 'bigdecimal'

class Quote

  attr_accessor :date, :open, :high, :low, :close

  def initialize(values={})
    @date = Date.strptime(values[0], '%Y-%m-%d')
    @open = BigDecimal.new(values[1])
    @high = BigDecimal.new(values[2])
    @low = BigDecimal.new(values[3])
    @close = BigDecimal.new(values[4])
  end

end
