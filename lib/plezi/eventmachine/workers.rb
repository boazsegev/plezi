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
				@instances ||= 0
				@instances += 1
				@instances = 1 if @instances > 8
				Prime.first(@instances).last / 10.0
			end
			def self.reset_wait
				@instances = 0
			end
		end
	end
end