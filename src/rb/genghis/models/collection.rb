require 'base64'

module Genghis
  module Models
    class Collection
      def initialize(collection)
        @collection = collection
      end

      def name
        @collection.name
      end

      def drop!
        @collection.drop
      end

      def insert(data)
        id = @collection.insert data
        @collection.find_one('_id' => id)
      end

      def remove(doc_id)
        query = {'_id' => thunk_mongo_id(doc_id)}
        raise Genghis::DocumentNotFound.new(self, doc_id) unless @collection.find_one(query)
        @collection.remove query
      end

      def update(doc_id, data)
        document = @collection.find_and_modify \
          :query  => {'_id' => thunk_mongo_id(doc_id)},
          :update => data,
          :new    => true

        raise Genghis::DocumentNotFound.new(self, doc_id) unless document
        document
      end

      def documents(query={}, page=1)
        Query.new(@collection, query, page)
      end

      def [](doc_id)
        doc = @collection.find_one('_id' => thunk_mongo_id(doc_id))
        raise Genghis::DocumentNotFound.new(self, doc_id) unless doc
        doc
      end

      def as_json(*)
        {
          :id      => @collection.name,
          :name    => @collection.name,
          :count   => @collection.count,
          :indexes => @collection.index_information.values,
        }
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def thunk_mongo_id(doc_id)
        if (doc_id[0] == '~')
          ::Genghis::JSON.decode(Base64.decode64(doc_id[1..-1]))
        else
          doc_id =~ /^[a-f0-9]{24}$/i ? BSON::ObjectId(doc_id) : doc_id
        end
      end
    end
  end
end
