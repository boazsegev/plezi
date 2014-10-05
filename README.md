# Anorexic

A thin, lightweight, barebones, ruby alternative to rails (ROR)... so thin, it's anorexic!

The philosophy is simple - pristine, simple and dedicated gems for each functionality are better then a fullfeatured framework.

Anorexic is the pristine, simple and dedicated DSL that will make your web app respond like it's on steroids.

It's a multi-threaded system based on WEBrick. There's no rake, no thin, no unicorn... if you want something, you will have to plug it in or hard-code it yourself...

...and since it's all pure ruby, it's as easy as it gets.

## why not Ruby on Rails?

Ruby on Rails became too bloated and big for some projects... in comes anorexic to the rescue. Feed it on plug-ins and gems to expend it's capabilities, or feed it on your own code - it will eat it all up.

Where Rails is a provides you with a whole solution, Anorexic just creates the skeleton. Where Rails is a wired, full featured (and HEAVY) supercomputer - Anorexic is just a motherboard and a CPU, waiting for you to connect your favorite gems and peripherals.

Don't get me wrong, I love Ruby on Rails... but it's just to big and heavy for some apps I want to develop. 

## Pristine lego blocks

I love the Ruby community and I know that we are realy good at writing gems and plug-ins that save a lot of time. But we don't need all the plug-ins all the time.

This is the "Pristine lego blocks" phylosophy.

Our needs are totally different for each project. An XML web service for an iPhone native app is a very different animal then a book-store web app (not another book store app!).

Together we can write add-ons and features and beautifuls gems that we will use when (and if) we need them.

## Installation

Add this line to your application's Gemfile:

    gem 'anorexic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install anorexic

## Usage

to write a web app, simply type

    $ anorexic new appname

the app is a simple DSL that deletes itself once the server starts running (this way, we avoid any conflicts in the code - no reserved keywords).

The most simple app will be a simple web server (it can actually be even more simple):

		require 'bundler'
		Bundler.require
		require 'anorexic'

		# set the folder from which to serve files - this can be removed to avoid file access.
		public_folder = File.expand_path(File.dirname(__FILE__), 'public')

		# set up a non-secure service on port 80
		listen 80, DocumentRoot: public_folder

		# this rount is just to show who made the app
		route "/people" do |req, res|
			res.body = "<html><head></head><body><p>I made this app! :-)</p></body></html>"
		end

		# deletes the DSL and starts the service
		start


## Contributing

1. Fork it ( https://github.com/[my-github-username]/anorexic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
