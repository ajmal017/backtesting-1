require_relative 'position'
require_relative 'configuration'
require_relative 'yahoo_client'
require 'yaml'
require 'active_support/all'

POSITIONS_FILE = './test.yml'
OUTPUT_DIR = './output'

FileUtils.rm_rf(OUTPUT_DIR)
FileUtils.mkdir(OUTPUT_DIR)

configuration = Configuration.values

raw = YAML.load(File.read(POSITIONS_FILE)).with_indifferent_access
raw[:positions] ||= []

positions = raw[:positions].map do |row|
  position = Position.new(configuration: configuration, data: row)
  position.calculate_results

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
