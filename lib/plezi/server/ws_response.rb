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

		def initialize request
			@request, @service = request,request.service
		end

		# sends data through the websocket connection in a non-blocking way.
		#
		# Plezi will try a best guess at the type of the data (binary vs. clear text).
		#
		# This should be the preferred way.
		def << str
			service.send_nonblock self.class.frame_data(str.dup)
			self
		end

		# sends data through the websocket connection in a blocking way.
		#
		# Plezi will try a best guess at the type of the data (binary vs. clear text).
		#
		def send str
			service.send self.class.frame_data(str.dup)
			self
		end
		# sends binary data through the websocket connection in a blocking way.
		#
		def binsend str
			service.send self.class.frame_data(str.dup, 2)
			self
		end
		# sends clear text data through the websocket connection in a blocking way.
		#
		def txtsend str
			service.send self.class.frame_data(str.dup, 1)
			self
		end


		# makes sure any data held in the buffer is actually sent.
		def flush
			service.flush
			self
		end

		# pings the connection
		def ping
			service.send_nonblock self.class.frame_data('', 9)
			self
		end
		# pings the connection
		def pong
			service.send_nonblock self.class.frame_data('', 10)
			self
		end

		# sends any pending data and closes the connection.
		def close
			service.send_nonblock self.class.frame_data('', 8)
			service.disconnect
		end

		# Dangerzone! ()alters the string, use `send` instead: formats the data as one or more WebSocket frames.
		def self.frame_data data, op_code = nil, fin = true
			# set up variables
			frame = ''.force_encoding('binary')
			op_code ||= (data.encoding.name == 'UTF-8' ? 1 : 2)
			data.force_encoding('binary')

			# fragment big data chuncks into smaller frames - op-code reset for 0 for all future frames.
			[frame << frame_data(data.slice!(0..1048576), op_code, false), op_code = 0] while data.length > 1048576

			# apply extenetions to the frame
			ext = 0
			# ext |= call each service.protocol.extenetions with data #changes data and returns flags to be set
			# service.protocol.extenetions.each { |ex| ext |= WSProtocol::SUPPORTED_EXTENTIONS[ex[0]][2].call data, ex[1..-1]}

			# set 
			frame << ( (fin ? 0b10000000 : 0) | (op_code & 0b00001111) | ext).chr

			if data.length < 125
				frame << data.length.chr
			elsif data.length.bit_length < 16					
				frame << 126.chr
				frame << [data.length].pack('S>')
			else
				frame << 127.chr
				frame << [data.length].pack('Q>')
			end
			frame << data
			frame
		end
	end
end
