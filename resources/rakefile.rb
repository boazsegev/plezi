# encoding: UTF-8
BUILDING_PLEZI_TEMPLATE = true
NO_PLEZI_AUTO_START = true

require 'rubygems'
require 'rake'

app_name = ::File.expand_path(::Dir["."][0]).split(/[\\\/]/).last
require ::File.expand_path(::Dir["."][0], ( app_name + ".rb") )

namespace :app do

	desc "adds and framework files that might be missing (use after adding plezi gems).\nnotice: this will not update rakefile.rb or Gemfile(!)."
	task :rebuild do
		Dir.chdir '..'
		puts `plezi force #{app_name}`
	end
end

task :default do
	puts `rake -T`
end