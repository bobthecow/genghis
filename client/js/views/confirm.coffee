{$, _}   = require '../vendors'
View     = require './view'
template = require('../../templates/confirm.mustache').render

class Confirm extends View
  className: 'modal confirm-modal'
  template:  template

  ui:
    '$confirm': 'button.confirm'
    '$input':   'input.confirm-input'

  events:
    'click $confirm':       'confirm'
    'click button.dismiss': 'dismiss'
    'keyup .confirm-input': 'validateInput'

  keyboardEvents:
    'esc':   'dismiss'
    'enter': 'confirm'

  defaultOptions:
    header:      null
    body:        'Really? There is no undo.'
    confirmText: 'Okay'
    dismissText: 'Cancel'
    isDangerous: true
    keyboard:    false

  omittedOptions: ['parse', 'confirm']

  initialize: (options) ->
    @onConfirm = options.confirm or $.noop
    @render() if options.show isnt false

  afterRender: ->
    if @confirmInput
      @$el.on('shown.bs.modal', => @$input.focus())
    @$el.modal({@backdrop, @keyboard})

  confirm: =>
    return unless @inputIsValid()
    @onConfirm()
    @dismiss()

  validateInput: (e) =>
    if @inputIsValid()
      @$confirm.removeAttr('disabled')
    else
      @$confirm.attr('disabled', true)

    if e.keyCode is 27 # escape
      @dismiss()
    else if e.keyCode is 13 # enter
      e.preventDefault()
      @confirm()

  inputIsValid: =>
    !@confirmInput or (@$input.val() is @confirmInput)

  dismiss: =>
    @$el.on('hidden.bs.modal', @detach).modal('hide')

  dangerLevel: =>
    if @isDangerous then 'btn-danger' else 'btn-primary'

module.exports = Confirm
