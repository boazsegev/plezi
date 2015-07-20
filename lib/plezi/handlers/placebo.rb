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
		module Base
			class PsedoIO
				attr_reader :cache, :params
				def initialize handler
					@cache = { websocket_handler: handler}
					@params = {}
					handler.io = self
				end
				def call
					false
				end
				def clear?
					false
				end
				def on_disconnect
					false
				end
				# Access data stored in the IO's wrapper cache.
				def [] key
					@cache[key]
				end
				# Store data in the IO's wrapper cache.
				def []= key, val
					@cache[key] = val
				end
			end
			module Core
				def self.included base
					base.send :include, InstanceMethods
					base.extend ClassMethods
				end

				module InstanceMethods
					public
					attr_accessor :io
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
						return false unless self.class.has_super_method?(data[:method])
						self.method(data[:method]).call *data[:data]
					end
					# Returns the websocket connection's UUID, used for unicasting.
					def uuid
						io[:uuid] ||= SecureRandom.uuid
					end

				end
				module ClassMethods
					public
					def has_super_method? method_name
						@super_methods_list ||= self.superclass.instance_methods.to_set
						@super_methods_list.include? method_name
					end
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
			handler = new_class.new
			GReactor.add_raw_io_to_stack nil, Placebo::Base::PsedoIO.new(handler)
			handler
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
