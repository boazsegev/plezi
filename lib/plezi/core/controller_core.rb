
module Plezi
  module Base
    # This module will be mixed-in to the class which inherits the original
    # Controller class.
    module ControllerCore
			# @!parse include InstanceMethods
			# @!parse extend ClassMethods

			def self.included base
				base.send :include, InstanceMethods
				base.extend ClassMethods
			end

			module InstanceMethods
				public

				def initialize request, response
					@request = request
          @response = response
					@params = request.params
					@flash = request['plezi.flash'.freeze]
					@host_params = request['plezi.host_settings'.freeze]
					@cookies = request['plezi.cookie_jar'.freeze]
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
					# make sure that the session object is available for websocket connections
					# session
					# make sure that rendering uses JSON for websocket messages (unless already set)
					params['format'] ||= 'json'
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
						return close unless data.is_a?(Hash)
					rescue
						return close
					end
					Plezi::Base::Helpers.make_hash_accept_symbols data
					ret = nil
					begin
						if data['_EID_'.freeze]
							write "{\"event\":\"_ack_\",\"_EID_\":#{data['_EID_'.freeze]}}"
						end
						if self.class.has_auto_dispatch_method?(data['event'.freeze] = data['event'.freeze].to_s.to_sym)
							ret = self.__send__(data['event'.freeze], data)
						else
							ret = (self.class.has_super_method?(:unknown) && ( unknown(data) || true)) || (self.class.has_super_method?(:unknown_event) && ::Plezi.warn('Auto-Dispatch API updated: use `unknown` instead of `unknown_event`') && ( unknown_event(data) || true)) || ({ event: :err, status: 404, result: "not found", request: data }.to_json)
						end
					rescue ArgumentError => e
						::Plezi.error "Auto-Dispatch Error for event :#{data['event'.freeze]} - #{e.message}"
					end
					ret = ret.to_json if ret.is_a?(Hash)
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

        def has_super_method? method_name
          (@super_methods_list ||= self.superclass.instance_methods.to_set).include? method_name
        end

			end


    end
  end
end
