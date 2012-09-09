Genghis.Collections.Documents = Backbone.Collection.extend({
    model: Genghis.Models.Document,
    parse: function(resp) {
        app.selection.pagination.set({
            page:  resp.page,
            pages: resp.pages,
            count: resp.documents.length,
            total: resp.count
        });

        return resp.documents;
    }
});
