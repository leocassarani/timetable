require_relative 'downloader'
require_relative 'parser'
require_relative '../config/courses'

module Timetable
  class Calendar
    attr_reader :course, :yoe

    def initialize(course, yoe_text)
      unless COURSES.has_key?(course)
        raise ArgumentError, %Q{Invalid course name "#{course}"}
      end

      yoe = yoe_text.to_i
      unless valid_years.include?(yoe)
        raise ArgumentError, %Q{Invalid year of entry "#{yoe_text}"}
      end

      @course = course
      @yoe = yoe
      @year = course_year

      download
      parse
    end

    def to_ical
      return "An error has occurred" if @cal.nil?
      @cal.to_ical
    end

  private

    def download
      id = COURSE_IDS[course][@year]
      return if id.nil?
      downloader = Downloader.new(id, 'autumn', 1..1)
      @data = downloader.download
    end

    def parse
      parser = Parser.new(@data)
      @cal = parser.parse
    end

    # Returns the range of valid years of entry
    def valid_years
      now = Time.now

      # Get the current year in double digits (e.g. 11 for 2011)
      range_end = now.year - 2000

      # Subtract one year if we're in the spring or summer term
      range_end -= 1 if new_year?
      range_start = range_end - 3

      range_start..range_end
    end

    # Computes the course year given the year of entry, e.g. in autumn
    # 2010 students who entered the course in 2008 are in year 3
    def course_year
      year = Time.now.year - (yoe + 2000)
      # Add one if we're still in the autumn term
      year += 1 unless new_year?
      year
    end

    # Returns true if it's not August yet, as draft timetables
    # are usually published in the first weeks of August
    def new_year?
      Time.now.month < 8
    end
  end
end
