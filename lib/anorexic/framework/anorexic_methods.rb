
module Anorexic

	module_function

	#######################
	## Encoding?

	# # gets the default encoding used to encode (from binary) any incoming requests.
	# def default_encoding
	# 	Application.instance.default_encoding
	# end

	# # sets the default encoding used to encode (from binary) any incoming requests.
	# def default_encoding= encoding
	# 	Application.instance.default_encoding = encoding
	# end

	#######################
	## Logging
	module_function

	# the logger object
	@logger = ::Logger.new(STDOUT)

	# gets the active logger
	def logger
		@logger
	end
	# gets the active STDOUT copy, if exists
	def logger_copy
		@copy_to_stdout
	end

	# create and set the logger object. accepts:
	# log_file:: a log file name to be used for logging
	# copy_to_stdout:: if false, log will only log to file. defaults to true.
	def create_logger log_file = STDOUT, copy_to_stdout = false
		@copy_to_stdout = false
		@copy_to_stdout = ::Logger.new(STDOUT) if copy_to_stdout
		@logger = ::Logger.new(log_file)
		@logger
	end
	alias :set_logger :create_logger

	# writes a raw line to the log\
	def log_raw line
		@logger << line
		@copy_to_stdout << line if @copy_to_stdout
	end

	# logs info
	def log line
		@logger.info line
		@copy_to_stdout.info line if @copy_to_stdout
	end
	# logs info
	def info line
		@logger.info line
		@copy_to_stdout.info line if @copy_to_stdout
	end
	# logs warning
	def warn line
		@logger.warn line
		@copy_to_stdout.warn line if @copy_to_stdout
	end
	# logs errors
	def error line
		@logger.error line
		@copy_to_stdout.error line if @copy_to_stdout
	end
	# logs a fatal error
	def fatal line
		@logger.fatal line
		@copy_to_stdout.fatal line if @copy_to_stdout
	end

	#######################
	## Event Engine (Callbacks) / Multi-tasking
	protected
	module_function
	SHUTDOWN_CALLBACKS = []
	EVENTS = []
	LOCKER = Mutex.new

	# Anorexic event cycle settings: gets/sets how many worker threads Anorexic will run.
	def max_threads
		@max_threads ||= 16
	end
	def max_threads= value
		@max_threads = value
	end

	# Anorexic event cycle settings: how long to sleep during idle time, before forcing another cycle.
	def idle_sleep
		@idle_sleep ||= 0.1
	end
	def idle_sleep= value
		@idle_sleep = value
	end

	public
	module_function

	# returns true if there are any unhandled events
	def events?
		LOCKER.synchronize {!EVENTS.empty?}
	end

	# pushes and event to the event's stack
	#
	# accepts:
	# handler:: an object that answers to `call`, usually a Proc or a method.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	#
	# if a block is passed along, it will be used as a callback: the block will be called with the values returned by the handler's `call` method.
	def push_event handler, *args, &block
		if block
			LOCKER.synchronize {EVENTS << [(Proc.new {|a| Anorexic.push_event block, handler.call(*a)} ), args]}
		else
			LOCKER.synchronize {EVENTS << [handler, args]}
		end
	end

	# Public API. creates an asynchronous call to a method, with an optional callback:
	# demo use:
	# `callback( Kernel, :sleep, 1 ) { puts "this is a demo" }`
	# callback sets an asynchronous method call with a callback.
	#
	# paramaters:
	# object:: the object holding the method to be called (use `Kernel` for global methods).
	# method:: the method's name (Symbol). this is the method that will be called.
	# *arguments:: any additional arguments that should be sent to the method (the main method, not the callback).
	#
	# this method also accepts an optional block (the callback) that will be called once the main method has completed.
	# the block will recieve the method's returned value.
	#
	# i.e.
	#    puts 'while we wait for my work to complete, can you tell me your name?'
	#    Anorexic.callback(STDIO, :gets) do |name|
	#         puts "thank you, #{name}. I'm working on your request as we speak."
	#    end
	#    # do more work without waiting for the chat to start nor complete.
	def callback object, method, *args, &block
		push_event object.method(method), *args, &block
	end

	# Public API. adds a callback to be called once the services were shut down. see: callback for more info.
	def on_shutdown object=nil, method=nil, *args, &block
		if block && !object && !method
			LOCKER.synchronize {SHUTDOWN_CALLBACKS << [block, args]}
		elsif block
			LOCKER.synchronize {SHUTDOWN_CALLBACKS << [(Proc.new {|*a| block.call(object.method(method).call(*a))} ), args]}
		elsif object && method
			LOCKER.synchronize {SHUTDOWN_CALLBACKS << [object.method(method), args]}
		end
	end

	# Anorexic Engine, DO NOT CALL. pulls an event from the event's stack and processes it.
	def fire_event
		event = LOCKER.synchronize {EVENTS.shift}
		return false unless event
		begin
			event[0].call(*event[1])
		rescue OpenSSL::SSL::SSLError => e
			warn "SSL Bump - SSL Certificate refused?"
		rescue Exception => e
			raise if e.is_a?(SignalException) || e.is_a?(SystemExit)
			error e
		end
		true
	end

	# Anorexic Engine, DO NOT CALL. creates the thread pool and starts cycling through the events.
	def start_services
		# prepare threads
		exit_flag = false
		threads = []
		(max_threads).times {  Thread.new { thread_cycle until exit_flag }  }
		

		# Thread.new { check_connections until SERVICES.empty? }
		#...
		# set signal tarps
		trap('INT'){ exit_flag = true; raise "close Anorexic" }
		trap('TERM'){ exit_flag = true; raise "close Anorexic" }
		puts 'Services running. Press ^C to stop'
		# sleep until trap raises exception (cycling might cause the main thread to ignor signals and lose attention)
		(sleep unless SERVICES.empty?) rescue true
		# start shutdown.
		exit_flag = true
		# set new tarps
		trap('INT'){ puts 'Forced exit.'; Kernel.exit }#rescue true}
		trap('TERM'){ puts 'Forced exit.'; Kernel.exit }#rescue true }
		puts 'Started shutdown process. Press ^C to force quit.'
		# shut down listening sockets
		stop_services
		# disconnect active connections
		stop_connections
		# cycle down threads
		info "Waiting for workers to cycle down"
		threads.each {|t| t.join if t.alive?}

		# rundown any active events
		thread_cycle while events?

		# call shutdown callbacks
		SHUTDOWN_CALLBACKS.each {|s| s[0].call(*s[1]) }
		SHUTDOWN_CALLBACKS.clear

		# return exit code?
		0
	end

	# Anorexic Engine, DO NOT CALL. runs one thread cycle
	def self.thread_cycle flag = 0
		io_reactor
		true while fire_event
		# 	was, before reactor:
		#	sleep(idle_sleep) unless (accept_connections | fire_connections)
		# GC.start unless events? # forcing GC caused CPU to work overtime with MRI.
		# @time_since_output ||= Time.now
		# if Time.now - @time_since_output >= 1
		# 	@time_since_output = Time.now
		# 	info "#{IO_CONNECTION_DIC.length} active connections ( #{ IO_CONNECTION_DIC.select{|k,v| v.protocol.is_a?(WSProtocol)} .length } websockets)."
		# end
		true
	end


	#######################
	## Services pooling and calling

	# the services store
	SERVICES = {}
	#the services mutex
	S_LOCKER = Mutex.new
	#the connections mutex
	C_LOCKER = Mutex.new
	#the io reactor mutex
	IO_LOCKER = Mutex.new

	# public API to add a service to the framework.
	# accepts:
	# port:: port number
	# parameters:: a hash of paramaters that are passed on to the service for handling (and from there, service dependent, to the protocol and/or handler).
	#
	# parameters are any of the following:
	# host:: the host name. defaults to any host not explicitly defined.
	# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
	# root:: the public root folder. if this is defined, static files will be served from the location.
	# assets:: the assets root folder. defaults to nil (no assets support). if the path is defined, assets will be served from `/assets/...` (or the public_asset path defined) before any static files. assets will not be served if the file in the /public/assets folder if up to date (a rendering attempt will be made for systems that allow file writing).
	# assets_public:: the assets public uri location (uri format, NOT a file path). defaults to `/assets`. assets will be saved (or rendered) to the assets public folder and served as static files.
	# assets_callback:: a method that accepts one parameters: `request` and renders any custom assets. the method should return `false` unless it has created a response object (`response = Anorexic::HTTPResponse.new(request)`) and sent a response to the client using `response.finish`.
	# save_assets:: saves the rendered assets to the filesystem, under the public folder. defaults to false.
	# templates:: the templates root folder. defaults to nil (no template support). templates can be rendered by a Controller class, using the `render` method.
	# ssl:: if true, an SSL service will be attempted. if no certificate is defined, an attempt will be made to create a self signed certificate.
	# ssl_key:: the public key for the SSL service.
	# ssl_cert:: the certificate for the SSL service.
	#
	#
	# assets:
	#
	# assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively) before sending them as static files. if it is impossible to write the files, they will be rendered dynamically for every request (it would be better to render them before-hand).
	#
	# templates:
	#
	# templates can be either an ERB file on a Haml file.
	#
	def add_service port, paramaters = {}
		paramaters[:port] ||= port
		paramaters[:service_type] ||= ( paramaters[:ssl] ? SSLService : BasicService)
		service = nil
		service = paramaters[:service_type].create_service(port, paramaters) unless ( defined?(BUILDING_ANOREXIC_TEMPLATE) || defined?(ANOREXIC_ON_RACK) )
		S_LOCKER.synchronize {SERVICES[service] = paramaters}
		info "Started listening on port #{port}."
		true
	end

	# Anorexic Engine, DO NOT CALL. stops all services - active connection will remain open until completion.
	def stop_services
		info 'Stopping services'
		S_LOCKER.synchronize {SERVICES.each {|s, p| s.close rescue true; info "Stoped listening on port #{p[:port]}"}; SERVICES.clear }
	end

	# def accept_connections
	# 	return false if S_LOCKER.locked?
	# 	S_LOCKER.synchronize do
	# 		IO.select(SERVICES.keys, SERVICES.keys, SERVICES.keys, idle_sleep)
	# 		SERVICES.each do |s, p|
	# 			begin
	# 				loop do
	# 					io = s.accept_nonblock
	# 					callback Anorexic, :add_connection, io, p
	# 				end
	# 			rescue Errno::EWOULDBLOCK => e

	# 			# rescue OpenSSL::SSL::SSLError => e
	# 			# 	log "SSL connection bump"
	# 			# 	# retry
	# 			rescue Exception => e
	# 				# error e
	# 				SERVICES.delete s if s.closed?
	# 			end
	# 		end
	# 	end
	# 	true
	# end

	# # Anorexic Engine, DO NOT CALL. itirates the connections and creates reading events.
	# # returns false if there are no connections.
	# def fire_connections
	# 	return false if CO_LOCKER.locked?
	# 	CO_LOCKER.synchronize { io_r = IO.select(IO_CONNECTION_DIC.keys, nil, IO_CONNECTION_DIC.keys, idle_sleep) rescue nil; C_LOCKER.synchronize { (io_r[0] + io_r[2]).uniq.each{ |c| callback(IO_CONNECTION_DIC[c], :on_message) if IO_CONNECTION_DIC[c] } } if io_r  }
	# 	true
	# end

	# Anorexic Engine, DO NOT CALL. waits on IO and pushes events. all threads hang while reactor is active (unless events are already 'in the pipe'.)
	def io_reactor
		IO_LOCKER.synchronize do
			return false unless EVENTS.empty?
			united = SERVICES.keys + IO_CONNECTION_DIC.keys
			return false if united.empty?
			io_r = (IO.select(united, nil, united, idle_sleep) rescue false)
			if io_r
				(io_r[0] + io_r[2]).each do |io|
					if SERVICES[io]
						begin
							connection = io.accept_nonblock
							callback Anorexic, :add_connection, connection, SERVICES[io]
						rescue Errno::EWOULDBLOCK => e

						rescue Exception => e
							error e
							# SERVICES.delete s if s.closed?
						end
					elsif IO_CONNECTION_DIC[io]
						callback(IO_CONNECTION_DIC[io], :on_message)
					end
				end
			end
		end
		true
	end

	# the connections store
	IO_CONNECTION_DIC = {}

	# Anorexic Engine, DO NOT CALL. disconnectes all active connections
	def stop_connections
		log 'Stopping connections'
		C_LOCKER.synchronize {IO_CONNECTION_DIC.values.each {|c| callback c, :on_disconnect unless c.disconnected?} ; IO_CONNECTION_DIC.clear}
	end

	# Anorexic Engine, DO NOT CALL. adds a new connection to the connection stack
	def add_connection io, params
		connection = params[:service_type].new(io, params)
		C_LOCKER.synchronize {IO_CONNECTION_DIC[connection.socket] = connection} if connection
		callback(connection, :on_message)
	end
	# Anorexic Engine, DO NOT CALL. removes a connection from the connection stack
	def remove_connection connection
		C_LOCKER.synchronize { IO_CONNECTION_DIC.delete connection.socket }
	end

	# clears closed connections from the stack
	def clear_connections
		C_LOCKER.synchronize { IO_CONNECTION_DIC.values.each {|c| callback c, :on_disconnect if c.disconnected? } }
	end

end

AN = Anorexic
