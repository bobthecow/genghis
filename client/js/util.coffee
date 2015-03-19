{$, _} = require './vendors'

Util =
  route: (url) ->
    url.replace(window.app.baseUrl, '').replace /^\//, ''

  parseSearch: (str = '') ->
    params = {}
    if str.length
      _.each str.split('&'), (val) ->
        [name, chunks...] = val.split('=')
        params[name] = decodeURIComponent(chunks.join("="))
    params

  # Encode search params, but not too much. Our queries have a bunch of {}[]:$,
  # ... which are all technically legal to have there. So let's keep 'em.
  buildSearch: (params) ->
    e = (v) ->
      encodeURIComponent(v).replace(/%(7B|7D|5B|5D|3A|24|2C)/g, decodeURIComponent)
    _.map(params, (val, name) -> "#{e(name)}=#{e(val)}").join('&')

  humanizeSize: (bytes) ->
    return 'n/a' if bytes is -0
    sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)), 10)
    size = (if (i is 0) then (bytes / Math.pow(1024, i)) else (bytes / Math.pow(1024, i)).toFixed(1))
    size = Util.round(size, 2).toString().replace(/\.0+$/, '')
    "#{size} #{sizes[i]}"

  humanizeCount: (count = 0) ->
    suffix = ''
    if count > 1000
      count = Math.floor(count / 1000)
      suffix = ' k'
    if count > 1000
      count = Math.floor(count / 1000)
      suffix = ' M'
    return '...' if count > 1000
    "#{count}#{suffix}"

  round: (value, precision = 0) ->
    return Math.round(value) if +precision is 0
    value = +value
    exp   = -1 * (+precision)
    return NaN if _.isNaN(value) or not (_.isNumber(exp) and exp % 1 is 0)
    value = value.toString().split('e')
    value = Math.round(+(value[0] + 'e' + (if value[1] then (+value[1] - exp) else -exp)))
    value = value.toString().split('e')
    +(value[0] + 'e' + (if value[1] then (+value[1] + exp) else exp))

  escape: (str) ->
    return unless str
    String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')

  toggleCollapser: (e) ->
    $property = $(e.currentTarget).blur().parent()
    $value    = $property.children('.v')
    isName    = /^\s*(name|title)\s*/i
    summary   = ''

    unless $property.children('.e').length
      if $value.hasClass('o')
        open  = '{'
        close = '}'

        # Try to find the 'name' or 'title' property first...
        $s = $(_.detect($value.find('> span.p > var'), (el) ->
          isName.test $(el).text()
        )).siblings('span.v')

        # Otherwise, we'll settle for anything, basically.
        if $s.length is 0
          $s = $(_.detect($value.find('> span.p > span.v'), (el) ->
            $el = $(el)
            $el.hasClass('n') or $el.hasClass('b') or ($el.hasClass('q') and $el.text().length < 64)
          ))

        # If we found something, store the summary.
        if $s?.length
          prop    = $s.siblings('var').text()
          summary = ((if prop then prop + ': ' else '')) + $s.text()

      else
        open  = '['
        close = ']'

        # Look for the first short thing to put in the summary...
        $s = $value
          .children('.v')
          .first()
          .filter('.call,.a,.re,.b,.z,.n,.q,.ar.empty,.o.empty')

        if $s?.length
          summary = $s.text()

      summary = Util.escape("#{summary[0..50]} ") if summary isnt ''
      $property.append "<span class=\"e\">#{open} <q>#{summary}&hellip;</q> #{close}</span>"

    $property.toggleClass('collapsed')
    e.preventDefault()

  base64Encode: (string) ->
    b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
    length = string.length
    output = ''
    i = 0

    while i < length
      ascii = [
        string.charCodeAt(i)
        string.charCodeAt(i + 1)
        string.charCodeAt(i + 2)
      ]
      index = [
        ascii[0] >> 2
        ((ascii[0] & 3) << 4) | ascii[1] >> 4
        ((ascii[1] & 15) << 2) | ascii[2] >> 6
        ascii[2] & 63
      ]
      index[2] = 64  if isNaN(ascii[1])
      index[3] = 64  if isNaN(ascii[2])
      output += b64[index[0]] + b64[index[1]] + b64[index[2]] + b64[index[3]]
      i += 3
    output

  base64Decode: (string) ->
    b64    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
    length = string.length
    output = ''
    string = string.replace(/[^A-Za-z0-9\+\/\=]/g, '')
    i = 0
    while i < length
      enc1 = b64.indexOf(string.charAt(i++))
      enc2 = b64.indexOf(string.charAt(i++))
      enc3 = b64.indexOf(string.charAt(i++))
      enc4 = b64.indexOf(string.charAt(i++))
      chr1 = (enc1 << 2) | (enc2 >> 4)
      chr2 = ((enc2 & 15) << 4) | (enc3 >> 2)
      chr3 = ((enc3 & 3) << 6) | enc4
      output = output + String.fromCharCode(chr1)
      output = output + String.fromCharCode(chr2)  unless enc3 is 64
      output = output + String.fromCharCode(chr3)  unless enc4 is 64
    output

  base64ToHex: (str) ->
    hex = []
    bin = atob(str.replace(/[=\s]+$/, ''))
    length = bin.length
    i = 0

    while i < length
      chr = bin.charCodeAt(i).toString(16)
      hex.push (if (chr.length is 1) then '0' + chr else chr)
      ++i
    hex.join ''

  encodeDocumentId: (id) ->
    return if _.isUndefined(id)
    if _.isObject(id) and id.$genghisType is 'ObjectId'
      id.$value
    else
      '~' + @base64Encode(JSON.stringify(id))

  decodeDocumentId: (id) ->
    if _.isString(id) and id[0] is '~'
      @base64Decode(id.substr(1))
    else
      id

  download: do ->
    frame = undefined
    (url) ->
      unless frame
        frame = $('<iframe>', id: 'genghis-util-download').hide().appendTo('body')
      frame.attr 'src', url

  readAsDataURL: (file) ->
    deferred = new $.Deferred()
    reader   = new FileReader()
    reader.onload = (e) ->
      deferred.resolve(e.target.result, e)
    reader.onerror = (e) ->
      deferred.resolve(e)
    reader.readAsDataURL(file)
    deferred.promise()

module.exports = Util
