require 'active_support/core_ext'
require 'icalendar'

module Timetable
  class ParserDelegate
    attr_reader :events
    alias :all :events

    EVENT_TYPES = {
      "LEC" => "Lecture",
      "LAB" => "Lab",
      "TUT" => "Tutorial",
      "Wks" => ''
    }

    def initialize(calendar)
      @calendar = calendar
      @events = []
      @uid = 1
    end

    def process_week_range(range)
      @week_range = range
    end

    def process_week_start(date)
      @week_start = date
    end

    def process_event(data)
      # Create an event for each element in the weeks range
      data[:weeks].each do |week|
        week = week.to_i
        next unless @week_range.include?(week)

        start_date = @week_start.advance(
          :weeks => week - @week_range.begin,
          :days => data[:day],
          :hours => data[:time]
        )

        event = Icalendar::Event.new
        event.uid = "DOC-#{@uid}"
        @uid += 1

        event.tzid = "Europe/London"
        event.start = start_date
        # For now assume every event ends after an hour
        event.end = event.start.advance(:hours => 1)

        event.summary = format_summary(data)
        event.description = format_attendees(data)
        event.location = format_location(data)

        attempt_merge(event, week, data[:day], data[:time])
      end
    end

    def parsing_ended
      @calendar.parsing_ended(@events)
    end

  private

    def format_summary(data)
      summary = data[:name]
      type = EVENT_TYPES[data[:type]] or ''
      # Only add the non-empty event type if it's not contained in the
      # summary already - e.g. "Laboratory I", not "Laboratory I (Lab)"
      summary += " (#{type})" unless type.empty? || summary.include?(type)
      summary
    end

    def format_attendees(data)
      data[:attendees].join(', ')
    end

    def format_location(data)
      locations = data[:locations]
      return "" if locations.nil? || locations.empty?

      # If all the room names are numeric, then append "Room(s)"
      # to the beginning of the list
      if locations.all?(&:integer?)
        prefix = String.pluralize(locations.count, "Room") + ' '
      else
        # Otherwise, add "Room" in front of the numeric room names
        # and keep the non-numeric ones unaltered
        locations.map! { |loc| loc.integer? ? "Room #{loc}" : loc }
      end

      (prefix or '') + locations.join(', ')
    end

    # Attempts to merge an event with the previously occurring one,
    # as in the case of a 2+ hour lecture
    def attempt_merge(event, week, day, time)
      merged = false

      # Retrieve the events in the previous timeslot
      previous = previous_events(event)

      previous.each do |prev|
        if prev.summary == event.summary
          # If the two events have the same summary merge them
          # into a single event spanning multiple hours
          prev.end = event.end
          register_event(event.start, prev)
          merged = true
          break
        end
      end

      # If we couldn't find a previous event to merge with,
      # add the event to the calendar the normal way
      unless merged
        @events << event
        register_event(event.start, event)
      end
    end

    # Adds event to the hash table that associates a timeslot with
    # the events occurring during it
    def register_event(datetime, event)
      @dups[datetime] << event
    end

    # Finds all events occurring 1 hour before the given event
    def previous_events(event)
      # Initialise the hash to use an empty array as default value
      @dups ||= Hash.new { |h, k| h[k] = [] }
      an_hour_earlier = event.start.advance(:hours => -1)
      @dups[an_hour_earlier]
    end
  end
end

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
