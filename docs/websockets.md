# Plezi Websockets

Inside Plezi's core code is the pure Ruby HTTP and Websocket Server (and client) that comes with [Iodine](https://github.com/boazsegev/iodine), a wonderful little server that supports an effective websocket functionality both as a server and as a client.

Plezi augmentes Iodine by adding auto-Redis support for scaling and automatically mapping each Contoller Class as a broadcast channel and each server instance to it's own unique channel - allowing unicasting to direct it's message at the target connection's server and optimizing resources.

Reading through this document, you should remember that Plezi's websocket connections are object oriented - they are instances of Controller classes that answer a specific url/path in the Plezi application. More than one type of connection (Controller instance) could exist in the same application.

# Communicating between different Websocket clients

Plezi supports three models of communication:

* General websocket communication.

    When using this type of communication, it is expected that each connection's controller provide a protected instance method with a name matching the event name and that this method will accept, as arguments, the data sent with the event.

    This type of communication includes:

    - **Multicasting**:

        Use `multicast` to send an event to all the websocket connections currently connected to the application (including connections on other servers running the application, if Redis is used).

    - **Unicasting**:

        Use `unicast` to send an event to a specific websocket connection.

        This uses a unique UUID that contains both the target server's information and the unique connection identifier. This allows a message to be sent to any connected websocket across multiple application instances when using Redis, minimizing network activity and server load as much as effectively possible.

        Again, exacly like when using multicasting, any connection targeted by the message is expected to implemnt a method matching the name of the event, which will accept (as arguments) the data sent.

        For instance, when using:

               `unicast target_id, :event_name, "string", and: :hash`
   
        The receiving websocket controller is expected to have a protected method named `event_name` like so:

               ```ruby
               protected
               def event_name str, options_hash
               end
               ```

* Object Oriented communication:

    Use `broadcast` or `Controller.broadcast` to send an event to a all the websocket connections that are managed by a specific Controller class.

    The controller is expected to provide a protected instance method with a name matching the event name and that this method will accept, as arguments, the data sent with the event.

    The benifit of using this approach is knowing exacly what type of objects handle the message - all the websocket connections receiving the message will be members (instances) of the same class.

    For instance, when using:

           `MyController.broadcast :event_name, "string", and: :hash`

    The receiving websocket controller is expected to have a protected method named `event_name` like so:

           ```ruby
           class MyController
               #...
               protected
               def event_name str, options_hash
               end
           end
           ```

* Identity oriented communication (future design - API incomplete):

	Identity oriented communication will only work if Plezi's Redis features are enabled. To enable Plezi's automatic Redis features (such as websocket scaling automation, Redis Session Store, etc'), use:

	     `ENV['PL_REDIS_URL'] ||=  "redis://user:password@redis.example.com:9999"`

    Use `#register_as` or `#notify(identity, event_name, data)` to send make sure a certain Identity object (i.e. an app's User) receives notifications either in real-time (if connected) or the next time the identity connects to a websocket and identifies itself using `#register_as`.

    Much like General Websocket Communication, the identity can call `#register_as` from different Controller classes and it is expected that each of these Controller classes implement the necessary methods.

    It is suggested that an Identity based websocket connection will utilize the `#on_open` callback to authenticate and register an identity. For example:

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

    Sending messages to the identity is similar to the other communication API methods. For example:

        `notify user_id, :event_name, "string data", hash: :data, more_hash: :data`

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

# An object oriented websocket 


