define(function(require) {
    'use strict';

    var Util = require('genghis');
    var View = require('genghis/views/view');

    return View.extend({
        modelEvents: {
            'all': 'setTitle'
        },

        setTitle: function(name) {
            var args = Array.prototype.slice.call(arguments, 1);

            switch (name) {
                case 'route:index':
                case 'route:server':
                case 'route:database':
                case 'route:collection':
                    // just pass these ones through :)
                    break;

                case 'route:document':
                    args.push(Util.decodeDocumentId(args.pop()));
                    break;

                case 'route:collectionQuery':
                    args.push('Query results');
                    break;

                case 'route:explainQuery':
                    args.push('Query explanation');
                    break;

                case 'route:notFound':
                    args = ['Not Found'];
                    break;

                default:
                    return;
            }

            args.unshift('Genghis');
            document.title = args.join(' \u203A ');
        }
    });
});
