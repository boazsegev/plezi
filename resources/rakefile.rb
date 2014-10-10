# encoding: UTF-8
BUILDING_ANOREXIC_TEMPLATE = NO_ANOREXIC_AUTO_START = true

app_name = ::File.expand_path(::Dir["."][0]).split(/[\\\/]/).last
require ::File.expand_path(::Dir["."][0], ( app_name + ".rb") )

namespace :app do

	desc "adds and framework files that might be missing (use after adding anorexic gems)."
	task :rebuild do
		# require gem and add the app to the tree
		puts "coming soon..."
		template = AppTemplate.new 
		Dir.chdir '..'
		template.build app_name
	end
end

task :default do
	puts `rake -T`
end