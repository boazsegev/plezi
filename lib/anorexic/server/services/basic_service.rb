module Anorexic

	# this class is a basic TCP socket service.
	#
	# a protocol should be assigned, or the service will fall back to an echo service.
	#
	# a protocol should answer to: on_connect(service), on_message(service, data), on_disconnect(service) and on_exception(service, exception)
	#
	# the on_message method should return any data that wasn't used (to be sent again as part of the next `on_message` call, once more data is received).
	#
	# if the protocol is a class, these methods should be instance methods.
	# a protocol class should support the initialize(service, parameters={}) method as well.
	#
	# to-do: fix logging
	class BasicService

		# create a listener (io) - will create a TCPServer socket
		#
		# listeners are 'server sockets' that answer to `accept` by creating a new connection socket (io).
		def self.create_service port, parameters
			TCPServer.new(port)
		end

		# instance methods

		attr_reader :socket, :locker, :closed, :parameters, :out_que, :active_time
		attr_accessor :protocol, :handler, :timeout

		# creates a new connection wrapper object for the new socket that was recieved from the `accept_nonblock` method call.
		def initialize socket, parameters = {}
			@handler = parameters[:handler]
			@socket = socket
			# socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, "\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" #== [10 sec 0 usec].pack '1_2'
			@out_que = []
			@locker = Mutex.new
			@parameters = parameters
			@protocol = parameters[:protocol]
			@protocol = protocol.new self, parameters if protocol.is_a?(Class)
			@protocol.on_connect self if @protocol && @protocol.methods.include?(:on_connect)
			@active_time = Time.now
			@timeout ||= 5
			# Anorexic.callback self, :on_message
		end

		# # sets a connection timeout
		# def set_timeout timeout = 8
		# 	@timeout = timeout
		# end

		# checks if a connection timed out
		def timedout?
			Time.now - @active_time > @timeout
		end

		# resets the timer for the connection timeout
		def touch
			@active_time = Time.now
		end

		# sends data immidiately - forcing the data to be sent, flushing any pending messages in the que
		def send data = nil
			touch
			return if @out_que.empty? && data.nil?
			locker.synchronize do
				if @out_que.empty?
					_send data rescue disconnect
				else
					@out_que.each { |d| _send d rescue disconnect }
					@out_que.clear
					(_send data rescue disconnect) if data
				end
			end
		end

		# sends data immidiately, interrupting any pending que and ignoring thread safety.
		def send_unsafe_interrupt data = nil
			touch
			_send data rescue disconnect
		end

		# sends data without waiting - data might be sent in a different order then intended.
		def send_nonblock data
			touch
			locker.synchronize {@out_que << data}
			Anorexic.callback(self, :send)
		end

		# adds data to the out buffer - but doesn't send the data until a send event is called.
		def << data
			touch
			locker.synchronize {@out_que << data}
		end

		# makes sure any data in the que is send and calls `flush` on the socket, to make sure the buffer is sent.
		def flush
			begin
				send
				socket.flush				
			rescue Exception => e
				
			end
		end

		# event based interface for messages.

		# notice: since it is all async evet base - multipart messages might be garbled up...?
		# todo: protect from garbeling.
		def on_message
			# return false if locker.locked?
			return false if locker.locked?
			return disconnect if (_disconnected? rescue true)
			locker.synchronize do
				begin
					touch
					if protocol
						protocol.on_message self
					else # if there's no protocol - fall back on echo.
						data = read
						send "echo #{Time.now.utc.to_s}: "
						send data
						disconnect if data.to_s.match /^bye[\r\n]*$/
					end
				rescue Exception => e
					return disconnect
				end
			end
		end

		# def on_message
		# 	# return false if locker.locked?
		# 	return false if locker.locked?
		# 	if (_disconnected? rescue true) || (@timeout && (Time.now - @active_time) > @timeout && true) #implement check that all content was sent
		# 		Anorexic.callback self, :on_disconnect
		# 	end
		# 	begin
		# 		locker.lock
		# 		read_size = socket.stat.size
		# 		data = _read(read_size) unless read_size == 0
		# 	rescue Exception => e
		# 		return false
		# 	ensure
		# 		locker.unlock
		# 	end
		# 	if data && !data.empty?
		# 		@active_time = Time.now
		# 		if protocol
		# 			begin
		# 				protocol.on_message(self, data)
		# 			rescue Exception => e
		# 				locker.unlock if locker.locked?
		# 				Anorexic.callback protocol, :on_exception, self, e
		# 			end
		# 		else # if there's no protocol - fall back on echo.
		# 			send "echo #{Time.now.utc.to_s}: #{data}"
		# 			Anorexic.callback self, :on_disconnect if @in_que[-1].to_s.match /^bye[\r\n]*$/
		# 		end
		# 	end
		# end

		# called once a socket is disconnected or needs to be disconnected.
		def on_disconnect
			Anorexic.callback Anorexic, :remove_connection, self
			locker.synchronize do
				@out_que.each { |d| _send d rescue true}
				@out_que.clear
			end
			if protocol
				Anorexic.callback protocol, :on_disconnect, self
			end
			close
		end

		# status markers

		# closes the connection
		def close
			locker.synchronize do
				_close rescue true
			end
		end
		# returns true if the service is disconnected
		def disconnected?
			_disconnected?
		end
		# disconects the service.
		def disconnect
			Anorexic.callback self, :on_disconnect
		end
		# returns true if the socket has content to be read.
		def has_incoming_data?
			 (socket.stat.size > 0) rescue false
		end


		# identification markers

		#returns the service type - set to normal
		def service_type
			'normal'
		end
		#returns true if the service is encrypted using the OpenSSL library.
		def ssl?
			false
		end

		#################
		# overide the followind methods for any child class.

		# this is a public method and it should be used by child classes to implement each
		# read(_nonblock) action. accepts one argument ::size for an optional buffer size to be read.
		def read size = 1048576
			@socket.recv_nonblock( size ) rescue nil
		end

		protected

		# this is a protected method, it should be used by child classes to implement each
		# send action.
		def _send data
			# data.force_encoding "binary" rescue false
			len = data.bytesize
			act = @socket.send data, 0
			while len > act
				act += @socket.send data.byteslice(act..-1) , 0
				touch
			end
		end
		# this is a protected method, it should be used by child classes to implement each
		# close action. doesn't accept any arguments.
		def _close
			socket.flush rescue true
			socket.close
		end
		# this is a protected method, it should be used by child classes to tell if the socket
		# was closed (returns true/false).
		def _disconnected?
			socket.closed? || socket.stat.mode == 0140222 rescue true # if mode is read only, it's the same as closed.
		end

	end
end


######
## example requests

# GET / HTTP/1.1
# Host: localhost:2000
# Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# Cookie: user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w
# User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25
# Accept-Language: en-us
# Accept-Encoding: gzip, deflate
# Connection: keep-alive