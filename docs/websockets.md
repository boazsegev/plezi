# Plezi Websockets

Inside Plezi's core code is the pure Ruby HTTP and Websocket Server (and client) that comes with [Iodine](https://github.com/boazsegev/iodine), a wonderful little server that supports an effective websocket functionality both as a server and as a client.

Plezi augmentes Iodine by adding auto-Redis support for scaling and automatically mapping each Contoller Class as a broadcast channel and each server instance to it's own unique channel - allowing unicasting to direct it's message at the target connection's server and optimizing resources.

Reading through this document, you should remember that Plezi's websocket connections are object oriented - they are instances of Controller classes that answer a specific url/path in the Plezi application. More than one type of connection (Controller instance) could exist in the same application.

## A short intro to Websockets (skip this if you can)

In a very broad sense, Websockets allow the browser communicate with the server in a bi-directional manner. This overcomes some of the limitations imposed by Http alone, allowing (for instance) to push real-time data, such as chat messages or stock quotes, directly to the browser.

In essense, while Http's worflow is a call and response (the browser "calls", the server "responds"), Websockets is a conversation, sometimes with long pauses, where both sides can speak whenever they feel the need to.

This, in nature, requires that both sides of the conversation establish a common language... this part is pretty much up to each application.

It's easy to think about it this way:

the browsers starts a call-response sequence. All websocket connections start as Http call-response. The browser shouts over the internet "I want to start a conversation".

The server responds: "Sure thing, let's talk".

Than they start their websocket conversation, keeping the connection between them open. The server can also answer "no thanks", but than there's no websocket connection and the Http connection will probably die out (unless it's Http/2).

### initiating a websocket connection

The websocket connection is initiated by the browser using `Javascript`.

The `Javascript` should, in most applications, handle the following three Websocket `Javascript` events:

- `onopen`: a connection was established.
- `onmessage`: a message was received through the connection.
- `onclose`: an open connection had closed, or a connection initiated couldn't be established.

Here is a common enough example of a script designed to open a websocket:

```javascript

websocket = NaN

function init_websocket()
{
  //  no need to renew socket connection if it's open
  if(websocket && websocket.readyState == 1) return true;

  // initiate the url for the websocket... this is a bit of an overkill,
  // but it will allow you to copy & paste decent code
  var ws_uri = (window.location.protocol.match(/https/) ? 'wss' : 'ws') + '://' + window.document.location.host

  // initiate a new websocket connection
  websocket = new WebSocket(ws_uri);

  // define the onopen event callback
  websocket.onopen = function(e) {
      // what do you want to do now?
      // maybe send a message?
      websocket.send("Hello there!");
      // a common practice is to use JSON
      var msg = JSON.stringify({msg: 'chat', data: 'Hello there!'})
      websocket.send(msg);
  };

  // define the onclose event callback
  websocket.onclose = function(e) {
    // you probably want to reopen the websocket if it closes
    setTimeout( init_websocket, 100 );
  };

  // define the onmessage event callback
  websocket.onmessage = function(e) {
    // what do you want to do now?
    console.log(e.data);
    // to use JSON, use:
    // msg = JSON.parse(e.data);
  };
}

init_websocket();

```

As you can tell from reading through the code, this means that the browser will open a new connection to the server, using the websocket protocol.

In our example the script sent a message: `"Hello there!"`. It's up to your code to decide what to do with the data it receives, be it using JSON or raw data.

When data comes in from the browser, the `onmessage` event is raised. It's up to your script to decypher the meaning of that message within the `onmessage` callback.

###

No we know a bit about what Websockets are and how to initiate a websocket connection to send and receive data... next up, how to get Plezi to answer (or refuse) websocket requests?

## Communicating between the application and clients

(todo: write documentation)


## Communicating between different Websocket clients

Plezi supports three models of communication:

### General websocket communication.

  When using this type of communication, it is expected that each connection's controller provide a protected instance method with a name matching the event name and that this method will accept, as arguments, the data sent with the event.

  This type of communication includes:

  - **Multicasting**:

      Use `multicast` to send an event to all the websocket connections currently connected to the application (including connections on other servers running the application, if Redis is used).

  - **Unicasting**:

      Use `unicast` to send an event to a specific websocket connection.

      This uses a unique UUID that contains both the target server's information and the unique connection identifier. This allows a message to be sent to any connected websocket across multiple application instances when using Redis, minimizing network activity and server load as much as effectively possible.

      Again, exacly like when using multicasting, any connection targeted by the message is expected to implemnt a method matching the name of the event, which will accept (as arguments) the data sent.

For instance, when using:

      unicast target_id, :event_name, "string", and: :hash

The receiving websocket controller is expected to have a protected method named `event_name` like so:

```ruby
class MyController
    #...
    protected
    def event_name str, options_hash
        #...
    end
end
```

### Object Oriented communication:

Use `broadcast` or `Controller.broadcast` to send an event to a all the websocket connections that are managed by a specific Controller class.

The controller is expected to provide a protected instance method with a name matching the event name and that this method will accept, as arguments, the data sent with the event.

The benifit of using this approach is knowing exacly what type of objects handle the message - all the websocket connections receiving the message will be members (instances) of the same class.

For instance, when using:

      MyController.broadcast :event_name, "string", and: :hash

The receiving websocket controller is expected to have a protected method named `event_name` like so:

```ruby
class MyController
    #...
    protected
    def event_name str, options_hash
        #...
    end
end
```

### Identity oriented communication (future design - API incomplete):

Identity oriented communication will only work if Plezi's Redis features are enabled. To enable Plezi's automatic Redis features (such as websocket scaling automation, Redis Session Store, etc'), use:

      ENV['PL_REDIS_URL'] ||=  "redis://user:password@redis.example.com:9999"

Use `#register_as` or `#notify(identity, event_name, data)` to send make sure a certain Identity object (i.e. an app's User) receives notifications either in real-time (if connected) or the next time the identity connects to a websocket and identifies itself using `#register_as`.

Much like General Websocket Communication, the identity can call `#register_as` from different Controller classes and it is expected that each of these Controller classes implement the necessary methods.

It is a good enough practice that an Identity based websocket connection will utilize the `#on_open` callback to authenticate and register an identity. For example:

```ruby
class MyController
   #...
   def on_open
       user = suthenticate_user
       close unless user
       register_as user.id
   end

   protected

   def event_name str, options_hash
       #...
   end
end
```

It is recommended that the authentication and registration are split into two different events - the `pre_connect` for authentication and the `on_open` for registration - since, as a matter of security, it is better to prevent someone from entering (not establishing a websocket connection) than throwing them out (closing the connection within the `on_open` event).

Sending messages to the identity is similar to the other communication API methods. For example:

      notify user_id, :event_name, "string data", hash: :data, more_hash: :data

As expected, it could be that an Identity will never revisit the application, and for this reason limits must be set as to how long the "mailbox" should remain alive in the database when it isn't acessed by the Identity.

At the moment, the API for managing this timeframe is yet undecided, but it seems that Plezi will set a default of 21 days and that this default could be customized by introducing a Controller specific _class_ method that will return the number of seconds after which a mailbox should be expunged unless accessed. i.e.:

```ruby
class MyController
   #...
   def self.message_store_lifespan
       1_814_400 # 21 days
   end
end
```


(todo: write documentation)

