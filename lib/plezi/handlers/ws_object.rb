module Plezi

	module Base

		# This module includes all the methods that will be injected into Websocket objects,
		# specifically into Plezi Controllers and Placebo objects.
		#
		# the methods defined in this module will be injected into the Controller class passed to
		# Plezi (using the `route` or `shared_route` commands), and will be available
		# for the controller to use within it's methods.
		#
		# for some reason, the documentation ignores the following additional attributes, which are listed here:
		#
		# request:: the HTTPRequest object containing all the data from the HTTP request. If a WebSocket connection was established, the `request` object will continue to contain the HTTP request establishing the connection (cookies, parameters sent and other information).
		# params:: any parameters sent with the request (short-cut for `request.params`), will contain any GET or POST form data sent (including file upload and JSON format support).
		# cookies:: a cookie-jar to get and set cookies (set: `cookie\[:name] = data` or get: `cookie\[:name]`). Cookies and some other data must be set BEFORE the response's headers are sent.
		# flash:: a temporary cookie-jar, good for one request. this is a short-cut for the `response.flash` which handles this magical cookie style.
		# response:: the HTTPResponse **OR** the WSResponse object that formats the response and sends it. use `response << data`. This object can be used to send partial data (such as headers, or partial html content) in blocking mode as well as sending data in the default non-blocking mode.
		# host_params:: a copy of the parameters used to create the host and service which accepted the request and created this instance of the controller class.
		#
		module WSObject
			def self.included base
				base.send :include, InstanceMethods
				base.extend ClassMethods
				base.superclass.instance_eval {extend SuperClassMethods}
				base.superclass.instance_eval {include SuperInstanceMethods}
			end

			def self.translate_message msg
				begin
					@safe_types ||= [Symbol, Date, Time, Encoding, Struct, Regexp, Range, Set]
					YAML.safe_load(msg, @safe_types)
				rescue => e
					Iodine.error "The following could be a security breach attempt:"
					Iodine.error e
					nil
				end
			end
			def self.forward_message data
				begin
					return false if data[:server] == Plezi::Settings.uuid
					data[:type] = Object.const_get(data[:type]) unless data[:type].nil? || data[:type] == :all
					if data[:target]
						data[:type].___faild_unicast( data ) unless Iodine::Http::Websockets.unicast data[:target], data
					else
						Iodine::Http::Websockets.broadcast data
					end
				rescue => e
					Iodine.error "The following could be a security breach attempt:"
					Iodine.error e
					nil
				end
			end

			module InstanceMethods
				public

				# handles websocket opening.
				def on_open
					@ws_io = @request[:io]
					super() if defined?(super)
				end
				# handles websocket messages.
				def on_message data
					super if defined?(super)
				end
				# handles websocket being closed.
				def on_close
					super if defined? super
				end

				# handles broadcasts / unicasts
				def on_broadcast data
					unless data.is_a?(Hash) && (data[:type] || data[:target]) && data[:method] && data[:data]
						Iodine.warn "Broadcast message unknown... falling back on base broadcasting"
						return super(data) if defined? super
						return false
					end
					return false if data[:type] && data[:type] != :all && !self.is_a?(data[:type])
					# return ( self.class.placebo? ? true : we.write(ws.data)) if :method == :to_client
					return ((data[:type] == :all) ? false : (raise "Broadcasting recieved but no method can handle it - dump:\r\n #{data.to_s}") ) unless self.class.has_super_method?(data[:method])
					self.method(data[:method]).call(*data[:data])
				end

				# Get's the websocket's unique identifier for unicast transmissions.
				#
				# This UUID is also used to make sure Radis broadcasts don't triger the
				# boadcasting object's event.
				def uuid
					return @uuid if @uuid
					if __get_io
						return (@uuid ||=  Plezi::Settings.uuid + @io.id)
					end
					nil
				end
				alias :unicast_id :uuid

				protected

				# allows writing of data to the websocket (if opened). Otherwise appends the message to the Http response.
				def write data
					(@ws_io || @response) << data
				end

				# Performs a websocket unicast to the specified target.
				def unicast target_uuid, method_name, *args
					self.class.unicast target_uuid, method_name, *args
				end

				# Use this to brodcast an event to all 'sibling' objects (websockets that have been created using the same Controller class).
				#
				# Accepts:
				# method_name:: a Symbol with the method's name that should respond to the broadcast.
				# args*:: The method's argumenst - It MUST be possible to stringify the arguments into a YAML string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
				#
				# The method will be called asynchrnously for each sibling instance of this Controller class.
				#
				def broadcast method_name, *args
					return false unless self.class.has_method? method_name
					self.class._inner_broadcast({ method: method_name, data: args, type: self.class}, __get_io )
				end
				# Use this to multicast an event to ALL websocket connections on EVERY controller, including Placebo controllers.
				#
				# Accepts:
				# method_name:: a Symbol with the method's name that should respond to the broadcast.
				# args*:: The method's argumenst - It MUST be possible to stringify the arguments into a YAML string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
				#
				# The method will be called asynchrnously for ALL websocket connections.
				#
				def multicast method_name, *args
					self.class._inner_broadcast({ method: method_name, data: args, type: :all}, __get_io )
				end

				def __get_io
					@io ||= (@request ? @request[:io] : nil)
				end
			end
			module ClassMethods

				def reset_routing_cache
					@methods_list = nil
					@exposed_methods_list = nil
					@super_methods_list = nil
					has_method? nil
					has_exposed_method? nil
					has_super_method? nil
				end
				def has_method? method_name
					@methods_list ||= self.instance_methods.to_set
					@methods_list.include? method_name
				end
				def has_super_method? method_name
					@super_methods_list ||= self.superclass.instance_methods.to_set
					@super_methods_list.include? method_name
				end
				def has_exposed_method? method_name
					@reserved_methods_list ||= Class.new.public_instance_methods +
						Plezi::Base::WSObject::InstanceMethods.public_instance_methods +
						Plezi::Base::WSObject::SuperInstanceMethods.public_instance_methods +
						Plezi::ControllerMagic::InstanceMethods.public_instance_methods +
						Plezi::Base::ControllerCore::InstanceMethods.public_instance_methods +
						[:before, :after, :save, :show, :update, :delete, :initialize]
					@exposed_methods_list ||= ( (self.public_instance_methods - @reserved_methods_list ).delete_if {|m| m.to_s[0] == '_'} ).to_set
					@exposed_methods_list.include? method_name
				end

				protected

				# a callback that resets the class router whenever a method (a potential route) is added
				def method_added(id)
					reset_routing_cache
				end
				# a callback that resets the class router whenever a method (a potential route) is removed
				def method_removed(id)
					reset_routing_cache
				end
				# a callback that resets the class router whenever a method (a potential route) is undefined (using #undef_method).
				def method_undefined(id)
					reset_routing_cache
				end

			end
			module SuperInstanceMethods
			end

			module SuperClassMethods
				public

				# answers the question if this is a placebo object.
				def placebo?; false end

				# WebSockets: fires an event on all of this controller's active websocket connections.
				#
				# Class method.
				#
				# Use this to brodcast an event to all connections.
				#
				# accepts:
				# method_name:: a Symbol with the method's name that should respond to the broadcast.
				# *args:: any arguments that should be passed to the method (IF REDIS IS USED, LIMITATIONS APPLY).
				#
				# this method accepts and optional block (NON-REDIS ONLY) to be used as a callback for each sibling's event.
				#
				# the method will be called asynchrnously for each sibling instance of this Controller class.
				def broadcast method_name, *args
					return false unless has_method? method_name
					_inner_broadcast method: method_name, data: args, type: self
				end

				# WebSockets: fires an event on a specific websocket connection using it's UUID.
				#
				# Use this to unidcast an event to specific websocket connection using it's UUID.
				#
				# accepts:
				# target_uuid:: the target's unique UUID.
				# method_name:: a Symbol with the method's name that should respond to the broadcast.
				# *args:: any arguments that should be passed to the method (IF REDIS IS USED, LIMITATIONS APPLY).
				def unicast target_uuid, method_name, *args
					raise 'No target specified for unicasting!' unless target_uuid
					@@uuid_cutoff ||= Plezi::Settings.uuid.length
					_inner_broadcast method: method_name, data: args, target: target_uuid[@@uuid_cutoff..-1], to_server: target_uuid[0...@@uuid_cutoff], type: :all
				end

				# Use this to multicast an event to ALL websocket connections on EVERY controller, including Placebo controllers.
				#
				# Accepts:
				# method_name:: a Symbol with the method's name that should respond to the broadcast.
				# args*:: The method's argumenst - It MUST be possible to stringify the arguments into a YAML string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
				#
				# The method will be called asynchrnously for ALL websocket connections.
				#
				def multicast method_name, *args
					_inner_broadcast method: method_name, data: args, type: :all
				end

				# WebSockets

				# sends the broadcast
				def _inner_broadcast data, ignore_io = nil
					if data[:target]
						if data[:target] && (data[:to_server] == Plezi::Settings.uuid )
							return ( ::Iodine::Http::Websockets.unicast( data[:target], data ) || ___faild_unicast( data ) )
						end
						return ( data[:to_server].nil? && ::Iodine::Http::Websockets.unicast(data[:target], data) ) || ( Plezi::Base::AutoRedis.away?(data[:to_server]) && ___faild_unicast( data ) ) || __inner_redis_broadcast(data)
					else
						::Iodine::Http::Websockets.broadcast data, ignore_io
						__inner_redis_broadcast data				
					end
					true
				end

				def __inner_redis_broadcast data
					return unless conn = Plezi.redis
					data = data.dup
					data[:type] = data[:type].name if data[:type].is_a?(Class)
					data[:server] = Plezi::Settings.uuid
					return conn.publish( ( data[:to_server] || Plezi::Settings.redis_channel_name ), data.to_yaml ) if conn
					false
				end

				def ___faild_unicast data
					has_class_method?(:failed_unicast) && failed_unicast( data[:to_server].to_s + data[:target], data[:method], data[:data] )
					true
				end

				def has_method? method_name
					@methods_list ||= self.instance_methods.to_set
					@methods_list.include? method_name
				end
				def has_class_method? method_name
					@class_methods_list ||= self.methods.to_set - Object.methods
					@class_methods_list.include? method_name
				end
			end
		end
	end
end
