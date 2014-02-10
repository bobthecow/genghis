{$, _}      = require '../vendors'
Util        = require '../util'
GenghisJSON = require '../json'
defaults    = require '../defaults'
View        = require './view'
template    = require '../../templates/search.mustache'

PLACEHOLDERS = [
  '{name: /genghis(app)?/i}'
  '{awesomeness: {$gt: 10}}'
  '{search: "like this, yo."}'
  '{neverGonna: ["give you up", "let you down", "run around", "desert you"]}'
]

_j = (val, pretty = false) ->
  GenghisJSON.stringify(val, pretty)

_n = (q = '', pretty = false) ->
  q = "#{q}".trim()
  if q isnt ''
    try
      q = GenghisJSON.normalize(q, pretty)
  q

class Search extends View
  tagName:   'form'
  className: 'navbar-search navbar-form navbar-left'
  template:  template

  ui:
    '$query':    'input#navbar-query'
    '$well':     '.well'
    '$grippie':  '.grippie'
    '$advanced': '.search-advanced'

  events:
    'keyup $query':         'handleSearchKeyup'
    'click span.grippie':   'toggleExpanded'
    'click button.cancel':  'collapseSearch'
    'click button.search':  'findDocumentsAdvanced'
    'click button.explain': 'explainQuery'

  keyboardEvents:
    '/': 'focusSearch'

  dataEvents:
    'change            model': 'updateQuery'
    'change:collection model': 'collapseNoFocus'

  initialize: ->
    @documents = @model.documents
    @search    = @model.search
    @explain   = @model.explain
    super

  serialize: ->
    placeholder: _.sample(PLACEHOLDERS)

  afterRender: ->
    @$el.submit (e) -> e.preventDefault()

    wrapper   = @$el
    resizable = @$well
    expand    = @expandSearch
    collapse  = @collapseSearch

    @$grippie.bind 'mousedown', (e) ->
      mouseMove = (e) ->
        mouseY = e.clientY + document.documentElement.scrollTop - wrapper.offset().top
        wrapper.height mouseY + 'px'  if mouseY >= minHeight and mouseY <= maxHeight
        if wrapper.hasClass('expanded')
          collapse() if mouseY < minHeight
        else
          expand() if mouseY > 100
        false
      mouseUp = (e) ->
        $(document).unbind('mousemove', mouseMove).unbind('mouseup', mouseUp)
        collapse() unless wrapper.hasClass('expanded')
        e.preventDefault()
      e.preventDefault()
      minHeight = 30
      maxHeight = Math.min($(window).height() / 2, 350)
      $(document)
        .mousemove(mouseMove)
        .mouseup(mouseUp)

  updateQuery: (query = '') =>
    if query = @search.get('query')
      query = _j(query) unless _.isEmpty(query)
    if _.isEmpty(query)
      query = @model.get('document')
      if _.isString(query) and query[0] is '~'
        query = _j({_id: Util.decodeDocumentId(query)})
    query = '' if _.isEmpty(query)
    @$query.val(query)

  handleSearchKeyup: (e) =>
    @$el.removeClass('has-error')
    if e.keyCode is 13
      e.preventDefault()
      @findDocuments($(e.target).val())
    else
      @blurSearch() if e.keyCode is 27

  findDocuments: (q, opt = {}) =>
    q   = q.trim()
    url = if opt.explain then @explain.baseUrl() else @documents.baseUrl()

    # ObjectId hax.
    if q.match(/^([a-z\d]+)$/i) and not opt.explain
      @app.router.navigate("#{url}/#{q}", true)
      return

    try
      q = GenghisJSON.parse(q)
    catch e
      @$el.addClass('has-error')
      return

    search = @search.toString(query: q, fields: {}, sort: {}, page: 1, pretty: true)
    @app.router.navigate("#{url}#{search}", true)

  findDocumentsAdvanced: (e) =>
    @findDocuments(@editor.getValue())
    @collapseSearch()

  explainQuery: (e) ->
    @findDocuments(@editor.getValue(), {explain: true})
    @collapseNoFocus()

  focusSearch: (e) =>
    # TODO: make the view stateful rather than querying the DOM
    if @$query.is(':visible')
      e?.preventDefault?()
      @$query.focus()
    else if @editor and @$well.is(':visible')
      e?.preventDefault?()
      @editor.focus()

  blurSearch: =>
    @$query.blur()
    @updateQuery()

  advancedSearchToQuery: =>
    q = _n(@editor.getValue())
      .replace(/^\{\s*\}$/, '')
      .replace(/^\{\s*(['"]?)_id\1\s*:\s*\{\s*(['"]?)\$id\2\s*:\s*(["'])([a-z\d]+)\3\s*\}\s*\}$/, '$4')
      .replace(/^\{\s*(['"]?)_id\1\s*:\s*(new\s+)?ObjectId\s*\(\s*(["'])([a-z\d]+)\3\s*\)\s*\}$/, '$4')
    @$query.val(q)

  queryToAdvancedSearch: =>
    q = @$query.val().trim()
    q = "{_id:ObjectId(\"#{q}\")}" if q.match(/^[a-z\d]+$/i)
    @editor.setValue(_n(q, true))

  expandSearch: (expand) =>
    return unless @isAttached()
    unless @editor
      @editor = CodeMirror(@$well[0], _.extend({}, defaults.codeMirror,
        lineNumbers: false
        placeholder: _n(@$query.attr('placeholder'), true)
        extraKeys:
          'Ctrl-Enter': @findDocumentsAdvanced
          'Cmd-Enter':  @findDocumentsAdvanced
          'Esc':        @findDocumentsAdvanced
      ))
      @editor.on(
        focus:  => @$advanced.addClass('focused')
        blur:   => @$advanced.removeClass('focused')
        change: @advancedSearchToQuery
      )

    @queryToAdvancedSearch()
    @$el.addClass 'expanded'
    {editor, focusSearch} = this
    _.defer ->
      editor.refresh()
      focusSearch()

  collapseSearch: =>
    @collapseNoFocus()
    @focusSearch()

  collapseNoFocus: =>
    @$el.removeClass('expanded').css('height', 'auto')

  toggleExpanded: =>
    if @$el.hasClass('expanded')
      @collapseSearch()
    else
      @expandSearch()
      @$el.height(Math.floor($(window).height() / 4) + 'px')

module.exports = Search
