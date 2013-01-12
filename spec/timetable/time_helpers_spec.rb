require 'timetable/time_helpers'

describe Timetable::TimeHelpers do
  include Timetable::TimeHelpers

  let(:now) { mock(:now, year: 2013, month: 8) }
  before { Time.stub(:now) { now } }

  describe "new_year?" do
    it "returns true before August" do
      Time.stub_chain(:now, :month) { 7 }
      new_year?.should be_true
    end

    it "returns false from August onwards" do
      Time.stub_chain(:now, :month) { 8 }
      new_year?.should be_false
    end
  end

  describe "academic_year" do
    context "before August" do
      before { Time.stub_chain(:now, :month) { 7 } }

      it "returns the previous calendar year" do
        academic_year.should == 2012
      end
    end

    context "from August onwards" do
      before { Time.stub_chain(:now, :month) { 8 } }

      it "returns the current calendar year" do
        academic_year.should == 2013
      end
    end
  end

  describe "valid_years" do
    it "returns a range of the last 4 years, as double digits" do
      valid_years.should == (10..13)
    end
  end
end
