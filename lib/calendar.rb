require 'icalendar'
require 'yaml'
require_relative 'cache'
require_relative 'downloader'
require_relative 'parser'

module Timetable
  # Returns true if it's not August yet, as draft timetables
  # are usually published in the first weeks of August
  def self.new_year?
    Time.now.month < 8
  end

  # Returns the current year, adjusted as per self.new_year?
  def self.academic_year
    Time.now.year - (new_year? ? 1 : 0)
  end

  # Computes the course year given the year of entry, e.g. in autumn
  # 2010 students who entered the course in 2008 are in year 3
  def self.course_year(yoe)
    year = Timetable::academic_year - (yoe + 2000)
    # Add one as we want to count from 1, not 0
    year += 1
    year
  end

  class Calendar
    attr_reader :course, :yoe

    def initialize(course, yoe, ignored = [])
      validate_arguments(course, yoe)

      @course = course
      @yoe = yoe.to_i
      @ignored = ignored_names(ignored)

      @course_year = Timetable::course_year(yoe)
      @course_id = course_id

      process_all # unless load_cached
    end

    def to_ical
      @cal.to_ical if @cal
    end

  private

    # Checks that the parameters provided by the user are valid,
    # i.e. the course name exists and the yoe is within range
    def validate_arguments(course, yoe_text)
      unless config("courses").has_key?(course)
        raise ArgumentError, %Q{Invalid course name "#{course}"}
      end

      yoe = yoe_text.to_i
      unless valid_years.include?(yoe)
        raise ArgumentError, %Q{Invalid year of entry "#{yoe_text}"}
      end
    end

    # Returns an array with the names of the modules not taken
    def ignored_names(ignored)
      modules = config("modules") || []
      ignored.map! { |i| modules[i] || "" }
    end

    # Attempts to load the cached copy of the parsed timetable files
    def load_cached
      begin
        if Cache.has?(@course_id)
          puts "Hitting cache"
          events = Cache.get(@course_id)

          # Initialise @cal as an empty Icalendar::Calendar instance
          init_calendar

          # Add all cached events to our (empty) calendar, unless they
          # relate to a module that's in the ignored list
          events.each do |e|
            @cal.add_event(e) unless should_ignore(e)
          end

          return true
        end
      rescue
        return nil
      end
    end

    # Initialises an empty calendar and saves it to the @cal instance var
    def init_calendar
      @cal = Icalendar::Calendar.new
      @cal.prodid = "DoC Timetable"
      set_timezones
    end

    # Sets the two timezones (DST and standard) for @cal to use
    def set_timezones
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

    # Downloads and parses all the necessary files, then saves it all
    # to cache and applies preset options
    def process_all
      puts "Not hitting cache"

      # Initialise an empty calendar in @cal
      init_calendar

      # Download and parse each of the files for all the seasons
      # and week ranges we need to process
      config("seasons").each do |season|
        config("week_ranges").each do |weeks|
          data = download(season, weeks)
          parse(data)
        end
      end

      # Save the parsed events to cache to speed up future requests
      Cache.save(@course_id, @cal.events)

      # Apply the preset options by hiding ignored modules - we have to
      # do this in a slightly roundabout way because it wouldn't be safe
      # to remove events while they're being iterated upon
      remove = []
      @cal.events.each { |e| remove << e if should_ignore(e) }
      remove.each { |e| @cal.remove_event(e) }
    end

    # Returns true if a given event should be ignored, that is if
    # its #summary string attribute starts with the name of one of
    # the modules the user isn't taking
    def should_ignore(e)
      @ignored.any? { |ign| e.summary =~ /^#{ign}/i }
    end

    def download(season, weeks)
      downloader = Downloader.new(@course_id, season, weeks)
      downloader.download
    end

    def parse(data)
      parser = Parser.new(data)
      @cal = parser.parse(@cal, @ignored)
    end

    def config(key)
      @config ||= load_config
      @config[key]
    end

    # Loads all the configuration files into a hash and returns it
    def load_config
      config = {}
      config.merge!(YAML.load_file("config/timetable.yml"))
      config.merge!(YAML.load_file("config/modules.yml"))
    end

    # Returns the range of valid years of entry
    def valid_years
      now = Time.now

      # Get the current year in double digits (e.g. 11 for 2011)
      range_end = Timetable::academic_year - 2000
      range_start = range_end - 3

      range_start..range_end
    end

    def course_id
      ids = config("course_ids")[course]
      return if ids.nil?
      ids[@course_year]
    end
  end
end
