require 'yaml'
require 'active_support/all'

CONFIGURATION_FILE = './settings/configuration.yml'

class Configuration

  def self.values
    YAML.load(File.read(CONFIGURATION_FILE)).with_indifferent_access
  end

end
