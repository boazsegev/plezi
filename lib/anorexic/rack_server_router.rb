module Anorexic

	module AnoRack

		# the router - this is the actual application object for the RackServer
		class Router
			attr_accessor :routes
			def initialize
				@routes = []
			end
			def call env
				# set response object
				response = Rack::Response.new
				# set request object
				request = Rack::Request.new(env)
				# allow lookup of params as keys run:
				self.class.make_hash_accept_symbols hash: request.params
				self.class.make_hash_accept_symbols hash: request.cookies
				# set magic cookies
				class << request.cookies
					def set_controller controller
						@controller = controller
					end
					def []= key, val
						if @controller
							if val
								@controller.response.set_cookie key, val
							else
								@controller.response.delete_cookie key
							end
						end
						super
					end
				end

				return_value = false
				# compare routes
				request.path_info.chomp!('/')
				@routes.each do |route|
					match = route[0].match request.path_info
					next unless match
					request.params.update match
					if route[1].is_a? Class
						break if return_value = route[1].new(env, request, response)._route_path_to_methods_and_set_the_response_
					elsif route[1].public_methods.include? :call
						if return_value = route[1].call(request, response)
							return_value = response.finish
							break 
						end
					elsif route[1] == false
						match.each {|k,v| request.path_info.gsub!( /\/#{Regexp.quote v}(\/|$)/, "/"); request.path_info.to_s.chomp!('/')}
					end
				end
				return_value
			end
			# adds a route to the router - used by the Anorexic framework.
			def add_route path = "", controller = nil, &block
				unless (controller && (controller.is_a?( Class ) || controller.is_a?( Proc ) ) ) || block || (controller == false)
					raise "Counldn't add an empty route! Routes must have either a Controller class or a block statement!"
				end
				if controller.is_a?(Class)
					# add controller magic
					controller = self.class.make_magic controller
				end
				@routes << [Route.new(path), block || controller]
			end

			# tweeks the params and cookie's hash object to accept :symbols in addition to strings (similar to Rails but without ActiveSupport).
			def self.make_hash_accept_symbols hash
				df_proc = Proc.new do |hs,k|
					if k.is_a?(Symbol) && hs.has_key?( k.to_s)
						hs[k.to_s]
					elsif k.is_a?(String) && hs.has_key?( k.to_sym)
						hs[k.to_sym]
					end
				end
				hash.values.each do |v|
					if v.is_a?(Hash)
						v.default_proc = df_proc
						make_hash_accept_symbols v
					end
				end
			end

			# injects some magic to the controller
			#
			# adds the `redirect_to` and `send_data` methods to the controller class, as well as the properties:
			# env:: the env recieved by the Rack server.
			# params:: the request's paramaters.
			# cookies:: the request's cookies.
			# flash:: an amazing Hash object that sets temporary cookies for one request only - greate for saving data between redirect calls.
			#
			def self.make_magic(controller)
				new_class_name = "AnorexicMegicRuntimeController_#{controller.name.gsub /[\:\-]/, '_'}"
				return Module.const_get new_class_name if Module.const_defined? new_class_name
				ret = Class.new(controller) do
					include Anorexic::ControllerMagic

					def initialize env, request, response
						@env, @request, @params = env, request, request.params
						@response = response
						# @response["Content-Type"] ||= ::Anorexic.default_content_type

						# create magical cookies
						@cookies = request.cookies
						@cookies.set_controller self

						# propegate flash object
						@flash = Hash.new do |hs,k|
							hs["anorexic_flash_#{k}"] if hs.has_key? "anorexic_flash_#{k}"
						end
						cookies.each do |k,v|
							@flash[k] = v if k.start_with? "anorexic_flash_"
						end
						super *[]
					end

					def after
						# remove old flash
						if defined?(super)
							ret = super
							return false if ret == false
						end
						ret ||= true

						cookies.keys.each do |k|
							if k.to_s.start_with? "anorexic_flash_"
								response.delete_cookie k
								flash.delete k
							end
						end
						#set new flash cookies
						@flash.each do |k,v|
							response.set_cookie "anorexic_flash_#{k.to_s}", v
						end
						ret
					end

					def _route_path_to_methods_and_set_the_response_
						available_methods = self.methods
						available_public_methods = (self.class.superclass.public_instance_methods - Object.public_instance_methods) - [:before, :after, :save, :show, :update, :delete, :initialize]
						return false if available_methods.include?(:before) && before == false
						got_from_action = false
						if params && params["id"]
							if (request.delete? || params["_method"].to_s.upcase == 'DELETE') && available_methods.include?(:delete) && !available_public_methods.include?(params["id"].to_sym)
								got_from_action = delete
							elsif request.get?
								if params["id"].to_s[0] != "_" && available_public_methods.include?(params["id"].to_sym)
									got_from_action = self.send params["id"].to_sym
								elsif available_methods.include?(:show)
									got_from_action = show
								end
							elsif (request.put? || request.post? ) && available_methods.include?(:update)
								got_from_action = update
							end
						else
							if request.get? && available_methods.include?(:index)
								got_from_action = index
							elsif (request.put? || request.post?) && available_methods.include?(:save)
								got_from_action = save
							end
						end
						unless got_from_action
							return false
						end
						return false if (available_methods.include?(:after) && after == false)
						response.write got_from_action if got_from_action != true
						response.finish
					end
				end
				Object.const_set(new_class_name, ret)
				ret
			end
		end

		#####
		# this class holds the actual route
		class Route
			attr_accessor :path
			def initialize path
				@fill_paramaters = {}
				if path.is_a? Regexp
					@path = path
				elsif path.is_a? String
					if path == '*'
						@path = /.*/
					else
						param_num = 0
						section_search = "(\/[^\/]*)"
						optional_section_search = "(\/[^\/]*)?"
						@path = '^'
						path = path.gsub(/(^\/)|(\/$)/, '').split '/'
						path.each do |section|
							if section == '*'
								# create catch all
								@path << ".*"
								# finish
								@path = /#{@path}$/
								return

							# check for routes formatted: /:paramater - required paramaters
							elsif section.match /^\:([\w]*)$/
								#create a simple section catcher
							 	@path << section_search
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\:([\w]*)$/)[1]


							# check for routes formatted: /(:paramater) - optional paramaters
							elsif section.match /^\(\:([\w]*)\)$/
								#create a optional section catcher
							 	@path << optional_section_search
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([\w]*)\)$/)[1]

							# check for routes formatted: /(:paramater){options} - optional paramaters
							elsif section.match /^\(\:([\w]*)\)\{([^\/\{\}]*)}$/
								#create a optional section catcher
							 	@path << (  "(\/(" +  section.match(/^\(\:([\w]*)\)\{([^\/\{\}]*)}$/)[2] + "))?"  )
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([\w]*)\)\{([^\/\{\}]*)}$/)[1]
							 	param_num += 1 # we are using to spaces

							else
								@path << "\/"
								@path << section
							end
						end
						if @fill_paramaters.empty?
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
			def match path
				m = @path.match path
				return false unless m
				hash = {}
				@fill_paramaters.each { |k, v|  hash[v] = m[k][1..-1] if m[k] && m[k] != '/' }
				hash
			end
		end
	end
end
