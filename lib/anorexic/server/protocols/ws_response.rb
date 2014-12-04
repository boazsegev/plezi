module Anorexic

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

		# pushes data to the body of the response. this is the preffered way to add data to the response.
		def << str
			service.send_nonblock self.class.frame_data(str.dup)
		end

		# sends the response object. headers will be frozen (they can only be sent at the head of the response).
		#
		# the response will remain open for more data to be sent through (using `response << data` and `response.send`).
		def send str
			service.send_nonblock self.class.frame_data(str.dup)
		end

		# makes sure any data held in the buffer is actually sent.
		def flush
			service.flush
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
			op_code ||= data.encoding.name == 'UTF-8' ? 1 : 2
			data.force_encoding('binary')

			# fragment big data chuncks into smaller frames
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