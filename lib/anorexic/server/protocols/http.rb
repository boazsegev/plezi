module Anorexic

	# this module is the protocol (controller) for the HTTP server.
	#
	#
	# to do: implemet logging, support body types: multipart (non-ASCII form data / uploaded files), json & xml
	class HTTPProtocol

		HTTP_METHODS = %w{GET HEAD POST PUT DELETE TRACE OPTIONS}

		def initialize service, params
			@parser_stage = 0
			@parser_data = {}
			@parser_body = ''
			@parser_chunk = ''
			@parser_length = 0
			@locker = Mutex.new
			@@rack_dictionary ||= {"HOST".freeze => :host_name, 'REQUEST_METHOD'.freeze => :method,
								'PATH_INFO'.freeze => :path, 'QUERY_STRING'.freeze => :query,
								'SERVER_NAME'.freeze => :host_name, 'SERVER_PORT'.freeze => :port,
								'rack.url_scheme'.freeze => :requested_protocol}
		end

		# called when connection is initialized.
		def on_connect service
		end

		# called when data is recieved
		# typically returns an Array with any data not yet processed (to be returned to the in-que)... but here it always processes (or discards) the data.
		def on_message(service, data)
			# parse the request
			@locker.synchronize { parse_message service, data.lines.to_a }
			if (@parser_stage == 1) && @parser_data[:version] >= 1.1
				# send 100 continue message????? doesn't work! both Crome and Safari go crazy if this is sent after the request was sent (but before all the packets were recieved... msgs over 1 Mb).
				# Anorexic.push_event Proc.new { Anorexic.info "sending continue signal."; service.send_nonblock "100 Continue\r\n\r\n" }
				# service.send_unsafe_interrupt "100 Continue\r\n\r\n" # causes double lock on service
			end
			true
		end

		# # called when a disconnect is fired
		# # (socket was disconnected / service should be disconnected / shutdown / socket error)
		def on_disconnect service
		end

		# called when an exception was raised
		# (socket was disconnected / service should be disconnected / shutdown / socket error)
		def on_exception service, e
			Anorexic.error e
		end


		# Protocol specific helper methods.

		# parses incoming data
		def parse_message service, data
			# require 'pry'; binding.pry
			if 	@parser_stage == 0
				return false unless parse_method service, data
			end
			if 	@parser_stage == 1
				return false unless parse_head service, data
			end
			if 	@parser_stage == 2
				return false unless parse_body service, data
			end
			true
		end

		# parses the method request (the first line in the HTTP request).
		def parse_method service, data
			return false unless data[0] && data[0].match(/^#{HTTP_METHODS.join('|')}/)
			@parser_data[:time_recieved] = Time.now
			@parser_data[:params] = {}
			@parser_data[:cookies] = Cookies.new
			@parser_data[:method] = ''
			@parser_data[:query] = ''
			@parser_data[:original_path] = ''
			@parser_data[:path] = ''
			if defined? Rack
				@parser_data['rack.version'] = Rack::VERSION
				@parser_data['rack.multithread'] = true
				@parser_data['rack.multiprocess'] = false
				@parser_data['rack.hijack?'] = false
				@parser_data['rack.logger'] = Anorexic.logger
			end
			@parser_data[:method], @parser_data[:query], @parser_data[:version] = data.shift.split(/[\s]+/)
			@parser_data[:version] = (@parser_data[:version] || 'HTTP/1.1').match(/[0-9\.]+/).to_s.to_f
			data.shift while data[0].to_s.match /^[\r\n]+/
			@parser_stage = 1
		end

		#parses the head on a request (headers and values).
		def parse_head service, data
			until data[0].nil? || data[0].match(/^[\r\n]+$/)
				m = data.shift.match(/^([^:]*):[\s]*([^\r\n]*)/)
				# move cookies to cookie-jar, all else goes to headers
				case m[1].downcase
				when 'cookie'
					HTTP.extract_data m[2].split(/[;,][\s]?/), @parser_data[:cookies], :uri
				end
				@parser_data[ HTTP.make_utf8!(m[1]).downcase ] ? (@parser_data[ HTTP.make_utf8!(m[1]).downcase ] << ", #{HTTP.make_utf8! m[2]}"): (@parser_data[ HTTP.make_utf8!(m[1]).downcase ] =  HTTP.make_utf8! m[2])
			end
			return false unless data[0]
			data.shift while data[0] && data[0].match(/^[\r\n]+$/)
			if @parser_data["transfer-coding"] || (@parser_data["content-length"] && @parser_data["content-length"].to_i != 0) || @parser_data["content-type"]
				@parser_stage = 2
			else					
				# create request object and hand over to handler
				complete_request service
				return parse_message service, data unless data.empty?
			end
			true
		end

		#parses the body of a request.
		def parse_body service, data
			# check for body is needed, if exists and if complete
			if @parser_data["transfer-coding"] == "chunked"
				until data.empty? || data[0].to_s.match(/0(\r)?\n/)
					if @parser_length == 0
						@parser_length = data.to_s.shift.match(/^[a-z0-9A-Z]+/).to_i(16)
						@parser_chunk.clear
					end
					unless @parser_length == 0
						@parser_chunk << data.shift while ( (@parser_length >= @parser_chunk.bytesize) && data[0])
					end
					if @parser_length <= @parser_chunk.bytesize
						@parser_body << @parser_chunk.byteslice(0, @parser_body.bytesize)
						@parser_length = 0
						@parser_chunk.clear
					end
				end
				return false unless data[0].to_s.match(/0(\r)?\n/)
				true until data.empty? || data.shift.match(/^[\r\n]+$/)
				data.shift while data[0].to_s.match /^[\r\n]+$/
			elsif @parser_data["content-length"].to_i
				@parser_length = @parser_data["content-length"].to_i if @parser_length == 0
				@parser_chunk << data.shift while @parser_length > @parser_chunk.bytesize && data[0]
				return false if @parser_length > @parser_chunk.bytesize
				@parser_body = @parser_chunk.byteslice(0, @parser_length)
				@parser_chunk.clear
			else 
				Anorexic.warn 'bad body request - trying to read'
				@parser_body << data.shift while data[0] && !data[0].match(/^[\r\n]+$/)
			end
			# parse body (POST parameters)
			read_body

			# complete request
			complete_request service

			#read next request unless data is finished
			return parse_message service, data unless data.empty?
			true 
		end

		# completes the parsing of the request and sends the request to the handler.
		def complete_request service
			#finalize params and query properties
			m = @parser_data[:query].match /(([a-z0-9A-Z]+):\/\/)?(([^\/\:]+))?(:([0-9]+))?([^\?\#]*)(\?([^\#]*))?/
			@parser_data[:requested_protocol] = m[1] || (service.ssl? ? 'https' : 'http')
			@parser_data[:host_name] = m[4] || (@parser_data['host'] ? @parser_data['host'].match(/^[^:]*/).to_s : nil)
			@parser_data[:port] = m[6] || (@parser_data['host'] ? @parser_data['host'].match(/:([0-9]*)/).to_a[1] : nil)
			@parser_data[:original_path] = HTTP.decode(m[7], :uri) || '/'
			@parser_data['host'] ||= "#{@parser_data[:host_name]}:#{@parser_data[:port]}"
			# parse query for params - m[9] is the data part of the query
			if m[9]
				HTTP.extract_data m[9].split(/[&;]/), @parser_data[:params]
			end

			HTTP.make_utf8! @parser_data[:original_path]
			@parser_data[:path] = @parser_data[:original_path].chomp('/')
			@parser_data[:original_path].freeze

			HTTP.make_utf8! @parser_data[:host_name] if @parser_data[:host_name]
			HTTP.make_utf8! @parser_data[:query]

			@@rack_dictionary.each {|k,v| @parser_data[k] = @parser_data[v]}

			#create request
			request = HTTPRequest.new service
			request.update @parser_data

			#clear current state
			@parser_data.clear
			@parser_body.clear
			@parser_chunk.clear
			@parser_length = 0
			@parser_stage = 0

			#check for server-responses
			case request.request_method
			when "TRACE"
				return true
			when "OPTIONS"
				Anorexic.push_event Proc.new do
					response = HTTPResponse.new request
					response[:Allow] = "GET,HEAD,POST,PUT,DELETE,OPTIONS"
					response["access-control-allow-origin"] = "*"
					response['content-length'] = 0
					response.finish
				end
				return true
			end

			#pass it to the handler or decler error.
			if service.handler
				Anorexic.callback service.handler, :on_request, request
			else
				AN.error "No Handler for this HTTP service."
			end
		end

		# read the body's data and parse any incoming data.
		def read_body
			# parse content
			case @parser_data["content-type"].to_s
			when /x-www-form-urlencoded/
				HTTP.extract_data @parser_body.split(/[&;]/), @parser_data[:params], :uri
			when /multipart\/form-data/
				read_multipart @parser_data, @parser_body
			when /text\/xml/
				# to-do support xml? support json?
				@parser_data[:body] = @parser_body.dup
			when /application\/json/
				@parser_data[:body] = @parser_body.dup
				JSON.parse(HTTP.make_utf8! @parser_data[:body]).each {|k, v| HTTP.add_param_to_hash k, v, @parser_data[:params]}
			else
				@parser_data[:body] = @parser_body.dup
				Anorexic.error "POST body type (#{@parser_data["content-type"]}) cannot be parsed. raw body is kept in the request's data as request[:body]: #{@parser_body}"
			end
		end

		# parse a mime/multipart body or part.
		def read_multipart headers, part, name_prefix = ''
			if headers["content-type"].to_s.match /multipart/
				boundry = headers["content-type"].match(/boundary=([^\s]+)/)[1]
				if headers["content-disposition"].to_s.match /name=/
					if name_prefix.empty?
						name_prefix << HTTP.decode(headers["content-disposition"].to_s.match(/name="([^"]*)"/)[1])
					else
						name_prefix << "[#{HTTP.decode(headers["content-disposition"].to_s.match(/name="([^"]*)"/)[1])}]"
					end
				end
				part.split(/([\r]?\n)?--#{boundry}(--)?[\r]?\n/).each do |p|
					unless p.strip.empty? || p=='--'
						# read headers
						h = {}
						p = p.lines
						while p[0].match(/^[^:]+:[^\r\n]+/) 
							m = p.shift.match(/^([^:]+):[\s]?([^\r\n]+)/)
							h[m[1].downcase] = m[2]
						end
						if p[0].strip.empty?
							p.shift
						else
							Anorexic.error 'Expected empty line after last header - empty line missing.'
						end
						# send headers and body to be read
						read_multipart h, p.join, name_prefix
					end
				end
				return
			end
			# convert part to `charset` if charset is defined?

			if !headers["content-disposition"]
				Anorexic.error "Wrong multipart format with headers: #{headers} and body: #{part}"
				return
			end

			cd = {}

			HTTP.extract_data headers["content-disposition"].match(/[^;];([^\r\n]*)/)[1].split(/[;,][\s]?/), cd, :uri

			name = name_prefix.dup

			if name_prefix.empty?
				name << HTTP.decode(cd[:name][1..-2])
			else
				name << "[#{HTTP.decode(cd[:name][1..-2])}]"
			end
			if headers["content-type"]
				HTTP.add_param_to_hash "#{name}[data]", part, @parser_data[:params]
				HTTP.add_param_to_hash "#{name}[type]", HTTP.make_utf8!(headers["content-type"]), @parser_data[:params]
				cd.each {|k,v|  HTTP.add_param_to_hash "#{name}[#{k.to_s}]", HTTP.make_utf8!(v[1..-2]), @parser_data[:params] unless k == :name}
			else
				HTTP.add_param_to_hash name, HTTP.decode(part, :utf8), @parser_data[:params]
			end
			true
		end
	end
end

## Heroku/extra headers info

# All headers are considered to be case-insensitive, as per HTTP Specification.
# X-Forwarded-For: the originating IP address of the client connecting to the Heroku router
# X-Forwarded-Proto: the originating protocol of the HTTP request (example: https)
# X-Forwarded-Port: the originating port of the HTTP request (example: 443)
# X-Request-Start: unix timestamp (milliseconds) when the request was received by the router
# X-Request-Id: the Heroku HTTP Request ID
# Via: a code name for the Heroku router

