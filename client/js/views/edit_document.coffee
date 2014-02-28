{_}         = require '../vendors'
CodeMirror  = require '../shims/codemirror'
View        = require './view'
GenghisJSON = require '../json'
AlertView   = require './alert'
Alert       = require '../models/alert'
defaults    = require '../defaults'
template    = require('../../templates/edit_document.mustache').render

class EditDocument extends View
  template:     template
  errorLines:   []
  showControls: true

  ui:
    '$textarea': 'textarea'

  events:
    'click button.save':   'save'
    'click button.cancel': 'cancel'

  dataEvents:
    'attached this': 'refreshEditor'

  serialize: ->
    id:           @model?.id?.replace('~', '-') or 'new',
    showControls: @showControls

  afterRender: =>
    data = if @model? then @model.JSONish() else "{\n    \n}\n"
    @$textarea.text(data)
    @editor = CodeMirror.fromTextArea(@$textarea[0], _.extend({}, defaults.codeMirror,
      autofocus: true
      extraKeys:
        'Ctrl-Enter': @save
        'Cmd-Enter':  @save
    ))
    @editor.setSize(null, @height) if @height

    # hax!
    @editor.setCursor(line: 1, ch: 4) unless @model?

    @$textarea.resize(_.throttle(@editor.refresh, 100))
    @editor.on('focus', => @trigger('focused'))
    @editor.on('blur',  => @trigger('blurred'))

  clearErrors: ->
    @getErrorBlock().empty()
    _.each @errorLines, (marker) =>
      @editor.removeLineClass(marker, 'background', 'error-line')
    @errorLines = []

  setEditorValue: (val, cursor) =>
    @clearErrors()
    @editor.setValue(val)
    @editor.setCursor(cursor) if cursor

  getEditorValue: =>
    @clearErrors()
    try
      return GenghisJSON.parse(@editor.getValue())
    catch e
      _.each e.errors or [e], (error) =>
        message = error.message
        if error.lineNumber and not (/Line \d+/i.test(message))
          message = "Line #{error.lineNumber}: #{error.message}"
        @showError(message)
        if error.lineNumber
          @errorLines.push(@editor.addLineClass(error.lineNumber - 1, 'background', 'error-line'))
    false

  save: =>
    if data = @getEditorValue()
      @onSave(data)

  onSave: (data) =>
    @model.clear(silent: true)
    @model.save(data, wait: true)
      .done(@cancel)
      .fail((doc, xhr) =>
        try
          msg = JSON.parse(xhr.responseText).error
        @showError(msg or 'Error updating document.')
      )

  cancel: =>
    @detach()

  refreshEditor: =>
    @editor.refresh()
    @editor.focus()

  getErrorBlock: ->
    return @errorBlock if @errorBlock?
    @errorBlock = $('<div class="errors"></div>').insertBefore(@$el)

  showError: (message) =>
    alert     = new Alert(level: 'danger', msg: message, block: true)
    alertView = new AlertView(model: alert)
    alertView.attachTo(@getErrorBlock())

module.exports = EditDocument
