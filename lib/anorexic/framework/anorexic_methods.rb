
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
		@idle_sleep ||= 0.024
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
			LOCKER.synchronize {EVENTS << [(Proc.new {|*a| Anorexic.push_event block, handler.call(*a)} ), args]}
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
		rescue Exception => e
			raise if e.is_a?(SignalException)
			log e
		end
		true
	end

	# Anorexic Engine, DO NOT CALL. creates the thread pool and starts cycling through the events.
	def start_services
		# prepare threads
		exit_flag = false
		threads = []
		(max_threads).times {  Thread.new { sleep 0.001; ( sleep(idle_sleep) && thread_cycle ) until exit_flag }  }
		

		# Thread.new { check_connections until SERVICES.empty? }
		#...
		# set signal tarps
		trap('INT'){ exit_flag = true; raise "close Anorexic" }
		trap('TERM'){ exit_flag = true; raise "close Anorexic" }
		puts 'Services running. Press ^C to stop'
		# cycle until trap raises exception
		(sleep unless SERVICES.empty?) rescue true
		# start shutdown.
		exit_flag = true
		# set new tarps
		trap('INT'){ puts 'Forced exit.'; Kernel.exit rescue true}
		trap('TERM'){ puts 'Forced exit.'; Kernel.exit rescue true }
		puts 'Started shutdown process. Press ^C to force quit.'
		# shut down listening sockets
		stop_services
		# disconnect active connections
		stop_connections
		# cycle down threads
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
		true while fire_event
		accept_connections
		fire_connections # unless events?
	end


	#######################
	## Services pooling and calling

	# the services store
	SERVICES = []
	#the services and connections mutex
	S_LOCKER = Mutex.new

	# public API to add a service to the framework.
	# accepts:
	# port:: port number
	# parameters:: a hash of paramaters that are passed on to the service for handling (and from there, service dependent, to the protocol and/or handler).
	#
	# parameters are any of the following:
	# host:: the host name. defaults to any host not explicitly defined.
	# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
	# root:: the public root folder. if this is defined, static files will be served from the location.
	# assets:: the assets root folder. defaults to nil (no assets support). if the is defined, assets will be served from `/assets/...` before any static files. assets will not be served if the file in the /public/assets folder if up to date (a rendering attempt will be made for systems that allow file writing).
	# assets_public:: the assets public uri location (uri format, NOT a file path). defaults to `/assets`. assets will be saved (or rendered) to the assets public folder and served as static files.
	# assets_callback:: a method that accepts one parameters: `request` and renders any custom assets. the method should return `false` unless it has created a response object (`response = Anorexic::HTTPResponse.new(request)`) and sent a response to the client using `response.finish`.
	# ssl:: if true, an SSL service will be attempted. if no certificate is defined, an attempt will be made to create a self signed certificate.
	# ssl_key:: the public key for the SSL service.
	# ssl_cert:: the certificate for the SSL service.
	#
	#
	# assets:
	#
	# assets support will render `.sass`, `.scss` and `.coffee` and save them as local files (`.css`, `.css`, and `.js` respectively) before sending them as static files. if it is impossible to write the files, they will be rendered dynamically for every request (it would be better to render them before-hand).
	def add_service port, paramaters = {}
		paramaters[:port] ||= port
		paramaters[:service_type] ||= ( paramaters[:ssl] ? SSLService : BasicService)
		service = paramaters[:service_type].create_service(port, paramaters)
		S_LOCKER.synchronize {SERVICES << [service, paramaters]}
		info "Started listening on port #{port}."
		true
	end

	# Anorexic Engine, DO NOT CALL. stops all services - active connection will remain open until completion.
	def stop_services
		info 'Stopping services'
		S_LOCKER.synchronize {SERVICES.each {|s| s[0].close rescue true; info "Stoped listening on port #{s[1][:port]}"}; SERVICES.clear }
	end

	# checks for pending connections and accepts any pending connections
	def accept_connections
		ret = false
		SERVICES.each do |s|
			begin
				loop do
					io = s[0].accept_nonblock
					add_connection io, s[1]
					ret = true
				end
			rescue Errno::EWOULDBLOCK => e

			rescue Exception => e
				# error e
				S_LOCKER.synchronize { SERVICES.delete_if { |s| s[0].closed? } }
			end
		end
		ret
	end

	# the connections store
	CONNECTIONS = []

	# Anorexic Engine, DO NOT CALL. disconnectes all active connections
	def stop_connections
		log 'Stopping connections'
		S_LOCKER.synchronize {CONNECTIONS.each {|c| callback c, :on_disconnect unless c.disconnected?} ; CONNECTIONS.clear}
	end

	# Anorexic Engine, DO NOT CALL. adds a new connection to the connection stack
	def add_connection io, params
		connection = params[:service_type].new(io, params)
		S_LOCKER.synchronize {CONNECTIONS << connection}
		callback(connection, :on_message)
	end
	# adds a new connection to the connection stack
	def remove_connection connection
		S_LOCKER.synchronize {CONNECTIONS.delete connection}
	end

	# Anorexic Engine, DO NOT CALL. itirates the connections and creates reading events.
	# returns false if there are no connections.
	def fire_connections
		return if S_LOCKER.locked?
		S_LOCKER.synchronize { CONNECTIONS.each{|c| callback c, :on_message} }
		# !CONNECTIONS.empty?
	end

	# def check_connections
	# 	# ret = false
	# 	# S_LOCKER.synchronize do 
	# 	# 	CONNECTIONS.delete_if do |k, connection|
	# 	# 		if connection.disconnected?
	# 	# 			callback connection, :on_disconnect
	# 	# 			ret = true
	# 	# 		else
	# 	# 			callback(connection, :on_message) if connection.has_incoming_data?
	# 	# 		end
	# 	# 	end
	# 	# end
	# 	# ret
	# 	active = S_LOCKER.synchronize { IO.select CONNECTIONS.map{|c| c.socket}, nil, nil, 0.01 rescue false }
	# 	if active
	# 		puts "#{SERVICES.length} services, #{active[0].length} active"
	# 		active[0].each {|io| callback CONNECTIONS[io], :on_message} rescue true			
	# 	end
	# end

end

AN = Anorexic
