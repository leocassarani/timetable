require 'active_support/core_ext'

module Timetable
  class ParserDelegate
    attr_reader :events

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

        event = Event.new(data, week, @week_start, @week_range)
        event.uid = "DOC-#{@uid}"
        @uid += 1
        attempt_merge(event.to_icalendar, week, data[:day], data[:time])
      end
    end

    def parsing_ended
      @calendar.parsing_ended(@events)
    end

  private

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
      one_hour_earlier = event.start.advance(:hours => -1)
      @dups[one_hour_earlier]
    end
  end
end
