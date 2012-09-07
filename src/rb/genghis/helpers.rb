require 'mongo'
require 'json'

module Genghis
  module Helpers
    PAGE_LIMIT = 50


    ### Misc request parsing helpers ###

    def query_param
      ::Genghis::JSON.decode(params.fetch('q', '{}'))
    end

    def page_param
      params.fetch('page', 1).to_i
    end

    def request_json
      ::JSON.parse request.body.read
    end

    def request_genghis_json
      ::Genghis::JSON.decode request.body.read
    end

    def thunk_mongo_id(id)
      id =~ /^[a-f0-9]{24}$/i ? BSON::ObjectId(id) : id
    end


    ### Seemed like a good place to put this ###

    def server_status_alerts
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

      alerts
    end


    ### Server management ###

    def servers
      @servers ||= begin
        dsn_list = ::JSON.parse(request.cookies['genghis_rb_servers'] || '[]')
        servers  = default_servers.merge(init_servers(dsn_list))
        servers.empty? ? init_servers(['localhost']) : servers # fall back to 'localhost'
      end
    end

    def default_servers
      @default_servers ||= init_servers((ENV['GENGHIS_SERVERS'] || '').split(';'), :default => true)
    end

    def init_servers(dsn_list, opts={})
      Hash[dsn_list.map { |dsn|
        server = Genghis::Models::Server.new(dsn)
        server.default = opts[:default] || false
        [server.name, server]
      }]
    end

    def add_server(dsn)
      raise "Server #{name} already exists" unless servers[name].nil?
      server = Genghis::Models::Server.new!(dsn)
      servers[server.name] = server
      save_servers
      server
    end

    def remove_server(name)
      not_found if servers[name].nil?
      @servers.delete(servers[name])
      save_servers
    end

    def save_servers
      dsn_list = servers.collect { |name, server| server.dsn unless server.default }.compact
      response.set_cookie(
        :genghis_rb_servers,
        :path    => '/',
        :value   => dsn_list.to_json,
        :expires => Time.now + 60*60*24*365
      )
    end

  end
end