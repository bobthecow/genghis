Util = require '../util.coffee'
View = require './view.coffee'

class Title extends View
  modelEvents:
    all: 'setTitle'

  setTitle: (name, args...) ->
    switch name
      when 'route:index', 'route:server', 'route:database', 'route:collection'
        break # we'll just pass these through...
      when 'route:document'
        args.push Util.decodeDocumentId(args.pop())
      when 'route:collectionQuery'
        args.push 'Query results'
      when 'route:explainQuery'
        args.push 'Query explanation'
      when 'route:notFound'
        args = ['Not Found']
      else
        return
    args.unshift 'Genghis'
    document.title = args.join(' › ')

module.exports = Title
