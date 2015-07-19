module Plezi
	module EventMachine

		# A single worker.
		class Worker
			def initialize
				@stop = false
				wait = Worker.get_wait
				@thread = Thread.new { EventMachine.run wait until @stop }
			end
			def stop
				@instances = -1
				@stop = true
			end
			def join
				stop
				@thread.join rescue true
			end
			def alive?
				@thread.alive?
			end
			def status
				@thread.status
			end
			def self.get_wait
				@primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37] 
				@instances ||= -1
				@instances += 1 if @instances < 7
				@primes[@instances] / 10.0
			end
		end
	end
end