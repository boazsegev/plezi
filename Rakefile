require "bundler/gem_tasks"

# create a default task
desc "Tests most of the basic features for the Plezi framework."
task :test do
	load "./test/plezi_tests.rb"
end
desc "Leaves the testing server open for 1 minute after most of the tests are complete, delaying shutdown testing."
task :slowtest do
	PLEZI_TEST_TIME = 60
	load "./test/plezi_tests.rb"
end

