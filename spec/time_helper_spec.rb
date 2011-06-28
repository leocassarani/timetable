require 'spec_helper'

describe Timetable::TimeHelper do
  let(:helper) { Object.new.extend(Timetable::TimeHelper) }

  describe "new_year?" do
    it "returns true if we're past August, false otherwise" do
      helper.new_year?.should == Time.now.month < 8
    end
  end

  describe "academic_year" do
    it "returns the current academic year" do
      year = Time.now.year
      year -= 1 if helper.new_year?
      helper.academic_year.should == year
    end
  end

  describe "valid_years" do
    it "returns the currently valid years of entry" do
      year = Time.now.year - 2000
      year -= 1 if helper.new_year?
      helper.valid_years.should == ((year - 3)..year)
    end
  end
end