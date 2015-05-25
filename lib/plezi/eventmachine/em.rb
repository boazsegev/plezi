module Plezi

	# This module holds the events, timers and IO logic and workflow (asynchronous workflow).
	#
	# Timed events are approximated and their exact time of execution is dependant on the workload and continues uptime of the process (timed events AREN'T persistant)
	module EventMachine

		module_function

		# sets the amount of worker threads cycling the event machine and starts (or re-starts) the event machine.
		def start count=12
			@workers ||= []
			@workers_lock ||= Mutex.new
			stop unless @workers.count <= count
			(count - @workers.count).times {@workers << Worker.new}
		end

		# runs through all existing events and one idle cycle
		def run wait = 0.1
			begin
				fire_timers
				do_job while do_job
				# replace with io
				review_io || sleep(wait)
			rescue Exception => e
				Plezi.error e
			end
		end

		def stop_and_wait
			@workers_lock.synchronize { @workers.each {|w| w.stop }; @workers.each {|w| w.join }; @workers.clear; Worker.reset_wait}
		end

		def stop
			@workers_lock.synchronize { @workers.each {|w| w.stop } ; @workers.clear; Worker.reset_wait}
		end

		def running?
			@workers && @workers.any?
		end
		def count_living_workers
			(@workers_lock.synchronize { @workers.select {|w| w.alive? } } ).count
		end
		def workers_status
			@workers_lock.synchronize { @workers.map {|w| w.status } }
		end

		SHUTDOWN_CALLBACKS = []
		# runs the shutdown queue
		def shutdown
			stop_and_wait rescue false
			old_timeout = io_timeout
			io_timeout = 0.001
			run
			io_timeout = old_timeout
			do_job while do_job
			stop_connections
			do_job while do_job
			QUEUE_LOCKER.synchronize do
				SHUTDOWN_CALLBACKS.each { |s_job| s_job[0].call(*s_job[1]) }
				SHUTDOWN_CALLBACKS.clear
			end
			true
		end
		# Adds a callback to be called once the services were shut down. see: callback for more info.
		def on_shutdown object=nil, method=nil, *args, &block
			if block && !object && !method
				QUEUE_LOCKER.synchronize {SHUTDOWN_CALLBACKS << [block, args]}
			elsif block
				QUEUE_LOCKER.synchronize {SHUTDOWN_CALLBACKS << [(Proc.new {|*a| block.call(object.method(method).call(*a))} ), args]}
			elsif object && method
				QUEUE_LOCKER.synchronize {SHUTDOWN_CALLBACKS << [object.method(method), args]}
			end
		end

	end

	module_function

	# Plezi event cycle settings: gets how many worker threads Plezi will initially run.
	def max_threads
		@max_threads ||= 16
	end
	# Plezi event cycle settings: sets how many worker threads Plezi will initially run.
	def max_threads= value
		raise "Plezi will hang and do nothing if there isn't at least one (1) working thread. Cannot set Plezi.max_threads = #{value}" if value.to_i <= 0
		@max_threads = value.to_i
		start @max_threads if EventMachine.running?
	end

	# Adds a callback to be called once the services were shut down. see: callback for more info.
	def on_shutdown object=nil, method=nil, *args, &block
		EventMachine.on_shutdown object, method, *args, &block
	end
end
