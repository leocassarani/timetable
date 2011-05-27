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
  class Parser
    attr_accessor :input
    attr_reader :calendar

    EVENT_TYPES = {
      "LEC" => "Lecture",
      "LAB" => "Lab",
      "TUT" => "Tutorial",
      "Wks" => ''
    }

    # Unique event ID, shared by all Parser objects
    @@uid = 1

    def initialize(input = nil)
      @input = input
    end

    # The optional parameter is a default output calendar,
    # see the discussion of #parse_cells for details
    def parse(cal = nil)
      return cal if input.nil?

      reset_state
      find_week_range
      find_week_start
      find_cells
      parse_cells(cal)
      @calendar
    end

  private

    def reset_state
      @doc = nil
      @events = nil
    end

    # Retrieves the range of week numbers that the calendar comprises
    def find_week_range
      @doc ||= Hpricot(input)
      tag = @doc.search("body/h3[2]/font")
      return if tag.empty?
      text = tag.inner_html

      # Matches both "(Week 1)" and "(Weeks 2 - 11)"
      range = text.scan(/\(Week[s]? (\d{1,2})[\s-]*(\d{1,2})?\)/)
      range_start, range_end = range.flatten

      range_start = range_start.to_i
      # The range terminates at range_end, if it exists, or range_start
      # itself, if the calendar only describes a single week of term
      range_end = range_end.nil? ? range_start : range_end.to_i

      @week_range = range_start..range_end
    end

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

      # Retrieve the number of the week the calendar starts on
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
      @cells.map!(&:inner_html)
    end

    # Iterates over the array of table cells and puts together an
    # Icalendar::Calendar object with all the events it can find.
    #
    # Takes as an optional argument an Icalendar::Calendar object
    # to be used as the output calendar, useful in order to merge
    # the new events with previously created ones
    def parse_cells(cal = nil)
      @calendar = cal || Icalendar::Calendar.new
      day = time = 0

      @cells.each do |cell|
        # Reset day and time if it's a horizontal heading (e.g. "0900")
        if cell =~ /^(\d{2})00$/
          day = 0
          time = $1.to_i
          next
        end

        # Move on if the cell is empty or just a newline
        unless cell.empty? || cell == "<br />"
          lines = cell.split("<br />").delete_if { |s| s.empty? }
          # Each event is made up of two lines, so we take them both
          lines.each_slice(2) do |event|
            parse_event(event, day, time)
          end
        end

        day += 1
      end
    end

    def parse_event(event, day, time)
      # Grab the title from event[0], metadata from event[1]
      title, extra = event
      title.gsub!("&amp;", "&")
      info, attendees, location = extra.split(" / ")

      type, weeks = parse_info(info)
      attendees = parse_attendees(attendees)
      location = parse_location(location)

      # Create an event for each element in the weeks range
      weeks.each do |week|
        week = week.to_i
        next unless @week_range.include?(week)

        # Set the event start date by adding the appropriate
        # number of days and hours to @week_start
        start_date = @week_start.advance(
          :weeks => week - @week_no,
          :days => day,
          :hours => time
        )

        event = Icalendar::Event.new
        event.uid = "DOC-#{@@uid}"
        @@uid += 1
        event.tzid = "Europe/London"
        event.start = start_date
        # For now assume every event ends after an hour
        event.end = event.start.advance(:hours => 1)

        summary = title
        summary += " (#{type})" unless type.empty?
        event.summary = summary
        event.description = attendees
        event.location = location

        merged = false
        # Retrieve the events in the previous timeslot
        previous = previous_events(event)
        previous.each do |prev|
          if prev.summary == event.summary
            # If the two events are the same (e.g. 2-hour lecture),
            # merge them into a single event spanning multiple hours.
            prev.end = event.end
            # Register the previous event instead
            register_event(event.start, prev)
            # We have found an event to merge with
            merged = true
            # Garbage-collect the event we no longer need
            event = nil
            break
          end
        end

        # If we couldn't find a previous event to merge with,
        # add the event to the calendar the normal way
        unless merged
          @calendar.add_event(event)
          register_event(event.start, event)
        end
      end
    end

    def parse_info(info)
      # Match strings like "LEC (2-6)"
      if info =~ /(\w+) \((\d{1,2})-(\d{1,2})\)/
        type = EVENT_TYPES[$1] or ''
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
        prefix = String.pluralize(location.count, "Room") + ' '
      else
        # Otherwise, add "Room" in front of the numeric room names
        # and keep the non-numeric ones unaltered
        location.map! { |loc| loc.integer? ? "Room #{loc}" : loc }
      end
      (prefix or '') + location.join(', ')
    end

    # Adds event to the hash table that associates a timeslot with
    # the events occurring during it
    def register_event(datetime, event)
      # Don't need any safety checks as the hash will
      # return an empty array if no match is found
      @events[datetime] << event
    end

    # Finds all events occurring 1 hour before the given event
    def previous_events(event)
      # Initialise the hash to use an empty array as default value
      @events ||= Hash.new { |h, k| h[k] = [] }
      an_hour_earlier = event.start.advance(:hours => -1)
      @events[an_hour_earlier]
    end
  end
end
