# Plezi - a real-time web application framework for Ruby

Are microservices on your mind? Do you dream of a an SPA that's easy to scale? Did you wonder if you could write a whole Websockets, RESTful AJAX back-end with just a few lines of code (application logic not included)?

Welcome to your new home with [plezi.io](http://www.plezi.io), the Ruby real-time framework that assumes the application's logic is *not* part of the web service.

## What does Plezi have to offer?

Plezi is a Rack based framework with support for native (server side implemented) Websocket.

Plezi will provide the following features over plain Rack:

* Object Oriented (M)VC design, BYO (Bring Your Own) models.

* A case sensitive RESTful router to map HTTP requests to your Controllers.

    Non-RESTful public Controller methods will be automatically published as valid HTTP routes, allowing the Controller to feel like an intuitive "virtual folder" with RESTful features.

* An extensible template rendering abstraction engine, supports Slim, Markdown (using RedCarpet), ERB and SASS (mostly for embedded CSS) out of the box.

* Raw Websocket connections (non of that fancy "subscribe" thingy).

* An (optional) Auto-Dispatch to map JSON websocket "events" to Controller functions (handlers).

* Automatic (optional) scaling using Redis.

Things Plezi **doesn't** do (anymore / ever):

* No application logic inside.

    Conneting your application logic to Plezi is easy, however, application logic should really be *independent*, **reusable** and secure. There are plenty of gems that support independent application logic authoring.

* No native session support. If you *must* have session support, Rack middleware gems provide a lot of options. Pick one... However...

    Session have been proved over and over to be insecure and resource draining.

    Why use a session when you can save server resources and add security by using a persistent connection, i.e. a Websocket? If you really feel like storing unimportant stuff, why not use javascript's `local storage` on the *client's* machine? (if you need to save important stuff, you probably shouldn't be using sessions anyway).

* No asset pipeline (Plezi does support templates, but not "assets").

    Most of the HTML, CSS and JavaScript could be (and probably should be) rendered ahead of time. Assets are a classic example.

    However, Assets can be emulated using a Controller, if you really wish to server them dynamically.

    Besides, Plezi is oriented towards being a good back-end for your SPA (Single Page Application), not an HTML / CSS / JS renderinging machine.

* No development mode. If you want to restart the application automatically whenever you update the code, there are probably plenty of gems that will take care of that.

Do notice, Websockets require Iodine (the server), since (currently) it's the only Ruby server known to support native Websockets using a Websocket Callback Object.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plezi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plezi

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boazsegev/plezi.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
