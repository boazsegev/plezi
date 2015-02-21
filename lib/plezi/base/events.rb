
module Plezi

	module_function

	#######################
	## Events (Callbacks) / Multi-tasking Platform

	# DANGER ZONE - Plezi Engine. an Array containing all the shutdown callbacks that need to be called.
	SHUTDOWN_CALLBACKS = []
	# DANGER ZONE - Plezi Engine. an Array containing all the current events.
	EVENTS = []
	# DANGER ZONE - Plezi Engine. the Mutex locker for the event machine.
	LOCKER = Mutex.new

	# returns true if there are any unhandled events
	def events?
		LOCKER.synchronize {!EVENTS.empty?}
	end

	# Public API. pushes an event to the event's stack
	#
	# accepts:
	# handler:: an object that answers to `call`, usually a Proc or a method.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	#
	# if a block is passed along, it will be used as a callback: the block will be called with the values returned by the handler's `call` method.
	def push_event handler, *args, &block
		if block
			LOCKER.synchronize {EVENTS << [(Proc.new {|a| Plezi.push_event block, handler.call(*a)} ), args]}
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
	#    Plezi.callback(STDIO, :gets) do |name|
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

	# Plezi Engine, DO NOT CALL. pulls an event from the event's stack and processes it.
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
end
