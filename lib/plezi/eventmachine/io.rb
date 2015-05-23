module Plezi
	module EventMachine

		class BasicIO

			attr_reader :io, :params
			def initialize io, params
				@io, @params = io, params
			end
			def clear?
				false
			end
			def call
				begin
					socket = io.accept_nonblock
					handler = Plezi::Connection.new socket, @params
					EventMachine.add_io socket, handler					
				rescue Errno::EWOULDBLOCK => e

				rescue => e
					Plezi.error e
				end
			end
		end
		module_function

		EM_IO = {}
		IO_LOCKER = Mutex.new

		# Adds an io object to the Plezi event machine.
		#
		# accepts:
		# io:: an actual IO object (i.e. socket) that can be passed on to IO.select.
		# job:: an object that answers to #call. job#call will be called whenever the IO object is flagged by IO.select.
		#
		def add_io io, job
			IO_LOCKER.synchronize { EM_IO[io] = job }
		end

		def remove_io io
			IO_LOCKER.synchronize { (EM_IO.delete io).close rescue true }
		end

		def clear_connections
			IO_LOCKER.synchronize { EM_IO.delete_if { |io, c| c.clear? } }
		end

		def forget_connections
			IO_LOCKER.synchronize { EM_IO.clear }
		end

		def stop_connections
			IO_LOCKER.synchronize { EM_IO.each { |io, c| Plezi.run_async { c.disconnect rescue true }  } }
		end

		# set the default idle waiting time.
		@io_timeout = 0.1

		# Plezi event cycle settings: how long to wait for IO activity before forcing another cycle.
		#
		# No timing methods will be called during this interval.
		#
		# Gets the current idle setting. The default setting is 0.1 seconds.
		def io_timeout
			@io_timeout
		end
		# Plezi event cycle settings: how long to wait for IO activity before forcing another cycle.
		#
		# No timing methods will be called during this interval (#run_after / #run_every).
		# 
		# It's rare, but it's one of the reasons for the timeout: some connections might wait for the timeout befor being established.
		#
		# set the current idle setting
		def io_timeout= value
			@io_timeout = value
		end

		SELECT_LOCKER = Mutex.new
		# hangs for IO data
		def review_io
			return false if IO_LOCKER.locked?
			IO_LOCKER.synchronize do
				return false unless queue_empty? && EM_IO.any?
				io_array = EM_IO.keys
				begin
					io_r = ::IO.select(io_array, nil, io_array, @io_timeout)
					return false unless io_r
					io_r[0].each {|io| queue [], EM_IO[io] }
					io_r[2].each { |io| EM_IO.delete io }
				rescue Errno::EWOULDBLOCK => e

				rescue => e
					EM_IO.delete_if {|io, job| io.closed?}
					raise e
				end
				true
			end
		end

	end

	module_function

	# Plezi event cycle settings: how long to wait for IO activity before forcing another cycle.
	#
	# No timing methods will be called during this interval.
	#
	# Gets the current idle setting. The default setting is 0.1 seconds.
	def idle_sleep
		EventMachine.io_timeout
	end
	# Plezi event cycle settings: how long to wait for IO activity before forcing another cycle.
	#
	# No timing methods will be called during this interval (#run_after / #run_every).
	# 
	# It's rare, but it's one of the reasons for the timeout: some connections might wait for the timeout befor being established.
	#
	# set the current idle setting
	def idle_sleep= value
		EventMachine.io_timeout = value
	end

	# public API to add a service to the framework.
	# accepts a Hash object with any of the following options (Hash keys):
	# port:: port number. defaults to 3000 or the port specified when the script was called.
	# host:: the host name. defaults to any host not explicitly defined (a catch-all).
	# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
	# root:: the public root folder. if this is defined, static files will be served from the location.
	# assets:: the assets root folder. defaults to nil (no assets support). if the path is defined, assets will be served from `/assets/...` (or the public_asset path defined) before any static files. assets will not be served if the file in the /public/assets folder if up to date (a rendering attempt will be made for systems that allow file writing).
	# assets_public:: the assets public uri location (uri format, NOT a file path). defaults to `/assets`. assets will be saved (or rendered) to the assets public folder and served as static files.
	# assets_callback:: a method that accepts one parameters: `request` and renders any custom assets. the method should return `false` unless it has created a response object (`response = Plezi::HTTPResponse.new(request)`) and sent a response to the client using `response.finish`.
	# save_assets:: saves the rendered assets to the filesystem, under the public folder. defaults to false.
	# templates:: the templates root folder. defaults to nil (no template support). templates can be rendered by a Controller class, using the `render` method.
	# ssl:: if true, an SSL service will be attempted. if no certificate is defined, an attempt will be made to create a self signed certificate.
	# ssl_key:: the public key for the SSL service.
	# ssl_cert:: the certificate for the SSL service.
	#
	# some further options, which are unstable and might be removed in future versions, are:
	# protocol:: the protocol objects (usually a class, but any object answering `#call` will do).
	# handler:: an optional handling object, to be called upon by the protocol (i.e. #on_message, #on_connect, etc'). this option is used to allow easy protocol switching, such as from HTTP to Websockets. 
	#
	# Duringn normal Plezi behavior, the optional `handler` object will be returned if `listen` is called more than once for the same port.
	#
	# assets:
	#
	# assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively)
	# before sending them as static files.
	#
	# templates:
	#
	# ERB, Slim and Haml are natively supported.
	#
	def listen parameters = {}
		# update default values
		parameters = {assets_public: '/assets'}.update(parameters)

		# set port if undefined
		if !parameters[:port] && defined? ARGV
			if ARGV.find_index('-p')
				port_index = ARGV.find_index('-p') + 1
				parameters[:port] ||= ARGV[port_index].to_i
				ARGV[port_index] = (parameters[:port] + 1).to_s
			else
				ARGV << '-p'
				ARGV << '3001'
				parameters[:port] ||= 3000
			end
		end

		#keeps information of past ports.
		@listeners ||= {}
		@listeners_locker = Mutex.new

		# check if the port is used twice.
		if @listeners[parameters[:port]]
			puts "WARNING: port aleady in use! returning existing service and attemptin to add host (maybe multiple hosts? use `host` instead)." unless parameters[:host]
			@active_router = @listeners[parameters[:port]].params[:handler] || @listeners[parameters[:port]].params[:protocol]
			@active_router.add_host parameters[:host], parameters if @active_router.is_a?(HTTPRouter)
			return @active_router
		end

		# make sure the protocol exists.
		unless parameters[:protocol]
			parameters[:protocol] = HTTPProtocol
			parameters[:handler] ||=  HTTPRouter.new
		end

		# create the EventMachine IO object.
		io = EventMachine::BasicIO.new TCPServer.new(parameters[:port]), parameters
		EventMachine.add_io io.io, io
		@listeners_locker.synchronize { @listeners[parameters[:port]] = io }
		# set the active router to the handler or the protocol.
		@active_router = (parameters[:handler] || parameters[:protocol])
		@active_router.add_host(parameters[:host], parameters) if @active_router.is_a?(HTTPRouter)

		Plezi.run_async { Plezi.info "Started listening on port #{parameters[:port]}." }

		# return the current handler or the protocol..
		@active_router
	end

	# Closes and removes listening IO's registered by Plezi using #listen
	def stop_services
		info 'Stopping services'
		@listeners_locker.synchronize { @listeners.each {|port, io| EventMachine.remove_io(io.io); info "Stoped listening on port #{port}" } ; @listeners.clear } if @listeners
		true
	end

end