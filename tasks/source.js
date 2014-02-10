// From https://github.com/hughsk/vinyl-source-stream/blob/master/index.js
// but with appropriate cwd, base and path.

var through2 = require('through2')
var File = require('vinyl')
var path = require('path')

module.exports = createSourceStream

function createSourceStream(filename) {
  var ins = through2()
  var out = false

  if (filename) {
    filename = path.resolve(filename)
  }

  var file = new File(filename ? {
      cwd:  process.cwd()
    , base: path.dirname(filename)
    , path: filename
    , contents: ins
  } : {
    contents: ins
  })

  return through2({
    objectMode: true
  }, function(chunk, enc, next) {
    if (!out) {
      this.push(file)
      out = true
    }

    ins.push(chunk)
    next()
  }, function() {
    ins.push(null)
    this.push(null)
  })
}
