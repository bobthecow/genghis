View     = require './view.coffee'
Nav      = require './nav.coffee'
Search   = require './search.coffee'
template = require '../../templates/navbar.mustache'

class Navbar extends View
  el:       '.navbar'
  template: template

  ui:
    '$nav': 'nav'

  events:
    'click a.navbar-brand': 'onClickBrand'

  modelEvents:
    'change:collection': 'onChangeCollection'

  initialize: ->
    @navView    = new Nav({@model, @baseUrl})
    @searchView = new Search({@model})
    @render()

  serialize: ->
    {@baseUrl}

  afterRender: ->
    @navView.attachTo @$nav

  onChangeCollection: (model) ->
    if model.get('collection')
      @searchView.attachTo @$nav unless @searchView.isAttached()
    else
      @searchView.detach true if @searchView.isAttached()

  onClickBrand: (e) ->
    return if e.ctrlKey or e.shiftKey or e.metaKey
    e.preventDefault()
    @router.navigate '', true

module.exports = Navbar
