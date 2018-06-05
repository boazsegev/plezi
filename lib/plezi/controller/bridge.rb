module Plezi
  module Base
    # This module bridges between the Plezi Controller and the Iodine::Connection .
    module Bridge
      CONTROLLER_NAME = "plezi.controller".to_sym
      CLIENT_NAME = "@_pl__client".to_sym # don't rename without updating Controller
      # returns a client's controller
      def controller client
        client.env[CONTROLLER_NAME]
      end

      # called when the callback object is linked with a new client
      def on_open client
        c = controller(client)
        c.instance_variable_set(CLIENT_NAME, client)
        if client.protocol == :sse
          c.on_sse
        else
          c.on_open
        end
      end
      # called when data is available
      def on_message client, data
         controller(client).on_message(data)
      end
      # called when the server is shutting down, before closing the client
      # (it's still possible to send messages to the client)
      def on_shutdown client
         controller(client).on_shutdown
      end
      # called when the client is closed (no longer available)
      def on_close client
         controller(client).on_close
      end
      # called when all the previous calls to `client.write` have completed
      # (the local buffer was drained and is now empty)
      def on_drained client
         controller(client).on_drained
      end
      extend self
    end
  end
end
