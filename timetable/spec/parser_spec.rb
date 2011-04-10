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
  
  it "should return a calendar given an input" do
    @parser.input = ""
    @parser.parse.should be_a_kind_of Icalendar::Calendar
  end
  
  it "should return an empty calendar given an empty string" do
    @parser.input = ""
    cal = @parser.parse
    cal.events.should be_empty
  end
  
  it "should return an empty calendar given an empty timetable" do
    @parser.input = read_sample_data("empty.html")
    cal = @parser.parse
    cal.events.should be_empty
  end

  describe "monkey patches" do
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
end