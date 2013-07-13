define(['genghis'], function(Genghis) {
    return Genghis.defaults = {
        codeMirror: {
            mode:          'application/json',
            lineNumbers:   true,
            tabSize:       4,
            indentUnit:    4,
            matchBrackets: true
        }
    };
});
