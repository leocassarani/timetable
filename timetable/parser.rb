require 'active_support/core_ext'
require 'hpricot'
require 'icalendar'

class String
  # True if the string is an integer unsigned number, e.g.
  # "123" is true, but "-123", "+123" and "bacon" are not
  def integer?
    match(/\A\d+\Z/)
  end

  # Returns either the singular or the plural of a given
  # word, depending on the value of count
  def self.pluralize(count, singular, plural = nil)
    plural ||= "#{singular.strip}s"
    count == 1 ? singular : plural
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

      # Retrieve the number of the first week the calendar spans
      @week_no = start_text.scan(/Week (\d+) start date/)
      @week_no = @week_no.flatten.first.to_i

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
        unless cell.empty? || cell == "<br />"
          lines = cell.split("<br />").delete_if { |s| s.empty? }
          # Each event is made up of two lines, so we take them both
          lines.each_slice(2) do |event|
            # event[0] is the title, event[1] is event metadata
            title, extra = event
            info, attendees, location = extra.split(" / ")

            type, weeks = parse_info(info)
            attendees = parse_attendees(attendees)
            location = parse_location(location)

            weeks.each do |week|
              event = Event.new

              offset = (week.to_i - @week_no) * 7
              event.start = @week_start.advance(:days => offset + day, :hours => time)
              event.end = event.start.advance(:hours => 1)

              event.summary = title + (type.empty? ? '' : " (#{type})")
              event.description = attendees
              event.location = location
              @calendar.add_event(event)
            end
          end
        end
        
        day += 1
      end
    end

    def parse_info(info)
      # Match strings like "LEC (2-6)"
      if info =~ /(\w+) \((\d{1,2})-(\d{1,2})\)/
        type = EVENT_TYPES[$1]
        weeks = $2..$3
        [type, weeks]
      end
    end

    def parse_attendees(attendees)
      return '' if attendees.nil? || attendees.empty?
      # Match strings like "ajf (2-6)"
      attendees = attendees.scan(/([\w-']+) \([-0-9]{3,5}\)/)
      attendees.flatten.join(', ')
    end

    def parse_location(location)
      return '' if location.nil? || location.empty?
      location = location.split(',')

      # If all the room names are numeric, then we append "Room(s)"
      # to the beginning of the list
      if location.all? { |loc| loc.integer? }
        locstring = String.pluralize(location.count, "Room") + ' '
      else
        # Otherwise, add "Room" in front of the numeric room names
        # and keep the non-numeric ones unaltered
        location.map! { |loc| loc.integer? ? "Room #{loc}" : loc }
      end
      (locstring || '') + location.join(', ')
    end
  end
end
