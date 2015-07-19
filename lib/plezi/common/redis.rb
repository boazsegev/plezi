
module Plezi

	module_function

	# Reviews the Redis connection, sets it up if it's missing and returns the Redis connection.
	#
	# A Redis connection will be automatically created if the `ENV['PL_REDIS_URL']` is set.
	# for example:
	#      ENV['PL_REDIS_URL'] = ENV['REDISCLOUD_URL']`
	# or
	#      ENV['PL_REDIS_URL'] = "redis://username:password@my.host:6379"
	def redis_connection
		return false unless defined?(Redis) && ENV['PL_REDIS_URL']
		return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis
		@redis_uri ||= URI.parse(ENV['PL_REDIS_URL'])
		@redis ||= Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password)
		@redis_sub_thread = Thread.new do
			Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password).subscribe(@redis_channel_name) do |on|
			begin
					on.message do |channel, msg|
						data = YAML.load(msg)
						if data[:target]
							GRHttp::Base::WSHandler.unicast data[:target], data
						else
							GRHttp::Base::WSHandler.broadcast data
						end
					end
				rescue Exception => e
					Plezi.error e
					retry
				end
			end						
		end
		raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless @redis
		@redis
	end
end

