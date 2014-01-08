require 'genghis/version'
require 'genghis/helpers'
require 'genghis/errors'
require 'genghis/json'
require 'genghis/models/collection'
require 'genghis/models/database'
require 'genghis/models/query'
require 'genghis/models/server'
require 'genghis/server'

module Genghis
  class DevServer < Genghis::Server
    set :views,         File.expand_path('../../../../public/templates', __FILE__)
    set :public_folder, File.expand_path('../../../../public', __FILE__)

    def index_template
      'index'.intern
    end

    def error_template
      'error'.intern
    end
  end
end
