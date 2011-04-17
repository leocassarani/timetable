require "bundler/setup"
require "sinatra"
require "haml"
require_relative "calendar"

module Timetable
  set :haml, :format => :html5

  class Timetable < Sinatra::Base
    get '/' do
      haml :index
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
  end
end
