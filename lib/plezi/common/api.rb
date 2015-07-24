
module Plezi

	module_function

	# Defines methods used to set up the Plezi app.

	# public API to add a service to the framework.
	# accepts a Hash object with any of the following options (Hash keys):
	# port:: port number. defaults to 3000 or the port specified when the script was called.
	# host:: the host name. defaults to any host not explicitly defined (a catch-all). NOTICE: in order to allow for hostname aliases, this is host emulation and the listening socket will bind to all the addresses available. To limit the actual binding use the `:bind` parameter as set by the GReactor's API - in which case host aliases might not work.
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
	# assets:
	#
	# assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively)
	# before sending them as static files.
	#
	# templates:
	#
	# ERB, Slim and Haml are natively supported. Otherwise define an assets_callback (or submit a pull request with a patch). 
	#
	# @returns [Plezi::Router]
	#
	def listen parameters = {}
		# update default values
		parameters[:index_file] ||= 'index.html'
		parameters[:assets_public] ||= '/assets'
		parameters[:assets_public].chomp! '/'

		if !parameters[:port] && defined? ARGV
			if ARGV.find_index('-p')
				port_index = ARGV.find_index('-p') + 1
				parameters[:port] ||= ARGV[port_index].to_i
				ARGV[port_index] = (parameters[:port] + 1).to_s
			else
				ARGV << '-p'
				ARGV << '3001'
				parameters[:port] ||= 3000
			end
		end

		#keeps information of past ports.
		@listeners ||= {}
		@listeners_locker = Mutex.new

		# check if the port is used twice.
		@listeners_locker.synchronize do
			if @listeners[parameters[:port]]
				puts "WARNING: port aleady in use! returning existing service and attemptin to add host (maybe multiple hosts? use `host` instead)."
				@active_router = @listeners[parameters[:port]][:upgrade_handler]
				@active_router.add_host parameters[:host], parameters if @active_router.is_a?(::Plezi::Base::HTTPRouter)
				return @active_router
			end
		end
		@listeners[parameters[:port]] = parameters

		# make sure the protocol exists.
		parameters[:http_handler] = ::Plezi::Base::HTTPRouter.new
		parameters[:upgrade_handler] = parameters[:http_handler].upgrade_proc

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
	# accepts a host name and a parameter(s) Hash which are the same parameter(s) as {Plezi.listen} accepts:
	def host(host_name, params)
		raise "Must define a listener before adding a route - use `Plezi.listen`." unless @active_router
		@active_router.add_host host_name, params
	end

	# starts the Plezi framework server and hangs until the exit signal is given.
	def start
		start_async
		puts "\nPress ^C to exit.\n"
		GReactor.join { puts "\r\nStarting shutdown sequesnce. Press ^C to force quit."}
	end
	# starts the Plezi framework and returns immidiately,
	# allowing you to run the Plezi framework along side another framework. 
	def start_async
		Object.const_set("NO_PLEZI_AUTO_START", true) unless defined?(NO_PLEZI_AUTO_START)
		return GReactor.start if GReactor.running?
		puts "Starting Plezi #{Plezi::VERSION} Services using the GRHttp #{GRHttp::VERSION} server."
		GReactor.on_shutdown { puts "Plezi shutdown. It was fun to serve you."  }
		GReactor.start Plezi::Settings.max_threads
	end
	# This allows you to run the Plezi framework along side another framework - WITHOUT running the actual server.
	#
	# The server will not be initiatet and instead you will be able to use Plezi controllers and the Redis auto-config
	# to broadcast Plezi messages to other Plezi processes - allowing for scalable intigration of Plezi into other frameworks.
	def start_placebo
		GReactor.clear_listeners
		redis_connection # make sure the redis connection is activated
		puts "* Plezi #{Plezi::VERSION} Services will start with no Server...\n"
		start_async
	end

	# this module contains the methods that are used as a DSL and sets up easy access to the Plezi framework.
	#
	# use the`listen`, `host` and `route` functions rather then accessing this object.
	#
	@active_router = nil
end

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

NO_PLEZI_AUTO_START = true if defined?(::Rack)
