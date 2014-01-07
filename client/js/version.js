'use strict';

var fs = require('fs');

var VERSION = fs.readFileSync(__dirname + '/../../../VERSION.txt');

module.exports = VERSION;
