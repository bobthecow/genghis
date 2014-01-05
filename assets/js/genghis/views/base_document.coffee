define (require) ->
  _           = require('underscore')
  View        = require('genghis/views/view')
  GenghisJSON = require('genghis/json')
  AlertView   = require('genghis/views/alert')
  Alert       = require('genghis/models/alert')

  # TODO: this shouldn't be BaseDocument, it should be a DocumentEditor view
  # that's used by both Document and NewDocument views to edit document JSON.
  class BaseDocument extends View
    errorLines: []

    clearErrors: ->
      @getErrorBlock().empty()
      _.each @errorLines, (marker) =>
        @editor.removeLineClass marker, 'background', 'error-line'
      @errorLines = []

    getEditorValue: ->
      @clearErrors()
      errorBlock = @getErrorBlock()
      editor     = @editor
      errorLines = @errorLines
      try
        return GenghisJSON.parse(editor.getValue())
      catch e
        _.each e.errors or [e], (error) ->
          message = error.message
          if error.lineNumber and not (/Line \d+/i.test(message))
            message = "Line #{error.lineNumber}: #{error.message}"

          alertView = new AlertView(model: new Alert(level: 'danger', msg: message, block: true))
          errorBlock.append alertView.render().el
          if error.lineNumber
            errorLines.push editor.addLineClass(error.lineNumber - 1, 'background', 'error-line')
      false


