module Genghis
  module Models
    class Database
      def initialize(client, name)
        @client = client
        @name   = name
      end

      def name
        database.name
      end

      def drop!
        database.connection.drop_database(database.name)
      end

      def create_collection(coll_name)
        fail Genghis::CollectionAlreadyExists.new(self, coll_name) if database.collection_names.include? coll_name
        database.create_collection coll_name
        Collection.new(database[coll_name])
      rescue
        raise Genghis::MalformedDocument, 'Invalid collection name'
      end

      def collections
        @collections ||= database.collections.map { |c| Collection.new(c) unless system_collection?(c) }.compact
      end

      def [](coll_name)
        fail Genghis::CollectionNotFound.new(self, coll_name) unless database.collection_names.include? coll_name
        Collection.new(database[coll_name])
      end

      def as_json(*)
        {
          :id          => database.name,
          :name        => database.name,
          :count       => collections.count,
          :collections => collections.map { |c| c.name },
          :stats       => stats,
        }
      rescue Mongo::InvalidNSName => e
        {
          :id    => @name,
          :name  => @name,
          :error => e.message,
        }
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def database
        @database ||= @client[@name]
      end

      def info
        @info ||= begin
          name = database.name
          database.connection['admin'].command(:listDatabases => true)['databases'].find do |db|
            db['name'] == name
          end
        end
      end

      def stats
        @stats ||= database.command(:dbStats => true)
      end

      def system_collection?(coll)
        [
          Mongo::DB::SYSTEM_NAMESPACE_COLLECTION,
          Mongo::DB::SYSTEM_INDEX_COLLECTION,
          Mongo::DB::SYSTEM_PROFILE_COLLECTION,
          Mongo::DB::SYSTEM_USER_COLLECTION,
          Mongo::DB::SYSTEM_JS_COLLECTION
        ].include?(coll.name)
      end
    end
  end
end
