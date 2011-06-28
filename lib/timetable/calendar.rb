require 'icalendar'

module Timetable
  class Calendar
    include TimeHelper

    attr_reader :cal

    # Create the calendar object for a single course ID.
    #
    # @param [String] course The name of the user's course.
    # @param [String, Integer] yoe The user's year of entry.
    # @param [Array] ignored An array of strings, each of which corresponds
    #   to the code of a module the user isn't taking (e.g. "210").
    def initialize(course, yoe, ignored = [])
      validate_args(course, yoe)

      @course = course
      @yoe = yoe.to_i
      @ignored = ignored_names(ignored)

      @course_year = course_year(yoe)
      @course_id = course_id

      process_all unless load_cached
    end

    # Convert the output calendar to iCalendar format.
    #
    # @return [Icalendar::Calendar] The calendar in iCalendar format.
    def to_ical
      @cal.to_ical if @cal
    end

    # Callback method for the {Events} class.
    def parsing_ended(events)
      @events = events
    end

  private

    # Check that the parameters provided by the user are valid,
    # i.e. the course name exists and the year of entry is within range
    def validate_args(course, yoe_text)
      unless Config.read("courses").has_key?(course)
        raise ArgumentError, %Q{Invalid course name "#{course}"}
      end

      yoe = yoe_text.to_i
      unless valid_years.include?(yoe)
        raise ArgumentError, %Q{Invalid year of entry "#{yoe_text}"}
      end
    end

    # Downloads and parses all the necessary files, then saves it all
    # to cache and applies preset options
    def process_all
      @events = []

      # Download and parse each of the files for all the seasons
      # and week ranges we need to process
      Config.read("seasons").each do |season|
        Config.read("week_ranges").each do |weeks|
          data = download(season, weeks)
          parse(data)
        end
      end

      # Do nothing if saving to cache was not possible
      Cache.save(@course_id, @events) rescue nil

      init_calendar
      add_to_calendar(@events)
    end

    def parse(data)
      @parser ||= Parser.new(Events.new(self))
      @parser.parse(data)
    end

    def download(season, weeks)
      downloader = Downloader.new(@course_id, season, weeks)
      downloader.download
    end

    # Attempts to load the cached copy of the parsed timetable files
    def load_cached
      begin
        if Cache.has?(@course_id)
          events = Cache.get(@course_id)
          init_calendar
          add_to_calendar(events)
          return true
        end
      rescue
        return false
      end
    end

    # Initialises an empty calendar
    def init_calendar
      @cal = Icalendar::Calendar.new
      @cal.prodid = "DoC Timetable"
      set_calendar_name
      set_calendar_timezones
    end

    # Sets the default name for the output calendar
    def set_calendar_name
      calname = course_name
      calname += " Year #{@course_year}" unless masters_course?
      @cal.custom_property("X-WR-CALNAME", calname)
    end

    # Sets the two timezones (DST and standard) for @cal to use
    def set_calendar_timezones
      @cal.timezone do
        timezone_id "Europe/London"

        daylight do
          timezone_offset_from "+0000"
          timezone_offset_to "+0100"
          timezone_name "BST"
          dtstart "19700329T010000"
          add_recurrence_rule "FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU"
        end

        standard do
          timezone_offset_from "+0100"
          timezone_offset_to "+0000"
          timezone_name "GMT"
          dtstart "19701025T020000"
          add_recurrence_rule "FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU"
        end
      end
    end

    # Filter the events and add them to the output Icalendar object.
    # @param [Array] events An array of Icalendar::Event instances.
    def add_to_calendar(events)
      events.each do |event|
         @cal.add_event(event) unless should_ignore(event)
      end
    end

    # Returns an array with the names of the modules not taken
    def ignored_names(ignored)
      modules = Config.read("modules") || []
      ignored.map { |i| modules[i] || "" }
    end

    # Returns true if a given event should be ignored, that is if
    # its #summary string attribute starts with the name of one of
    # the modules the user isn't taking
    def should_ignore(event)
      @ignored.any? { |ign| event.summary =~ /^#{ign}/i }
    end

    # Returns true if @course_id is a single-year course
    def masters_course?
      Config.read("course_ids")[@course].count == 1
    end

    def course_name
      Config.read("courses")[@course] || ""
    end

    def course_id
      ids = Config.read("course_ids")[@course]
      ids[@course_year] rescue nil
    end
  end
end
