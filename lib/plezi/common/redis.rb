
module Plezi

	module Base
		module AutoRedis
			@redis_locker ||= Mutex.new
			@redis = @redis_sub_thread = nil
			module_function
			def inner_init_redis
				return false unless ENV['PL_REDIS_URL'] && defined?(::Redis)
				@redis_locker.synchronize do
					return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis # repeat the test once syncing is done.
					@redis_uri ||= URI.parse(ENV['PL_REDIS_URL'])
					@redis.quit if @redis
					@redis = ::Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password)
					raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless @redis
					@redis_sub_thread = Thread.new do
						begin
							safe_types = [Symbol, Date, Time, Encoding, Struct, Regexp, Range, Set]
							::Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password).subscribe(Plezi::Settings.redis_channel_name, Plezi::Settings.uuid) do |on|
								on.message do |channel, msg|
									begin
										data = YAML.safe_load(msg, safe_types)
										next if data[:server] == Plezi::Settings.uuid
										data[:type] = Object.const_get(data[:type]) unless data[:type].nil? || data[:type] == :all
										if data[:target]
											GRHttp::Base::WSHandler.unicast data[:target], data
										else
											GRHttp::Base::WSHandler.broadcast data
										end
									rescue => e
										GReactor.error e
									end
								end
							end
						rescue => e
							GReactor.error e
							retry
						end
					end
					@redis
				end
			end
			def get_redis
				return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis
				inner_init_redis
			end
		end
	end

	module_function

	# Reviews the Redis connection, sets it up if it's missing and returns the Redis connection.
	#
	# A Redis connection will be automatically created if the `ENV['PL_REDIS_URL']` is set.
	# for example:
	#      ENV['PL_REDIS_URL'] = ENV['REDISCLOUD_URL']`
	# or
	#      ENV['PL_REDIS_URL'] = "redis://username:password@my.host:6379"
	#
	# Accepts an optional block that will receive the Redis connection object. i.e.
	#
	#      Plezi.redis {|r| r.connected? }
	#
	# Returns the Redis object or the block's returned value (if a block is provided).
	def redis
		if r = Plezi::Base::AutoRedis.get_redis
			return (block_given? ? yield(r) : r)
		end
		false
	end
	alias :redis_connection :redis
end

