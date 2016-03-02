require 'yaml'
require 'active_support/all'

MARKET_PULSE_FILE = './settings/market_pulse.yml'

class MarketPulse

  def self.market_pulse_for_date(date=nil)
    values = MarketPulse.values

    values.each_with_index do |v, index|
      pulse_date = Date.strptime(v[:date], '%m/%d/%Y')

      prev = index - 1
      if pulse_date > date && prev >= 0
        return MarketPulse.formatted_pulse_for_code(values[prev][:pulse])
      end
    end
  end

  def self.values
    YAML.load(File.read(MARKET_PULSE_FILE)).with_indifferent_access[:market_pulse]
  end

  def self.formatted_pulse_for_code(code=nil)
    case code
    when 'U'
      return 'Confirmed Uptrend'
    when 'P'
      return 'Uptrend Under Pressure'
    when 'C'
      return 'Market In Correction'
    else
      return nil
    end
  end

end
