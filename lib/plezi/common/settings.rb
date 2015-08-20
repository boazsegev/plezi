
module Plezi

	# This module allows you to set some of the Plezi framework's settings.
	module Settings

		module_function

		# The maximum number of threads that are used for concurrency.
		def max_threads
			@max_threads ||= 30
		end
		# Sets the maximum number of threads that are used for concurrency.
		def max_threads=val
			@max_threads = val
		end

		# The number of second between pings automatically sent by an open websocket.
		def autoping
			@autoping ||= 45
		end
		# Sets the number of second between pings automatically sent by an open websocket.
		#
		# Set to nil or false to disable auto-pinging.
		def autoping=val
			@autoping = 45
		end

		# Sets the Redis Channel Name.
		def redis_channel_name=val
			return false unless defined? Redis
			raise "Can't change channel name after Redis subscription had been initiated." if @redis
			@redis_channel_name = val
		end
		# Returns the Redis Channel Name used by this app.
		# @return [String]
		def redis_channel_name
			@redis_channel_name ||= 'Plezi_Redis_Channel'
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

		# This Server's UUID, for Redis and unicasting identification.
		def uuid
			@uuid ||= SecureRandom.uuid
		end
	end
end

