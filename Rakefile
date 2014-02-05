require 'rubygems/package_task'

namespace :gulp do
  task :clean do
    sh 'gulp clean'
  end

  task :build do
    sh 'gulp build'
  end
end

task :clean   => ['gulp:clean']
task :clobber => ['gulp:clean', 'ruby:clobber_package']

desc 'Compile Genghis'
task :build   => ['gulp:clean', 'gulp:build']
task :default => [:build]

def modify_base_gemspec
  eval(File.read('genghisapp.gemspec')).tap { |s| yield s }
end

namespace :ruby do
  spec = modify_base_gemspec do |s|
    s.platform = Gem::Platform::RUBY
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end
end

[:mingw32, :mswin32].each do |v|
  namespace v do
    spec = modify_base_gemspec do |s|
      s.add_dependency 'windows-pr',    '~> 1.2'
      s.add_dependency 'win32-process', '~> 0.7.0'
      s.platform = "i386-#{v}"
    end

    Gem::PackageTask.new(spec) do |pkg|
      pkg.need_zip = false
      pkg.need_tar = false
    end
  end
end

desc 'Build all platform gems'
task :gems => [:build, 'ruby:gem', 'mswin32:gem', 'mingw32:gem']

namespace :gems do
  desc 'Build and push latest gems'
  task :push => :gems do
    chdir("#{File.dirname(__FILE__)}/pkg") do
      Dir['*.gem'].each do |gemfile|
        # sh "gem push #{gemfile}"
        puts "gem push #{gemfile}"
      end
    end
  end
end