{$, _, Giraffe}       = require '../vendors'

Router                = require '../router.coffee'

Selection             = require '../models/selection.coffee'
Alerts                = require '../collections/alerts.coffee'

View                  = require './view.coffee'
TitleView             = require './title.coffee'
NavbarView            = require './navbar.coffee'
MastheadView          = require './masthead.coffee'
AlertsView            = require './alerts.coffee'
FooterView            = require './footer.coffee'

ServersView           = require './servers.coffee'
DatabasesView         = require './databases.coffee'
CollectionsView       = require './collections.coffee'
DocumentsView         = require './documents.coffee'
ExplainView           = require './explain.coffee'
DocumentSectionView   = require './document_section.coffee' # TODO: rename to document view, make a document_edit view?

notFoundTemplate      = require '../../templates/not_found.mustache'
welcomeTemplate       = require '../../templates/welcome.mustache'

ROUTE_SECTION_MAP =
  'route:index':           'servers'
  'route:server':          'databases'
  'route:database':        'collections'
  'route:collection':      'documents'
  'route:collectionQuery': 'documents'
  'route:explainQuery':    'explain'
  'route:document':        'document'

class App extends Giraffe.App
  initialize: ->
    @alerts = new Alerts()

    @router = new Router(app: this)
    @listenTo(@router, 'all', @autoShowSection)

    @selection = new Selection({}, {@baseUrl})
    {@servers, @databases, @collections, @documents} = @selection

  afterRender: ->
    # initialize all our app views
    @titleView = new TitleView(model: @router)
    @masthead  = new View()
    @content   = new View(tagName: 'section', className: 'container fluid')

    @attach(new NavbarView(model: @selection, router: @router))
    @attach(@masthead)
    @attach(new AlertsView(collection: @alerts))
    @attach(@content)
    @attach(new FooterView({@baseUrl}))

    # trigger the first selection change. go go gadget app!
    _.defer(@selection.update)
    _.defer(@checkStatus)

  checkStatus: =>
    {alerts} = this
    $.getJSON("#{@baseUrl}check-status").error(alerts.handleError).success (status) ->
      _.each status.alerts, (alert) ->
        alerts.add(_.extend(block: not alert.msg.search(/<(p|ul|ol|div)[ >]/i), alert))

  showMasthead: (options = {}) =>
    @masthead.attach(new MastheadView(options), {method: 'html'})

  removeMasthead: () ->
    @masthead.detachChildren()

  showNotFound: (heading, content) ->
    @showMasthead(content: notFoundTemplate({heading, content}), epic: true, error: true)

  showWelcome: _.once(->
    @showMasthead(content: welcomeTemplate(version: Genghis.version), epic: true, className: 'masthead welcome')
  )

  autoShowSection: (route) ->
    if ROUTE_SECTION_MAP[route]
      @showSection(ROUTE_SECTION_MAP[route])

  showSection: (section) =>
    @removeMasthead()

    view = switch section
      when 'servers'
        @showWelcome()
        new ServersView(collection: @servers)

      when 'databases'
        new DatabasesView(
          model:      @selection.currentServer,
          collection: @databases
        )

      when 'collections'
        new CollectionsView(
          model:      @selection.currentDatabase,
          collection: @collections
        )

      when 'documents'
        new DocumentsView(
          model:      @selection.currentCollection,
          collection: @documents,
          pagination: @selection.pagination
        )

      when 'explain'
        new ExplainView(model: @section.explain)

      when 'document'
        new DocumentsView(model: @selection.currentDocument)

    if view
      $('body').addClass('has-section')
      @content.attach(view, method: 'html')
    else
      @content.detachChildren()
      $('body').removeClass('has-section')
      @showNotFound()

module.exports = App
