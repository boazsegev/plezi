module Plezi
	#####
	# this is a Handler stub class for an HTTP echo server.
	class HTTPHost

		# the parameters / settings for the Host.
		attr_reader :params
		# the routing array
		attr_reader :routes

		# initializes an HTTP host with the parameters for the specific host.
		#
		# parameters are the same (almost) as `add_service` and include `root` for file root, `assets`
		# and other non service related options.
		def initialize params = {}
			@params = params.dup
			@routes = []
			# params[:save_assets] = true unless params[:save_assets] == false
			@params[:index_file] ||= 'index.html'
			@params[:assets_public] ||= '/assets'
			@params[:assets_public].chomp! '/'

			@sass_cache = Sass::CacheStores::Memory.new if defined?(::Sass)
			# @sass_cache_lock = Mutex.new
		end

		# adds a route under the specific host
		def add_route path, controller, &block
			routes << Route.new(path, controller, params, &block)
		end

		# handles requests sent to the host. returns true if the host delt with the request.
		#
		# since hosts are required to handle the requests (send 404 errors if resources arrn't found),
		# this method always returns true.
		def on_request request
			begin
				# render any assets?
				return true if render_assets request

				# send static file, if exists and root is set.
				return true if send_static_file request

				# return if a route answered the request
				routes.each {|r| return true if r.on_request(request) }

				# send folder listing if root is set, directory listing is set and folder exists

				#to-do

				#return error code or 404 not found
				send_by_code request, 404			
			rescue Exception => e
				# return 500 internal server error.
				Plezi.error e
				send_by_code request, 500
			end
			true
		end

		# Dresses up as a Rack app (If you don't like WebSockets, it's a reasonable aaproach).
		def call request
			request = Rack::Request.new request if defined? Rack
			ret = nil
			begin
				# render any assets?
				ret = render_assets request
				return ret if ret

				# send static file, if exists and root is set.
				ret = send_static_file request
				return ret if ret

				# return if a route answered the request
				routes.each {|r| ret = r.call(request); return ret if ret }

				# send folder listing if root is set, directory listing is set and folder exists

				#to-do

				#return error code or 404 not found
				return send_by_code request, 404			
			rescue Exception => e
				# return 500 internal server error.
				Plezi.error e
				return send_by_code request, 500
			end
			true
		end

		################
		## basic responses
		## (error codes and static files)

		# sends a response for an error code, rendering the relevent file (if exists).
		def send_by_code request, code, headers = {}
			begin
				@base_code_path ||= params[:templates] || File.expand_path('.')
				if defined?(::Slim) && Plezi.file_exists?(fn = File.join(@base_code_path, "#{code}.html.slim"))
					Plezi.cache_data fn, Slim::Template.new( fn ) unless Plezi.cached? fn
					return send_raw_data request, Plezi.get_cached( fn ).render( self, request: request ), 'text/html', code, headers
				elsif defined?(::Haml) && Plezi.file_exists?(fn = File.join(@base_code_path, "#{code}.html.haml"))
					Plezi.cache_data fn, Haml::Engine.new( IO.read( fn ) ) unless Plezi.cached? fn
					return send_raw_data request, Plezi.get_cached( File.join(@base_code_path, "#{code}.html.haml") ).render( self ), 'text/html', code, headers
				elsif defined?(::ERB) && Plezi.file_exists?(fn = File.join(@base_code_path, "#{code}.html.erb"))
					return send_raw_data request, ERB.new( Plezi.load_file( fn ) ).result(binding), 'text/html', code, headers
				elsif Plezi.file_exists?(fn = File.join(@base_code_path, "#{code}.html"))
					return send_file(request, fn, code, headers)
				end
				return true if send_raw_data(request, HTTPResponse::STATUS_CODES[code], 'text/plain', code, headers)
			rescue Exception => e
				Plezi.error e
			end
			false
		end

		# attempts to send a static file by the request path (using `send_file` and `send_raw_data`).
		#
		# returns true if data was sent.
		def send_static_file request
			return false unless params[:root]
			file_requested = request[:path].to_s.split('/')
			unless file_requested.include? '..'
				file_requested.shift
				file_requested = File.join(params[:root], *file_requested)
				return true if send_file request, file_requested
				return send_file request, File.join(file_requested, params[:index_file])
			end
			false
		end

		# sends a file/cacheed data if it exists. otherwise returns false.
		def send_file request, filename, status_code = 200, headers = {}
			if Plezi.file_exists?(filename) && !::File.directory?(filename)
				return send_raw_data request, Plezi.load_file(filename), MimeTypeHelper::MIME_DICTIONARY[::File.extname(filename)], status_code, headers
			end
			return false
		end
		# sends raw data through the connection. always returns true (data send).
		def send_raw_data request, data, mime, status_code = 200, headers = {}
			response = HTTPResponse.new request, status_code, headers
			response['cache-control'] = 'public, max-age=86400'					
			response << data
			response['content-length'] = data.bytesize
			response.finish
			true
		end

		###############
		## asset rendering and responses

		# renders assets, if necessary, and places the rendered result in the cache and in the public folder.
		def render_assets request
			# contine only if assets are defined and called for
			return false unless @params[:assets] && request.path.match(/^#{params[:assets_public]}\/.+/)
			# review callback, if defined
			return true if params[:assets_callback] && params[:assets_callback].call(request)

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
				return (data ? send_raw_data(request, data, MimeTypeHelper::MIME_DICTIONARY[::File.extname(source_file)]) : false)
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
				return send_file request, target_file
			when /\.js$/
				coffee = source_file.gsub /js$/i, 'coffee'
				return false unless Plezi.file_exists?(coffee)
				# review mtime and render coffee if necessary
				if defined?(::CoffeeScript) && Plezi.cache_needs_update?(coffee)
					# render coffee to cache
					Plezi.cache_data coffee, nil
					Plezi.save_file target_file, CoffeeScript.compile(IO.read coffee), params[:save_assets]
				end
				# try to send the cached js file which started the request.
				return send_file request, target_file
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
