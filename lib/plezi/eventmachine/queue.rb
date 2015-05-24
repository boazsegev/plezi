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

	def run_async *args, &block
		EventMachine.queue args, block
	end

	def callback object, method, *args, &block
		block ? EventMachine.queue( args, (proc { |ar| block.call( object.method(method).call(*ar) ) }) ) : EventMachine.queue(args, object.method(method) )
	end

end