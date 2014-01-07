View     = require './view.coffee'
template = require '../../templates/masthead.mustache'

class Masthead extends View
  tagName:   'header'
  className: 'masthead'
  template:  template

  initialize: (options) ->
    @heading = options.heading
    @content = options.content or ''
    @error   = options.error   or false
    @epic    = options.epic    or false
    @sticky  = options.sticky  or false
    @render()

  serialize: ->
    heading: @heading
    content: @content

  afterRender: ->
    @$el
      .toggleClass('error',  @error)
      .toggleClass('epic',   @epic)
      .toggleClass('sticky', @sticky)
      .insertAfter('header.navbar')

module.exports = Masthead
