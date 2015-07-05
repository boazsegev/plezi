module Plezi

	# this module is the protocol (controller) for the HTTP server.
	#
	#
	# to do: implemet logging, support body types: multipart (non-ASCII form data / uploaded files), json & xml
	class WSProtocol < EventMachine::Protocol

		SUPPORTED_EXTENTIONS = {}
		# SUPPORTED_EXTENTIONS['x-webkit-deflate-frame'] = Proc.new {|body, params| }
		# SUPPORTED_EXTENTIONS['permessage-deflate'] = Proc.new {|body, params| } # client_max_window_bits

		# get the timeout interval for this websockt (the number of seconds the socket can remain with no activity - will be reset every ping, message etc').
		def timeout_interval
			connection.timeout
		end
		# set the timeout interval for this websockt (the number of seconds the socket can remain with no activity - will be reset every ping, message etc').
		def timeout_interval= value
			connection.timeout = value
		end

		# the extentions registered for the websockets connection.
		attr_reader :extentions

		def initialize connection, params
			super
			@extentions = []
			@locker = Mutex.new
			@parser_stage = 0
			@parser_data = {}
			@parser_data[:body] = []
			@parser_data[:step] = 0
			@message = ''
		end

		# a proc object that calls #on_connect for the handler passed.
		ON_CONNECT_PROC = Proc.new {|handler| handler.on_connect}
		# called when connection is initialized.
		def on_connect
			# set timeout to 60 seconds
			Plezi.log_raw "#{@request[:client_ip]} [#{Time.now.utc}] - #{@connection.object_id} Upgraded HTTP to WebSockets.\n"
			Plezi::EventMachine.queue [@connection.handler], ON_CONNECT_PROC if @connection.handler && @connection.handler.methods.include?(:on_connect)
			@connection.touch
			Plezi.run_after(2) { @connection.timeout = 60 }
		end

		# called when data is recieved
		# returns an Array with any data not yet processed (to be returned to the in-que).
		def on_message
			# parse the request
			extract_message connection.read.to_s.bytes
			true
		end

		# a proc object that calls #on_disconnect for the handler passed.
		ON_DISCONNECT_PROC = Proc.new {|handler| handler.on_disconnect}
		# called when a disconnect is fired
		# (socket was disconnected / connection should be disconnected / shutdown / socket error)
		def on_disconnect
			# Plezi.log_raw "#{@request[:client_ip]} [#{Time.now.utc}] - #{@connection.object_id} Websocket disconnected.\n"
			Plezi::EventMachine.queue [@connection.handler], ON_DISCONNECT_PROC if @connection.handler.methods.include?(:on_disconnect)
		end

		########
		# Protocol Specific Helpers

		# perform the HTTP handshake for WebSockets. send a 400 Bad Request error if handshake fails.
		def http_handshake request, response, handler
			# review handshake (version, extentions)
			# should consider adopting the websocket gem for handshake and framing:
			# https://github.com/imanel/websocket-ruby
			# http://www.rubydoc.info/github/imanel/websocket-ruby
			return connection.handler.hosts[request[:host] || :default].send_by_code request, 400 , response.headers.merge('sec-websocket-extensions' => SUPPORTED_EXTENTIONS.keys.join(', ')) unless request['upgrade'].to_s.downcase == 'websocket' && 
									request['sec-websocket-key'] &&
									request['connection'].to_s.downcase == 'upgrade' &&
									# (request['sec-websocket-extensions'].split(/[\s]*[,][\s]*/).reject {|ex| ex == '' || SUPPORTED_EXTENTIONS[ex.split(/[\s]*;[\s]*/)[0]] } ).empty? &&
									(request['sec-websocket-version'].to_s.downcase.split(/[, ]/).map {|s| s.strip} .include?( '13' ))
			@request = request
			response.status = 101
			response['upgrade'] = 'websocket'
			response['content-length'] = '0'
			response['connection'] = 'Upgrade'
			response['sec-websocket-version'] = '13'
			# Note that the client is only offering to use any advertised extensions
			# and MUST NOT use them unless the server indicates that it wishes to use the extension.
			request['sec-websocket-extensions'].to_s.split(/[\s]*[,][\s]*/).each {|ex| @extentions << ex.split(/[\s]*;[\s]*/) if SUPPORTED_EXTENTIONS[ex.split(/[\s]*;[\s]*/)[0]]}
			response['sec-websocket-extensions'] = @extentions.map {|e| e[0] } .join (',')
			response.headers.delete 'sec-websocket-extensions' if response['sec-websocket-extensions'].empty?
			response['Sec-WebSocket-Accept'] = Digest::SHA1.base64digest(request['sec-websocket-key'] + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
			response.finish
			@extentions.freeze
			connection.protocol = self
			connection.handler = handler
			Plezi::EventMachine.queue [self], ON_CONNECT_PROC
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
					review_message_size
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

		# The proc queued whenever a frame is complete.
		COMPLETE_FRAME_PROC = Proc.new {|handler, message| handler.on_message message}

		# handles the completed frame and sends a message to the handler once all the data has arrived.
		def complete_frame
			@extentions.each {|ex| SUPPORTED_EXTENTIONS[ex[0]][1].call(@parser_data[:body], ex[1..-1]) if SUPPORTED_EXTENTIONS[ex[0]]}

			case @parser_data[:op_code]
			when 9 # ping
				# handle @parser_data[:op_code] == 9 (ping)
				Plezi.callback @connection, :send_nonblock, WSResponse.frame_data(@parser_data[:body].pack('C*'), 10) # "\x8A\x00" can't be used, because body should be returned. # sends pong op_code == 10
				@parser_op_code = nil if @parser_op_code == 9
			when 10 #pong
				# handle @parser_data[:op_code] == 10 (pong)
				@parser_op_code = nil if @parser_op_code == 10
			when 8
				# handle @parser_data[:op_code] == 8 (close)
				Plezi.callback( @connection, :send_nonblock, "\x88\x00" ) { @connection.disconnect }
				@parser_op_code = nil if @parser_op_code == 8
			else
				@message << @parser_data[:body].pack('C*')
				# handle @parser_data[:op_code] == 0 / fin == false (continue a frame that hasn't ended yet)
				if @parser_data[:fin]
					HTTP.make_utf8! @message if @parser_op_code == 1
					Plezi::EventMachine.queue [@connection.handler, @message], COMPLETE_FRAME_PROC
					@message = ''
					@parser_op_code = nil
				end
			end
			@parser_stage = 0
			@parser_data[:body].clear
			@parser_data[:step] = 0
		end
		#reviews the message size and closes the connection if expected message size is over the allowed limit.
		def review_message_size
			if ( self.class.message_size_limit.to_i > 0 ) && ( ( @parser_data[:len] + @message.bytesize ) > self.class.message_size_limit.to_i )
				Plezi.callback @connection, :disconnect
				@message.clear
				@parser_data[:step] = 0
				@parser_data[:body].clear
				@parser_stage = -1
				return false
			end
			true
		end

		# Sets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
		#
		# Although memory will be allocated for the latest TCP/IP frame,
		# this allows the websocket to disconnect if the incoming expected message size exceeds the allowed maximum size.
		#
		# If the sessage size limit is exceeded, the disconnection will be immidiate as an attack will be assumed. The protocol's normal disconnect sequesnce will be discarded.
		def self.message_size_limit=val
			@message_size_limit = val
		end
		# Gets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
		def self.message_size_limit
			@message_size_limit
		end
		message_size_limit = 0

	end

	# Sets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
	#
	# Although memory will be allocated for the latest TCP/IP frame,
	# this allows the websocket to disconnect if the incoming expected message size exceeds the allowed maximum size.
	#
	# If the sessage size limit is exceeded, the disconnection will be immidiate as an attack will be assumed. The protocol's normal disconnect sequesnce will be discarded.
	def self.ws_message_size_limit=val
		WSProtocol.message_size_limit = val
	end
	# Gets the message byte size limit for a Websocket message. Defaults to 0 (no limit)
	def self.ws_message_size_limit
		WSProtocol.message_size_limit
	end
end


######
## example requests

# GET /nickname HTTP/1.1
# Upgrade: websocket
# Connection: Upgrade
# Host: localhost:3000
# Origin: https://www.websocket.org
# Cookie: test=my%20cookies; user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w
# Pragma: no-cache
# Cache-Control: no-cache
# Sec-WebSocket-Key: 1W9B64oYSpyRL/yuc4k+Ww==
# Sec-WebSocket-Version: 13
# Sec-WebSocket-Extensions: x-webkit-deflate-frame
# User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25