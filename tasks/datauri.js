'use strict';

var fs        = require('fs');
var es        = require('event-stream');
var _         = require('lodash');
var path      = require('path');
var datauri   = require('datauri');
var minimatch = require('minimatch');

// todo: use css-parse to only replace urls in css properties.

var URL_RE      = /^url\(\s*((["'])(.+?)\2|([^"'][^)]*))\s*\)$/;
var ALL_URLS_RE = /\burl\(\s*((["'])(.+?)\2|([^"'][^)]*))\s*\)/g;
var EXTERNAL_RE = /^(data|https?):/;

var escapeRe = function(str) {
  return (''+str).replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1");
};

var replaceUrl = function(value, cb) {
  var match = value.match(URL_RE);
  if (match) {
    var url = match[3] || match[4];
    var newUrl = cb(url);
    if (newUrl) {
      return value.replace(match[0], match[0].replace(match[1], newUrl));
    }
  }

  return value;
};

var replaceAllUrls = function(styles, cb) {
  var matches = styles.match(ALL_URLS_RE);
  if (matches) {
    _.uniq(matches).forEach(function(match) {
      var newVal = replaceUrl(match, cb);
      if (newVal) {
        styles = styles.replace(new RegExp(escapeRe(match), 'g'), newVal);
      }
    });
  }

  return styles;
};

var isGlobMatch = function(target, filePath) {
  return _.any(target, function(glob) {
    return minimatch(filePath, glob);
  });
};

module.exports = function(opt) {
  return es.map(function(file, cb) {
    opt = _.extend({
      base:   path.join(file.cwd, path.dirname(file.path)),
      target: '**/*.{png,gif,jpg,svg}'
    }, opt || {});

    var base   = path.resolve(file.cwd, opt.base || '');
    var target = _.map(_.isArray(opt.target) ? opt.target : [opt.target], function(glob) {
      return path.resolve(file.cwd, glob);
    });

    file.contents = new Buffer(replaceAllUrls(file.contents.toString(), function(url) {
      // Don't replace data: or http: urls.
      if (url.match(EXTERNAL_RE)) return;

      var filePath = path.resolve(base, url);
      if (!isGlobMatch(target, filePath) || !fs.existsSync(filePath)) {
        return;
      }

      return datauri(filePath);
    }));

    cb(null, file);
  });
};
