module Plezi
	module Base

		# the methods defined in this module will be injected into the Controller's Core class (inherited from the controller).
		module ControllerCore
			def self.included base
				base.send :include, InstanceMethods
				base.extend ClassMethods
			end

			module InstanceMethods
				public

				def initialize request, response
					@request = request
					@params = request.params
					@flash = response.flash
					@host_params = request.io[:params]
					@response = response
					@cookies = request.cookies
					# @response["content-type"] ||= ::Plezi.default_content_type
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
					return false unless self.class.superclass.available_routing_methods.include?(:on_message)
					# call the controller's original method, if exists, and check connection.
					return false if (defined?(super) && !super)
					# finish if the response was sent
					return false if response.headers_sent?
					# complete handshake
					return self
				end
				# handles websocket opening.
				def on_open ws
					# set broadcasts and return true
					@response = ws
					ws.autopong Plezi.autoping
					# create the redis connection (in case this in the first instance of this class)
					self.class.redis_connection
					super() if defined?(super)
				end
				# handles websocket messages.
				def on_message ws
					super(ws.data) if defined?(super)
				end
				# handles websocket being closed.
				def on_close ws
					super() if defined? super
				end
				# handles websocket being closed.
				def on_broadcast ws
					data = ws.data
					unless (data[:type] || data[:target]) && data[:method] && data[:data]
						GReactor.warn "Broadcast message unknown... falling back on base broadcasting"
						return super(data) if defined? super
						return false
					end
					return false if data[:type] && !self.is_a?(data[:type])
					return false unless self.class.has_method?(data[:method])
					self.method(data[:method]).call *data[:data]
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
					ret = self.method(ret).call
					return false unless ret
					#run :after filter
					return false if self.class.available_routing_methods.include?(:after) && self.after == false
					# review returned type for adding String to response
					return ret
				end

			end

			module ClassMethods
				public

				# a callback that resets the class router whenever a method (a potential route) is added
				def method_added(id)
					self.superclass.reset_routing_cache
					reset_routing_cache
				end
				# a callback that resets the class router whenever a method (a potential route) is removed
				def method_removed(id)
					self.superclass.reset_routing_cache
					reset_routing_cache
				end
				# a callback that resets the class router whenever a method (a potential route) is undefined (using #undef_method).
				def method_undefined(id)
					self.superclass.reset_routing_cache
					reset_routing_cache
				end

				def has_method? method_name
					@methods_list ||= self.instance_methods
					@methods_list.include? method_name
				end
				def has_super_method? method_name
					@super_methods_list ||= self.superclass.instance_methods
					@super_methods_list.include? method_name
				end

			end
		end
	end
end
