module Anorexic



	# this is a basic server object for the Anorexic framework.
	# it is also a good template from which to create a more advanced server class
	# (if you wish to implement your own framework).
	#
	# the Anorexic::RackServer already made some progress for Rack supported servers, and it is recommended over WEBrick.
	#
	# if you create your own server class, remember to set the `Anorexic::Application.instance.server_class` to you new class, BEFORE the listen call:
	#    Anorexic::Application.instance.server_class = NewServerClass
	#    listen ...
	#
	# the server class must support the fullowing methods:
	# new:: new(port = 3000, params = {}). defined using the `def initialize(port, params)`.
	# add_route:: add_route(path, config, &block).
	# start:: (no paramaters)
	# shutdown:: (no paramaters)
	# self.set_logger:: log_file (class method)
	#
	# it is advised that the server class pass-through any paramaters
	# defined in `params[:server_params]` to the server.
	#
	# it is advised that Rack servers accept a `params[:middleware]` Array.
	# each item is also an Array of [MiddlewareClass, arguments, to, use] to be placed in the `params[:middleware]` Array.
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
					response['Content-Type'] = Anorexic.default_content_type
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


end
