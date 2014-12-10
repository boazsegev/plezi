
module Anorexic

	# this module contains the methods that are used as a DSL and sets up easy access to the Anorexic framework.
	#
	# use the`listen`, `host` and `route` functions rather then accessing this object.
	#
	module DSL
		module_function

		@servers = {}
		@active_router = nil

		# adds a server (performs the action required by the listen method).
		#
		# accepts:
		# port:: (optional) the port number for the service. if not defined, defaultes to the -p runtime argument (i.e. `./app.rb -p 8080`) or to 3000 if argument is missing. 
		# params:: any parameter accepted by the Anorexic.add_service method. defaults to: `:protocol=>Anorexic::HTTPProtocol, :handler => HTTPRouter.new`
		def listen(port, params = {})
			# set port and arguments
			if port.is_a?(Hash)
				params = port
				port = nil
			end
			if !port && defined? ARGV
				if ARGV.find_index('-p')
					port_index = ARGV.find_index('-p') + 1
					port ||= ARGV[port_index].to_i
					ARGV[port_index] = (port + 1).to_s
				else
					ARGV << '-p'
					ARGV << '3000'
					return listen nil, params
				end
			end
			port ||= 3000

			# create new service or choose existing
			if @servers[port]
				puts "WARNING: port aleady in use! returning existing service and attemptin to add host (maybe multiple hosts? use `host` instead)." unless params[:host]
				@active_router = @servers[port][:handler]
				@active_router.add_host params[:host], params
				return @active_router
			end
			params[:protocol] ||= HTTPProtocol
			@active_router = params[:handler] ||=  HTTPRouter.new # HTTPEcho #
			@active_router.add_host params[:host], params
			return false unless Anorexic.add_service(port, params)
			@servers[port] = params
			@active_router
		end

		# adds a route to the last server created
		def route(path, controller = nil, &block)
			@active_router.add_route path, controller, &block
		end


		# adds a shared route to all existing services and hosts.
		def shared_route(path, controller = nil, &block)
			@servers.values.each {|p| p[:handler].add_shared_route path, controller, &block }
		end

		# adds a host to the last server created
		#
		# accepts the same parameter(s) as the `listen` command (see Anorexic.add_service), except :protocol and :handler are ignored:
		# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
		def host(host_name, params)
			@active_router.add_host host_name, params
		end
	end
end

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

# Set a shortcut for the Anorexic module.
AN = Anorexic

# creates a server object and waits for routes to be set.
# 
# port:: the port to listen to. the first port defaults to 3000 and increments by 1 with every `listen` call. it's possible to set the first port number by running the app with the -p paramater.
# params:: a Hash of serever paramaters: v_host, ssl_cert, ssl_pkey or ssl_self.
#
# The different keys in the params hash control the server's behaviour, as follows:
#
# host:: sets a host for virtal hosts / namespaces. defaults to the global host (`:any`).
# ssl_self:: sets an SSL server with a self assigned certificate (changes with every restart). defaults to false.
# debug:: set's detailed exeption output, using Rack::ShowExceptions
# server_params:: a hash of paramaters to be passed directly to the server - architecture dependent.
# middleware:: a middleray array of arras of type [Middleware, paramater, paramater], if using RackServer.
#
def listen(port = nil, params = {})
	Anorexic::DSL.listen port, params
end

# adds a virtul host to the current service (the last `listen` call) or switches to an existing host within the active service.
#
# accepts:
# host_name: a String with the full host name (i.e. "www.google.com" / "mail.google.com")
# params:: any of the parameters accepted by the `listen` command, except `protocol`, `handler`, and `ssl` parameters.
def host(host_name = false, params = {})
	Anorexic::DSL.host host_name, params
end

# adds a route to the last server object
#
# path:: the path for the route
# controller:: The controller class which will accept the route.
#
# `path` paramaters has a few options:
#
# * `path` can be a Regexp object, forcing the all the logic into controller (typically using the before method).
#
# * simple String paths are assumed to be basic RESTful paths:
#
#     route "/users", Controller => route "/users/(:id)", Controller
#
# * routes can define their own parameters, for their own logic:
#
#     route "/path/:required_paramater_foo/(:optional_paramater_bar)"
#
# * routes can define optional routes with regular expressions in them:
#
#     route "(:locale){en|ru}/path"
#
# magic routes make for difficult debugging - the smarter the routes, the more difficult the debugging.
# use with care and avoid complex routes when possible. RESTful routes are recommended when possible.
# jason serving apps are advised to use required paramaters, empty sections indicating missing required paramaters (i.e. /path///foo/bar///).
#
def route(path, controller = nil, &block)
	Anorexic::DSL.route(path, controller, &block)
end

# adds a route to the all the existing servers and hosts.
#
# accepts same options as route.
def shared_route(path, controller = nil, &block)
	Anorexic::DSL.shared_route(path, controller, &block)
end

# finishes setup of the servers and starts them up. This will hange the proceess.
#
# this method is called automatically by the Anorexic framework.
#
# it is recommended that you DO NOT CALL this method.
# if any post shut-down actions need to be performed, use Anorexic.on_shutdown instead.
def start_services
	return 0 if ( defined?(NO_ANOREXIC_AUTO_START) || defined?(BUILDING_ANOREXIC_TEMPLATE) || defined?(ANOREXIC_ON_RACK) )
	Object.const_set "NO_ANOREXIC_AUTO_START", true
	undef listen
	undef host
	undef route
	undef shared_route
	undef start_services
	Anorexic.start_services
end

# sets to start the services once dsl script is finished loading.
at_exit { start_services } unless ( defined?(NO_ANOREXIC_AUTO_START) || defined?(BUILDING_ANOREXIC_TEMPLATE) || defined?(ANOREXIC_ON_RACK) )

# sets a name for the process (on some systems).
$0="Anorexic (Ruby)"
