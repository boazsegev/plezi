# Anorexic
[![Gem Version](https://badge.fury.io/rb/anorexic.svg)](http://badge.fury.io/rb/anorexic)
[![Inline docs](http://inch-ci.org/github/boazsegev/anorexic.svg?branch=master)](http://inch-ci.org/github/boazsegev/anorexic)

A thin, lightweight, barebones, mutli-threaded Ruby alternative to Rails (ROR) and Sinatra frameworks... so thin, it's anorexic!

The philosophy is simple - pristine, simple and dedicated gems for each functionality allow for a custom made framework that is exactly the right size during runtime.

Anorexic is a barebones DLS that can run with or without Rack and offers single-port as well as multi-port service for basic and advanced web services alike.

...and since it's all pure Ruby, it's as easy as it gets.

## Installation

install it using:

    $ gem install anorexic

## Framework Usage

to create a new barebones app using the Anorexic framework, run from terminal:

    $ anorexic new appname

That's it, now you have a ready to use basic web server (with some demo code), just run it:

    $ cd appname
    $ ./appname.rb # ( or: anorexic s )

this is a smart framework app that comes very skinny and will happily eat any gem you feed it. it responds extra well to Thin and Haml, which you can enable in it's Gemfile.

now go, in your browser, to: http://localhost:3000/

the default first port for the app is 3000. you can set the first port to listen to by using the `-p ` option (make sure you have permissions for the requested port):

    $ ./appname.rb -p 80

## Barebones Web Service

Anorexic contains a simple single-use DSL (all the DLS methods are removed once the server starts running - less clutter while running).

you can run anorexic from your favorite Ruby terminal :) - Anorexic starts the moment you exit the terminal.

Anorexic creates a whole web service with three commands that speek for themselves:
- listen
- route
- shared_route

this example is basic, useless, but required for every doc out there...

"Hello World!" in 3 lines - try it in irb (exit irb to start server):

		require 'anorexic'
		listen
		route(/.?/) { |req, res| res.body << "Hello World!" }

After you exited irb, the Anorexic server started up. go to http://localhost:3000/ and see it run :)

if more then one `listen` call was made, ports will be sequential (3000, 3001, 3002...) unless explicitly set(`listen 443`).

*btw*: did you notice the catch-all regular-expression? you can write it like this too:

		require 'anorexic'
		listen
		route('*') { |req, res| res.body << "Hello World!" }

Here's a simple web server, complete with SSL (supported on Thin and webrick servers), in three (+1) lines of code, serving static pages from the `public` folder::

		require 'anorexic'

		# set up a non-secure service on port 3000
		listen 3000, file_root: File.expand_path(File.join(Dir.pwd , 'public'))

		# set up a encrypted service on port 8080, works only with some servers (i.e. thin, webrick)
		listen 8080, ssl_self: true, file_root: File.expand_path(File.join(Dir.pwd , 'public')) 

		shared_route('/people') { |req, res| res.body << "I made this :-)" }

## Anorexic Routes

Routes have paths that tell the application which code to run for every request it recieves. when you set your browser to: `http://www.server.com/the/stuff/they/request?paramaters=params[:paramaters]` , this is the routes path: `/the/stuff/they/request`

As long as Anorexic uses the Anorexic::RackServer class (we could change that, but why would we?), the routes will work the same for all the listening ports.

Anorexic allows your code to choose it's routes dynamically, in the order they are created. like so:

    require 'anorexic'
    listen

    # this route declines to answer
    route('/') { |req, res| res.body << "I Give Up!"; false }

    # this route wins
    route('/') { |req, res| res.body << "I Win!" }

    # this route never sees the light of day
    route('/') { |request, response| response.body << "Help Me!" }

Anorexic supports magic routes, in similar formats found in other systems, such as: `route "/:required/(:optional)/(:optional_with_format){[\\d]*}", Controler` -  **please see the `route` documentation for more information on routes**.

Anorexic assummes all simple string routes to be RESTful routes ( `"/user" == "/user/(:id)"` ).

    require 'anorexic'
    listen

    # this route demos a route for listing/showing posts,
    # with or without revision numbers or page-control....
    route "/post/(:id)/(:revision){[\d]*}/(:page_number)", Anorexic::StubController

Anorexic accepts Regexp routes as well as string and magic routes and defines a short cut for a catch-all route:

    require 'anorexic'
    listen

    # this route accepts paths that start with a number (i.e.: /nonumber)
    route(/^\/[\d]+[\D]+/) { |req, res| res.body << "Give me more numbers :)" }

    # this route accepts paths that are just numbers (i.e.: /87652)
    route(/^\/[\d]+$/) { |req, res| res.body << "I Love Numbers!" }

    # this route accepts paths that don't have any number (i.e.: /nonumber)
    route(/^\/[\D]+$/) { |req, res| res.body << "Where're my numbers :(" }

    # this route catches everything else.
    route('*') { |request, response| response.body << "Gotcha!" }

## Anorexic Virtual Hosts

The Anorexic `listen` command can be used to create virtual hosts for the same service, by supplying a port that is already assigned:

    require 'anorexic'

    # sets a virtuls host on localhost 1 (saving the server object to use it's port)
    server = listen host: 'localhost'

    route('/welcome') { |req, res| res.body << "Welcome to Localhost." }

    # sets a virtuls host on admin.localhost1
    # (using the same port creates a virtual host instead of a new service)
    admin_host = listen server.port, host: '127.0.0.1'

    route('/welcome') { |req, res| res.body << "Administrate Localhost." }

    # sets a global router for the same service
    # (for any host NOT localhost1 or admin.localhost1 )
    listen server.port
    route('/welcome') { |req, res| res.body << "Welcome to the global namespace" }

    # virtual hosts support shared routes, just like real services
    shared_route('/people') { |req, res| res.body << "we made this!" }

    # it's possible to directly add routes to an "older" host, if you saved it.
    # (this works also as live route adding)
    admin_host.add_route('/secret') { |req, res| res.body << "Shhhh!" }

    # shared routes can be catch-all (careful).
    shared_route('*') { |req, res| res.body << "Gotcha!" }

## Anorexic Controller classes

One of the best things about the Anorexic is it's ability to take in any class as a controller class and route to the classes methods with special support for RESTful methods (`index`, `show`, `save`, `update`, `delete`, `before` and `after`):

		require 'pry'
		require 'anorexic'
		require 'thin' # will change the default server to thin automatically.

		class Controller
			def index
				"Hello World!"
			end
			def show
				"You're looking for: #{params[:id]}"
			end
			def debug
				binding.pry
				true
			end
			def delete
				"did you try /#{params["id"]}/?_method=delete or does your server support a native DELETE method?"
			end
		end

		listen
		route "/users" , Controller
		route "/" , Controller

Returning a String will automatically add the string to the response before sending the response - which makes for cleaner code. It's also possible to send the response as it is (by returning true) or to create your own response (careful, you need to know what you're doing there...).

Controllers can even be nested (order matters) or have advanced uses that are definitly worth exploring.

Here's some food for thought - code similar to something actually used in the framework app:

		require 'pry'
		require 'anorexic'
		require 'thin'

		class ReWriteController
			# using the before filter and regular expressions to make some changes.
			def before
				result = request.path.match /^\/(en|fr)($|\/.*)/
				if result
					params["locale"] = result[1].to_sym
					request.path_info = result[2]
				end
				return false
			end
		end

		class Controller
			def index
				return "Bonjour le monde!" if params[:locale] == :fr
				"Hello World!"
			end
			def show
				return "Vous êtes à la recherche d' : #{params[:id]}" if params[:locale] == :fr
				"You're looking for: #{params[:id]}"
			end
			def debug
				binding.pry
				true
			end
			def delete
				return "Mon Dieu! Mon français est mauvais!" if params[:locale] == :fr
				"did you try /#{params["id"]}/?_method=delete"
			end
		end

		listen

		route "*" , ReWriteController

		route /^\/[\d\+\-\*\/\(\)\.]+$/ do |request, response|
			message = (request.params[:locale] == :fr) ? "La solution est" : "My Answer is"
			response.body << "#{message}: #{eval(request.path[1..-1])}"
		end

		route "/users" , Controller

		route "/" , Controller

try:

* http://localhost:3000/
* http://localhost:3000/users
* http://localhost:3000/users/hello
* http://localhost:3000/(5+5*20-15)/9

## Anorexic is hungry for pristine yummy gems

This is the "Pristine chunks" phylosophy.

Our needs are totally different for each project. An XML web service for an iPhone native app is a very different animal then a book-store web app (please, not another book store app...).

Together we can write add-ons and features and beautifuls gems that we will use when (and if) we need them - so our apps are always happy and never overweight!

## What about Ruby on Rails or Sinatra?

I love the Ruby community and I know that we are realy good at writing gems and plug-ins that save a lot of time and code. But we don't need all the plug-ins all the time.

Ruby on Rails became too bloated and big for some projects... It's full of great features that some of them are sometimes used... but at the end of the day, it's HEAVY.

Looking into Sinatra benchmarks on the web showed that Rails and Sinatra frameworks perform on a similar level. The added 'lightness' just wasn't light enough.

Some of us started reverting to pure Rack, and a lot of code kept being written over and over again... Actually, Anorexic is just a smart wrapper to Rack, to make routing and MVC (Model-View-Controller) programming easier.

So sure, you can use Rails or Sinatra, they're great, but we Love to feed Anorexic our code, it just eats it up so nicely.

# Feed the Anorexic framework

The whole of the Anorexic framework philosophy is about community, sharing and feeding the anorexic framework with small and pristine gems.

Please, feel free to contribute, push any changes on the github project and create your own gems to feed the Anorexic open framework.

## Contributing


1. Fork it ( https://github.com/boazsegev/anorexic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
