# I started writing tests... but I haven't finished quite yet.
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open-uri'
require 'plezi'

def report_before_filter(result= true)
	return true if $before_tested
	puts("    * Before filter test: #{PleziTestTasks::RESULTS[result]}")
	$before_tested = true
	true
end
def report_after_filter(result= true)
	return true if $after_tested
	puts("    * After filter test: #{PleziTestTasks::RESULTS[result]}")
	$after_tested = true
	true
end

class TestCtrl



	# this will be called before every request.
	def before
		report_before_filter
	end

	# this will be called after every request.
	def after
		report_after_filter
	end

	# shouldn't be available (return 404).
	def _hidden
		"do you see me?"
	end
	def index
		"test"
	end
	def headers
		"HTTP request: #{request[:method]} #{request[:query]} - version: #{request[:version]}\n" + (request.headers.map {|k, v| "#{k}: #{v}"} .join "\n")
	end

	# returns the url used to access this method
	def my_url
		dest = params.dup
		url_for dest
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
		case data
		when 'get uuid'
			response << "uuid: #{uuid}"
		when /to: ([^\s]*)/
			# puts "cating target: #{data.match(/to: ([^\s]*)/)[1]}"
			unicast data.match(/to: ([^\s]*)/)[1], :_push, "unicast"
			# broadcast :_push, "unicast"
		else
			broadcast :_push, data
			_push data
		end
			return true
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


	RESULTS = {true => "\e[32mpassed\e[0m", :waiting => "\e[32mwaiting validation\e[0m", :failed => "\e[31mFAILED!\e[0m"}
	RESULTS.default = RESULTS[:failed]

	def run_tests
		(public_methods(false)).each {|m| method(m).call if m.to_s.match /^test_/}
		report_before_filter false
		report_after_filter false
		true
	end
	def test_sleep
		Plezi.run_async do
			begin
				puts "    * Sleeper test: #{RESULTS[URI.parse("http://localhost:3000/sleeper").read == 'slept']}"
				puts "    * ASync tasks test: #{RESULTS[true]}"
			rescue => e
				puts "    **** Sleeper test FAILED TO RUN!!!"
				puts e
			end
		end
	end

	def test_index
		begin
			puts "    * Index test: #{RESULTS[URI.parse("http://localhost:3000/").read == 'test']}"
		rescue => e
			puts "    **** Index test FAILED TO RUN!!!"
			puts e
		end
	end
	def test_ssl
		puts "    * Connection to non-ssl and unique route test: #{RESULTS[URI.parse("http://localhost:3000/ssl").read == 'false']}"
		uri = URI.parse("https://localhost:3030/ssl")
		Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https"), verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
			puts "    * Connection to ssl and unique ssl route test: #{RESULTS[ http.request(Net::HTTP::Get.new(uri)).body == 'true' ]}"
		end
		rescue => e
		puts "    **** SSL Tests FAILED to complete!!!"
		puts e
	end
	def test_new
		puts "    * New RESTful path test: #{RESULTS[URI.parse("http://localhost:3000/new").read == 'new']}"

		rescue => e
		puts "    **** New RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_show
		puts "    * Show RESTful path test: #{RESULTS[URI.parse("http://localhost:3000/3").read == 'show 3']}"

		rescue => e
		puts "    **** Show RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_update
		puts "    * Update RESTful path test: #{RESULTS[Net::HTTP.post_form( URI.parse("http://localhost:3000/"), id: 3).body == 'update 3']}"

		rescue => e
		puts "    **** Update RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_delete
		puts "    * Delete RESTful path test: #{RESULTS[Net::HTTP.post_form( URI.parse("http://localhost:3000/"), id: 3, _method: :delete).body == 'delete 3']}"

		rescue => e
		puts "    **** Delete RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_save
		puts "    * Save RESTful path test: #{RESULTS[Net::HTTP.post_form( URI.parse("http://localhost:3000/new"), data: "passed").body == 'passed']}"

		rescue => e
		puts "    **** Save RESTful path test FAILED TO RUN!!!"
		puts e
	end
	def test_streamed
		begin
			puts "    * Streaming test: #{RESULTS[URI.parse("http://localhost:3000/streamer").read == 'streamed']}"
		rescue => e
			puts "    **** Streaming test FAILED TO RUN!!!"
			puts e
		end
	end
	def test_url_for
		test_url = "/some/path/test/my_url/ask/"
		puts "    * simple #url_for test: #{RESULTS[URI.parse("http://localhost:3000" + test_url).read == test_url]}"
		test_url = "/some/another_path/my_url/ask/"
		puts "    * missing arguments #url_for test: #{RESULTS[URI.parse("http://localhost:3000" + test_url).read == test_url]}"

		rescue => e
		puts "    **** #url_for test FAILED TO RUN!!!"
		puts e
	end
	def test_websocket
		connection_test = broadcast_test = echo_test = unicast_test = false
		begin
			ws4 = Plezi::WebsocketClient.connect_to("wss://localhost:3030") do |msg|
				if msg == "unicast"
					puts "    * Websocket unicast testing: #{RESULTS[false]}"
					unicast_test = :failed
				end
			end
			ws2 = Plezi::WebsocketClient.connect_to("wss://localhost:3030") do |msg|
				next unless @is_connected || !(@is_connected = true)
				if msg == "unicast"
					puts "    * Websocket unicast message test: #{RESULTS[false]}"
					unicast_test = :failed
					next
				else
					puts "    * Websocket broadcast message test: #{RESULTS[broadcast_test = (msg == 'echo test')]}"
					go_test = false
				end
			end
			ws3 = Plezi::WebsocketClient.connect_to("wss://localhost:3030") do |msg|
				if msg.match /uuid: ([^s]*)/
					ws2 << "to: #{msg.match(/^uuid: ([^s]*)/)[1]}"
					puts "    * Websocket UUID for unicast testing: #{msg.match(/^uuid: ([^s]*)/)[1]}"
				elsif msg == "unicast"
					puts "    * Websocket unicast testing: #{RESULTS[:waiting]}"
					unicast_test ||= true
				end
			end
			ws3 << 'get uuid'
			puts "    * Websocket SSL client test: #{RESULTS[ws2 && true]}"
			ws1 = Plezi::WebsocketClient.connect_to("ws://localhost:3000") do |msg|
				unless @connected
					puts "    * Websocket connection message test: #{RESULTS[connection_test = (msg == 'connected')]}"
					@connected = true
					response << "echo test"
					next
				end
				if msg == "unicast"
					puts "    * Websocket unicast testing: #{RESULTS[false]}"
					unicast_test = :failed
					next
				end
				puts "    * Websocket echo message test: #{RESULTS[echo_test = (msg == 'echo test')]}"
			end
			
		rescue => e
			puts "    **** Websocket tests FAILED TO RUN!!!"
			puts e.message
		end
		remote = Plezi::WebsocketClient.connect_to("wss://echo.websocket.org/") {|msg| puts "    * Extra Websocket Remote test (SSL: echo.websocket.org): #{RESULTS[msg == 'Hello websockets!']}"; response.close}
		remote << "Hello websockets!"
		sleep 0.5
		[ws1, ws2, ws3, ws4, remote].each {|ws| ws.close}
		PL.on_shutdown {puts "    * Websocket connection message test: #{RESULTS[connection_test]}" unless connection_test}
		PL.on_shutdown {puts "    * Websocket echo message test: #{RESULTS[echo_test]}" unless echo_test}
		PL.on_shutdown {puts "    * Websocket broadcast message test: #{RESULTS[broadcast_test]}" unless broadcast_test}
		PL.on_shutdown {puts "    * Websocket unicast message test: #{RESULTS[unicast_test]}"}
	end
	def test_404
		puts "    * 404 not found and router continuity tests: #{RESULTS[ Net::HTTP.get_response(URI.parse "http://localhost:3000/get404" ).code == '404' ]}"

		rescue => e
		puts "    **** 404 not found test FAILED TO RUN!!!"
		puts e
	end
	def test_500
		workers = Plezi::EventMachine.count_living_workers
		print "    * 500 internal error test: #{RESULTS[ Net::HTTP.get_response(URI.parse "http://localhost:3000/fail" ).code == '500' ]}"
		# cause 10 more exceptions to be raised... testing thread survival.
		10.times { putc "."; Net::HTTP.get_response(URI.parse "http://localhost:3000/fail" ).code }
		putc "\n"
		workers_after_test = Plezi::EventMachine.count_living_workers
		puts "    * Worker survival test: #{RESULTS[workers_after_test == workers]} (#{workers_after_test} out of #{workers})"

		rescue => e
		puts "    **** 500 internal error test FAILED TO RUN!!!"
		puts e
	end
end

NO_PLEZI_AUTO_START = true

PL.create_logger '/dev/null'
# PL.max_threads = 4

listen port: 3000

route("/ssl") {|req, res| res << "false" }
listen port: 3030, ssl: true
route("/ssl") {|req, res| res << "true" }

shared_route '/some/:multi{path|another_path}/(:option){route|test}/(:id)/(:optional)', TestCtrl
shared_route '/', TestCtrl


Plezi::EventMachine.start Plezi.max_threads

shoutdown_test = false
Plezi.on_shutdown { shoutdown_test = true }

puts "    --- Starting tests"
puts "    --- Failed tests should read: #{PleziTestTasks::RESULTS[false]}"
PleziTestTasks.run_tests


# Plezi::EventMachine.clear_timers

sleep PLEZI_TEST_TIME if defined? PLEZI_TEST_TIME

Plezi::DSL.stop_services
puts "#{Plezi::EventMachine::EM_IO.count} connections awaiting shutdown."
Plezi::EventMachine.stop_connections
puts "#{Plezi::EventMachine::EM_IO.count} connections awaiting shutdown after connection close attempt."
if Plezi::EventMachine::EM_IO.count > 0
	Plezi::EventMachine.forget_connections
	puts "#{Plezi::EventMachine::EM_IO.count} connections awaiting shutdown after connections were forgotten."
end
Plezi::EventMachine.shutdown


puts "    * Shutdown test: #{ PleziTestTasks::RESULTS[shoutdown_test] }"


