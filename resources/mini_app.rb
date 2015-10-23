# encoding: UTF-8

## Set working directory, load gems and create logs
	## Using pathname extentions for setting public folder
	require 'pathname'
	## Set up root object, it might be used by the environment and\or the plezi extension gems.
	Root ||= Pathname.new(File.dirname(__FILE__)).expand_path

	## If this app is independant, use bundler to load gems (including the plezi gem).
	## otherwise, use the original app's Gemfile and start Plezi's Rack mode.
	require 'bundler'
	Bundler.require(:default, ENV['ENV'].to_s.to_sym)

	## make sure all file access and file loading is relative to the application's root folder
	# Dir.chdir Root.to_s
	## load code from a subfolder called 'app'
	# Dir[File.join "{app}", "**" , "*.rb"].each {|file| load File.expand_path(file)}
	## OR load code from all the ruby files in the main forlder (subfolder inclussion will fail on PaaS)
	# Dir[File.join File.dirname(__FILE__), "*.rb"].each {|file| load File.expand_path(file) unless file == __FILE__}

	## Uncomment to create a log file
	# Iodine.logger = Logger.new File.expand_path(Root.join('server.log').to_s)

# # Options for Scaling the app (across processes or machines):
	# # uncomment to set up forking for 3 more processes (total of 4).
	# Iodine.processes = 4
	#
	# # Redis scaling
	# Plezi::Settings.redis_channel_name = 'appsecret'
	# ENV['PL_REDIS_URL'] ||= ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'] || ENV['REDISTOGO_URL'] || "redis://username:password@my.host:6389"
	#
	# # Consider setting a common session token for Redis supported sessions.
	# Iodine::Http.session_token = 'appname_uui'


# The basic appname controller, to get you started
class MyController
	# HTTP
	def index
		# return response << "Hello World!" # for a hello world app
		render :welcome
	end
	# Websockets
	def on_message data
		data = ERB::Util.html_escape data
		print data
		broadcast :print, data		
	end
	def on_open
		print 'Welcome!'
		broadcast :print, "Somebody joind us :-)"
	end
	def on_close
		broadcast :print, "Somebody left us :-("
	end

	protected

	def print data
		response << data
	end
end


# change some of the default settings here.
host :default,
	# public: Root.join('public').to_s,
	assets: Root.join('assets').to_s,
	templates: Root.join('templates').to_s

# # Optional stuff:
	# # I18n re-write, i.e.: `/en/home` will be rewriten as `/home`, while setting params[:locale] to "en"
	# route "/:locale{#{I18n.available_locales.join "|"}}/*" , false if defined? I18n
	#
	# # OAuth2 - Facebook / Google authentication
	# require 'plezi/oauth'
	# ENV["FB_APP_ID"] ||= "app id"; ENV["FB_APP_SECRET"] ||= "secret"; ENV['GOOGLE_APP_ID'] = "app id"; ENV['GOOGLE_APP_SECRET'] = "secret"
	# create_auth_shared_route do |service_name, auth_token, remote_user_id, remote_user_email, remote_response|
	#         # ...callback for authentication.
	#         # This callback should return the app user object or false
	#         # This callback has access to the controller's methods (request, cookies, response, etc')
	# end

# Add your routes and controllers by order of priority.
route '/(:id)', MyController

