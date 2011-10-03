require 'spec_helper'

describe Timetable::ParserDelegate do
  let(:calendar) { double('calendar').as_null_object }
  let(:delegate) { Timetable::ParserDelegate.new(calendar) }
  let(:parser) { Timetable::Parser.new(delegate) }

  it "can parse several different files" do
    calendar.should_receive(:parsing_ended).twice
    # single has 1 event, multiline has 2
    parser.parse(load_fixture("single.html"))    
    parser.parse(load_fixture("multiline.html"))
    delegate.events.should have(3).events
  end

  it "returns an empty array given an empty timetable" do
    calendar.should_receive(:parsing_ended)
    parser.parse(load_fixture("empty.html"))
    delegate.events.should be_empty
  end

  context "given all possible inputs for the 'location' field" do
    let(:data) { load_fixture("rooms.html") }

    it "produces a correct list of rooms for all types of locations" do
      parser.parse(data)
      events = delegate.events.sort { |a, b| a.start <=> b.start }
      locations = events.map(&:location)

      empty, textual, numeric_single, numeric_multiple, mix = locations
      empty.should be_empty
      textual.should == "G16 Sir Alexander Flemming Bldg"
      numeric_single.should == "Room 308"
      numeric_multiple.should == "Rooms 308, 343, 344"
      mix.should == "Clore Lecture Theatre, Room 343"
    end
  end

  context "given a single event" do
    let(:data) { load_fixture("single.html") }
    before :each do
      parser.parse(data)
    end

    it "creates a single event" do
      delegate.events.should have(1).event
    end

    it "gives the correct attributes to the event" do
      event = delegate.events.first

      event.summary.should == "Programming (Lecture)"
      event.description.should == "ajf"
      event.location.should == "Room 308"
      event.start.should == DateTime.civil(2010, 10, 6, 10)
      event.end.should == event.start.advance(:hours => 1)
    end
  end

  context "given a single event that occurs five times" do
    let(:data) { load_fixture("single_repeating.html") }
    before :each do
      parser.parse(data)
    end

    it "creates five distinct events" do
      delegate.events.should have(5).events
    end

    it "creates events with identical attributes" do
      events = delegate.events

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
      events = delegate.events
      first = events.shift
      events.inject(first.start) do |date, event|
        event.start.should == date.advance(:weeks => 1)
        event.start
      end
    end
  end

  context "given two events in the same timeslot" do
    let(:data) { load_fixture("multiline.html") }
    before :each do
      parser.parse(data)
    end

    it "creates two events" do
      delegate.events.should have(2).events
    end

    it "creates the events one week apart" do
      events = delegate.events
      first, second = events.sort { |a, b| a.start <=> b.start }
      second.start.should == first.start.advance(:weeks => 1)
    end
  end

  context "given an event spanning two consecutive timeslots" do
    let(:data) { load_fixture("multislot.html") }
    before :each do
      parser.parse(data)
    end

    it "creates one event only" do
      delegate.events.should have(1).events
    end

    it "creates a two-hour event" do
      event = delegate.events.first
      event.end.should == event.start.advance(:hours => 2)
    end
  end

  context "given a repeating event that exceeds the range of the calendar" do
    let(:data) { load_fixture("out_of_range.html") }
    before :each do
      parser.parse(data)
    end

    it "only creates the events within the range of the calendar" do
      delegate.events.should have(5).events
    end
  end

  context "given events of different types" do
    let(:data) { load_fixture("event_types.html") }
    before :each do
      parser.parse(data)
    end

    it "appends the event type to the summary" do
      events = delegate.events.sort { |a, b| a.start <=> b.start }
      lecture, lab, tutorial = events[0, 3]

      lecture.summary.should == "Programming (Lecture)"
      lab.summary.should == "Logic (Lab)"
      tutorial.summary.should == "Hardware (Tutorial)"
    end

    it "doesn't append the event type to the summary if it's already contained within it" do
      events = delegate.events.sort { |a, b| a.start <=> b.start }
      lecture, lab, tutorial = events[3, 3]

      lecture.summary.should == "Introductory Lecture"
      lab.summary.should == "Laboratory I"
      tutorial.summary.should == "Meet your Tutor Week"
    end
  end

  context "given an event with 'all day' in the title" do
    let(:data) { load_fixture("all_day.html") }
    before :each do
      parser.parse(data)
    end

    it "creates an event that runs from 9am to 6pm on the day" do
      event = delegate.events.first
      event.start.hour.should == 9
      event.end.hour.should == 18
      event.start.to_date.should == event.end.to_date
    end
  end
end

describe "String monkey patches" do
  describe "#integer?" do
    context "given an unsigned nonnegative integer" do
      let(:inputs) { %w[0 42 123] }

      it "returns true" do
        inputs.each do |input|
          input.integer?.should be_true
        end
      end
    end

    context "given any non-integer input" do
      let(:inputs) { [""] + %w[+123 -123 123b4con bacon] }

      it "returns false" do
        inputs.each do |input|
          input.integer?.should be_false
        end
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
