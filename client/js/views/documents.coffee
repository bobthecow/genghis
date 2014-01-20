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
    # 'request collection': 'onRequest'
    # 'sync    collection': 'onSync'

    'attached this': 'onAttached'
    'detached this': 'onDetached'

  serialize: ->
    isGrid: @model.isGridCollection()

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
    @collection.each(@addDocument)

  addDocument: (document) =>
    view = new DocumentView(model: document)
    view.attachTo(@$content)

  createDocument: (e) =>
    e?.preventDefault?()
    if @model.isGridCollection()
      # yeah, it's not worth our time
      unless Modernizr.filereader
        app.alerts.create(msg: FILE_API_MSG, level: 'danger', block: true)
        return
      @attach(new NewGridFile(collection: @collection))
    else
      @attach(new NewDocument(collection: @collection))

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

    file = e.originalEvent.dataTransfer.files[0]
    view = new NewGridFile(collection: @collection, fileDialog: false)
    @attach(view)
    view.showMetadata(file)

  onRequest: =>
    spin = => @$el.addClass('spinning')
    @spinTimeout = setTimeout(spin, 500)

  onSync: =>
    clearTimeout(@spinTimeout) if @spinTimeout
    @$el.removeClass('spinning')

  onAttached: =>
    @bindKeyboardEvents()

  onDetached: =>
    @unbindKeyboardEvents()

module.exports = Documents
