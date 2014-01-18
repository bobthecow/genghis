module Genghis
  module Models
    class Query
      PAGE_LIMIT = 50

      def initialize(collection, query = {}, fields = {}, page = 1)
        @collection = collection
        @query      = query
        @fields     = fields
        @page       = page
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
        opts = {:limit => PAGE_LIMIT, :skip => offset}
        opts[:fields] = @fields unless @fields.empty?
        @documents ||= @collection.find(@query, opts)
      end
    end
  end
end
