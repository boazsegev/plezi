# Plezi - a real-time web application framework for Ruby

Are microservices on your mind? Do you dream of easy websockets, RESTful AJAX or a small and consice web application that could fit in a few lines of code?

Welcome to your new home with [plezi.io](http://www.plezi.io).

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

* No native session support. Rack has a lot of session support options. Pick one.

* No asset pipeline.

  Assets can be emulated using a Controller, if you wish, but they should probably be baked and served as static files when possible.

* No Ruby based static file service - static file serving should be left to the Server, not the application.

  Plezi's default server, Iodine, provides a poor-man's file server that is easy to set up.

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
