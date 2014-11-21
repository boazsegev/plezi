
module Anorexic

	# Rack application model support
	module_function
	

	# Anorexic dresses up for Rack - this is a watered down version.
	# a full featured Anorexic app, with WebSockets, requires the use of the Anorexic server
	# (the built-in server)
	def call env
		raise "No Anorexic Services" unless Anorexic::SERVICES[0]

		Anorexic::SERVICES[0][1][:handler].call env
	end
