module Timetable
  class Calendar
    attr_reader :course, :yoe

    def initialize(course, yoe)
      @course = course
      @yoe = yoe
    end

    def to_ical
      "Not implemented yet"
    end
  end
end