module Plezi
	module Base
		module SessionStorage
			module_function
			# returns a session object
			def fetch id
				@session_cache[id] || (@session_cache[id] = Plezi::Session)
			end
			@session_cache = {}
		end
	end
	# A hash like interface for storing request session data.
	# The store must implement: store(key, value) (aliased as []=);
	# fetch(key, default = nil) (aliased as []);
	# delete(key); clear;
	class Session
		# called by the Plezi framework to initiate a session with the id requested
		def initiate id
			@id = id
			@data = {}
			(conn=Pleazi.redis) ? (@data=conn.hgetall(id)) : (@data={})
		end
		# Get a key from the session data store. If a Redis server is supplied, it will be used to synchronize session data.
		#
		# Due to scaling considirations, all keys will be converted to strings, so that `"name" == :name` and `1234 == "1234"`.
		# If you store two keys that evaluate as the same string, they WILL override each other.
		def [] key
			key = key.to_s
			if conn=Pleazi.redis
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
			if conn=Pleazi.redis
				conn.hset @id, key, value
			end
			@data[key] = value
		end
		alias :store :[]=

		# Removes a key from the session's data store.
		def delete key
			key = key.to_s
			if conn=Pleazi.redis
				conn.hdel @id, key
			end				
			@data.delete key	
		end

		# Clears the session's data.
		def clear
			conn.del @id if conn=Pleazi.redis
			@data.clear
		end
	end
end
GRHttp::SessionManager.storage = Plezi::Base::SessionStorage
