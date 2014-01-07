jQuery = require 'jquery'
require 'jquery.tablesorter'

SIZES   = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB']
IS_SIZE = /^\d+(\.\d+)? (Bytes|KB|MB|GB|TB|PB)$/

jQuery.tablesorter.addParser
  id: 'size'
  type: 'numeric'
  is: (s) -> s.trim().match(IS_SIZE)
  format: (s) ->
    [size, unit] = s.trim().split(' ')
    parseFloat(size) * Math.pow(1024, _.indexOf(SIZES, unit))
