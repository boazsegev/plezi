require "anorexic/version"
# Using the built-in webrick to create services.
require 'logger'
require 'openssl'
require 'webrick'
require 'webrick/https'

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

##############################################################################
# a stand alone webrick services app.
# this is the common code for all apps.
#
# it is a simple DSL with five functions:
# - listen <<port>>, <<options>> : sets up a server
# - route <<path>> &block : sets up a route for the last server created
# - shared_route <<path>> &block : sets up a route for all previous servers
# - start : starts to actually listen. can be set up as a deamon.
#
# the `start` is automatically when the setup is finished.
# once called, the main DSL will be removed (undefined), so as to avoid conflicts.
#
# To overide the behavior, overide tha Anorexic::Application methods:
#
# set_logger, add_server, add_route_to_server
#
# the set_logger should set the @logger and @log_file application variables. and return a logger IO object.
#
# the add_server(port = 3000, params = {}) and  add_route_to_server(server, path, config = {}, &block)
# should take the parameters allowed in listen and route
#
# here is an empty overwrite example (which will crash if you leave it like this)
#
#
#
# thanks to Russ Olsen for his ideas for DSL and his blog post at:
# http://www.jroller.com/rolsen/entry/building_a_dsl_in_ruby1 
##############################################################################
module Anorexic

	# this is the basic server object for the Anorexic framework.
	# create a similar one to change the anorexic server
	# (to support puma, thin, rack, etc').
	#
	# remember to set the `Anorexic::Application.instance.server_class` to you new class:
	#    `Anorexic::Application.instance.server_class = NewServer`
	#
	# the server class must support the fullowing methods:
	# new:: new(port = 3000, params = {})
	# add_route:: path, config, &block
	# start:: (no paramaters)
	# shutdown:: (no paramaters)
	# self.set_logger:: log_file (class method)
	#
	# it is advised that the server class pass-through any paramaters
	# defined in `params[:server_params]` to the server.
	#
	# it is advised that Rack servers accept a `params[:middleware]` Array.
	# each item is a string to be placed after the Rack::Builder `use` function.
	#
	class WEBrickServer
		attr_reader :server
		attr_reader :routes

		def initialize(port = 3000, params = {})
			@routes = []
			params[:server_params] ||= {}

			server_params = {Port: port}.update params
			options = { v_host: nil, s_alias: nil, ssl_cert: nil, ssl_pkey: nil, ssl_self: false }
			options.update params

			if Anorexic.logger
				server_params[:AccessLog] = [
					[Anorexic.logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT],
				]
			end

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
			@server = WEBrick::HTTPServer.new(server_params.update(params[:server_params]))
			self
		end

		def add_route path, config, &block
			# add route to server
			if config[:servlet]
				puts "attempting to mount a servlet - not yet tested nor fully supportted"
				config[:servlet_args] ||= []
				@server.mount path, config[:servlet], *config[:servlet_args]
			elsif config[:file_root]
				config[:servlet_args] ||= []
				extra_options = [config[:file_root]]
				extra_options << {}
				extra_options.last[:FancyIndexing] = true if config[:allow_indexing]
				extra_options.last.update config[:options] if config[:options].is_a?(Hash)
				extra_options.push *config[:servlet_args]
				@server.mount path, WEBrick::HTTPServlet::FileHandler, *extra_options
			else
				@server.mount_proc path do |request, response|
					response['Content-Type'] = config['Content-Type'] || 'text/html'
					block.call request, response
				end
			end
		end

		def start
			# start the server
			@server.start
		end

		def shutdown
			# start the server
			@server.shutdown
		end
	end

	# This is the main application object. only one can exist.
	#
	# This object is the power behind the `listen`, `route` and `start` functions.
	#
	# Please use the`listen`, `route` and `start` functions rather then accessing this object.
	#
	# It is better to make most settings using the listen paramaters.
	class Application
		include Singleton

		attr_reader :logger, :servers
		attr_accessor :server_class

		def initialize
			@servers = []
			@threads = []
			@logger = ::Logger.new STDOUT
			@server_class = WEBrickServer
		end
		def set_logger log_file, copy_to_stdout = true
			@logger = ::Logger.new(log_file)
			if log_file != STDOUT && copy_to_stdout
				@logger = CustomIO.new(@logger, (::Logger.new(STDOUT)))
				# $stdout = @logger - fails when debugging....
			end
			@logger
		end

		def add_server(port = 3000, params = {})
			@servers << @server_class.new(port, params)
		end

		def check_server_array
			if @servers.empty?
				raise "ERROR: must define a listenong point before setting it's routes."
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
			server.add_route path, config, &block
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

	# used to merge logger with STDOUT (double out)
	class CustomIO
		def initialize *targets
			@targets = targets
		end

		def write(*args, &block)
			send_to_targets(:write, *args, &block)
		end
		def close(*args, &block)
			send_to_targets(:close, *args, &block)
		end
		def send_to_targets(sym, *args, &block)
			ret = []
			if block
				@targets.each {|t| ret << t.send(sym, *args, &block)}
			else
				@targets.each {|t| ret << t.send(sym, *args)}
			end
			return *ret
		end

		def method_missing(sym, *args, &block)
			send_to_targets sym, *args, &block
		end
	end

	module_function

	def logger
		Application.instance.logger
	end
	def create_logger log_file, copy_to_stdout = true
		Application.instance.set_logger log_file, copy_to_stdout
	end

end

# fix the Ruby Logger class (used by Anorexic) to fit Rack and WEBrick:
# (Rack uses `write`, which Logger doesn't define)
class ::Logger
	alias_method :write, :<<
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
# if you're not using a rack extention, you can also add any of the WEBrick values as described at:
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPServer.html#method-i-mount_proc
def listen(port = 3000, params = {})
	Anorexic::Application.instance.add_server port, params
end

# adds a route to the last server object
#
# path:: the path for the route
# config:: options for the default behaviour of the route.
#
# the current options for the config depend on the active server.
# for the default server ( Anorexic::WEBrickServer ), the are:
#
# Content-Type:: the key should be the string 'Content-Type'. defaults to 'Content-Type' => 'text/html'.
# file_root:: sets a root folder to serve files. defaults to nil (no root).
# allow_indexing:: if a root folder is set, this sets th indexing option. defaults to false.
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
	Object.const_set "NO_ANOREXIC_AUTO_START", true
	undef listen
	undef shared_route
	undef route
	undef start
	trap("INT") {Anorexic::Application.instance.shutdown}
	Anorexic::Application.instance.start deamon
end

# sets to start the services once dsl script is finished loading.
at_exit { start } unless defined?(NO_ANOREXIC_AUTO_START) || defined?(BUILDING_ANOREXIC_TEMPLATE)
