require 'open-uri'

module Timetable
  REMOTE_HOST = "www.doc.ic.ac.uk"
  REMOTE_PATH = "internal/timetables/timetable/:season/class"
  REMOTE_FILE = ":course_:start_:end.htm"
  REMOTE_URL = "http://#{REMOTE_HOST}/#{REMOTE_PATH}/#{REMOTE_FILE}"

  class Downloader
    attr_accessor :course_id, :season, :weeks
    attr_reader :data

    def initialize(course_id = nil, season = nil, weeks = nil)
      @course_id = course_id
      @season = season
      @weeks = weeks
    end

    def download
      return if url.nil?
      begin
        @data = open(url).read
      rescue OpenURI::HTTPError
        # We ignore HTTP errors, and so will the parser
        return nil
      end
      @data
    end

  private

    # Returns the URL corresponding to the input given
    def url
      return if course_id.nil? || season.nil? || weeks.nil?

      # Somewhat surprisingly, if we don't clone the constant
      # then the calls to gsub! will actually change its value
      result = REMOTE_URL.clone
      result.gsub!(':season', season.to_s)
      result.gsub!(':course', course_id.to_s)
      result.gsub!(':start', weeks.first.to_s)
      result.gsub!(':end', weeks.last.to_s)
      result
    end
  end
end
