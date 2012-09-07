## v2.0.0-dev

Brand new features:

 * Genghis doesn't require a webserver! Ghengis.php now runs as a standalone server with the PHP 5.4 CLI SAPI.
 * Genghis doesn't require PHP! Introducing Genghis.rb — Thanks @TylerBrock for doing all the work :)
 * Add support for pre-configured servers via the `$GENGHIS_SERVERS` environment variable.
 * Add support for replica sets, e.g. `localhost:12345/?replicaSet=production`.

Tons of improvements:

 * Add this CHANGELOG. Meta.
 * Genghis now has a more refined visual style — greeeeen!
 * More responsive design (check it in a really small window!)
 * Epic document parsing and rendering overhaul:
    * Huge speed improvements. Rendering, collapsing and scrolling like wow.
    * Date, ObjectId and regular expression values (and more) are now formatted (and edited) for humans, not robots.
    * Documents are now displayed _and edited_ as Genghis Flavored JSON, a more lenient and intuitive superset of JSON.
 * UX Improvements:
    * Update code editor. The new one (CodeMirror) is lighter, faster, smaller and a cleaner implementation.
    * Add Cmd+Enter / Ctrl+Enter keyboard shortcut for saving the document being edited.
    * Prevent "new document" modal from closing on background click.
    * Better "keyboard shortcuts" dialog on smaller screens.
    * Require database name confirmation rather than DELETE before removing a db.
    * Collection removal is paranoid as well: it also requires confirmation before removing.
    * Expando-matic search box. No more squinting or scrolling to see your massive queries.
 * Update Bootstrap (2.1.0), jQuery (1.8.0), Underscore (1.3.3), and Backbone (0.9.2).
 * Use UglifyJS instead of closure compiler to minify JS. It's faster and doesn't require Java :)

And a handful of bug fixes:

 * Fix #19 — Only implicitly wrap MongoIds if they're 24 character hex strings.
 * Fix #20 — Support creating and editing documents with an `attributes` property.
 * Fix output glitches when displaying a brand new document immediately after an existing document.
 * Fix – possible JavaScript error when adding a new collection.
 * Fix – handful of rare (and relatively benign) error messages.
 * Fix — malformed server DSN could prevent servers list from rendering.
 * Fix — rare bug where properties with a specific structure might be mistaken for ObjectIds or Dates.
 * Fix — no longer recreates missing dbs and collections on GET requests.
 * Improve error handling in a couple of places.


## v1.4.2

 * Mention the PECL driver dependency.
 * Fix regressions with the search box.
 * Fix auto-collapsing documents when there are a bunch.
 * Escape HTML in folded document summaries.


## v1.4.1

 * Update to Bootstrap v2.0.2.
 * Fix error message regression when PECL Mongo driver isn't present.
 * Fix missing CSS from the keyboard shortcuts help dialog.
 * Minor cleanup.


## v1.4.0

 * Add a keyboard shortcuts note to the footer.
 * Namespace PHP classes.
 * Improve document folding (style *and* performance!).


## v1.3.0

Genghis v1.3.0: Now with KEYBOARD SHORTCUTS!


## v1.2.0

 * Update to Bootstrap v2.0.1.
 * Work around bug with PECL Mongo driver < 1.0.11.


## v1.1.0

 * Add authentication support.
 * Expose additional details in server, database and collection rows.


## v1.0.3

Add a version number to docblocks and built packages.


## v1.0.2

Update to Bootstrap v1.4.0.


## v1.0.1

Fix an E_STRICT error in asset mime-type guessing.


## v1.0.0

Initial release.
