#encoding: utf-8


require 'spec_helper'
require 'faraday'
require 'mongo'

genghis_backends.each do |backend|
  describe "Genghis #{backend} API" do
    before :all do
      @api = start_backend backend
      @api.headers['Accept'] = 'application/json'
      @api.headers['X-Requested-With'] = 'XMLHttpRequest'
    end

    it 'boots up' do
      res = @api.get '/check-status'
      res.status.should eq 200
      res.body.should match_json_expression({
        alerts: Array
      })
    end

    it 'returns 404 when an unknown URL is requested' do
      res = @api.get '/bacon-sammitch'
      res.status.should eq 404
      res.body.should match_json_expression \
        error:  'Not Found',
        status: 404
    end

    context 'servers' do
      describe 'GET /servers' do
        it 'always contains localhost' do
          res = @api.get '/servers'
          res.status.should eq 200
          res.body.should match_json_expression \
            [
              {
                id:        'localhost',
                name:      'localhost',
                editable:  true,
                size:      Fixnum,
                count:     Fixnum,
                databases: Array
              }
            ]
        end
      end

      describe 'POST /servers' do
        it 'creates a server when given a valid DSN' do
          res = @api.post do |req|
            req.url '/servers'
            req.headers['Content-Type'] = 'application/json'
            req.body = { url: 'mongo.example.com:27017' }.to_json
          end

          res.status.should eq 200
          res.headers['content-type'].should start_with 'application/json'
          res.body.should match_json_expression \
            id:        'mongo.example.com',
            name:      'mongo.example.com',
            editable:  true,
            error:     String # mongo.example.com is valid, but unable to connect
        end

        it 'remembers old servers when you add a new one' do
          res = @api.post do |req|
            req.url '/servers'
            req.headers['Content-Type'] = 'application/json'
            req.headers['Cookie'] = 'genghis_servers=%7B%22localhost%22%3A%22mongodb%3A%5C%2F%5C%2Flocalhost%3A27017%22%7D'
            req.body = { url: 'mongo.example.com:27017' }.to_json
          end
          res.headers['set-cookie'].should_not be_empty
          servers_cookie = URI.decode(res.headers['set-cookie'].split(';').first.split('=').last)
          servers_cookie.should match_json_expression \
            [
              %r{^(mongodb://)?localhost(:27017)?$},
              %r{^(mongodb://)?mongo.example.com(:27017)?$}
            ]
        end


        it 'returns 400 if the DSN is empty' do
          res = @api.post do |req|
            req.url '/servers'
            req.headers['Content-Type'] = 'application/json'
            req.body = { url: '' }.to_json
          end

          res.status.should eq 400
          res.body.should match_json_expression \
            error:  'Malformed server DSN',
            status: 400
        end

        it 'returns 400 if the DSN is not valid' do
          res = @api.post do |req|
            req.url '/servers'
            req.headers['Content-Type'] = 'application/json'
            req.body = { url: 'http://foo/bar' }.to_json
          end

          res.status.should eq 400
          res.body.should match_json_expression \
            error:  'Malformed server DSN',
            status: 400
        end
      end

      describe 'GET /servers/:server' do
        it 'returns server info' do
          res = @api.get '/servers/localhost'
          res.status.should eq 200
          res.body.should match_json_expression \
            id:        'localhost',
            name:      'localhost',
            editable:  true,
            size:      Fixnum,
            count:     Fixnum,
            databases: Array
        end

        it 'returns 404 when the server is not found' do
          res = @api.get '/servers/not-a-real-server'
          res.status.should eq 404
        end
      end

      describe 'DELETE /servers/:server' do
        it 'deletes a server if it exists' do
          res = @api.delete do |req|
            req.url '/servers/mongo.example.com'
            servers = CGI::escape('["mongodb:\/\/mongo.example.com"]')
            req.headers['Cookie'] = 'genghis_servers=%s;genghis_rb_servers=%s' % [servers, servers]
          end
          res.status.should eq 200
        end

        it 'returns 404 when the server is not found' do
          res = @api.delete '/servers/not-a-real-server'
          res.status.should eq 404
        end
      end
    end

    context 'databases' do
      before :all do
        @conn = Mongo::Connection.new
        @conn.drop_database('__genghis_spec_test__') if @conn.database_names.include? '__genghis_spec_test__'
        @conn['__genghis_spec_test__']['__tmp__'].drop
      end

      after :all do
        @conn.drop_database '__genghis_spec_test__'
      end

      describe 'GET /servers/:server/databases' do
        it 'returns a list of databases' do
          res = @api.get '/servers/localhost/databases'

          res.status.should eq 200
          res.body.should match_json_expression \
            [
              {
                id:          '__genghis_spec_test__',
                name:        '__genghis_spec_test__',
                count:       0,
                collections: [],
                stats:       Hash
              }
            ].ignore_extra_values!
        end
      end

      describe 'POST /servers/:server/databases' do
        after :all do
          @conn.drop_database '__genghis_spec_create_db_test__'
        end

        it 'creates a new database' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: '__genghis_spec_create_db_test__' }.to_json
          end

          res.status.should eq 200
          res.headers['content-type'].should start_with 'application/json'
          res.body.should match_json_expression \
            id:          '__genghis_spec_create_db_test__',
            name:        '__genghis_spec_create_db_test__',
            count:       0,
            collections: [],
            stats:       Hash
        end

        it 'returns 400 unless given a valid database name' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: '' }.to_json
          end

          res.status.should eq 400
          res.body.should match_json_expression \
            error:  'Invalid database name',
            status: 400
        end

        it 'returns 400 if db already exists' do
          @conn['__genghis_spec_create_db_test__']['__tmp__'].drop
          res = @api.post do |req|
            req.url '/servers/localhost/databases'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: '__genghis_spec_create_db_test__' }.to_json
          end

          res.status.should eq 400
          res.body.should match_json_expression \
            error:  "Database '__genghis_spec_create_db_test__' already exists on 'localhost'",
            status: 400
        end
      end

      describe 'GET /servers/:server/databases/:db' do
        it 'returns database info' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__'

          res.status.should eq 200
          res.body.should match_json_expression \
            id:          '__genghis_spec_test__',
            name:        '__genghis_spec_test__',
            count:       0,
            collections: [],
            stats:       Hash
        end

        it 'returns 404 when the database is not found' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_delete_fake_db_test__'
          res.status.should eq 404
        end
      end

      describe 'DELETE /servers/:server/databases/:db' do
        it 'deletes a database if it exists' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__'
          res.status.should eq 200
          @conn.database_names.include?('__genghis_spec_test__').should eq false
        end

        it 'returns 404 when the database is not found' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_delete_fake_db_test__'
          res.status.should eq 404
        end
      end
    end

    context 'collections' do
      before :all do
        @conn = Mongo::Connection.new
        @conn.drop_database('__genghis_spec_test__') if @conn.database_names.include? '__genghis_spec_test__'
        @db = @conn['__genghis_spec_test__']
        @db.create_collection 'spec_collection'
      end

      after :all do
        @conn.drop_database '__genghis_spec_test__'
      end

      describe 'GET /servers/:server/databases/:db/collections' do
        it 'returns a list of collections' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections'

          res.status.should eq 200
          res.body.should match_json_expression \
            [
              {
                id:      'spec_collection',
                name:    'spec_collection',
                count:   0,
                indexes: Array,
                stats:   Hash,
              }
            ]
        end

        it 'returns 404 if the database is not found' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_fake_db__/collections'
          res.status.should eq 404
        end
      end

      describe 'POST /servers/:server/databases/:db/collections' do
        it 'creates a new collection' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: 'spec_create_collection' }.to_json
          end

          res.status.should eq 200
          res.headers['content-type'].should start_with 'application/json'
          res.body.should match_json_expression \
            id:      'spec_create_collection',
            name:    'spec_create_collection',
            count:   0,
            indexes: Array,
            stats:   Hash
        end

        it 'returns 400 unless given a valid collection name' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: '' }.to_json
          end

          res.status.should eq 400
          res.body.should match_json_expression \
            error:  'Invalid collection name',
            status: 400
        end

        it 'returns 400 if collection already exists' do
          @conn['__genghis_spec_test__'].create_collection 'already_exists'
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: 'already_exists' }.to_json
          end

          res.status.should eq 400
          res.body.should match_json_expression \
            error:  "Collection 'already_exists' already exists in '__genghis_spec_test__'",
            status: 400
        end
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll' do
        it 'returns collection info' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_collection'

          res.status.should eq 200
          res.body.should match_json_expression \
            id:      'spec_collection',
            name:    'spec_collection',
            count:   0,
            indexes: Array,
            stats:   Hash
        end

        it 'returns 404 when the database is not found' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_fake_db__/collections/spec_collection'
          res.status.should eq 404
        end

        it 'returns 404 when the collection is not found' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/fake_collection'
          res.status.should eq 404
        end
      end

      describe 'DELETE /servers/:server/databases/:db/collections/:coll' do
        it 'deletes a collection if it exists' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/spec_collection'
          res.status.should eq 200
          @conn['__genghis_spec_test__'].collection_names.include?('spec_collection').should eq false
        end

        it 'returns 404 when the database is not found' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_fake_db__/collections/spec_collection'
          res.status.should eq 404
        end

        it 'returns 404 when the database is not found' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/fake_collection'
          res.status.should eq 404
        end
      end

      context 'collections with weird names' do
        before :all do
          @conn = Mongo::Connection.new
          @conn.drop_database('__genghis_spec_test__') if @conn.database_names.include? '__genghis_spec_test__'
          @db = @conn['__genghis_spec_test__']
          @db.create_collection 'one with a few spaces'
          @db.create_collection 'another.with.dots'
          @db.create_collection 'forward/slashes'
          @db.create_collection 'back\\slashes'
          @db.create_collection 'and unicode…'
        end

        after :all do
          @conn.drop_database '__genghis_spec_test__'
        end

        describe 'GET /servers/:server/databases/:db/collections' do
          it 'can handle collections with weird names' do
            res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections'
            res.status.should eq 200
            res.body.should match_json_expression \
              [
                {
                  id:      'one with a few spaces',
                  name:    'one with a few spaces',
                  count:   0,
                  indexes: Array,
                  stats:   Hash
                },
                {
                  id:      'another.with.dots',
                  name:    'another.with.dots',
                  count:   0,
                  indexes: Array,
                  stats:   Hash
                },
                {
                  id:      'forward/slashes',
                  name:    'forward/slashes',
                  count:   0,
                  indexes: Array,
                  stats:   Hash
                },
                {
                  id:      'back\\slashes',
                  name:    'back\\slashes',
                  count:   0,
                  indexes: Array,
                  stats:   Hash
                },
                {
                  id:      'and unicode…',
                  name:    'and unicode…',
                  count:   0,
                  indexes: Array,
                  stats:   Hash
                },
              ]
          end
        end

        describe 'POST /servers/:server/databases/:db/collections' do
          it 'creates a new collection just like you would expect' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections'
              req.headers['Content-Type'] = 'application/json'
              req.body = { name: 'a b.c/d\\e…' }.to_json
            end

            res.status.should eq 200
            res.headers['content-type'].should start_with 'application/json'
            res.body.should match_json_expression \
              id:      'a b.c/d\\e…',
              name:    'a b.c/d\\e…',
              count:   0,
              indexes: Array,
              stats:   Hash
          end
        end

        describe 'GET /servers/:server/databases/:db/collections/:coll' do
          before :all do
            @db.create_collection 'foo bar.baz/qux\\quux…'
          end

          it 'returns collection info' do
            res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/foo%20bar.baz%2Fqux%5Cquux%E2%80%A6'

            res.status.should eq 200
            res.body.should match_json_expression \
              id:      'foo bar.baz/qux\\quux…',
              name:    'foo bar.baz/qux\\quux…',
              count:   0,
              indexes: Array,
              stats:   Hash
          end
        end
      end
    end

    context 'documents' do
      before :all do
        @conn = Mongo::Connection.new
        @conn.drop_database('__genghis_spec_test__') if @conn.database_names.include? '__genghis_spec_test__'
        @db = @conn['__genghis_spec_test__']
        @coll = @db.create_collection 'spec_docs'

        @id_pattern = {
          :$genghisType => 'ObjectId',
          :$value       => String
        }
      end

      after :all do
        @conn.drop_database '__genghis_spec_test__'
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll/documents' do
        it 'returns a list of documents' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'

          res.status.should eq 200
          res.body.should match_json_expression \
            count:     Fixnum,
            page:      Fixnum,
            pages:     Fixnum,
            per_page:  50,
            offset:    Fixnum,
            documents: Array
        end

        it 'returns 404 if the collection is not found' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_fake_docs/documents'
          res.status.should eq 404
        end
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll/explain?q=' do

        let(:res)  { @api.get "/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/explain?q=#{URI::encode('{}')}" }
        let(:body) { res.body }

        it 'returns 200 status' do
          res.status.should eq 200
        end

        it 'has some basic index info' do
          body.should match_json_expression({
            cursor:      'BasicCursor',
            indexOnly:   false,
            allPlans:    Array,
            server:      String
          }.ignore_extra_keys)
        end
      end

      describe 'POST /servers/:server/databases/:db/collections/:coll/documents' do
        it 'creates a document' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { foo: 'FOO!', bar: 123, baz: { qux: 4.56, quux: false } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            foo: 'FOO!',
            bar: 123,
            baz: {
              qux:  4.56,
              quux: false
            }
        end

        it 'creates a document with a specified id' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { _id: 1, foo: 'bar' }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: 1,
            foo: 'bar'
        end

        it 'handles NaN values' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { foo: { '$genghisType' => 'NaN' } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            foo: {
              '$genghisType' => 'NaN'
            }
        end

        it 'supports Timestamps' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { foo: { '$genghisType' => 'Timestamp', '$value' => { '$t' => 123, '$i' => 456 } } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            foo: {
              '$genghisType' => 'Timestamp',
              '$value' => {
                '$t' => 123,
                '$i' => 456,
              }
            }
        end

        it 'does not mangle dates' do
          dates = [
            '0001-01-01T01:01:01Z',
            '0001-01-01T01:01:01.1Z',
            '0001-01-01T01:01:01.01Z',
            '0001-01-01T01:01:01.001Z',
            '1234-12-23T01:02:03.123Z',
          ]

          dates.each do |date|
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
              req.headers['Content-Type'] = 'application/json'
              req.body = {
                date: {
                  :$genghisType => 'ISODate',
                  :$value       => date
                }
              }.to_json
            end

            res.status.should eq 200
            res.body.should match_json_expression \
              _id: @id_pattern,
              date: {
                :$genghisType => 'ISODate',
                :$value       => date
              }
          end
        end

        it 'handles NaN values' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { foo: { '$genghisType' => 'NaN' } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            foo: {
              '$genghisType' => 'NaN'
            }
        end

        it 'returns 400 if the document is invalid' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = "{whot:'is this'}"
          end

          res.status.should eq 400
        end

        it 'returns 400 if the document id is invalid' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = {_id: [0, 1]}.to_json
          end

          res.status.should eq 400
        end

        it 'returns 404 if the collection is not found' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/fake_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 1 }.to_json
          end
          res.status.should eq 404
        end

        it 'returns 404 if the database is not found' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_fake_db__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 1 }.to_json
          end
          res.status.should eq 404
        end
      end

      describe 'DELETE /servers/:server/databases/:db/collections/:coll/documents' do
        before do
          @coll.insert({foo: 1, bar: 'a'})
          @coll.insert({foo: 2, bar: 'b'})
          @coll.drop_indexes
        end

        after do
          @coll.drop_indexes
          @coll.remove
        end

        it 'empties a collection' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
          res.status.should eq 200
          @conn['__genghis_spec_test__'].collection_names.include?('spec_docs').should eq true
          @coll.size.should eq 0
        end

        it 'maintains indices' do
          @coll.ensure_index({foo: -1})
          @coll.ensure_index({bar: 1}, {unique: true})
          @coll.ensure_index({baz: 1}, {name: 'baz_rocks', sparse: true, expireAfterSeconds: 6000})

          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
          res.status.should eq 200
          @conn['__genghis_spec_test__'].collection_names.include?('spec_docs').should eq true
          @coll.index_information.should match_json_expression \
            '_id_'      => Hash,
            'foo_-1'    => Hash,
            'bar_1'     => {unique: true}.ignore_extra_keys!,
            'baz_rocks' => {name: 'baz_rocks', sparse: true, expireAfterSeconds: 6000}.ignore_extra_keys!
        end

        it 'returns 404 if the collection is not found' do
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/spec_fake_docs/documents'
          res.status.should eq 404
        end
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll/documents/:id' do
        it 'returns a document' do
          id  = @coll.insert({test: 1})
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s

          res.status.should eq 200
          res.body.should match_json_expression \
            _id:  @id_pattern,
            test: 1
        end

        it 'can deal with non-objectid _id properties' do
          id = "test"
          @coll.insert({_id: id})
          id_str = "~#{Base64.encode64('"test"')}"
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id_str

          res.status.should eq 200
          res.body.should match_json_expression \
            _id:  "test"
        end

        it 'handles NaN values' do
          id  = @coll.insert({foo: Float::NAN})
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            foo: {
              '$genghisType' => 'NaN'
            }
        end

        it 'supports BSON Timestamps' do
          id  = @coll.insert({foo: BSON::Timestamp.new(123, 456)})
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            foo: {
              '$genghisType' => 'Timestamp',
              '$value' => {
                '$t' => 123,
                '$i' => 456,
              }
            }
        end

        it 'returns 404 if the document is not found' do
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/123'
          res.status.should eq 404
        end

        it 'returns 404 if the collection is not found' do
          id  = @coll.insert({test: 1})
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/fake_docs/documents/' + id.to_s
          res.status.should eq 404
        end

        it 'returns 404 if the database is not found' do
          id  = @coll.insert({test: 1})
          res = @api.get '/servers/localhost/databases/__genghis_spec_fake_db__/collections/spec_docs/documents/' + id.to_s
          res.status.should eq 404
        end
      end

      describe 'PUT /servers/:server/databases/:db/collections/:coll/documents/:id' do
        it 'updates the document' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 2 }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            test: 2
        end

        it 'handles NaN values' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: { '$genghisType' => 'NaN' } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            test: {
              '$genghisType' => 'NaN'
            }
        end

        it 'supports BSON Timestamps' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: { '$genghisType' => 'Timestamp', '$value' => { '$t' => 123, '$i' => 456 } } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            test: {
              '$genghisType' => 'Timestamp',
              '$value' => {
                '$t' => 123,
                '$i' => 456,
              }
            }
        end

        it 'can deal with non-objectid _id properties' do
          id = "testier"
          @coll.insert({_id: id})
          id_str = "~#{Base64.encode64('"testier"')}"
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id_str
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 1 }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: "testier",
            test: 1
        end

        it 'handles NaN values' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: { '$genghisType' => 'NaN' } }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            _id: @id_pattern,
            test: {
              '$genghisType' => 'NaN'
            }
        end

        it 'returns 400 if a document id is updated' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { _id: 1, test: 2 }.to_json
          end

          res.status.should eq 400
        end

        it 'returns 400 if the document is invalid' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = '...'
          end
          res.status.should eq 400
        end

        it 'returns 404 if the document is not found' do
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/123'
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 2 }.to_json
          end
          res.status.should eq 404
        end

        it 'returns 404 if the collection is not found' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/fake_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 2 }.to_json
          end
          res.status.should eq 404
        end

        it 'returns 404 if the database is not found' do
          id  = @coll.insert({test: 1})
          res = @api.put do |req|
            req.url '/servers/localhost/databases/__genghis_spec_fake_db__/collections/spec_docs/documents/' + id.to_s
            req.headers['Content-Type'] = 'application/json'
            req.body = { test: 2 }.to_json
          end
          res.status.should eq 404
        end
      end

      describe 'DELETE /servers/:server/databases/:db/collections/:coll/documents/:id' do
        it 'deletes the document' do
          id  = @coll.insert({test: 1})
          @coll.find(_id: id).count.should eq 1

          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s
          res.status.should eq 200

          @coll.find(_id: id).count.should eq 0
        end

        it 'returns 404 if the document is not found' do
          id  = @coll.insert({test: 1})
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/123'
          res.status.should eq 404
          @coll.find(_id: id).count.should eq 1
        end

        it 'returns 404 if the collection is not found' do
          id  = @coll.insert({test: 1})
          res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/fake_docs/documents/' + id.to_s
          res.status.should eq 404
          @coll.find(_id: id).count.should eq 1
        end

        it 'returns 404 if the database is not found' do
          id  = @coll.insert({test: 1})
          res = @api.delete '/servers/localhost/databases/__genghis_spec_fake_db__/collections/spec_docs/documents/' + id.to_s
          res.status.should eq 404
          @coll.find(_id: id).count.should eq 1
        end
      end

      context 'GridFS' do
        before :all do
          @grid = Mongo::Grid.new(@coll.db, 'test')
          @coll.db['test.chunks'].ensure_index({:files_id => Mongo::ASCENDING, :n => Mongo::ASCENDING}, :unique => true)
          @grid.put('tmp')
        end

        describe 'POST /servers/:server/databases/:db/collections/:coll/files' do
          it 'inserts a new file' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {
                file:        encode_upload('foo!'),
                filename:    'foo.txt',
                contentType: 'application/octet',
                metadata:    {expected: 'you know it'}
              }.to_json
            end

            res.status.should eq 200
            res.body.should match_json_expression \
              _id:         Hash,
              filename:    'foo.txt',
              contentType: 'application/octet',
              metadata:    { expected: 'you know it' },
              uploadDate:  Hash,
              length:      Fixnum,
              chunkSize:   Fixnum,
              md5:         String
          end

          it 'returns 400 if the file upload is not a base64 encoded data: URI' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {
                file:        'foo!',
                filename:    'foo.txt',
                contentType: 'application/octet',
                metadata:    {expected: 'you know it'}
              }.to_json
            end

            res.status.should eq 400
            res.body.should match_json_expression \
              error:  'File must be a base64 encoded data: URI',
              status: 400
          end

          it 'returns 400 if the document is missing important bits' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {filename: 'foo.txt'}.to_json
            end
            res.status.should eq 400
          end

          it 'returns 400 if the document has unexpected properties' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {file: encode_upload('foo'), unexpected: 'you know it.'}.to_json
            end
            res.status.should eq 400
          end

          it 'returns 404 if the collection is not found' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/fake.files/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {file: encode_upload('foo')}.to_json
            end
            res.status.should eq 404
          end

          it 'returns 404 if the collection is not a GridFS files collection' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/test.chunks/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {file: encode_upload('foo')}.to_json
            end
            res.status.should eq 404
          end

          it 'returns 404 if the database is not found' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_fake_db__/collections/test.files/files'
              req.headers['Content-Type'] = 'application/json'
              req.body = {file: 'foo'}.to_json
            end
            res.status.should eq 404
          end
        end

        describe 'GET /servers/:server/databases/:db/collections/:coll/files/:id' do
          it 'returns a document' do
            id  = @grid.put('foo')
            res = @api.get do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files/' + id.to_s
              req.headers.delete('X-Requested-With')
              req.headers.delete('Accept')
            end

            res.status.should eq 200
            res.headers['Content-Disposition'].should start_with 'attachment'
            res.body.should eq 'foo'
          end

          it 'returns 404 if the document is not found' do
            res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files/123'
            res.status.should eq 404
          end

          it 'returns 404 if the collection is not found' do
            id  = @grid.put('bar')
            res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/fake.files/files/' + id.to_s
            res.status.should eq 404
          end

          it 'returns 404 if the collection is not a GridFS files collection' do
            id  = @grid.put('baz')
            res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/test.chunks/files/' + id.to_s
            res.status.should eq 404
          end

          it 'returns 404 if the database is not found' do
            id  = @grid.put('qux')
            res = @api.get '/servers/localhost/databases/__genghis_spec_fake_db__/collections/test.files/files/' + id.to_s
            res.status.should eq 404
          end
        end

        describe 'DELETE /servers/:server/databases/:db/collections/:coll/files/:id' do
          it 'deletes a file (and all chunks)' do
            id = @grid.put('wheee')
            res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files/' + id.to_s

            res.status.should eq 200
            res.body.should match_json_expression \
              success: true

            expect { @grid.get(id) }.to raise_error Mongo::GridFileNotFound

            # and the chunks should be gone...
            @db['test.chunks'].find(_id: id).count.should eq 0
          end

          it 'returns 404 if the document is not found' do
            res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/test.files/files/123'
            res.status.should eq 404
          end

          it 'returns 404 if the collection is not found' do
            id  = @grid.put('bar')
            res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/fake.files/files/' + id.to_s
            res.status.should eq 404
          end

          it 'returns 404 if the collection is not a GridFS files collection' do
            id  = @grid.put('baz')
            res = @api.delete '/servers/localhost/databases/__genghis_spec_test__/collections/test.chunks/files/' + id.to_s
            res.status.should eq 404
          end

          it 'returns 404 if the database is not found' do
            id  = @grid.put('qux')
            res = @api.delete '/servers/localhost/databases/__genghis_spec_fake_db__/collections/test.files/files/' + id.to_s
            res.status.should eq 404
          end
        end
      end
    end
  end
end
