{$, _}     = require '../vendors'
Util       = require '../util'
View       = require './view'
NavSection = require './nav_section'
template   = require '../../templates/nav.mustache'

class Nav extends View
  tagName:   'ul'
  className: 'nav navbar-nav'
  template:  template

  events:
    'click a': 'navigate'

  dataEvents:
    'change model': 'updateSubnav'

  keyboardEvents:
    's': 'navigateToServers'
    'u': 'navigateUp'

  initialize: ->
    # TODO: clean this up somehow
    $('body').bind 'click', (e) ->
      $('.dropdown-toggle, .menu').parent('li').removeClass 'open'

    @serverNavView = new NavSection(
      className:  'dropdown server'
      model:      @model.server
      collection: @model.servers
    )

    @databaseNavView = new NavSection(
      className:  'dropdown database'
      model:      @model.database
      collection: @model.databases
    )

    @collectionNavView = new NavSection(
      className:  'dropdown collection'
      model:      @model.coll
      collection: @model.collections
    )

  serialize: ->
    baseUrl: @baseUrl

  updateSubnav: (model) =>
    attrs = model.changedAttributes()

    if _.has(attrs, 'server')
      if attrs.server?
        @attach(@serverNavView) unless @serverNavView.isAttached()
      else
        @serverNavView.detach(true)

    if _.has(attrs, 'database')
      if attrs.database?
        @attach(@databaseNavView) unless @databaseNavView.isAttached()
      else
        @databaseNavView.detach(true)

    if _.has(attrs, 'collection')
      if attrs.collection?
        @attach(@collectionNavView) unless @collectionNavView.isAttached()
      else
        @collectionNavView.detach(true)

  navigate: (e) ->
    return if e.ctrlKey or e.shiftKey or e.metaKey
    e.preventDefault()
    @router.navigate(Util.route($(e.target).attr('href')), true)

  navigateToServers: (e) ->
    e.preventDefault()
    @router.redirectToIndex()

  navigateUp: (e) ->
    e.preventDefault()
    return @router.navigate(@model.coll.url(), true)     if @model.has('search') or @model.has('document')
    return @router.navigate(@model.database.url(), true) if @model.has('collection')
    return @router.navigate(@model.server.url(), true)   if @model.has('database')
    return @router.navigate(@baseUrl, true)              if @model.has('server')

module.exports = Nav
