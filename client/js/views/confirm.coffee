{$, _}   = require '../vendors'
View     = require './view.coffee'
template = require '../../templates/confirm.mustache'

class Confirm extends View
  className: 'modal confirm-modal'
  template:  template
  ui:
    $confirm: 'button.confirm'

  events:
    'click $confirm':       'confirm'
    'click button.dismiss': 'dismiss'
    'keyup .confirm-input': 'validateInput'

  defaults:
    header:      null
    body:        'Really? There is no undo.'
    confirmText: 'Okay'
    dismissText: 'Cancel'

  initialize: (options) ->
    _.bindAll this, 'render', 'confirm', 'validateInput', 'dismiss', 'remove'
    @onConfirm    = options.confirm or $.noop
    @confirmInput = options.confirmInput
    @modalOptions = _.pick(options, 'backdrop', 'keyboard')
    @options = _.pick(options, 'header', 'body', 'confirmText', 'confirmInput', 'dismissText')
    @render()  if options.show isnt false

  serialize: ->
    _.defaults @options, @defaults

  afterRender: ->
    $el = @$el
    if @confirmInput
      $el.on 'shown.bs.modal', ->
        $el.find('.confirm-input').focus()

    $el.modal @modalOptions

  confirm: =>
    @onConfirm()
    @dismiss()

  validateInput: (e) =>
    if $(e.target).val() is @confirmInput
      @$confirm.removeAttr 'disabled'

      # handle enter
      if e.keyCode is 13
        e.preventDefault()
        @$confirm.click()
    else
      @$confirm.attr 'disabled', true

  dismiss: =>
    @$el.on('hidden.bs.modal', @remove).modal 'hide'

module.exports = Confirm
