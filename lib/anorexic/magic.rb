module Anorexic

	# the methods defined in this module will be injected into the Controller class passed to the MVC
	# and will be available for the controller to use.
	#
	module ControllerMagic
		module_function

		public

		attr_reader :env, :params, :request, :cookies, :flash
		attr_accessor :response

		def redirect_to url, options = {}
			return super *[] if defined? super
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
