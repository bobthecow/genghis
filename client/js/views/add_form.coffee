{_}  = require '../vendors'
View = require './view'

class AddForm extends View
  className: 'add-form form-inline'

  attributes:
    role: 'form'

  ui:
    '$input': 'input'

  events:
    'click button.add':    'submit'
    'click button.cancel': 'cancel'
    'keyup $input':        'updateOnKeyup'

  dataEvents:
    'attached this': 'onAttached'
    'detached this': 'onDetached'

  updateOnKeyup: (e) =>
    switch e.keyCode
      when 13 then @submit() # enter
      when 27 then @cancel() # escape

  createModel: =>
    new @collection.model(name: @$input.val())

  submit: =>
    model = @createModel()
    model.collection = @collection
    model.save()
      .done( =>
        @collection.add(model)
        @detach()
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

  cancel: =>
    @detach()

  onAttached: =>
    @$input.select().focus()

  onDetached: =>
    @$input.val('')


module.exports = AddForm
