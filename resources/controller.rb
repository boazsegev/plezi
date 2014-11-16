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
# index method.
#
# if a method returns false, an 404 not found is assumed. and routes continue to search.
#
# otherwise, the method's return value is added to the response body.
#
# methods should return the body string as their last value
#
# no inheritance required.
#
# has magic access to the following Rack paramaters:
#
#    attr_accessor :env, :params, :request, :response, :cookies
#
# env:: the http Rack env called.
# params:: short-cut for request.params
# request:: the request object
# response:: the response object. you can create a new one with `response = Rack::Request.new(env)`
# cookies:: short-cut for request.cookies - coockies cannot be set here - use response instead.
# flash:: a hash used for one-time cookies (get and set). any added values will be available for the same client for this and the next connection, after wish they are removed.
#
class SampleController

	# it is possible to includes all the Anorexic::FeedHaml helper methods...
	# ... this breakes the strict MVC architecture by running the HAML view
	# as part of the controller class. It's good for hacking, but bad practice.
	# include Anorexic::FeedHaml if defined? Anorexic::FeedHaml

	# called before any action
	def before

		## uncomment for a very loose reloading - use for debug mode only.
		# load Root.join("environment.rb").to_s unless ENV['RACK_ENV'] == 'production'

		true
	end

	# called when request is GET and there's no "id" in quary
	def index
		"Hello World."
	end

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

	def before
		# some actions before the request is parsed
		# you can remove this, ofcourse. the base class is enough
		true
	end
	def after
		# some actions after the request is parsed
		# you can remove this, ofcourse. the base class is enough
		true
	end
end