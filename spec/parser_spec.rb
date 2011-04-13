require 'parser'

def read_sample_data(filename)
  filepath = File.join(File.dirname(__FILE__), "data/#{filename}")
  File.read(filepath)
end

describe Timetable::Parser do
  before :each do
    @parser = Timetable::Parser.new
  end

  context "given no input" do
    it "returns nil" do
      @parser.parse.should == nil
    end
  end

  context "given nil input" do
    it "returns nil" do
      @parser.input = nil
      @parser.parse.should == nil
    end
  end

  it "can parse several different files" do
    @parser.input = read_sample_data("single.html")
    first = @parser.parse
    @parser.input = read_sample_data("single_repeating.html")
    second = @parser.parse
    first.should_not == second
  end

  context "given an input" do
    it "returns a calendar" do
      @parser.input = read_sample_data("single.html")
      @parser.parse.should be_a_kind_of Icalendar::Calendar
    end
  end

  context "given an empty string" do
    it "returns an empty calendar" do
      @parser.input = ""
      cal = @parser.parse
      cal.should be_a_kind_of Icalendar::Calendar
      cal.events.should be_empty
    end
  end

  context "given an empty timetable" do
    it "returns an empty calendar" do
      @parser.input = read_sample_data("empty.html")
      cal = @parser.parse
      cal.events.should be_empty
    end
  end

  context "given all possible inputs for the location field" do
    it "produces a correct list of rooms" do
      @parser.input = read_sample_data("rooms.html")
      events = @parser.parse.events

      events.sort { |a, b| a.start <=> b.start }
      locations = events.map { |e| e.location }

      empty, textual, numeric_single, numeric_multiple, mix = locations
      empty.should be_empty
      textual.should == "G16 Sir Alexander Flemming Bldg"
      numeric_single.should == "Room 308"
      numeric_multiple.should == "Rooms 308, 343, 344"
      mix.should == "Clore Lecture Theatre, Room 343"
    end
  end

  context "given a single event" do
    before :each do
      @parser.input = read_sample_data("single.html")
      @result = @parser.parse
    end

    it "creates one event only" do
      @result.should have(1).events
    end

    it "gives the correct attributes to the event" do
      event = @result.events.first
      event.summary.should == "Programming (Lecture)"
      event.description.should == "ajf"
      event.location.should == "Room 308"
      event.start.should == DateTime.civil(2010, 10, 6, 10)
      event.end.should == event.start.advance(:hours => 1)
    end
  end

  context "given a single event that occurs five times" do
    before :each do
      @parser.input = read_sample_data("single_repeating.html")
      @result = @parser.parse
    end

    it "creates five distinct events" do
      @result.should have(5).events
    end

    it "creates events with identical attributes" do
      events = @result.events

      first = events.shift
      summary = first.summary
      description = first.description
      location = first.location
      duration = first.end - first.start

      events.each do |event|
        event.summary.should == summary
        event.description.should == description
        event.location.should == location
        (event.end - event.start).should == duration
      end
    end

    it "creates events that are one week apart" do
      events = @result.events
      first = events.shift
      events.inject(first.start) do |date, event|
        event.start.should == date.advance(:weeks => 1)
        event.start
      end
    end
  end

  context "given two events in the same timeslot" do
    before :each do
      @parser.input = read_sample_data("multiline.html")
      @result = @parser.parse
    end

    it "creates two events" do
      @result.should have(2).events
    end

    it "creates the events one week apart" do
      events = @result.events
      first, second = events.sort { |a, b| a.start <=> b.start }
      second.start.should == first.start.advance(:weeks => 1)
    end
  end

  context "given an event spanning two consecutive timeslots" do
    before :each do
      @parser.input = read_sample_data("multislot.html")
      @result = @parser.parse
    end

    it "creates one event only" do
      @result.should have(1).events
    end

    it "creates a two-hour event" do
      event = @result.events.first
      event.end.should == event.start.advance(:hours => 2)
    end
  end
end

# String monkey patches
describe String do
  describe "#integer?" do
    context "given an unsigned positive integer" do
      it "returns true" do
        "1".integer?.should be_true
        "123".integer?.should be_true
      end
    end

    context "given any non-integer input" do
      it "returns false" do
        "".integer?.should be_false
        "+123".integer?.should be_false
        "-123".integer?.should be_false
        "123b4con".integer?.should be_false
        "bacon".integer?.should be_false
      end
    end
  end

  describe ".pluralize" do
    context "given count of 1" do
      it "uses the singular" do
        String.pluralize(1, "bacon").should == "bacon"
        String.pluralize(1, "mouse", "mice").should == "mouse"
      end
    end

    context "given count different from 1" do
      it "uses the plural" do
        String.pluralize(0, "bacon").should == "bacons"
        String.pluralize(42, "mouse", "mice").should == "mice"
      end
    end
  end
end
