
module Plezi

	module_function

	# Plezi event cycle settings: gets how many worker threads Plezi will run.
	def max_threads
		@max_threads ||= 16
	end
	# Plezi event cycle settings: sets how many worker threads Plezi will run.
	def max_threads= value
		raise "Plezi will hang and do nothing if there isn't at least one (1) working thread. Cannot set Plezi.max_threads = #{value}" if value.to_i <= 0
		@max_threads = value.to_i
	end

	# Plezi Engine, DO NOT CALL. creates the thread pool and starts cycling through the events.
	def start_services
		# prepare threads
		exit_flag = false
		threads = []
		run_every(5 , Plezi.method(:clear_connections)) #{info "Cleared inactive Connections"}
		run_every 3600 , GC.method(:start)
		# run_every( 1 , Proc.new() { Plezi.info "#{IO_CONNECTION_DIC.length} active connections ( #{ IO_CONNECTION_DIC.select{|k,v| v.protocol.is_a?(WSProtocol)} .length } websockets)." })
		# run_every 10 , -> {Plezi.info "Cache report: #{CACHE_STORE.length} objects cached." } 
		(max_threads).times {  Thread.new { thread_cycle until exit_flag }  }		

		# Thread.new { check_connections until SERVICES.empty? }
		#...
		# set signal tarps
		trap('INT'){ exit_flag = true; raise "close Plezi" }
		trap('TERM'){ exit_flag = true; raise "close Plezi" }
		puts "Services running Plezi version #{Plezi::VERSION}. Press ^C to stop"
		puts %q{**deprecation notice**:

v.0.8.0 will consist of many changes that will also influence the API. The 0.8.0 version will mark the begining of some major rewrites, so that the code will be even easier to maintain.

If your code depends on Timers and other advanced API, please review your code before updating to the 0.8.0 version.

		}
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

	# Plezi Engine, DO NOT CALL. runs one thread cycle
	def self.thread_cycle flag = 0
		io_reactor rescue false # stop_connections
		true while fire_event
		fire_timers

		# rescue Exception => e
		# error e
		# # raise if e.is_a?(SignalException) || e.is_a?(SystemExit)
	end
end
