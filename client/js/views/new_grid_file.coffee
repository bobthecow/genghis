{$, _}      = require '../vendors'
NewDocument = require './new_document.coffee'
Document    = require '../models/document.coffee'
Util        = require '../util.coffee'
GenghisJSON = require '../json.coffee'
template    = require '../../templates/new_grid_file.mustache'

class NewGridFile extends NewDocument
  el:       '#new-grid-file'
  template: template

  render: ->
    super
    @fileInput = $('<input id="new-grid-file-input" type="file">')
      .hide()
      .appendTo('body')
    @currentFile = null
    @fileInput.bind 'change', @handleFileInputChange
    this

  getTextArea: ->
    @$('#editor-upload')[0]

  show: ->
    # get the file
    @fileInput.click()

  handleFileInputChange: (e) =>
    @showMetadata e.target.files[0]

  showMetadata: (file) =>
    @currentFile = file
    if file
      @fileInput.val ''

      # now let 'em edit metadata
      @editor.setValue GenghisJSON.stringify(
        filename:    file.name
        contentType: file.type or 'binary/octet-stream'
        metadata:    {}
      )

      @editor.setCursor(line: 3, ch: 15)
      @modal.modal 'show'

  saveDocument: ->
    data = @getEditorValue()
    return if data is false
    if data.file
      @showServerError "Unexpected property: 'file'"
      return

    {closeModal, showServerError} = this
    docs      = @collection
    uploadUrl = @collection.url.replace('.files/documents', '.files/files')

    reader = new FileReader()
    reader.onload = (e) ->
      data.file = e.target.result
      $.ajax(
        type:        'POST'
        url:         uploadUrl
        data:        JSON.stringify(data)
        contentType: 'application/json'
      ).success((doc) ->
        docs.add doc
        closeModal()
        id = new Document(doc).prettyId()
        app.router.navigate Util.route("#{docs.url}/#{id}"), true
      ).error((xhr) ->
        try
          msg = JSON.parse(xhr.responseText).error
        showServerError msg or 'Error uploading file.'
      )

    reader.readAsDataURL @currentFile

module.exports = NewGridFile
