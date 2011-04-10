require 'hpricot'
require 'icalendar'

class DateTime
  # Creates a copy that's a given number of hours in the future
  def advance_hours(hours)
    DateTime.civil(year, month, day, hour + hours + min, sec)
  end
end

module Timetable
  EVENT_TYPES = {
    "LEC" => "Lecture",
    "LAB" => "Lab",
    "TUT" => "Tutorial",
    "Wks" => ''
  }

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
      @calendar
    end

    private

    # Retrieves the string that indicates when the week that the
    # table represents begins, and saves it as a DateTime object
    def find_week_start
      @doc ||= Hpricot(input)
      # Retrieve the first occurrence of a stand-alone <font> tag,
      # which happens to be the week start date. Return if nil,
      # which would normally indicate bad input, e.g. empty string.
      tag = @doc.at("body/font")
      return if tag.nil?

      start_text = tag.inner_html
      # Retrieve text of the form "Monday 11 October, 2010"
      start_text = start_text.scan(/\w+ \d{1,2} \w+, \d{4}$/).first
      # Parse the resulting text into a DateTime object
      @week_start = DateTime.strptime(start_text, "%a %d %b, %Y")
    end
    
    # Retrieves an array of the textual contents of the table cells
    def find_cells
      @doc ||= Hpricot(input)
      @cells = @doc.search("table/tbody/tr/td/font")
      @cells.map! { |node| node.inner_html }
    end
    
    # Iterates over the array of table cells and puts together an
    # Icalendar::Calendar object with all the events it can find
    def parse_cells
      @calendar = Calendar.new
      day = time = 0
      
      @cells.each do |cell|
        # Reset day and time if it's a horizontal heading (e.g. "0900")
        if cell =~ /^(\d{2})00$/
          day = 0
          time = $1.to_i
          next
        end
        
        # Only deal with the cell if it's not empty or just a newline
        unless cell.empty? or cell == "<br />"
          lines = cell.split("<br />").delete_if { |s| s.empty? }
          # Each event is made up of two lines, so we take them both
          lines.each_slice(2) do |event|
            title, extra = event
            info, attendees, location = extra.split(" / ")
            puts info
            type, weeks = parse_info(info)
          end
        end
        
        day += 1
      end
    end

    def parse_info(info)
      if info =~ /(\w+) \((\d{1,2})-(\d{1,2})\)/
        type = EVENT_TYPES[$1]
        weeks = $2..$3
        [type, weeks]
      end
    end
  end
end