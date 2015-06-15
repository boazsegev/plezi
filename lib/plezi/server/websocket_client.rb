module Plezi

	# Websocket client objects are members of this class.
	#
	# This is a VERY simple Websocket client. It doesn't support cookies, HTTP authentication or... well... anything, really.
	# It's just a simple client used for the Plezi framework's testing. It's usful for simple WebSocket connections, but no more.
	class WebsocketClient
		attr_accessor :response, :request

		class RequestEmulator < Hash
			def service
				self[:connection]
			end
		end

		def initialize request
			@response = WSResponse.new request
			@options = request[:options]
			@on_message = @options[:on_message]
			raise "Websocket client must have an #on_message Proc." unless @on_message && @on_message.is_a?(Proc)
			@on_connect = @options[:on_connect]
			@on_disconnect = @options[:on_disconnect]
		end

		def on_message(data = false, &block)
			unless data
				@on_message = block if block
				return @on_message
			end
			instance_exec( data, &@on_message) 
		end

		def on_connect(&block)
			if block
				@on_connect = block
				return @on_connect
			end
			instance_exec(&@on_connect) if @on_connect
		end

		def on_disconnect(&block)
			if block
				@on_disconnect = block
				return @on_disconnect
			end
			instance_exec(&@on_disconnect) if @on_disconnect
		end

		#disconnects the Websocket.
		def disconnect
			@response.close if @response
		end

		# sends data through the socket. a shortcut for ws_client.response <<
		def << data
			@response << data			
		end

		# Create a simple Websocket Client(!)
		#
		# This method accepts two parameters:
		# url:: a String representing the URL of the websocket. i.e.: 'ws://foo.bar.com:80/ws/path'
		# options:: a Hash with options to be used. The options will be used to define
		# &block:: an optional block that accepts one parameter (data) and will be used as the `#on_message(data)`
		#
		# The method will either return a WebsocketClient instance object or it will raise an exception.
		#
		# An on_message Proc must be defined, or the method will fail.
		#
		# The on_message Proc can be defined using the optional block:
		#
		#      WebsocketClient.connect_to("ws://localhost:3000/") {|data| response << data} #echo example
		#
		# OR, the on_message Proc can be defined using the options Hash: 
		#
		#      WebsocketClient.connect_to("ws://localhost:3000/", on_connect: -> {}, on_message: -> {|data| response << data})
		#
		# The #on_message(data), #on_connect and #on_disconnect methods will be executed within the context of the WebsocketClient
		# object, and will have natice acess to the Websocket response object.
		#
		# After the WebsocketClient had been created, it's possible to update the #on_message and #on_disconnect methods:
		#
		#      # updates #on_message
		#      wsclient.on_message do |data|
		#           response << "I'll disconnect on the next message!"
		#           # updates #on_message again.
		#           on_message {|data| disconnect }
		#      end
		#
		#
		# !!please be aware that the Websockt Client will not attempt to verify SSL certificates,
		# so that even SSL connections are subject to a possible man in the middle attack.
		def self.connect_to url, options={}, &block
			options[:on_message] ||= block
			options[:handler] = WebsocketClient
			options[:protocol] = EventMachine::Protocol
			url = URI.parse(url) unless url.is_a?(URI)
			connection_type = EventMachine::Connection

			socket = false #implement the connection, ssl vs. no ssl
			if url.scheme == "https" || url.scheme == "wss"
				connection_type = EventMachine::SSLConnection
				options[:ssl_client] = true
				url.port ||= 443
			end
			url.port ||= 80
			socket = TCPSocket.new(url.host, url.port)
			connection = connection_type.new socket, options
			psedo_request = RequestEmulator.new
			psedo_request[:connection] = connection
			psedo_request[:client_ip] = 'WS Client'
			psedo_request[:url] = url
			psedo_request[:options] = options
			WSProtocol.client_handshake psedo_request
			connection.handler
			rescue => e
				socket.close if socket
				raise e
		end

	end

	class WSProtocol < EventMachine::Protocol
		def self.client_handshake psedo_request, timeout = 5
			connection = psedo_request[:connection]
			url = psedo_request[:url]
			# send protocol upgrade request
			websocket_key = [(Array.new(16) {rand 255} .pack 'c*' )].pack('m0*')
			connection.send "GET #{url.path}#{url.query.to_s.empty? ? '' : ('?' + url.query)} HTTP/1.1\r\nHost: #{url.host}#{url.port ? (':'+url.port.to_s) : ''}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: #{websocket_key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
			# wait for answer - make sure we don't over-read
			# (a websocket message might be sent immidiately after connection is established)
			reply = ''
			reply.force_encoding('binary')
			start_time = Time.now
			stop_reply = "\r\n\r\n"
			until reply[-4..-1] == stop_reply
				(reply << connection.read(1)) rescue (sleep 0.1)
				raise Timeout::Error, "Websocket client handshake timed out (HTTP reply not recieved)\n\n Got Only: #{reply.dump}" if Time.now >= (start_time + 5)
			end
			# review reply
			raise 'Connection Refused.' unless reply.lines[0].match(/^HTTP\/[\d\.]+ 101/i)
			raise 'Websocket Key Authentication failed.' unless reply.match(/^Sec-WebSocket-Accept:[\s]*([^\s]*)/i) && reply.match(/^Sec-WebSocket-Accept:[\s]*([^\s]*)/i)[1] == Digest::SHA1.base64digest(websocket_key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
			# set-up handler response object. 
			connection.handler = WebsocketClient.new psedo_request

			# raise "not yet implemented"

			# set the connetion's protocol to a new WSProtocol instance
			connection.protocol = self.new psedo_request[:connection], psedo_request[:options]
			# add the socket to the EventMachine IO reactor
			EventMachine.add_io connection.socket, connection
			true
		end
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