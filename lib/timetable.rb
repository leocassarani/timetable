require "sinatra/base"
require "haml"
require "json"
require "yaml"
require_relative "calendar"

module Timetable
  class Application < Sinatra::Base
    # Set the parent directory of this file as the project root
    set :root, File.dirname(File.dirname(__FILE__))
    set :haml, :format => :html5

    helpers do
      # Given a number, returns a string with the number followed
      # by its ordinal suffix. E.g. 1 is "1st". Only works in the
      # 0-20 range, which is more than enough for what we need
      def ordinal(num)
        suffixes = [nil, 'st', 'nd', 'rd', 'th']
        num.to_s + (suffixes[num] || 'th')
      end

      # Returns the year of entry corresponding to a given course
      # year (as a number), so that 1 corresponds to the current
      # academic year, 2 to last year, etc
      def year_to_yoe(year)
        Timetable::academic_year - year + 1
      end

      # Returns the URL of the install guide picture for a given
      # app (iCal, GCal, etc) and a given step in the guide.
      def guide_pic(app, step)
        "images/#{app}/step#{step}.png"
      end
    end

    get '/' do
      @courses = config("courses")
      @course_years = course_years
      haml :index
    end

    post '/install' do
      @course = params[:course]
      @yoe = params[:yoe]
      @url = "webcal://example.com"
      haml :install
    end

    # Match routes such as /comp/09 or /jmc/10
    get %r{/([a-z]+)/([\d]{2})/?} do
      course, yoe = params[:captures]
      begin
        calendar = Calendar.new(course, yoe)
      rescue ArgumentError => e
        return e.message
      end
      headers "Content-Type" => "text/plain"
      calendar.to_ical
    end

    # Returns the configuration value for a given key
    def config(key)
      @config ||= YAML.load_file("config/timetable.yml")
      @config[key]
    end

    # Helper method that returns a hash containing an array of
    # valid years for every course ID, e.g. "comp" => [1,2,3,4]
    def course_years
      config("course_ids").inject({}) do |memo, (k, v)|
        memo.merge({k => v.keys})
      end
    end
  end
end
