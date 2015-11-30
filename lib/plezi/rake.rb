# make sure this file only runs within the context of a Rake enabled script
if defined? Rake
	
	# Make sure the server doesn't start
	Iodine.protocol = false


	namespace :make do
		# TODO: add ActiveRecord controller-model generator

		# TODO: add Squel controller-model generator

	end
	# add console mode
	desc "Same as `plezi c`: starts the application as a console, NOT a server."
	task :console do
		Kernel.exec "plezi c"
	end
	desc "Same as `rake console`: starts the application as a console, NOT a server."
	task :c do
		Kernel.exec "plezi c"
	end

end