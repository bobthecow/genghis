define (require) ->
  View     = require('genghis/views/view')
  Nav      = require('genghis/views/nav')
  Search   = require('genghis/views/search')
  template = require('hgn!genghis/templates/navbar')

  class Navbar extends View
    el:       '.navbar'
    template: template

    ui:
      '$nav': 'nav'

    events:
      'click a.navbar-brand': 'onClickBrand'

    modelEvents:
      'change:collection': 'onChangeCollection'

    initialize: (options = {}) ->
      {@router, @baseUrl} = options
      @navView = new Nav(model: @model, baseUrl: @baseUrl)
      @searchView = new Search(model: @model)
      @render()

    serialize: ->
      baseUrl: @baseUrl

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
