exports.project = (pm) ->
  {f, $} = pm

  _updateMocha: ->
    testsDir = 'src/tests'
    $.cp 'node_modules/mocha/mocha.js', testsDir
    $.cp 'node_modules/mocha/mocha.css', testsDir
    $.cp_rf 'node_modules/mocha/images', testsDir
    $.cp 'node_modules/chai/chai.js', testsDir
    $.cp 'node_modules/sinon/pkg/sinon.js', testsDir

  scripts:
    description: 'Compiles test Coffee scripts'
    files: 'src/tests/**/*.coffee'
    dev: [
      f.coffee sourceMap: true
      f.writeFile _filename: { replace: [/^src/, 'dist']}
    ]

  statics:
    description: 'Copies static files'
    dev: ->
      $.xcopy 'src/tests/', 'dist/tests'
      $.rm 'dist/tests/*coffee'

  all: ['scripts', 'statics']


