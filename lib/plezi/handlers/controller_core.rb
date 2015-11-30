module Plezi
	module Base

		# the methods defined in this module will be injected into the Controller's Core class (inherited from the controller).
		module ControllerCore
			def self.included base
				base.send :include, Plezi::Base::WSObject
				base.send :include, InstanceMethods
				base.extend ClassMethods
			end

			module InstanceMethods
				public

				def initialize request, response
					@request = request
					@params = request.params
					@flash = response.flash
					@host_params = request[:host_settings]
					@response = response
					@cookies = request.cookies
					# # \@response["content-type"] ||= ::Plezi.default_content_type
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
					return false unless self.class.has_super_method?(:on_message) || self.class.superclass.instance_variable_get(:@auto_dispatch)
					# call the controller's original method, if exists, and check connection.
					return false if (defined?(super) && !super)
					# finish if the response was sent
					return false if response.headers_sent?
					# make sure that the session object is available for websocket connections
					session
					# make sure that rendering uses JSON for websocket messages (unless already set)
					params[:format] ||= 'json'
					# complete handshake
					return self
				end

				# Websockets
				#
				# this method either forwards the on_message handling to the `on_message` callback, OR
				# auto-dispatches the messages by translating the JSON into a method call using the `event` keyword.
				def on_message data
					unless self.class.superclass.instance_variable_get(:@auto_dispatch)
						return super if defined? super
						return false
					end
					begin
						data = JSON.parse data
					rescue
						return close
					end
					Plezi::Base::Helpers.make_hash_accept_symbols data
					unless self.class.has_super_method?(data['event'.freeze] = data['event'.freeze].to_s.to_sym)
						return (self.class.has_super_method?(:unknown_event) && ( unknown_event(data) || true)) || write({ event: :err, status: 404, result: "not found", request: data }.to_json)
					end
					ret = self.__send__(data['event'.freeze], data)
					write(ret) if ret.is_a?(String)
				end 

				# Inner Routing
				def _route_path_to_methods_and_set_the_response_
					#run :before filter
					return false if self.class.has_method?(:before) && self.before == false 
					#check request is valid and call requested method
					ret = requested_method
					return false unless ret
					ret = self.__send__(ret)
					return false unless ret
					#run :after filter
					return false if self.class.has_method?(:after) && self.after == false
					# review returned type for adding String to response
					return ret
				end

			end

			module ClassMethods
			end
		end
	end
end
