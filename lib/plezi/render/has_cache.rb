module Plezi
  module Base
    # Provides a thread-safe caching engine
    module HasCache
      # initializes the cache
      def self.extended(base)
        base.instance_variable_set :@_lock, Mutex.new
        base.instance_variable_set :@_cache, {}.dup
      end

      # Stores data in the cache
      def store(key, value)
        @_lock.synchronize { @_cache[key] = value }
      end
      alias []= store
      # Retrieves data form the cache
      def get(key)
        @_lock.synchronize { @_cache[key] }
      end
      alias [] get
    end
    # Provides thread-specific caching engine, allowing lockless cache at the expenss of memory.
    module HasStore
      # Stores data in the cache
      def store(key, value)
        (Thread.current[(@_chache_name ||= object_id.to_s(16))] ||= {}.dup)[key] = value
      end
      alias []= store
      # Retrieves data form the cache
      def get(key)
        (Thread.current[(@_chache_name ||= object_id.to_s(16))] ||= {}.dup)[key]
      end
      alias [] get
    end
  end
end
