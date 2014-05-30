fs        = require 'fs'
es        = require 'event-stream'
_         = require 'lodash'
path      = require 'path'
datauri   = require 'datauri'
minimatch = require 'minimatch'

# todo: use css-parse to only replace urls in css properties.
URL_RE      = /^url\(\s*((["'])(.+?)\2|([^"'][^)]*))\s*\)$/
ALL_URLS_RE = /\burl\(\s*((["'])(.+?)\2|([^"'][^)]*))\s*\)/g
EXTERNAL_RE = /^(data|https?):/

escapeRe = (str) ->
  "#{str}".replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1")

replaceUrl = (value, cb) ->
  match = value.match(URL_RE)
  if match
    url = match[3] or match[4]
    newUrl = cb(url)
    return value.replace(match[0], match[0].replace(match[1], newUrl)) if newUrl
  value

replaceAllUrls = (styles, cb) ->
  matches = styles.match(ALL_URLS_RE)
  if matches
    _.uniq(matches).forEach (match) ->
      newVal = replaceUrl(match, cb)
      styles = styles.replace(new RegExp(escapeRe(match), 'g'), newVal) if newVal
  styles

isGlobMatch = (target, filePath) ->
  _.any target, (glob) ->
    minimatch filePath, glob

module.exports = (opt = {}) ->
  es.map (file, cb) ->
    opt = _.extend({
      base:   path.join(file.cwd, path.dirname(file.path)),
      target: '**/*.{png,gif,jpg,svg}'
    }, opt)

    base   = path.resolve(file.cwd, opt.base || '')
    target = opt.target
    target = [target] unless _.isArray(target)
    target = _.map((if _.isArray(opt.target) then opt.target else [opt.target]), (glob) ->
      path.resolve file.cwd, glob
    )

    file.contents = new Buffer(replaceAllUrls(file.contents.toString(), (url) ->

      # Don't replace data: or http: urls.
      return if url.match(EXTERNAL_RE)
      filePath = path.resolve(base, url)

      return unless isGlobMatch(target, filePath)
      return unless fs.existsSync(filePath)

      datauri(filePath)
    ))

    cb(null, file)
