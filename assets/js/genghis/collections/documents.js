define(['underscore', 'backbone.giraffe', 'genghis/collections', 'genghis/models/document'], function(_, Giraffe, Collections, Document) {

    return Collections.Documents = Giraffe.Collection.extend({
        model: Document,

        parse: function(resp) {
            app.selection.pagination.set({
                page:  resp.page,
                pages: resp.pages,
                count: resp.documents.length,
                total: resp.count
            });

            this.guessCreationTime = _.all(resp.documents, function(d) {
                var id = d._id || null;

                // Handle the trivial cases...

                // non-object ids shouldn't count against it
                if (!_.isObject(id) || id.$genghisType != 'ObjectId') {
                    return true;
                }

                // object ids with the wrong length string should
                if (id.$value.length != 24) {
                    return false;
                }

                var timestamp = parseInt(id.$value.substring(0,8), 16) * 1000;

                // If it's too far in the past or future, don't guess creation time.
                return (timestamp > this.start && timestamp < this.end);
            }, {
                start: 1251388342000,                                     // MongoDB v1.0 release date
                end:   (new Date()).getTime() + (2 * 24 * 60 * 60 * 1000) // within the next 48 hours
            });

            return resp.documents;
        }
    });
});
