#Change Log

***

Change log v.0.16.1

**Fix**: Fix the application boilerplate code, fixing a typo in the resulting `config.ru` which resulted in boilerplate code failing to execute. Credit to @namiwang (Nami WANG) for PR #28.

**Update**: Added support for SassC for assets routing.

***

Change log v.0.16.0

**Update**: update gem dependency to utilize `iodine` 0.5.x versions.

***

Change log v.0.15.1

**Fix**: fixed gem dependency to limit the allowed versions of the `iodine` server and protect against changes made to the iodine 0.5.0 pub/sub API.

***

Change log v.0.15.0

**Deprecation**: no more `broadcast`, `unicast`, `multicast` or `write2everyone`... Plezi fully embraced the Pub/Sub design and the [Iodine Extensions to the Rack Websocket Specification Proposal](https://github.com/boazsegev/iodine/blob/master/SPEC-Websocket-Draft.md).

**Feature**: Super powerful Pub/Sub support comes directly from the server layer (iodine), allowing for process cluster Pub/Sub without the need for any Pub/Sub service. Iodine also brings a native Redis connector to easily scale Pub/Sub to multiple machines using a Redis servers.

***

Change log v.0.14.9 - EOL (last 0.14.x release)

**Fix**: Asset Sass rendering will now only save the output to a file in production mode, allowing development mode to hot-load the assets and re-render them when changes occur.

**Feature**: (experimental) The `params` hash will now search for a String alternative, if a Symbol is provided... in other words, the `params#[]` accessor can now be used with both symbols and Strings.

**Changes**: Changed the default Iodine workers to dynamically adjust to Redis scaling availability.

***

Change log v.0.14.7

**Fix**: Tested against Iodine 0.3.0.

***

Change log v.0.14.6

**Fix**: Fixed Plezi client SSL URL scheme for auto-url connections.

***

Change log v.0.14.5

**Fix**: Fixed Plezi client issues related to the code beautifier moving things around.

**Fix**: Fixed a possible issue with unicasting (sending a message to a specific connection).

**Styling**: styling updated and some indentation fixed with the help of Rubocop.

**Misc**: minor refactoring of our message dispatch logic and other minor prevents temporary empty arrays from being created when possible.

***

Change log v.0.14.4

**Fix**: fixed an issue were scaling using `fork` or server workers would break the automatic scaling feature. The issue was caused by the pub/Sub channel ID of the new processes being identical to the origin process. Credit to Vladimir Dementyev (@palkan) for exposing this issue. This did not seem to effect applications that scaled up with independent processes / machines, such as applications that scaled up using "dynos" on Heroku.

***

Change log v.0.14.3

**Dependencies**: added the missing `bundler` and `rack >= 2.0.0` dependencies. Since the bundler gem is often installed by default, it took me a while to realize it was missing from the dependency list. Rack was also easy to miss (being as common).

**Update**: minor tweaks to the cookie jar, allowing a unified `to_s` method and unified `keys`/`values` methods.

**Update**: added an Iodine worker process default to prevent auto-forking unless Redis is used for Websocket scaling. Plezi will default to a single process even though Iodine will default to the number of CPU cores / 2.

**minor fix**: fixed small issues with the app template (old text was updated).

***

Change log v.0.14.2

**Dependencies**: updates to dependency version requirements.

**Performance**: minor performance updates, i.e.: in the router, moved a `case` statement from the live (app is running) stage to the prep (app is initializing) stage and saved the `call` method extraction result for faster middleware mode performance.

***

Change log v.0.14.1

**Update**: update due to Iodine's 0.2.1 version and the deprecation of the `uuid` method (replaced by `conn_id` to minimize collisions).

***

Change log v.0.14.0

Rewrote the whole thing. v. 0.14.0 is a total restart...

...in fact, the changes were so big, we're bumping the developemnt version twice.

You might wonder what changed and what stayed the same. Well... we kept the name.

API changes ahead.

Features were **removed** (I know, features are usually *added*, but Plezi will not become another Sinatra / Rails).

***

Pre 0.14.0

***

Change log v.0.12.22

**Fix**: fix for issue #17 where unicode characters might cause `erb` rendering to fail. Credit to @davidjuin0519 (Juin Chiu) for reporting the issue and helping resolve it.

* **Deprecation notice**:

     v.0.12.22 will probably be the last one for a pure Ruby implementation. Future versions might be limited to Ruby MRI due to C extensions being used.

     Plezi's server, Iodine, was re-written in C, allowing for a smaller memory footprint, more speed and tens of thousands of concurrent connections (using `kqueue` and `epoll`, instead of Ruby's `select` which is limited to 1024 connections).

     Plezi 0.13.x will be using Iodine's C version (0.2.x) by default.

     Since Iodine 0.2.x is Rack complient, Plezi will be able to work with other Rack servers except when using websockets (which will require Iodine due to it's unique websocket support).

     This means that Plezi will be limited to systems that can run the new version of Iodine (Ruby MRI and Unix based systems, such as Linux and Mac OSX).


***

Change log v.0.12.21

**Update**: Auto-Dispatch:

* method whitlisting process was updates. Method arity is now reviewed, so that only methods that accept one or more parameters are recognized as websocket auto-dispatch methods (allowing for Http only methods without throwing exceptions).

* client now adds helper methods for AJAJ (like AJAX, but JSON instead of XML). The javascript client supports the `client.ajaj.emit` to send AJAJ requests and the `client.ajaj.auto=true` to automatically fallback on AJAJ after timeout (unless a custom callback is defined for the specific `emit`).

***

Change log v.0.12.20

**Fix (Client)**: The onopen callback is now called (the issue was related to a typo in the name of the onopen callback).

**Updates**: Auto-Dispatch Client - logging is now easier with the `log_events` property (set to `true` to log all events).

***

Change log v.0.12.19

**Fix**: The Controller's `close` method went missing... It's back. Closing the Websocket/Http connections was never easier with the `close` method available straight from the controller.

**Updates**: Auto-Dispatch updates:

* Updated the Auto-Dispatch API conventions, so that the client and the server conventions are the same (both map events to methods with the same name (without the `on` prefix) and map unknown events to the `unknown` callback).

* Auto-Dispatch callbacks can return a Hash as well as a String when the return value is meant to be written to the websockets.

* Auto-Dispatch sends an `_ack_` event whenever an event contains an event ID (`_EID_`) property.

* Auto-Dispatch client's `emit` supports timeout callbacks (for easier fallback to AJAX).

* A `:client` route allows serving Auto-Dispatch's updated client rather than the original client provided in the template. This allows the application to serve the updated client when Plezi is updated.

***

Change log v.0.12.18

**Feature**: Auto-dispatching allows, when enabled, to automatically map JSON websocket messages to controller methods, according to their `event` property. Also, when using the auto-dispatch, Plezi will automatically send the returned value for dispatch methods that return a String (just like when using Http). This means that unifying Websocket and RESTful APIs is now easier than ever.

**Change**: the `json` format is now automatically assumed when a websocket connection is established - allowing `render` calls to automatically prefer `json` format templates.

**Change**: The warning shown when using the Identity API without Redis will now only appear once, instead of repeating itself.

***

Change log v.0.12.17

**Fix**: error template format would (and should) fallback to 'html' if the originally requested format (i.e. 'json') was missing. An issue with nested template rendering (when the error template would call `render` to render a partial or other template) caused the fallback to revert to the original (missing) format when searching for the nested template. This issue is now fixed, by instructing ErrorCtrl to set the global format rather than the local one.

**Update**: when the `ENV["ENV"]` or `ENV["ENV"]` are set to `"production"`, the SASS asset render engine will be set to compress the css (minify), for smaller transfers.

***

Change log v.0.12.16

**Fix**: fixed an issue with the `#url_for` method, which couldn't be used as a class method.

**Update**: a new and improved `#url_for` method (both for Controller class and instance). The instance class will attempt to preserve any re-write route paramerets, such as the `:locale` and `:format` parameters. The class method will do the same IF it receives the exiting request's `params` Hash as a second argument. `#url_for` is always a "best guess" and should be accurate for when guessing isn't super difficult.

***

Change log v.0.12.15

**Fix**: fixed the Redis connection, which was failing after DB selection support was added.

**Fix**: Iodine update fixes an issue where unicasting might fail when connection is still very new.

**Fixe**: fixed an issue with the Identity API where Redis emulation would loose the historic messages due to unicasting failure for the unregistered (super new) connection.

***

Change log v.0.12.14

**Update**: `Controller#redirect_to` will now attempt to guess the URL using `url_for`, unless the URL given is a String. It also leverages the new `redirect_to` Iodine::Response method, allowing you to set the FUTURE response's status_code.

**Update**: Error page rendering is now performed within a controller class called `ErrorCtrl`. This means that the error templates have acess to all the helper methods and properties of a controller, including `render`, `redirect_to`, etc'.

***

Change log v.0.12.13

**Fix**: fixed an error in te rendering engine, where the default :format was an empty String instead of 'html'.

**Update**: if `params[:format]` exists, the `params[:format]` will be used to set the format of the template to be rendered (i.e., if `params[:format] == 'json'`, Plezi will look for `template_name.json.erb` instead of `template_name.html.erb`)

***

Change log v.0.12.12

**Update**: Redis will now connect to the selected database if the database is set in the `ENV['PL_REDIS_URL']`.

**Security**: Redis session local storage will now expire after 24 hours from last visit.

**Compatibility**: minor fixes and changes in preperation for Ruby 2.3.0. Updated the Session object API to match Iodine (added the `#refresh` method as an alias for `#to_h`).

**Change**: changed the `Controller#render` method to accept `:format` instead of `:type`, for more clarity. `:type` is still supported for the 0.12.0 version line.

***

Change log v.0.12.11

**Update/Fix**: dedicated methods for Controllers shouldn't be case sensitive. i.e. `/humans` and `/huMans/` should lead to the same route, IF that route is a method called `:humans` within a Controller class.

***

Change log v.0.12.10

**Fix**: removed a debug message introduced when fixing the renderer for version 0.12.9.

**Update**: Plezi will respect changes to the response status when rendering error massges (i.e. 404 or 500 error templates), allowing us to change the response status to 302 (redirect) and set a location header using (response['location'] = '/')... This allows for a more gracefull error 500 handling.

**Update**: updated gemspecs to link to [plezi.io](http://www.plezi.io).

***

Change log v.0.12.9

**Fix**: Layered rendering (when using layout) will now fail if the inner layer (the actual page) fails to render - directing the user to the 404 error page instead of displaying the layout with no data.

**Update**: `render` will now accept either a String (for a template name in the root of the template folder), a Symbol (the `_` sign will be used to delimit folders, if needed) or an Array of Strings (delimiting folders up to the file's base name).

***

Change log v.0.12.8

**Fix**: Sass cacheing now works as expected, so that repeated calls to the SASS renderer are loaded from the cache without failing.

***

Change log v.0.12.7

**Identity API**: Identity API now allows you to set a higher number of allowable concurrent connections per identity, rather than the original single connection limit. Also, allows limited functionality when Redis isn't defined (registration lifetime is limited to the process lifetime and scaling will not work without Redis).

**Template**: minor template updates.

**Fix**: fixed an issue with data and (file) sending, introduced when extending the `send_data` method to allow for big File objects (buffering them through the connection instead of loading them to the memory).

***

Change log v.0.12.6

**Template Fix**: Heroku would load the `environment.rb` file while deploying the application. This would cause Plezi's server to kick in and hang deployment. This issue was circumvented by renaming the `environment.rb` file to `initialize.rb`. Thanks to Adrian Gomez for exposing the issue (issue#9)

***

Change log v.0.12.5

**Fix**: Placebo's older Rack recognition required that Rack be required within the gemfile of the application. This is no longer the case. Now `start_placebo` can also be used in a non-Rack environment (i.e. when disabling the server using: `Plezi.protocol = :placebo`). This allows writing Plezi based "worker" scripts that aren't web servers but can send and receive messages from the main application.

***

Change log v.0.12.4

**Fix**: unicasting should be type agnostic.

**Update**: When using `Plezi.start_placebo`. The Placebo class will now allways have the websocket broadcasting capabilities, even if Placebo isn't initializes (if Plezi is runing) - allowing you to call `Plezi.start_placebo MyPlacebo` and `MyPlacebo.broadcast` from within the server application and having only the Placebo application react.

***

Change log v.0.12.3

**Feature**: (requires Redis) Identity API is here (read more on the [Websockets guide](./websockets.md))

* Websocket Identity API allows you to link a websocket connection with a unique "identity" (i.e., `user.id` or even `session.id`).

     This is called "registering", as the identity "registers" and is henceforth recognized.

* Notifications sent to the identidy will persist until the identity's "lifetime" expires.

     The default "lifetime" is 7 days, meaning an "Identity" message queue will survive for 7 days since the last time the Identity was "registered". This lifetime can be set for each identity during registration.

* This allows you to send notifications that will "wait" until a user or visitor reconnects and registers the new connection under their Identity.

* This is an alternative to persistant storage, where either visitors messages that aren't read within a certain timespan

**Fix**: the Placebo API was fixed to correspond with the changes in Iodine's API.

**Fix**: fixed an issue where Placebo's on_close would through an exception.

**Fix**: Some websocket API methods were exposed to the Http router as paths (causing internal 500 errors, as they couldn't be invoked by the router). These methods are now `protected` and by doing so the Http router ignores them. Also, `has_exposed_method?` was reviewed in a way that should help avoid future occurrences of these issues.

**Fix**: fixed an issue where AJAX parameters weren't form-decoded (`'%20'` wasn't replaced with `' '` etc'). Now the parameters are decoded as expected.

***

Change log v.0.12.2

**Update**: Plezi now leverages Iodine's support for a File response body, allowing for a smaller memory footpring when sending large files.

**Fix**: fixed an issue where host aliases wouldn't initiate, causing host initiation to fail, due to a typo in the HTTPRouter.

**Fix**: fixed an issue with the plezi OAuth2 extention, which caused OAuth to fail when encoding URL data before initiating the OAuth process. OAuth2 should now work as expected. Plezi's OAuth2 has built-in support for both Google and Facebook authentication, as well as an API that allows implemnting more OAuth2 complient services (i.e. GitHub).

***

Change log v.0.12.1

**Fix**: fixed an issue with the app template, where a typo (an extra comma sign ',') caused the `host` command to fail.

**API**: The `host` method can now be used without a host name (only passing a Hash), automatically falling back to the default host.

**Update**: Plezi version number now displays as the server starts running.

***

Change log v.0.12.0 - API changes (throwing out dead code and many more changes)

**Feature** The `Controller.failed_unicast(target, method, arguments_array)` callback is here, allowing you to write a class level callback that will be called if `unicast` fails to find it's target (i.e. if the Websocket connection was already closed or the hosting server shutdown).

\* the lack of this callback being called does NOT imply that the unicast was processed without errors, it's only called if the target itself wasn't found (the connection already recognized as closed). Errors can occure within the method originally called by `unicast` when the target was found but the connection was dropped while processing was underway. The `failed_unicast` callback, together with error handling in the original method (i.e. `response << "message"` returning `nil`) should cover any reasonable scenario.

**Minor**: updated asset pipeline performance; API for the `Plezi.route` methods now auto-creates an empty listening service (no assets, no templates, no public folder...) if one is missing.

**Fix**: The '/*' is automatically appended to the Re-Write routes, so now writing re-write routes is easier and more intuitive.

**Fix**: fixed issue with the Placebo API that could cause CPU cycles (IO.select would return immediately) and an issue where the on_close callback wouldn't be called.

**Big Change**: Discarded GReactor and GRHttp in favor of [Iodine](https://github.com/boazsegev/iodine) - an Object Oriented IO Reactor for writing network services, which includes an optional Http, Websocket and even an experimental Http/2 server (all to show off it's the ability to change protocols mid-stream).

**API changes**: Along with moving to a single server Iodine module, `listen` had been deprecated in favor of a simpler API, as well as many other helpers that were acting as dead-code.

**Fix**: Along with switching to Iodine, certain server related issues were fixed (such as String and Symbol cookies with unexpected behavior).

***

Change log v.0.11.2

**Fix**: Fixed an issue where the Session object wouldn't be available for websocket connections after the handshake was complete.

***

Change log v.0.11.1

**Feature**: (undocumented) Rendering and Asset extentions! Now, Rendering and Asset pipeline can be extended to allow for more rendering and asset engines. This is yet undocumented and somewhat experimental, but the API in this regard will be stable for all `~>= 0.11.1` versions.

**Update**: Simpler asset rendering workflow, rewritten while adding extention support.

**Fix**: Fixed an issue where the MimeTypeHelper wouldn't recognize a file's extention (due to the '.' in the file's extention string).

***

Change log v.0.11.0

**Update**: Requires GRHttp server and GReactor version 0.1.0 or above, adjusted to the updated API.

**Update**: Better pinging and timout support courtesy of the updated GRHttp server.

**Update**: The default number of threads is now 30. It seems that once we move beyond 1 thread (which is also supported), the added threads are adding more security against blocking code without effecting performance as much. It is expected that advanced users will consider moving away from multi-threading to muli-processing while avoiding blocking code. All these options are supported by Plezi, GRHttp and GReactor.

**Fix**: Fixed an issue where requests for folders within the assets folder (folder indexing) would fail with an internal error message (error 500) instead of a not found message (error 404).

**Fix**: fixed an issue that caused the static file service to fail when using the preferred `:public` vs. the older `:root` option used to set the public folder's path.

**Minor**: minor adjustments and improvements, such as: auto-setting the `content-type` header when using `render`.

***

Change log v.0.10.17

**Update**: Requires a newer version of the GRHttp server and GReactor, building on it's WSClient and HTTP decoding improvements.

**Security**: Redis connection broadcasting now enforces `safe_load`, so that even id the Redis server and it's data are compromized, it should not lead to foreign code execution. Please note that this will enforce limits on session data as well as on websocket broadcasting.

**Sessions**: Sessions are now avoided unless explicitly created or unless a websocket connection is established. The reason being that unless Redis is defined, sessions are stored in-memory and end up requiring a lot of space. File storage might be considered for future releases.

***

Change log v.0.10.16

**Fix**: Requires a newer version of the GRHttp server, which fixs an issue with Firefox's websocket implementation.

**New Feature**: Persistent and synchronized Session data(!) using Redis (if supplied) with a fallback to temporary memory storage. Session lifetime is 5 days.

***

Change log v.0.10.15

**Fix**: Fixed the autostart feature that was diabled due to a changed in the GRHttp server's code for Rack support.

***

Change log v.0.10.14

**Deprecation notice**: Setting the public root folder is now done using the option `public` instead of the option `root`.

**Fix**: Yard documentation failed due to duplicate entries. The issue was fixed.

**Update**: removed duplicate code and updated the server for better Rack support.

***

Change log v.0.10.13

**Fix**: The Placebo API was tested and an issue with the new Placebo class broadcast method was fixed.

**Update**: Websocket code refactoring unified Placebo and Controller's API and bahavior.

**Update**: Unicasting performance using Redis was improved by creating a different Redis channel for each process, so that the unicast is only sent to the process containing the receiver.

this should mean that apps using unicasting can scale freely while apps using broadcasting need to address boradcasting considirations (broadcasting causes ALL the websocket connections - in ALL processes - to answer a broadcast, which raises scaling considirations).

***

Change log v.0.10.12

**Placebo API**: The Placebo API was reviews and revamped slightly, to allow you a better experience and better error feedback.

**Template**: The template's error pages were restyled with Plezi's new color scheme.

***

Change log v.0.10.12

**BIG Feature**: Run both your existing Rack app and plezi on he same GRHttp server - augment your app with all of Plezi's amasing features (two frameworks in one).

**Updates** updates to the mini template, the testing, the core API code and many more minor updates.

**API published**: Most of the private API in the Plezi::Base::DSL module was just made public (moving the methods to the main Plezi namespace). Your app should work as before unless you used private method calls instead of Plezi's published API.

***

Change log v.0.10.11

**Feature**: added the mini-app template, for quick websocket oriented apps that are meant to be attached to other frameworks (use `$ plezi mini appname` or `$ plezi m appname`).

**Feature**: allow Regexp hosts in the `listen` and `host` methods.

**Fix**: An error in the cache system was introduced when performing slight performance enhancements (two variable names were switched). The issue is now fixed.

**Fix**: Correctly handle multiple `listen` calls with the same port number.

***

Change log v.0.10.10

**Fix**: Autopinging wasn't senf doe to a typo (`unless` instead of `if`).. this is now fixed. Autopinging will keep your Websocket connections alive.

***

Change log v.0.10.9

**Minor**: minor update to the cache system, might improve performance somewhat and might fix rare issues related to some binary files. Updated GRHttp server version required.

**Fix**: fixed an issue with Placebo listeners where they might be thrown from the IO stack and thereby stop listening ()or, alternatively, consume CPU) . This issue was caused by GReactor's 'BasicIO#clear?' code enforcing two-way connectivity.

***

Change log v.0.10.8

**Fix**: Fixed an issue with the new websocket upgrade handler. It is unclear how come the issue did not show up during the testing.

\* (All the changes in version 0.10.7 still apply)

***

Change log v.0.10.7 (yanked)

**Fix**: Forces the use of a better version of the GRHttp server, now as fully tested as I could manage. This fixes an issue where the lasy byte on a Websocket message might have been corrupt.

**Fix**: fixed an issue where websocket connections would be quietly established (messages would be ignored) even though they should have been declined.

**Update**: Better support for intigration of Plezi with other frameworks, using `Plezi.start_async` and `Plezi.start_placebo` to get all the benifits of Plezi without distrupting the host framework.

**Update**: added the multicasting feature - allows you to send a message to ALL the websocket connections that defined a method to handle the message - use `multicast :method_name, arg1, arg2, arg3...`.

**Update**: Added the Placebo API to support websocket broadcasting on normal classes - allows for super-easy framework integration with other Ruby frameworks such as Rails and Sinatra.

***

Change log v.0.10.6

**Performance Boost**: updated the GRHttp server version, to leverage the new Websocket engine, which offers a significant performance boost and allows for larger data to be transmitted over the websocket connection (tested with more than 250MB of data).

***

Change log v.0.10.5

**Fix**: updated the server version to fix socket status code issues on Debian OS (resolve socket disconnection issues).

***

Change log v.0.10.3

**Update**: updated the starting process, so that Plezi's engine (based on GReactor) could be started and restarted if needed.

**Fix**: the startup process ignored the `max_thread` settings. This is now fixed.

***

Change log v.0.10.2

**Fix**: fixed an issue where the Redis connection couldn't broadcast due to limited acess to the controller's methods.

**Fix**: fixed an issue with the server's UUID being set before the GReactor's forking, thereby disabling Redis communications between processed over te same machine.

***

Change log v.0.10.1

**Fix**: fixed an issue where the new Controller's inner router might route to RESTful methods that weren't defined (:show, :save, etc').

**fix**: fixed an issue with the new Controller's inner router might not reset it's cache when methods are added to the controller after the service has begun.

***

Change log v.0.10.0

**Major Revesion**:

- The Plezi IO Reactor was extracted to an external gem called [GReactor](https://github.com/boazsegev/GReactor) and optimized.
- The Plezi HTTP and Websocket Server was extracted to an external gem called [GRHttp](https://github.com/boazsegev/GRHttp) and optimized.
- The Websocket API, implementation and engine were all revised. CAREFUL: **Old Websocket API deprecated**.

**WebSocket API revisions**:

- The `#on_connect` callback had been renamed to `#on_open`, for clarity and to conform with the Javascript API.
- The `#on_disconnect` callback had been renamed to `#on_close`, for clarity and to conform with the Javascript API.
- The `#collect` method had been deprecated due to scaling limitations it had imposed.
- The `#broadcast` and `Controller.broadcast` methods had been altered and would no longer accept an optional block of code.
- The Redis support had been altered and the redis connection object (if exists) is now available using `Plezi.redis_connection` instead of the older Controller method.

**Settings API revisions**:

- The settings API had been moved to the namespace `Plezi::Settings`.

***

Change log v.0.9.2

**Some API deprecation notice**

V.0.10.0 will be a major revision. It will _also_ change the Websocket API so that it conforms to the Javascript API, making it clearer.

Also, V. 0.10.0 will utilize the [GReactor](https://github.com/boazsegev/GReactor) IO reactor and the [GRHttp](https://github.com/boazsegev/GRHttp) HTTP and Websocket server gems. Both are native Ruby, so no C or Java extentions should be introduced.

This means that asynchronous tasking will now be handled by GReactor's API.

Make sure to test your app before upgrading to the 0.10.0 version.

***

Change log v.0.9.1

**changed**: Template Gemfile now enforces the Plezi version. Also, the template's demo page now demonstrates WebSocket broadcasting.

Minor updates.

***

Change log v.0.9.0

**changes** (might break code):

- The error code file handling logic has been changed.

   Plezi will no longer look the 404 and 505 files in the _public_ `:root` location. Instead the files should be placed at the **templates** folder if defined or at the app's root folder (_if templates folder isn't set_).

   Also, error code files should now correctly specify that they are html templates - for example, the older '404.erb' should be renamed as '404.html.erb'

   To update your application **please rename the error code files and move them to the app template's folder** (`appname/app/views`).

- Updated the template's welcome page and database configuration support. Existing applications shouldn't be effected.


**feature**: auto-pinging can now be customized for different hosting-server timeouts and it can also be disabled using the `Plezi.ping_interval` setter and getter.

**feature**: The Plezi framework can now impose limits on Websocket message sizes (even messages split across a number of frames) by using the `Plezi.ws_message_size_limit=` method.

**fix**: Outgoing Websocket messages would break for messages over 32KB (and sometimes over 16KB). This was caused by an issue in the frame splitting algorithm which is now resolved.

***

Change log v.0.8.7

**minor performance**: streamlined the ping/pong Websocket process.

**fix**: fixed an issue with the auto-utilization of the I18n gem, where one request could set the locale for all subsequent requests that are processed by the same thread.

**deprecation warning**: The current code for default error pages will be changed in version 0.9.0, so that default error pages will follow a different naming convention and would be searched for in a different location. The updated design will be part of the updated `plezi` helper script. Please review your code before upgrading to the 0.9.0 version.

***

Change log v.0.8.6

**fix**: fixed an issue with the plezi helper script that prevented the script from starting the Plezi app or Plezi console.

**feature**: Unicasting allows you to target a specific Websocket connection using a unique identifier (UUID). Use the controllers `#unicast(target_uuid, mathod_name, *args) to target a specific client. Automatically uses Radis, if Radis is set up, to unicast across processes.

***

Change log v.0.8.5

**feature**: Plezi now includes a very simple Websocket Client (no support for cookies). It's used for testing the integrity of the Plezi Framework and could be used to test the Plezi apps.

**feature**: the Controller can now create easy urls for it's own paths, using the #url_for method. Works wonderfuly for simple routes (routes such as: '/path/to/restful/controller/(:id)/(:other)/(:simple)/(:options)').

**update**: better ActiveRecord support now adds AC rake tasks.

***

Change log v.0.8.4

**core routing changes**: moved the Controller's routing cache out of the global cahce store. This might provide a very slight performance increase.

**feature**: a new OAuth2 controller offers an easy support for OAuth2 login services such as facebook and google. to use this feature, require 'plezi/oauth'.

**fix**: fixed an issue where RESTful requests to `new` would be mistakenly routed to the `save` method.

**testing**: some basic testing for the RESTful Plezi framework has been implemented. Please notice that the tests WILL run the Plezi server on ports 3000 (for http) and 3030 (for https) during the test. The test will run Net::HTTP requests against the Plezi server.

***

Change log v.0.8.3

**Auto-ping feature**: WebSocket connections now automatically send a `ping` every ~45 seconds (approximately) before the websocket's connection would timeout. This auto-ping will keep the connection alive even if no data is exchanged.

**Minor performance updates**: Disconnection workflow was slightly optimized. Also, medium and small websocket messages (less than 131,072 UTF-8 characters) should be faster to handle.

***

Change log v.0.8.2

**fix**: fixed an issue where websocket clients that didn't send the `sec-websocket-extensions` header would cause an exception to be raised and their connections would be refused.

***

Change log v.0.8.1

**fix**: fixed an issue that silently prevented SSL connections from working properly. SSL was mistakenly disabled and normal connections were attempted. This issue should have cause a no-service situation, as attempting to connect using SSL to a non-SSL connection would fail.

**fix**: fixed Websocket connections. An extra EOL marker at the end of the HTTP upgrade responce caused websockets to fail. The excess new line marker was removed.

***

Change log v.0.8.0

**Refactoring**: core code was refractored. Older code __might__ not work.

Most apps should be able to upgrade with no issues.

**Rack support might be broken** (again)... Rack support has changed and it's probably boken. It might come back, and it might not - it was originally only for testing. Plezi is a pure Ruby Rack alternative. It runs it's own web server (since, unlike Rack, the response objects are part of the server and this allows for a whole lot of magic and concurrency to happen). I hadn't had the time to test the Rack support under the new code.

**Events API changes**: the method Plezi.push_event has been removed. Plezi.run_async and Plezi.callback are the preffered methods to be used for event handling.

**Timers API changes**: The API for timed events has changed. It is now both more streamlined and allows setting a repeat limit for events that repeat themselves (i.e. schedule an event to repeat every 60 seconds and limit it to perform only 5 times).

**fix**: Fixed an issue with attachments. Attachments were mistakenly enforced to comply with UTF-8 encoding, preventing binary attachments from successfully uploading.

unstable API warning - **Effects only advanced users**: v.0.8.0 is a time for change. The regular API (the DSL and some Plezi helpers) will remain stable (and if it breaks, we will fix it), but the core API - which some users might have used even though they probably shouldn't have - will change.

***

Change log v.0.7.7

**fix**: fixed a header issue in the HTTPResponse that prevented websocket connections.

**deprecation notice**:

v.0.8.0 will consist of many changes that will also influence the API. The 0.8.0 version will mark the begining of some major rewrites, so that the code will be even easier to maintain.

If your code depends on Timers and other advanced API, please review your code before updating to the 0.8.0 version.

***

Change log v.0.7.6

**performance**: minor performance improvements.

**API**: minor additions to the Plezi API, such as the `Plezi.run_async` method.

**fix**: Some HTTP refinements. for example, keep-alive headers are now enforced for all connections (not standard, but better performance). Patch requests are now pipelined to the controller's RESTful API.

***

Change log v.0.7.5

**fix**: fixed an issue where form data might not be decoded correctly, resulting in remainin '+' signs that weren't properly converted to spaces.

***

Change log v.0.7.4

**change/fix**: it seems that behavior is more predictable when routes macgic parameters are non-persistent between routes. The old behavior (persistent parameters) is now limited to re-write routes.

**fix**: an error was introduced when using paramd\[:id] with a Fixnum. This was caused by the router attempting to search for a method by that name before using the parameter as an :id. This is now fixed by temporarily converting the Fixnum to a string before the required converstion to a symbol.

**experimental feature**: added the method `def_special_method`, which can be used in controller classes to create specially named paths, defying Ruby naming restrictions, such as: "play-now", "text.me" etc'. This is an EXPERIMENTAL feature which might be limited in future releases (specifically limited to names without dots '.', in case of future formatting support).

***

Change log v.0.7.3

**major fix**: Fixed a conflict in the controller namespaces and caching system, which caused routing and Redis connection errors. The errors were resolved by moving the caching to the Framework's global caching system.

**fix + feature**: It is now possible to dynamically add or remove routes from existing controllers. As you know, Plezi controllers behave like "smart folders" and their public methods are automatically published as routes. But - That routing table is cached. Now the cache is automatically reset whenever a method is added or removed from the controller, or, you can reset the controller's routing cache by calling the controller class method #reset_routing_cache. This allows you to dynamically add or remove routes from existing controllers.

**fix**: fixed as issue with utf-8 data in the cookie and flash data, where utf-8 data wasn't encoded properly as an ASCII string before being sent in the HTTP headers.

**fix**: fixed an error with catch-all and re-write routes that caused some routes to fail or that rewrote routes that should not have been re-written. This bug was introduces when re-write routes conflicted with similar actual routes (such as '/en' conflicting with '/entance', the 'en' would be removed although that was not the intention).

**fix**: fixed the raketasks... which do nothing just yet.

**fix**: fixed the 404 error for the slim template. It now has access to the request object, so that it is possible to dynamically show the requested path or other parameters and cookies.

**fix**: fixed the timing of the first service start up logging to log only once services actually start.

***

Change log v.0.7.2

**fix**: fixed the template's Proc file for Heroku integration. There was a issue due to the main app file name convention change (the app file no longer has the .rb extention, and now the Proc file correctly reflects that change).

**fix**: recognition of floats caused conversion errors for stings that are nomeric with multiple dots (i.e. 1.1.2015). Also, float recognition was discovered to be non-reversable (i.e `"1.10".to_f.to_s #==> "1.1"`). For this reason, float recognition has been removed. Fixnum recognition is still active.

***

Change log v.0.7.1 - OLDER CODE MIGHT BREAK!

**feature**: ruby objects (Integers, Floats, true & false) are now automatically converted from strings to Ruby objects (notice that 'true' and 'false' ARE case sensative, to preserve the value in case of a #to_s method call)

**change**: Request parameter names are now converted to numbers, if they are recognized as numbers (i.e. use `params[:list][0][:name]` rather than `params[:list]['0'.to_sym][:name]`)

**Logo**: we're still working on a nice logo... but we have a lot on our todo list. so we put a temporary one in.

***

Change log v.0.7.0

Welcome our new name, Plezi.

Plezi means "Fun" in Heitian and we are very happy to have this new bright and shiny name.

We are growing up to into a happier and more mature framework.

***

Change log v.0.6.23

**name change notice**: Due to some people being offended by the framework's name, the name will be deprecated in favor of a more generic name. I apologize if anyone felt offended by the name, that was never my intention. The new name we are considering is Plezi, meaning 'fun' in Heitian.

**major fix**: A serious bug was discovered where RESTful routes would not execute due to a security update which blocked the HTTP router from knowing these methods were available. This was fixed by giving the router access to more information about the controller.

***

Change log v.0.6.22

**new feature**: HTTP streaming is here and easier then ever. Simply call `response.start_http_streaming` from your controler, set the asynchronous work using Plezi Events (or timers) and return `true` from your controller. This feature requires that the response will be manually closed using `response.finish` once the work is done.

**misc**: App generator (`plezi` command) now protects against invalid app names by auto-correcting the name, replacing any invalid characters with an underscore.

**misc**: updated the gemspec file and project tag-line for a better gem description.

**fix**: fixed an issue where chunked data wasn't encoded correctly. This issue only effected the use of HTTP streaming, which wasn't a formal nor documented feature before this release.

***

Change log v.0.6.21

**fix**: fixed a bug in the broadcast/collect system, where closed connections would still react to broadcasts until garbage collected. fixed the issue by reinforcing the on_disconnect for the controllers child class (the one inheriting the controller and injecting the Plezi magic into it).

**fix**: fixed a bug where some websocket connections might fail without a Redis server. fixed issue by making sure a successful #pre_connect method will return `true`.

***

Change log v.0.6.20

**feature**: Redis broadcasts (automated)! once a Redis server is defined for Plezi, #broadcast will automatically use Redis (limitations apply due to data-types, memory sharing, callback limitations etc')!

To change Plezi's #broadcast method to use Redis, set the Redix server url using the `ENV['PL_REDIS_URL']` - i.e. `ENV['PL_REDIS_URL'] = ENV['REDISCLOUD_URL']` or `ENV['PL_REDIS_URL'] = "redis://username:password@my.host:6379"`

**template**: a `redis_config.rb` file was added to the template. It has some demo code and explanations about automating Redis in Plezi... it's as easy as uncommenting one line and writing in the Redis server's URL :)

***

Change log v.0.6.19

**performance/feature**: assets rendering was re-written and should work faster - except for Sass which now reviews all dependencies for updates (a new feature instead of performance boost).

**fix**: fixed an issue where the router would split a Regexp within a RESTful route (i.e. `'route :simple_math{[\d\+\-\*\/]}'`) even when the special '/' charecter was escaped.

**fix/change**: fixed an issue where dots ('.') would act as slashes ('/') in path naming recognition, deviding parameters names which contained dots into a number of path segments (instead of one).

***

Change log v.0.6.18 (yanked)

**BROKEN**:

trying to fix the routing system broke the code. Apologies to anyone who updated. We have yanked this version and are working on a better fix.

***

Change log v.0.6.17

**fix**: (Controller methods injection issue) fixed an issue where JRuby treats the `include` method as private. Now the `include` is wrapped within an instance_eval block which allows private method calls.

**fix**: connection timeout could have been continuously reset on some connections. this issue was fixed by ensuring connection timeout is reset only when data was actually read.

**fix**: log recognition of client ip through proxy (X-Forwarded-For header)

**change**: WARNING - Might effect code: empty files and data in multi-part forms are ignored (nil value and no key in the params hash, rather then an empty value).

**core code updates**: the core code for the sockets and protocol classes was restructured, allowing more control to the protocol classes (preparing for possible changes in the protocol parsing engine, especially for websockets which might be updated to use the 'websocket' gem in order to support more websocket protocols).

***

Change log v.0.6.16

**feature**: Slim template rendering is now part of the native render helper method (including template caching). In my testing, it's speed was much better then the Haml (especially for multi-threaded repeated concurrent requests, which can be the norm).

**fix?**: trying to fix a mysterious bug in the cache system. It seems okay now (had to do with the mtime for files).

**template**: template updates, including changes in application file name, welcome page and database configuration files.

**performance**: minor framework engine tweeks (reducing the price of wrapping responses within controllers).

**readability**: changed code structure to help readability and cooperation.

**fix**: fixed some issues with socket timeouts.

**feature**: timed events - It is now possible to add timed events to run once or every x seconds. timed events run only when server runs an idle cycle (during which it also accepts new connections) and timing isn't exact.

***

Change log v.0.6.15

**feature**: the new Websocket class `broadcast` and `collect` allows broadcasting and colletion of data between different connection types!

**fix**: error handling for missing methods was now excessive and informed of intentionally missing routes as well actual errors - fixed by correcting the if statement (hopefuly for the final time).

***

Change log v.0.6.14

**performance**: the HTTPResponse engine has been tweeked a bit to improve the performance (~8% improvement for a simple 'Hello World').

**template**: template code is now updated to seperate the service logic (in the `environment.rb`)  from the routing logic (in the new `routes.rb`).

**fix**: `render` with a String template name (unlike symbol template names) now correctly relates to the template folder path rather then the application's root folder path.

**fix**: fixed minor issue where errors would not be reported if caused by a no method error.

**update**: updated the redirect_to to allow easier redirection to index (using an empty string).

***

Change log v.0.6.13

**minor**: added a `flush` method to the HTTPResponse and WSResponse - to make sure all the data is sent before the code continues (blocks the thread).

**minor**: documentation fixes and updates.

**fix?**: removed a possible risk for an issue with WebSocket Controllers.

***

Change log v.0.6.12

Mainly small engine and performance tweeks here and there.

***

Change log v.0.6.11

**fix**: the long awaited fix for ssl services is here. notice that most of the time, SSL should be handled by the proxy calling on Plezi and SSL services should be disabled.

**performance**: performance improvements and a better, greener Plezi (less CPU load while idling). performance improvements are even more noticable on JRuby... although, if you're looking for the fastest 'hello world', maybe this is not a perfect fit.

***

Change log v.0.6.10

**features**: more websocket controller features for operating on websocket siblings. see the ControllerMagic documentation for more details.

**fix**: fixed the force exit. exception handling prevented forced exit from taking place. it was fixed by creating an allowance for the force exit exception to pass through.

**fix**: `broadcast` and `collect` are now limited to active websocket connections (closed connections and active HTTP connections will be ignored).

***

Change log v.0.6.9

**fix**: redirect_to could would fail when a custom port (such as 3000) was in use. the issue was cause by a parsing error in the port recognition (the ':' was passed on to the port variable under some circumstances). This was fixed by correction the parser.

**update**: now routes can assign array and hash parameter - i.e. '/posts/(:id)/(:user[name])/(:user[email])/(:response)/(:args[])/(:args[])/(:args[])'

**update**: tweeks to the socket event engine, to allow for more concurrent connections.

**fix**: RESTful routing to `new` and `index` had issues.

**fix**: WebSockets - sending data through multiple connections could cause data corruption. this is now fixed by duplicating the data before framing it.


***

Change log v.0.6.8

**fix**: fixed an issue where WebSocket connections would get disconnected after sending data (an update in v. 0.6.6 introduced a bug that caused connections to close once data was sent).

**updates**: quick web app template updates. now you get better code when you run `$ plezi new myapp`...

***

Change log v.0.6.7

**fix**: fixed an issue where rendering (Haml/ERB) would fail if I18n was defined, but no locale was specified in render or in request parameters.

***

Change log v.0.6.6

**feature**: Both rendering of ERB and Haml moved into the magic controller - now, both ERB and Haml rendering is as easy as can be. (Haml's performance is still slow for concurrent connections. ERB seems almost 4 times faster when under stress).

**change**: rendered assets are no longer saved to disk by defaulte. use `listen ... save_assets: true` to save rendered assets to the public folder.

**fix**: fixed an issue where the socket data wasn't read on systems that refues to report the unread buffer size (i.e. Heroku). Now, reading wil be attempted without any regards to the reported unread buffer.
***

Change log v.0.6.5

**engine**: Plezi idling engine tweeks. As of yet, Plezi never really sleeps... (new events can be created by either existing events, existing connections or new connections, so IO.select cannot be used)... idle time costs CPU cycles which were as minimized as possible for now.

**feature**: very basic Rack support is back (brought back mainly for testing)... BUT:

Rack code and Plezi code are NOT fully compatible. for example: Rack's parameters aren't always fully decoded. Also, Rack's file upload contains tmporary files, where Plezi's request object contains the binary data in a binary String object.

Also, Rack does NOT support native WebSocket Controllers (you will need middle ware for that).

***

Change log v.0.6.4

**fix/performance**: faster websocket parsing... finaly :-)

**fix**: Websocket close signal now correctly disconnects socket.

**fix**: Trap (^C signal) might fail if main thread was hanging. Fixed by putting main thread to sleep and waking it on signal.

***

Change log v.0.6.3

**fix**: There was a bug transcoding utf-8 data (non ASCII) in the websocket response. WebSockets now sends unicode and UTF-8 text correctly.

**fix**: special routing fixed for POST requests. v.0.6.1 brought changes to the router, so that non restful routes were refused except for GET requets. now the expected behaviour of params[:id] => :method (if :method exists) is restored also for POST and DELETE.

***

Change log v.0.6.2

**fix**: v.0.6.1 broke the WebSockets. WebSockets are back.

***

Change log v.0.6.1

**performance** - Caching and other tweeks to help performance. noticable improvements for controller routes, Haml (404.haml, 500.haml and framework template code), assets (Sass, Scss, Coffee-Script).

**known-issues** - (rare - occures only when files are misplaced) non cachable files aren't served from the assets folder unless file system is writable (Heroku is an example where this issue of misplaced files might occure).

***

Change log v.0.6.0 - **WebSockets are here!**

This version is a major re-write for the whole plezi framework.

**RACK SUPPORT DROPPED!**

Rack support is dropped in favor of a native server that allowa protocol switching mid-stream...

This re-write is a major step into the future. Plezi is no longer an alternative to Rails or Sinatra - rather, it aspires to be an alternative to Rack and Node.js, with native support for websocket, callbacks and asynchronous responses.

***

Change log v.0.5.2

**deprecation-notice**: Rack will not be supported on Plezi v. 0.6.0 and above. Major code changes expected!

***

Change log v.0.5.1

**pro-feature**: route's with Proc values are now unsafe (if value isn't `response` or `true`, the value will be passed on - might raise exceptions, but could be used for lazy content (careful - rack's lazy content might crash your service).

**pro-feature**: Controller return values are now unsafe (if value isn't a `String` or a `true`/`false`, the value will be passed on as is instead of the original response object - might raise exceptions, but could be used for lazy content (careful - rack's lazy content might crash your service).

***

Change log v.0.5.0

**feature:** Multiple (virtual) hosts on the same port are now available `listen port, host: 'foo', file_root: 'public/'`, each host holds it's own route stack, file_root and special parameters (i.e. `:debug` etc'). greate for different namespaces (admin.foo.com, www.foo.com, etc').

**fix**: Magic params have full featured Regex capabilities for the optional routes (`(:optional){(regex)|([7]{3})}`).

***

Change log v.0.4.3

**notice!:** v.0.5.0 might break any code using the `listen :vhost => "foo.bar.com"` format. hosts and aliases will be restructured.

**fix**: an issue with the router was discovered, where non-RESTful Controller methods weren't called for POST, PUT or DELETE http requests. this issue is now fixed, so that non-RESTful methods will be attempted and will exclude ID's with the same value from being created...

... in other words, it is now easier to create non-RESTful apps, should there be a need to do so.

***

Change log v.0.4.2

**error-detection**: Plezi will check that the same port isn't used for to services and will return a warning. a `listen` call with `RackServer` will return an existing router object if a service is already assigned to the requested port.

**notice!:** v.0.5.0 will break any code using the `listen :vhost => "foo.bar.com"` format. hosts and aliases will be restructured.

**fix**: 404 error handler should now be immune to path rewrites (displays originally requested path).

**fix/template**: fixed for Heroku - Plezi will not write the pid file if under Heroku Dyno (Heroku apps crash when trying to write data to files).

***

Change log v.0.4.1

**template feature**: the I18n path detection (for paths `"/:locale/..."`) is now totally automated and limited to available locales (only if I18n gem is included in the gem file).

**fix/template**: corrected javascripts folder name in app generator (was singular, now plural).

**template change**: changed mvc configuration file name to db_config.

**fix**: fixed template code for Sequel integration (still very basic).


***

Change log v.0.4.0

This is a strong update that might break old code.

the following features are added

- magic routes:

it is now possible to set required parameters inside the route:
```ruby
route "/version/:number/", Controller
# => accepts only paths styled "/version/foo".
# => if no version paramater exists, path will not be called and parameters will not be set.
# => (this: "/version" fails).
```

it is now possible to set optional parameters inside the route:
```ruby
route "/user/(:id)/(:visitor_id)", Controller
# => accepts any of the following paths:
# => "/user"
# => "/user/foo"
# => "/user/foo/bar"
```

it is now possible to disregard any excess path data:
```ruby
route "/user/(:id)/*", Controller
# => accepts any of the following paths:
# => "/user"
# => "/user/foo"
# => "/user/foo/bar"
```

- re-write routes:

re-write routes allow us to extract parameters from the route without any controller, rewriting the request's path.

they can be extreamly powerful in fairly rare but interesting circumstances.

for example:
```ruby
route "/(:foo)/*", false
# for the request "/bar/path":
# => params[:foo] = "bar"
# => request.path_info == "/path"
```

in a more worldly sense...
```ruby
route ":proc/(:version){v-[\\w\\d\\.]*}/:func/*", false
# look at http://www.rubydoc.info path for /gems/plezi/0.3.2/frames ...
```

**feature**: magic routes.

**feature**: re-write routes.

**update**: new Web App templates save the process id (pid) to the tmp folder (architecture only).

**fix**: 404 and 505 errors set content type correctly.

***

Change log v.0.3.2

**fix**: the SSL features fix depended on Thin being defined. this caused programs without Thin server to fail. this is now fixed.

**fix**: using a single webrick server didn't trap the ^C so that it was impossible to exit the service. this is now fixed.

**fix**: a comment in the code caused the documentation to be replaced with that comment (oops...). this is now fixed.

***

Change log v.0.3.1

**feature removed**: (Code Breaker), removed the `Plezi.default_content_type` feature. it's prone to issues.

**patched**: utf-8 encoding enforcement now works. this might disrupt non-text web-apps (which should use `Plezi.default_encoding = 'binary'` or `Plezi.default_encoding = false`).

**feature**: Enabled path rewrites to effect router - see the advanced features in the wiki home for how to apply this powerful feature. Notice that re-writing is done using the `env["PATH_INFO"]` or the `request.path_info=` method - the `request.path` method is a read only method.

**fix**: a very rare issue was found in the 404.html and 500.html handlers which caused unformatted error messages (as if the 404.html or 500.html files didn't exist). this is now fixed.

**fix**: the send_data method now sets the content-type that was set by the caller (was sending 'application/pdf' for a historic testing reason).

**fix**: minor fixes to the app generator. `plezi new app` should now place the `en.yaml` file correctly (it was making a directory instead of writing the file... oops).

***

Change log v.0.3.0

This release breaks old code!

Re-written the RackServer class and moved more logic to middleware (request re-encoding, static file serving, index file serving, 404 error handling and exception handling are now done through middleware).

Proc safety feature is discarded for now - if you use `return` within a dynamic Ruby Proc, you WILL get an exception - just like Ruby intended you to.

File services can now be set up only through the listen call and directory listing is off *(I'm thinking of writing my own middleware for that, as the Rack::Directory seems to break apart or maybe I don't understand how to use it).

so, code that looked like this:

```
listen

# routes

route '*', file_root: File.expand_path(File.join(Dir.pwd, 'public'))
```

should now look like this:

```
listen root: file_root: File.expand_path(File.join(Dir.pwd, 'public'))

# routes
```

fix: Static file services

fix, update: I18n support

fix: ActiveRecord Tasks

update: Haml support

***

Change log v.0.2.1

Updated some SSL features so that Thin SSL is initialized.

Support for SSL features is still very basic, as there isn't much documentation and each server handles the initialization somewhat differently (at times extremely differently).

some minor bug fixes.

***

Change log v.0.2.0

First release that actually works well enough to do something with.
