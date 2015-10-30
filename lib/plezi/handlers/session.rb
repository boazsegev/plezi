module Plezi
	module Base
		module SessionStorage
			module_function
			# returns a session object
			def fetch id
				return Plezi::Session.new(id) if Plezi.redis # avoid a local cache if Redis is used.
				Iodine::Http::SessionManager::FileSessionStorage.fetch id # use the tmp-file-session logic if Redis isn't present
			end
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
				return self
			end
			failed
		end
		# returns the session id (the session cookie value).
		def id
			@id
		end
		# Get a key from the session data store. If a Redis server is supplied, it will be used to synchronize session data.
		#
		# Due to scaling considirations, all keys will be converted to strings, so that `"name" == :name` and `1234 == "1234"`.
		# If you store two keys that evaluate as the same string, they WILL override each other.
		def [] key
			key = key.to_s
			if conn=Plezi.redis
				conn.expire @id, SESSION_LIFETIME
				return conn.hget @id, key
			end
			failed
		end
		alias :fetch :[]

		# Stores a key in the session's data store. If a Redis server is supplied, it will be used to synchronize session data.
		#
		# Due to scaling considirations, all keys will be converted to strings, so that `"name" == :name` and `1234 == "1234"`.
		# If you store two keys that evaluate as the same string, they WILL override each other.
		def []= key, value
			return delete key if value.nil?
			key = key.to_s
			if (conn=Plezi.redis)
				conn.hset @id, key, value
				conn.expire @id, SESSION_LIFETIME
				return value
			end
			failed
		end
		alias :store :[]=

		# @return [Hash] returns a shallow copy of the current session data as a Hash.
		def to_h
			if (conn=Plezi.redis) 
				conn.expire @id, SESSION_LIFETIME
				return conn.hgetall(@id)
			end
			failed
		end

		# @return [String] returns the Session data in YAML format.
		def to_s
			if (conn=Plezi.redis) 
				conn.expire @id, SESSION_LIFETIME
				return conn.hgetall(@id).to_yaml
			end
			failed
		end

		# Removes a key from the session's data store.
		def delete key
			key = key.to_s
			if (conn=Plezi.redis)
				conn.expire @id, SESSION_LIFETIME
				ret = conn.hget @id, key
				conn.hdel @id, key
				return ret
			end				
			failed
		end

		# Clears the session's data.
		def clear
			if (conn=Plezi.redis)
				return conn.del @id
			end
			failed
		end

		protected

		def failed
			raise 'Redis connection failed while using Redis Session Storage.'
			
		end
	end
	Iodine::Http::SessionManager.storage = Plezi::Base::SessionStorage
end
