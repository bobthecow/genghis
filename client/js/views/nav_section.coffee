{$}         = require '../vendors'
View        = require './view'
NavMenuItem = require './nav_menu_item'
Projections = require 'backbone.projections'

MENU_CAP = 9

template    = require('../../templates/nav_section.mustache').render

class NavSection extends View
  tagName:  'li'
  template: template

  ui:
    '$toggle':  '.dropdown-toggle'
    '$menu':    'ul.dropdown-menu'
    '$divider': 'li.divider'

  dataEvents:
    'change model':     'updateLink'
    'reset collection': 'render'
    'add collection':   'addModel'

  initialize: ->
    @base = @collection
    capped      = new Projections.Capped(@base, cap: MENU_CAP, comparator: (m) -> - m.get('count'))
    @collection = new Projections.Sorted(capped, comparator: (m) -> m.get('name'))

  afterRender: ->
    @renderMenu()
    @updateLink()
    @$el.toggleClass('has-more-children', @base.length > MENU_CAP)
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
    @collection.each(@addModel)
    @$el.toggleClass('has-more-children', @base.length > MENU_CAP)
    # FIXME: Handle really wide badges on the menu dropdown
    @$menu.find('a span').each (i, el) ->
      $el = $(el)
      len = $el.text().length
      $el.parent().css 'padding-right', "#{len + 0.5}em" if len > 3

  addModel: (model) =>
    view = new NavMenuItem(model: model)
    view.attachTo(@$divider, method: 'before')

module.exports = NavSection
