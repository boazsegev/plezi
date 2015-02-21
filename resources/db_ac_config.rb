#################
##     SETTINGS FOR DATABASES
#
# this file contains common settings and rake tasks for ORM gems.
#
# please review / edit the settings you need.
# 
############
## ActiveRecord without Rails
# more info @:
# https://www.youtube.com/watch?v=o0SzhgYntK8
# demo code here:
# https://github.com/stungeye/ActiveRecord-without-Rails
if defined? ActiveRecord

	if defined? SQLite3
		ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => Root.join('db','db.sqlite3').to_s, encoding: 'unicode'
	elsif defined? PG
		ActiveRecord::Base.establish_connection :adapter => 'postgresql', encoding: 'unicode'
  else
    Plezi.logger.warning "ActiveRecord database adapter not auto-set. Update the db_ac_config.rb file"
	end

	# if debugging purposes, uncomment this line to see the ActiveRecord's generated SQL:
	# ActiveRecord::Base.logger = Plezi.logger

	# Uncomment this line to make the logger output look nicer in Windows.
	# ActiveSupport::LogSubscriber.colorize_logging = false

	if defined? Rake
##########
# start rake segment

    namespace :db do

      desc "Migrate the database so that it is fully updated, using db/migrate."
      task :migrate do
        ActiveRecord::Base.logger = Plezi.logger
        ActiveRecord::Migrator.migrate(Root.join('db', 'migrate').to_s, ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
      end

      desc "Seed the database using the db/seeds.rb file"
      task :seed do
        if ::File.exists? Root.join('db','seeds.rb').to_s
          load Root.join('db','seeds.rb').to_s
        else
          puts "the seeds file doesn't exists. please create a seeds.db file and place it in the db folder for the app."
        end
      end

    end

# end rake segment
##########
	end

end

