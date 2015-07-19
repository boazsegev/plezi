module Plezi
	module EventMachine

		# Every timed event is a member of the TimedEvent class and responds to it's methods. 
		class TimedEvent

			# Sets/gets how often a timed event repeats, in seconds.
			attr_accessor :interval
			# Sets/gets how many times a timed event repeats.
			# If set to false or -1, the timed event will repead until the application quits.
			attr_accessor :repeat_limit

			# Initialize a timed event.
			def initialize interval, repeat_limit = -1, args=[], job=nil
				@interval = interval
				@repeat_limit = repeat_limit ? repeat_limit.to_i : -1
				@job = job || (Proc.new { stop! })
				@next = Time.now + interval
				@args = args
			end

			# stops a timed event.
			def stop!
				@repeat_limit = 0
			end

			# Returns true if the timer is finished.
			#
			# If the timed event is due, this method will also add the event to the queue.
			def done?(time = Time.now)
				return false unless @next <= time
				return true if @repeat_limit == 0
				@repeat_limit -= 1 if @repeat_limit.to_i > 0
				EventMachine.queue @args, @job
				@next = time + @interval
				@repeat_limit == 0
			end
		end

		module_function

		# the timers stack.
		TIMERS = []
		# the timers stack Mutex.
		TIMERS_LOCK = Mutex.new

		# Creates a TimedEvent object and adds it to the Timers stack.
		def timed_job seconds, limit = false, args = [], block = nil
			TIMERS_LOCK.synchronize {TIMERS << TimedEvent.new(seconds, limit, args, block); TIMERS.last}
		end

		# returns true if there are any unhandled events
		def timers?
			TIMERS.any?
		end

		# cycles through timed jobs, executing and/or deleting them if their time has come.
		def fire_timers
			TIMERS_LOCK.synchronize { time = Time.now; TIMERS.delete_if {|t| t.done? time} }
		end
		# clears all timers
		def clear_timers
			TIMERS.clear
		end

	end

	module_function

	# # returns true if there are any unhandled events
	# def timers?
	# 	EventMachine.timers?
	# end

	# pushes a timed event to the timers's stack
	#
	# accepts:
	# seconds:: the minimal amount of seconds to wait before calling the handler's `call` method.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	# &block:: the block to execute.
	#
	# A block is required.
	#
	# Timed event's time of execution is dependant on the workload and continuous uptime of the process (timed events AREN'T persistant).
	def run_after seconds, *args, &block
		EventMachine.timed_job seconds, 1, args, block
	end

	# pushes a timed event to the timers's stack
	#
	# accepts:
	# time:: the time at which the job should be executed.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	# &block:: the block to execute.
	#
	# A block is required.
	#
	# Timed event's time of execution is dependant on the workload and continuous uptime of the process (timed events AREN'T persistant).

	def run_at time, *args, &block
		EventMachine.timed_job( (Time.now - time), 1, args, block)
	end
	# pushes a repeated timed event to the timers's stack
	#
	# accepts:
	# seconds:: the minimal amount of seconds to wait before calling the handler's `call` method.
	# limit:: the amount of times the event should repeat itself. The event will repeat every x amount of `seconds`. The event will repeat forever if limit is set to false.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	# &block:: the block to execute.
	#
	# A block is required.
	#
	# Timed event's time of execution is dependant on the workload and continuous uptime of the process (timed events AREN'T persistant).
	def run_every seconds, limit = -1, *args, &block
		EventMachine.timed_job seconds, limit, args, block
	end
end