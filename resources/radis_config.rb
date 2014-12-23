# encoding: UTF-8

if defined? Radis
	## set up Anorexic to use Radis broadcast?
	## less recommended then writing your own tailored solution
	##
	## (this overrides the default Controller#broadcast method which is normally limited to one process)
	##
	## It is better to save the Redis URL as an environment parameter then in the source code.
	# ENV['AN_REDIS_URL'] = ENV['REDISCLOUD_URL'] ||= ENV["REDISTOGO_URL"] ||= "redis://username:password@my.host:6389"

	## create a listening thread - this is for your own code.
	## Anorexic creates is own listening thread for each Controller class that broadcasts using Redis.
	## (using the Controller.redis_connection and Controller.redis_channel_name class methods)
	##
	## the following is only sample code for you to change:
	# RADIS_CHANNEL = appsecret
	# RADIS_THREAD = Thread.new do
	# 	redis_uri = URI.parse(ENV['REDISCLOUD_URL'])
	# 	Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password).subscribe(RADIS_CHANNEL) do |on|
	# 		on.message do |channel, msg|
	# 			msg = JSON.parse(msg)
	# 			# do stuff
	# 		end
	# 	end
	# end
end