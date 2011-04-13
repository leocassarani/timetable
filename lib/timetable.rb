require 'sinatra'
require_relative 'calendar'

module Timetable
  class Timetable < Sinatra::Base
    set :public, 'public'

    get '/' do
      "This is the index page"
    end

    get '/:course/:yoe' do
      pass if params[:course] == "__sinatra__"
      begin
        calendar = Calendar.new(params[:course], params[:yoe])
      rescue ArgumentError => e
        return e.message
      end
      calendar.to_ical
    end
  end
end
