$        = require 'jquery'
_        = require 'underscore'
Backbone = require 'backbone'


# Extend jQuery
window.$ = window.jQuery = $
require 'jquery-hoverIntent/jquery.hoverIntent'
require 'bootstrap/js/dropdown'
require 'bootstrap/js/modal'
require 'bootstrap/js/tooltip'
require 'bootstrap/js/popover'
require 'jquery.tablesorter/js/jquery.tablesorter'

# And our little tablesorter mixin.
do ->
  SIZES   = ['Bytes','KB','MB','GB','TB','PB']
  IS_SIZE = /^\d+(\.\d+)? (Bytes|KB|MB|GB|TB|PB)$/
  $.tablesorter.addParser
    id:   'size'
    type: 'numeric'
    is: (s) ->
      s.trim().match(IS_SIZE)
    format: (s) ->
      [val, unit] = s.trim().split(' ')
      parseFloat(val) * Math.pow(1024, _.indexOf(SIZES, unit))


# Extend Backbone
window._        = _
window.Backbone = Backbone

Backbone.$ = $

# give backbone.mousetrap a hand.
require 'mousetrap'
require 'backbone.mousetrap/backbone.mousetrap'

Giraffe = require 'backbone.giraffe'


# Now export the whole mess.
module.exports = {$, _, Backbone, Giraffe}
