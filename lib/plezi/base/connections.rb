
module Plezi

	module_function

	# DANGER ZONE - Plezi Engine. the connections store
	IO_CONNECTION_DIC = {}
	# DANGER ZONE - Plezi Engine. the connections mutex
	C_LOCKER = Mutex.new

	# Plezi Engine, DO NOT CALL. disconnectes all active connections
	def stop_connections
		log 'Stopping connections'
		C_LOCKER.synchronize {IO_CONNECTION_DIC.values.each {|c| c.timeout = -1; callback c, :on_disconnect unless c.disconnected?} ; IO_CONNECTION_DIC.clear}
	end

	# Plezi Engine, DO NOT CALL. adds a new connection to the connection stack
	def add_connection io, params
		connection = params[:service_type].new(io, params)
		C_LOCKER.synchronize {IO_CONNECTION_DIC[connection.socket] = connection} if connection
		callback(connection, :on_message)
	end
	# Plezi Engine, DO NOT CALL. removes a connection from the connection stack
	def remove_connection connection
		C_LOCKER.synchronize { IO_CONNECTION_DIC.delete connection.socket }
	end

	# clears closed connections from the stack
	def clear_connections
		C_LOCKER.synchronize { IO_CONNECTION_DIC.values.each {|c| callback c, :on_disconnect if c.disconnected? || c.timedout? } }
	end

end
