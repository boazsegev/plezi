module Plezi
	module EventMachine
		module_function

		QUEUE = []
		QUEUE_LOCKER = Mutex.new

		def queue args, job
			raise "Job missing" unless job
			QUEUE_LOCKER.synchronize { QUEUE << [job, args]}
			true
		end

		def do_job
			job, args = QUEUE_LOCKER.synchronize { QUEUE.shift }
			job ? (job.call(*args) || true) : false
		end

		def queue_empty?
			QUEUE.empty?
		end

	end

	module_function

	# Accepts a block and runs it asynchronously. This method runs asynchronously and returns immediately.
	#
	# use:
	#
	#      Plezi.run_async(arg1, arg2, arg3 ...) { |arg1, arg2, arg3...| do_something }
	#
	# the block will be run within the current context, allowing access to current methods and variables.
	def run_async *args, &block
		EventMachine.queue args, block
	end

	# This method runs asynchronously and returns immediately.
	#
	# This method accepts:
	# object:: an object who's method will be called.
	# method:: the method's name to be called. type: Symbol.
	# *args:: any arguments to be passed to the method.
	#
	# This method also accepts an optional block which will be run with the method's returned value within the existing context.
	#
	def callback object, method, *args, &block
		block ? EventMachine.queue( args, (proc { |ar| block.call( object.method(method).call(*ar) ) }) ) : EventMachine.queue(args, object.method(method) )
	end

end