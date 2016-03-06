require 'yaml'
require 'active_support/all'
require 'optparse'
require 'csv'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: backtesting.rb [options]"

  opts.on('-f', '--filename FILENAME', 'Filename') { |v| options[:filename] = v }
  opts.on('-o', '--output_file OUTPUT_FILE', 'Output filename') { |v| options[:output_file] = v }
end.parse!

unless options[:filename]
  $stderr.puts "Error: you must specify the --filename option."
  exit 1
end

POSITIONS_FILE = options[:filename]
OUTPUT_FILE = options[:output_file]

raw_array = CSV.parse(File.read(POSITIONS_FILE), headers: false).to_a
raw_array.shift

positions = []
raw_array.map do |row|
  position = {}

  position["symbol"] = row[0] if row[0].present?
  position["breakout_date"] = row[1] if row[1].present?
  position["buy_point"] = row[2].to_f if row[2].present?
  position["buy_date"] = row[3] if row[3].present?
  position["buy_price"] = row[4].to_f if row[4].present?

  positions << position
end

yaml_string = { "positions" => positions }.to_yaml
if OUTPUT_FILE.present?
  File.write(OUTPUT_FILE, yaml_string)
else
  puts yaml_string
end
