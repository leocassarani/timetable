require 'spec_helper'

describe Timetable do
  describe ".new_year?" do
    it "returns true if we're past August, false otherwise" do
      Timetable::new_year?.should == Time.now.month < 8
    end
  end

  describe ".academic_year" do
    it "returns the current academic year" do
      year = Time.now.year
      year -= 1 if Timetable::new_year?
      Timetable::academic_year.should == year
    end
  end
end

describe Timetable::Calendar do
  context "detecting bad parameters" do
    it "raises an ArgumentError given a nil course name" do
        calendar = lambda { Timetable::Calendar.new(nil, "09") }
        calendar.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError given an invalid course name" do
      calendar = lambda { Timetable::Calendar.new("foobar", "09") }
      calendar.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError given a nil year of entry" do
      calendar = lambda { Timetable::Calendar.new("comp", nil) }
      calendar.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError given a non-numeric year of entry" do
      calendar = lambda { Timetable::Calendar.new("comp", "foobar") }
      calendar.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError given an invalid year of entry" do
      calendar = lambda { Timetable::Calendar.new("comp", "03") }
      calendar.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError given nil arguments" do
      calendar = lambda { Timetable::Calendar.new(nil, nil) }
      calendar.should raise_error(ArgumentError)
    end

    it "raises an ArgumentError given invalid arguments" do
      calendar = lambda { Timetable::Calendar.new("chunky", "bacon") }
      calendar.should raise_error(ArgumentError)
    end
  end
end