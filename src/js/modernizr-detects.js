Modernizr.addTest('cssmask', Modernizr.testAllProps('maskRepeat'));

Modernizr.addTest('textoverflow', Modernizr.testAllProps('textOverflow'));

Modernizr.addTest('filereader', function () {
    return !!(window.File && window.FileList && window.FileReader);
});

Modernizr.addTest('fileinput', function() {
    var elem = document.createElement('input');
    elem.type = 'file';
    return !elem.disabled;
});
