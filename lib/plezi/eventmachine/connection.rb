# encoding: UTF-8



module Plezi

	module EventMachine

		class Connection
			attr_reader :socket, :params, :active_time, :out_que, :locker
			attr_accessor :protocol, :handler, :timeout

			# initializes the connection and it's settings.
			def initialize socket, params
				@socket, @params, @handler = socket, params, params[:handler]
				# socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, "\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" #== [10 sec 0 usec].pack '1_2'
				@out_que, @locker = [], Mutex.new
				@protocol = params[:protocol].is_a?(Class) ? (params[:protocol].new self, params) : params[:protocol]
				@protocol.on_connect if @protocol.is_a?(Protocol)
				touch
				@timeout ||= 5
			end

			# used by the EM when the connection should handle data.
			def call
				# don't let competing threads do the same job.
				return false if @locker.locked?
				begin
					@locker.synchronize do
						return disconnect if disconnected?
						protocol.on_message
					end

				rescue Exception => e
					PL.error e
					return disconnect
				end
			end

			def clear?
				return false unless timedout? || disconnected?
				disconnect
				true
			end

			# checks if a connection timed out
			def timedout?
				Time.now - @active_time > @timeout.to_i
			end

			# resets the timer for the connection timeout
			def touch
				@active_time = Time.now
			end

			# returns an IO-like object used for reading/writing (unlike the original IO object, this can be an SSL layer or any other wrapper object).
			def io
				@socket
			end

			# sends data immidiately - forcing the data to be sent, flushing any pending messages in the que
			def send data = nil
				return false unless @out_que.any? || data
				@locker.synchronize do
					unless @out_que.empty?
						@out_que.each { |d| _send d rescue disconnect }
						@out_que.clear					
					end
					(_send data rescue disconnect) if data
				end
			end

			# the non-blocking proc used for send_nonblock
			SEND_COMPLETE_PROC = Proc.new {|c| c.send }

			# sends data without waiting - data might be sent in a different order then intended.
			def send_nonblock data
				touch
				@locker.synchronize {@out_que << data}
				EventMachine.queue [self], SEND_COMPLETE_PROC
			end

			# adds data to the out buffer - but doesn't send the data until a send event is called.
			def << data
				touch
				@locker.synchronize {@out_que << data}
			end

			# makes sure any data in the que is send and calls `flush` on the socket, to make sure the buffer is sent.
			def flush
				send
				io.flush
			end

			# the proc used to remove the connection from the IO stack.
			REMOVE_CONNECTION_PROC = Proc.new {|old_io| EventMachine.remove_io old_io }
			# called once a socket is disconnected or needs to be disconnected.
			def on_disconnect
				EventMachine.queue [@socket], REMOVE_CONNECTION_PROC
				@locker.synchronize do
					@out_que.each { |d| _send d rescue true}
					@out_que.clear
					io.flush rescue true
					io.close rescue true
				end
				EventMachine.queue [], protocol.method(:on_disconnect) if protocol && !protocol.is_a?(Class)
			end

			# status markers

			# closes the connection
			def close
				@locker.synchronize do
					io.flush rescue true
					io.close rescue true
				end
			end
			# returns true if the service is disconnected
			def disconnected?
				(@socket.closed? || socket.stat.mode == 0140222) rescue true # if mode is read only, it's the same as closed.
			end
			# the async disconnect proc
			FIRE_DISCONNECT_PROC = Proc.new {|handler| handler.on_disconnect }
			# disconects the service.
			def disconnect
				@out_que.clear
				EventMachine.queue [self], FIRE_DISCONNECT_PROC
			end
			# returns true if the socket has content to be read.
			def has_incoming_data?
				 (@socket.stat.size > 0) rescue false
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
				begin
					data = @socket.recv_nonblock( size )
					return nil if data.to_s.empty?
					touch
					data
				rescue Exception => e
					
				end
			end
			# # this is a public method and it should be used by child classes to implement each
			# # read(_nonblock) action. accepts one argument ::size for an optional buffer size to be read.
			# def read_line
			# 	data = @line_data ||= ''
			# 	begin
			# 		data << @socket.recv_nonblock( 1 ).to_s until data[-1] == "\n"
			# 		@line_data = ''
			# 		return data
			# 	rescue => e
			# 		return false
			# 	ensure
			# 		touch
			# 	end
			# end

			protected

			# this is a protected method, it should be used by child classes to implement each
			# send action.
			def _send data
				@active_time += 7200
				len = data.bytesize
				act = @socket.send data, 0
				while len > act
					act += @socket.send data.byteslice(act..-1) , 0
				end
				touch
			end

		end
	end
end
