
module Plezi
  module Base
    # this handles Plezi routing
    module Router
      # represents a single route - his is where the heavy lifting is mostly performed
      class Route
  			# the Regexp that will be used to match the request.
  			attr_reader :path
  			# the controller that answers the request on this path (if exists).
  			attr_reader :controller
  			# the proc that answers the request on this path (if exists).
  			attr_reader :proc
  			# the parameters for the router and service that were used to create the service, router and host.
  			attr_reader :params
  			# an array containing the parts of the original url, if any. `false` for Regexp or non relevant routes.
  			attr_reader :url_array

  			# lets the route answer the request. returns false if no response has been sent.
  			def on_request request, response
  				fill_parameters = match request.path
  				return false unless fill_parameters
  				old_params = request.params.dup
          # fill_parameters.each {|k,v| Plezi::Base::Helpers.add_param_to_hash k, ::Plezi::Base::Helpers.form_decode(v), request.params }
          fill_parameters.each {|k,v| ::Rack::Utils.default_query_parser.normalize_params(request.params, ::URI.decode_www_form_component(k), ::URI.decode_www_form_component(v), ::Rack::Utils.default_query_parser.param_depth_limit) }
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
  					@controller = self.class.controller_magic controller
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
  					@url_array = path.gsub(/(^\/)|(\/$)/, ''.freeze).gsub(/([^\\])\//, '\1 - /').split ' - /'
  					@url_array.each.with_index do |section, section_index|
  						if section == '*'.freeze
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
  				m = @path.match path
  				return false unless m
  				@fill_parameters.each { |k, v| hash[v] = m[k][1..-1] if m[k] && m[k] != '/'.freeze }
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
  			def self.controller_magic(controller)
  				new_class_name = "Plezi__#{controller.name.gsub(/[\:\-\#\<\>\{\}\(\)\s]/ , '_'.freeze)}"
  				return Module.const_get new_class_name if Module.const_defined? new_class_name
  				# controller.include Plezi::ControllerMagic
  				controller.instance_exec {|r| include Plezi::ControllerMagic; }
  				ret = Class.new(controller) do
  					include Plezi::Base::ControllerCore
  				end
  				Object.const_set(new_class_name, ret)
  				Module.const_get(new_class_name).reset_routing_cache
  				ret
  			end
  		end
    end
  end
end
