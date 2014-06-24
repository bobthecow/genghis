fs      = require 'fs'
path    = require 'path'
bower   = require 'bower'
resolve = require 'resolve'

bowerModules = undefined

__extend = (obj, sources...) ->
  for source in sources
    obj[key] = val for key, val of source
  obj

withBower = (cb) ->
  return cb() if bowerModules
  bower.commands.list({map: true}, {offline: true})
    .on 'end', (map) ->
      bowerModules = map.dependencies
      cb()

isRelative = (id) ->
  id.match(/^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/)

isAbsolute = (id) ->
  id.match(/^\//)

PATH_SPLIT_RE = if process.platform == 'win32' then /[\/\\]/ else /\/+/

bowerModule = (id) ->
  [pkg, rest...] = id.split(PATH_SPLIT_RE)
  return pkg if pkg of bowerModules

resolver = (id, opts, cb) ->
  # The easy case: Browserify gives us these for free
  if id of opts.modules
    return cb(null, opts.modules[id], opts)

  base = path.dirname(opts.filename)

  # This one's also low-hanging fruit: relative and absolute paths
  # TODO: sanitize those options or make 'em explicit
  if isRelative(id) || isAbsolute(id)
    return resolve(id, __extend({basedir: base}, opts), cb)

  # Since we don't allow node_modules, the rest must be Bower modules,
  # so let's go find 'em!
  withBower ->
    if moduleName = bowerModule(id)
      module = bowerModules[moduleName]

      # They're not asking for the module directly...
      if id != moduleName
        # So we'll use a normal resolver to sort it out.
        # TODO: sanitize those options, or make 'em explicit
        return resolve(id.replace(moduleName, '.'), __extend({basedir: module.canonicalDir}, opts), cb)

      mainModule = module.pkgMeta?.main
      if Array.isArray(mainModule)
        mainModule = mainModule.filter((f) -> /\.js$/.test(f))[0]

      if mainModule
        return cb(null, path.resolve(path.join(module.canonicalDir, mainModule)), opts)

      # Nothing so far, so let's try guessing as a last-ditch effort.
      fullPath = path.join(module.canonicalDir, "#{moduleName}.js")
      fs.exists fullPath, (exists) ->
        if exists
          cb(null, fullPath, opts)

module.exports = resolver
