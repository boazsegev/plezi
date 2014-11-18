module Anorexic

	# the methods defined in this module will be injected into the Controller class passed to the MVC
	# and will be available for the controller to use.
	#
	# to do: add HTTP encrypted authentication?
	module ControllerMagic
		module_function

		public

		# the request object, class: HTTPRequest.
		attr_reader :request
		# the ::params variable contains all the paramaters set by the request (/path?locale=he  => params["locale"] == "he").
		attr_reader :params
		# this is a magical hash representing the cookies hash set in the request variables.
		#
		# the magic, you ask?
		#
		# the cookies hash is writable - calling `cookies[:new_cookie_name] = value` will set the cookie in the response object.
		attr_reader :cookies
		# the HTTPResponse object, which sets the response to be sent.
		attr_accessor :response
		# the ::flash is a little bit of a magic hash that sets and reads temporary cookies.
		# these cookies will live for one successful request to a Controller and will then be removed.
		attr_reader :flash

		# this method does two things.
		#
		# 1. sets redirection headers for the response.
		# 2. sets the `flash` object (short-time cookies) with all the values passed except the :status value.
		#
		# use:
		#      redirect_to 'http://google.com', notice: "foo", status: 302
		#      # => redirects to 'http://google.com' with status 302 and adds notice: "foo" to the flash
		# or simply:
		#      redirect_to 'http://google.com'
		#      # => redirects to 'http://google.com' with status 302 (default status)
		#
		def redirect_to url, options = {}
			return super *[] if defined? super
			raise 'Cannot redirect after headers were sent' if response.headers_sent?
			url = "#{request.base_url}/#{url.to_s.gsub('_', '/')}" if url.is_a?(Symbol)
			# redirect
			response.clear
			response.status = options.delete(:status) || 302
			response['Location'] = url
			flash.update options
			true
		end

		# this method adds data to be sent.
		#
		# this is usful for sending 'attachments' (data to be downloaded) rather then
		# a regular response.
		#
		# this is also usful for offering a file name for the browser to "save as".
		#
		# it accepts:
		# data:: the data to be sent
		# options:: a hash of any of the options listed furtheron.
		#
		# the :symbol=>value options are:
		# type:: the type of the data to be sent. defaults to empty. if :filename is supplied, an attempt to guess will be made.
		# inline:: sets the data to be sent an an inline object (to be viewed rather then downloaded). defaults to false.
		# filename:: sets a filename for the browser to "save as". defaults to empty.
		#
		def send_data data, options = {}
			raise 'Cannot use "send_data" after headers were sent' if response.headers_sent?
			# write data to response object
			response << data

			# set headers
			content_disposition = "attachment"

			options[:type] ||= MimeTypeHelper::MIME_DICTIONARY[::File.extname(options[:filename])] if options[:filename]

			if options[:type]
				response["content-type"] = options[:type]
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
			response["content-length"] = data.bytesize rescue true
			response["content-disposition"] = content_disposition
			response.finish
			true
		end

		# returns the initial method called (or about to be called) by the router for the HTTP request.
		#
		# this is can be very useful within the before / after filters:
		#   def before
		#     return false unless "check credentials" && [:save, :update, :delete].include?(requested_method)
		#
		# if the controller responds to a WebSockets request (a controller that defines the `on_message` method),
		# the value returned is invalid and will remain 'stuck' on :pre_connect
		# (which is the last method called before the protocol is switched from HTTP to WebSockets).
		def requested_method
			@@___available_public_methods___ ||= ((self.class.superclass.public_instance_methods - Object.public_instance_methods) - [:before, :after, :save, :show, :update, :delete, :new, :initialize, :on_message, :pre_connect, :on_connect, :on_disconnect])
			request.method = 'DELETE' if params[:_method].to_s.downcase == 'delete'
			return :pre_connect if request['upgrade'] && request['upgrade'].to_s.downcase == 'websocket' &&  request['connection'].to_s.downcase == 'upgrade'
			case request.method
			when 'GET', 'HEAD'
				return :index unless params[:id]
				return params[:id].to_sym if @@___available_public_methods___.include?(params[:id].to_sym) && params[:id].to_s[0] != "_"
				return :show
			when 'POST', 'PUT'
				return params[:id] && params[:id].to_sym if @@___available_public_methods___.include?(params[:id].to_sym) && params[:id].to_s[0] != "_"
				return :save if params[:id].nil? || params[:id] == 'new'
				return :update
			when 'DELETE'
				return params[:id] && params[:id].to_sym if @@___available_public_methods___.include?(params[:id].to_sym) && params[:id].to_s[0] != "_"
				return :delete
			end
			false
		end

		## WebSockets Magic

		# WebSockets.
		#
		# Use this to brodcast an event to all 'sibling' websockets (websockets that have been created using the same Controller class).
		#
		# accepts:
		# method_name:: a Symbol with the method's name that should respond to the broadcast.
		# *args:: any arguments that should be passed to the method.
		#
		# the method will be called asynchrnously for each sibling instance of this Controller class.
		def broadcast method_name, *args, &block
			 ObjectSpace.each_object(self.class) { |controller|
			 	Anorexic.callback controller, method_name, *args, &block if controller.class.superclass.public_instance_methods.include?(method_name) && (controller.object_id != self.object_id)
			 }
		end

		# this method handles the protocol and handler transition between the HTTP connection
		# (with a protocol instance of HTTPProtocol and a handler instance of HTTPRouter)
		# and the WebSockets connection
		# (with a protocol instance of WSProtocol and an instance of the Controller class set as a handler)
		def pre_connect
			# call the controller's original method, if exists.
			# return false if defined? super && super == false
			# complete handshake
			return false unless self.class.public_instance_methods.include?(:on_message)
			return false unless WSProtocol.new( request.service, request.service.parameters).http_handshake request, response, self
			@response = WSResponse.new request
		end


		# # will (probably NOT), in the future, require authentication or, alternatively, return an Array [user_name, password]
		# #
		# #
		# def request_http_auth realm = false, auth = 'Digest'
		# 	return request.service.handler.hosts[request[:host] || :default].send_by_code request, 401, "WWW-Authenticate" => "#{auth}#{realm ? "realm=\"#{realm}\"" : ''}" unless request['authorization']
		# 	request['authorization']
		# end
	end
end
