#########################################
# this is your SampleController
#
# feed it and give it plenty of children, borothers and sisters.
#
#########################################
#
# this is a skelaton for a RESTful and WebSocket controller implementation.
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
# no inheritance is required (the Plezi framework inherits your code, not the other way around).
#
# here are some of the available controller properties and methods:
#
#    attr_accessor :params, :request, :response, :cookies
#
# params:: short-cut for request.params
# request:: the request object
# response:: the response object.
# cookies:: a magic cookie-jar (sets and gets cookies).
# flash:: a hash used for one-time cookies (get and set). any added values will be available for the same client for this and the next connection, after which they are removed.
#
# redirect_to:: easily set up redirection.
# send_data:: easily send data, setting the content-type header.
# render:: easily render Slim, Haml and IRB files into String text.
#
class SampleController

	# it is possible to includes all the Plezi::FeedHaml helper methods...
	# ... this breakes the strict MVC architecture by running the HAML view
	# as part of the controller class. It's good for hacking, but bad practice.
	# include Plezi::FeedHaml if defined? Plezi::FeedHaml

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
		# while using sym redirection (unlike string redirection),
		# Plezi will attempt to auto-format a valid URL. 
		redirect_to "assets_welcome.html".to_sym
	end

	# called when the params[:id] == fail. this a demonstration for custom routing.
	def fail
		# throw up this code and feed plezi your own lines :)
		raise "Plezi raising hell!"
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
	# prior to allowing a WebSocket to open.
	#
	# if the method returns false, the connection will be refused and the remaining routes will be attempted.
	def pre_connect
		# false
		true
	end

	# called immediately after a WebSocket connection has been established.
	def on_open
		# response.close
		# false
	end

	# called when new data is recieved
	#
	# data is a string that contains binary or UTF8 (message dependent) data.
	#
	# the demo content simply broadcasts the message.
	def on_message data
		# broadcast sends an asynchronous message to all sibling instances, but not to self.
		data = ERB::Util.html_escape data
		broadcast :_print_out, data
		response << "You said: #{data}"
		response << (request.ssl? ? "FYI: Yes, This is an SSL connection..." : "FYI: Nope, this isn't an SSL connection (clear text).") if data.match /ssl\?/i
end

	# called when a disconnect packet has been recieved or the connection has been cut
	# (ISN'T called after a disconnect message has been sent).
	def on_close
	end

	# a demo event method that recieves a broadcast from instance siblings.
	#
	# methods that are protected and methods that start with an underscore are hidden from the router
	# BUT, broadcasted methods must be public (or the broadcast will quietly fail)... so we have to use
	# the _underscore for this method.
	def _print_out data
		response << "Someone said: #{data}"			
	end

end