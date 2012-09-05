# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name        = 'genghisapp'
  gem.version     = File.read('VERSION').strip.gsub('-', '.')
  gem.author      = "Justin Hileman"
  gem.email       = 'justin@justinhileman.info'
  gem.homepage    = 'http://genghisapp.com'
  gem.summary     = %q{The single-file MongoDB admin app}
  gem.description = %q{The single-file MongoDB admin app}

  gem.platform                  = Gem::Platform::RUBY
  gem.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if gem.respond_to? :required_rubygems_version=
  # gem.rubyforge_project         = 'genghisapp'

  gem.add_dependency 'sinatra',          '~> 1.3.3'
  gem.add_dependency 'sinatra-contrib',  '~> 1.3.1'
  gem.add_dependency 'sinatra-mustache', '~> 0.0.4'
  gem.add_dependency 'mongo',            '~> 1.7.0'
  gem.add_dependency 'json',             '~> 1.7.0'

  # building
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'kicker'
  gem.add_development_dependency 'active_support'
  gem.add_development_dependency 'therubyracer'
  gem.add_development_dependency 'less'
  gem.add_development_dependency 'rainpress'
  gem.add_development_dependency 'uglifier'
  gem.add_development_dependency 'html_compressor'

  # testing
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'capybara'
  gem.add_development_dependency 'poltergeist'
  gem.add_development_dependency 'json_expressions'
  gem.add_development_dependency 'faraday'

  gem.files       = %w(LICENSE README.markdown CHANGELOG.markdown genghis.rb)
  gem.files      += Dir.glob("bin/**/*")
  gem.files      += Dir.glob("spec/**/*")
  gem.test_files  = Dir.glob("spec/**/*")
  gem.executables = %w(genghisapp)
end