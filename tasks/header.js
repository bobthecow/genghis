/* jshint node: true */
'use strict';

var path = require('path');

var es = require('event-stream');
var gutil = require('gulp-util');
var extend = require('lodash.assign');

var headerPlugin = function(headerText, data) {
  headerText = headerText || '';
  return es.map(function(file, cb){
    var context = extend({file: file}, typeof data === 'function' ? data(file) : data);
    var text    = typeof headerText === 'function' ? headerText(file, context) : headerText;
    file.contents = Buffer.concat([
      new Buffer(gutil.template(text, context)),
      file.contents
    ]);
    cb(null, file);
  });
};

module.exports = headerPlugin;
