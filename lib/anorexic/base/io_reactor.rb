
module Anorexic

	module_function


	# DANGER ZONE - Anorexic Engine. the io reactor mutex
	IO_LOCKER = Mutex.new

	# Anorexic Engine, DO NOT CALL. waits on IO and pushes events. all threads hang while reactor is active (unless events are already 'in the pipe'.)
	def io_reactor
		IO_LOCKER.synchronize do
			return false unless EVENTS.empty?
			united = SERVICES.keys + IO_CONNECTION_DIC.keys
			return false if united.empty?
			io_r = (IO.select(united, nil, united, idle_sleep) ) #rescue false)
			if io_r
				io_r[0].each do |io|
					if SERVICES[io]
						begin
							connection = io.accept_nonblock
							callback Anorexic, :add_connection, connection, SERVICES[io]
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
