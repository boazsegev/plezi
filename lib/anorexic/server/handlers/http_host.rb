module Anorexic
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
			@params = params
			@routes = []
			params[:index_file] ||= 'index.html'
			params[:assets_public] ||= '/assets'
			params[:assets_public].chomp! '/'

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
				Anorexic.error e
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
				Anorexic.error e
				return send_by_code request, 500
			end
			true
		end

		# renders assets, if necessary, and places the rendered result in the cache and in the public folder.
		def render_assets request
			# contine only if assets are defined and called for
			return false unless @params[:assets] && request.path.match(/^#{params[:assets_public]}\/.+/)
			# call callback
			return true if params[:assets_callback] && params[:assets_callback].call(request)
			source_file = File.join(params[:assets], *(request.path.match(/^#{params[:assets_public]}\/(.+)/)[1].split('/')))
			# stop if file name is reserved
			return false if source_file.match(/(scss|sass|coffee|haml)$/)
			target_file = false
			target_file = File.join( params[:root], params[:assets_public], *request.path.match(/^#{params[:assets_public]}\/(.*)/)[1].split('/') )if params[:root]
			if !File.exists?(source_file)
				case source_file
				when /\.css$/
					source_file.gsub! /css$/, 'sass'
					source_file.gsub! /sass$/, 'scss' unless File.exists?(source_file)
					# if needs render, delete target file (force render).
					# File.delete(target_file) if force_sass_refresh?(source_file, target_file) # rescue true
				when /\.js$/
					source_file.gsub! /js$/i, 'coffee'
				end
			end
			return false unless File.exists?(source_file) && asset_needs_render?(source_file, target_file)
			# check sass / scss, coffee script
			case source_file
			when /\.scss$/, /\.sass$/
				if defined? ::Sass
					source_file, map = Sass::Engine.for_file(source_file, cache_store: @sass_cache).render_with_sourcemap(params[:assets_public])
					render_asset request, (target_file + '.map'), source_file rescue false
				else
					return false
				end
			when /\.coffee$/
				if defined? ::CoffeeScript
					source_file = CoffeeScript.compile(IO.read source_file)
				else
					return false
				end
			else
				source_file = IO.read source_file
			end
			render_asset(request, target_file, source_file)
		end

		# returns true if an asset needs to be rendered.
		def asset_needs_render? source_file, target_file
			return true unless Anorexic.file_exists?(target_file)
			raise 'asset verification failed - no such file?!' unless File.exists?(source_file)
			File.mtime(source_file) > Anorexic.file_mtime(target_file)
		end

		# checks sass dependecies, if a referesh is required (isn't in use, bacause of performance issues).
		def force_sass_refresh? source_file, target_file
			return false unless File.exists?(source_file) && Anorexic.file_exists?(target_file) && defined?(::Sass)
			Sass::Engine.for_file(source_file, cache_store: @sass_cache).dependencies.each {|e| return true if File.exists?(e.options[:filename]) && (File.mtime(e.options[:filename]) > File.mtime(target_file))} # fn = File.join( e.options[:load_paths][0].root, e.options[:filename]) 
			false
		end

		# renders an asset to the cache an attempt to save it to the file system.
		#
		# always returns false (data wasn't sent).
		def render_asset request, target, data
			Anorexic.save_file(target, data)
			return HTTPResponse.new( request, 200, {'content-type' => MimeTypeHelper::MIME_DICTIONARY[File.extname(target)] }, [data]).finish unless Anorexic.cached?(target)
			false
		end

		# sends a response for an error code, rendering the relevent file (if exists).
		def send_by_code request, code, headers = {}
			begin
				if params[:root]
					if defined?(::Haml) && Anorexic.file_exists?(File.join(params[:root], "#{code}.haml"))
						Anorexic.cache_data File.join(params[:root], "#{code}.haml"), Haml::Engine.new( Anorexic.load_file( File.join( params[:root], "#{code}.haml" ) ) ) unless Anorexic.cached? File.join(params[:root], "#{code}.haml")
						return send_raw_data request, Anorexic.get_cached( File.join(params[:root], "#{code}.haml") ).render( self, request: request), 'text/html', code, headers
					elsif defined?(::ERB) && Anorexic.file_exists?(File.join(params[:root], "#{code}.erb"))
						return send_raw_data request, ERB.new( Anorexic.load_file( File.join(params[:root], "#{code}.erb") ) ).result(binding), 'text/html', code, headers
					elsif Anorexic.file_exists?(File.join(params[:root], "#{code}.html"))
						return send_file(request, File.join(params[:root], "#{code}.html"), code, headers)
					end
				end
				return true if send_raw_data(request, HTTPResponse::STATUS_CODES[code], "text/plain", code, headers)
			rescue Exception => e
				Anorexic.error e
			end
			false
		end

		# attempts to send a static file by the request path (using `send_file` and `send_raw_data`).
		#
		# returns true if data was sent.
		def send_static_file request
			return false unless params[:root]
			file_requested = request[:path].to_s.split('/')
			unless file_requested.include? ".."
				file_requested.shift
				file_requested = File.join(params[:root], *file_requested)
				return send_file request, file_requested if Anorexic.file_exists?(file_requested) && !File.directory?(file_requested)
				return send_file request, File.join(file_requested, params[:index_file])
			end
			return false
		end

		# sends a file/cacheed data if it exists. otherwise returns false.
		def send_file request, filename, status_code = 200, headers = {}
			if Anorexic.file_exists?(filename) && !::File.directory?(filename)
				return send_raw_data request, Anorexic.load_file(filename), MimeTypeHelper::MIME_DICTIONARY[::File.extname(filename)], status_code, headers
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
		end

	end

end
