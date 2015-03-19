
module Plezi

	module_function

	#######################
	## Services pooling and calling

	# DANGER ZONE - Plezi Engine. the services store
	SERVICES = {}
	# DANGER ZONE - Plezi Engine. the services mutex
	S_LOCKER = Mutex.new

	# public API to add a service to the framework.
	# accepts:
	# port:: port number
	# parameters:: a hash of parameters that are passed on to the service for handling (and from there, service dependent, to the protocol and/or handler).
	#
	# parameters are any of the following:
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
	#
	# assets:
	#
	# assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively) before sending them as static files. if it is impossible to write the files, they will be rendered dynamically for every request (it would be better to render them before-hand).
	#
	# templates:
	#
	# templates can be either an ERB file on a Haml file.
	#
	def add_service port, parameters = {}
		parameters[:port] ||= port
		parameters[:service_type] ||= ( parameters[:ssl] ? SSLService : BasicService)
		service = nil
		service = parameters[:service_type].create_service(port, parameters) unless ( defined?(BUILDING_PLEZI_TEMPLATE) || defined?(PLEZI_ON_RACK) )
		S_LOCKER.synchronize {SERVICES[service] = parameters}
		Plezi.callback Plezi, :info, "Started listening on port #{port}."
		true
	end

	# Plezi Engine, DO NOT CALL. stops all services - active connection will remain open until completion.
	def stop_services
		info 'Stopping services'
		S_LOCKER.synchronize {SERVICES.each {|s, p| s.close rescue true; info "Stoped listening on port #{p[:port]}"}; SERVICES.clear }
	end

end
