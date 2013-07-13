define(['genghis/collections', 'genghis/collections/base_collection', 'genghis/models/collection'], function(Collections, BaseCollection, Collection) {
  return Collections.Collections = BaseCollection.extend({
    model: Collection
  });
});
