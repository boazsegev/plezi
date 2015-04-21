
module Plezi

	module_function

	# set the default idle waiting time.
	@idle_sleep = 0.1

	# Plezi event cycle settings: how long to wait for IO activity before forcing another cycle.
	#
	# No timing methods will be called during this interval.
	#
	# Gets the current idle setting. The default setting is 0.1 seconds.
	def idle_sleep
		@idle_sleep
	end
	# Plezi event cycle settings: how long to wait for IO activity before forcing another cycle.
	#
	# No timing methods will be called during this interval (#run_after / #run_every).
	# 
	# It's rare, but it's one of the reasons for the timeout: some connections might wait for the timeout befor being established.
	#
	# set the current idle setting
	def idle_sleep= value
		@idle_sleep = value
	end

	# DANGER ZONE - Plezi Engine. the io reactor mutex
	IO_LOCKER = Mutex.new

	# Plezi Engine, DO NOT CALL. waits on IO and pushes events. all threads hang while reactor is active (unless events are already 'in the pipe'.)
	def io_reactor
		IO_LOCKER.synchronize do
			return false unless EVENTS.empty?
			united = SERVICES.keys + IO_CONNECTION_DIC.keys
			return false if united.empty?
			io_r = (IO.select(united, nil, united, @idle_sleep) ) #rescue false)
			if io_r
				io_r[0].each do |io|
					if SERVICES[io]
						begin
							connection = io.accept_nonblock
							callback Plezi, :add_connection, connection, SERVICES[io]
						rescue Errno::EWOULDBLOCK => e

						rescue Exception => e
							error e
							# SERVICES.delete s if s.closed?
						end
					elsif IO_CONNECTION_DIC[io]
						callback(IO_CONNECTION_DIC[io], :on_message)
					else
						IO_CONNECTION_DIC.delete(io)
						SERVICES.delete(io)
					end
				end
				io_r[2].each { |io| (IO_CONNECTION_DIC.delete(io) || SERVICES.delete(io)).close rescue true }
			end
		end
		true
	end
end
