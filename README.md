# Anorexic

A thin, lightweight, barebones, ruby alternative to rails (ROR)... so thin, it's anorexic!

The philosophy is simple - pristine, simple and dedicated gems for each functionality allow for a custom made framework that is exactly the right size during runtime.

Anorexic is the pristine, simple and dedicated DSL that will make your web app respond like it's on steroids.

It's a barebones DLS running WEBrick... if you want something (Thin, HAML, anythin), you will have to plug it in or hard-code it yourself...

...and since it's all pure ruby, it's as easy as it gets.

## why not Ruby on Rails?

I love the Ruby community and I know that we are realy good at writing gems and plug-ins that save a lot of time and code. But we don't need all the plug-ins all the time.

Ruby on Rails became too bloated and big for some projects... It's full of greate features that some of them are sometimes used... but at the end of the day, it's HEAVY.

in comes anorexic to the rescue. Feed it on plug-ins and gems to expend it's capabilities, or feed it on your own code - it will eat it all up and size up to your exact needs.

Don't get me wrong, I love Ruby on Rails... but it's just to big and heavy for some apps I want to develop. 

## Anorexic is hungry for pristine yummy gems

This is the "Pristine chunks" phylosophy.

Our needs are totally different for each project. An XML web service for an iPhone native app is a very different animal then a book-store web app (not another book store app!).

Together we can write add-ons and features and beautifuls gems that we will use when (and if) we need them - so our apps are always happy and never overweight!

## Installation

install it using:

    $ gem install anorexic

## Usage

the app is a simple DSL that deletes all the DLS methods once the server starts running (this way, we avoid any conflicts in the code - no reserved keywords).

The most simple app will be a simple web server (it can actually be even more simple):

		# load the anorexic gem
		require 'rubygems'
		require 'anorexic'

		# set the folder from which to serve files
		public_folder = File.expand_path(File.dirname(__FILE__), 'public')

		# set up a non-secure service on port 80
		# serves file without file indexingå
		listen 80, file_root: public_folder

and, with 4 lines of very clear code, without any shortcuts, we have a running web server :)

## Framework Usage

to create a new barebones app using the Anorexic framework, run from terminal:

    $ anorexic new appname

or, create a new web app with some anorexic gems you installed:

    $ anorexic n appname w anorexic-haml

or, even create a new web app with all the anorexic gems you installed:

    $ anorexic n appname w all

# Feed the Anorexic framework

The whole of the Anorexic framework philosophy is about community, sharing and feeding the anorexic framework with small and pristine gems.

see the anorexic-haml for an example of a small gem that feeds HAML and I18n to the Anorexic framework.

## Contributing


1. Fork it ( https://github.com/[my-github-username]/anorexic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
