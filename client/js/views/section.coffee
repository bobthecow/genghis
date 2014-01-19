{$, _} = require '../vendors'
View   = require './view.coffee'

class Section extends View
  tagName:   'section'
  className: 'app-section'

  ui:
    '$title':         '> header h2'
    '$table':         'table'
    '$tbody':         'table tbody'
    '$addFormToggle': '.add-form-toggle'

  events:
    'click .add-form-toggle button': 'showAddForm'

  keyboardEvents:
    'c': 'showAddForm'

  dataEvents:
    'change model': 'updateTitle'

    'reset        collection': 'render'
    'add          collection': 'addModelAndUpdate'
    'request      collection': 'startSpinning'
    'sync destroy collection': 'stopSpinning'

    'attached this':    'onAttached'
    'detached this':    'onDetached'
    # 'detached addForm': 'onAddFormDetached'

  initialize: ->
    @addForm = new @addFormView(collection: @collection, disposeOnDetach: false)

    # TODO: figure out why this doesn't work in the dataEvents above?
    @listenTo(@addForm, 'detached', @onAddFormDetached)

  serialize: ->
    title: @formatTitle(@model)

  afterRender: ->
    @addAll()

    # Sort this bad boy.
    @$table.tablesorter textExtraction: (el) ->
      $('.value', el).text() or $(el).text()

    if @collection.size()
      @$table.trigger 'sorton', [[[0, 0]]]

  updateTitle: =>
    @$title.text(@formatTitle(@model))

  showAddForm: (e) =>
    e?.preventDefault?()
    @$addFormToggle.hide()
    @attach(@addForm)

  addModel: (model) =>
    view = new @rowView(model: model)
    view.attachTo(@$tbody)

  addModelAndUpdate: (model) =>
    @addModel(model)
    @$table.trigger('update')

  addAll: =>
    @$tbody.empty()
    @collection.each(@addModel)

  onAttached: =>
    @bindKeyboardEvents()

  onDetached: =>
    @unbindKeyboardEvents()

  onAddFormDetached: =>
    @$addFormToggle.show()

  startSpinning: =>
    @$el.addClass('spinning')

  stopSpinning: =>
    @$el.removeClass('spinning')

module.exports = Section
