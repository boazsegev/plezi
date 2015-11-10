module Plezi
	module Base
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
			def on_request request, response
				fill_parameters = match request.path
				return false unless fill_parameters
				old_params = request.params.dup
				fill_parameters.each {|k,v| Plezi::Base::Helpers.add_param_to_hash k, ::Plezi::Base::Helpers.form_decode(v), request.params }
				ret = false
				if controller
					ret = controller.new(request, response)._route_path_to_methods_and_set_the_response_
				elsif proc
					# proc.init(request, response)
					# ret = proc.instance_exec(request, response, &proc)
					ret = proc.call(request, response)
				elsif controller == false
					request.path = path.match(request.path).to_a.last.to_s
					return false
				end
				unless ret
					request.params.replace old_params unless fill_parameters.empty?
					return false
				end
				return ret
			end

			# the initialize method accepts a Regexp or a String and creates the path object.
			#
			# Regexp paths will be left unchanged
			#
			# a string can be either a simple string `"/users"` or a string with parameters:
			# `"/static/:required/(:optional)/(:optional_with_format){[\d]*}/:optional_2"`
			def initialize path, controller, params={}, &block
				@original_path, @url_array, @params = path, false, params
				initialize_path( (controller == false) ? "#{path.chomp('/')}/*" : path )
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
					@controller = self.class.make_controller_magic controller, self
				end
				if @proc.is_a?(Proc)
					# # proc's methods aren't executed since it's binding isn't `self`
					# @proc.instance_exec do
					# 	extend ::Plezi::ControllerMagic::InstanceMethods
					# 	undef :url_for
					# 	undef :full_url_for
					# 	undef :requested_method
					# 	def run request, response
					# 		@request = request
					# 		@params = request.params
					# 		@flash = response.flash
					# 		@host_params = request[:host_settings]
					# 		@response = response
					# 		@cookies = request.cookies
					# 	end
					# end
				end
			end

			# # returns the url for THIS route (i.e. `url_for :index`)
			# #
			# # This will be usually used by the Controller's #url_for method to get the relative part of the url.
			# def url_for dest = :index
			# 	raise NotImplementedError, "#url_for isn't implemented for this router - could this be a Regexp based router?" unless @url_array
			# 	# convert dest.id and dest[:id] to their actual :id value.
			# 	dest = (dest.id rescue false) || (raise TypeError, "Expecting a Symbol, Hash, String, Numeric or an object that answers to obj[:id] or obj.id") unless !dest || dest.is_a?(Symbol) || dest.is_a?(String) || dest.is_a?(Numeric) || dest.is_a?(Hash)
			# 	url = '/'
			# 	case dest
			# 	when false, nil, '', :index
			# 		add = true
			# 		@url_array.each do |sec|
			# 			add = false unless sec[0] != :path
			# 			url << sec[1] if add
			# 			raise NotImplementedError, '#url_for(index) cannot be implementedfor this path.' if !add && sec[0] == :path
			# 			# todo: :multi_path
			# 		end
			# 	when Hash
			# 	when Symbol, String, Numeric
			# 	end
			# end



			# returns the url for THIS route (i.e. `url_for :index`)
			#
			# This will be usually used by the Controller's #url_for method to get the relative part of the url.
			def url_for dest = :index
				raise NotImplementedError, "#url_for isn't implemented for this router - could this be a Regexp based router?" unless @url_array
				case dest
				when :index, nil, false
					dest = {}
				when String
					dest = {id: dest.dup}
				when Numeric, Symbol
					dest = {id: dest}
				when Hash
					dest = dest.dup
					dest.each {|k,v| dest[k] = v.dup if v.is_a? String }
				else
					# convert dest.id and dest[:id] to their actual :id value.
					dest = {id: (dest.id rescue false) || (raise TypeError, "Expecting a Symbol, Hash, String, Numeric or an object that answers to obj[:id] or obj.id") }
				end
				dest.default_proc = Plezi::Base::Helpers::HASH_SYM_PROC

				url = '/'

				@url_array.each do |sec|
					raise NotImplementedError, "#url_for isn't implemented for this router - Regexp multi-path routes are still being worked on... use a named parameter instead (i.e. '/foo/(:multi_route){route1|route2}/bar')" if REGEXP_FORMATTED_PATH === sec

					param_name = (REGEXP_OPTIONAL_PARAMS.match(sec) || REGEXP_FORMATTED_OPTIONAL_PARAMS.match(sec) || REGEXP_REQUIRED_PARAMS.match(sec) || REGEXP_FORMATTED_REQUIRED_PARAMS.match(sec))
					param_name = param_name[1].to_sym if param_name

					if param_name && dest[param_name]
						url << Plezi::Base::Helpers.encode_url(dest.delete(param_name))
						url << '/' 
					elsif !param_name
						url << sec
						url << '/' 
					elsif REGEXP_REQUIRED_PARAMS === sec || REGEXP_OPTIONAL_PARAMS === sec
						url << '/'
					elsif REGEXP_FORMATTED_REQUIRED_PARAMS === sec
						raise ArgumentError, "URL can't be formatted becuse a required parameter (#{param_name.to_s}) isn't specified and it requires a special format (#{REGEXP_FORMATTED_REQUIRED_PARAMS.match(sec)[2]})."
					end
				end
				unless dest.empty?
					add = '?'
					dest.each {|k, v| url << "#{add}#{Plezi::Base::Helpers.encode_url k}=#{Plezi::Base::Helpers.encode_url v}"; add = '&'}
				end
				url

			end


			# Used to check for routes formatted: /:paramater - required parameters
			REGEXP_REQUIRED_PARAMS = /^\:([^\(\)\{\}\:]*)$/
			# Used to check for routes formatted: /(:paramater) - optional parameters
			REGEXP_OPTIONAL_PARAMS = /^\(\:([^\(\)\{\}\:]*)\)$/
			# Used to check for routes formatted: /(:paramater){regexp} - optional formatted parameters
			REGEXP_FORMATTED_OPTIONAL_PARAMS = /^\(\:([^\(\)\{\}\:]*)\)\{(.*)\}$/
			# Used to check for routes formatted: /:paramater{regexp} - required parameters
			REGEXP_FORMATTED_REQUIRED_PARAMS = /^\:([^\(\)\{\}\:\/]*)\{(.*)\}$/
			# Used to check for routes formatted: /{regexp} - required path
			REGEXP_FORMATTED_PATH = /^\{(.*)\}$/

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
					@url_array = []

					# prep path string and split it where the '/' charected is unescaped.
					@url_array = path.gsub(/(^\/)|(\/$)/, '').gsub(/([^\\])\//, '\1 - /').split ' - /'
					@url_array.each.with_index do |section, section_index|
						if section == '*'
							# create catch all
							section_index == 0 ? (@path << "(.*)") : (@path << "(\\/.*)?")
							# finish
							@path = /#{@path}$/
							return

						# check for routes formatted: /:paramater - required parameters
						elsif section.match REGEXP_REQUIRED_PARAMS
							#create a simple section catcher
						 	@path << section_search
						 	# add paramater recognition value
						 	@fill_parameters[param_num += 1] = section.match(REGEXP_REQUIRED_PARAMS)[1]

						# check for routes formatted: /(:paramater) - optional parameters
						elsif section.match REGEXP_OPTIONAL_PARAMS
							#create a optional section catcher
						 	@path << optional_section_search
						 	# add paramater recognition value
					 		@fill_parameters[param_num += 1] = section.match(REGEXP_OPTIONAL_PARAMS)[1]

						# check for routes formatted: /(:paramater){regexp} - optional parameters
						elsif section.match REGEXP_FORMATTED_OPTIONAL_PARAMS
							#create a optional section catcher
						 	@path << (  "(\/(" +  section.match(REGEXP_FORMATTED_OPTIONAL_PARAMS)[2] + "))?"  )
						 	# add paramater recognition value
						 	@fill_parameters[param_num += 1] = section.match(REGEXP_FORMATTED_OPTIONAL_PARAMS)[1]
						 	param_num += 1 # we are using two spaces - param_num += should look for () in regex ? /[^\\](/

						# check for routes formatted: /:paramater{regexp} - required parameters
						elsif section.match REGEXP_FORMATTED_REQUIRED_PARAMS
							#create a simple section catcher
						 	@path << (  "(\/(" +  section.match(REGEXP_FORMATTED_REQUIRED_PARAMS)[2] + "))"  )
						 	# add paramater recognition value
						 	@fill_parameters[param_num += 1] = section.match(REGEXP_FORMATTED_REQUIRED_PARAMS)[1]
						 	param_num += 1 # we are using two spaces - param_num += should look for () in regex ? /[^\\](/

						# check for routes formatted: /{regexp} - formated path
						elsif section.match REGEXP_FORMATTED_PATH
							#create a simple section catcher
						 	@path << (  "\/(" +  section.match(REGEXP_FORMATTED_PATH)[1] + ")"  )
						 	# add paramater recognition value
						 	param_num += 1 # we are using one space - param_num += should look for () in regex ? /[^\\](/
						else
							@path << "\/"
							@path << section
						end
					end
					unless @fill_parameters.values.include?("id")
						@path << optional_section_search
						@fill_parameters[param_num += 1] = "id"
						@url_array << '(:id)'
					end
					# set the Regexp and return the final result.
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
				# 		Plezi::Base::Helpers.add_param_to_hash 'format', m[2], hash
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
			def self.make_controller_magic(controller, container)
				new_class_name = "Plezi__#{controller.name.gsub /[\:\-\#\<\>\{\}\(\)\s]/, '_'}"
				return Module.const_get new_class_name if Module.const_defined? new_class_name
				# controller.include Plezi::ControllerMagic
				controller.instance_exec(container) {|r| include Plezi::ControllerMagic; }
				ret = Class.new(controller) do
					include Plezi::Base::ControllerCore
				end
				Object.const_set(new_class_name, ret)
				Module.const_get(new_class_name).reset_routing_cache
				ret.instance_exec(container) {|r| set_pl_route r;}
				ret
			end

		end
	end

end
