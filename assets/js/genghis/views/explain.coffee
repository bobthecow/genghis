define (require) ->
  View     = require('genghis/views/view')
  Util     = require('genghis/util')
  template = require('hgn!genghis/templates/explain')

  class Explain extends View
    el:       'section#explain'
    template: template

    ui:
      '$doc': '.document'

    modelEvents:
      'sync': 'updateExplain'

    initialize: ->
      @render()

    afterRender: ->
      Util.attachCollapsers @$('article')[0]

    updateExplain: ->
      @$doc.html @model.prettyPrint()
      @$el.removeClass 'spinning'

    show: ->
      $('body').addClass "section-#{@$el.attr('id')}"
      @$el.addClass('spinning').show()
      $(document).scrollTop 0

    hide: ->
      $('body').removeClass "section-#{@$el.attr('id')}"
      @$el.hide()


