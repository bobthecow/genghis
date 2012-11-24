module Genghis
  module Models
    class Server
      attr_reader   :name
      attr_reader   :dsn
      attr_accessor :default

      @default = false

      def initialize(dsn)
        dsn = 'mongodb://'+dsn unless dsn.include? '://'

        begin
          dsn = extract_extra_options(dsn)
          uri = ::Mongo::URIParser.new dsn

          # name this server something useful
          name = uri.host

          if user = uri.auths.map{|a| a['username']}.first
            name = "#{user}@#{name}"
          end

          name = "#{name}:#{uri.port}" unless uri.port == 27017

          if db = uri.auths.map{|a| a['db_name']}.first
            unless db == 'admin'
              name = "#{name}/#{db}"
              @db = db
            end
          end

          @name = name
        rescue Mongo::MongoArgumentError => e
          @error = "Malformed server DSN: #{e.message}"
          @name  = dsn
        end
        @dsn = dsn
      end

      def create_database(db_name)
        raise Genghis::DatabaseAlreadyExists.new(self, db_name) if connection.database_names.include? db_name
        begin
          connection[db_name]['__genghis_tmp_collection__'].drop
        rescue Mongo::InvalidNSName
          raise Genghis::MalformedDocument.new('Invalid database name')
        end
        Database.new(connection[db_name])
      end

      def databases
        info['databases'].map { |db| Database.new(connection[db['name']]) }
      end

      def [](db_name)
        raise Genghis::DatabaseNotFound.new(self, db_name) unless connection.database_names.include? db_name
        Database.new(connection[db_name])
      end

      def as_json(*)
        json = {
          :id       => @name,
          :name     => @name,
          :editable => !@default,
        }

        if @error
          json.merge!({:error => @error})
        else
          begin
            connection
            info
          rescue Mongo::ConnectionFailure => e
            json.merge!({:error => "Connection error: #{e.message}"})
          rescue Mongo::OperationFailure => e
            json.merge!({:error => "Connection error: #{e.result['errmsg']}"})
          else
            json.merge!({
              :size      => info['totalSize'].to_i,
              :count     => info['databases'].count,
              :databases => info['databases'].map { |db| db['name'] },
            })
          end
        end

        json
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def extract_extra_options(dsn)
        host, opts = dsn.split('?', 2)

        keep  = {}
        @opts = {}
        Rack::Utils.parse_query(opts).each do |opt, value|
          case opt
          when 'replicaSet'
            keep[opt] = value
          when 'connectTimeoutMS'
            unless value =~ /^\d+$/
              raise Mongo::MongoArgumentError.new("Unexpected #{opt} option value: #{value}")
            end
            @opts[:connect_timeout] = (value.to_f / 1000)
          when 'ssl'
            unless value == 'true'
              raise Mongo::MongoArgumentError.new("Unexpected #{opt} option value: #{value}")
            end
            @opts[opt.to_sym] = true
          else
            raise Mongo::MongoArgumentError.new("Unknown option #{opt}")
          end
        end
        opts = Rack::Utils.build_query keep
        opts.empty? ? host : [host, opts].join('?')
      end

      def connection
        @connection ||= Mongo::Connection.from_uri(@dsn, {:connect_timeout => 1}.merge(@opts))
      rescue OpenSSL::SSL::SSLError => e
        raise Mongo::ConnectionFailure.new('SSL connection error')
      rescue StandardError => e
        raise Mongo::ConnectionFailure.new(e.message)
      end

      def info
        @info ||= begin
          if @db.nil?
            connection['admin'].command({:listDatabases => true})
          else
            {
              'databases' => [{'name' => @db}],
              'totalSize' => connection[@db].stats['fileSize']
            }
          end
        end
      end
    end
  end
end