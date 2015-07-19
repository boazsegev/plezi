# Plezi, The Rack Free Ruby framework for realtime web-apps
[![Gem Version](https://badge.fury.io/rb/plezi.svg)](http://badge.fury.io/rb/plezi)
[![Inline docs](http://inch-ci.org/github/boazsegev/plezi.svg?branch=master)](http://www.rubydoc.info/gems/plezi/)

> People who are serious about their frameworks, should write their own servers...

Find more info on [Plezi's framework documentation](http://www.rubydoc.info/gems/plezi/)

## About the Plezi framework

Plezi is an easy to use Ruby Websocket Framework, with full RESTful routing support and HTTP streaming support. It's name comes from the word "fun" in Haitian, since Plezi is really fun to work with and it keeps our code clean and streamlined.

Plezi works as an asynchronous multi-threaded Ruby alternative to a Rack/Rails/Sintra/Faye/EM-Websockets combo. It's also great as an alternative to socket.io, allowing for both websockets and long pulling.

Plezi runs over the [GRHttp server](https://github.com/boazsegev/GRHttp), which is a pure Ruby HTTP and Websocket Generic Server build using [GReactor](https://github.com/boazsegev/GReactor) - a multi-threaded pure ruby alternative to EventMachine with basic process forking support (enjoy it, if your code is scaling ready).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plezi'
```

Or install it yourself as:

    $ gem install plezi

## Creating a Plezi Application

to create a new barebones app using the Plezi framework, run from terminal:

    $ plezi new appname

That's it, now you have a ready to use basic web server (with some demo code, such as a websocket chatroom).

If you're on MacOS or linux you can simply double click the `appname` script file in the `appname` folder. Or, from the terminal, you can type:

    $ cd appname
    $ ./appname # ( or: plezi s )

now go, in your browser, to: [http://localhost:3000/](http://localhost:3000/)

the default first port for the app is 3000. you can set the first port to listen to by using the `-p ` option (make sure you have permissions for the requested port):

    $ ./appname -p 80

you now have a smart framework app that will happily assimilate any gem you feed it. it responds extra well to Haml, Sass and Coffee-Script, which you can enable in it's Gemfile.

## Barebones Web Service

This example is basic, useless, but required for every doc out there...

"Hello World!" in 3 lines - try it in irb (exit irb to start server):

		require 'plezi'
		listen
		route(/.?/) { |req, res| res << "Hello World!" }

After you exit irb, the Plezi server will start up. Go to http://localhost:3000/ and see it run :)

## Plezi Controller classes

One of the best things about the Plezi is it's ability to take in any class as a controller class and route to the classes methods with special support for RESTful methods (`index`, `show`, `new`, `save`, `update`, `delete`, `before` and `after`) and for WebSockets (`pre_connect`, `on_open`, `on_message(data)`, `on_close`, `broadcast`, `unicast`, `on_broadcast(data)`):

        require 'plezi'

        class Controller
            def index
                "Hello World!"
            end
        end

        listen
        route '*' , Controller

Except for WebSockets, returning a String will automatically add the string to the response before sending the response - which makes for cleaner code. It's also possible to send the response as it is (by returning true).

Controllers can even be nested (order matters) or have advanced uses that are definitly worth exploring.

\* please read the demo code for Plezi::StubRESTCtrl and Plezi::StubWSCtrl to learn more. Also, read more about the [GRHttp server](GRHttp websocket and HTTP server) at the core of Plezi to get more information about the amazing [HTTPRequest](http://www.rubydoc.info/gems/grhttp/0.0.6/GRHttp/HTTPRequest) and [HTTPResponse](http://www.rubydoc.info/gems/grhttp/GRHttp/HTTPResponse) objects.

## Native Websocket and Redis support

Plezi Controllers have access to native websocket support through the `pre_connect`, `on_open`, `on_message(data)`, `on_close`, `broadcast` and `unicast` methods.

Here is some demo code for a simple Websocket broadcasting server, where messages sent to the server will be broadcasted back to all the **other** active connections (the connection sending the message will not recieve the broadcast).

As a client side, we will use the WebSockets echo demo page - we will simply put in ws://localhost:3000/ as the server, instead of the default websocket server (ws://echo.websocket.org).

Remember to connect to the service from at least two browser windows - to truly experience the `broadcast`ed websocket messages.

```ruby
    require 'plezi'

    # do you need automated redis support?
    # require 'redis'
    # ENV['PL_REDIS_URL'] = "redis://user:password@localhost:6379"

    class BroadcastCtrl
        def index
            redirect_to 'http://www.websocket.org/echo.html'
        end
        def on_message data
            # try replacing the following two lines are with:
            # self.class.broadcast :_send_message, data
            broadcast :_send_message, data
            response << "sent."
        end
        def _send_message data
            response << data
        end
        def hello
            'Hello!'
        end
        def_special_method "humans.txt" do
            'I made this :)'
        end
    end

    listen 

    route '/', BroadcastCtrl
```

method names starting with an underscore ('_') will NOT be made public by the router: so while both '/hello' and '/humans.txt' are public ( [try it](http://localhost:3000/humans.txt) ), '/_send_message' will return a 404 not found error ( [try it](http://localhost:3000/_send_message) ).

## Native HTTP streaming with Asynchronous events

Plezi comes with native HTTP streaming support, alowing you to use Plezi Events and Timers to send an Asynchronous response.

Let's make the classic 'Hello World' use HTTP Streaming:

```ruby
        require 'plezi'

        class Controller
            def index
                response.stream_async do
                    sleep 0.5
                    response << "Hello ";
                    response.stream_async{ sleep 0.5; response << "World" }
                end
                true
            end
        end

        listen
        route '*' , Controller
```

Notice you can nest calls to the `response.stream_async` method, allowing you to breakdown big blocking tasks into smaller chunks. `response.stream_async` will return immediately, scheduling the task for background processing.

You can also handle other tasks asynchronously using the [GReactor API](http://www.rubydoc.info/gems/greactor)'s.

More on asynchronous events and timers later.

## Plezi Routes

Plezi supports magic routes, in similar formats found in other systems, such as: `route "/:required/(:optional_with_format){[\\d]*}/(:optional)", Plezi::StubRESTCtrl`.

Plezi assummes all simple routes to be RESTful routes with the parameter `:id` ( `"/user" == "/user/(:id)"` ).

    require 'plezi'
    listen

    # this route demos a route for listing/showing posts,
    # with or without revision numbers or page-control....
    # notice the single quotes (otherwise the '\' would need to be escaped).
    route '/post/(:id)/(:revision){[\d]+\.[\d]+}/(:page_number)', Plezi::StubRESTCtrl

now visit:

* [http://localhost:3000/post/12/1.3/1](http://localhost:3000/post/12/1.3/1)
* [http://localhost:3000/post/12/1](http://localhost:3000/post/12/1)

**please see the `route` documentation for more information on routes**.

## Plezi Virtual Hosts

Plezi can be used to create virtual hosts for the same service, allowing you to handle different domains and subdomains with one app:

    require 'plezi'
    listen
    host 'localhost', alias: 'localhost2'

    shared_route '/humans.txt' do |req, res|
        res << "we are people - shared by all routes."
    end

    host

    route('*') do |req, res|
        res << "this is a 'catch-all' host. you got here by putting in the IP adderess."
    end

    host 'localhost'

    route('*') do |req, res|
        res << "this is localhost or localhost 2"
    end

Now visit:

* [http://127.0.0.1:3000/]( http://127.0.0.1:3000/ )
* [http://localhost:3000/]( http://localhost:3000/ )
* [http://127.0.0.1:3000/humans.txt]( http://127.0.0.1:3000/humans.txt )
* [http://localhost:3000/humans.txt]( http://localhost:3000/humans.txt )

## Plezi Logging

The Plezi module (also `PL`) delegates to the GReactor methods, helping with logging as well as the support you already noticed for dynamic routes, dynamic services and more.

Logging:

    require 'plezi'

    # simple logging of strings
    PL.info 'log info'
    GReactor.info 'This is the same, but more direct.'
    PL.warn 'log warning'
    PL.error 'log error'
    PL.fatal "log a fatal error (shuoldn't be needed)."
    PL.log_raw "Write raw strings to the logger."

    # the logger accepts exceptions as well.
    begin
        raise "hell"
    rescue Exception => e
        PL.error e
    end

Please notice it is faster to use the GReactor API directly when using API that is delegated to GReactor.

## Plezi Events and Timers

The Plezi module (also `PL`) also delegates to the [GReactor's API](http://www.rubydoc.info/gems/greactor/GReactor) to help with asynchronous tasking, callbacks, timers and customized shutdown cleanup.

Asynchronous callbacks (works only while services are active and running):

    require 'plezi'

    def my_shutdown_proc time_start
        puts "Services were running for #{Time.now - time_start} seconds."
    end

    # shutdown callbacks
    GReactor.on_shutdown(Kernel, :my_shutdown_proc, Time.now) { puts "this will run after shutdown." }
    GReactor.on_shutdown() { puts "this will run too." }

    # a timer
    GReactor.run_after 2, -> {puts "this will wait 2 seconds to run... too late. for this example"}

    # an asynchronous method call with an optional callback block
    GReactor.callback(Kernel, :puts, "Plezi will start eating our code once we exit terminal.") {puts 'first output finished'}

    GReactor.run_async {puts "notice that the background tasks will only start once the Plezi's engine is running."}
    GReactor.run_async {puts "exit Plezi to observe the shutdown callbacks."}

## Re-write Routes

Plezi supports special routes used to re-write the request and extract parameters for all future routes.

This allows you to create path prefixes which will be removed once their information is extracted.

This is great for setting global information such as internationalization (I18n) locales.

By using a route with the a 'false' controller, the parameters extracted are automatically retained.

*(Older versions of Plezi allowed this behavior for all routes, but it was deprecated starting version 0.7.4).

    require 'plezi'

    class Controller
        def index
            return "Bonjour le monde!" if params[:locale] == 'fr'
            "Hello World!\n #{params}"
        end
        def show
            return "Vous êtes à la recherche d' : #{params[:id]}" if params[:locale] == 'fr'
            "You're looking for: #{params[:id]}"
        end
        def debug
            # binding.pry
            # do you use pry for debuging?
            # no? oh well, let's ignore this.
            false
        end
        def delete
            return "Mon Dieu! Mon français est mauvais!" if params[:locale] == 'fr'
            "did you try #{request.base_url + request.original_path}?_method=delete or does your server support a native DELETE method?"
        end
    end

    listen

    # this is our re-write route.
    # it will extract the locale and re-write the request.
    route '/:locale{fr|en}/*', false

    # this route takes a regular expression that is a simple math calculation
    # (calculator)
    #
    # it is an example for a Proc controller, which can replace the Class controller.
    route /^\/[\d\+\-\*\/\(\)\.]+$/ do |request, response|
        message = (request.params[:locale] == 'fr') ? "La solution est" : "My Answer is"
        response << "#{message}: #{eval( request.path[1..-1] )}"
    end

    route "/users" , Controller

    route "/" , Controller

try:

* [http://localhost:3000/](http://localhost:3000/)
* [http://localhost:3000/fr](http://localhost:3000/fr)
* [http://localhost:3000/users/hello](http://localhost:3000/users/hello)
* [http://localhost:3000/users/(5+5*20-15)/9.0](http://localhost:3000/users/(5+5*20-15)/9.0)
* [http://localhost:3000/(5+5*20-15)/9.0](http://localhost:3000/(5+5*20-15)/9)
* [http://localhost:3000/fr/(5+5*20-15)/9.0](http://localhost:3000/fr/(5+5*20-15)/9)
* [http://localhost:3000/users/hello?_method=delete](http://localhost:3000/users/hello?_method=delete)

As you can see in the example above, Plezi supports Proc routes as well as Class controller routes.

Please notice that there are some differences between the two. Proc routes less friedly, but plenty powerful and are great for custom 404 error handling.

## OAuth2 and other Helpers

Plezi has a few helpers that help with common tasks.

For instance, Plezi has a built in controller that allows you to add social authentication using Google, Facebook
and and other OAuth2 authentication service. For example:

    require 'plezi'

    class Controller
        def index
            flash[:login] ? "You are logged in as #{flash[:login]}" : "You aren't logged in. Please visit one of the following:\n\n* #{request.base_url}#{Plezi::OAuth2Ctrl.url_for :google}\n\n* #{request.base_url}#{Plezi::OAuth2Ctrl.url_for :facebook}"
        end
    end

    # set up the common social authentication variables for automatic Plezi::OAuth2Ctrl service recognition.
    ENV["FB_APP_ID"] ||= "facebook_app_id / facebook_client_id"
    ENV["FB_APP_SECRET"] ||= "facebook_app_secret / facebook_client_secret"
    ENV['GOOGLE_APP_ID'] = "google_app_id / google_client_id"
    ENV['GOOGLE_APP_SECRET'] = "google_app_secret / google_client_secret"

    require 'plezi/oauth'

    # manually setup any OAuth2 service (we'll re-setup facebook as an example):
    Plezi::OAuth2Ctrl.register_service(:facebook, app_id: ENV['FB_APP_ID'],
                    app_secret: ENV['FB_APP_SECRET'],
                    auth_url: "https://www.facebook.com/dialog/oauth",
                    token_url: "https://graph.facebook.com/v2.3/oauth/access_token",
                    profile_url: "https://graph.facebook.com/v2.3/me",
                    scope: "public_profile,email") if ENV['FB_APP_ID'] && ENV['FB_APP_SECRET']


    listen

    create_auth_shared_route do |service_name, token, remote_user_id, remote_user_email, remote_response|
        # we will create a temporary cookie storing a login message. replace this code with your app's logic
        flash[:login] = "#{remote_response['name']} (#{remote_user_email}) from #{service_name}"
    end

    route "/" , Controller

    exit

Plezi has a some more goodies under the hood.

Whether such goodies are part of the Plezi-App Template (such as rake tasks for ActiveRecord without Rails) or part of the Plezi Framework core (such as descried in the Plezi::ControllerMagic documentation: #flash, #url_for, #render, #send_data, etc'), these goodies are fun to work with and make completion of common tasks a breeze.


## Plezi Settings

Plezi is meant to be very flexible. please take a look at the Plezi Module for settings you might want to play with (max_threads, idle_sleep, create_logger) or any monkey patching you might enjoy.

Feel free to fork or contribute. right now I am one person, but together we can make something exciting that will help us enjoy Ruby in this brave new world and (hopefully) set an example that will induce progress in the popular mainstream frameworks such as Rails and Sinatra.

## Contributing

1. Fork it ( https://github.com/boazsegev/plezi/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
