/* jshint node: true */
'use strict';

var path   = require('path');
var fs     = require('fs');

var es     = require('event-stream');
var gutil  = require('gulp-util');
var _      = require('lodash');

var headerPlugin = function(headerText, data) {
  headerText = headerText || '';
  return es.map(function(file, cb){
    var context = _.extend({file: file}, _.isFunction(data) ? data(file) : data);
    var text    = _.isFunction(headerText) ? headerText(file, context) : headerText;
    file.contents = Buffer.concat([
      new Buffer(gutil.template(text, context)),
      file.contents
    ]);
    cb(null, file);
  });
};

headerPlugin.fromFile = function (filepath, data){
  if ('string' !== typeof filepath) throw new Error('Invalid filepath');
  var fileContent = fs.readFileSync(path.resolve(process.cwd(), filepath));
  return headerPlugin(fileContent, data);
};

module.exports = headerPlugin;
