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

    def initialize(course, yoe)
      validate_arguments(course, yoe)

      @course = course
      @yoe = yoe.to_i
      @course_year = Timetable::course_year(yoe)
      @course_id = course_id

      process_all unless load_cached
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

    # Attempts to load the cached copy of the parsed timetable files
    def load_cached
      begin
        if Cache.has?(@course_id)
          puts "Hitting cache"
          events = Cache.get(@course_id)
          @cal = Icalendar::Calendar.new
          @cal.prodid = "DoC Timetable"
          # TODO: set timezones
          events.each { |e| @cal.add_event(e) }
          return true
        end
      rescue
        return nil
      end
    end

    # Downloads and parses all the necessary files
    def process_all
      puts "Not hitting cache"
      config("seasons").each do |season|
        config("week_ranges").each do |weeks|
          data = download(season, weeks)
          parse(data)
        end
      end
      Cache.save(@course_id, @cal.events)
    end

    def download(season, weeks)
      downloader = Downloader.new(@course_id, season, weeks)
      downloader.download
    end

    def parse(data)
      parser = Parser.new(data)
      @cal = parser.parse(@cal)
    end

    def config(key)
      @config ||= YAML.load_file("config/timetable.yml")
      @config[key]
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
