
module Plezi

	# this isn't part of the public API.
	module Base

		# holds methods that are called by the DSL.
		#
		# this isn't part of the public API.
		module DSL
			module_function

			# this module contains the methods that are used as a DSL and sets up easy access to the Plezi framework.
			#
			# use the`listen`, `host` and `route` functions rather then accessing this object.
			#
			@servers = {}
			@active_router = nil


			# public API to add a service to the framework.
			# accepts a Hash object with any of the following options (Hash keys):
			# port:: port number. defaults to 3000 or the port specified when the script was called.
			# host:: the host name. defaults to any host not explicitly defined (a catch-all).
			# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
			# root:: the public root folder. if this is defined, static files will be served from the location.
			# assets:: the assets root folder. defaults to nil (no assets support). if the path is defined, assets will be served from `/assets/...` (or the public_asset path defined) before any static files. assets will not be served if the file in the /public/assets folder if up to date (a rendering attempt will be made for systems that allow file writing).
			# assets_public:: the assets public uri location (uri format, NOT a file path). defaults to `/assets`. assets will be saved (or rendered) to the assets public folder and served as static files.
			# assets_callback:: a method that accepts two parameters: (request, response) and renders any custom assets. the method should return `false` unless it had set the response.
			# save_assets:: saves the rendered assets to the filesystem, under the public folder. defaults to false.
			# templates:: the templates root folder. defaults to nil (no template support). templates can be rendered by a Controller class, using the `render` method.
			# ssl:: if true, an SSL service will be attempted. if no certificate is defined, an attempt will be made to create a self signed certificate.
			# ssl_key:: the public key for the SSL service.
			# ssl_cert:: the certificate for the SSL service.
			#
			# some further options, which are unstable and might be removed in future versions, are:
			# protocol:: the protocol objects (usually a class, but any object answering `#call` will do).
			# handler:: an optional handling object, to be called upon by the protocol (i.e. #on_message, #on_connect, etc'). this option is used to allow easy protocol switching, such as from HTTP to Websockets. 
			#
			# Duringn normal Plezi behavior, the optional `handler` object will be returned if `listen` is called more than once for the same port.
			#
			# assets:
			#
			# assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively)
			# before sending them as static files.
			#
			# templates:
			#
			# ERB, Slim and Haml are natively supported.
			#
			# @returns [Plezi::Router]
			#
			def listen parameters = {}
				# update default values
				parameters[:index_file] ||= 'index.html'
				parameters[:assets_public] ||= '/assets'
				parameters[:assets_public].chomp! '/'

				#keeps information of past ports.
				@listeners ||= {}
				@listeners_locker = Mutex.new

				# check if the port is used twice.
				@listeners_locker.synchronize do
					if @listeners[parameters[:port]]
						puts "WARNING: port aleady in use! returning existing service and attemptin to add host (maybe multiple hosts? use `host` instead)."
						@active_router = @listeners[parameters[:port]].params[:http_handler]
						@active_router.add_host parameters[:host], parameters if @active_router.is_a?(HTTPRouter)
						return @active_router
					end
				end
				@listeners[parameters[:port]] = parameters

				# make sure the protocol exists.
				parameters[:upgrade_handler] = parameters[:http_handler] = HTTPRouter.new

				GRHttp.listen parameters
				# set the active router to the handler or the protocol.
				@active_router = parameters[:http_handler]
				@active_router.add_host(parameters[:host], parameters)

				# return the current handler or the protocol..
				@active_router
			end
			# adds a route to the last server created
			def route(path, controller = nil, &block)
				raise "Must define a listener before adding a route - use `Plezi.listen`." unless @active_router
				@active_router.add_route path, controller, &block
			end


			# adds a shared route to all existing services and hosts.
			def shared_route(path, controller = nil, &block)
				raise "Must have created at least one Pleze service before calling `shared_route` - use `Plezi.listen`." unless @listeners
				@listeners.values.each {|p| p[:http_handler].add_shared_route path, controller, &block }
			end

			# adds a host to the last server created
			#
			# accepts the same parameter(s) as the `listen` command (see Plezi.add_service), except :protocol and :handler are ignored:
			# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
			def host(host_name, params)
				raise "Must define a listener before adding a route - use `Plezi.listen`." unless @active_router
				@active_router.add_host host_name, params
			end


			# tweeks a hash object to read both :symbols and strings (similar to Rails but without).
			def make_hash_accept_symbols hash
				@magic_hash_proc ||= Proc.new do |hs,k|
					if k.is_a?(Symbol) && hs.has_key?( k.to_s)
						hs[k.to_s]
					elsif k.is_a?(String) && hs.has_key?( k.to_sym)
						hs[k.to_sym]
					elsif k.is_a?(Numeric) && hs.has_key?(k.to_s.to_sym)
						hs[k.to_s.to_sym]
					end
				end
				hash.default_proc = @magic_hash_proc
				hash.values.each do |v|
					if v.is_a?(Hash)
						make_hash_accept_symbols v
					end
				end
			end
		end
	end

	def self.start
		return GReactor.start if GReactor.running?
		Object.const_set("NO_PLEZI_AUTO_START", true) unless defined?(NO_PLEZI_AUTO_START)
		puts "Starting Plezi #{Plezi::VERSION} Services using the GRHttp #{GRHttp::VERSION} server."
		puts "Press ^C to exit."
		GReactor.on_shutdown { puts "Plezi shutdown. It was fun to serve you."  }
		GReactor.start Plezi::Settings.max_threads
		GReactor.join { puts "\r\nStarting shutdown sequesnce. Press ^C to force quit."}
	end
end

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

# PL is a shortcut for the Plezi module, so that `PL == Plezi`.
PL = Plezi

# shortcut for Plezi::DSL.listen.
#
def listen(params = {})
	Plezi::Base::DSL.listen params
end

# adds a virtul host to the current service (the last `listen` call) or switches to an existing host within the active service.
#
# accepts:
# host_name: a String with the full host name (i.e. "www.google.com" / "mail.google.com")
# params:: any of the parameters accepted by the `listen` command, except `protocol`, `handler`, and `ssl` parameters.
def host(host_name = false, params = {})
	Plezi::Base::DSL.host host_name, params
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
	Plezi::Base::DSL.route(path, controller, &block)
end

# adds a route to the all the existing servers and hosts.
#
# accepts same options as route.
def shared_route(path, controller = nil, &block)
	Plezi::Base::DSL.shared_route(path, controller, &block)
end

# defines a method with a special name, such as "humens.txt".
#
# this could be used in controller classes, to define special routes which might defy
# normal Ruby naming conventions, such as "/welcome-home", "/play!", etc'
#
# could also be used to define methods with special formatting, such as "humans.txt",
# until a more refined way to deal with formatting will be implemented.
def def_special_method name, obj=self, &block
	obj.instance_exec { define_method name.to_s.to_sym, &block }
end



# finishes setup of the servers and starts them up. This will hange the proceess.
#
# this method is called automatically by the Plezi framework.
#
# it is recommended that you DO NOT CALL this method.
# if any post shut-down actions need to be performed, use Plezi.on_shutdown instead.
def start_services
	return 0 if defined?(NO_PLEZI_AUTO_START)
	undef listen
	undef host
	undef route
	undef shared_route
	Plezi.start
end

# restarts the Plezi app with the same arguments as when it was started.
#
# EXPERIMENTAL
def restart_plezi_app
	exec "/usr/bin/env ruby #{$PL_SCRIPT} #{$PL_ARGV.join ' '}"
end

# sets to start the services once dsl script is finished loading.
at_exit { start_services }

# sets information to be used when restarting
$PL_SCRIPT = $0
$PL_ARGV = $*.dup
# $0="Plezi (Ruby)"
