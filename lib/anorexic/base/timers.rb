
module Anorexic

	module_function

	#######################
	## Timed Events / Multi-tasking

	# DANGER ZONE - Anorexic Engine. an Array containing all the current events.
	TIMERS = []
	# DANGER ZONE - Anorexic Engine. the Mutex locker for the event machine.
	T_LOCKER = Mutex.new

	# This class is used by Anorexic to hold events and push them into the events stack when the time comes.
	class TimedEvent

		def initialize seconds, repeat, handler, args, block
			@time = Time.now + seconds
			@seconds, @repeat, @handler, @args, @block  = seconds, repeat, handler, args, block
		end

		def done?
			return false unless @time <= Time.now
			Anorexic.push_event @handler, *@args, &@block
			return true unless @repeat
			@time = Time.now + @seconds
			false
		end

		def stop_repeat
			@repeat = false
		end

		attr_reader :timed
	end

	# returns true if there are any unhandled events
	def timers?
		T_LOCKER.synchronize {!TIMERS.empty?}
	end

	# pushes a timed event to the timers's stack
	#
	# accepts:
	# seconds:: the minimal amount of seconds to wait before calling the handler's `call` method.
	# handler:: an object that answers to `call`, usually a Proc or a method.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	#
	# if a block is passed along, it will be used as a callback: the block will be called with the values returned by the handler's `call` method.
	def run_after seconds, handler, *args, &block
		T_LOCKER.synchronize {TIMERS << TimedEvent.new(seconds, false, handler, args, block); TIMERS.last}
	end

	# pushes a repeated timed event to the timers's stack
	#
	# accepts:
	# seconds:: the minimal amount of seconds to wait before calling the handler's `call` method.
	# handler:: an object that answers to `call`, usually a Proc or a method.
	# *arg:: any arguments that will be passed to the handler's `call` method.
	#
	# if a block is passed along, it will be used as a callback: the block will be called with the values returned by the handler's `call` method.
	def run_every seconds, handler, *args, &block
		T_LOCKER.synchronize {TIMERS << TimedEvent.new(seconds, true, handler, args, block); TIMERS.last}
	end

	# DANGER ZONE - Used by the Anorexic engine to review timed events and push them to the event stack
	def fire_timers
		return false if T_LOCKER.locked?
		T_LOCKER.synchronize { TIMERS.delete_if {|t| t.done? } }
	end
end
