# Anorexic

A thin, lightweight, barebones, ruby alternative to rails (ROR)... so thin, it's anorexic!

Ruby on Rails became too bloated and big for some projects... in comes anorexic to the rescue. Feed it on plug-in and gems to expend it's capabilities, or feed it on your own code - it will eat it all up.

It's a multi-threaded system based on WEBrick. There's no rake, no thin, no unicorn... if you want somethin, you will have to plug it in or hard-code it.

Where Rails is a provides you with a whole solution, Anorexic just creates the skeleton. Where Rails is a wired, full featured supercomputer, Anorexic is just a motherboard and a CPU, waiting for you to connect your favorite gems and peripherals.

The philosophy is simple - pristine, simple and dedicated gems for each functionality are better then a fullfeatured framework.

Anorexic is the pristine, simple and dedicated DSL that will make your web app respond like it's on steroids.

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

## Contributing

1. Fork it ( https://github.com/[my-github-username]/anorexic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
