require 'active_support/core_ext'
require 'icalendar'

module Timetable
  class Cache
    COLLECTION = "cache"

    # Return whether a particular course ID is cached in the database.
    # A course ID is considered cached if there is a corresponding record
    # in the database and that record is no more than 30 minutes old.
    #
    # @param [Integer] course_id The course ID.
    # @return [Boolean] A boolean value indicating whether the given
    #   course ID is already cached in the database.
    def self.has?(course_id)
      return false if ENV['RACK_ENV'] == 'test'

      Database.execute(COLLECTION) do |db|
        db.exists?(
          "course_id" => course_id,
          "created_on" => { "$gte" => 30.minutes.ago }
        )
      end
    end

    # Retrieve the cached events for a given course ID, no matter how long
    # ago the record was saved to cache.
    #
    # @param [Integer] course_id The course ID.
    # @return [Array] An array of {Icalendar::Event} objects.
    def self.get(course_id)
      events = Database.execute(COLLECTION) do |db|
        db.find("course_id" => course_id)["events"]
      end
      events.map { |event| Icalendar::Event.unserialize(event) }
    end

    # Save the events list for a given course ID in serialized form, as well
    # as a +created_on+ value for when the cached record was created.
    #
    # @param [Integer] course_id The course ID.
    # @param [Array] events An array of {Icalendar::Event} objects to be saved
    #   to cache.
    def self.save(course_id, events)
      return if ENV['RACK_ENV'] == 'test'
      doc = {
        "course_id" => course_id,
        "created_on" => Time.now,
        "events" => events.map(&:serialize)
      }
      Database.execute(COLLECTION) do |db|
        old = db.find("course_id" => course_id)
        old ? db.update(old, doc) : db.insert(doc)
      end
    end
  end
end

module Icalendar
  class Event
    # Return a hash with the essential attributes of the event, ready to be
    # inserted into a MongoDB collection.
    #
    # @return [Hash] The main iCalendar attributes of the receiver.
    def serialize
      {
        "uid"         =>  uid,
        "start"       =>  start.to_time,
        "end"         =>  self.end.to_time,
        "summary"     =>  summary,
        "description" =>  description,
        "location"    =>  location
      }
    end

    # Create a new instance of {Event} given a hash of attributes.
    #
    # @param [Hash] hash The desired attributes for the new event.
    # @return [Event] An instance of {Event} generated from the given data.
    def self.unserialize(hash)
      # Mongo doesn't support DateTime objects, so start and end times
      # are serialized as Time objects, here we simply convert them back
      hash["start"] = hash["start"].to_datetime
      hash["end"] = hash["end"].to_datetime

      event = Event.new
      hash.each do |key, value|
        event.send("#{key}=".to_sym, value)
      end
      event
    end
  end
end
