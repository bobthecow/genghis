{$, _}       = require '../vendors'
CodeMirror   = require '../shims/codemirror'

BaseDocument = require './base_document.coffee'
Util         = require '../util.coffee'
AlertView    = require './alert.coffee'
Alert        = require '../models/alert.coffee'
defaults     = require '../defaults.coffee'
template     = require '../../templates/new_document.mustache'

class NewDocument extends BaseDocument
  el:       '#new-document'
  template: template

  render: ->
    # TODO: clean this up, it's weird.
    @$el   = $(@template()).hide().appendTo('body')
    @el    = @$el[0]
    @modal = @$el.modal(backdrop: 'static', show: false, keyboard: false)
    wrapper = @$('.wrapper')
    @editor = CodeMirror.fromTextArea(@getTextArea(), _.extend({}, defaults.codeMirror,
      extraKeys:
        'Ctrl-Enter': @saveDocument
        'Cmd-Enter':  @saveDocument
    ))
    @editor.on 'focus', -> wrapper.addClass    'focused'
    @editor.on 'blur',  -> wrapper.removeClass 'focused'

    $(window).resize _.throttle(@refreshEditor, 100)
    @modal.on 'hide.bs.modal', @cancelEdit
    @modal.on 'shown.bs.modal', @refreshEditor
    @modal.find('button.cancel').bind 'click', @closeModal
    @modal.find('button.save').bind   'click', @saveDocument
    this

  cancelEdit: (e) =>
    @editor.setValue ''

  refreshEditor: =>
    @editor.refresh()
    @editor.focus()

  getErrorBlock: ->
    errorBlock = @$('div.errors')
    if errorBlock.length is 0
      errorBlock = $('<div class="errors"></div>').prependTo(@$('.modal-body'))
    errorBlock

  showServerError: (message) =>
    alert = new Alert(level: 'danger', msg: message, block: true)
    alertView = new AlertView(model: alert)
    @getErrorBlock().append alertView.render().el

  getTextArea: =>
    @$('#editor-new')[0]

  show: =>
    @editor.setValue "{\n    \n}\n"
    @editor.setCursor(line: 1, ch: 4)
    @modal.modal 'show'

  saveDocument: =>
    data = @getEditorValue()
    return unless data
    model = new @collection.model(data)
    model.collection = @collection
    model.save()
      .done( =>
        @collection.add(model)
        @closeModal()
        @app.router.navigate(Util.route(model.url()), true)
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

  closeModal: (e) =>
    @modal.modal 'hide'

module.exports = NewDocument
