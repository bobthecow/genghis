{$}          = require '../vendors'
View         = require './view'
template     = require '../../templates/nav_section.mustache'
menuTemplate = require '../../templates/nav_section_menu.mustache'

class NavSection extends View
  tagName:      'li'
  template:     template
  menuTemplate: menuTemplate

  ui:
    '$toggle': '.dropdown-toggle'
    '$menu':   'ul.dropdown-menu'

  dataEvents:
    'change model':                'updateLink'
    'add remove reset collection': 'renderMenu'

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
      .attr('href', (if @model.id then _.result(@model, 'url') else ''))

  renderMenu: ->
    @$menu.html(@menuTemplate(model: @model, collection: @collection))

    # Handle really wide badges on the menu dropdown
    @$menu.find('a span').each (i, el) ->
      $el = $(el)
      len = $el.text().length
      $el.parent().css 'padding-right', "#{len + 0.5}em" if len > 3

module.exports = NavSection
