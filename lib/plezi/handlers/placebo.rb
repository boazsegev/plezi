module Plezi

	# This API wil allows you to listen to Websocket Broadcasts sent to any object and to accept unicasts
	# even when NOT connected to a websocket.
	#
	# Simpley create a class to handle any events and call `Plezi::Placebo.new ClassName` :
	#
	#       class MyListener
	#          def _my_method_name *args
	#             #logic
	#          end
	#       end
	#
	#       Plezi::Placebo.new MyListener
	#
	# A new instance will be created and that instance will answer any broadcasts, for ALL possible
	# Plezi controllers, as long as it had a method defined that is capable to handle the broadcast.
	#
	# The new instance will also accept unicasts sent to it's unique UUID.
	#
	# Returns an instance that is a member of the class passed, after that class was inherited by Plezi and
	# more methods were injected into it's subclass.
	module Placebo

		# the base module exposes some of the core functionality, but shouldn't be relied upon as far as it's API goes.
		module Base
			#the methods here will be injected to the Placebo controller.
			module Core
				def self.included base
					base.send :include, InstanceMethods
					base.extend ClassMethods
					base.superclass.instance_eval {extend SuperClassMethods}
				end

				#the methods here will be injected to the Placebo controller as Instance methods.
				module InstanceMethods
					public
					attr_accessor :io
					def initialize io
						@io = io
						@io[:websocket_handler] = self
						super()
					end
					# notice of disconnect
					def on_close
						return super() if defined? super
						GR.warn "Placebo #{self.class.superclass.name} disconnected. Ignore if this message appears during shutdown."
					end

					# handles broadcasts / unicasts
					def on_broadcast ws
						data = ws.data
						unless (data[:type] || data[:target]) && data[:method] && data[:data]
							GReactor.warn "Broadcast message unknown... falling back on base broadcasting"
							return super(data) if defined? super
							return false
						end
						# return false if data[:type] && !self.is_a?(data[:type])
						return false if data[:target] && data[:target] != ws.uuid
						return false if data[:type] && data[:type] != :all && !self.is_a?(data[:type])
						return ((data[:type] == :all) ? false : (raise "Placebo Broadcasting recieved but no method can handle it - dump:\r\n #{data.to_s}") ) unless self.class.has_super_method?(data[:method])
						self.method(data[:method]).call *data[:data]
					end
					# Returns the websocket connection's UUID, used for unicasting.
					def uuid
						io[:uuid] ||= SecureRandom.uuid
					end

					# Performs a websocket unicast to the specified target.
					def unicast target_uuid, method_name, *args
						self.class.unicast target_uuid, method_name, *args
					end
					# broadcast to a specific controller
					def broadcast controller_class, method_name, *args
						GRHttp::Base::WSHandler.broadcast({data: args, type: controller_class, method: method_name}, self)
						__send_to_redis data: args, type: controller_class, method: method_name
					end
					# multicast to all handlers.
					def multicast method_name, *args
						GRHttp::Base::WSHandler.broadcast({method: method_name, data: args, type: :all}, self)
						__send_to_redis method: method_name, data: args, type: :all
					end
					protected
					def __send_to_redis data
						raise "Wrong method name for websocket broadcasting - expecting type Symbol" unless data[:method].is_a?(Symbol) || data[:method].is_a?(Symbol)
						conn = Plezi.redis_connection
						data[:server] = Plezi::Settings.uuid
						return conn.publish( Plezi::Settings.redis_channel_name, data.to_yaml ) if conn
						false
					end
				end
				#the methods here will be injected to the Placebo controller as class methods.
				module ClassMethods
					public
					def has_super_method? method_name
						@super_methods_list ||= self.superclass.instance_methods.to_set
						@super_methods_list.include? method_name
					end
				end
				module SuperClassMethods
					# Broadcast to all instances (usually one instance) of THIS placebo controller.
					#
					# This should be used by the real websocket connections to forward messages to the placebo controller classes.
					def broadcast method_name, *args
						GRHttp::Base::WSHandler.broadcast({data: args, type: self.class, method: method_name}, self)
						@methods_list ||= instance_methods.to_set
						raise "No mothod defined to accept this broadcast." unless @methods_list.include? method_name
						__send_to_redis data: args, type: controller_class, method: method_name
					end
					# Performs a websocket unicast to the specified target.
					def unicast target_uuid, method_name, *args
						GRHttp::Base::WSHandler.unicast target_uuid, data: args, target: target_uuid, method: method_name
						__send_to_redis data: args, target: target_uuid, method: method_name
					end
				end
			end
			class PlaceboIO < GReactor::BasicIO
				def clear?
					io.closed?
				end
				def call
					self.read
					GR.warn "Placebo IO recieved IO signal - this is unexpected..."
				end
				def on_disconnect
					@params[:out].close rescue nil
					@cache[:websocket_handler].on_close if @cache[:websocket_handler]
				end
			end
		end
		module_function
		def new placebo_class
			new_class_name = "PlaceboPlezi__#{placebo_class.name.gsub /[\:\-\#\<\>\{\}\(\)\s]/, '_'}"
			new_class = nil
			new_class =  Module.const_get new_class_name if Module.const_defined? new_class_name
			unless new_class
				new_class = Class.new(placebo_class) do
					include Placebo::Base::Core
				end
				Object.const_set(new_class_name, new_class)
			end
			i, o = IO.pipe
			io = Placebo::Base::PlaceboIO.new i, out: o
			io = GReactor.add_raw_io i, io
			new_class.new(io)
		end
	end
end


# class A
# def _hi
# 'hi'
# end
# end
# Plezi::Placebo.new A
# a = nil
# GReactor.each {|h| a= h}
# a[:websocket_handler].on_broadcast GRHttp::WSEvent.new(nil, type: true, data: [], method: :_hi)
