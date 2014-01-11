{$, _, Giraffe}       = require '../vendors'

Selection             = require '../models/selection.coffee'
Alerts                = require '../collections/alerts.coffee'
Router                = require '../router.coffee'

View                  = require './view.coffee'
TitleView             = require './title.coffee'
NavbarView            = require './navbar.coffee'
AlertsView            = require './alerts.coffee'
KeyboardShortcutsView = require './keyboard_shortcuts.coffee'
ServersView           = require './servers.coffee'
DatabasesView         = require './databases.coffee'
CollectionsView       = require './collections.coffee'
DocumentsView         = require './documents.coffee'
ExplainView           = require './explain.coffee'
DocumentSectionView   = require './document_section.coffee'
MastheadView          = require './masthead.coffee'
FooterView            = require './footer.coffee'

notFoundTemplate      = require '../../templates/not_found.mustache'
welcomeTemplate       = require '../../templates/welcome.mustache'

class App extends Giraffe.App
  el: 'section#genghis'

  initialize: ->
    # for current selection
    @selection = new Selection({}, {@baseUrl})

    # for messaging
    alerts = @alerts = new Alerts()

    # initialize the router
    @router = new Router(app: this)
    @listenTo @router, 'all', @autoShowSection

    # initialize all our app views
    @titleView  = new TitleView(model: @router)
    @navbarView = new NavbarView(
      model:   @selection
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

    @masthead = new View();
    @masthead.attachTo('header.navbar', {method: 'after'})

    @footer  = new FooterView()
    @footer.attachTo('body')

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

  showMasthead: (options = {}) =>
    @masthead.attach(new MastheadView(options), {method: 'html'})

  removeMasthead: () ->
    @masthead.detachChildren()

  showNotFound: (heading, content) ->
    this.showMasthead(content: notFoundTemplate({heading, content}), epic: true, error: true)

  showWelcome: _.once(->
    @showMasthead(content: welcomeTemplate(version: Genghis.version), epic: true, className: 'masthead welcome')
  )

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


module.exports = App
