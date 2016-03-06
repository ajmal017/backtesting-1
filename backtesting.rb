require_relative 'position'
require_relative 'configuration'
require_relative 'yahoo_client'
require 'yaml'
require 'active_support/all'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: backtesting.rb [options]"

  opts.on('-f', '--filename FILENAME', 'Filename') { |v| options[:filename] = v }
  opts.on('-o', '--output_dir OUTPUT_DIR', 'Output directory') { |v| options[:output_dir] = v }
end.parse!

unless options[:filename]
  $stderr.puts "Error: you must specify the --filename option."
  exit 1
end

POSITIONS_FILE = options[:filename]
OUTPUT_DIR = options[:output_dir] || './output'

FileUtils.rm_rf(OUTPUT_DIR)
FileUtils.mkdir(OUTPUT_DIR)

configuration = Configuration.values

raw = YAML.load(File.read(POSITIONS_FILE)).with_indifferent_access
raw[:positions] ||= []

positions = raw[:positions].map do |row|
  position = Position.new(configuration: configuration, data: row)
  position.calculate_results

  puts "symbol: #{position.symbol}, Entry Date: #{position.formatted_buy_date} Exit Date: #{position.results.last.formatted_date}, G/L (%): #{(position.results.last.gain_loss_percent * 100).round(2)}"

  position
end

summary_strings = [ Position.summary_report_header ]

positions.each do |row|

  summary_strings << row.summary_report_string

  filepath = "#{OUTPUT_DIR}/#{row.report_filename}"
  File.write(filepath, row.report_string)
end

summary_filepath = "#{OUTPUT_DIR}/summary.csv"
File.write(summary_filepath, summary_strings.join("\n"))
