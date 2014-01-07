'use strict';

var $ = window.$ = require('jquery');

// jQuery extensions
require('jquery-hoverIntent/jquery.hoverIntent');
require('bootstrap/js/dropdown');
require('bootstrap/js/modal');
require('bootstrap/js/popover');
require('bootstrap/js/tooltip');

require('jquery.tablesorter/js/jquery.tablesorter.js');

// And our little tablesorter mixin.
(function() {
  var SIZES = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
  var IS_SIZE = /^\d+(\.\d+)? (Bytes|KB|MB|GB|TB|PB)$/;

  jQuery.tablesorter.addParser({
    id: 'size',
    type: 'numeric',
    is: function(s) {
      return s.trim().match(IS_SIZE);
    },
    format: function(s) {
      var size, unit, _ref;
      _ref = s.trim().split(' '), size = _ref[0], unit = _ref[1];
      return parseFloat(size) * Math.pow(1024, _.indexOf(SIZES, unit));
    }
  });
})


var _        = window._        = require('underscore');
var Backbone = window.Backbone = require('backbone');

// Backbone extensions
require('backbone.declarative');

// give backbone.mousetrap a hand.
require('mousetrap');
require('backbone.mousetrap');

// Giraffe needs a shim, but not for long
require('backbone.giraffe');
var Giraffe = Backbone.Giraffe;


// And export the whole mess.
module.exports = {
  $:          $,
  _:          _,
  Backbone:   Backbone,
  Giraffe:    Giraffe
};
