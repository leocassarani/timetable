require 'bundler/setup'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "lib"))
require 'timetable'

run Timetable::Application