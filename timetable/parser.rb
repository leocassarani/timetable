require 'icalendar'

module Timetable
  class Parser
    include Icalendar
    attr_accessor :input
    attr_reader :calendar
    
    def initialize(input = nil)
      @input = input
    end
    
    def parse
      return if input.nil?
      
      @calendar = Calendar.new
    end
  end
end