
module Plezi

	module_function

	def max_threads
		@max_threads ||= 8
	end
	def max_threads=val
		@max_threads = val
	end

	# Sets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
	#
	# Although memory will be allocated for the latest TCP/IP frame,
	# this allows the websocket to disconnect if the incoming expected message size exceeds the allowed maximum size.
	#
	# If the sessage size limit is exceeded, the disconnection will be immidiate as an attack will be assumed. The protocol's normal disconnect sequesnce will be discarded.
	def ws_message_size_limit=val
		GRHttp.ws_message_size_limit = val
	end
	# Gets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
	def ws_message_size_limit
		GRHttp.ws_message_size_limit
	end

end

