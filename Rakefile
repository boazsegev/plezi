
NO_ANOREXIC_AUTO_START = true
ENV['RACK_ENV'] = 'test'

require "bundler/gem_tasks"

require 'lib/anorexic.rb'

require 'lib/anorexic/feed_haml.rb' if require 'haml'

require 'rspec'

namespace :test do

	desc "Test that default listen port increments"
	task :port do
		a = []
		10.times { a << listen}
		return (assert (a[-1].port - a[0].port) == 9) ? "pass" : "fail" # (had to increment 9 times - the first time increments nothing)
	end

	
end