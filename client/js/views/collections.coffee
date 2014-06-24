{_}                 = require '../vendors'
Section             = require './section'
CollectionRow       = require './collection_row'
AddCollection       = require './add_collection'
AddGridFSCollection = require './add_gridfs_collection'
template            = require '../../templates/collections.mustache'

class Collections extends Section
  id:       'collections'
  template: template
  rowView:  CollectionRow
  title: =>
    if @model.id then "#{@model.id} Collections" else 'Collections'

  events: _.extend({
    'click .add-form-toggle a.show':        'showAddForm'
    'click .add-form-toggle a.show-gridfs': 'showAddFormGridFS'
  }, Section::events)

  keyboardEvents:
    'c':       'showAddForm'
    'shift+c': 'showAddFormGridFS'

  dataEvents: _.extend({
    'detached addFormGridFS': 'onAddFormDetached'
  }, Section::dataEvents)

  initialize: ->
    @addForm       = new AddCollection(collection: @collection, disposeOnDetach: false)
    @addFormGridFS = new AddGridFSCollection(collection: @collection, disposeOnDetach: false)

  afterRender: ->
    super
    @$('.dropdown-toggle').dropdown() # Yay dropdowns!

  showAddFormGridFS: (e) =>
    e?.preventDefault?()
    @$addFormToggle.hide()
    @attach(@addFormGridFS)

module.exports = Collections
