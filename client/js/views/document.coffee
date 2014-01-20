{$, _}       = require '../vendors'
Util         = require '../util.coffee'
Alert        = require '../models/alert.coffee'
View         = require './view.coffee'
EditDocument = require './edit_document.coffee'
Confirm      = require './confirm.coffee'
template     = require '../../templates/document.mustache'

class Document extends View
  tagName:  'article'
  template: template

  ui:
    '$errors':   '.errors'
    '$well':     '.well'
    '$document': '.document'

  events:
    'click a.id':            'navigate'
    'click button.edit':     'edit'
    # 'dblclick .document':    'edit',

    'click .document button, .document span.e': Util.toggleCollapser

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

  edit: =>
    @$el.addClass('edit')
    @$document.hide()
    height = Math.max(180, Math.min(600, @$well.height() + 40))

    @model.fetch().then =>
      view = new EditDocument(model: @model, height: height, errorBlock: @$errors)

      @listenTo(view,
        focused: => @$el.addClass('focused'),
        blurred: => @$el.removeClass('focused'),
        detached: @afterEdit
      )

      view.attachTo(@$well)

  afterEdit: =>
    @$el.removeClass('edit focused')
    @updateDocument()
    @$well.height('auto')

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

  destroy: =>
    selection = app.selection
    model     = @model

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
