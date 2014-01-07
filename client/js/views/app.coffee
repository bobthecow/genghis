$                     = require 'jquery'
_                     = require 'underscore'
Giraffe               = require '../shims/giraffe'

Selection             = require './models/selection.coffee'
Alerts                = require './collections/alerts.coffee'
Router                = require './router.coffee'

TitleView             = require './views/title.coffee'
NavbarView            = require './views/navbar.coffee'
AlertsView            = require './views/alerts.coffee'
KeyboardShortcutsView = require './views/keyboard_shortcuts.coffee'
ServersView           = require './views/servers.coffee'
DatabasesView         = require './views/databases.coffee'
CollectionsView       = require './views/collections.coffee'
DocumentsView         = require './views/documents.coffee'
ExplainView           = require './views/explain.coffee'
DocumentSectionView   = require './views/document_section.coffee'
MastheadView          = require './views/masthead.coffee'

welcomeTemplate       = require 'hgn!genghis/templates/welcome'

class App extends Giraffe.App
  el: 'section#genghis'

  initialize: (options = {}) ->
    # let's save this for later
    @baseUrl = options.baseUrl

    # for current selection
    @selection = new Selection()

    # for messaging
    alerts = @alerts = new Alerts()

    # initialize the router
    @router = new Router(app: this)
    @listenTo @router, 'all', @autoShowSection

    # initialize all our app views
    @titleView  = new TitleView(model: @router)
    @navbarView = new NavbarView(
      model:   selection
      baseUrl: @baseUrl
      router:  @router
    )
    @alertsView            = new AlertsView(collection: alerts)
    @keyboardShortcutsView = new KeyboardShortcutsView()
    @serversView           = new ServersView(collection: @selection.servers)
    @databasesView = new DatabasesView(
      model:       @selection.currentServer
      collection:  @selection.databases
    )
    @collectionsView = new CollectionsView(
      model:       @selection.currentDatabase
      collection:  @selection.collections
    )
    @documentsView = new DocumentsView(
      model:      @selection.currentCollection
      collection: @selection.documents
      pagination: @selection.pagination
    )
    @explainView           = new ExplainView(model: @selection.explain)
    @documentSectionView   = new DocumentSectionView(model: @selection.currentDocument)

    # Let's just keep these for later...
    @sections =
      servers:     @serversView
      databases:   @databasesView
      collections: @collectionsView
      documents:   @documentsView
      explain:     @explainView
      document:    @documentSectionView

    # check the server status...
    $.getJSON("#{@baseUrl}check-status").error(alerts.handleError).success (status) ->
      _.each status.alerts, (alert) ->
        alerts.add _.extend(block: not alert.msg.search(/<(p|ul|ol|div)[ >]/i), alert)

    # trigger the first selection change. go go gadget app!
    _.defer @selection.update

  showMasthead: (heading, content, options = {}) =>
    # remove any old mastheads
    @removeMasthead true
    new MastheadView(_.extend(options, heading: heading, content: content))

  removeMasthead: (force = false) ->
    masthead = $('header.masthead')
    masthead = masthead.not('.sticky') unless force
    masthead.remove()

  autoShowSection: (route) ->
    switch route
      when 'route:index'        then @showSection 'servers'
      when 'route:server'       then @showSection 'databases'
      when 'route:database'     then @showSection 'collections'
      when 'route:collection', 'route:collectionQuery'
        @showSection 'documents'
      when 'route:explainQuery' then @showSection 'explain'
      when 'route:document'     then @showSection 'document'

  showSection: (section) =>
    hasSection = section and _.has(@sections, section)

    # remove mastheads when navigating
    @removeMasthead()

    # show a welcome message the first time they hit the servers page
    @showWelcome() if section is 'servers'

    # TODO: move this somewhere else?
    $('body').toggleClass 'has-section', hasSection
    _.each @sections, (view, name) ->
      view.hide() unless name is section

    @sections[section].show() if hasSection

  showWelcome: _.once(->
    @showMasthead '', welcomeTemplate(version: Genghis.version),
      epic:      true
      className: 'masthead welcome'
  )

module.exports = App
