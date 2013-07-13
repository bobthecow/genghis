define(['genghis/collections', 'genghis/collections/base_collection', 'genghis/models/database'], function(Collections, BaseCollection, Database) {
  return Collections.Databases = BaseCollection.extend({
    model: Database
  });
});
