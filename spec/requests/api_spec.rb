require 'spec_helper'
require 'faraday'

describe 'Genghis API', :type => :request do
  before :all do
    @api = Faraday.new url: "http://localhost:#{@genghis_port}"
    @api.headers['Accept'] = 'application/json'
  end

  it 'boots up' do
    res = @api.get '/check-status'
    res.status.should eq 200
    res.body.should match_json_expression({
      alerts: []
    })
  end

  it 'lists servers'
end