require 'bundler'

namespace :gulp do
  task :clean do
    puts `gulp clean`
  end

  task :build do
    puts `gulp build`
  end
end

desc 'Compile Genghis'
task :clean   => ['gulp:clean']
task :clobber => ['gulp:clean']
task :build   => ['gulp:clean', 'gulp:build']
task :default => [:build]

Bundler::GemHelper.install_tasks
