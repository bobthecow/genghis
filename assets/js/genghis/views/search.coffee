define (require) ->
  $           = require('jquery')
  _           = require('underscore')
  Util        = require('genghis/util')
  GenghisJSON = require('genghis/json')
  defaults    = require('genghis/defaults')
  View        = require('genghis/views/view')
  template    = require('hgn!genghis/templates/search')

  PLACEHOLDERS = [
    '{name: /genghis(app)?/i}'
    '{awesomeness: {$gt: 10}}'
    '{search: "like this, yo."}'
    '{neverGonna: ["give you up", "let you down", "run around", "desert you"]}'
  ]

  View.extend
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

    modelEvents:
      'change':            'updateQuery'
      'change:collection': 'collapseNoFocus'

    initialize: ->
      _.bindAll this, "render", "updateQuery", "handleSearchKeyup", "findDocuments", "findDocumentsAdvanced", "focusSearch", "blurSearch", "advancedSearchToQuery", "queryToAdvancedSearch", "expandSearch", "collapseSearch", "collapseNoFocus", "toggleExpanded"

    serialize: ->
      query:       @model.get("query")
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
            collapse()  if mouseY < minHeight
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

    updateQuery: =>
      @$query.val @normalizeQuery(@model.get('query') or @getDocumentQuery() or '')

    getDocumentQuery: ->
      q = @model.get('document')
      if _.isString(q) and q[0] is '~'
        q = GenghisJSON.normalize("{\"_id\":#{Util.decodeDocumentId(q)}}")
      q

    handleSearchKeyup: (e) =>
      @$el.removeClass "error"
      if e.keyCode is 13
        e.preventDefault()
        @findDocuments $(e.target).val()
      else @blurSearch()  if e.keyCode is 27

    findDocuments: (q, section) =>
      section = section or "documents"
      url = Util.route(@model.currentCollection.url + "/" + section)
      q = q.trim()
      if section is "documents" and q.match(/^([a-z\d]+)$/i)
        url = url + "/" + q
      else
        try
          q = GenghisJSON.normalize(q, false)
        catch e
          @$el.addClass "error"
          return
        url = url + "?" + Util.buildQuery(q: encodeURIComponent(q))
      app.router.navigate url, true

    findDocumentsAdvanced: (e) =>
      @findDocuments @editor.getValue()
      @collapseSearch()

    explainQuery: (e) ->
      @findDocuments @editor.getValue(), "explain"
      @collapseSearch()

    focusSearch: (e) =>
      # TODO: make the view stateful rather than querying the DOM
      if @$query.is(":visible")
        e?.preventDefault?()
        @$query.focus()
      else if @editor and @$well.is(":visible")
        e?.preventDefault?()
        @editor.focus()

    blurSearch: =>
      @$query.blur()
      @updateQuery()

    normalizeQuery: (q) ->
      q = q.trim()
      if q isnt ""
        try
          q = GenghisJSON.normalize(q, false)
      q
        .replace(/^\{\s*\}$/, '')
        .replace(/^\{\s*(['"]?)_id\1\s*:\s*\{\s*(['"]?)\$id\2\s*:\s*(["'])([a-z\d]+)\3\s*\}\s*\}$/, '$4')
        .replace(/^\{\s*(['"]?)_id\1\s*:\s*(new\s+)?ObjectId\s*\(\s*(["'])([a-z\d]+)\3\s*\)\s*\}$/, '$4')

    advancedSearchToQuery: =>
      @$query.val @normalizeQuery(@editor.getValue())

    queryToAdvancedSearch: =>
      q = @$query.val().trim()
      q = "{_id:ObjectId(\"#{q}\")}" if q.match(/^[a-z\d]+$/i)
      if q isnt ""
        try
          q = GenghisJSON.normalize(q, true)
      @editor.setValue q

    expandSearch: (expand) =>
      unless @editor
        wrapper = @$advanced
        @editor = CodeMirror(@$well[0], _.extend({}, defaults.codeMirror,
          lineNumbers: false
          extraKeys:
            'Ctrl-Enter': @findDocumentsAdvanced
            'Cmd-Enter':  @findDocumentsAdvanced
            'Esc':        @findDocumentsAdvanced
        ))
        @editor.on 'focus', -> wrapper.addClass    'focused'
        @editor.on 'blur',  -> wrapper.removeClass 'focused'
        @editor.on 'change', @advancedSearchToQuery

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
      @$el
        .removeClass('expanded')
        .css('height', 'auto')

    toggleExpanded: =>
      if @$el.hasClass('expanded')
        @collapseSearch()
      else
        @expandSearch()
        @$el.height Math.floor($(window).height() / 4) + 'px'
