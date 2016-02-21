module Plezi

	module Base

			# Used to emulate the Redis connection when the Identoty API
			# is used on a single process with no Redis support.
			module RedisEmultaion
				public
				def lrange key, first, last = -1
					sync do
						return [] unless @cache[key]
						@cache[key][first..last] || []
					end
				end
				def llen key
					sync do
						return 0 unless @cache[key]
						@cache[key].count
					end
				end
				def ltrim key, first, last = -1
					sync do
						return "OK".freeze unless @cache[key]
						@cache[key] = @cache[key][first..last]
						"OK".freeze
					end
				end
				def del *keys
					sync do
						ret = 0
						keys.each {|k| ret += 1 if @cache.delete k }
						ret
					end
				end
				def lpush key, value
					sync do
						@cache[key] ||= []
						@cache[key].unshift value
						@cache[key].count
					end
				end
				def lpop key
					sync do
						@cache[key] ||= []
						@cache[key].shift
					end
				end
				def lrem key, count, value
					sync do
						@cache[key] ||= []
						@cache[key].delete(value)
					end
				end
				def rpush key, value
					sync do
						@cache[key] ||= []
						@cache[key].push value
						@cache[key].count
					end
				end
				def expire key, seconds
					@warning_sent ||= Iodine.warn "Identity API requires Redis - no persistent storage!".freeze
					sync do
						return 0 unless @cache[key]
						if @timers[key]
							@timers[key].stop!
						end
						@timers[key] = (Iodine.run_after(seconds) { self.del key })
					end
				end
				def multi
					sync do
						@results = []
						yield(self)
						ret = @results
						@results = nil
						ret
					end
				end
				alias :pipelined :multi
				protected
				@locker = Mutex.new
				@cache = Hash.new
				@timers = Hash.new

				def sync &block
					if @locker.locked? && @locker.owned?
						ret = yield
						@results << ret if @results
						ret
					else
						@locker.synchronize { sync(&block) }
					end
				end

				public
				extend self
			end

		end
	end
end
