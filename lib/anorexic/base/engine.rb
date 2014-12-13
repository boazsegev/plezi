
module Anorexic

	module_function

	# Anorexic event cycle settings: gets how many worker threads Anorexic will run.
	def max_threads
		@max_threads ||= 16
	end
	# Anorexic event cycle settings: sets how many worker threads Anorexic will run.
	def max_threads= value
		@max_threads = value
	end

	# Anorexic event cycle settings: how long to wait for IO activity before forcing another cycle.
	#
	# No timing methods will be called during this interval.
	#
	# get the current idle setting
	def idle_sleep
		@idle_sleep ||= 0.1
	end
	# Anorexic event cycle settings: how long to wait for IO activity before forcing another cycle.
	#
	# No timing methods will be called during this interval.
	#
	# set the current idle setting
	def idle_sleep= value
		@idle_sleep = value
	end

	# Anorexic Engine, DO NOT CALL. creates the thread pool and starts cycling through the events.
	def start_services
		# prepare threads
		exit_flag = false
		threads = []
		run_every(5 , Anorexic.method(:clear_connections)) #{info "Cleared inactive Connections"}
		run_every 3600 , GC.method(:start)
		# run_every( 1 , Proc.new() { Anorexic.info "#{IO_CONNECTION_DIC.length} active connections ( #{ IO_CONNECTION_DIC.select{|k,v| v.protocol.is_a?(WSProtocol)} .length } websockets)." })
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
		thread_cycle

		# call shutdown callbacks
		SHUTDOWN_CALLBACKS.each {|s| s[0].call(*s[1]) }
		SHUTDOWN_CALLBACKS.clear

		# return exit code?
		0
	end

	# Anorexic Engine, DO NOT CALL. runs one thread cycle
	def self.thread_cycle flag = 0
		io_reactor rescue false # stop_connections
		true while fire_event
		fire_timers

		rescue Exception => e

		error e
	end
end
