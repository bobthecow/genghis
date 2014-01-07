'use strict';

var $        = require('jquery');
var _        = require('underscore');
var Backbone = require('backbone');

require('backbone.declarative');
require('backbone.mousetrap');

var Giraffe  = require('./shims/giraffe');

module.exports = {
  $: $,
  _: _,
  Backbone: Backbone,
  Giraffe:  Giraffe
};
