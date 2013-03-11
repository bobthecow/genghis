require 'rake/clean'
require 'rake/packagetask'
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

GENGHIS_VERSION = File.read('VERSION').strip

tmp_dir = ENV['NOCOMPRESS'] ? 'tmp/uncompressed/' : 'tmp/compressed/'

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
  'src/img/backgrounds/*.png',
  'src/templates/backgrounds.css.erb'
] do
  File.open(tmp_dir+'backgrounds.css', 'w') do |file|
    body         = data_uri('src/img/backgrounds/body.png')
    grippie      = data_uri('src/img/backgrounds/grippie.png')
    nav          = data_uri('src/img/backgrounds/nav.png')
    servers_spin = data_uri('src/img/backgrounds/servers_spin.gif')
    section_spin = data_uri('src/img/backgrounds/section_spin.gif')

    file << ERB.new(File.read('src/templates/backgrounds.css.erb')).result(binding)
  end
end

css_files = [
  'vendor/codemirror/lib/codemirror.css',
  'vendor/keyscss/keys.css',
  tmp_dir+'backgrounds.css',
]

file tmp_dir+'style.css' => FileList[
  tmp_dir,
  'src/css/*.less',
  'vendor/bootstrap/less/*.less',
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

    parser = Less::Parser.new(:paths => ['./src/css'], :filename => 'src/css/style.less')
    css << parser.parse(File.read('src/css/style.less')).to_css

    file << (ENV['NOCOMPRESS'] ? css : Rainpress.compress(css))
  end
end

file tmp_dir+'templates.js' => FileList[tmp_dir, 'vendor/hogan/lib/*.js', 'src/templates/partials/*.mustache'] do
  File.open(tmp_dir+'templates.js', 'w') do |file|
    context = ExecJS.compile(File.read('vendor/hogan/web/builds/2.0.0/hogan-2.0.0.js'))
    FileList['src/templates/partials/*.mustache'].each do |name|
      key     = name.sub(/^src\/templates\/partials\/(.*)\.mustache$/, '\1').camelize
      content = context.eval("Hogan.compile(#{File.read(name).inspect}, {asString: true})")
      file << "Genghis.Templates.#{key} = new Hogan.Template({code: #{content}});\n"
    end
  end
end

file tmp_dir+'version.js' => FileList['VERSION'] do
  File.open(tmp_dir+'version.js', 'w') do |file|
    file << "Genghis.version = #{GENGHIS_VERSION.inspect};\n"
  end
end

app_script_files = FileList[
  'src/js/genghis/bootstrap.js',
  tmp_dir+'version.js',
  tmp_dir+'templates.js',
  'src/js/genghis/util.js',
  'src/js/genghis/json.js',
] +
FileList['src/js/genghis/base/**/*.js'].sort        +
FileList['src/js/genghis/models/**/*.js'].sort      +
FileList['src/js/genghis/collections/**/*.js'].sort +
FileList['src/js/genghis/views/**/*.js'].sort       +
FileList[
  'src/js/genghis/router.js'
]

script_files     = FileList[
  # vendor libraries
  'src/js/modernizr.js',
  'src/js/modernizr-detects.js',
  'vendor/jquery.js',
  'vendor/jquery.hoverIntent.js',
  'vendor/jquery.tablesorter.js',
  'vendor/underscore.js',
  'vendor/backbone.js',
  'vendor/codemirror/lib/codemirror.js',
  'vendor/codemirror/mode/javascript/javascript.js',
  'vendor/bootstrap/js/bootstrap-dropdown.js',
  'vendor/bootstrap/js/bootstrap-tooltip.js',
  'vendor/bootstrap/js/bootstrap-popover.js',
  'vendor/bootstrap/js/bootstrap-modal.js',
  'vendor/esprima/esprima.js',
  'vendor/mousetrap/mousetrap.js',
  'vendor/hogan/lib/template.js',

  # extensions
  'src/js/extensions.js',
] + app_script_files
file tmp_dir+'script.js' => [ tmp_dir, tmp_dir+'templates.js' ] + script_files do
  ugly = Uglifier.new(:copyright => false, :ascii_only => true)
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
  tmp_dir, 'src/templates/index.html.mustache.erb', 'src/img/favicon.png', 'src/img/keyboard.png'
] do
  File.open(tmp_dir+'index.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new

    favicon_uri  = data_uri('src/img/favicon.png')
    keyboard_uri = data_uri('src/img/keyboard.png')

    index = ERB.new(File.read('src/templates/index.html.mustache.erb')).result(binding)

    file << (ENV['NOCOMPRESS'] ? index : packer.compress(index))
  end
end

file tmp_dir+'error.html.mustache' => FileList[tmp_dir, 'src/templates/index.html.mustache.erb', 'src/img/favicon.png'] do
  File.open(tmp_dir+'error.html.mustache', 'w') do |file|
    packer = HtmlCompressor::HtmlCompressor.new

    favicon_uri = data_uri('src/img/favicon.png')

    tpl = ERB.new(File.read('src/templates/error.html.mustache.erb')).result(binding)

    file << (ENV['NOCOMPRESS'] ? tpl : packer.compress(tpl))
  end
end

asset_files = [tmp_dir+'index.html.mustache', tmp_dir+'error.html.mustache', tmp_dir+'style.css', tmp_dir+'script.js']

php_include_files = FileList['src/php/**/*.php'].sort.reject {|f| f == 'src/php/Genghis/AssetLoader/Dev.php' }
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
      { :name => asset.sub(/^tmp\/(un)?compressed\//, ''), :content => content, :etag => Digest::MD5.hexdigest(content) }
    end

    file << template.result(binding)
    chmod(0755, file)
  end
end

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)
task :test => :spec

Rake::PackageTask.new('genghis', GENGHIS_VERSION) do |p|
  p.need_tar = true
  p.package_files.include('genghis.php', 'genghis.rb', '.htaccess', 'README.markdown', 'LICENSE', 'CHANGELOG.markdown')
end

CLEAN.include('tmp/*')
CLOBBER.include('tmp/*', 'genghis.php', 'genghis.rb')
