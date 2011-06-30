require 'timetable'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.color_enabled = true
  config.mock_with :rspec
end

def sample_data(filename)
  filepath = "timetable/samples/#{filename}"
  filepath = File.join(File.dirname(__FILE__), filepath)
  File.read(filepath)
end