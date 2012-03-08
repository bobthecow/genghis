require 'rake/clean'
require 'rake/packagetask'
require 'yaml'
require 'erb'
require 'less'
require 'rainpress'
require 'uglifier'
require 'closure-compiler'
require 'html_compressor'
require 'digest/md5'
require 'base64'

GENGHIS_VERSION = '1.2.0'

# sweet mixin action
class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end

desc "Compile Genghis"
task :build => 'build:all'

namespace :build do
  desc "Compile Genghis CSS assets"
  task :css => [ 'tmp/style.css' ]

  desc "Compile Genghis JavaScript assets"
  task :js  => [ 'tmp/script.js' ]

  task :all => [ 'genghis.php', 'build:js', 'build:css' ]
end

directory 'tmp'

file 'tmp/style.css' => FileList['tmp', 'src/css/*.less'] do
  File.open('tmp/style.css', 'w') do |file|
    file << <<-doc.unindent
      /**
       * Genghis v#{GENGHIS_VERSION}
       *
       * The single-file MongoDB admin app
       *
       * http://genghisapp.com
       *
       * @author Justin Hileman <justin@justinhileman.info>
       */
    doc

    parser = Less::Parser.new(:paths => ['./src/css'], :filename => 'src/css/style.less')
    css = parser.parse(File.read('src/css/style.less')).to_css
    file << (ENV['NOCOMPRESS'] ? css : Rainpress.compress(css))
  end
end

script_files = FileList[
  # vendor libraries
  'src/js/jquery.js',
  'src/js/jquery.hoverintent.js',
  'src/js/jquery.tablesorter.js',
  'src/js/underscore.js',
  'src/js/backbone.js',
  'vendor/ace/ace-uncompressed.js',
  'vendor/ace/mode-json.js',
  'vendor/ace/theme-git_hubby.js',
  'vendor/apprise/apprise-1.5.full.js',
  'vendor/bootstrap/js/bootstrap-tooltip.js',
  'vendor/bootstrap/js/bootstrap-popover.js',
  'vendor/bootstrap/js/bootstrap-modal.js',

  # extensions
  'src/js/extensions.js',

  # genghis app
  'src/js/genghis/bootstrap.js',
  'src/js/genghis/util.js',
  'src/js/genghis/base/**/*',
  'src/js/genghis/models/**/*',
  'src/js/genghis/collections/**/*',
  'src/js/genghis/views/**/*',
  'src/js/genghis/router.js'
]
file 'tmp/script.js' => ['tmp'] + script_files do
  # ugly = Uglifier.new(:copyright => false)
  ugly = Closure::Compiler.new
  File.open('tmp/script.js', 'w') do |file|
    file << <<-doc.unindent
      /**
       * Genghis v#{GENGHIS_VERSION}
       *
       * The single-file MongoDB admin app
       *
       * http://genghisapp.com
       *
       * @author Justin Hileman <justin@justinhileman.info>
       */
    doc

    js_src = script_files.map{ |s| File.read(s) }.join(";\n")
    file << (ENV['NOCOMPRESS'] ? js_src : ugly.compile(js_src))
  end
end

file 'tmp/index.html.mustache' => FileList[
  'tmp', 'src/templates/partials/*.html.js',
  'src/templates/index.html.mustache.erb', 'src/img/favicon.png'
] do
  File.open('tmp/index.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new
    # include partials
    templates = FileList['src/templates/partials/*.html.js'].map do |name|
      {
        :name => name.sub(/^src\/templates\/partials\/(.*)\.html\.js$/, '\1'),
        :content => ENV['NOCOMPRESS'] ? File.read(name) : packer.compress(File.read(name))
      }
    end

    favicon_uri = "data:image/png;base64,#{Base64.encode64(File.read('src/img/favicon.png'))}"

    index = ERB.new(File.read('src/templates/index.html.mustache.erb')).result(binding)
    if ENV['NOCOMPRESS']
      file << index
    else
      file << packer.compress(index)
    end
  end
end

file 'tmp/error.html.mustache' => FileList['tmp', 'src/templates/index.html.mustache.erb'] do
  File.open('tmp/error.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new

    tpl = ERB.new(File.read('src/templates/error.html.mustache.erb')).result(binding)
    if ENV['NOCOMPRESS']
      file << tpl
    else
      file << packer.compress(tpl)
    end
  end
end

include_files = FileList['src/php/**/*.php']
asset_files = ['tmp/index.html.mustache', 'tmp/error.html.mustache', 'tmp/style.css', 'tmp/script.js']
file 'genghis.php' => include_files + asset_files do
  File.open('genghis.php', 'w') do |file|
    template = ERB.new(File.read('src/templates/genghis.php.erb'))

    includes = include_files.map { |inc| ENV['NOCOMPRESS'] ? File.read(inc) : `php -w #{inc}` }
    assets = asset_files.map do |asset|
      content = File.read(asset)
      { :name => asset.sub(/^tmp\//, ''), :content => content, :etag => Digest::MD5.hexdigest(content) }
    end

    file << template.result(binding)
  end
end

Rake::PackageTask.new('genghis', GENGHIS_VERSION) do |p|
  p.need_tar = true
  p.package_files.include('genghis.php', '.htaccess', 'README.markdown')
end

CLEAN.include('tmp/*')
CLOBBER.include('tmp/*', 'genghis.php')
