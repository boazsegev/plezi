module Plezi

	# this module is the protocol (controller) for the HTTP server.
	#
	#
	# to do: implemet logging, support body types: multipart (non-ASCII form data / uploaded files), json & xml
	class Protocol

		attr_accessor :connection, :params

		def initialize connection, params
			@connection, @params = connection, params
		end

		# called when connection is initialized.
		def on_connect
		end

		# called when data is recieved.
		#
		# this method is called within a lock on the service (Mutex) - craeful from double locking.
		#
		# typically returns an Array with any data not yet processed (to be returned to the in-que)... but here it always processes (or discards) the data.
		def on_message
		end

		# # called when a disconnect is fired
		# # (socket was disconnected / service should be disconnected / shutdown / socket error)
		def on_disconnect
		end

		# called when an exception was raised
		# (socket was disconnected / service should be disconnected / shutdown / socket error)
		def on_exception
			EventMachine.remove_io connection.io
			Plezi.error e
		end
	end
end

## Heroku/extra headers info

# All headers are considered to be case-insensitive, as per HTTP Specification.
# X-Forwarded-For: the originating IP address of the client connecting to the Heroku router
# X-Forwarded-Proto: the originating protocol of the HTTP request (example: https)
# X-Forwarded-Port: the originating port of the HTTP request (example: 443)
# X-Request-Start: unix timestamp (milliseconds) when the request was received by the router
# X-Request-Id: the Heroku HTTP Request ID
# Via: a code name for the Heroku router

