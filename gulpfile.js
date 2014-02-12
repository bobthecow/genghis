'use strict';

var gulp   = require('gulp');
var lr     = require('tiny-lr');
var server = lr();

require('./tasks/build');
require('./tasks/clean');
require('./tasks/copy').withServer(server);
require('./tasks/lint');
require('./tasks/livereload').withServer(server);
require('./tasks/report');
require('./tasks/scripts').withServer(server);
require('./tasks/styles').withServer(server);
require('./tasks/templates').withServer(server);

var watch = require('./tasks/watch');

// By default, build all the things!
gulp.task('default', ['rebuild'], watch);
