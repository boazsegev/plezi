module Plezi

	####
	# a skeleton for a RESTful controller class
	#
	# you dont have to inherit this or use this, this is stub code.
	#
	# it can also be used for non RESTful requests by utilizing only the
	# index method or adding public methods that aren't RESTful reserved (and don't start with '_').
	#
	# if a method returns false, a 404 error (not found) is assumed. and routes continue to search.
	#
	# otherwise, the method's return value is added to the response body. Normally, the method will return a String object.
	#
	# methods should return the response's body string as their last value, unless
	# they have correctly edited the response (in which case they should return `true`).
	#
	class StubRESTCtrl

		# every request that routes to this controller will create a new instance
		def initialize
		end

		# called when request is GET and params\[:id] isn't defined
		def index
			"Hello World!"
		end

		# called when request is GET and params\[:id] exists
		def show
			"nothing to show for id - #{params[:id]} - with parameters: #{params.to_s}"
		end

		# called when request is GET and params\[:id] == "new" (used for the "create new object" form).
		def new
			"Should we make something new?"
		end

		# called when request is POST or PUT and params\[:id] isn't defined params\[:id] == "new" 
		def save
			"save called - creating a new object."
		end

		# called when request is POST or PUT and params\[:id] exists and isn't "new"
		def update
			"update called - updating #{params[:id]}"
		end

		# called when request is DELETE (or params["_method"] == 'delete') and request.params\[:id] exists
		def delete
			"delete called - deleting object #{params[:id]}"
		end

		# called before request is called
		#
		# if method returns false (not nil), controller exists
		# and routes continue searching
		def before
			true
		end
		# called after request is completed
		#
		# if method returns false (not nil), the request body is cleared,
		# the controller exists and routes continue searching
		def after
			true
		end
	end

	####
	# a skeleton for a WebSocket controller class which uses REST to emulate long XHR pulling
	#
	# you dont have to inherit this or use this, this is example/stub code.
	#
	# WebSockets Controllers and RESTful Controllers can be the same class
	# (the same route can handle both a regular request and a WebSocket request).
	#
	# if the pre_connect method returns false, the WebSockets connection will be refused and the remaining routes will be attempted.
	#
	class StubWSCtrl

		# every request that routes to this controller will create a new instance
		def initialize
		end

		# called before the protocol is swithed from HTTP to WebSockets.
		#
		# this allows setting headers, cookies and other data (such as authentication)
		# prior to opening a WebSocket.
		#
		# if the method returns false, the connection will be refused and the remaining routes will be attempted.
		def pre_connect
			true
		end

		# called immediately after a WebSocket connection has been established.
		def on_connect
			true
		end

		# called when new data is recieved
		#
		# data is a string that contains binary or UTF8 (message dependent) data.
		def on_message data
			broadcast :_push, data
			_push "your message was sent: #{data.to_s}"
		end

		# called when a disconnect packet has been recieved or the connection has been cut
		# (ISN'T called after a disconnect message has been sent).
		def on_disconnect
		end

		# a demo event method that recieves a broadcast from instance siblings.
		#
		# methods that are protected and methods that start with an underscore are hidden from the router
		# BUT, broadcasted methods must be public (or the broadcast will quietly fail)... so we have to use
		# the _underscore for this method.
		def _push data
			response << data.to_s
		end

		#####
		## It is possible to use RESTful methods to help emulate long XHR pulling.
		## a RESTful controller can also be a WebSockets controller (these are not exclusive qualities).

		# called when request is GET and params\[:id] isn't defined
		def index
			"This stub controller is used to test websockets.\n\r\n\rVisit http://www.websocket.org/echo.html for WS testing.\n\r\n\rOr add a nickname to the route to view long-pulling stub. i.e.: #{request.base_url}/nickname"
		end

		# called when request is GET and params\[:id] exists (unless params\[:id] == "new").
		def show
			{message: 'read_chat', data: {id: params[:id], token: cookies['example_token'], example_data: 'we missed you.'}}.to_json
		end
		# called when request is POST / PUT and params\[:id] exists
		def update
			# assumes body is JSON - more handling could be done using the params (which hold parsed JSON data).
			broadcast :_push, request[:body] 
			{message: 'write_chat', data: {id: params[:id], token: cookies['example_token'], example_data: 'message sent.'}}.to_json
		end

	end
end
