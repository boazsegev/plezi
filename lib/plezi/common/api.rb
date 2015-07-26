
module Plezi

	module_function

	# Defines methods used to set up the Plezi app.

	# public API to add a service to the framework.
	# accepts a Hash object with any of the following options (Hash keys):
	# port:: port number. defaults to 3000 or the port specified when the script was called.
	# host:: the host name. defaults to any host not explicitly defined (a catch-all). NOTICE: in order to allow for hostname aliases, this is host emulation and the listening socket will bind to all the addresses available. To limit the actual binding use the `:bind` parameter as set by the GReactor's API - in which case host aliases might not work.
	# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
	# public:: the public root folder. if this is defined, static files will be served from this folder and all it's sub-folders. Plezi does NOT support file indexing.
	# assets:: the assets root folder. defaults to nil (no assets support). if the path is defined, assets will be served from `/assets/...` (or the public_asset path defined) before any static files. assets will not be served if the file in the /public/assets folder if up to date (a rendering attempt will be made for systems that allow file writing).
	# assets_public:: the assets public uri location (uri format, NOT a file path). defaults to `/assets`. `save_assets` will set if assets should be saved to the assets public folder as static files (defaults to false).
	# assets_callback:: a method that accepts two parameters: (request, response) and renders any custom assets. the method should return `false` unless it had set the response.
	# save_assets:: saves the rendered assets to the filesystem, under the public folder. defaults to false.
	# templates:: the templates root folder. defaults to nil (no template support). templates can be rendered by a Controller class, using the `render` method.
	# ssl:: if true, an SSL service will be attempted. if no certificate is defined, an attempt will be made to create a self signed certificate.
	# ssl_key:: the public key for the SSL service.
	# ssl_cert:: the certificate for the SSL service.
	#
	# Assets:
	#
	# Assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively)
	# before sending them as static files.
	#
	# Should you need to render a different type of asset, you can define an assets_callback (or submit a pull request with a patch). 
	# 
	# templates:
	#
	# Plezi's controller.render ERB, Slim and Haml are natively supported.
	#
	# @return [Plezi::Router]
	#
	def listen parameters = {}
		# update default values
		parameters[:index_file] ||= 'index.html'
		parameters[:assets_public] ||= '/assets'
		parameters[:assets_public].chomp! '/'
		parameters[:public] ||= parameters[:root] # backwards compatability
		puts "Warning: 'root' option is being depracated. use 'public' instead." if parameters[:root]

		# check if the port is used twice.
		@routers_locker.synchronize do
			@active_router = GRHttp.listen(parameters)
			unless @active_router[:upgrade_handler]
				@routers << (@active_router[:http_handler] = ::Plezi::Base::HTTPRouter.new)
				@active_router[:upgrade_handler] = @active_router[:http_handler].upgrade_proc
			else
				@active_router.delete :alias
			end
			@active_router[:http_handler].add_host(parameters[:host], @active_router.merge(parameters) )
			@active_router = @active_router[:http_handler]
		end
		# return the current handler or the protocol..
		@active_router
	end

	# clears all the listeners and routes defined
	def clear_app
		@routers_locker.synchronize {GReactor.clear_listeners; @routers.clear}
	end
	# adds a route to the last server created
	def route(path, controller = nil, &block)
		raise "Must define a listener before adding a route - use `Plezi.listen`." unless @active_router
		@routers_locker.synchronize { @active_router.add_route path, controller, &block }
	end


	# adds a shared route to all existing services and hosts.
	def shared_route(path, controller = nil, &block)
		raise "Must have created at least one Pleze service before calling `shared_route` - use `Plezi.listen`." unless @routers
		@routers_locker.synchronize { @routers.each {|r| r.add_shared_route path, controller, &block } }
	end

	# adds a host to the last server created
	#
	# accepts a host name and a parameter(s) Hash which are the same parameter(s) as {Plezi.listen} accepts:
	def host(host_name, params)
		raise "Must define a listener before adding a route - use `Plezi.listen`." unless @active_router
		@routers_locker.synchronize { @active_router.add_host host_name, params }
	end

	# starts the Plezi framework server and hangs until the exit signal is given.
	def start
		start_async
		puts "\nPress ^C to exit.\n"
		GReactor.join { puts "\r\nStarting shutdown sequesnce. Press ^C to force quit."}
	end

	# Makes sure the GRHttp server will be used by Rack (if Rack is available) and disables Plezi's autostart feature.
	#
	# This method is a both a fail safe and a shortcut. Plezi will automatically attempt to diable autostart when discovering Rack
	# but this method also makes sure that the GRHttp is set as the Rack server by setting the ENV\["RACK_HANDLER"] variable.
	#
	# This is used as an alternative to {Plezi.start_placebo}.
	#
	# Use {Plezi.start_placebo} to augment an existing app while operating Plezi on a different process or server.
	#
	# Use {Plezi.start_rack} to augment an existing Rack app (i.e. Rails/Sinatra) by loading both Plezi and the existing Rack app
	# to the GRHtto server (it will set up GRHttp as the Rack server).
	def start_rack
		Object.const_set("NO_PLEZI_AUTO_START", true) unless defined?(NO_PLEZI_AUTO_START)
		ENV["RACK_HANDLER"] = 'grhttp'
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
	@routers_locker = Mutex.new
	@routers ||= [].to_set
end

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

NO_PLEZI_AUTO_START = true if defined?(::Rack)
