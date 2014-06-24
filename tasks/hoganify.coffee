hogan   = require 'hogan.js'
through = require 'through'

EXT_PATTERN = /\.(html|hogan|hg|mustache|ms)$/

wrap = (template) ->
  """
  var t = new (require('hogan/lib/template')).Template(#{template});

  module.exports = function () {
    return t.render.apply(t, arguments);
  };
  """

module.exports = (file, opts = {}) ->
  return through() unless EXT_PATTERN.test(file)
  input = ""

  write = (buffer) ->
    input += buffer

  end = ->
    @queue wrap(hogan.compile(input, asString: true))
    @queue null

  through(write, end)
