
module Plezi

	# this module contains the methods that are used as a DSL and sets up easy access to the Plezi framework.
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
		# params:: any parameter accepted by the Plezi.add_service method. defaults to: `:protocol=>Plezi::HTTPProtocol, :handler => HTTPRouter.new`
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
			return false unless Plezi.add_service(port, params)
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
		# accepts the same parameter(s) as the `listen` command (see Plezi.add_service), except :protocol and :handler are ignored:
		# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
		def host(host_name, params)
			@active_router.add_host host_name, params
		end
	end
end

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

# Set a shortcut for the Plezi module.
PL = Plezi

# creates a server object and waits for routes to be set.
# 
# port:: the port to listen to. the first port defaults to 3000 and increments by 1 with every `listen` call. it's possible to set the first port number by running the app with the -p paramater.
# params:: a Hash of serever parameters, as listed in the Plezi#add_service documentation.
#
# The different keys in the params hash control the server's behaviour, as follows:
#
# host:: the host name. defaults to any host not explicitly defined (a catch-all).
# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
# root:: the public root folder. if this is defined, static files will be served from the location.
# assets:: the assets root folder. defaults to nil (no assets support). if the path is defined, assets will be served from `/assets/...` (or the public_asset path defined) before any static files. assets will not be served if the file in the /public/assets folder if up to date (a rendering attempt will be made for systems that allow file writing).
# assets_public:: the assets public uri location (uri format, NOT a file path). defaults to `/assets`. assets will be saved (or rendered) to the assets public folder and served as static files.
# assets_callback:: a method that accepts one parameters: `request` and renders any custom assets. the method should return `false` unless it has created a response object (`response = Plezi::HTTPResponse.new(request)`) and sent a response to the client using `response.finish`.
# save_assets:: saves the rendered assets to the filesystem, under the public folder. defaults to false.
# templates:: the templates root folder. defaults to nil (no template support). templates can be rendered by a Controller class, using the `render` method.
# ssl:: if true, an SSL service will be attempted. if no certificate is defined, an attempt will be made to create a self signed certificate.
# ssl_key:: the public key for the SSL service.
# ssl_cert:: the certificate for the SSL service.
#
def listen(port = nil, params = {})
	Plezi::DSL.listen port, params
end

# adds a virtul host to the current service (the last `listen` call) or switches to an existing host within the active service.
#
# accepts:
# host_name: a String with the full host name (i.e. "www.google.com" / "mail.google.com")
# params:: any of the parameters accepted by the `listen` command, except `protocol`, `handler`, and `ssl` parameters.
def host(host_name = false, params = {})
	Plezi::DSL.host host_name, params
end

# adds a route to the last server object
#
# path:: the path for the route
# controller:: The controller class which will accept the route.
#
# `path` parameters has a few options:
#
# * `path` can be a Regexp object, forcing the all the logic into controller (typically using the before method).
#
# * simple String paths are assumed to be basic RESTful paths:
#
#     route "/users", Controller => route "/users/(:id)", Controller
#
# * routes can define their own parameters, for their own logic:
#
#     route "/path/:required_paramater/:required_paramater{with_format}/(:optional_paramater)/(:optional){with_format}"
#
# * routes can define optional or required routes with regular expressions in them:
#
#     route "(:locale){en|ru}/path"
#
# * routes which use the special '/' charecter within a parameter's format, must escape this charecter using the '\' charecter. **Notice the single quotes** in the following example:
#
#     route '(:math){[\d\+\-\*\^\%\.\/]}'
#
#   * or, with double quotes:
#
#     route "(:math){[\\d\\+\\-\\*\\^\\%\\.\\/]}"
#
# magic routes make for difficult debugging - the smarter the routes, the more difficult the debugging.
# use with care and avoid complex routes when possible. RESTful routes are recommended when possible.
# json serving apps are advised to use required parameters, empty sections indicating missing required parameters (i.e. /path///foo/bar///).
#
def route(path, controller = nil, &block)
	Plezi::DSL.route(path, controller, &block)
end

# adds a route to the all the existing servers and hosts.
#
# accepts same options as route.
def shared_route(path, controller = nil, &block)
	Plezi::DSL.shared_route(path, controller, &block)
end

# finishes setup of the servers and starts them up. This will hange the proceess.
#
# this method is called automatically by the Plezi framework.
#
# it is recommended that you DO NOT CALL this method.
# if any post shut-down actions need to be performed, use Plezi.on_shutdown instead.
def start_services
	return 0 if ( defined?(NO_PLEZI_AUTO_START) || defined?(BUILDING_PLEZI_TEMPLATE) || defined?(PLEZI_ON_RACK) )
	Object.const_set "NO_PLEZI_AUTO_START", true
	undef listen
	undef host
	undef route
	undef shared_route
	undef start_services
	Plezi.start_services
end

# sets to start the services once dsl script is finished loading.
at_exit { start_services } unless ( defined?(NO_PLEZI_AUTO_START) || defined?(BUILDING_PLEZI_TEMPLATE) || defined?(PLEZI_ON_RACK) )

# sets a name for the process (on some systems).
$0="Plezi (Ruby)"
