require(['jquery.tablesorter'], function(_1) {
    jQuery.tablesorter.addParser({
        id: 'size',
        is: function(s) {
            return s.trim().match(/^\d+(\.\d+)? (Bytes|KB|MB|GB|TB|PB)$/);
        },
        format: function(s) {
            var sizes  = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'],
                chunks = s.trim().split(' ');

            return parseFloat(chunks.shift()) * Math.pow(1024, _.indexOf(sizes, chunks.shift()));
        },
        type: 'numeric'
    });
});
