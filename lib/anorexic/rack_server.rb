
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
		# holds the hosts dictionary
		attr_reader :hosts
		# holds the active host
		attr_reader :active_host
		# holds the rack handler's name (defaults to 'thin')
		attr_reader :rack_handlers

		# this is called by the Anorexic framework to initialize the server and set it's parameters.
		def initialize(port = 3000, params = {})
			@port, @params = port, params
			@hosts = {}
			@active_host = Anorexic::AnoRack::RackHost.new params
			@server = nil
			@hosts[@params[:host] || :any] = @active_host
			@rack_handlers = params[:server] || self.class.default_server
		end

		# overrides the `Class.new` method to avoid double ports
		def self.new *args
			port = args[0] if args[0].is_a? Fixnum
			port ||= args[0][:port] if args[0].is_a? Hash
			raise "Requested port couldn't be found - couldn't create server." unless port
			s = (Anorexic::Application.instance.servers.select {|s| s.is_a?(RackServer) && defined?(s.port) && s.port == port})[0]
			return super *args unless s
			listen_params = args[1] if args[1].is_a?(Hash)
			listen_params ||= args[0] if args[0].is_a?(Hash)
			listen_params ||= Hash.new
			if listen_params[:host]
				if s.hosts[ listen_params[:host] ]
					puts "Virtual Host exists on #{ listen_params[:host] }, returning existing host (server specific paramaters will be ignored)."					
				else
					puts "Creating Virtual Host on #{ listen_params[:host] } - server specific paramaters will be ignored."
					s.hosts[ listen_params[:host] ] = Anorexic::AnoRack::RackHost.new(listen_params)
				end
				return s.hosts[listen_params[:host]]
			end
			puts "WARNING: service already created for port #{port} - returning the global host."
			unless s.hosts[:any]
				s.hosts[:any] = Anorexic::AnoRack::RackHost.new(listen_params)
			end
			return s.hosts[:any]
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
		# controller:: a Class representing the Controller or a Hash options for the default behaviour of the route.
		#
		# an optional block can be used instead of the controller:
		def add_route path, controller, &block
			# add route to server
			@active_host.add_route path, controller, &block
		end

		def add_alias host_alias
			raise "Cannot add an alias if no host is active" unless @active_host
			@hosts[host_alias] = @hosts[@active_host]
		end
		def call env
			if @hosts.is_a? Hash
				if @hosts[env["SERVER_NAME"]]
					@hosts[env["SERVER_NAME"]].call env
				elsif @hosts[:any]
					@hosts[:any].call env
				else
					return [404, {}, ["No server found for host name - error 404"]]	
				end
			else
				@hosts.call env
			end
		end

		# starts the server - runs only once, on boot
		def start
			options = make_server_paramaters
			Rack::Handler.get(options.delete :server).run(self, options ) do |server|
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
			# set up server paramaters
			if options[:ssl_self]

				hosts_names = "CN=#{WEBrick::Utils::getservername}"
				hosts_names_list = @hosts.keys
				hosts_names_list.delete :any
				hosts_names_list.each_index {|i| hosts_names << ";#{i}.CN=#{hosts_names_list[i]}"}

				cert, rsa = Anorexic.create_self_signed_cert
				server_params[:SSLEnable] = true
				server_params[:SSLVerifyClient] = OpenSSL::SSL::VERIFY_NONE
				server_params[:SSLCertificate] = cert
				server_params[:SSLPrivateKey] = rsa
				server_params[:SSLCertName] = [ [ "CN",(WEBrick::Utils::getservername) ] ]

			elsif options[:ssl_cert] && options[:ssl_pkey]
				server_params[:SSLEnable] = true
				server_params[:SSLVerifyClient] = OpenSSL::SSL::VERIFY_NONE
				server_params[:SSLCertificate] = options[:ssl_cert]
				server_params[:SSLPrivateKey] = options[:ssl_pkey]
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
