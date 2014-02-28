GenghisJSON = require '../json'
View        = require './view'
template    = require('../../templates/sort_custom.mustache').render

class SortCustom extends View
  className: 'form-group'
  template:  template

  ui:
    '$input':  'input'

  events:
    'keyup $input':        'onKeyup'
    'click button.sort':   'save'
    'click button.cancel': 'detach'

  dataEvents:
    'attached this': 'focusInput'

  serialize: =>
    if sort = @model.get('sort')
      value = GenghisJSON.stringify(@model.get('sort'), false) unless _.isEmpty(sort)
    cid:   @cid
    value: value or ''

  onKeyup: (e) =>
    if e.keyCode is 13 # enter
      e.preventDefault()
      @save()
    else if e.keyCode is 27 # esc
      e.preventDefault()
      @detach()
    else if @$el.hasClass('has-error')
      @$el.removeClass('has-error')
      try
        GenghisJSON.parse(@$input.val())
      catch e
        @$el.addClass('has-error')

  save: =>
    try
      sort = GenghisJSON.parse(@$input.val())
    catch e
      @$el.addClass('has-error')
      return
    @model.set('sort', sort)
    @detach()

  focusInput: =>
    @$input.focus()

  getInput: =>
    try
      return GenghisJSON.parse(@$input.val())
    catch e
      @$el.addClass('has-error')
      return

module.exports = SortCustom
