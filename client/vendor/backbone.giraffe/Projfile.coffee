fs = require('fs')
async = require('async')
pkg = require('./package.json')

exports.server =
  dirname: 'dist/'


exports.project = (pm) ->
  {f, $, Utils} = pm
  $.registerExecutable 'git'
  pm.filters require('pm-tutdown')
  pm.load require('./Projtest.coffee'), ns: 'test'

  changeToDist = f.tap (asset) ->
    asset.filename = asset.filename.replace(/^src/, 'dist')

  changeExtname = (extname) ->
    return f.tap (asset) ->
      asset.filename = Utils.changeExtname(asset.filename, extname)

  updateVersion = f.tap (asset) -> asset.text = asset.text.replace('{{VERSION}}', pkg.version)

  getFileSize = (path) ->
    file = fs.statSync(path)
    (Math.round(file.size / 100) / 10) + 'k'

  replaceFileSize = (asset, match, file) ->
    asset.text = asset.text.replace(match, getFileSize('dist/' + file))

  updateFileSize = f.tap (asset) ->
    replaceFileSize asset, /\{\{FILE_SIZE_CONTRIB_MIN\}\}/g, 'backbone.giraffe.contrib.min.js'
    replaceFileSize asset, /\{\{FILE_SIZE_CONTRIB\}\}/g, 'backbone.giraffe.contrib.js'
    replaceFileSize asset, /\{\{FILE_SIZE_MIN\}\}/g, 'backbone.giraffe.min.js'
    replaceFileSize asset, /\{\{FILE_SIZE\}\}/g, 'backbone.giraffe.js'

  all: ['clean', 'giraffe', 'miniGiraffe', 'readme', 'docs', 'stylesheets', 'staticFiles', 'test:all']

  giraffe:
    desc: 'Builds Giraffe'
    files: 'src/backbone*.coffee'
    dev: [
      updateVersion
      f.coffee
      f.writeFile _filename: {replace: [/^src/, 'dist']}
      f.writeFile _filename: {replace: [/^dist/, 'dist/docs']}
    ]

  miniGiraffe:
    desc: 'Builds Minified Giraffe'
    files: 'src/backbone*.coffee'
    dev: [
      updateVersion
      f.coffee
      f.uglify
      f.tap (asset) ->
        asset.dirname = 'dist'
        asset.basename = asset.basename.replace(/\.js$/, '.min.js')
      f.writeFile _filename: {replace: [/^src/, 'dist']}
      f.writeFile _filename: {replace: [/^dist/, 'dist/docs']}
    ]

  readme:
    desc: 'Builds README.md'
    files: '_README.md'
    dev: [
      f.preproc root: process.cwd()
      updateVersion
      updateFileSize
      f.writeFile _filename: {replace: [/\_/, '']}
    ]

  # _docs
  _copyLicense:
    desc: 'Copies LICENSE to be made into an HTML file'
    files: ['LICENSE']
    dev: [
      f.tap (asset) ->
        asset.filename = switch asset.filename
          when 'LICENSE' then 'src/docs/license.md'
      f.writeFile
    ]

  _deleteTempLicense:
    desc: 'Deletes copied LICENSE'
    dev: ->
      $.rm 'src/docs/license.md'

  _toc:
    files: 'src/docs/_toc.md'
    dev: [
      f.tutdown assetsDirname: 'dist/docs/assets'
      f.writeFile _filename: 'dist/docs/_toc.html'
    ]

  _docs:
    desc: 'Builds docs'
    deps: ['_toc']
    files: [
      'src/docs/*.md'
      '!src/docs/_toc.md'
    ]
    dev: [
      f.preproc root: process.cwd()
      updateVersion
      updateFileSize
      f.tutdown
        templates:
          example: fs.readFileSync('src/docs/_example.mustache', 'utf8')
          uml: fs.readFileSync('src/docs/_uml.mustache', 'utf8')
        assetsDirname: 'dist/docs/assets'
      f.tap (asset) ->
        asset.nav = fs.readFileSync('dist/docs/_toc.html')
      f.template
        delimiters: 'mustache'
        filename: 'src/docs/_layout.mustache'
        navHeader: ''
      f.tap (asset) ->
        asset.filename = asset.filename.replace(/^src/, 'dist')
      f.writeFile
    ]

  _api:
    desc: 'Builds API documentation'
    deps: ['stylesheets', 'staticFiles']
    files: ['src/backbone.giraffe.coffee']
    dev: [
      f.tutdown commentFiller: '* '  #, debug:true
      f.template
        delimiters: 'mustache'
        filename: 'src/docs/_layout.mustache'
        navHeader:
          """
          <h2><a href="index.html">Examples</a></h2>
          <h2><a href="backbone.giraffe.html">Giraffe API</a></h2>
          <!-- <h2><a href="backbone.giraffe.contrib.html">Giraffe.Contrib API</a></h2> -->
          """
      f.tap (asset) -> asset.dirname = 'dist/docs'
      f.writeFile
    ]

  docs:
    desc: 'Builds the docs'
    deps: ['prep', '_copyLicense', '_docs', '_deleteTempLicense', '_api']

  stylesheets:
    desc: 'Builds less files'
    files: ['src/docs/css/*.less']
    dev: [
      f.less dumpLineNumbers: null
      changeToDist
      f.writeFile
    ]

  staticFiles:
    desc: 'Copies static files'
    dev: ->
      $.cp '-rf', 'src/docs/img', 'dist/docs'
      # needed since we only copy dist/docs/* to gh-pages
      #$.cp 'dist/backbone.giraffe*js', 'dist/docs'

  prep: ->
    $.mkdir '-p', 'dist/docs/assets'

  clean: ->
    $.rm '-rf', 'dist'
    $.rm '-f', 'README.md'

  "gh-pages":
    desc: "Creates/updates gh-pages branch"
    dev: (cb) ->
      this.timeout = 30000

      GH_PAGES = '_gh-pages'
      ensureGhPagesBranch = (cb) ->
        if $.test('-d', GH_PAGES)
          cb()
        else
          $ .git "clone git@github.com:barc/backbone.giraffe #{GH_PAGES}", (err) ->
            return cb(err) if err
            $.inside GH_PAGES, (popcb) ->
              $.git "checkout -t origin/gh-pages", popcb(cb)

      updateRepo = (cb) ->
        $.inside GH_PAGES, (popcb) ->
          $ .git("checkout gh-pages")
            .git("pull origin gh-pages")
            .start popcb(cb)

      updateFiles = (cb) ->
        $.cp '-rf', 'dist/docs/*', GH_PAGES
        cb()

      async.series [ensureGhPagesBranch, updateRepo, updateFiles], (err) ->
        if err
          $.error 'ERROR', err
        else
          $.info '_gh-pages updated. cd into it and `git push origin gh-pages`'
        cb()

