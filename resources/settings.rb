
# if you want active record support, uncomment the following line and set up the server
# require 'active_record'

## to return the WEBrick server without Rack,
## add the following line before a new listen call:
# Anorexic::Application.instance.server_class = Anorexic::WEBrickServer

#look at the library folder for more goodies :)

############
## ActiveRecord without Rails
# more info @:
# https://www.youtube.com/watch?v=o0SzhgYntK8
# demo code here:
# https://github.com/stungeye/ActiveRecord-without-Rails

if defined? DataMapper
  # If you want the logs...
  DataMapper::Logger.new(Anorexic.logger, :debug)
  
  if defined? SQLite3
    # An in-memory Sqlite3 connection:
    DataMapper.setup(:default, 'sqlite::memory:')

    # A Sqlite3 connection to a persistent database
    DataMapper.setup(:default, "sqlite:///#{Root.join('db', 'db.sqlite3').to_s}")
  elsif defined? PG
    # A Postgres connection:
    if ENV['DYNO']
      DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_RED_URL'])
    else
      Root.to_s.split(/\/\\/).last
      DataMapper.setup(:default, "postgres://localhost/#{Root.to_s.split(/[\/\\]/).last}")
    end
  end
  if defined? Rake
##########
# start rake segment

namespace :db do
  take :rebuild do
    DataMapper.finalize.auto_migrate!
  end
  task :migrate do
    DataMapper.finalize.auto_upgrade!
  end
  
end

# not yet implemented

# end rake segment
##########
  end

end

if defined? ActiveRecord

	if defined? SQLite3
		ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => Root.join('db','db.sqlite3').to_s, encoding: 'unicode'
	elsif defined? PG
		ActiveRecord::Base.establish_connection :adapter => 'postgresql', encoding: 'unicode'
	end

	# if debugging purposes, uncomment this line to see the ActiveRecord's generated SQL:
	# ActiveRecord::Base.logger = Anorexic.logger

	# Uncomment this line to make the logger output look nicer in Windows.
	# ActiveSupport::LogSubscriber.colorize_logging = false

	if defined? Rake
##########
# start rake segment

# not yet implemented

# end rake segment
##########
	end

end
