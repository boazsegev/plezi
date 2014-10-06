require "anorexic/version"
# Using the built-in webrick to create services.
require 'openssl'
require 'webrick'
require 'webrick/https'

# used to define root

##############################################################################
# a stand alone webrick services app.
# this is the common code for all apps.
#
# it is a simple DSL with four functions:
# - listen <<port>>, <<options>> : sets up a server
# - route <<path>> &block : sets up a route for the last server created
# - shared_route <<path>> &block : sets up a route for all previous servers
# - start : starts to actually listen. can be set up as a deamon.
#
# Once you call `start`, the DSL will be removed (undefined),
# so as to avoid conflicts.
#
# thanks to Russ Olsen for his ideas for DSL and his blog post at:
# http://www.jroller.com/rolsen/entry/building_a_dsl_in_ruby1 
##############################################################################
module Anorexic

	# This is the main application object. only one can exist.
	#
	# This object is the power behind the `listen`, `route` and `start` functions.
	#
	# Please use the`listen`, `route` and `start` functions rather then accessing this object.
	#
	# It is better to make most settings using the listen paramaters.
	class Application
		include Singleton

		def initialize
			@servers = []
			@threads = []
		end

		def add_server(port = 3000, params = {})
			server_params = {Port: port}.update params
			options = { v_host: nil, s_alias: nil, ssl_cert: nil, ssl_pkey: nil, ssl_self: false }
			options.update params

			if options[:file_root]
				options[:allow_indexing] ||= false
				server_params[:DocumentRootOptions] ||= {}
				server_params[:DocumentRoot] = options[:file_root]
				server_params[:DocumentRootOptions][:FancyIndexing] ||= options[:allow_indexing]
			end

			if options[:vhost]
				server_params[:ServerName] = options[:vhost]
				server_params[:ServerAlias] = options[:s_alias]
			end

			if options[:ssl_self]
				server_name = server_params[:ServerName] || "localhost"
				server_params[:SSLEnable] = true
				server_params[:SSLCertName] = [ ["CN" , server_name]]
			elsif options[:ssl_cert] && options[:ssl_pkey]
				server_params[:SSLEnable], server_params[:SSLCertificate], server_params[:SSLPrivateKey] = true, options[:ssl_cert], options[:ssl_pkey]
			end
			@servers << WEBrick::HTTPServer.new(server_params)
		end

		def check_server_array
			if @servers.empty?
				raise "ERROR: must define a listenong point before setting it's routes."
			end
			unless (@servers.select {|s| !s.is_a? WEBrick::HTTPServer}).empty?
				raise "TYPE ERROR: server objects must be WEBrick::HTTPServer. use 'listen' to add server objects."
			end
			true
		end

		def add_route(path, config = {}, &block)
			check_server_array
			add_route_to_server @servers.last, path, config, &block
		end

		def add_shared_route(path, config = {}, &block)
			check_server_array
			@servers.each { |s| add_route_to_server(s, path, config, &block) }
		end

		def add_route_to_server(server, path, config = {}, &block)
			if config[:servlet]
				puts "attempting to mount a servlet - not yet tested nor fully supportted"
				config[:servlet_args] ||= []
				server.mount path, config[:servlet], *config[:servlet_args]
			else
				server.mount_proc path do |request, response|
					response['Content-Type'] = config['Content-Type'] || 'text/html'
					block.call request, response
				end
			end
		end

		def start deamon = false
			@servers.each do |s|
				@threads << Thread.new do
					s.start
				end
			end
			unless deamon
				@threads.each {|t| t.join}
			end
			self
		end
		def shutdown
			@servers.each {|s| s.shutdown }
		end
	end


end

# creates a server object and waits for routes to be set.
# 
# port:: the port to listen to. defaults to 3000.
# params:: a Hash of serever paramaters: v_host, s_alias, ssl_cert, ssl_pkey or ssl_self.
#
# The different keys in the params hash control the server's behaviour, as follows:
#
# file_root:: sets a root folder to serve files. defaults to nil (no root).
# allow_indexing:: if a root folder is set, this sets th indexing option. defaults to false.
# v_host:: sets the virtual host name, for virtual hosts. defaults to nil (no virtual host).
# ssl_self:: sets an SSL server with a self assigned certificate (changes with every restart). defaults to false.
# ssl_cert:: sets an SSL certificate (an OpenSSL::X509::Certificate object). if both ssl_cert and ssl_pkey, an SSL server will be established. defaults to nil.
# ssl_pkey:: sets an SSL private ket (an OpenSSL::PKey::RSA object). if both ssl_cert and ssl_pkey, an SSL server will be established. defaults to nil.
#
# you can also add any of the WEBrick values as described at:
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPServer.html#method-i-mount_proc
def listen(port = 3000, params = {})
	Anorexic::Application.instance.add_server port, params
end

# adds a route to the last server object
#
# path:: the path for the route
# config:: options for the default behaviour of the route.
#
# the current options for the config are:
#
# Content-Type:: the key should be the string 'Content-Type'. defaults to 'Content-Type' => 'text/html'.
# servlet:: set a servlet instead of a Proc, see WEBRick documentation for more info. defaults to nil.
# servlet_args:: if a servlet is set, attempts to send arguments to the constructor. defaults to [] (no arguments).
#
def route(path, config = {'Content-Type' => 'text/html'}, &block)
	Anorexic::Application.instance.add_route path, config, &block
end

# adds a route to the all the previous server objects
# accepts same options as route
def shared_route(path, config = {'Content-Type' => 'text/html'}, &block)
	Anorexic::Application.instance.add_shared_route path, config, &block
end

# finishes setup of the servers and starts them up. This will hange the proceess unless it's set up as a deamon.
# deamon:: defaults to false.
def start(deamon = false)
	undef listen
	undef shared_route
	undef route
	undef start
	trap("INT") {Anorexic::Application.instance.shutdown}
	Anorexic::Application.instance.start deamon
end
