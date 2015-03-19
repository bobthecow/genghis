{$, _}       = require '../vendors'

View         = require './view'
EditDocument = require './edit_document'
Util         = require '../util'
template     = require '../../templates/new_document.mustache'

class NewDocument extends View
  id:        'new-document'
  className: 'modal modal-editor'
  template:  template

  ui:
    '$errors':  '.errors'
    '$wrapper': '.wrapper'

  events:
    'click button.cancel': 'closeModal'
    'click button.save':   'save'

  modalOptions:
    backdrop: 'static'
    keyboard: false

  afterRender: =>
    @modal    = @$el.modal(@modalOptions)
    @editView = new EditDocument(
      errorBlock:   @$errors,
      height:       @$wrapper.height(),
      showControls: false,
      onSave:       @onSave
    )

    @listenTo @editView,
      focused: => @$wrapper.addClass('focused'),
      blurred: => @$wrapper.removeClass('focused'),

    @editView.attachTo(@$wrapper)

    @modal.on('hide.bs.modal',  => @detach())
    @modal.on('shown.bs.modal', => @editView.refreshEditor())

  onSave: (data) =>
    model = new @collection.model(data)
    model.collection = @collection
    model.save()
      .done( =>
        @collection.add(model)
        @closeModal()

        # TODO: figure out why this doesn't work with this.app
        app.router.navigate(model.url(), true)
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

  closeModal: =>
    @modal.modal('hide')

  save: =>
    @editView.save()

module.exports = NewDocument
