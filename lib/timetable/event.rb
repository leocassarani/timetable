require 'icalendar'

module Timetable
  class Event
    EVENT_TYPES = {
      "LEC" => "Lecture",
      "LAB" => "Lab",
      "TUT" => "Tutorial",
      "Wks" => ''
    }

    EVENT_TYPE_PATTERNS = EVENT_TYPES.merge("TUT" => "Tutor")

    DAY_START = 9
    DAY_END = 18

    attr_reader :data, :event

    def initialize(data, week, week_start, week_range)
      @data, @week_start, @week_range = data, week_start, week_range

      @event = Icalendar::Event.new

      event.tzid = "Europe/London"
      event.start = event_start_date(data[:day], data[:time], week)
      event.end = event_end_date

      event.summary = format_summary(data[:name], data[:type])
      event.description = format_attendees(data[:attendees])
      event.location = format_location(data[:locations])
    end

    def uid=(uid)
      event.uid = uid
    end

    def to_icalendar
      event
    end

  private

    def event_start_date(day, time, week)
      start_date = @week_start.advance(
        :weeks => week - @week_range.begin,
        :days => day,
        :hours => time
      )
      if all_day?
        start_date.change(:hour => DAY_START)
      else
        start_date
      end
    end

    def event_end_date
      if all_day?
        event.start.change(:hour => DAY_END)
      else
        # Events span 1-hour timeslots by default but may get merged later
        event.start.advance(:hours => 1)
      end
    end

    def all_day?
      data[:name] =~ /\ball day\b/i
    end

    def format_summary(name, type)
      summary = name
      event_type = event_type(summary, type)
      event_type ? summary + " (#{event_type})" : summary
    end

    def event_type(summary, type)
      pattern = EVENT_TYPE_PATTERNS[type]
      # Only append the event type if it's not contained in the summary
      # already - e.g. "Laboratory I", not "Laboratory I (Lab)"
      unless summary =~ /#{pattern}/i
        EVENT_TYPES[type]
      end
    end

    def format_attendees(attendees)
      attendees.join(', ')
    end

    def format_location(locations)
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
