require 'rspec/autorun'
require 'json_expressions/rspec'
require 'net/http'

RSpec.configure do |config|
  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end

  config.before :all do
    @genghis_port = find_available_port
    @genghis_pid  = spawn 'php', '-S', "localhost:#{@genghis_port}", 'genghis.php', :out => '/dev/null'
    sleep 0.1
  end

  config.after :all do
    Process.kill('HUP', @genghis_pid)
  end
end