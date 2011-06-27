module Timetable
  module TimeHelper
    # Returns true if it's not August yet, as draft timetables
    # are usually published in the first weeks of August
    def new_year?
      Time.now.month < 8
    end

    # Returns the current year, adjusted as per self.new_year?
    def academic_year
      Time.now.year - (new_year? ? 1 : 0)
    end

    # Computes the course year given the year of entry, e.g. in autumn
    # 2010 students who entered the course in 2008 are in year 3
    def course_year(yoe)
      year = academic_year - (yoe + 2000)
      # Add one as we want to count from 1, not 0
      year += 1
      year
    end

    # Returns the range of valid years of entry
    def valid_years
      now = Time.now

      # Get the current year in double digits (e.g. 11 for 2011)
      range_end = academic_year - 2000
      range_start = range_end - 3

      range_start..range_end
    end
  end
end