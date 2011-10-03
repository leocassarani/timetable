require 'timetable'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.color_enabled = true
  config.mock_with :rspec
end

def load_fixture(filename)
  path = "timetable/fixtures/#{filename}"
  path = File.join(File.dirname(__FILE__), path)
  File.read(path)
end