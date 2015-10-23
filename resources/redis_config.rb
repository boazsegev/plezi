# encoding: UTF-8

if defined? Redis

	Plezi::Settings.redis_channel_name = 'appsecret'

	# ## Plezi Redis Automation
	# ## ====
	# ##
	# ## Sets up Plezi to use Radis broadcast.
	# ##
	# ## If Plezi Redis Automation is enabled:
	# ## Plezi creates is own listening thread that listens for each Controller class that broadcasts using Redis.
	# ## (using the Controller.redis_connection and Controller.redis_channel_name class methods)
	# ##
	# ## Only one thread will be created and initiated during startup (dynamically created controller routes might be ignored).
	# ##
	# ## this overrides the default Controller#broadcast method which is very powerful but
	# ## is limited to one process.
	# ##
	# ENV['PL_REDIS_URL'] ||= ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'] || ENV['REDISTOGO_URL'] || "redis://username:password@my.host:6389"


	# ## OR, write your own custom Redis Automation here
	# ## ====
	# ##
	# ## create a listening thread - rewrite the following code for your own Redis tailored solution.
	# ##
	# ## the following is only sample code for you to change:
	# RADIS_CHANNEL = 'appsecret'
	# RADIS_URI = URI.parse(ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'] || "redis://username:password@my.host:6389")
	# RADIS_CONNECTION = Redis.new(host: RADIS_URI.host, port: RADIS_URI.port, password: RADIS_URI.password)
	# RADIS_THREAD = Thread.new do
	# 	Redis.new(host: RADIS_URI.host, port: RADIS_URI.port, password: RADIS_URI.password).subscribe(RADIS_CHANNEL) do |on|
	# 		on.message do |channel, msg|
	# 			msg = JSON.parse(msg)
	# 			# do stuff, i.e.:
	# 			# Plezi.run_async(msg) { |m| Plezi.info m.to_s }
	# 		end
	# 	end
	# end
end