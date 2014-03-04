# encoding: utf-8

require 'spec_helper'
require 'faraday'
require 'mongo'

OBJECT_ID = {'$genghisType' => 'ObjectId', '$value' => String}

genghis_backends.each do |backend|
  describe "Genghis #{backend} API" do
    before :all do
      @api = start_backend backend
      @api.headers['Accept'] = 'application/json'
      @api.headers['X-Requested-With'] = 'XMLHttpRequest'
    end

    it 'boots up' do
      res = @api.get '/check-status'
      expect(res.status).to eq 200
      expect(res).to be_a_json_response
      expect(res.body).to match_json_expression \
        :alerts => Array
    end

    context 'when unknown URL requested' do
      let(:res) { @api.get '/bacon-sammitch' }

      it 'returns 404 status' do
        expect(res.status).to eq 404
        expect(res).to be_a_json_response
        expect(res.body).to match_json_expression \
          :error => 'Not Found',
          :status => 404
      end
    end

    context 'servers' do
      describe 'GET /servers' do
        let(:res) { @api.get '/servers' }

        it 'always contains localhost' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            [
              {
                :id => 'localhost',
                :name => 'localhost',
                :editable => true,
                :size => Fixnum,
                :count => Fixnum,
                :databases => Array
              }
            ]
        end
      end

      describe 'POST /servers' do
        let(:dsn) { 'mongo.example.com:27017' }
        let(:res) do
          @api.post do |req|
            req.url '/servers'
            req.headers['Content-Type'] = 'application/json'
            req.body = {:url => dsn}.to_json
          end
        end

        it 'adds a server' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :id => 'mongo.example.com',
            :name => 'mongo.example.com',
            :editable => true,
            :error => String # mongo.example.com is valid, but unable to connect
        end

        context 'when you already have servers' do
          let(:res) do
            @api.post do |req|
              req.url '/servers'
              req.headers['Content-Type'] = 'application/json'
              req.headers['Cookie'] = 'genghis_servers=%7B%22localhost%22%3A%22mongodb%3A%5C%2F%5C%2Flocalhost%3A27017%22%7D'
              req.body = {:url => dsn}.to_json
            end
          end

          it 'remembers the old servers too' do
            expect(res.headers['set-cookie']).to_not be_empty
            servers_cookie = URI.decode(res.headers['set-cookie'].split(';').first.split('=').last)
            expect(servers_cookie).to match_json_expression \
              [
                %r{^(mongodb://)?localhost(:27017)?$},
                %r{^(mongodb://)?mongo.example.com(:27017)?$}
              ]
          end
        end

        context 'when DSN is empty' do
          let(:dsn) { '' }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Malformed server DSN',
              :status => 400
          end
        end

        context 'when DSN is not valid' do
          let(:dsn) { 'http://foo/bar' }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Malformed server DSN',
              :status => 400
          end
        end
      end

      describe 'GET /servers/:server' do
        let(:res) { @api.get '/servers/localhost' }

        it 'returns server info' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :id => 'localhost',
            :name => 'localhost',
            :editable => true,
            :size => Fixnum,
            :count => Fixnum,
            :databases => Array
        end

        context 'when server not found' do
          let(:res) { @api.get '/servers/not-a-real-server' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Server 'not-a-real-server' not found",
              :status => 404
          end
        end
      end

      describe 'DELETE /servers/:server' do
        let(:res) do
          @api.delete do |req|
            req.url '/servers/mongo.example.com'
            servers = CGI.escape('["mongodb:\/\/mongo.example.com"]')
            req.headers['Cookie'] = "genghis_servers=#{servers};genghis_rb_servers=#{servers}"
          end
        end

        it 'deletes the server' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :success => true
        end

        context 'when server not found' do
          let(:res) { @api.delete '/servers/not-a-real-server' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Server 'not-a-real-server' not found",
              :status => 404
          end
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
        let(:res) { @api.get '/servers/localhost/databases' }

        it 'returns a list of databases' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            [
              {
                :id => '__genghis_spec_test__',
                :name => '__genghis_spec_test__',
                :count => 0,
                :collections => [],
                :stats => Hash
              }
            ].ignore_extra_values!
        end
      end

      describe 'POST /servers/:server/databases' do
        after :all do
          @conn.drop_database '__genghis_spec_create_db_test__'
        end

        let(:db)  { '__genghis_spec_create_db_test__' }
        let(:res) do
          @api.post do |req|
            req.url '/servers/localhost/databases'
            req.headers['Content-Type'] = 'application/json'
            req.body = {:name => db}.to_json
          end
        end

        it 'creates a new database' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :id => db,
            :name => db,
            :count => 0,
            :collections => [],
            :stats => Hash
        end

        context 'when database name is invalid' do
          let(:db) { '' }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Invalid database name',
              :status => 400
          end
        end

        context 'when database already exists' do
          let(:db) { '__genghis_spec_create_db_test__' }

          before do
            @conn[db]['__tmp__'].drop
          end

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_create_db_test__' already exists on 'localhost'",
              :status => 400
          end
        end
      end

      describe 'GET /servers/:server/databases/:db' do
        let(:db)  { '__genghis_spec_test__' }
        let(:res) { @api.get "/servers/localhost/databases/#{db}" }

        it 'returns database info' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :id => db,
            :name => db,
            :count => 0,
            :collections => [],
            :stats => Hash
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_get_fake_db_test__' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_get_fake_db_test__' not found on 'localhost'",
              :status => 404
          end
        end
      end

      describe 'DELETE /servers/:server/databases/:db' do
        let(:db)  { '__genghis_spec_drop_db_test__' }
        let(:res) { @api.delete "/servers/localhost/databases/#{db}" }

        before do
          @conn['__genghis_spec_drop_db_test__']['__tmp__'].drop
        end

        after do
          @conn.drop_database('__genghis_spec_drop_db_test__')
        end

        it 'drops the database' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(@conn.database_names.include?(db)).to eq false
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_delete_fake_db_test__' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_delete_fake_db_test__' not found on 'localhost'",
              :status => 404
          end
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
        let(:db)  { '__genghis_spec_test__' }
        let(:res) { @api.get "/servers/localhost/databases/#{db}/collections" }

        it 'returns a list of collections' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            [
              {
                :id => 'spec_collection',
                :name => 'spec_collection',
                :count => 0,
                :indexes => Array,
                :stats => Hash,
              }
            ]
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          before do
            @conn.drop_database('__genghis_spec_fake_db__') if @conn.database_names.include?('__genghis_spec_fake_db__')
          end

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404
          end
        end
      end

      describe 'POST /servers/:server/databases/:db/collections' do
        let(:coll) { 'spec_create_collection' }
        let(:res)  do
          @api.post do |req|
            req.url '/servers/localhost/databases/__genghis_spec_test__/collections'
            req.headers['Content-Type'] = 'application/json'
            req.body = {:name => coll}.to_json
          end
        end

        it 'creates a new collection' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :id => coll,
            :name => coll,
            :count => 0,
            :indexes => Array,
            :stats => Hash
        end

        context 'when collection name is invalid' do
          let(:coll) { '' }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Invalid collection name',
              :status => 400
          end
        end

        context 'when collection already exists' do
          let(:coll) { 'already_exists' }

          before do
            @conn['__genghis_spec_test__'].create_collection 'already_exists'
          end

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'already_exists' already exists in '__genghis_spec_test__'",
              :status => 400
          end
        end
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll' do
        let(:db)   { '__genghis_spec_test__' }
        let(:coll) { 'spec_collection' }
        let(:res)  { @api.get "/servers/localhost/databases/#{db}/collections/#{coll}" }

        it 'returns collection info' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :id => coll,
            :name => coll,
            :count => 0,
            :indexes => Array,
            :stats => Hash
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'fake_collection' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'fake_collection' not found in '__genghis_spec_test__'",
              :status => 404
          end
        end
      end

      describe 'DELETE /servers/:server/databases/:db/collections/:coll' do
        let(:db)   { '__genghis_spec_test__' }
        let(:coll) { 'spec_collection' }
        let(:res)  { @api.delete "/servers/localhost/databases/#{db}/collections/#{coll}" }

        before do
          @db = @conn['__genghis_spec_test__']
          @db['__tmp__'].drop
          @db.drop_collection('spec_collection') if @db.collection_names.include?('spec_collection')
          @db.create_collection 'spec_collection'
        end

        it 'deletes the collection' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(@db.collection_names.include?('spec_collection')).to eq false
          expect(res.body).to match_json_expression \
            :success => true
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'fake_collection' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'fake_collection' not found in '__genghis_spec_test__'",
              :status => 404
          end
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
          let(:res) { @api.get '/servers/localhost/databases/__genghis_spec_test__/collections' }

          it 'can handle collections with weird names' do
            row = {
              :id => String,
              :name => String,
              :count => 0,
              :indexes => Array,
              :stats => Hash
            }
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              [
                row.merge(:id => 'one with a few spaces', :name => 'one with a few spaces'),
                row.merge(:id => 'another.with.dots',     :name => 'another.with.dots'),
                row.merge(:id => 'forward/slashes',       :name => 'forward/slashes'),
                row.merge(:id => 'back\\slashes',         :name => 'back\\slashes'),
                row.merge(:id => 'and unicode…',          :name => 'and unicode…'),
              ]
          end
        end

        describe 'POST /servers/:server/databases/:db/collections' do
          it 'creates a new collection just like you would expect' do
            res = @api.post do |req|
              req.url '/servers/localhost/databases/__genghis_spec_test__/collections'
              req.headers['Content-Type'] = 'application/json'
              req.body = {:name => 'a b.c/d\\e…'}.to_json
            end

            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :id => 'a b.c/d\\e…',
              :name => 'a b.c/d\\e…',
              :count => 0,
              :indexes => Array,
              :stats => Hash
          end
        end

        describe 'GET /servers/:server/databases/:db/collections/:coll' do
          before :all do
            @db.create_collection 'foo bar.baz/qux\\quux…'
          end

          it 'returns collection info' do
            res = @api.get '/servers/localhost/databases/__genghis_spec_test__/collections/foo%20bar.baz%2Fqux%5Cquux%E2%80%A6'

            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :id => 'foo bar.baz/qux\\quux…',
              :name => 'foo bar.baz/qux\\quux…',
              :count => 0,
              :indexes => Array,
              :stats => Hash
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
      end

      after :all do
        @conn.drop_database '__genghis_spec_test__'
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll/documents' do
        let(:db)   { '__genghis_spec_test__' }
        let(:coll) { 'spec_docs' }
        let(:res)  { @api.get "/servers/localhost/databases/__genghis_spec_test__/collections/#{coll}/documents" }

        it 'returns a list of documents' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :count => Fixnum,
            :page => Fixnum,
            :pages => Fixnum,
            :per_page => 50,
            :offset => Fixnum,
            :documents => Array
        end

        context 'when collection does not exist' do
          let(:coll) { 'spec_fake_docs' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'spec_fake_docs' not found in '__genghis_spec_test__'",
              :status => 404
          end
        end

        context 'with a search string' do
          let(:q)   { {'a' => {'$exists' => true}} }
          let(:res) { @api.get "/servers/localhost/databases/__genghis_spec_test__/collections/#{coll}/documents?q=#{q.to_json}" }

          before :all do
            @coll.remove({})
            @coll.insert([
              {:a => 1},
              {:a => 2, :b => 2},
              {:b => 3},
            ])
          end

          it 'returns a list of documents' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :count     => 2,
              :page      => 1,
              :pages     => 1,
              :per_page  => 50,
              :offset    => 0,
              :documents => [
                {:_id => OBJECT_ID, :a => 1},
                {:_id => OBJECT_ID, :a => 2, :b => 2},
              ]
          end

          context 'with projection fields' do
            let(:fields) { {'a' => 1, '_id' => 0} }
            let(:res)    { @api.get "/servers/localhost/databases/__genghis_spec_test__/collections/#{coll}/documents?q=#{q.to_json}&fields=#{fields.to_json}" }

            it 'returns a list of projection documents' do
              expect(res.status).to eq 200
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :count => 2,
                :page  => 1,
                :pages => 1,
                :per_page => 50,
                :offset => 0,
                :documents => [
                  {:a => 1},
                  {:a => 2},
                ]
            end
          end

          context 'with sort order' do
            let(:sort) { {'a' => -1, 'c' => 1} }
            let(:res)  { @api.get "/servers/localhost/databases/__genghis_spec_test__/collections/#{coll}/documents?sort=#{sort.to_json}" }

            it 'returns a list of documents in order' do
              expect(res.status).to eq 200
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :count     => 3,
                :page      => 1,
                :pages     => 1,
                :per_page  => 50,
                :offset    => 0,
                :documents => [
                  {:_id => OBJECT_ID, :a => 2, :b => 2},
                  {:_id => OBJECT_ID, :a => 1},
                  {:_id => OBJECT_ID, :b => 3},
                ].ordered!
            end

            it 'saves users from themselves by preventing dumb sorts'
            it 'allows users to override dumb sort prevention and/or offers to let them add an index'
          end
        end
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll/explain?q=' do
        let(:res) { @api.get "/servers/localhost/databases/__genghis_spec_test__/collections/spec_docs/explain?q=#{URI.encode('{}')}" }

        it 'has some basic index info' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression({
            :cursor => 'BasicCursor',
            :indexOnly => false,
            :allPlans => Array,
            :server => String
          }.ignore_extra_keys)
        end
      end

      describe 'POST /servers/:server/databases/:db/collections/:coll/documents' do
        let(:db)       { '__genghis_spec_test__' }
        let(:coll)     { 'spec_docs' }
        let(:doc)      { {:foo => 'FOO!', :bar => 123, :baz => {:qux => 4.56, :quux => false}} }
        let(:req_body) { doc.to_json }
        let(:res) do
          @api.post do |req|
            req.url "/servers/localhost/databases/#{db}/collections/#{coll}/documents"
            req.headers['Content-Type'] = 'application/json'
            req.body = req_body
          end
        end
        let(:actualdoc) do
          json = JSON.parse(res.body)
          @coll.find_one({:_id => BSON::ObjectId(json['_id']['$value'])})
        end

        it 'creates a document' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :_id => OBJECT_ID,
            :foo => 'FOO!',
            :bar => 123,
            :baz => {
              :qux => 4.56,
              :quux => false
            }
        end

        context 'with a specified ID' do
          let(:doc) { {:_id => 1, :foo => 'bar'} }
          it 'creates a document with that id' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => 1,
              :foo => 'bar'
          end
        end

        context 'with unknown $genghisTypes' do
          let(:doc) { {:foo => {'$genghisType' => 'NOT A REAL TYPE!!'}} }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Malformed document',
              :status => 400
          end
        end

        context 'with NaN values' do
          let(:doc) { {:foo => {'$genghisType' => 'NaN'}} }

          it 'handles NaN values like a champ' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => 'NaN'
              }
          end
        end

        context 'with Infinity values' do
          let(:doc) { {:foo => {'$genghisType' => 'Infinity'}} }

          it 'handles Infinity values like a champ' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => 'Infinity'
              }
          end
        end

        context 'with -Infinity values' do
          let(:doc) { {:foo => {'$genghisType' => '-Infinity'}} }

          it 'handles -Infinity values like a champ' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => '-Infinity'
              }
          end
        end

        context 'with MinKey and MaxKey values' do
          let(:doc) { {:foo => {'$genghisType' => 'MinKey'}, :bar => {'$genghisType' => 'MaxKey'}} }

          it 'handles MinKey and MaxKey values like a champ' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => 'MinKey'
              },
              :bar => {
                '$genghisType' => 'MaxKey'
              }
          end
        end

        context 'with NumberLong values' do
          let(:doc) do
            {
              :foo => {'$genghisType' => 'NumberLong', '$value' => '2147483648'},
              :bar => {'$genghisType' => 'NumberLong', '$value' => '-2147483649'}
            }
          end

          it 'can hold its NumberLong' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {'$genghisType' => 'NumberLong', '$value' => '2147483648'},
              :bar => {'$genghisType' => 'NumberLong', '$value' => '-2147483649'}

            # check the actual value to make sure there are no shenanigans
            expect(actualdoc['foo']).to eq 2147483648
            expect(actualdoc['bar']).to eq -2147483649
          end
        end

        context 'with Timestamp values' do
          let(:doc) { {:foo => {'$genghisType' => 'Timestamp', '$value' => {'$t' => 123, '$i' => 456}}} }

          it 'supports Timestamps' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => 'Timestamp',
                '$value' => {
                  '$t' => 123,
                  '$i' => 456,
                }
              }
          end
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
                :date => {
                  '$genghisType' => 'ISODate',
                  '$value'       => date
                }
              }.to_json
            end

            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :date => {
                '$genghisType' => 'ISODate',
                '$value'       => date
              }
          end
        end

        context 'with an invalid document' do
          let(:req_body) { "{whot:'is this'}" }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Malformed document',
              :status => 400
          end
        end

        context 'with an invalid document id' do
          let(:doc) { {:_id => [0, 1]} }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => String, # TODO: standardize this error message
              :status => 400
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'fake_docs' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'fake_docs' not found in '__genghis_spec_test__'",
              :status => 404
          end
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          before do
            @conn.drop_database(db) if @conn.database_names.include?(db)
          end

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404
          end
        end
      end

      describe 'DELETE /servers/:server/databases/:db/collections/:coll/documents' do
        let(:coll) { 'spec_docs' }
        let(:res)  { @api.delete "/servers/localhost/databases/__genghis_spec_test__/collections/#{coll}/documents" }

        before do
          @coll.insert(:foo => 1, :bar => 'a')
          @coll.insert(:foo => 2, :bar => 'b')
        end

        after do
          @coll.remove
        end

        it 'empties the collection' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :success => true
          expect(@conn['__genghis_spec_test__'].collection_names.include?('spec_docs')).to eq true
          expect(@coll.size).to eq 0
        end

        context 'with collection indices' do
          before do
            @coll.drop_indexes
            @coll.ensure_index(:foo => -1)
            @coll.ensure_index({:bar => 1}, {:unique => true})
            @coll.ensure_index({:baz => 1}, {:name => 'baz_rocks', :sparse => true, :expireAfterSeconds => 6000})
          end

          after do
            @coll.drop_indexes
          end

          it 'maintains indices' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(@conn['__genghis_spec_test__'].collection_names.include?('spec_docs')).to eq true
            expect(@coll.index_information).to match_json_expression \
              '_id_'      => Hash,
              'foo_-1'    => Hash,
              'bar_1'     => {:unique => true}.ignore_extra_keys!,
              'baz_rocks' => {:name => 'baz_rocks', :sparse => true, :expireAfterSeconds => 6000}.ignore_extra_keys!
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'spec_fake_docs' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'spec_fake_docs' not found in '__genghis_spec_test__'",
              :status => 404
          end
        end
      end

      describe 'GET /servers/:server/databases/:db/collections/:coll/documents/:id' do
        let!(:id)    { @coll.insert(:test => 1) }
        let(:id_str) { id.to_s }
        let(:db)     { '__genghis_spec_test__' }
        let(:coll)   { 'spec_docs' }
        let(:res)    { @api.get "/servers/localhost/databases/#{db}/collections/#{coll}/documents/#{id_str}" }

        it 'returns a document' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :_id => OBJECT_ID,
            :test => 1
        end

        context 'with non-objectid _id' do
          let(:id)     { 'test' }
          let(:id_str) { "~#{Base64.encode64('"test"')}" }

          before do
            @coll.insert(:_id => id)
          end

          it 'deals with it' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => 'test'
          end
        end

        context 'with NaN _id' do
          let!(:id) { @coll.insert(:foo => Float::NAN) }

          it 'handles NaN values too' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => 'NaN'
              }
          end
        end

        context 'with BSON Timestamp values' do
          let!(:id) { @coll.insert(:foo => BSON::Timestamp.new(123, 456)) }

          it 'supports BSON Timestamps' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :foo => {
                '$genghisType' => 'Timestamp',
                '$value' => {
                  '$t' => 123,
                  '$i' => 456,
                }
              }
          end
        end

        context 'when document does not exist' do
          let(:id) { '123' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Document '123' not found in 'spec_docs'",
              :status => 404
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'fake_docs' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'fake_docs' not found in '__genghis_spec_test__'",
              :status => 404
          end
        end

        context 'when the database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404
          end
        end
      end

      describe 'PUT /servers/:server/databases/:db/collections/:coll/documents/:id' do
        let!(:id)      { @coll.insert(:test => 1) }
        let(:id_str)   { id.to_s }
        let(:db)       { '__genghis_spec_test__' }
        let(:coll)     { 'spec_docs' }
        let(:doc)      { {:test => 2} }
        let(:req_body) { doc.to_json }
        let(:res) do
          @api.put do |req|
            req.url "/servers/localhost/databases/#{db}/collections/#{coll}/documents/#{id_str}"
            req.headers['Content-Type'] = 'application/json'
            req.body = req_body
          end
        end

        it 'updates the document' do
          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :_id => OBJECT_ID,
            :test => 2
        end

        context 'with NaN values' do
          let(:doc) { {:test => {'$genghisType' => 'NaN'}} }

          it 'handles them like a champ' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :test => {
                '$genghisType' => 'NaN'
              }
          end
        end

        context 'with BSON Timestamp values' do
          let(:doc) { {:test => {'$genghisType' => 'Timestamp', '$value' => {'$t' => 123, '$i' => 456}}} }

          it 'supports BSON Timestamps' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :test => {
                '$genghisType' => 'Timestamp',
                '$value' => {
                  '$t' => 123,
                  '$i' => 456,
                }
              }
          end
        end

        context 'with non-objectid _id properties' do
          let(:id_str) { "~#{Base64.encode64('"testier"')}" }
          let(:doc)    { {:test => 1} }

          before do
            @coll.insert(:_id => 'testier')
          end

          it 'can deal with non-objectid _id properties' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => 'testier',
              :test => 1
          end
        end

        context 'with NaN values' do
          let(:doc) { {:test => {'$genghisType' => 'NaN'}} }

          it 'handles NaN values' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => OBJECT_ID,
              :test => {
                '$genghisType' => 'NaN'
              }
          end
        end

        context 'when updating document id' do
          let(:doc) { {:_id => 1, :test => 2} }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => String, # TODO: standardize this error message across backends.
              :status => 400
          end
        end

        context 'with an invalid document' do
          let(:req_body) { '...' }

          it 'responds with 400' do
            expect(res.status).to eq 400
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => 'Malformed document',
              :status => 400
          end
        end

        context 'when document does not exist' do
          let(:id_str) { '123' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Document '123' not found in 'spec_docs'",
              :status => 404
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'fake_docs' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'fake_docs' not found in '__genghis_spec_test__'",
              :status => 404
          end
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          it 'responds with 404' do
            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404
          end
        end
      end

      describe 'DELETE /servers/:server/databases/:db/collections/:coll/documents/:id' do
        let!(:id)    { @coll.insert(:test => 1) }
        let(:id_str) { id.to_s }
        let(:db)     { '__genghis_spec_test__' }
        let(:coll)   { 'spec_docs' }
        let(:res)    { @api.delete "/servers/localhost/databases/#{db}/collections/#{coll}/documents/#{id_str}" }

        it 'deletes the document' do
          expect(@coll.find(:_id => id).count).to eq 1

          expect(res.status).to eq 200
          expect(res).to be_a_json_response
          expect(res.body).to match_json_expression \
            :success => true

          expect(@coll.find(:_id => id).count).to eq 0
        end

        context 'when document does not exist' do
          let(:id_str) { '123' }

          it 'responds with 404' do
            expect(@coll.find(:_id => id).count).to eq 1

            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Document '123' not found in 'spec_docs'",
              :status => 404

            expect(@coll.find(:_id => id).count).to eq 1
          end
        end

        context 'when collection does not exist' do
          let(:coll) { 'fake_docs' }

          it 'responds with 404' do
            expect(@coll.find(:_id => id).count).to eq 1

            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Collection 'fake_docs' not found in '__genghis_spec_test__'",
              :status => 404

            expect(@coll.find(:_id => id).count).to eq 1
          end
        end

        context 'when database does not exist' do
          let(:db) { '__genghis_spec_fake_db__' }

          it 'responds with 404' do
            expect(@coll.find(:_id => id).count).to eq 1

            expect(res.status).to eq 404
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
              :status => 404

            expect(@coll.find(:_id => id).count).to eq 1
          end
        end
      end

      context 'GridFS' do
        before :all do
          @grid = Mongo::Grid.new(@coll.db, 'test')
          @coll.db['test.chunks'].ensure_index({:files_id => Mongo::ASCENDING, :n => Mongo::ASCENDING}, :unique => true)
          @grid.put('tmp')
        end

        describe 'POST /servers/:server/databases/:db/collections/:coll/files' do
          let(:db)   { '__genghis_spec_test__' }
          let(:coll) { 'test.files' }
          let(:file) { encode_upload('foo!') }

          let(:req_body) do
            {
              :file => file,
              :filename => 'foo.txt',
              :contentType => 'binary/octet-stream',
              :metadata => {:expected => 'you know it'}
            }
          end

          let(:res) do
            @api.post do |req|
              req.url "/servers/localhost/databases/#{db}/collections/#{coll}/files"
              req.headers['Content-Type'] = 'application/json'
              req.body = req_body.to_json
            end
          end

          it 'inserts a new file' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :_id => Hash,
              :filename => 'foo.txt',
              :contentType => 'binary/octet-stream',
              :metadata => {:expected => 'you know it'},
              :uploadDate => Hash,
              :length => Fixnum,
              :chunkSize => Fixnum,
              :md5 => String
          end

          context 'when file is not base64 encoded' do
            let(:file) { 'foo!' }

            it 'responds with 400' do
              expect(res.status).to eq 400
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => 'File must be a base64 encoded data: URI',
                :status => 400
            end
          end

          context 'when document is missing important bits' do
            let(:req_body) { {:filename => 'foo.txt'} }

            it 'responds with 400' do
              expect(res.status).to eq 400
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => 'Missing file',
                :status => 400
            end
          end

          context 'when document has unexpected properties' do
            let(:req_body) { {:file => encode_upload('foo'), :unexpected => 'you know it.'} }

            it 'responds with 400' do
              expect(res.status).to eq 400
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "Unexpected property: 'unexpected'",
                :status => 400
            end
          end

          context 'when collection does not exist' do
            let(:coll) { 'fake.files' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "Collection 'fake.files' not found in '__genghis_spec_test__'",
                :status => 404
            end
          end

          context 'when collection is not a GridFS files collection' do
            let(:coll) { 'test.chunks' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => String, # TODO: fix this. It's currently broken on Ruby backends:
                # :error => "GridFS collection 'test.chunks' not found in '__genghis_spec_test__'",
                :status => 404
            end
          end

          context 'when database does not exist' do
            let(:db) { '__genghis_spec_fake_db__' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
                :status => 404
            end
          end
        end

        describe 'GET /servers/:server/databases/:db/collections/:coll/files/:id' do
          let!(:id)  { @grid.put('foo') }
          let(:db)   { '__genghis_spec_test__' }
          let(:coll) { 'test.files' }
          let(:res) do
            @api.get do |req|
              req.url "/servers/localhost/databases/#{db}/collections/#{coll}/files/#{id}"
              req.headers.delete('X-Requested-With')
              req.headers.delete('Accept')
            end
          end

          it 'returns a document' do
            expect(res.status).to eq 200
            expect(res).to be_a_download_response
            expect(res.body).to eq 'foo'
          end

          context 'when document does not exist' do
            let(:id) { '123' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "GridFS file '123' not found",
                :status => 404
            end
          end

          context 'when collection does not exist' do
            let(:coll) { 'fake.files' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "Collection 'fake.files' not found in '__genghis_spec_test__'",
                :status => 404
            end
          end

          context 'when collection is not a GridFS files collection' do
            let(:coll) { 'test.chunks' }
            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
            end
          end

          context 'when database does not exist' do
            let(:db) { '__genghis_spec_fake_db__' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
            end
          end
        end

        describe 'DELETE /servers/:server/databases/:db/collections/:coll/files/:id' do
          let!(:id)  { @grid.put('wheee') }
          let(:db)   { '__genghis_spec_test__' }
          let(:coll) { 'test.files' }
          let(:res)  { @api.delete "/servers/localhost/databases/#{db}/collections/#{coll}/files/#{id}" }

          it 'deletes the file (and all chunks)' do
            expect(res.status).to eq 200
            expect(res).to be_a_json_response
            expect(res.body).to match_json_expression \
              :success => true

            expect { @grid.get(id) }.to raise_error Mongo::GridFileNotFound

            # and the chunks should be gone...
            expect(@db['test.chunks'].find(:_id => id).count).to eq 0
          end

          context 'when document does not exist' do
            let(:id) { '123' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "GridFS file '123' not found",
                :status => 404
            end
          end

          context 'when collection does not exist' do
            let(:coll) { 'fake.files' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "Collection 'fake.files' not found in '__genghis_spec_test__'",
                :status => 404
            end
          end

          context 'when collection is not a GridFS files collection' do
            let(:coll) { 'test.chunks' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => String, # TODO: fix this. It's currently broken on Ruby backends:
                # :error => "GridFS collection 'test.chunks' not found in '__genghis_spec_test__'",
                :status => 404
            end
          end

          context 'when database does not exist' do
            let(:db) { '__genghis_spec_fake_db__' }

            it 'responds with 404' do
              expect(res.status).to eq 404
              expect(res).to be_a_json_response
              expect(res.body).to match_json_expression \
                :error => "Database '__genghis_spec_fake_db__' not found on 'localhost'",
                :status => 404
            end
          end
        end
      end
    end
  end
end
