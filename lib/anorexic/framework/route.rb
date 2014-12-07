module Anorexic
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
			fill_paramaters = match request.path
			return false unless fill_paramaters
			fill_paramaters.each {|k,v| HTTP.add_param_to_hash k, v, request.params }
			response = HTTPResponse.new request
			if controller
				ret = controller.new(request, response, params)._route_path_to_methods_and_set_the_response_
				response.try_finish if ret
				return ret
			elsif proc
				ret = proc.call(request, response)
				response.try_finish if ret
				return ret
			elsif controller == false
				request.path = path.match(request.path).to_a.last
			end
			return false
		end

		# handles Rack requests (dresses up as Rack).
		def call request
			fill_paramaters = match request.path_info
			return false unless fill_paramaters
			fill_paramaters.each {|k,v| HTTP.add_param_to_hash k, v, request.params }
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
		# a string can be either a simple string `"/users"` or a string with paramaters:
		# `"/static/:required/(:optional)/(:optional_with_format){[\d]*}/:optional_2"`
		def initialize path, controller, params={}, &block
			@path_sections , @params = false, params
			initialize_path path
			initialize_controller controller, block
		end

		# initializes the controller,
		# by inheriting the class into an Anorexic controller subclass (with the Anorexic::ControllerMagic injected).
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
			@fill_paramaters = {}
			if path.is_a? Regexp
				@path = path
			elsif path.is_a? String
				if path == '*'
					@path = /.*/
				else
					param_num = 0
					section_search = "([\\/][^\\/]*)"
					optional_section_search = "([\\/][^\\/]*)?"
					@path = '^'
					path = path.gsub(/(^\/)|(\/$)/, '').split /[\/\.]/
					@path_sections = path.length
					path.each do |section|
						if section == '*'
							# create catch all
							@path << "(.*)"
							# finish
							@path = /#{@path}$/
							return

						# check for routes formatted: /:paramater - required paramaters
						elsif section.match /^\:([^\(\)\{\}\:]*)$/
							#create a simple section catcher
						 	@path << section_search
						 	# add paramater recognition value
						 	@fill_paramaters[param_num += 1] = section.match(/^\:([^\(\)\{\}\:]*)$/)[1]


						# check for routes formatted: /(:paramater) - optional paramaters
						elsif section.match /^\(\:([^\(\)\{\}\:]*)\)$/
							#create a optional section catcher
						 	@path << optional_section_search
						 	# add paramater recognition value
						 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([^\(\)\{\}\:]*)\)$/)[1]

						# check for routes formatted: /(:paramater){options} - optional paramaters
						elsif section.match /^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/
							#create a optional section catcher
						 	@path << (  "(\/(" +  section.match(/^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/)[2] + "))?"  )
						 	# add paramater recognition value
						 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/)[1]
						 	param_num += 1 # we are using two spaces

						else
							@path << "\/"
							@path << section
						end
					end
					unless @fill_paramaters.values.include?("id")
						@path << optional_section_search
						@fill_paramaters[param_num += 1] = "id"
					end
					@path = /#{@path}$/
				end
			else
				raise "Path cannot be initialized - path must be either a string or a regular experssion."
			end	
			return
		end

		# this performs the match and assigns the paramaters, if required.
		def match path
			hash = {}
			m = nil
			# unless @fill_paramaters.values.include?("format")
			# 	if (m = path.match /([^\.]*)\.([^\.\/]+)$/)
			# 		HTTP.add_param_to_hash 'format', m[2], hash
			# 		path = m[1]
			# 	end
			# end
			m = @path.match path
			return false unless m
			@fill_paramaters.each { |k, v| hash[v] = m[k][1..-1] if m[k] && m[k] != '/' }
			hash
		end

		###########
		## class magic methods

		protected

		# injects some magic to the controller
		#
		# adds the `redirect_to` and `send_data` methods to the controller class, as well as the properties:
		# env:: the env recieved by the Rack server.
		# params:: the request's paramaters.
		# cookies:: the request's cookies.
		# flash:: an amazing Hash object that sets temporary cookies for one request only - greate for saving data between redirect calls.
		#
		def self.make_controller_magic(controller)
			new_class_name = "Anorexic_#{controller.name.gsub /[\:\-]/, '_'}"
			return Module.const_get new_class_name if Module.const_defined? new_class_name
			controller.include Anorexic::ControllerMagic
			ret = Class.new(controller) do

				def initialize request, response, host_params
					@request, @params, @flash, @host_params = request, request.params, response.flash, host_params
					@response = response
					# @response["content-type"] ||= ::Anorexic.default_content_type

					@_accepts_broadcast = false

					# create magical cookies
					@cookies = request.cookies
					@cookies.set_controller self
					super()
				end

				def _route_path_to_methods_and_set_the_response_
					return false unless before rescue false
					ret = false
					begin
						ret = self.method(requested_method).call
					rescue NameError => e
						raise if self.methods.include? requested_method
					end
					unless ret
						return false
					end
					return false unless after rescue false
					if ret.is_a?(String)
						response['content-length'] = ret.bytesize if response.body.empty? && !response.headers_sent?
						response << ret
					end
					return true
				end
			end
			Object.const_set(new_class_name, ret)
			ret
		end

	end

end
