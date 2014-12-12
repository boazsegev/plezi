module Anorexic

	# this module is the protocol (controller) for the HTTP server.
	#
	#
	# to do: implemet logging, support body types: multipart (non-ASCII form data / uploaded files), json & xml
	class WSProtocol

		SUPPORTED_EXTENTIONS = {}
		# SUPPORTED_EXTENTIONS['x-webkit-deflate-frame'] = Proc.new {|body, params| }
		# SUPPORTED_EXTENTIONS['permessage-deflate'] = Proc.new {|body, params| } # client_max_window_bits

		# get the timeout interval for this websockt (the number of seconds the socket can remain with no activity - will be reset every ping, message etc').
		def timeout_interval
			@timeout_interval
		end
		# set the timeout interval for this websockt (the number of seconds the socket can remain with no activity - will be reset every ping, message etc').
		def timeout_interval= value
			@timeout_interval = value
			Anorexic.callback service, :set_timeout, @timeout_interval
		end

		# the service (holding the socket) over which this protocol is running.
		attr_reader :service
		# the extentions registered for the websockets connection.
		attr_reader :extentions

		def initialize service, params
			@params = params
			@service = service
			@extentions = []
			@locker = Mutex.new
			@parser_stage = 0
			@parser_data = {}
			@parser_data[:body] = []
			@parser_data[:step] = 0
			@in_que = []
			@message = ''
			@timeout_interval = 60
		end

		# called when connection is initialized.
		def on_connect service
			# cancel service timeout? (for now, reset to 60 seconds)
			service.timeout = @timeout_interval
			# Anorexic.callback service, :timeout=, @timeout_interval
			Anorexic.callback @service.handler, :on_connect if @service.handler.methods.include?(:on_connect)
			Anorexic.info "Upgraded HTTP to WebSockets. Logging only errors."
		end

		# called when data is recieved
		# returns an Array with any data not yet processed (to be returned to the in-que).
		def on_message(service)
			# parse the request
			return @locker.synchronize {extract_message service.read.bytes}
			true
		end

		# called when a disconnect is fired
		# (socket was disconnected / service should be disconnected / shutdown / socket error)
		def on_disconnect service
			Anorexic.callback @service.handler, :on_disconnect if @service.handler.methods.include?(:on_disconnect)
		end

		# called when an exception was raised
		# (socket was disconnected / service should be disconnected / shutdown / socket error)
		def on_exception service, e
			Anorexic.error e
		end

		########
		# Protocol Specific Helpers

		# perform the HTTP handshake for WebSockets. send a 400 Bad Request error if handshake fails.
		def http_handshake request, response, handler
			# review handshake (version, extentions)
			# should consider adopting the websocket gem for handshake and framing:
			# https://github.com/imanel/websocket-ruby
			# http://www.rubydoc.info/github/imanel/websocket-ruby
			return request.service.handler.hosts[request[:host] || :default].send_by_code request, 400 , response.headers.merge('sec-websocket-extensions' => SUPPORTED_EXTENTIONS.keys.join(', ')) unless request['upgrade'].to_s.downcase == 'websocket' && 
									request['sec-websocket-key'] &&
									request['connection'].to_s.downcase == 'upgrade' &&
									# (request['sec-websocket-extensions'].split(/[\s]*[,][\s]*/).reject {|ex| ex == '' || SUPPORTED_EXTENTIONS[ex.split(/[\s]*;[\s]*/)[0]] } ).empty? &&
									(request['sec-websocket-version'].to_s.downcase.split(/[, ]/).map {|s| s.strip} .include?( '13' ))
			response.status = 101
			response['upgrade'] = 'websocket'
			response['content-length'] = '0'
			response['connection'] = 'Upgrade'
			response['sec-websocket-version'] = '13'
			# Note that the client is only offering to use any advertised extensions
			# and MUST NOT use them unless the server indicates that it wishes to use the extension.
			request['sec-websocket-extensions'].split(/[\s]*[,][\s]*/).each {|ex| @extentions << ex.split(/[\s]*;[\s]*/) if SUPPORTED_EXTENTIONS[ex.split(/[\s]*;[\s]*/)[0]]}
			response['sec-websocket-extensions'] = @extentions.map {|e| e[0] } .join (',')
			response.headers.delete 'sec-websocket-extensions' if response['sec-websocket-extensions'].empty?
			response['Sec-WebSocket-Accept'] = Digest::SHA1.base64digest(request['sec-websocket-key'] + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
			response.finish
			@extentions.freeze
			response.service.protocol = self
			response.service.handler = handler
			Anorexic.callback self, :on_connect, response.service
			return true
		end

		# parse the message and send it to the handler
		#
		# test: frame = ["819249fcd3810b93b2fb69afb6e62c8af3e83adc94ee2ddd"].pack("H*").bytes; @parser_stage = 0; @parser_data = {}
		# accepts:
		# frame:: an array of bytes
		def extract_message data
			until data.empty?
					if @parser_stage == 0 && !data.empty?
					@parser_data[:fin] = data[0][7] == 1
					@parser_data[:rsv1] = data[0][6] == 1
					@parser_data[:rsv2] = data[0][5] == 1
					@parser_data[:rsv3] = data[0][4] == 1
					@parser_data[:op_code] = data[0] & 0b00001111
					@parser_op_code ||= data[0] & 0b00001111
					@parser_stage += 1
					data.shift
				end
				if @parser_stage == 1
					@parser_data[:mask] = data[0][7]
					@parser_data[:len] = data[0] & 0b01111111
					data.shift
					if @parser_data[:len] == 126
						@parser_data[:len] = merge_bytes( *(data.slice!(0,2)) ) # should be = ?
					elsif @parser_data[:len] == 127
						len = 0
						@parser_data[:len] = merge_bytes( *(data.slice!(0,8)) ) # should be = ?
					end
					@parser_data[:step] = 0
					@parser_stage += 1
				end
				if @parser_stage == 2 && @parser_data[:mask] == 1
					@parser_data[:mask_key] = data.slice!(0,4)
					@parser_stage += 1
				elsif  @parser_data[:mask] != 1
					@parser_stage += 1
				end
				if @parser_stage == 3 && @parser_data[:step] < @parser_data[:len]
					# data.length.times {|i| data[0] = data[0] ^ @parser_data[:mask_key][@parser_data[:step] % 4] if @parser_data[:mask_key]; @parser_data[:step] += 1; @parser_data[:body] << data.shift; break if @parser_data[:step] == @parser_data[:len]}
					slice_length = [data.length, (@parser_data[:len]-@parser_data[:step])].min
					if @parser_data[:mask_key]
						masked = data.slice!(0, slice_length)
						masked.map!.with_index {|b, i|  b ^ @parser_data[:mask_key][ ( i + @parser_data[:step] ) % 4]  }
						@parser_data[:body].concat masked
					else
						@parser_data[:body].concat data.slice!(0, slice_length)
					end
					@parser_data[:step] += slice_length
				end
				complete_frame unless @parser_data[:step] < @parser_data[:len]
			end
			true
		end

		# takes and Array of bytes and combines them to an int(16 Bit), 32Bit or 64Bit number
		def merge_bytes *bytes
			return bytes.pop if bytes.length == 1
			bytes.pop ^ (merge_bytes(*bytes) << 8)
		end

		# handles the completed frame and sends a message to the handler once all the data has arrived.
		def complete_frame
			@extentions.each {|ex| SUPPORTED_EXTENTIONS[ex[0]][1].call(@parser_data[:body], ex[1..-1]) if SUPPORTED_EXTENTIONS[ex[0]]}

			case @parser_data[:op_code]
			when 9, 10
				# handle @parser_data[:op_code] == 9 (ping) / @parser_data[:op_code] == 10 (pong)
				Anorexic.callback @service, :send_nonblock, WSResponse.frame_data(@parser_data[:body].pack('C*'), 10)
				@parser_op_code = nil if @parser_op_code == 9 || @parser_op_code == 10
			when 8
				# handle @parser_data[:op_code] == 8 (close)
				Anorexic.callback( @service, :send_nonblock, WSResponse.frame_data('', 8) ) { @service.disconnect }
				@parser_op_code = nil if @parser_op_code == 8
			else
				@message << @parser_data[:body].pack('C*')
				# handle @parser_data[:op_code] == 0 / fin == false (continue a frame that hasn't ended yet)
				if @parser_data[:fin]
					HTTP.make_utf8! @message if @parser_op_code == 1
					Anorexic.callback @service.handler, :on_message, @message
					@message = ''
					@parser_op_code = nil
				end
			end
			@parser_stage = 0
			@parser_data[:body].clear
			@parser_data[:step] = 0
		end
	end
end


######
## example requests

# GET /?encoding=text HTTP/1.1
# Upgrade: websocket
# Connection: Upgrade
# Host: localhost:3001
# Origin: https://www.websocket.org
# Cookie: test=my%20cookies; user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w
# Pragma: no-cache
# Cache-Control: no-cache
# Sec-WebSocket-Key: 1W9B64oYSpyRL/yuc4k+Ww==
# Sec-WebSocket-Version: 13
# Sec-WebSocket-Extensions: x-webkit-deflate-frame
# User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25