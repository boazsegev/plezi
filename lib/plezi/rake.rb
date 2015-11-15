# Make sure the server doesn't start
Iodine.protocol = false


namespace :make
	# add ActiveRecord controller-model generator

	# add Squel controller-model generator

end
# add console mode
desc "Start the application as a console with no server."
task :irb do
  require 'irb'
  IRB.start
end
