require "anorexic/version"
require "anorexic/stubs.rb"
require "anorexic/magic.rb"
require "anorexic/webrick_server.rb"
require "anorexic/rack_server.rb"

# require 'thin'

require 'rack'

require 'openssl'
require 'strscan'
require 'pathname'
require 'logger'

require 'webrick'
require 'webrick/https'

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

##############################################################################
# a stand alone web services app.
# this is the common code for all anorexic apps.
#
# it is a simple DSL with five functions that can build a whole web application:
# - listen port=3000, options={} : sets up a server
# - route "path", options={} &block : sets up a route for the last server created
# - shared_route "path", options={} &block : sets up a route for all previous servers
#
# we said, four, where's the forth?
#
# - start : the `start` is automatically called when the setup is finished. once called, the main DSL will be removed (undefined), so as to avoid code conflicts.
#
# here is some sample code:
#		require 'anorexic'
#		listen 3000
#		route('/') { |request, response| response.body << "Hello World from 3000!" }
#
#		listen 8080, ssl_self: true 
#		route('/') { |request, response| response.body << "SSL Hello World from 8080!" }
#
#		shared_route('/people') { |request, response| response.body << "Hello People!" }
#
# There are two built-in server classes:
#
# Anorexic::RackServer:: the rack  server - has MVC support and some lightweight magic features.
# Anorexic::WEBrickServer:: the WEBrick stand alone server - no rack support. has SSL features.
#
# its is possible to "mix and match" the different server classes. set the server class you want BEFORE calling listen:
#
#       Anorexic::Application.instance.server_class = Anorexic::WEBrickServer
#
# Anorexic::RackServer is the default server class. it will also set up an MVC structure for your app.
#
# The RackServer server can be used for any supported rack server. for example, to use webrick server:
#
#    require 'anorexic'
#    port = 3000
#    listen port, server: 'webrick', ssl_self: true
#
# Thin is the default server if no 'server' option is passed. Thin doesn't support SSL.
# It is possible to change the default server, for all the `listen` calls that do not specify a server, using:
#
#    Anorexic::RackServer.default_server = 'webrick'
#
# If the Thin server doesn't exist, the app will fall back to Puma (if available) or
# back to WEBrick server (if Puma isn't available) - the MVC RackServer implemantation will still be used.
# 
# The RackServer accepts Regexp (regular exception) for route paths. for example:
#
#    require 'anorexic'
#    listen
#    route(/[.]*/) {|request, response| response.body << "Your request, master: #{request.path}."}
#
# The catch-all route (/[.]*/) has a shortcut '*', so it's possible to write:
#
#    require 'anorexic'
#    listen
#    route('*') {|request, response| response.body << "Your request, master: #{request.path}."}
#
#
# The RackServer accepts an optional class object that can be passed using the `route` command. Passing a class object is especially useful for RESTful handling.
# read more at the Anorexic::StubController documentation, which is a stub class used for testing routes.
#
#    require 'anorexic'
#    listen
#    route "*", Anorexic::StubController
#
# class routes that have a specific path (including root, but not a catch-all or Regexp path)
# accept an implied `params[:id]` variable. the following path ('/'):
#
#    require 'anorexic'
#    listen
#    route "/", Anorexic::StubController
#    # client requests: /1
#    #  =>  Anorexic::StubController.new.show() # where params[:id] == 1
#
# to handle inline paramaters (/path/:id/:time), set the appropriate paramaters within the `before` method of the Conltroller.
#
# RackServer routes are handled in the order they are created. If overlapping routes exist, the first will execute first:
#
#    require 'anorexic'
#    listen
#    route('*') do |request, response|
#       response.body << "Your request, master: #{request.path}." unless request.path.match /cats/
#    end
#    route('*') {|request, response| response.body << "Ahhh... I love cats!"}
#
# the WEBrickServer overwrites the first route with the second and it does not accept Regexp routes.
#
# all the examples above shuold be good to run from irb.
#
# thanks to Russ Olsen for his ideas for a DSL and his blog post at:
# http://www.jroller.com/rolsen/entry/building_a_dsl_in_ruby1 
##############################################################################
module Anorexic



	# this is the main application object. only one can exist.
	#
	# this class collects the information from the `listen`, `route` and `start` functions and creates a server "lineup".
	#
	# use the`listen`, `route` and `start` functions rather then accessing this object.
	#
	# It is better to make most settings using the listen paramaters.
	class Application
		include Singleton

		attr_reader :logger, :servers
		attr_accessor :server_class
		attr_accessor :default_middleware
		# gets/sets the default content type for the 
		attr_accessor :default_content_type

		def initialize
			@servers = []
			@threads = []
			@logger = ::Logger.new STDOUT
			@server_class = Anorexic::RackServer
			@default_content_type = "text/html; charset=utf-8"
			@default_middleware = []
		end
		def set_logger log_file, copy_to_stdout = true
			@logger = ::Logger.new(log_file)
			if log_file != STDOUT && copy_to_stdout
				@logger = CustomIO.new(@logger, (::Logger.new(STDOUT)))
				# $stdout = @logger - fails when debugging....
			end
			@logger
		end

		def add_server(port, params = {})
			@servers << @server_class.new(port, params)
		end

		def check_server_array
			if @servers.empty?
				raise "ERROR: use `listen` first! must define a listening service before setting it's routes."
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

		def start deamon = false, wait_for_load = 3
			Anorexic.logger.info "starting up Anorexic and waiting for load compleation (count to #{wait_for_load})." if @servers.length > 1
			@servers.each do |s|
				@threads << Thread.new do
					s.start
				end
			end
			unless deamon
				if @servers.length > 1
					sleep wait_for_load
					Anorexic.logger.info "Multiple Anorexic services active - listening for shutdown."
					trap("INT") {Anorexic::Application.instance.shutdown}
					trap("TERM") {Anorexic::Application.instance.shutdown}
				end
				@threads.each {|t| t.join}
			end
			self
		end
		def shutdown
			@servers.each {|s| s.shutdown }
			# 
		end
	end

	module_function

	# get the default middleware array.
	#
	# this can be used to ass middleware to all Rack servers like so:
	#     Anorexic.default_middleware << [MiddleWare, paramater]
	def default_middleware
		Application.instance.default_middleware
	end

	# get the logger object
	def logger
		Application.instance.logger
	end

	# create and set the logger object. accepts:
	# log_file:: a log file name to be used for logging
	# copy_to_stdout:: if false, log will only log to file. if true, the Anorexic::CustomIO class will be used to log out to the file and to the STDOUT. defaults to true.
	def create_logger log_file, copy_to_stdout = true
		Application.instance.set_logger log_file, copy_to_stdout
	end

	# gets the default content type that should be sent back if an HTTP response header "Content-Type" wasn't set by the response.
	def default_content_type
		Application.instance.default_content_type
	end

	# sets the default content type that should be sent back if an HTTP response header "Content-Type" wasn't set by the response.
	def default_content_type= new_type
		Application.instance.default_content_type = new_type
	end

end

# fix the Ruby Logger class (used by Anorexic) to fit Rack and WEBrick:
# (Rack uses `write`, which Logger doesn't define)
class ::Logger
	alias_method :write, :<<
end

# creates a server object and waits for routes to be set.
# 
# port:: the port to listen to. the first port defaults to 3000 and increments by 1 with every `listen` call. it's possible to set the first port number by running the app with the -p paramater.
# params:: a Hash of serever paramaters: v_host, s_alias, ssl_cert, ssl_pkey or ssl_self.
#
# The different keys in the params hash control the server's behaviour, as follows:
#
# v_host:: sets the virtual host name, for virtual hosts. defaults to nil (no virtual host).
# ssl_self:: sets an SSL server with a self assigned certificate (changes with every restart). defaults to false.
# server_params:: a hash of paramaters to be passed directly to the server - architecture dependent.
#
# if you're not using a rack extention, the WEBrick options for :server_params are as described at:
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPServer.html#method-i-mount_proc
def listen(port = nil, params = {})
	if !port && defined? ARGV
		if ARGV.find_index('-p')
			port_index = ARGV.find_index('-p') + 1
			port ||= ARGV[port_index].to_i
			ARGV[port_index] = (port + 1).to_s
		else
			ARGV << '-p'
			ARGV << '3000'
			return listen port, params
		end
	end
	port ||= 3000	
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
# debug:: ONLY FOR RackServer: set's detailed exeption output, using Rack::ShowExceptions
# servlet:: ONLY FOR WEBrickServer: set a servlet instead of a Proc, see WEBRick documentation for more info. defaults to nil.
# servlet_args:: ONLY FOR WEBrickServer: if a servlet is set, attempts to send arguments to the constructor. defaults to [] (no arguments).
#
def route(path, config = {}, &block)
	Anorexic::Application.instance.add_route path, config, &block
end

# adds a route to the all the previous server objects
# accepts same options as route
def shared_route(path, config = {}, &block)
	Anorexic::Application.instance.add_shared_route path, config, &block
end

# finishes setup of the servers and starts them up. This will hange the proceess unless it's set up as a deamon.
# deamon:: defaults to false.
# wait_for_load:: how long Anorexic should wait for servers to start before setting the exit routine (only if deamon is false).
def start(deamon = false, wait_for_load = 4)
	Object.const_set "NO_ANOREXIC_AUTO_START", true
	undef listen
	undef shared_route
	undef route
	undef start
	Anorexic::Application.instance.start deamon, wait_for_load
end


# sets to start the services once dsl script is finished loading.
at_exit { start } unless defined?(NO_ANOREXIC_AUTO_START) || defined?(BUILDING_ANOREXIC_TEMPLATE)
