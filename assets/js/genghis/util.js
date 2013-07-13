define(['genghis'], function(Genghis) {
    return Genghis.Util = {
        route: function(url) {
            return url.replace(app.baseUrl, '').replace(/^\//, '');
        },

        parseQuery: function(str) {
            var params = {};

            if (str.length) {
                _.each(str.split('&'), function(val) {
                    var chunks = val.split('=');
                    var name   = chunks.shift();

                    params[name] = decodeURIComponent(chunks.join('='));
                });
            }

            return params;
        },

        buildQuery: function(params) {
            return _.map(params, function(val, name) { return name + '=' + val; }).join('&');
        },

        humanizeSize: function(bytes) {
            if (bytes ==- 0) return 'n/a';
            var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
            var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)), 10);

            var size = (i === 0) ? (bytes / Math.pow(1024, i)) : (bytes / Math.pow(1024, i)).toFixed(1);
            size = Genghis.Util.round(size, 2).toString().replace(/\.0+/, '');

            return size + ' ' + sizes[i];
        },

        humanizeCount: function(count) {
            var suffix = '';
            count = count || 0;

            if (count > 1000) {
                count  = Math.floor(count / 1000);
                suffix = ' k';
            }

            if (count > 1000) {
                count  = Math.floor(count / 1000);
                suffix = ' M';
            }

            if (count > 1000) {
                return '...';
            }

            return count + suffix;
        },

        round: function(value, precision) {
            // If the precision is undefined or zero...
            if (typeof precision === 'undefined' || +precision === 0) {
                return Math.round(value);
            }
            value = +value;
            var exp = -1 * (+precision);
            // If the value is not a number or the exp is not an integer...
            if (isNaN(value) || !(typeof exp === 'number' && exp % 1 === 0)) {
                return NaN;
            }
            // Shift
            value = value.toString().split('e');
            value = Math.round(+(value[0] + 'e' + (value[1] ? (+value[1] - exp) : -exp)));
            // Shift back
            value = value.toString().split('e');
            return +(value[0] + 'e' + (value[1] ? (+value[1] + exp) : exp));
        },

        escape: function(str) {
            if (str) {
                return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
            }
        },

        attachCollapsers: function(scope) {
            $('.document', scope).on('click', 'button,span.e', function(e) {

                var $property = $(this).parent();
                var $value    = $property.children('.v');
                var isName    = /^\s*(name|title)\s*/i;
                var isObject  = $value.hasClass('o');
                var summary   = '';
                var prop;
                var $s;

                if (!$property.children('.e').length) {
                    if (isObject) {
                        $s = $(_.detect($value.find('> span.p > var'), function(el) {
                            return isName.test($(el).text());
                        })).siblings('span.v');

                        if ($s.length === 0) {
                            $s = $(_.detect($value.find('> span.p > span.v'), function(el) {
                                var $el = $(el);
                                return $el.hasClass('n') || $el.hasClass('b') ||
                                    ($el.hasClass('q') && $el.text().length < 64);
                            }));
                        }

                        if ($s && $s.length) {
                            prop = $s.siblings('var').text();
                            summary = (prop ? prop + ': ' : '') + Genghis.Util.escape($s.text());
                        }
                    }

                    $property.append(
                        '<span class="e">' +
                        (isObject ? '{' : '[') +
                        ' <q>' +
                        summary +
                        ' &hellip;</q> ' +
                        (isObject ? '}' : ']') +
                        '</span>'
                    );
                }

                $property.toggleClass('collapsed');
                e.preventDefault();
            });
        },

        base64Encode: function(string) {
            var b64    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
            var length = string.length;
            var output = '';

            for (var i = 0; i < length; i += 3) {
                var ascii = [
                    string.charCodeAt(i),
                    string.charCodeAt(i+1),
                    string.charCodeAt(i+2)
                ];

                var index = [
                    ascii[0] >> 2,
                    ((ascii[0] & 3) << 4) | ascii[1] >> 4,
                    ((ascii[1] & 15) << 2) | ascii[2] >> 6,
                    ascii[2] & 63
                ];

                if (isNaN(ascii[1])) {
                    index[2] = 64;
                }
                if (isNaN(ascii[2])) {
                    index[3] = 64;
                }

                output += b64[index[0]] + b64[index[1]] + b64[index[2]] +b64[index[3]];
            }

            return output;
        },

        base64Decode: function (string) {
            var b64    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
            var length = string.length;
            var output = '';

            var chr1, chr2, chr3;
            var enc1, enc2, enc3, enc4;

            string = string.replace(/[^A-Za-z0-9\+\/\=]/g, '');

            var i = 0;
            while (i < length) {
                enc1 = b64.indexOf(string.charAt(i++));
                enc2 = b64.indexOf(string.charAt(i++));
                enc3 = b64.indexOf(string.charAt(i++));
                enc4 = b64.indexOf(string.charAt(i++));

                chr1 = (enc1 << 2) | (enc2 >> 4);
                chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
                chr3 = ((enc3 & 3) << 6) | enc4;

                output = output + String.fromCharCode(chr1);

                if (enc3 != 64) {
                    output = output + String.fromCharCode(chr2);
                }
                if (enc4 != 64) {
                    output = output + String.fromCharCode(chr3);
                }

            }

            return output;
        },

        base64ToHex: function(str) {
            var hex = [];
            var bin = atob(str.replace(/[=\s]+$/, ''));
            var length = bin.length;

            for (var i = 0; i < length; ++i) {
                var chr = bin.charCodeAt(i).toString(16);
                hex.push((chr.length === 1) ? '0' + chr : chr);
            }

            return hex.join('');
        },

        encodeDocumentId: function(id) {
            if (_.isObject(id) && id.hasOwnProperty('$genghisType') && id.$genghisType == 'ObjectId') {
                return id.$value;
            } else if (!_.isUndefined(id)) {
                return '~' + this.base64Encode(JSON.stringify(id));
            }
        },

        decodeDocumentId: function(id) {
            if (_.isString(id) && id[0] === '~') {
                return this.base64Decode(id.substr(1));
            } else {
                return id;
            }
        },

        download: (function() {
            var frame;
            return function(url) {
                if (!frame) {
                    frame = $('<iframe>', {id: 'genghis-util-download'}).hide().appendTo('body');
                }

                frame.attr('src', url);
            };
        })()
    };
});

