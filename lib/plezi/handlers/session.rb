module Plezi
	module Base
		module SessionStorage
			module_function
			# returns a session object
			def fetch id
				@session_cache[id] || (@session_cache[id] = Plezi::Session.new(id))
			end
			@session_cache = {}
		end
	end
	# A hash like interface for storing request session data.
	# The store must implement: store(key, value) (aliased as []=);
	# fetch(key, default = nil) (aliased as []);
	# delete(key); clear;
	class Session

		# The session's lifetime in seconds = 5 days. This is only true when using the built in support for the Redis persistent storage.
		SESSION_LIFETIME = 432_000
		# called by the Plezi framework to initiate a session with the id requested
		def initialize id
			@id = id
			if id && (conn=Plezi.redis)
				@data=conn.hgetall(id)
			end
			@data ||= {}
		end
		# Get a key from the session data store. If a Redis server is supplied, it will be used to synchronize session data.
		#
		# Due to scaling considirations, all keys will be converted to strings, so that `"name" == :name` and `1234 == "1234"`.
		# If you store two keys that evaluate as the same string, they WILL override each other.
		def [] key
			key = key.to_s
			if conn=Plezi.redis
				conn.expire @id, SESSION_LIFETIME
				@data[key] = conn.hget @id, key
			end
			@data[key]
		end
		alias :fetch :[]

		# Stores a key in the session's data store. If a Redis server is supplied, it will be used to synchronize session data.
		#
		# Due to scaling considirations, all keys will be converted to strings, so that `"name" == :name` and `1234 == "1234"`.
		# If you store two keys that evaluate as the same string, they WILL override each other.
		def []= key, value
			key = key.to_s
			if (conn=Plezi.redis)
				conn.hset @id, key, value
				conn.expire @id, SESSION_LIFETIME
			end
			@data[key] = value
		end
		alias :store :[]=

		# @return [Hash] returns a shallow copy of the current session data as a Hash.
		def to_h
			if (conn=Plezi.redis) 
				conn.expire @id, SESSION_LIFETIME
				return (@data=conn.hgetall(@id)).dup
			end
			@data.dup
		end

		# Removes a key from the session's data store.
		def delete key
			key = key.to_s
			if (conn=Plezi.redis)
				conn.expire @id, SESSION_LIFETIME
				conn.hdel @id, key
			end				
			@data.delete key	
		end

		# Clears the session's data.
		def clear
			if (conn=Plezi.redis)
				conn.del @id
			end
			@data.clear
		end
	end
	GRHttp::SessionManager.storage = Plezi::Base::SessionStorage
end
