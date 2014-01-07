{$, _}     = require '../vendors'
Util       = require '../util.coffee'
View       = require './view.coffee'
NavSection = require './nav_section.coffee'
template   = require '../../templates/nav.mustache'

class Nav extends View
  tagName:   'ul'
  className: 'nav navbar-nav'
  template:  template

  events:
    'click a': 'navigate'

  modelEvents:
    'change': 'updateSubnav'

  keyboardEvents:
    's': 'navigateToServers'
    'u': 'navigateUp'

  initialize: (options) ->
    @baseUrl = options.baseUrl

    # TODO: clean this up somehow
    $('body').bind 'click', (e) ->
      $('.dropdown-toggle, .menu').parent('li').removeClass 'open'

    @serverNavView = new NavSection(
      className:  'dropdown server'
      model:      @model.currentServer
      collection: @model.servers
    )

    @databaseNavView = new NavSection(
      className:  'dropdown database'
      model:      @model.currentDatabase
      collection: @model.databases
    )

    @collectionNavView = new NavSection(
      className:  'dropdown collection'
      model:      @model.currentCollection
      collection: @model.collections
    )

  serialize: ->
    baseUrl: @baseUrl

  updateSubnav: (model) =>
    attrs = model.changedAttributes()

    if _.has(attrs, 'server')
      if attrs.server?
        @attach @serverNavView unless @serverNavView.isAttached()
      else
        @serverNavView.detach true

    if _.has(attrs, 'database')
      if attrs.database?
        @attach @databaseNavView unless @databaseNavView.isAttached()
      else
        @databaseNavView.detach true

    if _.has(attrs, 'collection')
      if attrs.collection?
        @attach @collectionNavView unless @collectionNavView.isAttached()
      else
        @collectionNavView.detach true

  navigate: (e) ->
    return if e.ctrlKey or e.shiftKey or e.metaKey
    e.preventDefault()
    app.router.navigate Util.route($(e.target).attr('href')), true

  navigateToServers: (e) ->
    e.preventDefault()
    app.router.redirectToIndex()

  navigateUp: (e) =>
    e.preventDefault()
    if @model.get('server')
      server = @model.has('database')
    if @model.get('database')
      db = @model.has('collection')
    if @model.has('document') or @model.has('query')
      coll = @model.get('collection')
    app.router.redirectTo(server, db, coll)

module.exports = Nav
