define(['modernizr'], function(Modernizr) {
    Modernizr.addTest('cssmask', Modernizr.testAllProps('maskRepeat'));

    Modernizr.addTest('textoverflow', Modernizr.testAllProps('textOverflow'));

    Modernizr.addTest('filereader', !!(window.File && window.FileList && window.FileReader));

    Modernizr.addTest('fileinput', function() {
        if(navigator.userAgent.match(/(Android (1.0|1.1|1.5|1.6|2.0|2.1))|(Windows Phone (OS 7|8.0)|(XBLWP)|(ZuneWP)|(w(eb)?OSBrowser)|(webOS)|Pre\/1.2|Kindle\/(1.0|2.0|2.5|3.0))/)) {
            return false;
        }
        var elem = document.createElement('input');
        elem.type = 'file';
        return !elem.disabled;
    });

    return Modernizr;
});
