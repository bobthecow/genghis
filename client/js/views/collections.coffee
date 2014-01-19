{_}                 = require '../vendors'
Section             = require './section.coffee'
CollectionRow       = require './collection_row.coffee'
AddCollection       = require './add_collection.coffee'
AddGridFSCollection = require './add_gridfs_collection.coffee'
template            = require '../../templates/collections.mustache'

class Collections extends Section
  id:       'collections'
  template: template
  rowView:  CollectionRow

  events: _.extend({
    'click .add-form-toggle a.show':        'showAddForm'
    'click .add-form-toggle a.show-gridfs': 'showAddFormGridFS'
  }, Section::events)

  keyboardEvents:
    'c':       'showAddForm'
    'shift+c': 'showAddFormGridFS'

  initialize: ->
    @addForm       = new AddCollection(collection: @collection, disposeOnDetach: false)
    @addFormGridFS = new AddGridFSCollection(collection: @collection, disposeOnDetach: false)

    @listenTo(@addForm,       'detached', @onAddFormDetached)
    @listenTo(@addFormGridFS, 'detached', @onAddFormDetached)

  afterRender: ->
    super
    @$('.dropdown-toggle').dropdown() # Yay dropdowns!

  formatTitle: (model) ->
    return 'Collections' unless model
    "#{model.id} Collections"

  showAddFormGridFS: (e) =>
    e?.preventDefault?()
    @$addFormToggle.hide()
    @attach(@addFormGridFS)

module.exports = Collections
