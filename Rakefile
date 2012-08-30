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

GENGHIS_VERSION = '1.4.2'

tmp_dir = ENV['NOCOMPRESS'] ? 'tmp/uncompressed/' : 'tmp/compressed/'

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
  task :css => [ tmp_dir+'style.css' ]

  desc "Compile Genghis JavaScript assets"
  task :js  => [ tmp_dir+'script.js' ]

  desc "Compile PHP Genghis w/ CSS and JS"
  task :all_php => [ 'genghis.php', 'build:js', 'build:css' ]

  desc "Compile Ruby Genghis w/ CSS and JS"
  task :all_rb => [ 'genghis.rb', 'build:js', 'build:css' ]

  desc "Compile Both PHP and Ruby versions of Genghis"
  task :all => [ 'genghis.php', 'genghis.rb', 'build:js', 'build:css' ]
end

directory tmp_dir

file tmp_dir+'style.css' => FileList[tmp_dir, 'src/css/*.less', 'vendor/bootstrap/less/*.less', 'vendor/keyscss/keys.css'] do
  File.open(tmp_dir+'style.css', 'w') do |file|
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

    css = File.read('vendor/keyscss/keys.css')

    parser = Less::Parser.new(:paths => ['./src/css'], :filename => 'src/css/style.less')
    css << parser.parse(File.read('src/css/style.less')).to_css

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
  'vendor/hotkeys/jquery.hotkeys.js',

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

file tmp_dir+'script.js' => [ tmp_dir ] + script_files do
  # ugly = Uglifier.new(:copyright => false)
  ugly = Closure::Compiler.new
  File.open(tmp_dir+'script.js', 'w') do |file|
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

file tmp_dir+'index.html.mustache' => FileList[
  tmp_dir, 'src/templates/partials/*.html.js',
  'src/templates/index.html.mustache.erb', 'src/img/favicon.png', 'src/img/keyboard.png'
] do
  File.open(tmp_dir+'index.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new
    # include partials
    templates = FileList['src/templates/partials/*.html.js'].map do |name|
      {
        :name => name.sub(/^src\/templates\/partials\/(.*)\.html\.js$/, '\1'),
        :content => ENV['NOCOMPRESS'] ? File.read(name) : packer.compress(File.read(name))
      }
    end

    favicon_uri  = "data:image/png;base64,#{Base64.encode64(File.read('src/img/favicon.png'))}"
    keyboard_uri = "data:image/png;base64,#{Base64.encode64(File.read('src/img/keyboard.png'))}"

    index = ERB.new(File.read('src/templates/index.html.mustache.erb')).result(binding)
    if ENV['NOCOMPRESS']
      file << index
    else
      file << packer.compress(index)
    end
  end
end

file tmp_dir+'error.html.mustache' => FileList[tmp_dir, 'src/templates/index.html.mustache.erb', 'src/img/favicon.png'] do
  File.open(tmp_dir+'error.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new

    favicon_uri  = "data:image/png;base64,#{Base64.encode64(File.read('src/img/favicon.png'))}"

    tpl = ERB.new(File.read('src/templates/error.html.mustache.erb')).result(binding)
    if ENV['NOCOMPRESS']
      file << tpl
    else
      file << packer.compress(tpl)
    end
  end
end

asset_files = [tmp_dir+'index.html.mustache', tmp_dir+'error.html.mustache', tmp_dir+'style.css', tmp_dir+'script.js']

php_include_files = FileList['src/php/**/*.php']
file 'genghis.php' => php_include_files + asset_files do
  File.open('genghis.php', 'w') do |file|
    template = ERB.new(File.read('src/templates/genghis.php.erb'))

    includes = php_include_files.map { |inc| ENV['NOCOMPRESS'] ? File.read(inc) : `php -w #{inc}` }
    assets = asset_files.map do |asset|
      content = File.read(asset)
      { :name => asset.sub(/^tmp\/(un)?compressed\//, ''), :content => content, :etag => Digest::MD5.hexdigest(content) }
    end

    file << template.result(binding)
  end
end

rb_include_files = FileList['src/rb/*.rb']
asset_files = [tmp_dir+'index.html.mustache', tmp_dir+'error.html.mustache', tmp_dir+'style.css', tmp_dir+'script.js']
file 'genghis.rb' => rb_include_files + asset_files do
  File.open('genghis.rb', 'w') do |file|
    template = ERB.new(File.read('src/templates/genghis.rb.erb'))

    includes = rb_include_files.map { |inc| File.read(inc) }
    assets = asset_files.map do |asset|
      content = File.read(asset)
      { :name => asset.sub(/^tmp\/(un)?compressed\//, ''), :content => content, :etag => Digest::MD5.hexdigest(content) }
    end

    file << template.result(binding)
    chmod(0755, file)
  end
end

Rake::PackageTask.new('genghis', GENGHIS_VERSION) do |p|
  p.need_tar = true
  p.package_files.include('genghis.php', '.htaccess', 'README.markdown')
end

CLEAN.include('tmp/*')
CLOBBER.include('tmp/*', 'genghis.php', 'genghis.rb')
