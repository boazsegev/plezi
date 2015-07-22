# encoding: UTF-8

## Set working directory, load gems and create logs
	# Using pathname extentions for setting public folder
	require 'pathname'
	#set up root object, it might be used by the environment and\or the plezi extension gems.
	Root ||= Pathname.new(File.dirname(__FILE__)).expand_path
	# make sure all file access and file loading is relative to the application's root folder
	Dir.chdir Root.to_s
	# using bundler to load gems (including the plezi gem)
	require 'bundler'
	Bundler.require(:default, ENV['ENV'].to_s.to_sym)
	## uncomment to create a log file
	# GReactor.create_logger File.expand_path(Root.join('server.log').to_s)

## Options for Scaling the app (across processes or machines):
	## uncomment to set up forking.
	# GReactor::Settings.set_forking 4
	## Redis scaling
	# Plezi::Settings.redis_channel_name = 'appsecret'
	# ENV['PL_REDIS_URL'] ||= ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'] || ENV['REDISTOGO_URL'] || "redis://username:password@my.host:6389"


# The basic appname controller, to get you started
class MyController
	# HTTP
	def index
		"Hello World!\r\n\r\nThis appname mini-app is an example hello world and websocket chatroom.\r\n
		\r\nplease visit http://www.websocket.org/echo.html and connect to: ws://localhost:3000/nickname"
	end
	def websockets
		redirect_to "http://www.websocket.org/echo.html"
	end
	# Websockets
	def on_message data
		data = "#{params[:id]}: #{data}" if params[:id]
		_print data
		broadcast :_print, data		
	end
	def on_open
		_print 'Welcome!'
		broadcast :_print, "Somebody joind us :-)"
	end
	def on_close
		broadcast :_print, "Somebody left us :-("
	end
	def _print data
		response << data
	end
end


# start a web service to listen on the first default port (3000 or the port set by the command-line).
# you can change some of the default settings here.
listen 	host: :default,
		# root: Root.join('public').to_s,
		# assets: Root.join('assets').to_s,
		# assets_public: '/assets',
		# templates: Root.join('app','views').to_s,
		ssl: false

## Optional stuff:
	## I18n re-write, i.e.: `/en/home` will be rewriten as `/home`, while setting params[:locale] to "en"
	# route "/:locale{#{I18n.available_locales.join "|"}}/*" , false if defined? I18n
	#
	## OAuth2 - Facebook / Google authentication
	# require 'plezi/oauth'
	# ENV["FB_APP_ID"] ||= "app id"; ENV["FB_APP_SECRET"] ||= "secret"; ENV['GOOGLE_APP_ID'] = "app id"; ENV['GOOGLE_APP_SECRET'] = "secret"
	# create_auth_shared_route do |service_name, auth_token, remote_user_id, remote_user_email, remote_response|
	#         # ...callback for authentication.
	#         # This callback should return the app user object or false
	#         # This callback has access to the magic controller methods (request, cookies, etc')
	# end


# adds your controller as the root of the application
route '/(:id)', MyController

