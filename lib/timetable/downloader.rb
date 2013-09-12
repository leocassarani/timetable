require 'open-uri'

module Timetable
  REMOTE_HOST = "www.doc.ic.ac.uk"
  REMOTE_PATH = "internal/timetables/:year/:season/class"
  REMOTE_FILE = ":course_:start_:end.htm"

  class Downloader
    attr_accessor :course_id, :season, :weeks, :year
    attr_reader :data

    def initialize(course_id = nil, year = nil, season = nil, weeks = nil)
      @year = year
      @course_id = course_id
      @season = season
      @weeks = weeks
    end

    def download
      url = remote_url
      return if url.nil?
      begin
        @data = open(url).read
      rescue OpenURI::HTTPError
        # We ignore HTTP errors, and so will the parser
        return
      end
      @data
    end

  private

    # Returns the URL corresponding to the input given
    def remote_url
      return if course_id.nil? || season.nil? || weeks.nil?

      result = "http://" + [REMOTE_HOST, REMOTE_PATH, REMOTE_FILE].join('/')
      result.gsub!(':year', "#{@year.to_s}-#{(@year + 1).to_s[-2..-1]}")
      result.gsub!(':season', season.to_s)
      result.gsub!(':course', course_id.to_s)
      result.gsub!(':start', weeks.first.to_s)
      result.gsub!(':end', weeks.last.to_s)
      result
    end
  end
end
