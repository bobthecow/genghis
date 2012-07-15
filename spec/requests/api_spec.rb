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
      it 'lists available servers' do
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
      it 'creates a server when given a valid DSN'
      it 'returns 400 if the DSN is not valid'
    end
  end
end