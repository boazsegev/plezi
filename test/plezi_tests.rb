# I started writing tests... but I haven't finished quite yet.
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open-uri'
require 'plezi'

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
	# called when request is POST / PUT and params\[:id] exists and isn't 'new'
	def update
		"update #{params[:id]}"
	end
	def delete
		"delete #{params[:id]}"
	end
	# called when request is POST / PUT and params\[:id] is 'new'
	def save
		params[:data].to_s
	end
	def sleeper
		sleep 1
		"slept"
	end
	# should return a 404 error.
	def get404
		false
	end
	# path to test for chuncked encoding and response streaming.
	def streamer
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

	RESULTS = {true => "passed", false => 'FAILED!'}

	def run_tests
		(public_methods(false)).each {|m| method(m).call if m.to_s.match /^test_/}
		true
	end
	def test_sleep
		Plezi.run_async do
			begin
				puts "Sleeper test: #{RESULTS[URI.parse("http://localhost:3000/sleeper").read == 'slept']}"
				puts "ASync tasks test: #{RESULTS[true]}"
			rescue => e
				puts "Sleeper test FAILED TO RUN!!!"
				puts e
			end
		end
	end

	def test_index
		begin
			puts "index test: #{RESULTS[URI.parse("http://localhost:3000/").read == 'test']}"
		rescue => e
			puts "Index test FAILED TO RUN!!!"
			puts e
		end
	end
	def test_ssl
		puts "Connection to non-ssl and unique route test: #{RESULTS[URI.parse("http://localhost:3000/ssl").read == 'false']}"
		uri = URI.parse("https://localhost:3030/ssl")
		Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https"), verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
			puts "Connection to ssl and unique ssl route test: #{RESULTS[ http.request(Net::HTTP::Get.new(uri)).body == 'true' ]}"
		end
		rescue => e
		puts "SSL Tests FAILED to complete!!!"
		puts e
	end
	def test_new
		puts "New RESTful path test: #{RESULTS[URI.parse("http://localhost:3000/new").read == 'new']}"

		rescue => e
		puts "New RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_show
		puts "Show RESTful path test: #{RESULTS[URI.parse("http://localhost:3000/3").read == 'show 3']}"

		rescue => e
		puts "Show RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_update
		puts "Update RESTful path test: #{RESULTS[Net::HTTP.post_form( URI.parse("http://localhost:3000/"), id: 3).body == 'update 3']}"

		rescue => e
		puts "Update RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_delete
		puts "Delete RESTful path test: #{RESULTS[Net::HTTP.post_form( URI.parse("http://localhost:3000/"), id: 3, _method: :delete).body == 'delete 3']}"

		rescue => e
		puts "Delete RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_save
		puts "Save RESTful path test: #{RESULTS[Net::HTTP.post_form( URI.parse("http://localhost:3000/new"), data: "passed").body == 'passed']}"

		rescue => e
		puts "Save RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_streamed
		begin
			puts "Streaming test: #{RESULTS[URI.parse("http://localhost:3000/streamer").read == 'streamed']}"
		rescue => e
			puts "Streaming test FAILED TO RUN!!!"
			puts e
		end
	end
	def test_404
		puts "404 not found and router continuity tests: #{RESULTS[ Net::HTTP.get_response(URI.parse "http://localhost:3000/get404" ).code == '404' ]}"

		rescue => e
		puts "404 not found test FAILED TO RUN!!!"
		puts e
	end
	def test_500
		workers = Plezi::EventMachine.count_living_workers
		puts "500 internal error test: #{RESULTS[ Net::HTTP.get_response(URI.parse "http://localhost:3000/fail" ).code == '500' ]}"
		# cause 10 more exceptions to be raised... testing thread survival.
		10.times { Net::HTTP.get_response(URI.parse "http://localhost:3000/fail" ).code }
		workers_after_test = Plezi::EventMachine.count_living_workers
		puts "Worker survival test: #{RESULTS[workers_after_test == workers]} (#{workers_after_test} out of #{workers})"

		rescue => e
		puts "404 not found test FAILED TO RUN!!!"
		puts e		
	end
end

NO_PLEZI_AUTO_START = true

PL.create_logger '/dev/null'

listen port: 3000

route("/ssl") {|req, res| res << "false" }
listen port: 3030, ssl: true
route("/ssl") {|req, res| res << "true" }

shared_route '/', TestCtrl


Plezi::EventMachine.start Plezi.max_threads

shoutdown_test = false
Plezi.on_shutdown { shoutdown_test = true }

PleziTestTasks.run_tests

Plezi::EventMachine.clear_timers

Plezi::DSL.stop_services

Plezi::EventMachine.shutdown


puts "Shutdown test: #{ PleziTestTasks::RESULTS[shoutdown_test] }"


