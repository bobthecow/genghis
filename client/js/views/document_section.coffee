{$, _}       = require '../vendors'
View         = require './view.coffee'
DocumentView = require './document.coffee'
template     = require '../../templates/document_section.mustache'

class DocumentSection extends View
  id:        'document'
  tagName:   'section'
  className: 'app-section'
  template:  template

  ui:
    '$content': '.content'

  dataEvents:
    'change model': 'render'

  afterRender: ->
    view = new DocumentView(model: @model)
    view.attachTo(@$content)

  show: ->
    $('body').addClass("section-#{@id}")
    $(document).scrollTop(0)

  hide: ->
    $('body').removeClass("section-#{@id}")

module.exports = DocumentSection
