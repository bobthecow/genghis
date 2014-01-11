View     = require './view.coffee'
template = require '../../templates/masthead.mustache'

class Masthead extends View
  tagName:   'header'
  className: 'masthead'
  template:  template

  defaultOptions:
    content: ''
    error:   false
    epic:    false
    sticky:  false

  initialize: ->
    @render()

  serialize: ->
    {@heading, @content}

  afterRender: ->
    @$el
      .toggleClass('error',  @error)
      .toggleClass('epic',   @epic)
      .toggleClass('sticky', @sticky)
      .insertAfter('header.navbar')

module.exports = Masthead
