require 'mongo'
require 'json'

module Genghis
  module Helpers
    PAGE_LIMIT = 50


    ### Genghis JSON responses ###

    def genghis_json(doc, *args)
      json(::Genghis::JSON.as_json(doc), *args)
    end


    ### Misc request parsing helpers ###

    def query_param
      ::Genghis::JSON.decode(params.fetch('q', '{}'))
    end

    def page_param
      params.fetch('page', 1).to_i
    end

    def request_json
      @request_json ||= ::JSON.parse request.body.read
    rescue
      raise Genghis::MalformedDocument.new
    end

    def request_genghis_json
      @request_genghis_json ||= ::Genghis::JSON.decode request.body.read
    rescue
      raise Genghis::MalformedDocument.new
    end

    def thunk_mongo_id(id)
      id =~ /^[a-f0-9]{24}$/i ? BSON::ObjectId(id) : id
    end


    ### Seemed like a good place to put this ###

    def server_status_alerts
      require 'rubygems'

      alerts = []

      if check_json_ext?
        msg = <<-MSG.strip.gsub(/\s+/, " ")
          <h4>JSON C extension not found.</h4>
          Falling back to the pure Ruby variant. <code>gem install json</code> for better performance.
        MSG
        alerts << {:level => 'warning', :msg => msg}
      end

      # It would be awesome if we didn't have to resort to this :)
      if Gem::Specification.respond_to? :find_all

        if check_bson_ext?
          Gem.refresh

          installed = Gem::Specification.find_all { |s| s.name == 'mongo' }.map { |s| s.version }.sort.last
          if Gem::Specification.find_all { |s| s.name == 'bson_ext' && s.version == installed }.empty?
            msg = <<-MSG.strip.gsub(/\s+/, " ")
              <h4>MongoDB driver C extension not found.</h4>
              Install this extension for better performance: <code>gem install bson_ext -v #{installed}</code>
            MSG
            alerts << {:level => 'warning', :msg => msg}
          else
            msg = <<-MSG.strip.gsub(/\s+/, " ")
              <h4>Restart required</h4>
              You have recently installed the <tt>bson_ext</tt> extension.
              Run <code>genghisapp&nbsp;--kill</code> then restart <code>genghisapp</code> to use it.
            MSG
            alerts << {:level => 'info', :msg => msg}
          end
        end

        unless ENV['GENGHIS_NO_UPDATE_CHECK']
          require 'open-uri'

          Gem.refresh

          latest    = nil
          installed = Gem::Specification.find_all { |s| s.name == 'genghisapp' }.map { |s| s.version }.sort.last
          running   = Gem::Version.new(Genghis::VERSION.gsub(/[\+_-]/, '.'))

          begin
            open('https://raw.github.com/bobthecow/genghis/master/VERSION') do |f|
              latest = Gem::Version.new(f.read.gsub(/[\+_-]/, '.'))
            end
          rescue
            # do nothing...
          end

          if latest && (installed || running) < latest
            msg = <<-MSG.strip.gsub(/\s+/, " ")
              <h4>A Genghis update is available</h4>
              You are running Genghis version <tt>#{Genghis::VERSION}</tt>. The current version is <tt>#{latest}</tt>.
              Visit <a href="http://genghisapp.com">genghisapp.com</a> for more information.
            MSG
            alerts << {:level => 'warning', :msg => msg}
          elsif installed && running < installed
            msg = <<-MSG.strip.gsub(/\s+/, " ")
              <h4>Restart required</h4>
              You have installed Genghis version <tt>#{installed}</tt> but are still running <tt>#{Genghis::VERSION}</tt>.
              Run <code>genghisapp&nbsp;--kill</code> then restart <code>genghisapp</code>.
            MSG
            alerts << {:level => 'info', :msg => msg}
          end
        end

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
      server = Genghis::Models::Server.new(dsn)
      raise Genghis::MalformedDocument.new(server.error) if server.error
      raise Genghis::ServerAlreadyExists.new(server.name) unless servers[server.name].nil?
      servers[server.name] = server
      save_servers
      server
    end

    def remove_server(name)
      raise Genghis::ServerNotFound.new(name) if servers[name].nil?
      @servers.delete(name)
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

    def is_ruby?
      (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ruby') || !(RUBY_PLATFORM =~ /java/)
    end

    def check_json_ext?
      !ENV['GENGHIS_NO_JSON_CHECK'] && is_ruby? && !defined?(::JSON::Ext)
    end

    def check_bson_ext?
      !ENV['GENGHIS_NO_BSON_CHECK'] && is_ruby? && !defined?(::BSON::BSON_C)
    end

  end
end
