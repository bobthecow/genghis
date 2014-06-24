{$, _, Giraffe}       = require '../vendors'

Router                = require '../router'

Selection             = require '../models/selection'
Alerts                = require '../collections/alerts'

View                  = require './view'
TitleView             = require './title'
NavbarView            = require './navbar'
MastheadView          = require './masthead'
AlertsView            = require './alerts'
FooterView            = require './footer'

ServersView           = require './servers'
DatabasesView         = require './databases'
CollectionsView       = require './collections'
DocumentsView         = require './documents'
ExplainView           = require './explain'
DocumentSectionView   = require './document_section' # TODO: rename to document view, make a document_edit view?

notFoundTemplate      = require '../../templates/not_found.mustache'
welcomeTemplate       = require '../../templates/welcome.mustache'

ROUTE_SECTION_MAP =
  'route:index':            'servers'
  'route:server':           'databases'
  'route:database':         'collections'
  'route:collection':       'documents'
  'route:collectionSearch': 'documents'
  'route:explain':          'explain'
  'route:document':         'document'

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

    $body = $('body').removeClass()

    view = switch section
      when 'servers'
        @showWelcome()
        new ServersView(collection: @servers)

      when 'databases'
        new DatabasesView(
          model:      @selection.server,
          collection: @databases
        )

      when 'collections'
        new CollectionsView(
          model:      @selection.database,
          collection: @collections
        )

      when 'documents'
        new DocumentsView(
          model:      @selection.coll,
          collection: @documents
        )

      when 'explain'
        new ExplainView(model: @selection.explain)

      when 'document'
        new DocumentSectionView(model: @selection.document)

    if view
      $body.addClass("has-section section-#{view.id}")
      @content.attach(view, method: 'html')
      _.defer(-> $(document).scrollTop(0))
    else
      @content.detachChildren()
      @showNotFound()

module.exports = App
