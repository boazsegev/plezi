module Anorexic
	#####
	# this is a Handler stub class for an HTTP echo server.
	class HTTPRouter

		# the hosts dictionary router.hosts['www.foo.com'] == HTTPHost
		attr_reader :hosts
		# the current active host object
		attr_reader :active_host

		def initialize
			@hosts = {}
			@active_host = nil
		end

		def add_host host_name, params
			host_name = host_name ? host_name.downcase : :default
			@hosts[host_name] ||= HTTPHost.new params
			add_alias host_name, *params[:alias] if params[:alias]
			@active_host = @hosts[host_name]
		end
		def add_alias host_name, *aliases
			return false unless @hosts[host_name]
			aliases.each {|a| @hosts[a] = @hosts[host_name]}
			true
		end

		def add_route path, controller, &block
			raise 'No Host defined.' unless @active_host
			@active_host.add_route path, controller, &block
		end
		def add_shared_route path, controller, &block
			raise 'No Host defined.' if @hosts.empty?
			@hosts.each {|n, h| h.add_route path, controller, &block }
		end
		
		def on_request request
			request.service.timeout = false
			if request[:host_name] && hosts[request[:host_name].downcase]
				hosts[request[:host_name]].on_request request
			elsif hosts[:default]
				hosts[:default].on_request request
			else
				HTTPResponse.new( request, 404, {"content-type" => "text/plain", "content-length" => "15"}, ["host not found."]).finish
			end
			request.service.timeout = 5
		end
	end

end
