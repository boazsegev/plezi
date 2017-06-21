# Plezi - a real-time web application framework for Ruby

[![Gem Version](https://badge.fury.io/rb/plezi.svg)](https://badge.fury.io/rb/plezi)
[![Inline docs](http://inch-ci.org/github/boazsegev/plezi.svg?branch=master)](http://www.rubydoc.info/github/boazsegev/plezi/master/frames)
[![GitHub](https://img.shields.io/badge/GitHub-Open%20Source-blue.svg)](https://github.com/boazsegev/plezi)

Are microservices on your mind? Do you dream of a an SPA that's easy to scale? Did you wonder if you could write a whole Websockets, RESTful AJAX back-end with just a few lines of code (business logic not included)?

Welcome to your new home with [plezi.io](http://www.plezi.io), the Ruby real-time framework that assumes the business logic is *seperate* from the web service logic.

## Short and Sweet

Here's a short and sweet Websocket chatroom example you can cut and paste into the `irb` terminal.

Notice how the HTML/Javascript client is the longest part ;-)

```ruby
# Server
require 'plezi'
class MyChatroom
  # HTTP
  def index
    CLIENT_AS_STRING
  end
  # Websocket automatic routing of JSON events to method names.
  @auto_dispatch = true
  # i.e., this will be called when we receive the JSON: event: :chat_auth, ...
  def chat_auth event
    if params[:nickname] || (::ERB::Util.h(event[:nickname]) == "Me")
      # Not allowed (double authentication / reserved name)
      close
      return
    end
    # set our ID and subscribe to the chatroom's channel
    params[:nickname] = ::ERB::Util.h event[:nickname]
    subscribe channel: :chat
    publish channel: :chat, message: {event: 'chat_login',
                           name: params[:nickname],
                           user_id: id}.to_json
    # if we return an object, it will be sent to the websocket client.
    nil
  end

  def chat_message msg
    # prevent false identification
    msg[:name] = params[:nickname]
    msg[:user_id] = id
    publish channel: :chat, message: msg.to_json
    nil
  end
  # On Websocket closed.
  def on_close
    publish channel: :chat, message: {event: 'chat_logout',
                           name: params[:nickname],
                           user_id: id}.to_json
    # no need to unsubscribe, it's automatically performed for us.
  end
end

Plezi.route "/javascripts/client.js", :client
Plezi.route '/(:nickname)', MyChatroom

# Client
CLIENT_AS_STRING = <<EOM
<!DOCTYPE html>
<html>
<title>The Chatroom Example</title>
<head>
  <script src='/javascripts/client.js'></script>
  <script>
  // the client object
  client = NaN;
  // A helper function to print messages to a DIV called "output"
  function print2output(text) {
      var o = document.getElementById("output");
      o.innerHTML = "<li>" + text + "</li>" + o.innerHTML
  }
  // A helper function to disable a text input called "input"
  function disable_input() {
      document.getElementById("input").disabled = true;
  }
  // A helper function to enable a text input called "input"
  function enable_input() {
      document.getElementById("input").disabled = false;
      document.getElementById("input").placeholder = "Message";
  }
  // A callback for when our connection is established.
  function connected_callback(event) {
      enable_input();
      print2output("System: " + client.nickname + ", welcome to the chatroom.");
  }
  // creating the client object and connecting
  function connect2chat(nickname) {
      // create a global client object. The default connection URL is the same as our Controller's URL.
      client = new PleziClient();
      // save the nickname
      client.nickname = nickname;
      // Set automatic reconnection. This is great when a laptop or mobile phone is closed.
      client.autoreconnect = true
          // handle connection state updates
      client.onopen = function(event) {
          client.was_closed = false;
          // when the connection opens, we will authenticate with our nickname.
          // This isn't really authenticating anything, but we can add security logic later.
          client.emit({
              event: "chat_auth",
              nickname: client.nickname
          }, connected_callback);
      };
      // handle connection state updates
      client.onclose = function(event) {
          if (client.was_closed) return;
          print2output("System: Connection Lost.");
          client.was_closed = true;
          disable_input();
      };
      // handle the chat_message event
      client.chat_message = function(event) {
          if(client.user_id == event.user_id)
            event.name = "Me";
          print2output(event.name + ": " + event.message)
      };
      // handle the chat_login event
      client.chat_login = function(event) {
          if(!client.id && client.nickname == event.name)
            client.user_id = event.user_id;
          print2output("System: " + event.name + " logged into the chat.")
      };
      // handle the chat_logout event
      client.chat_logout = function(event) {
          print2output("System: " + event.name + " logged out of the chat.")
      };
      return client;
  }
  // This will be used to send the text in the `input` to the websocket.
  function send_text() {
      // get the text
      var msg = document.getElementById("input").value;
      // clear the input field
      document.getElementById("input").value = '';
      // no client? the text is the nickname.
      if (!client) {
          // connect to the chat
          connect2chat(msg);
          // prevent default action (form submission)
          return false;
      }
      // there is a client, the text is a chat message.
      client.emit({
          event: "chat_message",
          message: msg
      });
      // prevent default action (avoid form submission)
      return false;
  }
  </script>
    <style>
    html, body {width:100%; height: 100%; background-color: #ddd; color: #111;}
    h3, form {text-align: center;}
    input {background-color: #fff; color: #111; padding: 0.3em;}
    </style>
</head><body>
  <h3>The Chatroom Example</h3>
    <form id='form' onsubmit='send_text(); return false;'>
        <input type='text' id='input' name='input' placeholder='nickname'></input>
        <input type='submit' value='send'></input>
    </form>
    <script> $('#form')[0].onsubmit = send_text </script>
    <ul id='output'></ul>
</body>
</html>
EOM
exit
```

## What does Plezi have to offer?

Plezi is a Rack based framework with support for native (server side implemented) Websockets.

Plezi will provide the following features over plain Rack:

* Object Oriented (M)VC design, BYO (Bring Your Own) models.

* A case sensitive RESTful router to map HTTP requests to your Controllers.

    Non-RESTful public Controller methods will be automatically published as valid HTTP routes, allowing the Controller to feel like an intuitive "virtual folder" with RESTful features.

* Raw Websocket connections.

    Websocket connections are now route specific, routing the websocket callbacks to the Controller that "owns" the route.

* Auto-Dispatch (optional) to automatically map JSON websocket "events" to Controller functions (handlers).

* Native Pub/Sub provided by [Iodine](https://github.com/boazsegev/iodine).

* Automatic (optional) scaling using Redis.

* An extensible template rendering abstraction engine, supports Slim, Markdown (using RedCarpet) and ERB out of the box.

* Belated, extensible, asset baking (optional fallback for when the application's assets weren't baked before deployment).

    It's possible to define an asset route (this isn't the default) to bake assets on the fly.

    In production mode, assets will be baked directly to the public folder supplied to Iodine (the web server) with a matching path. This allows the static file server to serve future requests.

    However, during development, baking will save the files to the asset's folder, so that the Ruby layer will be the one serving the content and dynamic updates could be supported.

Things Plezi **doesn't** do (anymore / ever):

* No DSL. Plezi won't clutter the global namespace.

* No application logic inside.

    Conneting your application logic to Plezi is easy, however, application logic should really be *independent*, **reusable** and secure. There are plenty of gems that support independent application logic authoring.

* No native session support. If you *must* have session support, Rack middleware gems provide a lot of options. Pick one... However...

    Session have been proved over and over to be insecure and resource draining.

    Why use a session when you can save server resources and add security by using a persistent connection, i.e. a Websocket? If you really feel like storing unimportant stuff, why not use javascript's `local storage` on the *client's* machine? (if you need to save important stuff, you probably shouldn't be using sessions anyway).

* No code refresh / development mode. If you want to restart the application automatically whenever you update the code, there are probably plenty of gems that will take care of that.

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

A new application (default applications include a simple chatroom demo):

     $  plezi new app_name

A simple hello world from `irb`:

```ruby
require 'plezi'

class HelloWorld
  def index
    "Hello World!"
  end
end

Plezi.route '*', HelloWorld

exit # <= if running from terminal, this will start the server
```

## Documentation

Plezi is fairly well documented.

Documentation is available both in the forms of tutorials and explanations available on the [plezi.io website](http://www.plezi.io) as well as through [the YARD documentation](http://www.rubydoc.info/gems/plezi).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boazsegev/plezi.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
