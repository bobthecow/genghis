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
        begin
          id = @collection.insert data
        rescue Mongo::OperationFailure => e
          # going out on a limb here and assuming all of these are malformed...
          raise Genghis::MalformedDocument.new(e.result['errmsg'])
        end

        @collection.find_one('_id' => id)
      end

      def remove(doc_id)
        query = {'_id' => thunk_mongo_id(doc_id)}
        raise Genghis::DocumentNotFound.new(self, doc_id) unless @collection.find_one(query)
        @collection.remove query
      end

      def update(doc_id, data)
        begin
          document = @collection.find_and_modify \
            :query  => {'_id' => thunk_mongo_id(doc_id)},
            :update => data,
            :new    => true
        rescue Mongo::OperationFailure => e
          # going out on a limb here and assuming all of these are malformed...
          raise Genghis::MalformedDocument.new(e.result['errmsg'])
        end

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

      def get_file(doc_id)
        begin
          doc = grid.get(thunk_mongo_id(doc_id))
        rescue Mongo::GridFileNotFound
          raise Genghis::GridFileNotFound.new(self, doc_id)
        end

        raise Genghis::DocumentNotFound.new(self, doc_id) unless doc
        raise Genghis::GridFileNotFound.new(self, doc_id) unless is_grid_file?(doc)

        doc
      end

      def delete_file(doc_id)
        begin
          grid.get(thunk_mongo_id(doc_id))
        rescue Mongo::GridFileNotFound
          raise Genghis::GridFileNotFound.new(self, doc_id)
        end

        res = grid.delete(thunk_mongo_id(doc_id))

        raise Genghis::Exception.new res['err'] unless res['ok']
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

      def is_grid_collection?
        name.end_with? '.files'
      end

      def grid
        Genghis::GridFSNotFound.new(@collection.db, name) unless is_grid_collection?
        @grid ||= Mongo::Grid.new(@collection.db, name.sub(/\.files$/, ''))
      end

      def is_grid_file?(doc)
        !! doc['chunkSize']
      end
    end
  end
end
