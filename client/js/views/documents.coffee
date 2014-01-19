{$, _}          = require '../vendors'
Modernizr       = require '../shims/modernizr'

View            = require './view.coffee'
DocumentsHeader = require './documents_header.coffee'
Pagination      = require './pagination.coffee'
DocumentView    = require './document.coffee'
NewDocument     = require './new_document.coffee'
NewGridFile     = require './new_grid_file.coffee'

template        = require '../../templates/documents.mustache'

FILE_API_MSG    = "<h2>Unable to upload file.</h2> Your browser does not
                  support the File API. Please use a modern browser."

class Documents extends View
  id:        'documents'
  tagName:   'section'
  className: 'app-section'
  template:  template

  ui:
    '$header':     'header'
    '$pagination': '.pagination-wrapper'
    '$content':    '.content'
    '$addButton':  'button.add-document'

  events:
    'click     $addButton': 'createDocument'

    # This class is toggled to change the button between "create document"
    # and "file upload", so we're totally not adding it to the UI hash above.
    'dragover  button.file-upload': 'dragGridFile'
    'dragleave button.file-upload': 'dragLeave'
    'drop      button.file-upload': 'dropGridFile'

  keyboardEvents:
    'c': 'createDocument'

  dataEvents:
    'reset   collection': 'addAll'
    'add     collection': 'addDocument'
    'request collection': 'onRequest'
    'sync    collection': 'onSync'

    'attached this': 'onAttached'
    'detached this': 'onDetached'

  initialize: ->
    @render()

  afterRender: ->
    header = new DocumentsHeader(el: @$header, model: @collection.pagination)
    header.attachTo(@$header, method: 'html')

    @$pagination.each((i, el) =>
      view = new Pagination(el: el, collection: @collection)
      view.attachTo(el, method: 'html')
    )

    @addAll()

  addAll: =>
    @$content.empty()
    text = if @model.isGridCollection() then 'Upload file' else 'Add document'
    @$addButton.text(text).toggleClass 'file-upload', @model.isGridCollection()
    @collection.each @addDocument

  addDocument: (document) =>
    view = new DocumentView(model: document)
    @$content.append view.render().el

  createDocument: (e) =>
    e?.preventDefault?()
    if @model.isGridCollection()
      # yeah, it's not worth our time
      unless Modernizr.filereader
        app.alerts.create(msg: FILE_API_MSG, level: 'danger', block: true)
        return
      @getNewGridFileView().show()
    else
      @getNewDocumentView().show()

  dragGridFile: (e) ->
    e.stopPropagation()
    e.preventDefault()
    e.originalEvent.dataTransfer.dropEffect = 'copy'
    $(e.target).addClass 'active'

  dragLeave: (e) ->
    $(e.target).removeClass 'active'

  dropGridFile: (e) =>
    e.stopPropagation()
    e.preventDefault()
    $(e.target).removeClass 'active'

    # yeah, it's not worth our time
    unless Modernizr.filereader
      app.alerts.create(msg: FILE_API_MSG, level: 'danger', block: true)
      return
    @getNewGridFileView().showMetadata e.originalEvent.dataTransfer.files[0]

  getNewDocumentView: ->
    @newDocumentView = new NewDocument(collection: @collection) unless @newDocumentView

  getNewGridFileView: ->
    @newGridFileView = new NewGridFile(collection: @collection) unless @newGridFileView

  onRequest: =>
    @$el.addClass('spinning')

  onSync: =>
    @$el.removeClass('spinning')

  onAttached: =>
    @bindKeyboardEvents()

  onDetached: =>
    @unbindKeyboardEvents()

module.exports = Documents
