module Timetable
  COURSES = {
		'comp'  => 'Computing',
		'jmc'   => 'JMC',
		'ee'    => 'Electronic Engineering',
		'ise'   => 'Information System Engineering',
		'mci'   => 'MSc Computing for Industry',
		'mres'  => 'MRes in Advanced Computing',
		'msa'   => 'MSc Advanced Computing',
		'msv'   => 'MSc Computing Science',
		'mss'   => 'MSs Computing Science Specialism'
  }

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
    end

    def to_ical
      return "Not implemented yet" if @cal.nil?
    end

  private

    def valid_years
      now = Time.now

      # Get the current year in double digits (e.g. 11 for 2011)
      range_end = now.year - 2000

      # Subtract one year if it's not August yet, as draft timetables
      # are usually published then
      range_end -= 1 if now.month < 8
      range_start = range_end - 3

      range_start..range_end
    end
  end
end
