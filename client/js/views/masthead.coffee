View     = require './view'
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

  afterRender: ->
    @$el
      .toggleClass('error',  @error)
      .toggleClass('epic',   @epic)
      .toggleClass('sticky', @sticky)

module.exports = Masthead
