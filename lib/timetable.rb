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

    get '/' do
      @courses = config("courses")
      @course_years = course_years
      haml :index
    end

    post '/install' do
      # TODO
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
