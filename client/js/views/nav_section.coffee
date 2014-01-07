$            = require 'jquery'
View         = require './view.coffee'
template     = require 'hgn!genghis/templates/nav_section'
menuTemplate = require 'hgn!genghis/templates/nav_section_menu'

require 'jquery.hoverintent'

class NavSection extends View
  tagName:      'li'
  template:     template
  menuTemplate: menuTemplate

  ui:
    '$toggle': '.dropdown-toggle'
    '$menu':   'ul.dropdown-menu'

  modelEvents:
    'change': 'updateLink'

  collectionEvents:
    'add':    'renderMenu'
    'remove': 'renderMenu'
    'reset':  'renderMenu'

  initialize: ->
    @render()

  afterRender: ->
    @$toggle.hoverIntent ((e) ->
      $(e.target)
        .parent('li')
          .addClass('open')
          .siblings('li')
            .removeClass('open')
    ), $.noop

  updateLink: ->
    @$toggle
      .text((if @model.id then @model.id else ''))
      .attr('href', (if @model.id then @model.url else ''))

  renderMenu: ->
    @$menu.html @menuTemplate(model: @model, collection: @collection)

    # Handle really wide badges on the menu dropdown
    @$menu.find('a span').each (i, el) ->
      $el = $(el)
      len = $el.text().length
      $el.parent().css 'padding-right', "#{len + 0.5}em" if len > 3

module.exports = NavSection
