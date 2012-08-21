## v1.5.0

Updates:

 * Update Bootstrap (2.1.0), jQuery (1.8.0), Underscore (1.3.3), and Backbone (0.9.2).
 * Add a CHANGELOG. Meta.

Improvements:

 * Require db name confirmation rather than DELETE.
 * More responsive design (check it in a really small window!)
 * Faster client side rendering. Can't complain about that, eh?
 * Better keyboard shortcuts dialog on smaller screens.
 * Improve error handling in a couple of places.
 * Use UglifyJS instead of closure compiler to minify JS. It's faster and doesn't require Java :)

Bugs:

 * Fix #19 — Only implicitly wrap MongoIds if they're 24 character hex strings.

Features:

 * Make Genghis work with the PHP 5.4 CLI SAPI webserver.
 * Add support for pre-configured servers via $GENGHIS_SERVERS env variable.
 * Add support for replica sets, e.g. `localhost:12345/?replicaSet=production`.


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
