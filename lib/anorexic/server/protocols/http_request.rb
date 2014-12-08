module Anorexic

	# class is the base for the HTTP server.
	#
	# the class is initialized with a TCP/IP connection socket and starts
	# an event driven cycle using the `EventStack.push` and `EventStack.reverse_async`.
	#
	# to-do: fox logging.
	class HTTPRequest < Hash

		def initialize service
			super()
			self[:anorexic_service] = service
			######
			# set global variables
			self[:client_ip] = service.socket.remote_address.ip_address rescue false
		end

		public

		# the request's headers
		def headers
			self.select {|k,v| k.is_a? String }
		end
		# the request's method (GET, POST... etc').
		def request_method
			self[:method]
		end
		# set request's method (GET, POST... etc').
		def request_method= value
			self[:method] = value
		end
		# the parameters sent by the client.
		def params
			self[:params]
		end
		# the cookies sent by the client.
		def cookies
			self[:cookies]
		end

		# the query string
		def query
			self[:query]
		end

		# the original (frozen) path (resource requested).
		def original_path
			self[:original_path]
		end

		# the requested path (rewritable).
		def path
			self[:path]
		end
		def path=(new_path)
			self[:path] = new_path
		end

		# the base url ([http/https]://host[:port])
		def base_url switch_protocol = nil
			"#{switch_protocol || self[:requested_protocol]}://#{self[:host_name]}#{self[:port]? ":#{self[:port]}" : ''}"
		end

		# the service (socket wrapper) that answered this request
		def service
			self[:anorexic_service]
		end
		# the protocol managing this request
		def protocol
			self[:requested_protocol]
		end
		# the handler dealing with this request
		def handler
			self[:anorexic_service].handler
		end

		# method recognition

		# returns true of the method == GET
		def get?
			self[:method] == 'GET'
		end
		# returns true of the method == HEAD
		def head?
			self[:method] == 'HEAD'
		end
		# returns true of the method == POST
		def post?
			self[:method] == 'POST'
		end
		# returns true of the method == PUT
		def put?
			self[:method] == 'PUT'
		end
		# returns true of the method == DELETE
		def delete?
			self[:method] == 'DELETE'
		end
		# returns true of the method == TRACE
		def trace?
			self[:method] == 'TRACE'
		end
		# returns true of the method == OPTIONS
		def options?
			self[:method] == 'OPTIONS'
		end
		# returns true of the method == CONNECT
		def connect?
			self[:method] == 'CONNECT'
		end
		# returns true of the method == PATCH
		def patch?
			self[:method] == 'PATCH'
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
#
# => "GET / HTTP/1.1\n\rHost: localhost:2000\n\rAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n\rCookie: user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\n\rUser-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25\n\rAccept-Language: en-us\n\rAccept-Encoding: gzip, deflate\n\rConnection: keep-alive\n\r\n\r"
# => "GET /people/are/friendly HTTP/1.1\n\rHost: localhost:2000\n\rAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n\rCookie: user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\n\rUser-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25\n\rAccept-Language: en-us\n\rAccept-Encoding: gzip, deflate\n\rConnection: keep-alive\n\r\n\r"
# => "GET /girls?sexy=true HTTP/1.1\n\rHost: localhost:2000\n\rAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n\rCookie: user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\n\rUser-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25\n\rAccept-Language: en-us\n\rAccept-Encoding: gzip, deflate\n\rConnection: keep-alive\n\r\n\r"
# chunked => "17d; ignored data=boaz\r\nGET / HTTP/1.1\r\nHost: localhost:3000\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nCookie: user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\r\nUser-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25\r\nAccept-Language: en-us\r\nAccept-Encoding: gzip, deflate\r\nConnection: keep-alive\r\nc\r\n\r\nparsed as:\r\n\r\n4f4\r\n{:raw=>\"GET / HTTP/1.1\\r\\nHost: localhost:3000\\r\\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\\r\\nCookie: user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\\r\\nUser-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25\\r\\nAccept-Language: en-us\\r\\nAccept-Encoding: gzip, deflate\\r\\nConnection: keep-alive\\r\\n\\r\\n\", :anorexic_service=>#<Anorexic::BasicService:0x007ff4daab5ac8 @handler=Anorexic::HTTPEcho, @socket=#<TCPSocket:fd 9>, @in_que=\"\", @out_que=[], @locker=#<Mutex:0x007ff4daab5a28>, @parameters={:protocol=>Anorexic::HTTPProtocol, :handler=>Anorexic::HTTPEcho}, @protocol=Anorexic::HTTPProtocol>, :params=>{}, :cookies=>{:user_token=>\"2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\"}, :method=>\"GET\", :query=>\"/\", :original_path=>\"/\", :path=>\"/\", :version=>\"HTTP/1.1\", \"host\"=>\"localhost:3000\", \"accept\"=>\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\", \"cookie\"=>\"user_token=2INa32_vDgx8Aa1qe43oILELpSdIe9xwmT8GTWjkS-w\", \"user-agent\"=>\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25\", \"accept-language\"=>\"en-us\", \"accept-encoding\"=>\"gzip, deflate\", \"connection\"=>\"keep-alive\"}\r\n0\r\n\r\n"
