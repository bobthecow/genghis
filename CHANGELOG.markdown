## v2.1.7

 * [Fix #41][i41] — Add an "updated but not restarted" info message (Ruby backend).
 * Bump Bootstrap, CodeMirror, Esprima and Hogan.js vendor libraries — faster parsing, highlighting and rendering!
 * Update to latest versions of jQuery and Underscore.js.
 * [Fix #64][i64] — Allow creating a document with an explicit `_id`.
 * [Fix #64][i64] — Show an error message when trying to update an `_id` property.
 * Surface more error notifications when server goes away and other error cases.
 * Handle Backbone weirdness in docs with both `_id` and `id` properties.

[i41]: https://github.com/bobthecow/genghis/issues/41
[i64]: https://github.com/bobthecow/genghis/issues/64


## v2.1.6

 * [Fix #55][i55] — Better heuristic for guessing document creation date from ObjectId.
 * Catch more connection auth errors (Ruby backend).
 * [Fix #16][i16] — Support authenticating directly against a DB for non-admin users.
 * [Fix #61][i61] — Make the welcome masthead vertically responsive.
 * Source code and asset cleanup.

[i55]: https://github.com/bobthecow/genghis/issues/55
[i16]: https://github.com/bobthecow/genghis/issues/16
[i61]: https://github.com/bobthecow/genghis/issues/61


## v2.1.5

 * [Fix #46][i46] — Prevent connection errors from messing up `/servers` response (Ruby backend).
 * [Fix #42][i42] — Handle `connectTimeoutMS` and `ssl` server options (Ruby backend).
 * Cleaner mobile back buttons in WebKit browsers.
 * Disable submit button in paranoid db/collection confirm dialog until name is confirmed.
 * [Fix #56][i56] — Handle crazy characters in collection names (PHP backend).

[i46]: https://github.com/bobthecow/genghis/issues/46
[i42]: https://github.com/bobthecow/genghis/issues/42
[i56]: https://github.com/bobthecow/genghis/issues/56


## v2.1.4

 * [Fix #49][i49] — Add warning messages for `magic_quotes_gpc` and `magic_quotes_runtime`.
 * [Fix #51][i51] — Work around PHP driver issue with non-scalar ids.
 * [Fix #51][i51] — Fix error handling documents with `null` identifiers.
 * Make document headers prettier for non-string and non-ObjectId identifiers.
 * Handle URI decoding and routing for non-string and non-ObjectId identifiers in some browsers.
 * [Fix #44][i44] — Saner connection timeouts.
 * [Fix #50][i50] — Fix "add server" regression in PHP.
 * [Fix #54][i54] — Never daemonize `genghisapp` for Windows users.

[i49]: https://github.com/bobthecow/genghis/issues/49
[i51]: https://github.com/bobthecow/genghis/issues/51
[i51]: https://github.com/bobthecow/genghis/issues/51
[i44]: https://github.com/bobthecow/genghis/issues/44
[i50]: https://github.com/bobthecow/genghis/issues/50
[i54]: https://github.com/bobthecow/genghis/issues/54


## v2.1.3

 * Optical correction for masthead background image aspect.
 * Use Adobe's beautiful Source Code Pro rather than relying on the default system monospace.
 * [Fix #48][i48] — ActiveRecord messes up `DateTime#to_time`.
 * [Fix #52][i52] — MongoDate parsing regression in PHP.

[i48]: https://github.com/bobthecow/genghis/issues/48
[i52]: https://github.com/bobthecow/genghis/issues/52


## v2.1.2

 * Get CI working with Travis, add build status badge to README.
 * Fix Genghis asset URI when mounted on a non-root route (thanks Johan Buts).
 * Swap out masthead bg image for some CSS3 hotness.


## v2.1.1

 * [Fix #38][i38] — JSON rendering weirdness with empty array properties.
 * [Fix #40][i40] — Ruby 1.8.7 regression.

[i38]: https://github.com/bobthecow/genghis/issues/38
[i40]: https://github.com/bobthecow/genghis/issues/40


## v2.1

 * [Fix #28][i28] — Handle BSON BinData properly in documents and ids.
 * [Fix #33][i33] — Remove unexpected collapsed document representation in edit mode.
 * [Fix #32][i32] — No more mixed-content warning when Genghis is running over SSL.
 * [Fix #35][i35] — No more "Add Server" fail in Ruby.
 * Fix — Handle connection auth errors more gracefully.
 * Fix — Query bug when running under PHP 5.4 SAPI CLI server.
 * Add ObjectId timestamps to document headers.
 * Add a sanity check for PHP `date.timezone` settings.
 * Add an asset cachebuster param so nobody has to force refresh after updating.
 * Add a full API spec. Yey tests!
 * Improve consistency between PHP and Ruby APIs. This update brought to you by Full Test Coverage.
 * Refactor PHP API. For the children.
 * Added `CONTRIBUTING.markdown`.

[i28]: https://github.com/bobthecow/genghis/issues/28
[i33]: https://github.com/bobthecow/genghis/issues/33
[i32]: https://github.com/bobthecow/genghis/issues/32
[i35]: https://github.com/bobthecow/genghis/issues/35


## v2.0.2

 * [Fix #29][i29] — Don't throw unexpected unary expression error when parsing negative numbers.
 * [Fix #22][i22] — Handle high badge counts on nav dropdown.
 * [Fix #30][i30] — Weird content clipping when editing really long documents.

[i29]: https://github.com/bobthecow/genghis/issues/29
[i22]: https://github.com/bobthecow/genghis/issues/22
[i30]: https://github.com/bobthecow/genghis/issues/30


## v2.0.1

 * [Fix #26][i26] — Don't double-encode HTML entities in JSON output.

[i26]: https://github.com/bobthecow/genghis/issues/26


## v2.0.0

Brand new features:

 * Genghis doesn't require a webserver! Ghengis.php now runs as a standalone server with the PHP 5.4 CLI SAPI.
 * Genghis doesn't require PHP! Introducing Genghis.rb — Thanks @TylerBrock for doing all the work :)
 * Add super-simple RubyGems installation. `gem install genghisapp` is the new hotness.
 * Add a command line executable / daemon. You're just a `genghisapp` away. How rad is that?
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
    * Speed up the initial page load time.
    * Update code editor. The new one (CodeMirror) is lighter, faster, smaller and a cleaner implementation.
    * Add Cmd+Enter / Ctrl+Enter keyboard shortcut for saving the document being edited.
    * Prevent "new document" modal from closing on background click.
    * Better "keyboard shortcuts" dialog on smaller screens.
    * Require database name confirmation rather than DELETE before removing a db.
    * Collection removal is paranoid as well: it also requires confirmation before removing.
    * Restore spinning states to most sections — a spinner will show rather than displaying incorrect or outdated info.
    * Expando-matic search box. No more squinting or scrolling to see your massive queries.
 * Update Bootstrap (2.1.0), jQuery (1.8.0), Underscore (1.3.3), and Backbone (0.9.2).
 * Use UglifyJS instead of closure compiler to minify JS. It's faster and doesn't require Java :)
 * Mustaches! Now using Hogan.js instead of Underscore templating.
 * Check for updates. You can disable this with a `$GENGHIS_NO_UPDATE_CHECK` environment variable.
 * Add a welcome screen with project link and version info.
 * The README has way more to READ.
 * Spun off Bootstrappy styles for Apprise into their own project. [Check it out!](https://github.com/bobthecow/apprise-bootstrap)
 * All this while reducing the codebase by about 10%. BOOM.

And a handful of bug fixes:

 * [Fix #19][i19] — Only implicitly wrap MongoIds if they're 24 character hex strings.
 * [Fix #20][i20] — Support creating and editing documents with an `attributes` property.
 * Fix output glitches when displaying a brand new document immediately after an existing document.
 * Fix — possible JavaScript error when adding a new collection.
 * Fix — handful of rare (and relatively benign) error messages.
 * Fix — malformed server DSN could prevent servers list from rendering.
 * Fix — rare bug where properties with a specific structure might be mistaken for ObjectIds or Dates.
 * Fix — no longer recreates missing dbs and collections on GET requests.
 * Fix — all sorts of things now 404 if they're missing, rather than rendering an empty page.
 * Fix — assorted issues with running in subdirectories, and under nginx.
 * Improve error handling in a couple of places.

[i19]: https://github.com/bobthecow/genghis/issues/19
[i20]: https://github.com/bobthecow/genghis/issues/20


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

Fix an `E_STRICT` error in asset mime-type guessing.


## v1.0.0

Initial release.
