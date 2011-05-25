require 'mongo'

module Timetable
  class DatabaseConnection
    # Establishes a connection to our MongoHQ instance
    def initialize(collection)
      # TODO: define expected behaviour for when MongoHQ URL not
      # specified or connection unsuccessful
      if ENV['MONGOHQ_URL']
        uri = URI.parse(ENV['MONGOHQ_URL'])
        @conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
        db = @conn.db(uri.path.gsub(/^\//, ''))
        # Save the collection with the given name: we're going to
        # use @coll to retrieve, find and insert entries
        @coll = db.collection(collection)
      end
    end

    def insert(entry)
      @coll.insert(entry)
    end

    # Returns true if a preset with a given name already exists,
    # false otherwise
    def exists?(query)
      @coll.find(query).count > 0
    end

    # Returns the array of ignored courses corresponding to a given
    # preset name, or nil if it doesn't exist
    def find(query)
      @coll.find(query).first
    end

    def close
      @conn.close
    end
  end
end
