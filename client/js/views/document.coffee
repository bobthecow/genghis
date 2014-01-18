{$, _}       = require '../vendors'
CodeMirror   = require '../shims/codemirror'
Util         = require '../util.coffee'
Alert        = require '../models/alert.coffee'
BaseDocument = require './base_document.coffee'
AlertView    = require './alert.coffee'
Confirm      = require './confirm.coffee'
defaults     = require '../defaults.coffee'
template     = require '../../templates/document.mustache'

class Document extends BaseDocument
  tagName:  'article'
  template: template

  ui:
    '$document': '.document'
    '$well':     '.well'

  events:
    'click a.id':            'navigate'
    'click button.edit':     'openEditDialog'

    'click button,span.e':   Util.toggleCollapser

    # 'dblclick .document':    'openEditDialog',
    'click button.save':     'saveDocument'
    'click button.cancel':   'cancelEdit'
    'click button.destroy':  'destroy'
    'click a.grid-download': 'download'
    'click a.grid-file':     'navigate'

    # navigation!
    'click .ref .ref-ref .v .s':                   'navigateColl'
    'click .ref .ref-db .v .s':                    'navigateDb'
    'click .ref .ref-id .v .s, .ref .ref-id .v.n': 'navigateId' # handle numeric IDs too

  dataEvents:
    'change  model': 'updateDocument'
    'destroy model': 'dispose'

  afterRender: ->
    _.defer(@updateDocument)

  updateDocument: =>
    @$document?.empty()
      .append(@model.prettyPrint())
      .show()

  navigate: (e) ->
    return if e.ctrlKey or e.shiftKey or e.metaKey
    e.preventDefault()
    app.router.navigate Util.route($(e.target).attr('href')), true

  navigateDb: (e) ->
    $dbRef = $(e.target).parents('.ref')
    db     = $dbRef.find('.ref-db .v .s').text()
    app.router.redirectToDatabase(app.selection.server.id, db)

  navigateColl: (e) ->
    $dbRef = $(e.target).parents('.ref')
    db     = $dbRef.find('.ref-db  .v .s').text() or app.selection.database.id
    coll   = $dbRef.find('.ref-ref .v .s').text()
    app.router.redirectToCollection(app.selection.server.id, db, coll)

  navigateId: (e) ->
    $dbRef = $(e.target).parents('.ref')
    db     = $dbRef.find('.ref-db  .v .s').text() or app.selection.database.id
    coll   = $dbRef.find('.ref-ref .v .s').text() or app.selection.coll.id
    id     = $dbRef.find('.ref-id').attr('data-document-id')
    app.router.redirectToDocument(app.selection.server.id, db, coll, encodeURIComponent(id))

  openEditDialog: =>
    unless @model.isEditable()
      @app.alerts.error(msg: 'Unable to edit document')
      return

    @model.fetch().then =>
      $well    = @$well
      height   = Math.max(180, Math.min(600, $well.height() + 40))
      editorId = "editor-#{@model.id.replace('~', '-')}"
      textarea = $("<textarea id=\"#{editorId}\"></textarea>").text(@model.JSONish()).appendTo($well)
      @$document.hide()

      $el = @$el.addClass('edit')
      @editor = CodeMirror.fromTextArea(textarea[0], _.extend({}, defaults.codeMirror,
        autofocus: true
        extraKeys:
          'Ctrl-Enter': @saveDocument
          'Cmd-Enter':  @saveDocument
      ))

      @editor.on 'focus', ->
        $el.addClass 'focused'

      @editor.on 'blur', ->
        $el.removeClass 'focused'

      @editor.setSize null, height
      textarea.resize _.throttle(@editor.refresh, 100)

  cancelEdit: =>
    @$el.removeClass 'edit focused'
    @editor.toTextArea()
    @$('textarea').remove()
    @updateDocument()
    @$well.height 'auto'

  getErrorBlock: ->
    errorBlock = @$('div.errors')
    errorBlock = $('<div class="errors"></div>').prependTo(@el) if errorBlock.length is 0
    errorBlock

  showServerError: (message) =>
    alert     = new Alert(level: 'danger', msg: message, block: true)
    alertView = new AlertView(model: alert)
    @getErrorBlock().append alertView.render().el

  saveDocument: =>
    unless @model.isEditable()
      @app.alerts.error(msg: 'Unable to edit document')
      return

    data = @getEditorValue()
    return if data is false
    showServerError = @showServerError
    @model.clear silent: true
    @model.save(data, wait: true)
      .done(@cancelEdit)
      .fail(
        (doc, xhr) ->
          try
            msg = JSON.parse(xhr.responseText).error
          showServerError msg or 'Error updating document.'
      )

  destroy: =>
    model = @model
    if @model.isGridFile()
      docType = 'file'
      gridMsg = "This will delete all GridFS chunks as well. <br><br>"
    else
      docType = 'document'
      gridMsg = ''

    new Confirm(
      header:      'Deleting is forever'
      body:        "<strong>Really?</strong> #{gridMsg}There is no undo."
      confirmText: "<strong>Yes</strong>, delete #{docType} forever"
      confirm: ->
        selection = app.selection
        if model.isGridFile()
          model.url = model.url().replace('.files/documents/', '.files/files/')
        model.destroy(wait: true)
          .then(
            (doc, xhr) ->
              selection.pagination.decrementTotal()

              # if we're currently in single-document view, bust outta this!
              if selection.get('document')
                app.router.redirectToCollection(
                  selection.get('server'),
                  selection.get('database'),
                  selection.get('collection')
                )
          )
          .fail(
            (doc, xhr) ->
              try
                msg = JSON.parse(xhr.responseText).error
              app.alerts.create(level: 'danger', msg: msg or "Error deleting #{docType}.")
          )
    )

  download: (e) =>
    Util.download @model.downloadUrl()
    e.preventDefault()

module.exports = Document
