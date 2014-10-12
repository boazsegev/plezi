# Anorexic

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

## Barebones Web Service

the app is a simple DSL that deletes all the DLS methods once the server starts running (less clutter while running).

you can run anorexic from your favorite Ruby terminal :) - Anorexic starts the moment you exit the terminal.

this example is basic, useless, but required for every doc out there...

"Hello World!" in 3 lines - try it in irb (exit irb to start server):

		require 'anorexic'
		listen 
		route(/.?/) { |req, res| res.body << "Hello World!" }

did you notice the catch-all regular-expression? you can write it like this too:

		require 'anorexic'
		listen
		route('*') { |req, res| res.body << "Hello World!" }

Here's a simple web server in three (+2) lines of code, serving static pages from the `public` folder::

		require 'anorexic'

		# set up a non-secure service on port 80
		listen 80
		# set up a encrypted service on port 443, works only with servers that support SSL (i.e. webrick)
		listen 443, server: 'webrick', ssl_self: true

		shared_route('/people') { |req, res| res.body << "I made this :-)" }

		shared_route '*', file_root: File.expand_path(File.dirname(__FILE__), 'public')

## Anorexic Controller classes

one of the best things about the Anorexic is it's ability to take in any class as a controller class and route to the classes methods with special support for RESTful methods (index, show, save, update, before, after):

		require 'pry'
		require 'anorexic'
		require 'thin' # will change the default server to thin automatically.

		class Controller
			def index
				"Hellow World!"
			end
			def show
				"You're looking for: #{params[:id]}"
			end
			def debug
				binding.pry
				true
			end
			def delete
				"did you try /#{params["id"]}/?_method=delete"
			end
		end

		listen
		route "/users" , Controller
		route "/" , Controller

Controllers can even be nested (order matters) or have advanced uses that are definitly worth exploring. here's some food for thought:

		class SuperController
			def before
				# using the before filter and regular expressions to make some changes.
				params[:added_param] = " user id" if request.path.match /^\/users\/[^\/]+\/?$/
				return false
			end
		end

		class Controller
			def index
				"Hellow World!"
			end
			def show
				"You're looking for#{params[:added_param]}: #{params[:id]}"
			end
			def debug
				binding.pry
				true
			end
			def delete
				"did you try /#{params["id"]}/?_method=delete"
			end
		end

		listen
		route "*" , SuperController
		route "/users" , Controller
		route "/" , Controller


## Anorexic is hungry for pristine yummy gems

This is the "Pristine chunks" phylosophy.

Our needs are totally different for each project. An XML web service for an iPhone native app is a very different animal then a book-store web app (please, not another book store app...).

Together we can write add-ons and features and beautifuls gems that we will use when (and if) we need them - so our apps are always happy and never overweight!

## why not Ruby on Rails? why not Sinatra?

I love the Ruby community and I know that we are realy good at writing gems and plug-ins that save a lot of time and code. But we don't need all the plug-ins all the time.

Ruby on Rails became too bloated and big for some projects... It's full of great features that some of them are sometimes used... but at the end of the day, it's HEAVY.

Looking into Sinatra benchmarks on the web showed that Rails and Sinatra perform on a similar level. The added 'lightness' just wasn't light enough.

So sure, you can use Rails or Sinatra, they're great, but we Love to feed Anorexic our code, it just eats it up so nicely.

# Feed the Anorexic framework

The whole of the Anorexic framework philosophy is about community, sharing and feeding the anorexic framework with small and pristine gems.

see the anorexic-haml for an example of a small gem that feeds HAML and I18n to the Anorexic framework.

## Contributing


1. Fork it ( https://github.com/boazsegev/anorexic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
