define (require) ->
  $            = require('jquery')
  _            = require('underscore')
  CodeMirror   = require('codemirror')
  Util         = require('genghis/util')
  Alert        = require('genghis/models/alert')
  BaseDocument = require('genghis/views/base_document')
  AlertView    = require('genghis/views/alert')
  Confirm      = require('genghis/views/confirm')
  template     = require('hgn!genghis/templates/document')

  require 'codemirror.matchbrackets'
  require 'codemirror.javascript'

  class Document extends BaseDocument
    tagName:  'article'
    template: template

    ui:
      '$document': '.document'
      '$well':     '.well'

    events:
      'click a.id':            'navigate'
      'click button.edit':     'openEditDialog'

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

    modelEvents:
      change:  'updateDocument'
      destroy: 'remove'

    afterRender: ->
      Util.attachCollapsers @el
      setTimeout @updateDocument, 1

    updateDocument: =>
      @$document.empty()
        .append(@model.prettyPrint())
        .show()

    navigate: (e) =>
      return if e.ctrlKey or e.shiftKey or e.metaKey
      e.preventDefault()
      app.router.navigate Util.route($(e.target).attr('href')), true

    navigateDb: (e) =>
      $dbRef = $(e.target).parents('.ref')
      db     = $dbRef.find('.ref-db .v .s').text()
      app.router.redirectToDatabase app.selection.currentServer.id, db

    navigateColl: (e) =>
      $dbRef = $(e.target).parents('.ref')
      db     = $dbRef.find('.ref-db  .v .s').text() or app.selection.currentDatabase.id
      coll   = $dbRef.find('.ref-ref .v .s').text()
      app.router.redirectToCollection app.selection.currentServer.id, db, coll

    navigateId: (e) =>
      $dbRef = $(e.target).parents('.ref')
      db     = $dbRef.find('.ref-db  .v .s').text() or app.selection.currentDatabase.id
      coll   = $dbRef.find('.ref-ref .v .s').text() or app.selection.currentCollection.id
      id     = $dbRef.find('.ref-id').attr('data-document-id')
      app.router.redirectToDocument app.selection.currentServer.id, db, coll, encodeURIComponent(id)

    openEditDialog: =>
      $well    = @$well
      height   = Math.max(180, Math.min(600, $well.height() + 40))
      editorId = "editor-#{@model.id.replace('~', '-')}"
      textarea = $("<textarea id=\"#{editorId}\"></textarea>").text(@model.JSONish()).appendTo($well)
      @$document.hide()

      $el = @$el.addClass('edit')
      @editor = CodeMirror.fromTextArea(textarea[0], _.extend({}, Genghis.defaults.codeMirror,
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
      data = @getEditorValue()
      return if data is false
      showServerError = @showServerError
      @model.clear silent: true
      @model.save data,
        wait:    true
        success: @cancelEdit
        error: (doc, xhr) ->
          try
            msg = JSON.parse(xhr.responseText).error
          showServerError msg or 'Error updating document.'

    destroy: =>
      model      = @model
      isGridFile = @model.isGridFile()
      docType    = (if isGridFile then 'file' else 'document')
      @model.url = @model.url().replace('.files/documents/', '.files/files/') if isGridFile

      new Confirm(
        body:        "<strong>Really?</strong> " + ((if isGridFile then "This will delete all GridFS chunks as well. <br><br>" else "")) + "There is no undo."
        confirmText: "<strong>Yes</strong>, delete #{docType} forever"
        confirm: ->
          selection = app.selection
          model.destroy
            wait: true
            error: (doc, xhr) ->
              try
                msg = JSON.parse(xhr.responseText).error
              app.alerts.create(level: 'danger', msg: msg or "Error deleting #{docType}.")
            success: (doc, xhr) ->
              selection.pagination.decrementTotal()

              # if we're currently in single-document view, bust outta this!
              if selection.get('document')
                app.router.redirectTo selection.get('server'), selection.get('database'), selection.get('collection'), null, selection.get('query')
      )

    download: (e) =>
      Util.download @model.downloadUrl()
      e.preventDefault()
