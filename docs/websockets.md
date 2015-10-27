# Plezi Websockets

Inside Plezi's core code is the pure Ruby HTTP and Websocket Server (and client) that comes with [Iodine](https://github.com/boazsegev/iodine), a wonderful little server that supports an effective websocket functionality both as a server and as a client.

Plezi augmentes Iodine by adding auto-Redis support for scaling and automatically mapping each Contoller Class as a broadcast channel and each server instance to it's own unique channel - allowing unicasting to direct it's message at the target connection's server and optimizing resources.

Reading through this document, you should remember that Plezi's websocket connections are object oriented - they are instances of Controller classes that answer a specific url/path in the Plezi application. More than one type of connection (Controller instance) could exist in the same application.

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

* Identity oriented communication:

(todo: write documentation)

# An object oriented websocket 


