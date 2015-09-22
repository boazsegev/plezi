module Plezi

	module Base

		#####
		# handles the HTTP Routing
		class HTTPRouter

			class Host
				attr_reader :params
				attr_reader :routes
				def initialize params
					@params = params
					@routes = []
					params[:assets_public_regex] = /^#{params[:assets_public].to_s.chomp('/')}\/(.+)/.freeze
					params[:assets_refuse_templates] = /(#{AssetManager.all_extentions.join('|')}|\.\.\/)$/.freeze
				end
			end

			# return the upgrade handler (the self.on_upgrade method)
			def upgrade_proc
				self.method :on_upgrade
			end
			#handles websocket connection requests.
			def on_upgrade request, response
				host = get_host(request[:host_name].to_s.downcase) || @hosts[:default]
				return false unless host
				request.io[:params] = host.params
				# return if a route answered the request
				host.routes.each {|r| a = r.on_request(request, response); return a if a}
				# websockets should cut out here
				false
			end
			# initializes an HTTP router (the normal Handler for HTTP requests)
			#
			# the router holds the different hosts and sends them messages/requests.
			def initialize
				@hosts = {}
				@active_host = nil
			end

			# adds a host to the router (or activates an existing host to add new routes). accepts a host name and any parameters not related to the actual connection (ssl etc') (see {Plezi.listen})
			def add_host host_name, params = {}
				host_name = (host_name ? (host_name.is_a?(String) ? host_name.to_s.downcase : host_name) : :default)
				@active_host = get_host(host_name) || ( @hosts[host_name] = Host.new(params) )
				add_alias host_name, *params[:alias] if params[:alias]
				@active_host
			end
			# adds an alias to an existing host name (normally through the :alias parameter in the `add_host` method).
			def add_alias host_name, *aliases
				host = get_host host_name
				return false unless host
				aliases.each {|a| @hosts[a.to_s.downcase] = host}
				true
			end

			# adds a route to the active host. The active host is the last host referenced by the `add_host`.
			def add_route path, controller, &block
				raise 'No Host defined.' unless @active_host
				@active_host.routes << Route.new(path, controller, &block)
			end

			# adds a route to all existing hosts.
			def add_shared_route path, controller, &block
				raise 'No Host defined.' if @hosts.empty?
				@hosts.each {|n, h| h.routes << Route.new(path, controller, &block) }
			end

			# handles requests send by the HTTP Protocol (HTTPRequest objects)
			def call request, response
				begin
					host = get_host(request[:host_name].to_s.downcase) || @hosts[:default]
					return false unless host
					request.io[:params] = host.params
					# render any assets?
					return true if render_assets request, response, host.params
					# send static file, if exists and root is set.
					return true if Base::HTTPSender.send_static_file request, response
					# return if a route answered the request
					host.routes.each {|r| a = r.on_request(request, response); return a if a}
					#return error code or 404 not found
					return Base::HTTPSender.send_by_code request, response, 404 unless request[:io].params[:http_handler] == ::GRHttp::Base::Rack
				rescue => e				
					# return 500 internal server error.
					GReactor.error e
					Base::HTTPSender.send_by_code request, response, 500
				end
			end

			protected

			def get_host host_name
				@hosts.each {|k, v| return v if k === host_name}
				nil
			end

			###############
			## asset rendering and responses

			# renders assets, if necessary, and places the rendered result in the cache and in the public folder.
			def render_assets request, response, params
				# contine only if assets are defined and called for
				return false unless params[:assets] && (request.path =~ params[:assets_public_regex])
				# review callback, if defined
				return true if params[:assets_callback] && params[:assets_callback].call(request, response)

				# get file requested
				source_file = File.join(params[:assets], *(request.path.match(params[:assets_public_regex])[1].split('/')))


				# stop if file name is reserved / has security issues
				return false if File.directory?(source_file) || source_file =~ params[:assets_refuse_templates]

				# set where to store the rendered asset
				target_file = File.join( params[:public].to_s, params[:assets_public].to_s, *request.path.match(params[:assets_public_regex])[1].split('/') )

				# send the file if it exists (no render needed)
				if File.exists?(source_file)
					data = Plezi.cache_needs_update?(source_file) ? Plezi.save_file(target_file, Plezi.reload_file(source_file), (params[:public] && params[:save_assets])) : Plezi.load_file(source_file)
					return (data ? Base::HTTPSender.send_raw_data(request, response, data, MimeTypeHelper::MIME_DICTIONARY[::File.extname(source_file)]) : false)
				end

				# render the file if it's a registered asset
				data = ::Plezi::AssetManager.render source_file, binding
				if data
					return ::Plezi::Base::HTTPSender.send_raw_data request, response, Plezi.save_file(target_file, data, (params[:public] && params[:save_assets])), MimeTypeHelper::MIME_DICTIONARY[::File.extname(source_file)]
				end

				# send the data if it's a cached asset (map files and similar assets that were cached while rendering)
				if Plezi.cached?(source_file)
					return Base::HTTPSender.send_raw_data(request, response, Plezi.get_cached(source_file), MimeTypeHelper::MIME_DICTIONARY[::File.extname(source_file)])
				end

				# return false if an asset couldn't be rendered and wasn't found.
				return false
			end

		end
	end
end
