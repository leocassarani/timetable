require 'active_support/core_ext'
require 'icalendar'

module Timetable
  class Cache
    COLLECTION = "cache"
    # Returns whether a particular course_id is cached in our database
    def self.has?(course_id)
      db = DatabaseConnection.new(COLLECTION)
      # Check that the right course_id exists, and that it's not too old
      retval = db.exists?(
        "course_id" => course_id,
        "created_on" => {"$gte" => 30.minutes.ago}
      )
      db.close
      retval
    end

    # Retrieves the cached events for a given course id, regardless of how
    # old the cache is - that's what Cache.has? is for
    def self.get(course_id)
      db = DatabaseConnection.new(COLLECTION)
      events = db.find("course_id" => course_id)["events"]
      db.close
      events.map { |e| Icalendar::Event.unserialize(e) }
    end

    # Saves the events list for a given course_id in serialized form,
    # as well as when the cached record was created
    def self.save(course_id, events)
      doc = {
        "course_id" => course_id,
        "created_on" => Time.now,
        "events" => events.map(&:serialize)
      }

      db = DatabaseConnection.new(COLLECTION)
      old = db.find("course_id" => course_id)

      if old
        # Update the pre-existing document
        db.update(old, doc)
      else
        # Insert a new one otherwise
        db.insert(doc)
      end

      db.close
    end
  end
end

module Icalendar
  class Event
    # Returns a hash with the essential attributes of the event,
    # ready to be inserted into a MongoDB collection
    def serialize
      {
        "uid" => uid,
        "start" => start.to_time,
        "end" => self.end.to_time,
        "summary" => summary,
        "description" => description,
        "location" => location
      }
    end

    def self.unserialize(hash)
      # Mongo doesn't support DateTime objects, so start and end times
      # are serialized as Time objects, here we simply convert them back
      hash["start"] = hash["start"].to_datetime
      hash["end"] = hash["end"].to_datetime

      # Iterate over every (key, value) pair of the serialized hash
      # and call the corresponding key= method on our newly-created
      # Event object, with value as its argument. This simply populates
      # the attributes of the event with the serialized data.
      event = Event.new
      hash.each do |key, value|
        event.send("#{key}=".to_sym, value)
      end

      event
    end
  end
end
