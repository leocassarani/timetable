$:.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'timetable/parser'

module Timetable
  get '/' do
    parser = Parser.new("Ohai")
  end
end