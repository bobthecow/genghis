define (require) ->
  $            = require('jquery')
  _            = require('underscore')
  View         = require('genghis/views/view')
  DocumentView = require('genghis/views/document')
  template     = require('hgn!genghis/templates/document_section')

  class DocumentSection extends View
    el:       'section#document'
    template: template

    ui:
      $content: '.content'

    modelEvents:
      change: 'render'

    afterRender: ->
      @$el.removeClass 'spinning'
      view = new DocumentView(model: @model)
      @$content.html view.render().el

    show: ->
      $('body').addClass "section-#{@$el.attr('id')}"
      @$el.addClass('spinning').show()
      $(document).scrollTop 0

    hide: ->
      $('body').removeClass "section-#{@$el.attr('id')}"
      @$el.hide()
