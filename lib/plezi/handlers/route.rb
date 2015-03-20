module Plezi
	#####
	# this class holds the route and matching logic that will normally be used for HTTP handling
	# it is used internally and documentation is present for development and edge users.
	class Route
		# the Regexp that will be used to match the request.
		attr_reader :path
		# the controller that answers the request on this path (if exists).
		attr_reader :controller
		# the proc that answers the request on this path (if exists).
		attr_reader :proc
		# the parameters for the router and service that were used to create the service, router and host.
		attr_reader :params

		# lets the route answer the request. returns false if no response has been sent.
		def on_request request
			fill_parameters = match request.path
			return false unless fill_parameters
			old_params = request.params.dup
			fill_parameters.each {|k,v| HTTP.add_param_to_hash k, v, request.params }
			ret = false
			response = HTTPResponse.new request
			if controller
				ret = controller.new(request, response, params)._route_path_to_methods_and_set_the_response_
			elsif proc
				ret = proc.call(request, response)
				# response << ret if ret.is_a?(String)
			elsif controller == false
				request.path = path.match(request.path).to_a.last.to_s
				return false
			end
			unless ret
				request.params.replace old_params unless fill_parameters.empty?
				return false
			end
			response.try_finish
			return ret
		end

		# handles Rack requests (dresses up as Rack).
		def call request
			fill_parameters = match request.path_info
			return false unless fill_parameters
			fill_parameters.each {|k,v| HTTP.add_param_to_hash k, v, request.params }
			response = HTTPResponse.new request
			if controller
				ret = controller.new(request, response, params)._route_path_to_methods_and_set_the_response_
				return response if ret
			elsif proc
				ret = proc.call(request, response)
				return response if ret
			elsif controller == false
				request.path_info = path.match(request.path_info).to_a.last
			end
			return false
		end

		# the initialize method accepts a Regexp or a String and creates the path object.
		#
		# Regexp paths will be left unchanged
		#
		# a string can be either a simple string `"/users"` or a string with parameters:
		# `"/static/:required/(:optional)/(:optional_with_format){[\d]*}/:optional_2"`
		def initialize path, controller, params={}, &block
			@path_sections , @params = false, params
			initialize_path path
			initialize_controller controller, block
		end

		# initializes the controller,
		# by inheriting the class into an Plezi controller subclass (with the Plezi::ControllerMagic injected).
		#
		# Proc objects are currently passed through without any change - as Proc routes are assumed to handle themselves correctly.
		def initialize_controller controller, block
			@controller, @proc = controller, block
			if controller.is_a?(Class)
				# add controller magic
				@controller = self.class.make_controller_magic controller
			end
		end

		# initializes the path by converting the string into a Regexp
		# and noting any parameters that might need to be extracted for RESTful routes.
		def initialize_path path
			@fill_parameters = {}
			if path.is_a? Regexp
				@path = path
			elsif path.is_a? String
				# prep used prameters
				param_num = 0
				section_search = "([\\/][^\\/]*)"
				optional_section_search = "([\\/][^\\/]*)?"
				@path = '^'

				# prep path string
				# path = path.gsub(/(^\/)|(\/$)/, '')

				# scan for the '/' divider
				# (split path string only when the '/' is not inside a {} regexp)
				# level = 0
				# scn = StringScanner.new(path)
				# while scn.matched != ''
				# 	scn.scan_until /[^\\][\/\{\}]|$/
				# 	case scn.matched
				# 	when '{'
				# 		level += 1
				# 	when '}'
				# 		level -= 1
				# 	when '/'
				# 		split_pos ||= []
				# 		split_pos << scn.pos if level == 0
				# 	end
				# end

				# prep path string and split it where the '/' charected is unescaped.
				path = path.gsub(/(^\/)|(\/$)/, '').gsub(/([^\\])\//, '\1 - /').split ' - /'
				@path_sections = path.length
				path.each.with_index do |section, section_index|
					if section == '*'
						# create catch all
						section_index == 0 ? (@path << "(.*)") : (@path << "(\\/.*)?")
						# finish
						@path = /#{@path}$/
						return

					# check for routes formatted: /:paramater - required parameters
					elsif section.match /^\:([^\(\)\{\}\:]*)$/
						#create a simple section catcher
					 	@path << section_search
					 	# add paramater recognition value
					 	@fill_parameters[param_num += 1] = section.match(/^\:([^\(\)\{\}\:]*)$/)[1]

					# check for routes formatted: /:paramater{regexp} - required parameters
					elsif section.match /^\:([^\(\)\{\}\:\/]*)\{(.*)\}$/
						#create a simple section catcher
					 	@path << (  "(\/(" +  section.match(/^\:([^\(\)\{\}\:\/]*)\{(.*)\}$/)[2] + "))"  )
					 	# add paramater recognition value
					 	@fill_parameters[param_num += 1] = section.match(/^\:([^\(\)\{\}\:\/]*)\{(.*)\}$/)[1]
					 	param_num += 1 # we are using two spaces

					# check for routes formatted: /(:paramater) - optional parameters
					elsif section.match /^\(\:([^\(\)\{\}\:]*)\)$/
						#create a optional section catcher
					 	@path << optional_section_search
					 	# add paramater recognition value
					 	@fill_parameters[param_num += 1] = section.match(/^\(\:([^\(\)\{\}\:]*)\)$/)[1]

					# check for routes formatted: /(:paramater){regexp} - optional parameters
					elsif section.match /^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/
						#create a optional section catcher
					 	@path << (  "(\/(" +  section.match(/^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/)[2] + "))?"  )
					 	# add paramater recognition value
					 	@fill_parameters[param_num += 1] = section.match(/^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/)[1]
					 	param_num += 1 # we are using two spaces

					else
						@path << "\/"
						@path << section
					end
				end
				unless @fill_parameters.values.include?("id")
					@path << optional_section_search
					@fill_parameters[param_num += 1] = "id"
				end
				@path = /#{@path}$/
			else
				raise "Path cannot be initialized - path must be either a string or a regular experssion."
			end	
			return
		end

		# this performs the match and assigns the parameters, if required.
		def match path
			hash = {}
			# m = nil
			# unless @fill_parameters.values.include?("format")
			# 	if (m = path.match /([^\.]*)\.([^\.\/]+)$/)
			# 		HTTP.add_param_to_hash 'format', m[2], hash
			# 		path = m[1]
			# 	end
			# end
			m = @path.match path
			return false unless m
			@fill_parameters.each { |k, v| hash[v] = m[k][1..-1] if m[k] && m[k] != '/' }
			hash
		end

		###########
		## class magic methods

		protected

		# injects some magic to the controller
		#
		# adds the `redirect_to` and `send_data` methods to the controller class, as well as the properties:
		# env:: the env recieved by the Rack server.
		# params:: the request's parameters.
		# cookies:: the request's cookies.
		# flash:: an amazing Hash object that sets temporary cookies for one request only - greate for saving data between redirect calls.
		#
		def self.make_controller_magic(controller)
			new_class_name = "Plezi__#{controller.name.gsub /[\:\-]/, '_'}"
			return Module.const_get new_class_name if Module.const_defined? new_class_name
			# controller.include Plezi::ControllerMagic
			controller.instance_eval { include Plezi::ControllerMagic }
			ret = Class.new(controller) do

				def name
					new_class_name
				end

				def initialize request, response, host_params
					@request, @params, @flash, @host_params = request, request.params, response.flash, host_params
					@response = response
					# @response["content-type"] ||= ::Plezi.default_content_type

					@_accepts_broadcast = false

					# create magical cookies
					@cookies = request.cookies
					@cookies.set_controller self

					super()
				end

				# WebSockets.
				#
				# this method handles the protocol and handler transition between the HTTP connection
				# (with a protocol instance of HTTPProtocol and a handler instance of HTTPRouter)
				# and the WebSockets connection
				# (with a protocol instance of WSProtocol and an instance of the Controller class set as a handler)
				def pre_connect
					# make sure this is a websocket controller
					return false unless self.class.public_instance_methods.include?(:on_message)
					# call the controller's original method, if exists, and check connection.
					return false if (defined?(super) && !super) 
					# finish if the response was sent
					return true if response.headers_sent?
					# complete handshake
					return false unless WSProtocol.new( request.service, request.service.parameters).http_handshake request, response, self
					# set up controller as WebSocket handler
					@response = WSResponse.new request
					# create the redis connection (in case this in the first instance of this class)
					self.class.redis_connection
					# set broadcasts and return true
					@_accepts_broadcast = true
				end


				# WebSockets.
				#
				# stops broadcasts from being called on closed sockets that havn't been collected by the garbage collector.
				def on_disconnect
					@_accepts_broadcast = false
					super if defined? super
				end

				# Inner Routing
				#
				#
				def _route_path_to_methods_and_set_the_response_
					#run :before filter
					return false if self.class.available_routing_methods.include?(:before) && self.before == false 
					#check request is valid and call requested method
					ret = requested_method
					return false unless self.class.available_routing_methods.include?(ret)
					return false unless (ret = self.method(ret).call)
					#run :after filter
					return false if self.class.available_routing_methods.include?(:after) && self.after == false
					# review returned type for adding String to response
					if ret.is_a?(String)
						response << ret
						response['content-length'] = ret.bytesize if response.body.empty? && !response.headers_sent?
					end
					return true
				end
				# a callback that resets the class router whenever a method (a potential route) is added
				def self.method_added(id)
					reset_routing_cache
				end
				# a callback that resets the class router whenever a method (a potential route) is removed
				def self.method_removed(id)
					reset_routing_cache
				end
				# a callback that resets the class router whenever a method (a potential route) is undefined (using #undef_method).
				def self.method_undefined(id)
					reset_routing_cache
				end

				# # lists the available methods that will be exposed to HTTP requests
				# def self.available_public_methods
				# 	# set class global to improve performance while checking for supported methods
				# 	@@___available_public_methods___ ||= available_routing_methods - [:before, :after, :save, :show, :update, :delete, :initialize, :on_message, :pre_connect, :on_connect, :on_disconnect]
				# end

				# # lists the available methods that will be exposed to the HTTP router
				# def self.available_routing_methods
				# 	# set class global to improve performance while checking for supported methods
				# 	@@___available_routing_methods___ ||= (((public_instance_methods - Object.public_instance_methods) - Plezi::ControllerMagic::InstanceMethods.instance_methods).delete_if {|m| m.to_s[0] == '_'})
				# end

				# # resets this controller's router, to allow for dynamic changes
				# def self.reset_routing_cache
				# 	@@___available_routing_methods___ = @@___available_public_methods___ = nil
				# 	available_routing_methods
				# 	available_public_methods
				# end

				
				# # reviews the Redis connection, sets it up if it's missing and returns the Redis connection.
				# #
				# # todo: review thread status? (incase an exception killed it)
				# def self.redis_connection
				# 	return false unless defined?(Redis) && ENV['PL_REDIS_URL']
				# 	return @@redis if defined?(@@redis_sub_thread) && @@redis
				# 	@@redis_uri ||= URI.parse(ENV['PL_REDIS_URL'])
				# 	@@redis ||= Redis.new(host: @@redis_uri.host, port: @@redis_uri.port, password: @@redis_uri.password)
				# 	@@redis_sub_thread = Thread.new do
				# 		begin
				# 			Redis.new(host: @@redis_uri.host, port: @@redis_uri.port, password: @@redis_uri.password).subscribe(redis_channel_name) do |on|
				# 				on.message do |channel, msg|
				# 					args = JSON.parse(msg)
				# 					params = args.shift
				# 					__inner_process_broadcast params['_pl_ignore_object'], params['_pl_method_broadcasted'].to_sym, args
				# 				end
				# 			end						
				# 		rescue Exception => e
				# 			Plezi.error e
				# 			retry
				# 		end
				# 	end
				# 	raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless @@redis
				# 	@@redis
				# end

				# # returns a Redis channel name for this controller.
				# def self.redis_channel_name
				# 	self.name.to_s
				# end

				# # broadcasts messages (methods) for this process
				# def self.__inner_process_broadcast ignore, method_name, args, &block
				# 	ObjectSpace.each_object(self) { |controller| Plezi.callback controller, method_name, *args, &block if controller.accepts_broadcast? && (!ignore || controller.uuid != ignore) }
				# end

				# # broadcasts messages (methods) between all processes (using Redis).
				# def self.__inner_redis_broadcast ignore, method_name, args, &block
				# 	return false unless redis_connection
				# 	raise "Radis broadcasts cannot accept blocks (no inter-process callbacks of memory sharing)!" if block
				# 	# raise "Radis broadcasts accept only one paramater, which is an optional Hash (no inter-process memory sharing)" if args.length > 1 || (args[0] && !args[0].is_a?(Hash))
				# 	args.unshift ({_pl_method_broadcasted: method_name, _pl_ignore_object: ignore})
				# 	redis_connection.publish(redis_channel_name, args.to_json )
				# 	true
				# end

			end
			Object.const_set(new_class_name, ret)
			Module.const_get(new_class_name).reset_routing_cache
			ret
		end

	end

end
