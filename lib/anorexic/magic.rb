module Anorexic

	# the methods defined in this module will be injected into the Controller class passed to the MVC
	# and will be available for the controller to use.
	#
	module ControllerMagic
		module_function

		def me
			"go!"
			
		end

	end

end
