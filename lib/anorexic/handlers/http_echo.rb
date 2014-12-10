module Anorexic
	#####
	# this is a Handler stub class for an HTTP echo server.
	module HTTPEcho
		module_function

		# handles requests by printing out the parsed data. gets the `request` parameter from the HTTP protocol.
		def on_request request
			response = HTTPResponse.new request, 200, {"content-type" => "text/plain"}, ["parsed as:\r\n", request.to_s]
			response.body.last << "\n\n params:"
			request.params.each {|k,v| response.body.last << "\n#{k}: #{v}"}
			response.send
			response.finish
		end

		# does nothing - a simple stub as required from handlers
		def add_route *args
			self
		end

		# does nothing - a simple stub as required from handlers
		def add_host *args
			self
		end
	end

end
