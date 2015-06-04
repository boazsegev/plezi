# I started writing tests... but I haven't finished quite yet.


class TestCtrl

	# this will be called before every request.
	def before
	end

	# this will be called after every request.
	def after
	end

	# shouldn't be available (return 404).
	def _hidden
		"do you see me?"
	end
	def index
		"test"
	end

	# should return a 500 internal server error message.
	def fail
		raise "Hell!"
	end

	# called when request is GET and params\[:id] == "new".
	def new
		"new"
	end
	# called when request is GET and params\[:id] exists (unless params\[:id] == "new").
	def show
		"show #{params[:id]}"
	end
	# called when request is POST / PUT and params\[:id] exists
	def update
		"update #{params[:id]}"
	end
	def delete
		"delete #{params[:id]}"
	end
	def save
		params.to_json
	end
	def sleeper
		sleep 1
		"Hello World! :)"
	end
	# should return a 404 error.
	def get404
		false
	end
	# path to test for chuncked encoding and response streaming.
	def streamed
		response.start_http_streaming
		PL.callback(self, :_stream_out) { PL.callback(response, :finish) }
		true
	end
	def _stream_out
		response.send "streamed"
		true
	end
	def file_test
		if params[:file]
			send_data params[:file][:data], type: params[:file][:type], inline: true, filename: params[:file][:filename]
			return true
		end
		false
	end


	############
	## WebSockets

	# called once the websocket was connected
	def on_connect
		response << "connected"
	end

	# called when new Websocket data is recieved
	#
	# data is a string that contains binary or UTF8 (message dependent) data.
	def on_message data
		broadcast :_push, data
		_push data
	end

	# called when a disconnect packet has been recieved or the connection has been cut
	# (ISN'T called after a disconnect message has been sent).
	def on_disconnect
	end

	# a demo event method that recieves a broadcast from instance siblings.
	def _push data
		response << data.to_s
	end
end

module PleziTestTasks
	module_function

	def run_tests
		(public_methods(false)).each {|m| method(m).call if m.to_s.match /^test_/}
		true
	end

	def test_index
		puts "?"
		
	end
	def test_new
		
	end
	def test_show
		
	end
	def test_update
		
	end
	def test_delete
		
	end
	def test_save
		
	end
	def test_streamed
		
	end
	def test_404
		
	end
	def test_500
		
	end
end
