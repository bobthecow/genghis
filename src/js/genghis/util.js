Genghis.Util = {
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

        return ((i === 0)? (bytes / Math.pow(1024, i)) : (bytes / Math.pow(1024, i)).toFixed(1)) + ' ' + sizes[i];
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
    }
};
