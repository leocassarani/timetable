require 'spec_helper'

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

  describe "excluding ignored modules" do
    let(:course) { "comp" }
    let(:year) { 2 }
    let(:yoe) do
      helper = Object.new.extend(Timetable::TimeHelpers)
      helper.valid_years.to_a[-year]
    end
    let(:modules) { Timetable::Config.read("course_modules")[course][year] }
    let(:names) { modules.map { |m| Timetable::Config.read("modules")[m] } }

    context "given no ignored modules" do
      let(:calendar) { Timetable::Calendar.new(course, yoe, []) }

      it "returns a calendar containing events relating to those modules" do
        calendar.cal.events.any? do |event|
          names.any? do |name|
            event.summary =~ /#{name}/i
          end
        end.should be_true
      end
    end

    context "given a list of ignored modules" do
      let(:calendar) { Timetable::Calendar.new(course, yoe, modules) }

      it "returns a calendar with no events relating to those modules" do
        calendar.cal.events.each do |event|
          names.each do |name|
            event.summary.should_not match(/#{name}/i)
          end
        end
      end
    end
  end
end
