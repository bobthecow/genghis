require 'sinatra/base'
require 'sinatra/mustache'
require 'sinatra/json'
require 'sinatra/reloader'
require 'mongo'

module Genghis
  class Server < Sinatra::Base
    enable :inline_templates

    register Sinatra::Reloader if development?

    helpers Sinatra::JSON
    set :json_encoder,      :to_json
    set :json_content_type, :json

    helpers Genghis::Helpers


    ### Asset routes ###

    get '/assets/style.css' do
      content_type 'text/css'
      Genghis::Server.templates['style.css'.intern].first
    end

    get '/assets/script.js' do
      content_type 'text/javascript'
      Genghis::Server.templates['script.js'.intern].first
    end


    ### Default route ###

    get '*' do
      # Unless this is XHR, render index and let the client-side app handle routing
      pass if request.xhr?
      mustache 'index.html.mustache'.intern
    end


    ### Genghis API ###

    get '/check-status' do
      json({:alerts => server_status_alerts})
    end

    get '/servers' do
      json servers.values
    end

    post '/servers' do
      json add_server request_json['name']
    end

    get '/servers/:server' do |server|
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
      json servers[server][database][collection].documents(query_param, page_param), :encoder => ::Genghis::JSON
    end

    post '/servers/:server/databases/:database/collections/:collection/documents' do |server, database, collection|
      document = servers[server][database][collection].insert request_genghis_json
      json document, :encoder => ::Genghis::JSON
    end

    get '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, database, collection, document|
      json servers[server][database][collection][document], :encoder => ::Genghis::JSON
    end

    put '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, database, collection, document|
      document = servers[server][database][collection].update document, request_genghis_json
      json document, :encoder => ::Genghis::JSON
    end

    delete '/servers/:server/databases/:database/collections/:collection/documents/:document' do |server, database, collection, document|
      collection = servers[server][database][collection].remove document
      json :success => true
    end
  end
end
