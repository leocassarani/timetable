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
end