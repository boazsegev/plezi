#################
##     SETTINGS FOR DATABASES
#
# this file contains common settings and rake tasks for ORM gems.
#
# please review / edit the settings you need.
# 
############
## DataMapper
# more info @:
# http://datamapper.org
if defined? DataMapper
  # If you want the logs...
  DataMapper::Logger.new(Plezi.logger, :debug)
  
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

# end rake segment
##########
  end

end


