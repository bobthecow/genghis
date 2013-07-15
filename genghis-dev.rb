lib = File.expand_path('../src/rb', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'genghis/dev_server'

Genghis::DevServer.run!