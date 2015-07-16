module Plezi

	# this class handles WebSocket response.
	#
	# the WSResponse supports only one method - the send method.
	#
	# use: `response << data` to send data. data should be a String object.
	#
	# the data wil be sent as text if the string is encoded as a UTF-8 string (default encoding).
	# otherwise, the data will be sent as a binary stream.
	#
	# todo: extentions support, support frames longer then 125 bytes.
	class WSResponse

		#the service through which the response will be sent.
		attr_reader :service
		#the request.
		attr_accessor :request

		# Sets the defalt Websockt auto-ping interval.
		#
		# The default ping interval is 45 seconds.
		#
		# It's possible to set the ping interval to false, thereby disabling auto-pinging.
		def self.ping_interval=(val)
			@ping_interval = val
		end
		# Returns the defalt Websockt auto-ping interval.
		#
		# Plezi will automatically send a ping frame to keep websocket connections open.
		# This auto-pinging can be disabled by setting the `ping_interval` to false.
		def self.ping_interval
			@ping_interval ||= 45
		end
		PING_PROC = Proc.new {|res| EventMachine.timed_job ping_interval, 1, [res.ping], PING_PROC unless res.service.disconnected? || !ping_interval }

		def initialize request
			@request, @service = request,request.service
			PING_PROC.call(self)
		end

		# sends data through the websocket connection in a non-blocking way.
		#
		# Plezi will try a best guess at the type of the data (binary vs. clear text).
		#
		# This should be the preferred way.
		def << str
			service.send_nonblock self.class.frame_data(str)
			self
		end

		# sends data through the websocket connection in a blocking way.
		#
		# Plezi will try a best guess at the type of the data (binary vs. clear text).
		#
		def send str
			service.send self.class.frame_data(str)
			self
		end
		# sends binary data through the websocket connection in a blocking way.
		#
		def binsend str
			service.send self.class.frame_data(str, 2)
			self
		end
		# sends clear text data through the websocket connection in a blocking way.
		#
		def txtsend str
			service.send self.class.frame_data(str, 1)
			self
		end


		# makes sure any data held in the buffer is actually sent.
		def flush
			service.flush
			self
		end

		# pings the connection
		def ping
			service.send_nonblock "\x89\x00" # op_code 9
			self
		end
		# pings the connection
		def pong
			service.send_nonblock "\x8A\x00" # op_code 10
			self
		end

		# a closeing Proc
		CLOSE_PROC = Proc.new {|c| c.send "\x88\x00"; c.close}

		# sends any pending data and closes the connection.
		def close
			service.locker.locked? ? (EventMachine.queue [service], CLOSE_PROC) : (CLOSE_PROC.call(service)) 
		end

		FRAME_SIZE_LIMIT = 131_072 # javascript to test: str = '0123456789'; bigstr = ""; for(i = 0; i<=1033200; i+=1) {bigstr += str}; ws = new WebSocket('ws://localhost:3000/ws/size') ; ws.onmessage = function(e) {console.log(e.data.length)};ws. onopen = function(e) {ws.send(bigstr)}

		# Dangerzone! use `send` instead: formats the data as one or more WebSocket frames.
		def self.frame_data data, op_code = nil, fin = true
			# set up variables
			frame = ''.force_encoding('binary')
			op_code ||= (data.encoding.name == 'UTF-8' ? 1 : 2)


			if data[FRAME_SIZE_LIMIT] && fin
				# fragment big data chuncks into smaller frames - op-code reset for 0 for all future frames.
				data = data.dup
				data.force_encoding('binary')
				[frame << frame_data(data.slice!(0...FRAME_SIZE_LIMIT), op_code, false), op_code = 0] while data.length > FRAME_SIZE_LIMIT # 1048576
				# frame << frame_data(data.slice!(0..1048576), op_code, false)
				# data = 
				# op_code = 0
			end

			# apply extenetions to the frame
			ext = 0
			# ext |= call each service.protocol.extenetions with data #changes data and returns flags to be set
			# service.protocol.extenetions.each { |ex| ext |= WSProtocol::SUPPORTED_EXTENTIONS[ex[0]][2].call data, ex[1..-1]}

			# set 
			frame << ( (fin ? 0b10000000 : 0) | (op_code & 0b00001111) | ext).chr

			if data.length < 125
				frame << data.length.chr
			elsif data.length.bit_length <= 16					
				frame << 126.chr
				frame << [data.length].pack('S>')
			else
				frame << 127.chr
				frame << [data.length].pack('Q>')
			end
			frame.force_encoding(data.encoding)
			frame << data
			frame.force_encoding('binary')
			frame
		end
	end

	module_function
	# Sets the defalt Websockt auto-ping interval.
	#
	# This method accepts one value, which should be either a number in seconds or `false`.
	#
	# The default ping interval is 45 seconds.
	#
	# It's possible to set the ping interval to false, thereby disabling auto-pinging.
	def ping_interval=(val)
		WSResponse.ping_interval = val
	end
	# Returns the defalt Websockt auto-ping interval.
	#
	# Plezi will automatically send a ping frame to keep websocket connections open.
	# This auto-pinging can be disabled by setting the `ping_interval` to false.
	def ping_interval
		WSResponse.ping_interval
	end

end
