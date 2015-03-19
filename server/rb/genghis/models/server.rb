module Genghis
  module Models
    class Server
      attr_reader   :name
      attr_reader   :dsn
      attr_reader   :error
      attr_accessor :default

      @default = false

      def initialize(dsn)
        dsn = 'mongodb://' + dsn unless dsn.include? '://'

        begin
          dsn, uri = get_dsn_and_uri(extract_extra_options(dsn))

          # name this server something useful
          name = uri.host

          if (user = uri.auths.map { |a| a[:username] || a['username'] }.first)
            name = "#{user}@#{name}"
          end

          name = "#{name}:#{uri.port}" unless uri.port == 27017

          if (db = uri.auths.map { |a| a[:db_name] || a['db_name'] }.first)
            unless db == 'admin'
              name = "#{name}/#{db}"
              @db = db
            end
          end

          @name = name
        rescue Mongo::MongoArgumentError
          @error = 'Malformed server DSN'
          @name  = dsn
        end
        @dsn = dsn
      end

      def create_database(db_name)
        fail Genghis::DatabaseAlreadyExists.new(self, db_name) if db_exists? db_name
        begin
          client[db_name]['__genghis_tmp_collection__'].drop
        rescue Mongo::InvalidNSName
          raise Genghis::MalformedDocument, 'Invalid database name'
        end
        Database.new(client, db_name)
      end

      def databases
        info['databases'].map { |db| Database.new(client, db['name']) }
      end

      def [](db_name)
        fail Genghis::DatabaseNotFound.new(self, db_name) unless db_exists? db_name
        Database.new(client, db_name)
      end

      def as_json(*)
        json = {
          :id       => @name,
          :name     => @name,
          :editable => !@default,
        }

        if @error
          json.merge!(:error => @error)
        else
          begin
            client
            info
          rescue Mongo::AuthenticationError => e
            json.merge!(:error => "Authentication error: #{e.message}")
          rescue Mongo::ConnectionFailure => e
            json.merge!(:error => "Connection error: #{e.message}")
          rescue Mongo::OperationFailure => e
            json.merge!(:error => "Connection error: #{e.result['errmsg']}")
          else
            json.merge!(
              :size      => info['totalSize'].to_i,
              :count     => info['databases'].count,
              :databases => info['databases'].map { |db| db['name'] },
            )
          end
        end

        json
      end

      def to_json(*)
        as_json.to_json
      end

      private

      def get_dsn_and_uri(dsn)
        [dsn, ::Mongo::URIParser.new(dsn)]
      rescue Mongo::MongoArgumentError => e
        raise e unless e.message.include? 'MongoDB URI must include username'
        # We'll try one more time...
        dsn = dsn.sub(/\/?$/, '/admin')
        [dsn, ::Mongo::URIParser.new(dsn)]
      end

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
              fail Mongo::MongoArgumentError, "Unexpected #{opt} option value: #{value}"
            end
            @opts[:connect_timeout] = (value.to_f / 1000)
          when 'ssl'
            unless value == 'true'
              fail Mongo::MongoArgumentError, "Unexpected #{opt} option value: #{value}"
            end
            @opts[opt.to_sym] = true
          else
            fail Mongo::MongoArgumentError, "Unknown option #{opt}"
          end
        end
        opts = Rack::Utils.build_query keep
        opts.empty? ? host : [host, opts].join('?')
      end

      def client
        @client ||= Mongo::MongoClient.from_uri(@dsn, {:connect_timeout => 1, :w => 1}.merge(@opts))
      rescue OpenSSL::SSL::SSLError
        raise Mongo::ConnectionFailure, 'SSL connection error'
      rescue StandardError => e
        fail Mongo::ConnectionFailure, e.message
      end

      def info
        @info ||= begin
          if @db.nil?
            client['admin'].command(:listDatabases => true)
          else
            stats = client[@db].command(:dbStats => true)
            {
              'databases' => [{'name' => @db}],
              'totalSize' => stats['fileSize']
            }
          end
        end
      end

      def db_exists?(db_name)
        if @db.nil?
          client.database_names.include? db_name
        else
          @db == db_name
        end
      end
    end
  end
end
