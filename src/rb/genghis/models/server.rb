module Genghis
  module Models
    class Server
      attr_reader   :name
      attr_reader   :dsn
      attr_accessor :default

      def initialize(dsn)
        dsn = 'mongodb://'+dsn unless dsn.include? '://'

        begin
          uri = ::Mongo::URIParser.new dsn

          # name this server something useful
          name = uri.host
          if user = uri.auths.map{|a| a['username']}.first
            name = "#{user}@#{name}"
          end
          name = "#{name}:#{uri.port}" unless uri.port == 27017
          @name = name
        rescue Mongo::MongoArgumentError => e
          @error = "Malformed server DSN: #{e.message}"
        end
        @dsn = dsn
      end

      def create_database(db_name)
        connection[db_name]['__genghis_tmp_collection__'].drop
        Database.new(connection[db_name])
      end

      def databases
        connection['admin'].command({:listDatabases => true})['databases'].map do |db|
          Database.new(connection[db['name']])
        end
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
          rescue Mongo::ConnectionFailure => ex
            json.merge!({:error => ex.to_s})
          else
            json.merge!({
              :size      => info['totalSize'],
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

      def connection
        @connection ||= Mongo::Connection.from_uri(@dsn)
      end

      def info
        @info ||= connection['admin'].command({:listDatabases => true})
      end
    end
  end
end