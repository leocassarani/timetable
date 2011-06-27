require 'yaml'

module Timetable
  class Config
    def self.path
      File.join(File.dirname(File.dirname(__FILE__)), "config")
    end

    def self.read(key)
      @@config ||= load_config
      @@config[key]
    end

    def self.load_config
      # Load all YAML files in our path into a hash, then return it
      Dir[File.join(path, "*.yml")].inject({}) do |hash, file|
        hash.merge(YAML.load_file(file))
      end
    end
  end
end