View       = require './view'
template   = require '../../templates/nav_menu_item.mustache'

class NavMenuItem extends View
  tagName:  'li'
  template: template

module.exports = NavMenuItem
