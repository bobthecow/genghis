require File.expand_path('../src/rb/genghis/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'genghisapp'
  spec.version     = Genghis::VERSION
  spec.author      = 'Justin Hileman'
  spec.email       = 'justin@justinhileman.info'
  spec.homepage    = 'http://genghisapp.com'
  spec.summary     = %q{The single-file MongoDB admin app}

  spec.add_dependency 'json',             '>= 1.7.0', '< 1.9.0'
  spec.add_dependency 'mongo',            '>= 1.8.0', '<= 1.9.2'
  spec.add_dependency 'sinatra',          '>= 1.3.3', '< 1.5.0'
  spec.add_dependency 'sinatra-contrib',  '>= 1.3.1', '< 1.5.0'
  spec.add_dependency 'sinatra-mustache', '>= 0.0.4', '< 0.4.0'
  spec.add_dependency 'vegas',            '~> 0.1.8'

  spec.add_development_dependency 'active_support'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'html_compressor'
  spec.add_development_dependency 'less'
  spec.add_development_dependency 'rainpress'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'therubyracer'
  spec.add_development_dependency 'uglifier'

  spec.files        = Dir['LICENSE.txt', 'README.md', 'CHANGELOG.md', 'genghis.rb', 'bin/**/*']
  spec.test_files   = Dir['spec/**/*']
  spec.executables  = %w(genghisapp)
  spec.require_path = '.'

  spec.description = <<-description
    Genghis is a single-file MongoDB admin app, made entirely out of awesome.
  description
end
