{$}      = require '../vendors'
View     = require './view.coffee'
Util     = require '../util.coffee'
template = require '../../templates/explain.mustache'

class Explain extends View
  id:        'explain'
  tagName:   'section'
  className: 'app-section'
  template:  template

  ui:
    '$doc': '.document'

  events:
    'click button,span.e': Util.toggleCollapser

  dataEvents:
    'sync model': 'updateExplain'

  initialize: ->
    @render()

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

module.exports = Explain
