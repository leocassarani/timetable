require 'sinatra/base'
require 'haml'
require 'json'
require 'yaml'

$LOAD_PATH << File.dirname(__FILE__)
require 'cache'
require 'calendar'
require 'config'
require 'database'
require 'downloader'
require 'parser'
require 'preset'
require 'time_helper'

module Timetable
  class Application < Sinatra::Base
    include TimeHelper

    # Set the parent directory of this file as the project root
    set :root, File.dirname(File.dirname(__FILE__))
    set :haml, :format => :html5

    get '/' do
      @courses = Config.read("courses")
      @modules = Config.read("modules")
      @course_modules = Config.read("course_modules")
      haml :index
    end

    get '/install' do
      redirect '/'
    end

    post '/install' do
      # Convert year of entry into course year
      yoe = params[:yoe].to_i
      year = course_year(yoe)

      # Remove the values for the dropdown menus and the submit button
      # from the params hash to get the modules chosen by the user
      form = ["course", "yoe", "submit"]
      modules = params.reject { |key, _| form.include? key }
      modules = modules.keys

      # Create a new Preset object with the user's choices. It is worth
      # noting that if the same preset already exists, we will reuse
      # that database record and will avoid creating a new one
      begin
        preset = Preset.new(params[:course], yoe, year, modules)
      rescue RuntimeError => e
        return error 500, e.message
      end

      # If the preset doesn't exist (e.g. because the user took all the
      # modules), then give them a default url of the form course/yoe
      name = preset.name || "#{params[:course]}/#{params[:yoe]}"
      @url = "webcal://localhost:9393/#{name}"

      # Tell the views to include the lightbox image viewer js files
      @lightbox = true
      haml :install
    end

    # Match routes corresponding to a given preset
    get '/:preset' do
      preset = Preset.find(params[:preset])
      if preset.nil?
        return error 404, "Calendar preset not found"
      end
      show_ical(preset["course"], preset["yoe"], preset["ignored"])
    end

    # Match generic routes such as /comp/09 or /jmc/10
    get %r{/([a-z]+)/([\d]{2})/?} do
      course, yoe = params[:captures]
      show_ical(course, yoe)
    end

    helpers do
      # Returns a hash containing an array of valid years for every
      # course ID, e.g. "comp" => [1,2,3,4], "ee" => [3,4]
      def course_years
        Config.read("course_ids").inject({}) do |memo, (k, v)|
          memo.merge({k => v.keys})
        end
      end

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
        academic_year - year + 1
      end

      # Returns the URL of the install guide picture for a given
      # app (iCal, GCal, etc) and a given step in the guide.
      def guide_pic(app, step)
        "images/#{app}/step#{step}.png"
      end
    end

  private

    # Returns the iCal representation of the timetable for a given
    # course and year of entry, and (optional) ignored modules
    def show_ical(course, yoe, ignored = [])
      begin
        calendar = Calendar.new(course, yoe.to_i, ignored)
      rescue ArgumentError => e
        return error 404, e.message
      end
      headers "Content-Type" => "text/plain"
      calendar.to_ical
    end
  end
end
