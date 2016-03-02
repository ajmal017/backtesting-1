require_relative 'position'
require_relative 'yahoo_client'
require 'yaml'
require 'active_support/all'

FILE = './test.yml'
OUTPUT_DIR = './output'

FileUtils.rm_rf(OUTPUT_DIR)
FileUtils.mkdir(OUTPUT_DIR)

raw = YAML.load(File.read(FILE)).with_indifferent_access
raw[:positions] ||= []

configuration = raw[:configuration]

positions = raw[:positions].map do |row|
  position = Position.new(configuration: configuration, data: row)
  position.calculate_results

  position
end

summary_header = "Symbol,Entry Date,Exit Date,Total Weeks,Close,SMA(20),Close Above BP (%),G/L (%),Biggest G/L (%),Stop Loss,Peak Decline (%)"
summary_strings = [ summary_header ]

positions.each do |row|

  summary_strings << row.summary_report_string

  filepath = "#{OUTPUT_DIR}/#{row.report_filename}"
  File.write(filepath, row.report_string)
end

summary_filepath = "#{OUTPUT_DIR}/summary.csv"
File.write(summary_filepath, summary_strings.join("\n"))
