#################
##     SETTINGS FOR DATABASES
#
# this file contains common settings and rake tasks for ORM gems.
#
# please review / edit the settings you need.
# 
############
## Sequel
# more info @:
# http://sequel.jeremyevans.net
if defined? Sequel
  
  if defined? SQLite3
    # An in-memory Sqlite3 connection:
    # DB = Sequel.sqlite

    # A Sqlite3 connection to a persistent database
    DB = Sequel.sqlite(Root.join('db', 'db.sqlite3').to_s)

  elsif defined? PG
    if ENV['DYNO']
      # A Postgres connection for Heroku:
      DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_RED_URL'])
    else
      # app name is the same as the root app folder: Root.to_s.split(/\/\\/).last
      DB = Sequel.connect("postgres://localhost/#{Root.to_s.split(/[\/\\]/).last}")
    end
  end
  if defined? Rake
##########
# start rake segment

# not yet implemented

# end rake segment
##########
  end

end


