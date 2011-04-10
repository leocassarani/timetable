require 'hpricot'
require 'icalendar'

# Lessons start at 9am
MORNINGSTART = 9

class DateTime
  # Creates a copy that's a given number of hours in the future
  def advance_hours(hours)
    DateTime.civil(year, month, day, hour + hours + min, sec)
  end
end

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
      
      find_week_start
      find_cells
      parse_cells
    end

    # Retrieves the string that indicates when the week that the
    # table represents begins, and saves it as a DateTime object
    def find_week_start
      @doc ||= Hpricot(input)
      start_text = @doc.at("body/font").inner_html
      # Retrieve text of the form "Monday 11 October, 2010"
      start_text = start_text.scan(/\w+ \d{1,2} \w+, \d{4}$/).first
      # Parse the resulting text into a DateTime object
      @week_start = DateTime.strptime(start_text, "%a %d %b, %Y")
      @week_start = @week_start.advance_hours(MORNINGSTART)
    end
    
    # Retrieves an array of the textual contents of the table cells
    def find_cells
      @doc ||= Hpricot(input)
      @cells = @doc.search("table/tbody/tr/td/font")
      @cells.map! { |node| node.inner_html }
    end
    
    def parse_cells
      @calendar = Calendar.new
      
      day = 0
      time = 0
      @cells.each do |cell|
        # Reset day/time counts if this is the horizontal heading ("0900")
        if cell =~ /^(\d{2})00$/
          day = 0
          time = $1.to_i
          next
        end
        
        # Only deal with the cell if it's not empty or just a newline
        if cell !~ /^(<br \/>)?$/
          # Parse the cell contents...
        end
        
        day += 1
      end
    end
  end
end