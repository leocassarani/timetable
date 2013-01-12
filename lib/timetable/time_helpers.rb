module Timetable
  module TimeHelpers
    # Return true if it's not August yet.
    #
    # @return [Boolean] A boolean value representing whether we're currently
    #   in the period of the year before August, as new draft timetables are
    #   usually published in the first weeks of August.
    def new_year?
      Time.now.month < 8
    end

    # Return the current academic year.
    #
    # @return [Integer] The academic year currently in progress: the one
    #   that started last year if it's not August yet, or the one that
    #   started this year if we're past August.
    def academic_year
      Time.now.year - (new_year? ? 1 : 0)
    end

    # Compute the course year given the year of entry, e.g. in autumn
    # 2010 students who entered the course in 2008 are in year 3.
    #
    # @param [Integer] yoe A year of entry expressed as double digits.
    # @return [Integer] The course year that currently corresponds to
    #   the given year of entry.
    def course_year(yoe)
      academic_year - (yoe + 2000) + 1
    end

    # Return the range of currently valid years of entry.
    #
    # @return [Range] A range of valid years of entry, as double digits.
    def valid_years
      range_end = academic_year - 2000
      range_start = range_end - 3
      range_start..range_end
    end
  end
end
