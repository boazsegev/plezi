module Anorexic

	module AnoRack

		# this class - god willing - will transform the http service into a full-duplex
		# socket (maybe implementing the WebSocket protocol, as we discover more).
		#
		# it doesn't work yet and is extremely experimental.
		#
		# the vision is to recognise controller that are WebSocket friendly (answer to `onconnect` and `onmessage` etc')
		# and auto-transform the connection into a streaming connection, if possible.
		#
		class Chatter

			def initialize(env, controller)
				@env, @controller = env, controller
			end
			def method_name
				if env['rack.hijack']
					# hijack server
					Thread.start(request.env['rack.hijack'].call) do |s|
						a = ''
						begin
							# echo
							msg = ''
							while (a = s.gets) do
								msg << a
								if a == '\n\r'
									@controller.on_message(msg)
									msg = ''
								end
							end
							if msg != ''
									@controller.on_message(msg)
							end
							@controller.on_disconnect if @controller.class.superclass.public_instance_methods.include?(method_name)
							
						rescue Exception => e
							Anorexic.logger << e

						ensure
							s.close
							puts 'Hijacked socket closed.'
						end
					end
					return [101, {}, []]

				elsif env['async.callback']
					raise 'Thin async callback is not supported.'
				end
			end
			def fire_event(event, *args)
				method_name = "on_#{event}".to_sym
				 ObjectSpace.each_object(@controller.class) { |controller|
				 	controller.send(method_name, *args) if controller.class.superclass.public_instance_methods.include?(method_name) && (controller.object_id != @controller.object_id)
				 }
			end

		end
	end

end
