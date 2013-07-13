require 'rspec/autorun'
require 'json_expressions/rspec'
require 'net/http'
require_relative '../genghis.rb'

RSpec.configure do |config|
  def genghis_backends
    if ENV['GENGHIS_BACKEND']
      ENV['GENGHIS_BACKEND'].split(',').map(&:to_sym)
    else
      [:php, :php_dev, :ruby]
    end
  end

  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end

  def start_backend(backend)
    @genghis_port = find_available_port

    case backend
    when :php, :php_dev
      @genghis_pid = spawn 'php', '-S', "localhost:#{@genghis_port}", php_backend_filename(backend), :out => '/dev/null'
      api = Faraday.new url: "http://localhost:#{@genghis_port}"
      0.upto(20) do |i|
        break if api_started?(api)
        sleep 0.1
      end
      api
    when :ruby
      Faraday.new do |conn|
        conn.adapter :rack, Genghis::Server.new
      end
    end
  end

  def php_backend_filename(backend)
    case backend
    when :php     then 'genghis.php'
    when :php_dev then 'genghis-dev.php'
    end
  end

  def api_started?(api)
    api.get '/'
    true
  rescue Faraday::Error::ConnectionFailed => e
    false
  end

  def encode_upload(file)
    "data:text/plain;base64," + Base64.strict_encode64(file)
  end

  config.after :all do
    # Kill any outstanding Genghis backend
    Process.kill('HUP', @genghis_pid) unless @genghis_pid.nil?
    @genghis_pid = nil
  end
end