{$, _}       = require '../vendors'
NewDocument  = require './new_document.coffee'
EditDocument = require './edit_document.coffee'
Document     = require '../models/document.coffee'
Util         = require '../util.coffee'
GenghisJSON  = require '../json.coffee'
template     = require '../../templates/new_grid_file.mustache'

class NewGridFile extends NewDocument
  id:        'new-grid-file'
  className: 'modal modal-file-upload'
  template:  template

  ui:
    '$errors':  '.errors'
    '$wrapper': '.wrapper'
    '$file':    'input[type=file]'

  events:
    'change $file':        'onFileChange'
    'click button.cancel': 'closeModal'
    'click button.save':   'save'

  modalOptions:
    backdrop: 'static'
    keyboard: false
    show:     false

  afterRender: =>
    super
    @$file.click() unless @fileDialog is false

  onFileChange: (e) =>
    @showMetadata(e.target.files[0])

  showMetadata: (file) =>
    return unless @currentFile = file

    @$file.val('')

    # now let 'em edit metadata
    @editView.setEditorValue(GenghisJSON.stringify(
      filename:    @currentFile.name
      contentType: @currentFile.type or 'binary/octet-stream'
      metadata:    {}
    ), line: 3, ch: 15)

    @modal.modal('show')

  onSave: (data) =>
    if data.file
      @editView.showError("Unexpected property: 'file'")
      return

    Util.readAsDataURL(@currentFile)
      .done((file) =>
        data.file = file
        NewDocument::onSave.call(this, data)
      )

module.exports = NewGridFile
