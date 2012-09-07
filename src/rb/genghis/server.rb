require 'sinatra/base'
require 'sinatra/mustache'
require 'sinatra/json'
require 'sinatra/reloader'
require 'mongo'

module Genghis
  class Server < Sinatra::Base
    PAGE_LIMIT = 50

    enable :inline_templates
    register Sinatra::Reloader if development?

    helpers Sinatra::JSON
    set :json_encoder,      :to_json
    set :json_content_type, :json

    def request_json
      ::Genghis::JSON.decode request.body.read
    end

    def connection(server_name)
      server = servers[server_name] || not_found
      Mongo::Connection.from_uri(server[:dsn])
    end

    def server_info(server_name)
      server = servers[server_name] || not_found
      resp = { :id => server_name, :name => server_name, :editable => !server[:default] }
      if server[:error]
        resp.merge!({:error => server[:error]})
      else
        begin
          conn = connection(server_name)
        rescue Mongo::ConnectionFailure => ex
          resp.merge!({:error => ex.to_s})
        else
          databases = conn['admin'].command({:listDatabases => true})
          resp.merge!({
            :size      => databases['totalSize'],
            :count     => databases['databases'].count,
            :databases => databases['databases'].map {|db| db['name']}
          })
        end
      end
    end

    def database_info(server_name, database)
      conn = connection(server_name)
      collections = conn[database['name']].collections
      collections.reject! {|collection| collection.name.start_with?('system')}
      {
        :id => database['name'],
        :name => database['name'],
        :size => database['sizeOnDisk'],
        :count => collections.count,
        :collections => collections.map {|collection| collection.name}
      }
    end

    def collection_info(collection)
      {
        :id => collection.name,
        :name => collection.name,
        :count => collection.count,
        :indexes => collection.index_information.values
      }
    end

    def document_info(collection, page, query={})
      offset = PAGE_LIMIT * (page - 1)

      documents = collection.find(
        query,
        :limit => PAGE_LIMIT,
        :skip  => offset
      )

      {
        :count => documents.count,
        :page =>  page,
        :pages => [0, (documents.count / PAGE_LIMIT.to_f).ceil].max,
        :per_page => PAGE_LIMIT,
        :offset   => offset,
        :documents => documents.to_a
      }
    end

    def thunk_mongo_id(id)
      id =~ /^[a-f0-9]{24}$/i ? BSON::ObjectId(id) : id
    end

    def init_server(dsn)
      dsn = 'mongodb://'+dsn unless dsn.include? '://'

      server = {
        :name => dsn.sub(/^mongodb:\/\//, ''),
        :dsn  => dsn,
      }

      begin
        uri = ::Mongo::URIParser.new dsn

        # name this server something useful
        name = uri.host
        if user = uri.auths.map{|a| a['username']}.first
          name = "#{user}@#{name}"
        end
        name = "#{name}:#{uri.port}" unless uri.port == 27017
        server[:name] = name
      rescue Mongo::MongoArgumentError => e
        server[:error] = "Malformed server DSN: #{e.message}"
      end

      server
    end

    def init_servers(dsn_list, opts={})
      Hash[dsn_list.map { |dsn|
        server = init_server(dsn)
        server.merge(opts)
        [server[:name], server]
      }]
    end

    def save_servers
      server_names = servers.collect { |name, server| server[:dsn] unless server[:default] }.compact
      response.set_cookie(
        :genghis_rb_servers,
        :path => '/',
        :value => JSON.dump(server_names),
        :expires => Time.now + 60*60*24*365
      )
    end

    def default_servers
      @default_servers ||= begin
        env_var = (ENV['GENGHIS_SERVERS'] || '').split(';')
        init_servers(env_var, :default => true)
      end
    end

    def servers
      @servers ||= begin
        names   = ::JSON.parse(request.cookies['genghis_rb_servers'] || '[]')
        servers = default_servers.merge(init_servers(names))
        servers.empty? ? init_servers(['localhost']) : servers # fall back to 'localhost'
      end
    end

    get '/check-status' do
      alerts = []
      if ::BSON::BSON_CODER == ::BSON::BSON_RUBY
        msg = <<-MSG.strip.gsub(/\s+/, " ")
          <h4>MongoDB driver C extension not found.</h4>
          Install this extension for better performance: <code>gem install bson_ext</code>
        MSG
        alerts << {:level => 'warning', :msg => msg, :block => true}
      end

      unless defined? ::JSON::Ext
        msg = <<-MSG.strip.gsub(/\s+/, " ")
          <h4>JSON C extension not found.</h4>
          Falling back to the pure Ruby variant. <code>gem install json</code> for better performance.
        MSG
        alerts << {:level => 'warning', :msg => msg, :block => true}
      end

      json({:alerts => alerts})
    end

    get '/assets/style.css' do
      content_type 'text/css'
      Genghis::Server.templates['style.css'.intern].first
    end

    get '/assets/script.js' do
      content_type 'text/javascript'
      Genghis::Server.templates['script.js'.intern].first
    end

    get '*' do
      if request.xhr?
        pass
      else
        mustache 'index.html.mustache'.intern
      end
    end

    get '/servers' do
      json servers.keys.map {|server_name| server_info(server_name)}
    end

    post '/servers' do
      server = init_server(::JSON.parse(request.body.read)['name'])
      name   = server[:name]
      raise "Server #{name} already exists" unless servers[name].nil?
      @servers[name] = server
      save_servers
      json server_info name
    end

    get '/servers/:server' do |server|
      json server_info server
    end

    delete '/servers/:server' do
      not_found if servers[params[:server]].nil?
      @servers.delete(params[:server])
      save_servers
      json({ :success => true })
    end

    get '/servers/:server/databases' do |server|
      databases = connection(server)['admin'].command({:listDatabases => true})['databases']
      json databases.map {|database| database_info(server, database)}
    end

    post '/servers/:server/databases' do |server|
      name = ::JSON.parse(request.body.read)['name']
      connection(server)[name]['__genghis_tmp_collection__'].drop
      databases = connection(server)['admin'].command({:listDatabases => true})['databases']
      database  = databases.detect {|d| d['name'] == name}
      json database_info server, database
    end

    get '/servers/:server/databases/:database' do |server, db|
      databases = connection(server)['admin'].command({:listDatabases => true})['databases']
      database  = databases.detect {|d| d['name'] == db} || not_found
      json database_info server, database
    end

    delete '/servers/:server/databases/:database' do |server, db|
      not_found unless connection(server).database_names.include? db
      connection(server).drop_database db
      json :success => true
    end

    get '/servers/:server/databases/:database/collections' do |server, db|
      database = connection(server)[db]
      collections = database.collections.reject {|collection| collection.name.start_with?('system')}
      json collections.map {|collection| collection_info(collection)}
    end

    post '/servers/:server/databases/:database/collections' do |server, db|
      database = connection(server)[db]
      name = ::JSON.parse(request.body.read)['name']
      collection = database.create_collection name
      json collection_info collection
    end

    get '/servers/:server/databases/:database/collections/:collection' do |server, db, coll|
      not_found unless connection(server)[db].collection_names.include? coll
      json collection_info connection(server)[db][coll]
    end

    delete '/servers/:server/databases/:database/collections/:collection' do |server, db, coll|
      not_found unless connection(server)[db].collection_names.include? coll
      connection(server)[db][coll].drop
      json :success => true
    end

    get '/servers/:server/databases/:database/collections/:collection/documents' do |server, db, coll|
      collection = connection(server)[db][coll]
      page  = params.fetch('page', 1).to_i
      query = ::Genghis::JSON.decode(params.fetch('q', '{}'))
      json document_info(collection, page, query), :encoder => ::Genghis::JSON
    end

    post '/servers/:server/databases/:database/collections/:collection/documents' do |server, db, coll|
      collection = connection(server)[db][coll]
      id = collection.insert request_json
      document = collection.find_one('_id' => id) || not_found
      json document, :encoder => ::Genghis::JSON
    end

    get '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, db, coll, doc|
      document = connection(server)[db][coll].find_one('_id' => thunk_mongo_id(doc))
      json document, :encoder => ::Genghis::JSON
    end

    put '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, db, coll, doc|
      document = connection(server)[db][coll].find_and_modify \
        :query => {'_id' => thunk_mongo_id(doc)},
        :update => request_json,
        :new => true
      not_found unless document
      json document, :encoder => ::Genghis::JSON
    end

    delete '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, db, coll, doc|
      query      = {'_id' => thunk_mongo_id(doc)}
      collection = connection(server)[db][coll]
      collection.find_one(query) || not_found

      collection.remove query
      json :success => true
    end
  end
end
