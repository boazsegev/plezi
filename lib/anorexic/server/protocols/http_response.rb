module Anorexic

	# this class handles HTTP response objects.
	#
	# learning from rack, the basic response objects imitates the [0, {}, []] structure... with some updates.
	#
	# the Response's body should respond to each (and optionally to close).
	#
	# The response can be sent asynchronously, but headers and status cannot be changed once the response started sending data.
	class HTTPResponse

		#the response's status code
		attr_accessor :status
		#the response's headers
		attr_reader :headers
		#the flash cookie-jar (single-use cookies, that survive only one request)
		attr_reader :flash
		#the response's body container (defaults to an array, but can be replaces by any obect that supports `each` - `close` is NOT supported - call `close` as a callback block after `send` if you need to close the object).
		attr_accessor :body
		#bytes sent to the asynchronous que so far - excluding headers (only the body object).
		attr_reader :bytes_sent
		#the service through which the response will be sent.
		attr_reader :service
		#the request.
		attr_accessor :request
		#the http version header
		attr_accessor :http_version
		#Danger Zone! direct access to cookie headers - don't use this unless you know what you're doing!
		attr_reader :cookies

		# the response object responds to a specific request on a specific service.
		# hence, to initialize a response object, a request must be set.
		#
		# use, at the very least `HTTPResponse.new request`
		def initialize request, status = 200, headers = {}, body = []
			@request, @status, @headers, @body, @service = request, status, headers, body, (defined?(ANOREXIC_ON_RACK) ? false : request.service)
			@http_version = 'HTTP/1.1' # request.version
			@bytes_sent = 0
			@finished = false
			@cookies = {}
			# propegate flash object
			@flash = Hash.new do |hs,k|
				hs["anorexic_flash_#{k.to_s}"] if hs.has_key? "anorexic_flash_#{k.to_s}"
			end
			request.cookies.each do |k,v|
				@flash[k] = v if k.to_s.start_with? "anorexic_flash_"
			end
		end

		# returns true if headers were already sent
		def headers_sent?
			@headers.frozen?
		end

		# returns true if the response is already finished (the client isn't expecting any more data).
		def finished?
			@finished
		end

		# pushes data to the body of the response. this is the preffered way to add data to the response.
		def << str
			body.push str			
		end

		# returns a response header, if set.
		def [] header
			headers[header] # || @cookies[header]
		end

		# sets a response header. response headers should be a down-case String or Symbol.
		#
		# this is the prefered to set a header.
		#
		# returns the value set for the header.
		#
		# see HTTP response headers for valid headers and values: http://en.wikipedia.org/wiki/List_of_HTTP_header_fields
		def []= header, value
			header.is_a?(String) ? header.downcase! : (header.is_a?(Symbol) ? (header = header.to_s.downcase.to_sym) : (return false))
			headers[header]	= value
		end

		# sets/deletes cookies when headers are sent.
		#
		# accepts:
		# name:: the cookie's name
		# value:: the cookie's value
		# parameters:: a parameters Hash for cookie creation.
		#
		# parameters accept any of the following Hash keys and values:
		#
		# expires:: a Time object with the expiration date. defaults to 10 years in the future.
		# max_age:: a Max-Age HTTP cookie string.
		# path:: the path from which the cookie is acessible. defaults to '/'.
		# domain:: the domain for the cookie (best used to manage subdomains). defaults to the active domain (sub-domain limitations might apply).
		# secure:: if set to `true`, the cookie will only be available over secure connections. defaults to false.
		# http_only:: if true, the HttpOnly flag will be set (not accessible to javascript). defaults to false.
		#
		def set_cookie name, value, params = {}
			params[:expires] = (Time.now - 315360000) unless value
			value ||= 'deleted'
			params[:expires] ||= (Time.now + 315360000) unless params[:max_age]
			params[:path] ||= '/'
			value = HTTP.encode(value.to_s)
			if params[:max_age]
				value << ("; Max-Age=%s" % params[:max_age])
			else
				value << ("; Expires=%s" % params[:expires].httpdate)
			end
			value << "; Path=#{params[:path]}"
			value << "; Domain=#{params[:domain]}" if params[:domain]
			value << "; Secure" if params[:secure]
			value << "; HttpOnly" if params[:http_only]
			@cookies[HTTP.encode(name.to_s).to_sym] = value
		end

		# deletes a cookie (actually calls `set_cookie name, nil`)
		def delete_cookie name
			set_cookie name, nil
		end

		# clears the response object, unless headers were already sent (use `response.body.clear` to clear only the unsent body).
		#
		# returns false if the response was already sent.
		def clear
			return false if headers.frozen? || @finished
			@status, @body, @headers, @cookies = 200, [], {}, {}
			true
		end

		# sends the response object. headers will be frozen (they can only be sent at the head of the response).
		#
		# the response will remain open for more data to be sent through (using `response << data` and `response.send`).
		def send
			raise 'HTTPResponse SERVICE MISSING: cannot send http response without a service.' unless service
			send_headers
			return if request.head?
			if headers["transfer-encoding"] == "chunked"
				body.each do |s|
					service.send "#{s.bytesize.to_s(16)}\r\n"
					service.send s
					service.send "\r\n"
					@bytes_sent += s.bytesize
				end
			else
				body.each do |s|
					service.send s
					@bytes_sent += s.bytesize
				end
			end
			@body.is_a?(Array) ? @body.clear : ( @body = [] )
		end

		# sends the response and flags the response as complete. future data should not be sent. the flag will only be enforced be the Anorexic router. your code might attempt sending data (which would probbaly be ignored by the client or raise an exception).
		def finish
			@headers['content-length'] ||= body[0].bytesize if !headers_sent? && body.is_a?(Array) && body.length == 1
			return self if defined?(ANOREXIC_ON_RACK)
			raise 'HTTPResponse SERVICE MISSING: cannot send http response without a service.' unless service
			self.send
			service.send( (headers["transfer-encoding"] == "chunked") ? "0\r\n\r\n" : nil)
			@finished = true
			# log
			Anorexic.log_raw "#{request[:client_ip]} [#{Time.now.utc}] \"#{request[:method]} #{request[:original_path]} #{request[:requested_protocol]}\/#{request[:version]}\" #{status} #{bytes_sent.to_s} #{"%0.3f" % ((Time.now - request[:time_recieved])*1000)}ms\n"
		end

		# attempts to finish the response - if it was not flaged as completed.
		def try_finish
			finish unless @finished
		end

		# Danger Zone (internally used method, use with care): fix response's headers before sending them (date, connection and transfer-coding).
		def fix_headers
			# headers['Connection'] ||= "Keep-Alive"
			headers['Date'] = Time.now.httpdate
			headers['Transfer-Encoding'] ||= 'chunked' if !headers['content-length']
			headers['cache-control'] ||= 'no-cache'
			# remove old flash cookies
			request.cookies.keys.each do |k|
				if k.to_s.start_with? "anorexic_flash_"
					set_cookie k, nil
					flash.delete k
				end
			end
			#set new flash cookies
			@flash.each do |k,v|
				set_cookie "anorexic_flash_#{k.to_s}", v
			end
		end
		# Danger Zone (internally used method, use with care): fix response's headers before sending them (date, connection and transfer-coding).
		def send_headers
			return false if @headers.frozen?
			fix_headers
			service.send "#{@http_version} #{status} #{STATUS_CODES[status] || 'unknown'}\r\n"
			headers.each {|k,v| service.send "#{k.to_s}: #{v}\r\n"}
			@cookies.each {|k,v| service.send "Set-Cookie: #{k.to_s}=#{v.to_s}\r\n"}
			service.send "\r\n"
			@headers.freeze
			# @cookies.freeze
		end
		
		# response status codes, as defined.
		STATUS_CODES = {100=>"Continue",
			101=>"Switching Protocols",
			102=>"Processing",
			200=>"OK",
			201=>"Created",
			202=>"Accepted",
			203=>"Non-Authoritative Information",
			204=>"No Content",
			205=>"Reset Content",
			206=>"Partial Content",
			207=>"Multi-Status",
			208=>"Already Reported",
			226=>"IM Used",
			300=>"Multiple Choices",
			301=>"Moved Permanently",
			302=>"Found",
			303=>"See Other",
			304=>"Not Modified",
			305=>"Use Proxy",
			306=>"(Unused)",
			307=>"Temporary Redirect",
			308=>"Permanent Redirect",
			400=>"Bad Request",
			401=>"Unauthorized",
			402=>"Payment Required",
			403=>"Forbidden",
			404=>"Not Found",
			405=>"Method Not Allowed",
			406=>"Not Acceptable",
			407=>"Proxy Authentication Required",
			408=>"Request Timeout",
			409=>"Conflict",
			410=>"Gone",
			411=>"Length Required",
			412=>"Precondition Failed",
			413=>"Payload Too Large",
			414=>"URI Too Long",
			415=>"Unsupported Media Type",
			416=>"Range Not Satisfiable",
			417=>"Expectation Failed",
			422=>"Unprocessable Entity",
			423=>"Locked",
			424=>"Failed Dependency",
			426=>"Upgrade Required",
			428=>"Precondition Required",
			429=>"Too Many Requests",
			431=>"Request Header Fields Too Large",
			500=>"Internal Server Error",
			501=>"Not Implemented",
			502=>"Bad Gateway",
			503=>"Service Unavailable",
			504=>"Gateway Timeout",
			505=>"HTTP Version Not Supported",
			506=>"Variant Also Negotiates",
			507=>"Insufficient Storage",
			508=>"Loop Detected",
			510=>"Not Extended",
			511=>"Network Authentication Required"
		}
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