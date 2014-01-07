_             = require 'underscore'
Section       = require './section.coffee'
CollectionRow = require './collection_row.coffee'
template      = require 'hgn!genghis/templates/collections'

require 'bootstrap.dropdown'
require 'backbone.mousetrap'

class Collections extends Section
  el:       'section#collections'
  template: template
  rowView:  CollectionRow

  ui: _.extend(
    '$addFormGridFs':  '.add-form-gridfs'
    '$addInputGridFs': '.add-input-gridfs'
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
    @collection.create(
      {name: "#{name}.files"}
      wait: true
      success: closeAfterTwo
      error: (model, response) -> alerts.handleError response
    )
    @collection.create(
      {name: "#{name}.chunks"}
      wait: true
      success: closeAfterTwo
      error: (model, response) -> alerts.handleError response
    )

  closeAddFormGridFs: =>
    @$addFormToggle.show()
    @$addFormGridFs.hide()
    @$addInputGridFs.val ''

  updateOnKeyupGridFs: (e) =>
    @submitAddFormGridFs() if e.keyCode is 13 # enter
    @closeAddFormGridFs()  if e.keyCode is 27 # escape

module.exports = Collections
