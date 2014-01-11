{$}      = require '../vendors'
View     = require './view.coffee'
Util     = require '../util.coffee'
template = require '../../templates/explain.mustache'

class Explain extends View
  id:       'explain'
  tagName:  'section'
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

module.exports = Explain
