#Change Log

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