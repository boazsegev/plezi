module Anorexic

	# the methods defined in this module will be injected into the Controller class passed to the MVC
	# and will be available for the controller to use.
	#
	module ControllerMagic
		module_function

		public

		# the ::env variable is the env passed over from the Raack server and contains lot's of almost parsed info.
		attr_reader :env
		# the request object, class: Rack::Request.
		attr_reader :request
		# the ::params variable contains all the paramaters set by the request (/path?locale=he  => params["locale"] == "he").
		#
		# there's a bit of magic access there - the params can be accessed using symbols as well as strings: params[:id] == params["id"]
		attr_reader :params
		# this is a magical hash representing the cookies hash set in the request variables
		#
		# the magic, you ask?
		#
		# the cookies hash is writable - calling `cookies[:new_cookie_name] = value` will set the cookie in the current response object.
		attr_reader :cookies
		# a Rack::Response object, which sets the response to be sent.
		attr_accessor :response
		# the ::flash is a little bit of a magic hash that sets and reads temporary cookies.
		# these cookies will live for one successful request to a Controller and will then be removed.
		attr_reader :flash

		def redirect_to url, options = {}
			return super *[] if defined? super
			url = "#{request.base_url}/#{url.to_s.gsub('_', '/')}" if url.is_a?(Symbol)
			if options[:status]
				response.redirect url, options[:status]
				options.delete :status
			else
				response.redirect url
			end
			@flash.update options
		end

		def send_data data, options = {}
			# write data to response object
			response.write data

			# set headers
			content_disposition = "attachment"
			if options[:type]
				response["Content-Type"] = 'application/pdf'
				options.delete :type
			end
			if options[:inline]
				content_disposition = "inline"
				options.delete :inline
			end
			if options[:attachment]
				options.delete :attachment
			end
			if options[:filename]
				content_disposition << "; filename=#{options[:filename]}"
				options.delete :filename
			end
			response["Content-Disposition"] = content_disposition
		end

	end

end
