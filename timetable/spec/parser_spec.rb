require '../timetable/parser'

def read_sample_data(filename)
  filepath = File.join(File.dirname(__FILE__), filename)
  File.read(filepath)
end

describe Timetable::Parser do
  before :each do
    @parser = Timetable::Parser.new
  end
  
  it "should return nil if input not set" do
    @parser.parse.should == nil
  end
  
  it "should return nil if input set to nil" do
    @parser.input = nil
    @parser.parse.should == nil
  end

  it "should be able to parse several different files" do
    @parser.input = read_sample_data("single.html")
    first = @parser.parse
    @parser.input = read_sample_data("single_repeating.html")
    second = @parser.parse
    first.should_not == second
  end

  it "should return a calendar given an input" do
    @parser.input = read_sample_data("single.html")
    @parser.parse.should be_a_kind_of Icalendar::Calendar
  end

  it "should return an empty calendar given an empty string" do
    @parser.input = ""
    cal = @parser.parse
    cal.should be_a_kind_of Icalendar::Calendar
    cal.events.should be_empty
  end
  
  it "should return an empty calendar given an empty timetable" do
    @parser.input = read_sample_data("empty.html")
    cal = @parser.parse
    cal.events.should be_empty
  end

  describe "given a single event" do
    before :each do
      @parser.input = read_sample_data("single.html")
      @result = @parser.parse
    end

    it "should create one event" do
      @result.should have(1).events
    end

    it "should give the correct attributes to the event" do
      event = @result.events.first
      event.summary.should == "Programming (Lecture)"
      event.description.should == "ajf"
      event.location.should == "Room 308"
      event.start.should == DateTime.civil(2010, 10, 6, 10)
      event.end.should == event.start.advance(:hours => 1)
    end
  end

  describe "given a single repeating event" do
    before :each do
      @parser.input = read_sample_data("single_repeating.html")
      @result = @parser.parse
    end

    it "should create five events" do
      @result.should have(5).events
    end

    it "should create events with identical attributes" do
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

    it "should create events that are one week apart" do
      events = @result.events
      first = events.shift
      events.inject(first.start) do |date, event|
        event.start.should == date.advance(:weeks => 1)
        event.start
      end
    end
  end

  describe "given multiple events in the same timeslot" do
    before :each do
      @parser.input = read_sample_data("multiline.html")
      @result = @parser.parse
    end

    it "should create two events" do
      @result.should have(2).events
    end

    it "should create two events one week apart" do
      events = @result.events
      first, second = events.sort { |a, b| a.start <=> b.start }
      second.start.should == first.start.advance(:weeks => 1)
    end
  end

  describe "given an event spanning multiple timeslots" do
    before :each do
      @parser.input = read_sample_data("multislot.html")
      @result = @parser.parse
    end

    it "should only create one event" do
      @result.should have(1).events
    end

    it "should create a two-hour event" do
      event = @result.events.first
      event.end.should == event.start.advance(:hours => 2)
    end
  end
end

# String monkey patches
describe String do
  describe "String#integer?" do
      it "should return true on an unsigned positive integer" do
        "1".integer?.should be_true
        "123".integer?.should be_true
      end

      it "should return false on any non-integer input" do
        "".integer?.should be_false
        "+123".integer?.should be_false
        "-123".integer?.should be_false
        "123b4con".integer?.should be_false
        "bacon".integer?.should be_false
      end
  end

  describe "String.pluralize" do
    it "should use the singular when count is 1" do
      String.pluralize(1, "bacon").should == "bacon"
      String.pluralize(1, "mouse", "mice").should == "mouse"
    end

    it "should use the plural when count is not 1" do
      String.pluralize(0, "bacon").should == "bacons"
      String.pluralize(42, "mouse", "mice").should == "mice"
    end
  end
end
