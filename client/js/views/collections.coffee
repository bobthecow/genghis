{_}           = require '../vendors'
Section       = require './section.coffee'
CollectionRow = require './collection_row.coffee'
template      = require '../../templates/collections.mustache'

class Collections extends Section
  id:       'collections'
  template: template
  rowView:  CollectionRow

  ui: _.extend(
    '$addFormGridFs':  '.add-form-gridfs'
    '$addInputGridFs': '.add-form-gridfs input'
    '$addFormToggle':  '.add-form-toggle'
  , Section::ui)

  events: _.extend(
    'click .add-form-toggle a.show':        'showAddForm'
    'click .add-form-toggle a.show-gridfs': 'showAddFormGridFs'
    'click .add-form-gridfs button.add':    'submitAddFormGridFs'
    'click .add-form-gridfs button.cancel': 'closeAddFormGridFs'
    'keyup .add-form-gridfs input.name':    'updateOnKeyupGridFs'
  , Section::events)

  keyboardEvents: _.extend(
    'shift+c': 'showAddFormGridFs'
  , Section::keyboardEvents)

  afterRender: ->
    super
    @$('.dropdown-toggle').dropdown() # Yay dropdowns!

  formatTitle: (model) ->
    return 'Collections' unless model
    "#{model.id} Collections"

  showAddFormGridFs: (e) =>
    e?.preventDefault?()
    @$addFormToggle.hide()
    @$addFormGridFs.show()
    @$addInputGridFs.select().focus()

  submitAddFormGridFs: =>
    alerts = @app.alerts
    name   = @$addInputGridFs.val().replace(/^\s+/, '').replace(/\s+$/, '')
    if name is ''
      alerts.add msg: 'Please enter a valid collection name.'
      return
    name = name.replace(/\.(files|chunks)$/, '')

    # TODO: not this
    closeAfterTwo = _.after(2, @closeAddFormGridFs)

    files = new @collection.model(name: "#{name}.files")
    files.collection = @collection
    files.save()
      .done( =>
        @collection.add(files)
        closeAfterTwo()
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

    chunks = new @collection.model(name: "#{name}.chunks")
    chunks.collection = @collection
    chunks.save()
      .done( =>
        @collection.add(chunks)
        closeAfterTwo()
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

  closeAddFormGridFs: =>
    @$addFormToggle.show()
    @$addFormGridFs.hide()
    @$addInputGridFs.val ''

  updateOnKeyupGridFs: (e) =>
    @submitAddFormGridFs() if e.keyCode is 13 # enter
    @closeAddFormGridFs()  if e.keyCode is 27 # escape

module.exports = Collections
