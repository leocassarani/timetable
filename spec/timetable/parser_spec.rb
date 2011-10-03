require 'spec_helper'

describe Timetable::Parser do
  describe "#parse" do
    let(:delegate) { double('delegate').as_null_object }
    let(:parser) { Timetable::Parser.new(delegate) }

    before :each do
      # The parser will send messages only if the delegate responds to them
      delegate.stub!(:respond_to).and_return(true)
    end

    it "instantly terminates given no input" do
      delegate.should_receive(:parsing_ended)
      parser.parse(nil)
    end

    context "given an empty timetable" do
      let(:timetable) { load_fixture("empty.html") }

      it "parses weeks range and dates then terminates" do
        delegate.should_receive(:parsing_began).ordered
        delegate.should_receive(:process_week_range).ordered
        delegate.should_receive(:process_week_start).ordered
        delegate.should_not_receive(:process_event)
        # Use .ordered to make sure parsing_ended is at the end
        delegate.should_receive(:parsing_ended).ordered
        parser.parse(timetable)
      end
    end

    context "given a single-week range" do
      let(:timetable) { load_fixture("1_1_1.html") }

      it "parses it correctly" do
        delegate.should_receive(:process_week_range).with(1..1)
        parser.parse(timetable)
      end
    end

    context "given a multiple-week range" do
      let(:timetable) { load_fixture("1_2_11.html") }

      it "parses it correctly" do
        delegate.should_receive(:process_week_range).with(2..11)
        parser.parse(timetable)
      end
    end

    it "parses week start dates correctly" do
      timetable = load_fixture("1_1_1.html")
      week_start = DateTime.civil(2010, 10, 4)
      delegate.should_receive(:process_week_start).with(week_start)

      parser.parse(timetable)
    end

    context "given a timetable with a single event" do
      let(:timetable) { load_fixture("single.html") }

      it "calls process_event once with the event data" do
        event = {
          :day => 2,
          :time => 10,
          :name => "Programming",
          :type => "LEC",
          :weeks => 1..1,
          :attendees => ["ajf"],
          :locations => ["308"]
        }
        delegate.should_receive(:process_event).with(event)
        parser.parse(timetable)
      end
    end

    context "given a timetable with a single repeating event" do
      let(:timetable) { load_fixture("single_repeating.html") }

      it "calls process_event once with the event data" do
        event = {
          :day => 2,
          :time => 10,
          :name => "Programming",
          :type => "LEC",
          :weeks => 2..6,
          :attendees => ["ajf"],
          :locations => ["308"]
        }
        delegate.should_receive(:process_event).with(event)
        parser.parse(timetable)
      end
    end

    context "given two events in the same timeslot" do
      let(:timetable) { load_fixture("multiline.html") }

      it "calls process_event twice with different data" do
        first = {
          :day => 3,
          :time => 14,
          :name => "Discrete Mathematics I",
          :type => "LEC",
          :weeks => 3..3,
          :attendees => ["yg"],
          :locations => ["308"]
        }
        second = first.merge ({
          :name => "Mathematical Methods",
          :type => "LEC",
          :weeks => 2..2,
          :attendees => ["jb"]
        })
        delegate.should_receive(:process_event).with(first)
        delegate.should_receive(:process_event).with(second)
        parser.parse(timetable)
      end
    end

    context "given the same event spanning consecutive timeslots" do
      let(:timetable) { load_fixture("multislot.html") }

      it "calls process_event twice with a different timeslot value" do
        first = {
          :day => 2,
          :time => 9,
          :name => "Programming",
          :type => "LEC",
          :weeks => 2..2,
          :attendees => ["ajf"],
          :locations => ["308"]
        }
        second = first.merge(:time => 10)
        delegate.should_receive(:process_event).with(first)
        delegate.should_receive(:process_event).with(second)
        parser.parse(timetable)
      end
    end

    context "given two unrelated events" do
      let(:timetable) { load_fixture("two_events.html") }

      it "calls process_event twice with the correct data" do
        first = {
          :day => 2,
          :time => 9,
          :name => "Programming",
          :type => "LEC",
          :weeks => 2..2,
          :attendees => ["ajf"],
          :locations => ["308"]
        }
        second = {
          :day => 3,
          :time => 14,
          :name => "Mathematical Methods",
          :type => "LEC",
          :weeks => 2..4,
          :attendees => ["jb"],
          :locations => ["308"]
        }
        delegate.should_receive(:process_event).with(first)
        delegate.should_receive(:process_event).with(second)
        parser.parse(timetable)
      end
    end

    it "parses multiple attendees and locations correctly" do
      timetable = load_fixture("multiple_attendees_locations.html")
      event = {
        :attendees => ["ajf", "tora"],
        :locations => ["344", "343", "219"]
      }
      delegate.should_receive(:process_event).with(hash_including(event))
      parser.parse(timetable)
    end

    it "parses events with no attendees or locations correctly" do
      timetable = load_fixture("no_attendees_locations.html")
      event = {
        :attendees => [],
        :locations => []
      }
      delegate.should_receive(:process_event).with(hash_including(event))
      parser.parse(timetable)
    end
  end
end
