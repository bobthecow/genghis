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
            req.body = { name: 'mongo.example.com:27017' }.to_json
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
            req.body = { name: 'mongo.example.com:27017' }.to_json
          end
          res.headers['set-cookie'].should_not be_empty
          servers_cookie = URI.decode(res.headers['set-cookie'].split(';').first.split('=').last)
          servers_cookie.should match_json_expression \
            [
              %r{^(mongodb://)?localhost(:27017)?$},
              %r{^(mongodb://)?mongo.example.com(:27017)?$}
            ]
        end


        it 'adds the server but returns an error if the DSN is not valid' do
          res = @api.post do |req|
            req.url '/servers'
            req.headers['Content-Type'] = 'application/json'
            req.body = { name: 'http://foo/bar' }.to_json
          end

          res.status.should eq 200
          res.body.should match_json_expression \
            id:       'http://foo/bar',
            name:     'http://foo/bar',
            editable: true,
            error:    /^Malformed server DSN/
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
                size:        Fixnum
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
            size:        Fixnum
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
            size:        Fixnum
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
                indexes: Array
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
            indexes: Array
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
            indexes: Array
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
                  indexes: Array
                },
                {
                  id:      'another.with.dots',
                  name:    'another.with.dots',
                  count:   0,
                  indexes: Array
                },
                {
                  id:      'forward/slashes',
                  name:    'forward/slashes',
                  count:   0,
                  indexes: Array
                },
                {
                  id:      'back\\slashes',
                  name:    'back\\slashes',
                  count:   0,
                  indexes: Array
                },
                {
                  id:      'and unicode…',
                  name:    'and unicode…',
                  count:   0,
                  indexes: Array
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
              indexes: Array
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
              indexes: Array
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
          :'$genghisType' => 'ObjectId',
          :'$value'       => String
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

        it 'returns 400 if the document is invalid' do
          res = @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents'
            req.headers['Content-Type'] = 'application/json'
            req.body = "{whot:'is this'}"
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

      describe 'GET /servers/:server/databases/:db/collections/:coll/documents/:id' do
        it 'returns a document' do
          id  = @coll.insert({test: 1})
          res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/documents/' + id.to_s

          res.status.should eq 200
          res.body.should match_json_expression \
            _id:  @id_pattern,
            test: 1
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
    end
  end
end