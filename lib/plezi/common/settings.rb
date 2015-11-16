
module Plezi

	# This module allows you to set some of the Plezi framework's settings.
	module Settings

		module_function

		# Sets the Redis Channel Name.
		def redis_channel_name=val
			return false unless defined? Redis
			raise "Can't change channel name after Redis subscription had been initiated." if @redis
			@redis_channel_name = val
		end
		# Returns the Redis Channel Name used by this app.
		# @return [String]
		def redis_channel_name
			@redis_channel_name ||= "#{File.basename($0, '.*')}_redis_channel"
		end

		# Sets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
		#
		# Although memory will be allocated for the latest TCP/IP frame,
		# this allows the websocket to disconnect if the incoming expected message size exceeds the allowed maximum size.
		#
		# If the sessage size limit is exceeded, the disconnection will be immidiate as an attack will be assumed. The protocol's normal disconnect sequesnce will be discarded.
		def ws_message_size_limit=val
			Iodine::Http::Websockets.message_size_limit = val
		end
		# Gets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
		def ws_message_size_limit
			Iodine::Http::Websockets.message_size_limit
		end

		# This Server's UUID, for Redis and unicasting identification.
		def uuid
			@uuid ||= SecureRandom.uuid
		end


		# # # The following was discarded because benchmarks show the difference is negligible
		# # Get the cache refresh directive for the {#cache_needs_update?} implementation. Defaults to ENV['ENV'] != 'production'
		# def allow_cache_update?
		# 	Plezi.allow_cache_update?
		# end
		# # Set the cache refresh directive for the {#cache_needs_update?} implementation. Defaults to ENV['ENV'] != 'production'
		# def allow_cache_update= val
		# 	Plezi.allow_cache_update = val
		# end
		# # **Update**: up until now, Plezi would allow refresh any cached assets ot templated when they are edited. This file review is usually a waste of resources after deployment, since the files never get updated in production environments. Plezi now supports a two new settings options: `Plezi.allow_cache_update?` and `Plezi.allow_cache_update=` which will dictate if file review should be performed after caching. The default is now set to AVOID file reviews for production environments (`ENV['ENV'] || ENV['RACK_ENV'] != 'production'`).
	end
end