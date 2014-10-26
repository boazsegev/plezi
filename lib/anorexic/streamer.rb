module Anorexic

	module AnoRack

		# this class - god willing - will transform the http service into a streaming
		# socket (maybe implementing the WebSocket protocol, as we discover more).
		#
		# it doesn't work yet and is extremely experimental.
		#
		# the vision is to recognise controller that are WebSocket friendly (answer to `onconnect` and `onmessage` etc')
		# and auto-transform the connection into a streaming connection, if possible.
		#
		class Streamer

			def initialize(env, controller)
				@env, @controller = env, controller
				if env['rack.hijack']
					# hijack server
					Thread.start(request.env['rack.hijack'].call) do |s|
						a = ''
						begin
							# echo
							s.puts a while a = s.gets
							
						rescue Exception => e

						ensure
							s.close
							puts 'Hijacked socket closed.'
						end
					end
					return [101, {}, []]

				elsif env['async.callback']
						
					
				end
			end

		end
	end

end
