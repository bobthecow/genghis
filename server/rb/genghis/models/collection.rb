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

      def truncate!
        indexes = @collection.index_information
        @collection.drop
        indexes.each do |name, index|
          @collection.ensure_index index['key'], index
        end
      end

      def insert(data)
        begin
          id = @collection.insert data
        rescue Mongo::OperationFailure => e
          # going out on a limb here and assuming all of these are malformed...
          raise Genghis::MalformedDocument, e.result['errmsg']
        end

        @collection.find_one('_id' => id)
      end

      def remove(doc_id)
        query = {'_id' => thunk_mongo_id(doc_id)}
        fail Genghis::DocumentNotFound.new(self, doc_id) unless @collection.find_one(query)
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
          raise Genghis::MalformedDocument, e.result['errmsg']
        end

        fail Genghis::DocumentNotFound.new(self, doc_id) unless document
        document
      end

      def explain(query = {})
        @collection.find(query).explain
      end

      def documents(query = {}, fields = {}, sort = {}, page = 1)
        Query.new(@collection, query, fields, sort, page)
      end

      def [](doc_id)
        doc = @collection.find_one('_id' => thunk_mongo_id(doc_id))
        fail Genghis::DocumentNotFound.new(self, doc_id) unless doc
        doc
      end

      def put_file(data)
        unless (file = data.delete('file'))
          fail Genghis::MalformedDocument, 'Missing file'
        end

        opts = {}
        data.each do |k, v|
          case k
          when 'filename'
            opts[:filename] = v
          when 'metadata'
            opts[:metadata] = v unless v.empty?
          when '_id'
            opts[:_id]      = v
          when 'contentType'
            opts[:content_type] = v
          else
            fail Genghis::MalformedDocument, "Unexpected property: '#{k}'"
          end
        end

        id = grid.put(decode_file(file), opts)
        self[id]
      end

      def get_file(doc_id)
        begin
          doc = grid.get(thunk_mongo_id(doc_id))
        rescue Mongo::GridFileNotFound
          raise Genghis::GridFileNotFound.new(self, doc_id)
        end

        fail Genghis::DocumentNotFound.new(self, doc_id) unless doc
        fail Genghis::GridFileNotFound.new(self, doc_id) unless grid_file?(doc)

        doc
      end

      def delete_file(doc_id)
        begin
          grid.get(thunk_mongo_id(doc_id))
        rescue Mongo::GridFileNotFound
          raise Genghis::GridFileNotFound.new(self, doc_id)
        end

        res = grid.delete(thunk_mongo_id(doc_id))

        fail Genghis::Exception, res['err'] unless res['ok']
      end

      def as_json(*)
        {
          :id      => @collection.name,
          :name    => @collection.name,
          :count   => @collection.count,
          :indexes => @collection.index_information.values,
          :stats   => @collection.stats,
        }
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def thunk_mongo_id(doc_id)
        if doc_id.is_a? BSON::ObjectId
          doc_id
        elsif doc_id[0..0] == '~'
          doc_id = Base64.decode64(doc_id[1..-1])
          ::Genghis::JSON.decode("{\"_id\":#{doc_id}}")['_id']
        else
          doc_id =~ /^[a-f0-9]{24}$/i ? BSON::ObjectId(doc_id) : doc_id
        end
      end

      def grid_collection?
        name.end_with? '.files'
      end

      def grid
        Genghis::GridFSNotFound.new(@collection.db, name) unless grid_collection?
        @grid ||= Mongo::Grid.new(@collection.db, name.sub(/\.files$/, ''))
      end

      def grid_file?(doc)
        !!doc['chunkSize']
      end

      def decode_file(data)
        unless data =~ /^data:[^;]+;base64,/
          fail Genghis::MalformedDocument, 'File must be a base64 encoded data: URI'
        end

        Base64.strict_decode64(data.sub(/^data:[^;]+;base64,/, '').strip)
      rescue ArgumentError
        raise Genghis::MalformedDocument, 'File must be a base64 encoded data: URI'
      end
    end
  end
end
