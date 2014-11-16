
module Anorexic

	# File and Object Caching for Anorexic
	module_function
	# contains the cached data, in the format: CACHE_STORE["filename"] = CacheObject
	CACHE_STORE = {}
	LOCK = Mutex.new
	CACHABLE = %w{haml css js html scss sass coffee txt xml json yaml rb}

	# this class holds cached objects (data and modification times)
	class CacheObject
		# Cached attributes
		attr_accessor :data, :mtime

		# initialize a Cached object
		def initialize d = nil, t = Time.now
			@data, @mtime = d, t
		end
	end

	# load the file from the cache (if exists) or the file system (if it doesn't)
	def load_file filename
		return CACHE_STORE[filename].data if CACHE_STORE[filename]
		reload_file filename
	end
	# review a file's modification time
	def file_mtime filename
		return CACHE_STORE[filename].mtime if CACHE_STORE[filename]
		File.mtime(filename)
	end

	# force a file onto the cache (only if it is cachable - otherwise will load the file but will not cache it).
	def reload_file filename
		if CACHABLE.include? filename.match(/\.([^\.]+)$/)[1]
			LOCK.synchronize { CACHE_STORE[filename] = CacheObject.new( IO.read(filename) , File.mtime(filename)) }
			return CACHE_STORE[filename].data
		else
			return IO.read(filename)
		end
	end
	# places data into the cache, and attempts to save the data to a file name.
	def save_file filename, data
		cache_data filename, data
		begin
			raise 'no-write'
			IO.write filename, data
		rescue Exception => e
			Anorexic.warn("File couldn't be written (#{filename}) - file system error?")
		end
		data
	end
	# places data into the cache, under a file name
	def cache_data filename, data
		LOCK.synchronize { CACHE_STORE[filename] = CacheObject.new( data )  }
		data
	end

	# returns true if the file exists on disk or in the cache.
	def file_exists? filename
		return true if CACHE_STORE[filename]
		File.exists?(filename)
	end

	# refreshes the cache
	def refresh_cache
		LOCK.synchronize do
			CACHE_STORE.each do |k,v|
				if File.exists?(k) && v.mtime < File.mtime(k)
					v.data = IO.read k ; v.mtime = File.mtime(k)
				end
			end
		end
		true
	end
end
