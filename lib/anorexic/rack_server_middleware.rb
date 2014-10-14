module Anorexic

	# This Module holds the Rack Middleware written to help with the Anorexic framework.
	#
	# They include:
	#
	# ReEncoder:: milddleware to safely re-encode requests from binary strings to utf-8.
	# NotFound:: milddleware to redirect 404 not found errors to the local 404.html file (or Haml).
	# Exceptions:: milddleware to redirect 500 internal server errors to the local 500.html file (or Haml).
	# ServeIndex:: milddleware to serve folder index files (the :index option for Rack::Static was causing issues).
	# Router:: this is the final middleware / actual application for the RackServer class.
	#
	module AnoRack

		# the ReEncoder Middleware re-encodes the request to UTF-8 format, unless a different encoding is set
		#
		# This should be safe for most http requests (even files are uploaded with compatible encodings, it's the far eastern languages that might be a bit of a complication).
		#
		class ReEncoder

			def initialize app, encoding = "utf-8"
				@encoding = encoding
				@app = app
			end
			def call env
				# re-encode to utf-8, as it's all BINARY encoding at first
				if @encoding
					env["rack.input"].rewind
					env['rack.input'] = StringIO.new env["rack.input"].read.encode(@encoding, "binary", invalid: :replace, undef: :replace, replace: '')		 	
					env.each do |k, v|
						if k.to_s.match /^[A-Z]/
							unless v.frozen?
								v.force_encoding("binary").encode!(@encoding, "binary", invalid: :replace, undef: :replace, replace: '') unless v.force_encoding(@encoding).valid_encoding?
							end
						end
					end
				end
				@app.call env
			end
		end


		# Middleware to report 404 not found errors or render the local 404.haml / 404.html file
		class NotFound
			def initialize app, root = nil
				@root = (root == false) || root || ::File.expand_path(File.join(Dir.pwd , 'public') )
				@app = app
			end
			def call env
				@app.call(env) || file_not_found(env)
			end
			def file_not_found env
				########################
				# 404 not found
				# routes finished. if we got all the way here, need to return a 404.

				not_found = nil
				unless @root == true
					if defined? Anorexic::FeedHaml
						not_found = Anorexic::FeedHaml.render( "404".to_sym, locals: { request: Rack::Request.new(env) })
					end
					unless not_found
						path_to_404 = ::File.join(@root, "404.html")
						not_found = ::File.open(path_to_404, ::File::RDONLY) if ::File.exist?(path_to_404)
					end
				end
				content_type = 'text/html'
				unless not_found
					not_found = 'Sorry, you requested something we don\'t have yet... error 404 :-('
					content_type = 'text/plain'
				end
				not_found = [not_found] if not_found.is_a? String
				[ 404, { 'Content-Type'  => content_type}, not_found ]
			end
		end

		# Middleware to report internal errors or render the local 500.haml / 500.html file
		class Exceptions
			def initialize app, root = nil
				@root = (root == false) || root || ::File.expand_path(File.join(Dir.pwd , 'public') )
				@app = app
			end
			def call env
				begin
					@app.call env
				rescue Exception => e
					exception_thrown e, env
				end
			end
			def exception_thrown e, env
				if Anorexic.logger
					Anorexic.logger.error e
					Anorexic.logger.error e.backtrace.join("\n")
				else
					puts "ERROR: #{e.to_s}"
					puts e.backtrace.join("\n")
				end

				message = false
				unless @root == true
					if defined? Anorexic::FeedHaml
						message = Anorexic::FeedHaml.render "500".to_sym, locals: { request: Rack::Request.new(env), error: e}
					end
					unless message
						path_to_500 = File.join(@root, "500.html")
						message = ::File.open(path_to_500, ::File::RDONLY) if File.exist?(path_to_500)
					end
				end
				content_type = 'text/html'
				unless message
					message = 'Sorry, something went wrong... internal server error 500 :-('
					content_type = 'text/plain'
				end
				message = [message] if message.is_a? String
				[ 500, { 'Content-Type'  => content_type}, message ]
			end
		end

		# Serves static files, including an index file in a folder
		# This was written because the :index option in Rack::Static breaks the code.
		# instead we deffer to Rack::File after some testing.
		class ServeIndex
			def initialize app, root, index_file = 'index.html'
				@index_name = index_file
				@root = root
				@app = app
			end
			def call env
				file_requested = env["PATH_INFO"].to_s.split('/')
				unless file_requested.include? ".."
					file_requested.shift
					pure_request = ::File.join(@root, *file_requested)
					if File.exists?(pure_request) && !::File.directory?(pure_request)
						return Rack::File.new(@root).call(env)
						# return [ 200, { 'Content-Type' => Rack::Mime.mime_type(::File.extname(pure_request)), 'Cache-Control' => 'public, max-age=86400'}, ::File.open(pure_request, ::File::RDONLY)]
					end			
					file_requested = ::File.join(@root, *file_requested, @index_name)
					if File.exists? file_requested
						return [ 200, { 'Content-Type'  => 'text/html', 'Cache-Control' => 'public, max-age=86400'}, ::File.open(file_requested, ::File::RDONLY)]
					end			
				end
				# the app call must be last, otherwise the 404.html will override the file serving option.
				@app.call env
			end
		end

	end

end
