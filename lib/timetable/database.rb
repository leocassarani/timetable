require 'mongo'

module Timetable
  class Database
    # Establish a connection to our MongoHQ instance
    def initialize(collection)
      if ENV['MONGOHQ_URL']
        uri = URI.parse(ENV['MONGOHQ_URL'])

        begin
          @conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
        rescue Mongo::MongoArgumentError => e
          raise RuntimeError, "Cannot connect to the database"
        end

        db = @conn.db(uri.path.gsub(/^\//, ''))
      else
        local = "mongodb://localhost:27017"
        @conn = Mongo::Connection.from_uri(local)
        db = @conn.db('timetable')
      end

      @coll = db.collection(collection)
    end

    def self.execute(collection, &block)
      db = Database.new(collection)
      retval = block.call(db)
      db.close
      retval
    end

    # Instance-method alternative to {Database.execute}
    def execute(&block)
      retval = block.call
      close
      retval
    end

    def insert(entry)
      @coll.insert(entry)
    end

    def update(obj, entry)
      raise ArgumentError, "_id field missing" unless obj.has_key? "_id"
      @coll.update({"_id" => obj["_id"]}, entry)
    end

    # Return true if a preset with a given name already exists,
    # false otherwise
    def exists?(query)
      @coll.find(query).count > 0
    end

    # Return the array of ignored courses corresponding to a given
    # preset name, or nil if it doesn't exist
    def find(query)
      @coll.find(query).first
    end

    def close
      @conn.close
    end
  end
end
