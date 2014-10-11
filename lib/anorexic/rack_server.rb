module Anorexic


	# This is the main Server class for the anorexic framework.
	#
	# since this is actually a rack based server class,
	# and since rack is actually server agnostic...
	#
	# ... it is actually possible to use any server that has a Rack:Handler, not just the thin server:
	#    listen 80, server: 'puma'
	#
	# Thin is the default server if no 'server' option is passed. If Thin isn't available, Puma will be tested for.
	# Webrick, which is the Ruby build-in server, will be the last resort default server.
	#
	# it is possible to change the default server using:
	#
	#    Anorexic::RackServer.default_server = 'webrick'
	#
	class RackServer
		# holds the server object
		attr_reader :server
		# holds the port set for the server object
		attr_reader :port
		# holds any paramaters used for the server
		attr_reader :params
		# holds the array of routs
		attr_reader :routes
		# holds the rack handler's name (defaults to 'thin')
		attr_reader :rack_handlers

		# this is called by the Anorexic framework to initialize the server and set it's parameters.
		def initialize(port = 3000, params = {})
			@server = nil
			@port, @params = port, params
			@routes = []
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
			@routes << [path, config, block]
		end

		# starts the server - runs only once, on boot
		def start
			@server = Rack::Server.start make_server_paramaters
		end

		# this method sets up the server's paramaters and creates the server Proc that will be passed to the rack server.
		def make_server_paramaters
			#######
			# set up server paramaters
			server_params = {Port: @port, server: @rack_handlers}
			options = @params
			options[:server_params] ||= {}
			if ENV["RACK_ENV"] && ENV["RACK_ENV"] == "development"
				options[:middleware] ||= [[Rack::ShowExceptions]]
			else
				options[:middleware] ||= []
			end

			# add controller magic :)
			@routes.each_index do |i|
				config = @routes[i][1]
				@routes[i][1] = add_magic(config) if config.is_a? Class
			end

			ssl_options = nil

			if options[:vhost]
				server_params[:Host] = options[:vhost]
				server_params[:ServerAlias] = options[:s_alias]				
			end

			if options[:ssl_self]

				if options[:vhost]
					cert, rsa = create_self_signed_cert 1024, "CN=#{options[:vhost]}"
				else
					cert, rsa = create_self_signed_cert
				end
				server_params[:SSLEnable] = true
				server_params[:SSLVerifyClient] = OpenSSL::SSL::VERIFY_NONE
				server_params[:SSLCertificate] = cert
				server_params[:SSLPrivateKey] = rsa
				server_params[:SSLCertName] = [ [ "CN",(options[:vhost] || WEBrick::Utils::getservername) ] ]

			elsif options[:ssl_cert] && options[:ssl_pkey]
				ssl_options = {
					:verify_peer => false,
				}
			end

			#######
			# start the server up

			# look at: http://rubydoc.info/github/rack/rack/master/Rack/Server
			# also: http://rubydoc.info/github/rack/rack/file/SPEC
			rack_wrapper = Rack::Builder.new(self) do

				if Anorexic.logger
					use Rack::CommonLogger, Anorexic.logger
				end

				options[:middleware].each do |middleware|
					if middleware.is_a? Array
						use *middleware
					end
					
				end

				if options[:allow_indexing] && options[:file_root]
					Anorexic.logger.error "Directory listing not supported on `listen` - use route instead"
				elsif options[:file_root]
					Anorexic.logger.error "Static file serving is not supported on `listen` - use route instead"
				end

			end

			server_params[:app] = Proc.new do |env|
				begin
					# re-encode to utf-8, as it's all BINARY encoding at first
					env["rack.input"].rewind
					env['rack.input'] = StringIO.new env["rack.input"].read.encode("utf-8", "binary", invalid: :replace, undef: :replace, replace: '')
					rack_wrapper.call env
				rescue Exception => e
					if Anorexic.logger
						Anorexic.logger.error << e
					else
						warn e
					end

					request = Rack::Request.new(env)

					not_found = nil
					if defined? Anorexic::FeedHaml
						puts "looking for 500.html.haml file."
						not_found = Anorexic::FeedHaml.render "500".to_sym, locals: { request: request, error: e}
					end
					unless not_found
						puts "looking for 500.html file."
						path_to_404 = Root.join("public", "500.html").to_s if defined? Root
						path_to_404 ||= Pathname.new('.').expand_path.join("public", "400.html").to_s
						not_found = IO.read path_to_404 if File.exist?(path_to_404)
					end
					not_found = 'Sorry, something went wrong... internal server error 500 :-(' unless not_found
					response = Rack::Response.new [not_found], 502
					response.finish
				end
			end
			server_params.update(options[:server_params])
			server_params
		end

		# this is the main request handling proc, before it's wrapped using the make_server_paramaters
		#
		# this proc which will use the routing table set in the @routes array.
		#
		# it relays heavily on the agnostic Rack::Request class:
		# http://rubydoc.info/github/rack/rack/Rack/Request
		#
		# it also relays on the Rack::Response class:
		# http://rubydoc.info/github/rack/rack/Rack/Response
		#
		# runs for every request
		def call env
			# set request object
			request = Rack::Request.new(env)
			# easy lookup
			params = request.params
			# allow lookup of params as keys run:
			make_hash_accept_symbols hash: params
			make_hash_accept_symbols hash: request.cookies
			### not supported by some servers... commented out.
			# emulate DELETE & PUT is the same way Rails eulates them (consistancy)
			# if %w{PUT DELETE}.include? params[:_method].to_s.upcase
			# 	request.env["REQUEST_METHOD"] = params[:_method].upcase
			# end

			# remember original request path
			original_request_path = request.path

			# match routes and get correct handler
			@routes.each do |r|
				route_path, config, block = *r
				# check if paths fit and extract any inline paramaters from path
				paths_fit, inline_params = self.class.match_path(route_path, original_request_path.dup, config)
				request.env["PATH_INFO"] = original_request_path
				next unless paths_fit

				# add any inline params (implied params["id"])
				old_params = {}
				inline_params.each {|k,v| old_params[k] = params[k]}
				params.update inline_params

				if config.is_a? Hash
					if config[:file_root]
						static_proc = Proc.new {|env| false}
						public_folder_listing = Dir[File.join(config[:file_root], "**","*")].map {|f| f.gsub config[:file_root], ""}
						r = Rack::Static.new( static_proc, urls: public_folder_listing, root: config[:file_root].to_s, index: 'index.html').call(env)
						return r if r && r[0] != 404
						if config[:allow_indexing]
							r = Rack::Directory.new(config[:file_root]).call(env)
							return r if r && r[0] != 404
						end
					end
					if block
						response = Rack::Response.new
						response["Content-Type"] = ::Anorexic.default_content_type
						return response.finish if block.call(request,response)						
					end
				elsif config.is_a? Class #Anorexic::StubController
					#######################
					## MVC Magic happens here
					controller = config.new env, request, params
					return controller.response.finish if controller._route_path_to_methods_and_set_the_response_
				end
				# restore original param state
				old_params.each do |k,v|
					params[k] = v
					params.delete k if v.nil?
				end
			end

			########################
			# 404 not found
			# routes finished. if we got all the way here, need to return a 404.

			# new response object
			response = Rack::Response.new

			not_found = nil
			if defined? Anorexic::FeedHaml
				not_found = Anorexic::FeedHaml.render "404".to_sym, locals: { request: request, path: original_request_path}
			end
			unless not_found
				puts "looking for 404.html file."
				path_to_404 = Root.join("public", "404.html").to_s if defined? Root
				path_to_404 ||= Pathname.new('.').expand_path.join("public", "404.html").to_s
				not_found = IO.read path_to_404 if File.exist?(path_to_404)
			end
			not_found = 'Sorry, you requested something we don\'t have yet... error 404 :-(' unless not_found
			response = Rack::Response.new [not_found], 404
			response.finish
		end

		# tweeks the params hash to accept :symbols in addition to strings (similar to Rails, but probably different, as two keys, such as "id" and :id can co-exist if the developer isn't careful).
		def make_hash_accept_symbols hash
			df_proc = Proc.new do |hs,k|
				if k.is_a?(Symbol) && hs.has_key?( k.to_s)
					hs[k.to_s]
				elsif k.is_a?(String) && hs.has_key?( k.to_sym)
					hs[k.to_sym]
				end
			end
			hash.values.each do |v|
				if v.is_a?(Hash)
					v.default_proc = df_proc
					make_hash_accept_symbols v
				end
			end
		end

		# this is the routes interpreter
		#
		# route can be:
		# Regexp:: used to test request path against regular expressions.
		# *:: used to catch all routes - same as passing Regexp /[.]*/
		# '/':: if used with config[:file_root], sends all files matching request path in :file_root folder
		# implied_id:: for the MVC, if a Controller is passed, checks for an implied :id paramater (:id passed in path instead of quary string).
		# implied_path:: for the MVC, if a Controller is passed, tests for methods in the controller (defining more methods auto-directs to them). 
		# 
		def self.match_path route_path, request_path, config
			request_path = request_path.chomp('/')
			
			if route_path.is_a? Regexp
				return true, {} if route_path.match request_path
				return false, {}
			end

			if defined? route_path.call
				return route_path.call request_path
			end

			if route_path[0] == '*' || ( config.is_a?(Hash) && config[:file_root] && route_path == '/' )
				return true, {}
			end

			# fix paths as arrays
			route_array = route_path.split('/')
			route_array.delete("")
			request_array = request_path.split('/')
			request_array.delete("")

			if route_array == request_array
				return true, {}
			end

			# now is the time for some magic routes...

			# Magic exclusive for MVC - implied :id paramater / nested paths
			if config.is_a?(Class)
				# checks for implied :id paramater.
				# this will also induce the nested path magic in the controller.
				if route_array.length == (request_array.length-1) && route_array == request_array[0..-2]
					return true , {"id" => request_array.last}
					
				end
			end

			# optional paramaters magic...?
			return false, {} unless route_path.match /[\:\(]/

			# # not yet supported, and not really needed any more
			# # (mvc implied :id covers most use-cases)
			# #
			# # should for the hidden paramater which is the implied :id
			# #
			# if route_array.length >= (config.is_a?(Class) ? (request_array.length + 1) : request_array.length)
			# 	# find center of gravity for route_array
			# 	i = 0


			# 	# centralize request_array with route_array

			# 	# fill in paramaters, including implied :id, if relevant, and send

			# end
			return false, {}
		end

		# injects the magic to the controller
		#
		# adds the `redirect_to` and `send_data` methods to the controller class, as well as the properties:
		# env:: the env recieved by the Rack server.
		# params:: the request's paramaters.
		# cookies:: the request's cookies.
		# flash:: an amazing Hash object that sets temporary cookies for one request only - greate for saving data between redirect calls.
		#
		def add_magic(controller)
			new_class_name = "AnorexicMegicRuntimeController_#{controller.name.gsub /[\:\-]/, '_'}"
			return Module.const_get new_class_name if Module.const_defined? new_class_name
			ret = Class.new(controller) do
				include Anorexic::ControllerMagic

				def initialize env, request, params
					@env, @params, @request = env, params, request
					@response = Rack::Response.new
					@response["Content-Type"] = ::Anorexic.default_content_type
					@cookies = request.cookies

					# propegate flash object
					@flash = Hash.new do |hs,k|
						hs["anorexic_flash_#{k}"] if hs.has_key? "anorexic_flash_#{k}"
					end
					cookies.each do |k,v|
						@flash[k] = v if k.start_with? "anorexic_flash_"
					end
					super *[]
				end

				def after
					# remove old flash
					if defined?(super)
						ret = super
						return false if ret == false
					end
					ret ||= true

					cookies.keys.each do |k|
						if k.start_with? "anorexic_flash_"
							response.delete_cookie k
							flash.delete k
						end
					end
					#set new flash cookies
					@flash.each do |k,v|
						response.set_cookie "anorexic_flash_#{k.to_s}", v
					end
					ret
				end

				def _route_path_to_methods_and_set_the_response_
					available_methods = self.methods
					available_public_methods = (self.class.superclass.public_instance_methods - Object.public_instance_methods) - [:before, :after, :save, :show, :update, :delete, :initialize]
					return false if available_methods.include?(:before) && before == false
					got_from_action = false
					if params && params["id"]
						if (request.delete? || params["_method"].to_s.upcase == 'DELETE') && available_methods.include?(:delete) && !available_public_methods.include?(params["id"].to_sym)
							got_from_action = delete
						elsif request.get?
							if params["id"].to_s[0] != "_" && available_public_methods.include?(params["id"].to_sym)
								got_from_action = self.send params["id"].to_sym
							elsif available_methods.include?(:show)
								got_from_action = show
							end
						elsif (request.put? || request.post? ) && available_methods.include?(:update)
							got_from_action = update
						end
					else
						if request.get? && available_methods.include?(:index)
							got_from_action = index
						elsif (request.put? || request.post?) && available_methods.include?(:save)
							got_from_action = save
						end
					end
					unless got_from_action
						return false
					end
					return false if (available_methods.include?(:after) && after == false)
					response.write got_from_action if got_from_action != true
					return true
				end
			end
			Object.const_set(new_class_name, ret)
			ret
		end

		# shuts down the server. it's called by the system, but never used as rack server's handle shutdown themselves.
		def shutdown
			if defined? EventMachine && EventMachine.reactor_running?
				EventMachine.stop
			elsif Rack::Server.resopnd_to? :stop
				Rack::Server.stop
			elsif
				exit
			end
		end

		# Copied from the Ruby core WEBrick project, in order to create self signed certificates...
		#
		# ...but many Rack servers don't support SSL any way. WEBrick does (on rack as well as on stand-alone).
		def create_self_signed_cert(bits=1024, cn=nil, comment='a self signed certificate for when we only need encryption and no more.')

			cn ||= "CN=#{WEBrick::Utils::getservername}"

			rsa = OpenSSL::PKey::RSA.new(bits){|p, n|
			case p
			when 0; $stderr.putc "."  # BN_generate_prime
			when 1; $stderr.putc "+"  # BN_generate_prime
			when 2; $stderr.putc "*"  # searching good prime,
			                          # n = #of try,
			                          # but also data from BN_generate_prime
			when 3; $stderr.putc "\n" # found good prime, n==0 - p, n==1 - q,
			                          # but also data from BN_generate_prime
			else;   $stderr.putc "*"  # BN_generate_prime
			end
			}
			cert = OpenSSL::X509::Certificate.new
			cert.version = 2
			cert.serial = 1
			name = OpenSSL::X509::Name.parse(cn)
			cert.subject = name
			cert.issuer = name
			cert.not_before = Time.now
			cert.not_after = Time.now + (365*24*60*60)
			cert.public_key = rsa.public_key

			ef = OpenSSL::X509::ExtensionFactory.new(nil,cert)
			ef.issuer_certificate = cert
			cert.extensions = [
			ef.create_extension("basicConstraints","CA:FALSE"),
			ef.create_extension("keyUsage", "keyEncipherment"),
			ef.create_extension("subjectKeyIdentifier", "hash"),
			ef.create_extension("extendedKeyUsage", "serverAuth"),
			ef.create_extension("nsComment", comment),
			]
			aki = ef.create_extension("authorityKeyIdentifier",
			                        "keyid:always,issuer:always")
			cert.add_extension(aki)
			cert.sign(rsa, OpenSSL::Digest::SHA1.new)

			return [ cert, rsa ]
		end

	end



end
