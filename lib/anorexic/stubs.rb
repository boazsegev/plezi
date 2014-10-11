module Anorexic

	# this class is a stub used to merge a file Logger with STDOUT (double output)
	class CustomIO
		def initialize *targets
			@targets = targets
		end

		def write(*args, &block)
			send_to_targets(:write, *args, &block)
		end
		def close(*args, &block)
			send_to_targets(:close, *args, &block)
		end
		def send_to_targets(sym, *args, &block)
			ret = []
			if block
				@targets.each {|t| ret << t.send(sym, *args, &block)}
			else
				@targets.each {|t| ret << t.send(sym, *args)}
			end
			return *ret
		end

		def method_missing(sym, *args, &block)
			send_to_targets sym, *args, &block
		end
	end

	####
	# a skelaton for a RESTful controller class
	#
	# you dont have to inherit this or use this, this stub code.
	#
	# it can also be used for non RESTful requests by utilizing only the
	# index method.
	#
	# if a method returns false, an 404 not found is assumed. and routes continue to search.
	#
	# otherwise, the method's return value is added to the response body. Normally, the method will return a String object.
	#
	# methods should return the body string as their last value
	#
	class StubController

		def initialize
		end

		# called when request is GET and there's no "id" in quary
		def index
			"Hello World!"
		end

		# called when request is GET and quary defines "id"
		def show
			"nothing to show: #{params[:id]}"
		end

		# called when request is POST or PUT and there's no "id" in quary
		def save
			"save called: #{params[:id]}"
		end

		# called when request is POST or PUT and quary defines "id"
		def update
			"update called: #{params[:id]}"
		end

		# called when request is DELETE and quary defines "id"
		def delete
			"delete called: #{params[:id]}"
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
end
