
module Anorexic

	# require 'rack/utf8_sanitizer' # will not be using this after all

	# This is the main Server class for the Anorexic framework.
	#
	# this is a rack based server class,
	# hence, it should be possible to use any server that has a Rack:Handler, like so:
	#    listen 80, server: 'puma'
	#
	# Thin is the default server if no 'server' option is passed. If Thin isn't available, Puma will be tested for.
	# Webrick, which is the Ruby build-in server, will be the last resort default server.
	#
	# it is possible to change the default server using:
	#
	#    Anorexic::RackServer.default_server = 'foo_server'
	#
	class RackServer
		# holds the server object
		attr_reader :server
		# holds the port set for the server object
		attr_reader :port
		# holds any paramaters used for the server
		attr_reader :params
		# holds the array of routs
		attr_reader :router
		# holds the rack handler's name (defaults to 'thin')
		attr_reader :rack_handlers

		# this is called by the Anorexic framework to initialize the server and set it's parameters.
		def initialize(port = 3000, params = {})
			@server = nil
			@port, @params = port, params
			@router = Anorexic::AnoRack::Router.new
			@rack_handlers = params[:server] || self.class.default_server
		end

		# sets the default server
		def self.default_server= def_serv
			@@default_server = def_serv
		end
		# gets the default server
		def self.default_server
			@@default_server ||= nil
			return @@default_server || 'thin' if defined? Thin
			return @@default_server || 'puma' if defined? Puma
			@@default_server || 'webrick'
		end

		# this is called by the Anorexic framework to add a route to the server
		#
		# path:: the path for the route
		# config:: a Class representing the Controller or a Hash options for the default behaviour of the route.
		#
		# the current options for the config are:
		#
		# file_root:: sets a root folder to serve files. defaults to nil (no root).
		# allow_indexing:: if a root folder is set, this sets th indexing option. defaults to false.
		def add_route path, config, &block
			# add route to server
			@router.add_route path, config, &block
			@router.routes.last
		end

		# starts the server - runs only once, on boot
		def start
			options = make_server_paramaters
			Rack::Handler.get(options.delete :server).run(options.delete(:app), options ) do |server|
				if defined?(Thin::Server) && server.is_a?(Thin::Server)
					if options[:SSLEnable] && options[:SSLCertificate] && options[:SSLPrivateKey]
						server.ssl = true
						server.ssl_options = {
							cert: options[:SSLCertificate], key: options[:SSLPrivateKey]
						}
					end
				elsif defined?(WEBrick::HTTPServer) &&  server.is_a?( WEBrick::HTTPServer)
				else
					Anorexic.logger.error "Could not start SSL service for this server class #{server.class}. not yet supported by Anorexic. SERVICE WILL BE UN-ENCRYPTED."
				end
			end
		end

		# this method sets up the server's paramaters and creates the server Proc that will be passed to the rack server.
		def make_server_paramaters
			#######
			# set up server paramaters
			server_params = {Port: @port, server: @rack_handlers}
			options = @params
			options[:file_root] ||=  options[:root] || false
			options[:server_params] ||= {}

			#######
			# set up middleware array
			options[:middleware] ||= []

			options[:middleware].push *Anorexic.default_middleware

			if options[:file_root]
				options[:middleware].unshift [Anorexic::AnoRack::ServeIndex, options[:file_root]]
			end

			if options[:debug]
				options[:middleware].unshift [Rack::ShowExceptions]
			else
				options[:middleware].unshift [Anorexic::AnoRack::Exceptions, options[:file_root]]
			end

			options[:middleware].unshift [Rack::ContentLength] unless options[:middleware].include? [Rack::ContentLength]
			# will not be using this gem after all
			# options[:middleware].unshift [Rack::UTF8Sanitizer] if ::Anorexic.default_encoding.to_s.downcase == 'utf-8'
			options[:middleware].unshift [Anorexic::AnoRack::ReEncoder, ::Anorexic.default_encoding]

			if Anorexic.logger
				options[:middleware].unshift [Rack::CommonLogger, Anorexic.logger]
			end
			options[:middleware] << [Anorexic::AnoRack::NotFound, options[:file_root]]

			#######
			# set up server paramaters
			if options[:vhost]
				server_params[:Host] = options[:vhost]
				server_params[:ServerAlias] = options[:s_alias]				
			end
			if options[:ssl_self]

				if options[:vhost]
					cert, rsa = Anorexic.create_self_signed_cert 1024, "CN=#{options[:vhost]}"
				else
					cert, rsa = Anorexic.create_self_signed_cert
				end
				server_params[:SSLEnable] = true
				server_params[:SSLVerifyClient] = OpenSSL::SSL::VERIFY_NONE
				server_params[:SSLCertificate] = cert
				server_params[:SSLPrivateKey] = rsa
				server_params[:SSLCertName] = [ [ "CN",(options[:vhost] || WEBrick::Utils::getservername) ] ]

			elsif options[:ssl_cert] && options[:ssl_pkey]
				server_params[:SSLEnable] = true
				server_params[:SSLVerifyClient] = OpenSSL::SSL::VERIFY_NONE
				server_params[:SSLCertificate] = options[:ssl_cert]
				server_params[:SSLPrivateKey] = options[:ssl_pkey]
			end

			#######
			# Builde the Rack server

			# look at: http://rubydoc.info/github/rack/rack/master/Rack/Server
			# also: http://rubydoc.info/github/rack/rack/file/SPEC
			server_params[:app] = Rack::Builder.new(@router) do

				options[:middleware].each do |middleware|
					if middleware.is_a? Array
						use *middleware
					end
					
				end

			end

			server_params.update(options[:server_params])
			server_params
		end

		# shuts down the server. it's called by the system, but never used as rack server's handle shutdown themselves.
		def shutdown
			if defined? ::EventMachine
				if ::EventMachine.reactor_running?
					::EventMachine.stop
					return
				end
			end
			exit
		end

	end
end
