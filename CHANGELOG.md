#Change Log

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