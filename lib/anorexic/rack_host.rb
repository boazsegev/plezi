
module Anorexic

	# This is part of the main Server class for the Anorexic framework.
	#
	# This class is attached to a host (admin.foo.com / www.bar.com) and handles it's requests.
	#
	# this class makes it possible to create 'virtual hosts' with Anorexic using the `listen` call:
	#
	#      service = listen host: 'foo.bar.com'
	#
	#      route '/magic' Anorexic:StubController
	#
	#      listen service.port, host: 'bar.foo.com'
	#
	#      route '/people' Anorexic:StubController
	#
	#      shared_route '/' Anorexic:StubController
	#
	class RackHost
		# holds the router object
		attr_reader :router

		# this is called by the Anorexic framework to initialize the server and set it's parameters.
		def initialize(params = {})
			@router = Anorexic::AnoRack::Router.new
			make_service_app params
		end

		# this is called by the Anorexic framework to add a route to the server
		#
		# path:: the path for the route
		# controller:: a Class representing the Controller or a Hash options for the default behaviour of the route.
		#
		def add_route path, controller, &block
			# add route to server
			@router.add_route path, controller, &block
		end

		# handles any requests
		def call(env)
			@app(env) 
		end

		# this method sets up the server's paramaters and creates the server Proc that will be passed to the rack server.
		def make_service_app options
			#######
			# set up server paramaters
			options[:file_root] ||=  options[:root] || false

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
			# Build the Rack server

			# look at: http://rubydoc.info/github/rack/rack/master/Rack/Server
			# also: http://rubydoc.info/github/rack/rack/file/SPEC
			@app = Rack::Builder.new(@router) do

				options[:middleware].each do |middleware|
					if middleware.is_a? Array
						use *middleware
					end
					
				end

			end
		end
	end
end
