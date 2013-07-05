require 'sinatra/base'
require 'sinatra/mustache'
require 'sinatra/json'
require 'sinatra/reloader'
require 'sinatra/streaming'
require 'mongo'

module Genghis
  class Server < Sinatra::Base
    # default to 'production' because yeah
    set :environment, :production

    enable :inline_templates

    helpers Sinatra::Streaming

    helpers Sinatra::JSON
    set :json_encoder,      :to_json
    set :json_content_type, :json

    helpers Genghis::Helpers

    def self.version
      Genghis::VERSION
    end


    ### Error handling ###

    helpers do
      def error_response(status, message)
        @status, @message = status, message
        @genghis_version = Genghis::VERSION
        @base_url = request.env['SCRIPT_NAME']
        if request.xhr?
          content_type :json
          error(status, {:error => message, :status => status}.to_json)
        else
          error(status, mustache('error.html.mustache'.intern))
        end
      end
    end

    error 400..599 do
      err = env['sinatra.error']
      error_response(err.respond_to?(:http_status) ? err.http_status : 500, err.message)
    end

    not_found do
      error_response(404, env['sinatra.error'].message.sub(/^Sinatra::NotFound$/, 'Not Found'))
    end


    ### Asset routes ###

    get '/assets/style.css' do
      content_type 'text/css'
      self.class.templates['style.css'.intern].first
    end

    get '/assets/script.js' do
      content_type 'text/javascript'
      self.class.templates['script.js'.intern].first
    end


    ### GridFS handling ###

    get '/servers/:server/databases/:database/collections/:collection/files/:document' do |server, database, collection, document|
      file = servers[server][database][collection].get_file document

      content_type file['contentType'] || 'application/octet-stream'
      attachment   file['filename'] || document

      stream do |out|
        file.each do |chunk|
          out << chunk
        end
      end
    end

    # delete '/servers/:server/databases/:database/collections/:collection/files/:document' do |server, database, collection, document|
    #   # ...
    #   json :success => true
    # end


    ### Default route ###

    get '*' do
      # Unless this is XHR, render index and let the client-side app handle routing
      pass if request.xhr?
      @genghis_version = Genghis::VERSION
      @base_url = request.env['SCRIPT_NAME']
      mustache 'index.html.mustache'.intern
    end


    ### Genghis API ###

    get '/check-status' do
      json :alerts => server_status_alerts
    end

    get '/servers' do
      json servers.values
    end

    post '/servers' do
      json add_server request_json['name']
    end

    get '/servers/:server' do |server|
      raise Genghis::ServerNotFound.new(server) if servers[server].nil?
      json servers[server]
    end

    delete '/servers/:server' do |server|
      remove_server server
      json :success => true
    end

    get '/servers/:server/databases' do |server|
      json servers[server].databases
    end

    post '/servers/:server/databases' do |server|
      json servers[server].create_database request_json['name']
    end

    get '/servers/:server/databases/:database' do |server, database|
      json servers[server][database]
    end

    delete '/servers/:server/databases/:database' do |server, database|
      servers[server][database].drop!
      json :success => true
    end

    get '/servers/:server/databases/:database/collections' do |server, database|
      json servers[server][database].collections
    end

    post '/servers/:server/databases/:database/collections' do |server, database|
      json servers[server][database].create_collection request_json['name']
    end

    get '/servers/:server/databases/:database/collections/:collection' do |server, database, collection|
      json servers[server][database][collection]
    end

    delete '/servers/:server/databases/:database/collections/:collection' do |server, database, collection|
      servers[server][database][collection].drop!
      json :success => true
    end

    get '/servers/:server/databases/:database/collections/:collection/documents' do |server, database, collection|
      genghis_json servers[server][database][collection].documents(query_param, page_param, explain_param)
    end

    post '/servers/:server/databases/:database/collections/:collection/documents' do |server, database, collection|
      document = servers[server][database][collection].insert request_genghis_json
      genghis_json document
    end

    get '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, database, collection, document|
      genghis_json servers[server][database][collection][document]
    end

    put '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, database, collection, document|
      document = servers[server][database][collection].update document, request_genghis_json
      genghis_json document
    end

    delete '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, database, collection, document|
      collection = servers[server][database][collection].remove document
      json :success => true
    end

    post '/servers/:server/databases/:database/collections/:collection/files' do |server, database, collection|
      document = servers[server][database][collection].put_file request_genghis_json
      genghis_json document
    end

    delete '/servers/:server/databases/:database/collections/:collection/files/:document' do |server, database, collection, document|
      servers[server][database][collection].delete_file document
      json :success => true
    end
  end
end
