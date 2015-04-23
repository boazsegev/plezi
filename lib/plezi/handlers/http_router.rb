module Plezi
	#####
	# this is a Handler stub class for an HTTP echo server.
	class HTTPRouter

		# the hosts dictionary router.hosts['www.foo.com'] == HTTPHost
		attr_reader :hosts
		# the current active host object
		attr_reader :active_host

		# initializes an HTTP router (the normal Handler for HTTP requests)
		#
		# the router holds the different hosts and sends them messages/requests.
		def initialize
			@hosts = {}
			@active_host = nil
		end

		# adds a host to the router (or activates an existing host to add new routes). accepts a host name and any parameters not related to the service (see `Plezi.add_service`)
		def add_host host_name, params
			host_name = (host_name ? host_name.to_s.downcase : :default)
			@hosts[host_name] ||= HTTPHost.new params
			add_alias host_name, *params[:alias] if params[:alias]
			@active_host = @hosts[host_name]
		end
		# adds an alias to an existing host name (normally through the :alias parameter in the `add_host` method).
		def add_alias host_name, *aliases
			return false unless @hosts[host_name]
			aliases.each {|a| @hosts[a.to_s.downcase] = @hosts[host_name]}
			true
		end

		# adds a route to the active host. The active host is the last host referenced by the `add_host`.
		def add_route path, controller, &block
			raise 'No Host defined.' unless @active_host
			@active_host.add_route path, controller, &block
		end

		# adds a route to all existing hosts.
		def add_shared_route path, controller, &block
			raise 'No Host defined.' if @hosts.empty?
			@hosts.each {|n, h| h.add_route path, controller, &block }
		end
		
		# handles requests send by the HTTP Protocol (HTTPRequest objects)
		def on_request request
			request.service.timeout = 300
			if request[:host_name] && hosts[request[:host_name].to_s.downcase]
				hosts[request[:host_name].downcase].on_request request
			elsif hosts[:default]
				hosts[:default].on_request request
			else
				HTTPResponse.new( request, 404, {'content-type' => 'text/plain', 'content-length' => '15'}, ['host not found.']).finish
			end
			request.service.timeout = 5
		end
		# handles requests send by Rack - dresses up as Middleware, for Rack (if you're don't like WebSockets, go ahead...)
		def call env
			if env['HOST'] && hosts[env['HOST'].downcase]
				hosts[env['HOST'].downcase].call env
			elsif hosts[:default]
				hosts[:default].call env
			else
				[404, {'content-type' => 'text/plain', 'content-length' => '15'}, ['host not found.'] ]
			end
		end
	end

end
