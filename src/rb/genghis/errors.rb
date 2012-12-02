require 'sinatra'

module Genghis
  class Exception < ::Exception
  end

  class MalformedDocument < Exception
    def http_status; 400 end

    def initialize(msg=nil)
      @msg = msg
    end

    def message
      @msg || 'Malformed document'
    end
  end

  class NotFound < Exception
    def http_status; 404 end

    def message
      'Not found'
    end
  end

  class AlreadyExists < Exception
    def http_status; 400 end
  end

  class ServerNotFound < NotFound
    def initialize(name)
      @name = name
    end

    def message
      "Server '#{@name}' not found"
    end
  end

  class ServerAlreadyExists < AlreadyExists
    def initialize(name)
      @name = name
    end

    def message
      "Server '#{@name}' already exists"
    end
  end

  class DatabaseNotFound < NotFound
    def initialize(server, name)
      @server = server
      @name   = name
    end

    def message
      "Database '#{@name}' not found on '#{@server.name}'"
    end
  end

  class DatabaseAlreadyExists < AlreadyExists
    def initialize(server, name)
      @server = server
      @name   = name
    end

    def message
      "Database '#{@name}' already exists on '#{@server.name}'"
    end
  end


  class CollectionNotFound < NotFound
    def initialize(database, name)
      @database = database
      @name     = name
    end

    def message
      "Collection '#{@name}' not found in '#{@database.name}'"
    end
  end

  class GridFSNotFound < CollectionNotFound
    def message
      "GridFS collection '#{@name}' not found in '#{@database.name}'"
    end
  end

  class CollectionAlreadyExists < AlreadyExists
    def initialize(database, name)
      @database = database
      @name     = name
    end

    def message
      "Collection '#{@name}' already exists in '#{@database.name}'"
    end
  end

  class DocumentNotFound < NotFound
    def initialize(collection, doc_id)
      @collection = collection
      @doc_id     = doc_id
    end

    def message
      "Document '#{@doc_id}' not found in '#{@collection.name}'"
    end
  end

  class GridFileNotFound < DocumentNotFound
    def message
      "GridFS file '#{@doc_id}' not found"
    end
  end
end