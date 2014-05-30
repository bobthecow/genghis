# From https://github.com/hughsk/vinyl-source-stream/blob/master/index.js
# but with appropriate cwd, base and path.

through2 = require 'through2'
File     = require 'vinyl'
path     = require 'path'

createSourceStream = (filename) ->
  ins = through2()
  out = false

  data = {contents: ins}

  if filename
    filename  = path.resolve(filename)
    data.cwd  = process.cwd()
    data.base = path.dirname(filename)
    data.path = filename

  file = new File(data)

  one = (chunk, enc, next) ->
    unless out
      @push(file)
      out = true
    ins.push(chunk)
    next()

  two = ->
    ins.push(null)
    @push(null)

  through2.obj(one, two)

module.exports = createSourceStream
