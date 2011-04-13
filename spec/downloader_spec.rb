require 'downloader'

describe Timetable::Downloader do
  before :each do
    @downloader = Timetable::Downloader.new
  end

  context "given no input" do
    it "returns nil" do
      @downloader.download.should be_nil
    end
  end

  context "given missing input" do
    before :each do
      @downloader.course_id = nil
      @downloader.season = "autumn"
      @downloader.weeks = 1..1
    end

    it "returns nil" do
      @downloader.download.should be_nil
    end
  end

  context "given valid input" do
    before :each do
      @downloader.course_id = 1
      @downloader.season = "autumn"
      @downloader.weeks = 1..1
    end

    it "returns a valid HTML file" do
      data = @downloader.download
      data.should match(/<html[^>]*>/)
    end
  end
end
