'use strict';

var $ = window.$ = window.jQuery = require('jquery');

// jQuery extensions
require('jquery-hoverIntent/jquery.hoverIntent');
require('bootstrap/js/dropdown');
require('bootstrap/js/modal');
require('bootstrap/js/tooltip');
require('bootstrap/js/popover');

require('jquery.tablesorter/js/jquery.tablesorter.js');

// And our little tablesorter mixin.
(function() {
  var SIZES = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
  var IS_SIZE = /^\d+(\.\d+)? (Bytes|KB|MB|GB|TB|PB)$/;

  $.tablesorter.addParser({
    id: 'size',
    type: 'numeric',
    is: function(s) {
      return s.trim().match(IS_SIZE);
    },
    format: function(s) {
      var chunks = s.trim().split(' ');
      return parseFloat(chunks[0]) * Math.pow(1024, _.indexOf(SIZES, chunks[1]));
    }
  });
})();


var _        = window._        = require('underscore');
var Backbone = window.Backbone = require('backbone');
Backbone.$ = $;

// Backbone extensions

// give backbone.mousetrap a hand.
require('mousetrap');
require('backbone.mousetrap');

var Giraffe = require('backbone.giraffe');

// And export the whole mess.
module.exports = {
  $:          $,
  _:          _,
  Backbone:   Backbone,
  Giraffe:    Giraffe
};
