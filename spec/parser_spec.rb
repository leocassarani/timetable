require 'spec_helper'

describe Timetable::Parser do
  def sample_data(filename)
    filepath = File.join(File.dirname(__FILE__), "data/#{filename}")
    File.read(filepath)
  end

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
      let(:timetable) { sample_data("empty.html") }

      it "parses weeks range and dates then terminates" do
        delegate.should_receive(:process_week_range).ordered
        delegate.should_receive(:process_week_start).ordered
        delegate.should_not_receive(:process_event)
        # Use .ordered to make sure parsing_ended is at the end
        delegate.should_receive(:parsing_ended).ordered
        parser.parse(timetable)
      end
    end

    context "given a timetable with a single event" do
      let(:timetable) { sample_data("single.html") }

      it "calls process_event once with the event data" do
        event = {
          :day => 2,
          :timeslot => 1,
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
      let(:timetable) { sample_data("single_repeating.html") }

      it "calls process_event once with the event data" do
        event = {
          :day => 2,
          :timeslot => 1,
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
      let(:timetable) { sample_data("multiline.html") }

      it "calls process_event twice with different data" do
        first = {
          :day => 3,
          :timeslot => 5,
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
      let(:timetable) { sample_data("multislot.html") }

      it "calls process_event twice with a different timeslot value" do
        first = {
          :day => 2,
          :timeslot => 0,
          :name => "Programming",
          :type => "LEC",
          :weeks => 2..2,
          :attendees => ["ajf"],
          :locations => ["308"]
        }
        second = first.merge(:timeslot => 1)
        delegate.should_receive(:process_event).with(first)
        delegate.should_receive(:process_event).with(second)
        parser.parse(timetable)
      end
    end

    context "given two unrelated events" do
      let(:timetable) { sample_data("two_events.html") }

      it "calls process_event twice with the correct data" do
        first = {
          :day => 2,
          :timeslot => 0,
          :name => "Programming",
          :type => "LEC",
          :weeks => 2..2,
          :attendees => ["ajf"],
          :locations => ["308"]
        }
        second = {
          :day => 3,
          :timeslot => 5,
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

    it "correctly parses multiple attendees and locations" do
      timetable = sample_data("multiple_attendees_locations.html")
      event = {
        :attendees => ["ajf", "tora"],
        :locations => ["344", "343", "219"]
      }
      delegate.should_receive(:process_event).with(hash_including(event))
      parser.parse(timetable)
    end
  end
end
