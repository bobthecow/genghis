View     = require './view'
template = require '../../templates/documents_header.mustache'

class DocumentsHeader extends View
  template: template

  dataEvents:
    'change model': 'render'

  serialize: ->
    count = @model.get('count')
    page  = @model.get('page')
    limit = @model.get('limit')
    total = @model.get('total')

    unless total is count
      from = ((page - 1) * limit) + 1
      to   = Math.min((((page - 1) * limit) + count), total)

    total:  total
    range:  (total isnt count)
    from:   from
    to:     to
    plural: (total isnt 1)

module.exports = DocumentsHeader
