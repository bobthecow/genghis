var hogan = require('hogan.js'),
    through = require('through')

var filenamePattern = /\.(html|hogan|hg|mustache|ms)$/

var wrap = function(template) {
    return 'module.exports=(function() {var Hogan = require(\'hogan.js\');var template = new Hogan.Template(' + template + ');return function(data) {return template.render(data)}}());'
}

module.exports = function(file) {
    if (!filenamePattern.test(file)) return through()

    var input = ''
    var write = function(buffer) {
        input += buffer
    }

    var end = function() {
        this.queue(wrap(hogan.compile(input, {asString: true})))
        this.queue(null)
    }

    return through(write, end)
}
