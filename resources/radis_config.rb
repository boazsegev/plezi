# encoding: UTF-8

if defined? Radis

	# ## Anorexic Redis Automation
	# ## ====
	# ##
	# ## sets up Anorexic to use Radis broadcast.
	# ## this is less recommended then writing your own tailored solution
	# ##
	# ## If Anorexic Redis Automation is enabled:
	# ## Anorexic creates is own listening thread for each Controller class that broadcasts using Redis.
	# ## (using the Controller.redis_connection and Controller.redis_channel_name class methods)
	# ##
	# ## this overrides the default Controller#broadcast method which is very powerful but
	# ## is limited to one process.
	# ##
	# ENV['AN_REDIS_URL'] = ENV['REDISCLOUD_URL'] ||= ENV["REDISTOGO_URL"] ||= "redis://username:password@my.host:6389"


	# ## create a listening thread - rewrite the following code for your own Redis tailored solution.
	# ##
	# ## the following is only sample code for you to change:
	# RADIS_CHANNEL = appsecret
	# RADIS_URI = URI.parse(ENV['REDISCLOUD_URL'] || "redis://username:password@my.host:6389")
	# RADIS_CONNECTION = Redis.new(host: RADIS_URI.host, port: RADIS_URI.port, password: RADIS_URI.password)
	# RADIS_THREAD = Thread.new do
	# 	Redis.new(host: RADIS_URI.host, port: RADIS_URI.port, password: RADIS_URI.password).subscribe(RADIS_CHANNEL) do |on|
	# 		on.message do |channel, msg|
	# 			msg = JSON.parse(msg)
	# 			# do stuff
	# 		end
	# 	end
	# end
end