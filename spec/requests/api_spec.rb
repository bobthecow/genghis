require 'spec_helper'
require 'faraday'

describe 'Genghis API', :type => :request do
  before :all do
    @api = Faraday.new url: "http://localhost:#{@genghis_port}"
    @api.headers['Accept']       = 'application/json'
    @api.headers['Content-Type'] = 'application/json'
  end

  it 'boots up' do
    res = @api.get '/check-status'
    res.status.should eq 200
    res.body.should match_json_expression({
      alerts: []
    })
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
          ].ignore_extra_values!
      end
    end

    describe 'POST /servers' do
      it 'creates a server when given a valid DSN' do
        res = @api.post do |req|
          req.url '/servers'
          req.headers['Content-Type'] = 'application/json'
          req.body = { name: 'localhost:27017' }.to_json
        end

        res.status.should eq 200
        res.headers['content-type'].should eq 'application/json'
        res.body.should match_json_expression \
          id:        'localhost',
          name:      'localhost',
          editable:  true,
          size:      Fixnum,
          count:     Fixnum,
          databases: Array
      end

      it 'returns 400 if the DSN is not valid' do
        res = @api.post do |req|
          req.url '/servers'
          req.headers['Content-Type'] = 'application/json'
          req.body = { name: 'http://foo/bar' }.to_json
        end
        res.status.should eq 400
      end
    end

    describe 'DELETE /servers/:server' do
      it 'deletes a server if it exists' do
        res = @api.delete '/servers/localhost'
        res.status.should eq 200
      end

      it 'returns 404 when the server is not found' do
        res = @api.delete '/servers/not-a-real-server'
        res.status.should eq 404
      end
    end
  end
end