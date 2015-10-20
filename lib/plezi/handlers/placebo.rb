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
					base.send :include, Plezi::Base::WSObject
					base.send :include, InstanceMethods
					base.extend ClassMethods
					base.superclass.instance_eval {extend SuperClassMethods}
				end

				#the methods here will be injected to the Placebo controller as Instance methods.
				module InstanceMethods
					public
					attr_accessor :io
					def initialize io_in, io_out, request
						@io_in = io_in
						@io_out = io_out
						@request = request
						super()
					end
					# Cleanup on disconnection
					def on_close
						io_out.close unless io_out.closed?
						return super() if defined? super
						Iodine.warn "Placebo #{self.class.superclass.name} disconnected. Ignore if this message appears during shutdown."
					end
					def placebo?
						true
					end
				end
				#the methods here will be injected to the Placebo controller as class methods.
				module ClassMethods
				end
				module SuperClassMethods
					def placebo?
						true
					end
				end
			end
			class PlaceboIO < ::Iodine::Http::Websockets
				# emulate Iodine::Protocol#timeout?
				def timeout? time
					false
				end
				# emulate Iodine::Protocol#call
				def call
					read
					Iodine.warn "Placebo IO recieved IO signal - this is unexpected..."
				end
				# override "go_away"
				def go_away
					close
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
			req = {}
			handler = new_class.new(i, o, req)
			io = Placebo::Base::PlaceboIO.new i, handler, req
			handler
		end
	end
end
