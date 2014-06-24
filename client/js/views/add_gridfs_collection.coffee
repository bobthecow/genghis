AddForm  = require './add_form'
template = require '../../templates/add_gridfs_collection.mustache'

class AddGridFSCollection extends AddForm
  template: template

  submit: =>
    name = @$input.val().trim()
    if name is ''
      @app.alerts.add(msg: 'Please enter a valid collection name.')
      return

    name = name.replace(/\.(files|chunks)$/, '')

    detachAfterTwo = _.after(2, => @detach())

    # TODO: not this
    files = new @collection.model(name: "#{name}.files")
    files.collection = @collection
    files.save()
      .done( =>
        @collection.add(files)
        detachAfterTwo()
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

    chunks = new @collection.model(name: "#{name}.chunks")
    chunks.collection = @collection
    chunks.save()
      .done( =>
        @collection.add(chunks)
        detachAfterTwo()
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

module.exports = AddGridFSCollection
