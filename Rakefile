require 'bundler'

namespace :grunt do
  task :clean do
    puts `grunt clean`
  end

  task :build do
    puts `grunt build`
  end
end

desc 'Compile Genghis'
task :clean   => ['grunt:clean']
task :clobber => ['grunt:clean']
task :build   => ['grunt:clean', 'grunt:build']
task :default => [:build]

Bundler::GemHelper.install_tasks
