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
				@sass_cache = Sass::CacheStores::Memory.new if defined?(::Sass)
			end

			# adds a host to the router (or activates an existing host to add new routes). accepts a host name and any parameters not related to the actual connection (ssl etc') (see {Plezi.listen})
			def add_host host_name, params = {}
				host_name = (host_name ? host_name.to_s.downcase : :default)
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
					Base::HTTPSender.send_by_code request, response, 404
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
				return false unless params[:assets] && request.path.match(/^#{params[:assets_public]}\/.+/)
				# review callback, if defined
				return true if params[:assets_callback] && params[:assets_callback].call(request, response)

				# get file requested
				source_file = File.join(params[:assets], *(request.path.match(/^#{params[:assets_public]}\/(.+)/)[1].split('/')))

				# stop if file name is reserved / has security issues
				return false if source_file.match(/(scss|sass|coffee|\.\.\/)$/)

				# set where to store the rendered asset
				target_file = false
				target_file = File.join( params[:root], params[:assets_public], *request.path.match(/^#{params[:assets_public]}\/(.*)/)[1].split('/') ) if params[:root]

				# send the file if it exists (no render needed)
				if File.exists?(source_file)
					data = Plezi.cache_needs_update?(source_file) ? Plezi.save_file(target_file, Plezi.reload_file(source_file), params[:save_assets]) : Plezi.load_file(source_file)
					return (data ? Base::HTTPSender.send_raw_data(request, response, data, MimeTypeHelper::MIME_DICTIONARY[::File.extname(source_file)]) : false)
				end

				# render supported assets
				case source_file
				when /\.css$/
					sass = source_file.gsub /css$/, 'sass'
					sass.gsub! /sass$/, 'scss' unless Plezi.file_exists?(sass)
					return false unless Plezi.file_exists?(sass)
					# review mtime and render sass if necessary
					if defined?(::Sass) && refresh_sass?(sass)
						eng = Sass::Engine.for_file(sass, cache_store: @sass_cache)
						Plezi.cache_data sass, eng.dependencies
						css, map = eng.render_with_sourcemap(params[:assets_public])
						Plezi.save_file target_file, css, params[:save_assets]
						Plezi.save_file (target_file + ".map"), map, params[:save_assets]
					end
					# try to send the cached css file which started the request.
					return Base::HTTPSender.send_file request, response, target_file
				when /\.js$/
					coffee = source_file.gsub /js$/i, 'coffee'
					return false unless Plezi.file_exists?(coffee)
					# review mtime and render coffee if necessary
					if defined?(::CoffeeScript) && Plezi.cache_needs_update?(coffee)
						# render coffee to cache
						Plezi.cache_data coffee, nil
						Plezi.save_file target_file, CoffeeScript.compile(IO.binread coffee), params[:save_assets]
					end
					# try to send the cached js file which started the request.
					return Base::HTTPSender.send_file request, response, target_file
				end
				false
			end
			def refresh_sass? sass
				return false unless File.exists?(sass)
				return true if Plezi.cache_needs_update?(sass)
				mt = Plezi.file_mtime(sass)
				Plezi.get_cached(sass).each {|e| return true if File.exists?(e.options[:filename]) && (File.mtime(e.options[:filename]) > mt)} # fn = File.join( e.options[:load_paths][0].root, e.options[:filename]) 
				false
			end

		end
	end
end
