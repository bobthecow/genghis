Util = require '../util'
View = require './view'

class Title extends View
  dataEvents:
    'all model': 'setTitle'

  setTitle: (name, args..., query) ->
    switch name
      when 'route:index', 'route:server', 'route:database', 'route:collection'
        break # we'll just pass these through...
      when 'route:document'
        args.push Util.decodeDocumentId(args.pop())
      when 'route:collectionSearch'
        args.push 'Query results'
      when 'route:explain'
        args.push 'Query explanation'
      when 'route:notFound'
        args = ['Not Found']
      else
        return
    args.unshift 'Genghis'
    document.title = args.join(' › ')

module.exports = Title
