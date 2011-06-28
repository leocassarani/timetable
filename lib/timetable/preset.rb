require 'digest/sha1'

module Timetable
  class Preset
    attr_reader :name

    COLLECTION = "presets"

    def self.find(name)
      return if ENV["RACK_ENV"] == 'test'

      db = DatabaseConnection.new(COLLECTION)
      preset = db.find("name" => name)
      db.close
      preset
    end

    def initialize(course, yoe, year, modules = nil)
      @course = course
      @yoe = yoe
      @year = year
      @modules = modules.map(&:to_s)

      @ignored = modules_ignored
      # No point carrying on if no preset necessary
      return if @ignored.empty?

      @name = get_preset_name
      save_to_database
    end

  private

    # Returns the modules that the user has chosen to ignore,
    # given the ones they've chosen to take
    def modules_ignored
      # If @modules is nil, we assume the user is not ignoring anything
      return [] if @modules.nil?

      mods = Config.read("course_modules") || []
      mods = mods[@course] || []
      mods = mods[@year] || []
      # Convert everything to string to make sure we can compare
      # the elements to the ones in @modules, which are strings
      mods.map!(&:to_s)

      # Return the set difference between all the modules for the
      # given (course, yoe) pair and the modules chosen by the user
      ignored = mods - @modules
      ignored.sort
    end

    def get_preset_name
      return if @ignored.nil?
      salted = @course.to_s + @yoe.to_s + @ignored.join
      Digest::SHA1.hexdigest(salted)[0,5]
    end

    # Checks whether the preset is already present in our MongoHQ
    # instance, and saves it to the database if it isn't
    def save_to_database
      return if ENV['RACK_ENV'] == 'test' || @name.nil?
      db = DatabaseConnection.new(COLLECTION)
      # Only insert if the record doesn't exist already
      unless db.exists?("name" => @name)
        db.insert(
          "name"    =>  @name,
          "course"  =>  @course,
          "yoe"     =>  @yoe,
          "ignored" =>  @ignored
        )
      end
      db.close
    end
  end
end
