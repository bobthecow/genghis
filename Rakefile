require 'rake/clean'
require 'yaml'
require 'erb'
require 'less'
require 'rainpress'
require 'uglifier'
require 'html_compressor'
require 'digest/md5'
require 'base64'
require 'json'
require 'bundler'
require 'rspec/core/rake_task'

GENGHIS_VERSION = File.read('VERSION.txt').strip

tmp_dir = 'tmp/'

def data_uri(filename)
  "data:image/#{File.extname(filename)[1..-1]};base64,#{Base64.strict_encode64(File.read(filename))}"
end

# sweet mixin action
class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end

  def camelize
    self.to_s.sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
  end
end

desc 'Compile Genghis'
task :build => 'build:all'

namespace :build do
  desc 'Compile Genghis CSS assets'
  task :css => [ tmp_dir+'style.css' ]

  desc 'Compile Genghis JavaScript assets'
  task :js  => [ tmp_dir+'script.js' ]

  desc 'Compile PHP Genghis w/ CSS and JS'
  task :all_php => [ 'genghis.php', 'build:js', 'build:css' ]

  desc 'Compile Ruby Genghis w/ CSS and JS'
  task :all_rb => [ 'genghis.rb', 'build:js', 'build:css' ]

  desc 'Compile Both PHP and Ruby versions of Genghis'
  task :all => [ 'genghis.php', 'genghis.rb', 'build:js', 'build:css' ]
end

directory tmp_dir

file tmp_dir+'backgrounds.css' => FileList[
  tmp_dir,
  'assets/img/backgrounds/*.png',
  'src/templates/backgrounds.css.erb'
] do
  File.open(tmp_dir+'backgrounds.css', 'w') do |file|
    body         = data_uri('assets/img/backgrounds/body.png')
    grippie      = data_uri('assets/img/backgrounds/grippie.png')
    nav          = data_uri('assets/img/backgrounds/nav.png')
    servers_spin = data_uri('assets/img/backgrounds/servers_spin.gif')
    section_spin = data_uri('assets/img/backgrounds/section_spin.gif')

    file << ERB.new(File.read('src/templates/backgrounds.css.erb')).result(binding)
  end
end

css_files = [
  'assets/vendor/codemirror/lib/codemirror.css',
  'assets/vendor/keyscss/keys.css',
  tmp_dir+'backgrounds.css',
]

file tmp_dir+'style.css' => FileList[
  tmp_dir,
  'assets/css/*.less',
  'assets/vendor/bootstrap/less/*.less',
  *css_files
] do
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

    css = ''

    css_files.each do |f|
      css << File.read(f)
    end

    parser = Less::Parser.new(:paths => ['./assets/css'], :filename => 'assets/css/style.less')
    css << parser.parse(File.read('assets/css/style.less')).to_css

    file << Rainpress.compress(css)
  end
end

script_dependency_files = FileList[
  'assets/js/**/*.js',
  'assets/vendor/**/*.js',
]
file tmp_dir+'genghis.js' => [ tmp_dir ] + script_dependency_files do
  `r.js -o build.js`
end

file tmp_dir+'script.js' => [ tmp_dir, tmp_dir+'genghis.js' ] do
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

    file << File.read(tmp_dir+'genghis.js')
  end
end

file tmp_dir+'index.html.mustache' => FileList[
  tmp_dir, 'src/templates/index.html.mustache.erb', 'assets/img/favicon.png', 'assets/img/keyboard.png'
] do
  File.open(tmp_dir+'index.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new

    favicon_uri  = data_uri('assets/img/favicon.png')
    keyboard_uri = data_uri('assets/img/keyboard.png')

    index = ERB.new(File.read('src/templates/index.html.mustache.erb')).result(binding)

    file << packer.compress(index)
  end
end

file tmp_dir+'error.html.mustache' => FileList[tmp_dir, 'src/templates/index.html.mustache.erb', 'assets/img/favicon.png'] do
  File.open(tmp_dir+'error.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new

    favicon_uri = data_uri('assets/img/favicon.png')

    tpl = ERB.new(File.read('src/templates/error.html.mustache.erb')).result(binding)

    file << packer.compress(tpl)
  end
end

asset_files = [tmp_dir+'index.html.mustache', tmp_dir+'error.html.mustache', tmp_dir+'style.css', tmp_dir+'script.js']

php_include_files = FileList['src/php/**/*.php'].sort.reject {|f| f == 'src/php/Genghis/AssetLoader/Dev.php' }
file 'genghis.php' => php_include_files + asset_files do
  File.open('genghis.php', 'w') do |file|
    template = ERB.new(File.read('src/templates/genghis.php.erb'))

    includes = php_include_files.map { |inc| `php -w #{inc}` }
    assets = asset_files.map do |asset|
      content = File.read(asset)
      { :name => asset.sub(/^tmp\//, ''), :content => content, :etag => Digest::MD5.hexdigest(content) }
    end

    file << template.result(binding)
  end
end

rb_include_files = FileList[
  'src/rb/genghis/json.rb',
  'src/rb/genghis/errors.rb',
  'src/rb/genghis/models/**/*',
  'src/rb/genghis/helpers.rb',
  'src/rb/genghis/server.rb',
]
asset_files = [tmp_dir+'index.html.mustache', tmp_dir+'error.html.mustache', tmp_dir+'style.css', tmp_dir+'script.js']
file 'genghis.rb' => rb_include_files + asset_files do
  File.open('genghis.rb', 'w') do |file|
    template = ERB.new(File.read('src/templates/genghis.rb.erb'))

    includes = rb_include_files.map { |inc| File.read(inc) }
    assets = asset_files.map do |asset|
      content = File.read(asset)
      { :name => asset.sub(/^tmp\//, ''), :content => content, :etag => Digest::MD5.hexdigest(content) }
    end

    file << template.result(binding)
    chmod(0755, file)
  end
end

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)
task :test => :spec

CLEAN.include('tmp/*')
CLOBBER.include('tmp/*', 'genghis.php', 'genghis.rb')
