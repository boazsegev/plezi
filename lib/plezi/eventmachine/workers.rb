module Plezi
	module EventMachine

		# A single worker.
		class Worker
			def initialize
				@stop = false
				@thread = Thread.new { EventMachine.run until @stop }
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
		end
	end
end