#########################################
# this is your SampleController
#
# feed it and give it plenty of children, borothers and sisters.
#
#########################################
#
# this is a skelaton for a RESTful controller implementation.
#
# it can also be used for non RESTful requests by utilizing only the
# index method or other, non-RESTful, named methods.
#
# if a method returns false, an 404 not found is assumed. and routes continue to search.
#
# otherwise, the method's returned value is added to the response body (if it's a String).
#
# methods should return true (if the response was set/sent) or the body's string as their last value.
#
# no inheritance is required (the Anorexic framework inherits your code, not the other way around).
#
# has magic access to the following paramaters:
#
#    attr_accessor :env, :params, :request, :response, :cookies
#
# params:: short-cut for request.params
# request:: the request object
# response:: the response object.
# cookies:: a magic cookie-jar (sets and gets cookies).
# flash:: a hash used for one-time cookies (get and set). any added values will be available for the same client for this and the next connection, after which they are removed.
#
class SampleController

	# it is possible to includes all the Anorexic::FeedHaml helper methods...
	# ... this breakes the strict MVC architecture by running the HAML view
	# as part of the controller class. It's good for hacking, but bad practice.
	# include Anorexic::FeedHaml if defined? Anorexic::FeedHaml

	# called before any action except WebSockets actions
	def before
		# some actions before the request is parsed
		# you can remove this, ofcourse. the router doesn't require the method to exist.

		## uncomment the following line for a very loose reloading - use for debug mode only.
		# load Root.join("environment.rb").to_s unless ENV['RACK_ENV'] == 'production'

		true
	end

	# called after any action except WebSockets actions
	def after
		# some actions after the request is parsed
		# you can remove this, ofcourse. the router doesn't require the method to exist.
		true
	end

	# called when request is GET and there's no "id" in quary
	def index
		"Hello World."
	end

	# called when the params[:id] == fail. this a demonstration for custom routing.
	def fail
		# throw up this code and feed anorexic your own lines :)
		raise "Anorexic raising hell!"
	end

	# called when request is GET and quary defines "id"
	def show
		"I'd love to show you object with id: #{params[:id]}"
	end

	# called when the request is GET and the params[:id] == "new"
	def new
		"let's make something new."
	end

	# called when request is POST or PUT and there's no "id" in quary
	def save
		false
	end

	# called when request is POST or PUT and quary defines "id"
	def update
		false
	end

	# called when request is DELETE and quary defines "id"
	def delete
		false
	end

	# called before the protocol is swithed from HTTP to WebSockets.
	#
	# this allows setting headers, cookies and other data (such as authentication)
	# prior to opening a WebSocket.
	#
	# if the method returns false, the connection will be refused and the remaining routes will be attempted.
	def pre_connect
		false
	end

	# called immediately after a WebSocket connection has been established.
	# here we simply close the connection.
	def on_connect
		response.close
		false
	end

	# called when new data is recieved
	#
	# data is a string that contains binary or UTF8 (message dependent) data.
	#
	# the demo content simply broadcasts the message.
	def on_message data
		# broadcast sends an asynchronous message to all sibling instances, but not to self.
		broadcast :_tell_firends, data
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
	def _tell_firends data
		response << "Someone said #{data}"			
	end

end