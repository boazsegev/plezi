#################
##     SETTINGS FOR DATABASES
#
# this file contains common settings and rake tasks for ORM gems.
#
# please review / edit the settings you need.
# 
############
## ActiveRecord without Rails
# more info at:
# https://www.youtube.com/watch?v=o0SzhgYntK8
# demo code here:
# https://github.com/stungeye/ActiveRecord-without-Rails
if defined? ActiveRecord
	puts "Loading ActiveRecord database setting: #{ENV['ENV']}"
	ActiveRecord::Base.establish_connection(  YAML::load(  File.open( Root.join('db', 'config.yml').to_s )  )[ ENV["ENV"].to_s ]  )

	# if debugging purposes, uncomment this line to see the ActiveRecord's generated SQL:
	# ActiveRecord::Base.logger = Plezi.logger

	# Uncomment this line to make the logger output look nicer in Windows.
	# ActiveSupport::LogSubscriber.colorize_logging = false

	# Load ActiveRecord Tasks, if implemented
	if defined? Rake

		begin
			require 'standalone_migrations'
			StandaloneMigrations::Tasks.load_tasks
		rescue Exception => e
			ActiveRecord::Tasks::DatabaseTasks.env = ENV['ENV'] || 'development'
			ActiveRecord::Tasks::DatabaseTasks.database_configuration = YAML.load(File.read(Root.join('db', 'config.yml').to_s))
			ActiveRecord::Tasks::DatabaseTasks.db_dir = Root.join('db').to_s
			ActiveRecord::Tasks::DatabaseTasks.fixtures_path = Root.join( 'db', 'fixtures').to_s
			ActiveRecord::Tasks::DatabaseTasks.migrations_paths = [Root.join('db', 'migrate').to_s]
			ActiveRecord::Tasks::DatabaseTasks.seed_loader = Class.new do
				def self.load_seed
					filename = Root.join('db', 'seeds.rb').to_s
					unless File.file?(filename)
						IO.write filename, ''
					end
					load filename
				end
			end
			ActiveRecord::Tasks::DatabaseTasks.root = Root.to_s

			task :environment do
				ActiveRecord::Base.configurations = ActiveRecord::Tasks::DatabaseTasks.database_configuration
				ActiveRecord::Base.establish_connection ActiveRecord::Tasks::DatabaseTasks.env.to_sym
			end

			load 'active_record/railties/databases.rake'

		end
	end


end

