require 'timetable'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.color_enabled = true
  config.mock_with :rspec
end