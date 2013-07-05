module Genghis
  module Models
    class Query
      PAGE_LIMIT = 50

      def initialize(collection, query={}, page=1, explain=false)
        @collection = collection
        @page       = page
        @query      = query
        @explain    = explain
      end

      def as_json(*)
        {
          :count     => documents.count,
          :page      => @page,
          :pages     => pages,
          :per_page  => PAGE_LIMIT,
          :offset    => offset,
          :documents => documents.to_a
        }
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def pages
        [0, (documents.count / PAGE_LIMIT.to_f).ceil].max
      end

      def offset
        PAGE_LIMIT * (@page - 1)
      end

      def documents
        return @documents if @documents
        @documents ||= @collection.find(@query, :limit => PAGE_LIMIT, :skip => offset)

        # Explain returns 1 doc but we expose it as a collection with 1 record
        # and a fake ID
        if @explain
          @documents = [@documents.explain()]
          @documents[0]['_id'] = 'explain'
        end

        @documents
      end

    end
  end
end
