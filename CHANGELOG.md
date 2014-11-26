#Change Log
***

Change log v.0.6.9

**update**: now magic routes accept array and hash parameters - i.e. '/posts/(:id)/(:user[name])/(:user[email])/(:response)/(:args[])/(:args[])/(:args[])'

**update**: tweeks to the socket event engine, to allow for more concurrent connections.

**fix**: RESTful routing to `new` and `index` had issues.

**fix**: WebSockets - sending data through multiple connections could cause data corruption. this is now fixed by duplicating the data before framing it.


***

Change log v.0.6.8

**fix**: fixed an issue where WebSocket connections would get disconnected after sending data (an update in v. 0.6.6 introduced a bug that caused connections to close once data was sent).

**updates**: quick web app template updates. now you get better code when you run `$ anorexic new myapp`...

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

**engine**: Anorexic idling engine tweeks. As of yet, Anorexic never really sleeps... (new events can be created by either existing events, existing connections or new connections, so IO.select cannot be used)... idle time costs CPU cycles which were as minimized as possible for now.

**feature**: very basic Rack support is back (brought back mainly for testing)... BUT:

Rack code and Anorexic code are NOT fully compatible. for example: Rack's parameters aren't always fully decoded. Also, Rack's file upload contains tmporary files, where Anorexic's request object contains the binary data in a binary String object.

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

This version is a major re-write for the whole anorexic framework.

**RACK SUPPORT DROPPED!**

Rack support is dropped in favor of a native server that allowa protocol switching mid-stream...

This re-write is a major step into the future. Anorexic is no longer an alternative to Rails or Sinatra - rather, it aspires to be an alternative to Rack and Node.js, with native support for websocket, callbacks and asynchronous responses.

***

Change log v.0.5.2

**deprecation-notice**: Rack will not be supported on Anorexic v. 0.6.0 and above. Major code changes expected!

***

Change log v.0.5.1

**pro-feature**: route's with Proc values are now unsafe (if value isn't `response` or `true`, the value will be passed on - might raise exceptions, but could be used for lazy content (careful - rack's lazy content might crash your service).

**pro-feature**: Controller return values are now unsafe (if value isn't a `String` or a `true`/`false`, the value will be passed on as is instead of the original response object - might raise exceptions, but could be used for lazy content (careful - rack's lazy content might crash your service).

***

Change log v.0.5.0

**feature:** Multiple (virtual) hosts on the same port are now available `listen port, host: 'foo', file_root: 'public/'`, each host holds it's own route stack, file_root and special paramaters (i.e. `:debug` etc'). greate for different namespaces (admin.foo.com, www.foo.com, etc').

**fix**: Magic params have full featured Regex capabilities for the optional routes (`(:optional){(regex)|([7]{3})}`).

***

Change log v.0.4.3

**notice!:** v.0.5.0 might break any code using the `listen :vhost => "foo.bar.com"` format. hosts and aliases will be restructured. 

**fix**: an issue with the router was discovered, where non-RESTful Controller methods weren't called for POST, PUT or DELETE http requests. this issue is now fixed, so that non-RESTful methods will be attempted and will exclude ID's with the same value from being created...

... in other words, it is now easier to create non-RESTful apps, should there be a need to do so.

***

Change log v.0.4.2

**error-detection**: Anorexic will check that the same port isn't used for to services and will return a warning. a `listen` call with `RackServer` will return an existing router object if a service is already assigned to the requested port.

**notice!:** v.0.5.0 will break any code using the `listen :vhost => "foo.bar.com"` format. hosts and aliases will be restructured. 

**fix**: 404 error handler should now be immune to path rewrites (displays originally requested path).

**fix/template**: fixed for Heroku - Anorexic will not write the pid file if under Heroku Dyno (Heroku apps crash when trying to write data to files).

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

it is now possible to set required paramaters inside the route:
```ruby
route "/version/:number/", Controller
# => accepts only paths styled "/version/foo".
# => if no version paramater exists, path will not be called and paramaters will not be set.
# => (this: "/version" fails).
```

it is now possible to set optional paramaters inside the route:
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

re-write routes allow us to extract paramaters from the route without any controller, rewriting the request's path.

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
# look at http://www.rubydoc.info path for /gems/anorexic/0.3.2/frames ...
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

**feature removed**: (Code Breaker), removed the `Anorexic.default_content_type` feature. it's prone to issues.

**patched**: utf-8 encoding enforcement now works. this might disrupt non-text web-apps (which should use `Anorexic.default_encoding = 'binary'` or `Anorexic.default_encoding = false`).

**feature**: Enabled path rewrites to effect router - see the advanced features in the wiki home for how to apply this powerful feature. Notice that re-writing is done using the `env["PATH_INFO"]` or the `request.path_info=` method - the `request.path` method is a read only method.

**fix**: a very rare issue was found in the 404.html and 500.html handlers which caused unformatted error messages (as if the 404.html or 500.html files didn't exist). this is now fixed.

**fix**: the send_data method now sets the content-type that was set by the caller (was sending 'application/pdf' for a historic testing reason).

**fix**: minor fixes to the app generator. `anorexic new app` should now place the `en.yaml` file correctly (it was making a directory instead of writing the file... oops).

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