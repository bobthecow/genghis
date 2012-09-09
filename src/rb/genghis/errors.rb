require 'sinatra'

module Genghis
  class ServerNotFound < Sinatra::NotFound
    def initialize(name)
      @name = name
    end

    def message
      "Server #{@name.inspect} not found"
    end
  end

  class DatabaseNotFound < Sinatra::NotFound
    def initialize(server, name)
      @server = server
      @name   = name
    end

    def message
      "Database #{@name.inspect} not found on #{@server.name.inspect}"
    end
  end

  class CollectionNotFound < Sinatra::NotFound
    def initialize(database, name)
      @database = database
      @name     = name
    end

    def message
      "Collection #{@name.inspect} not found in #{@database.name.inspect}"
    end
  end

  class DocumentNotFound < Sinatra::NotFound
    def initialize(collection, doc_id)
      @collection = collection
      @doc_id     = doc_id
    end

    def message
      "Document #{@doc_id.inspect} not found in #{@collection.name.inspect}"
    end
  end
end