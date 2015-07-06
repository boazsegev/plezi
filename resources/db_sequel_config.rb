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
  
  if defined? PG && ENV['DYNO']
    # A default Postgres connection for Heroku:
    DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_RED_URL'])
  else
    # use db/config.yaml to connect to database
    DB = Sequel.connect( YAML::load(  File.open( Root.join('db', 'config.yml').to_s )  )[ ENV["ENV"].to_s ] )
  end
  if defined? Rake
##########
# start rake segment

# not yet implemented

# end rake segment
##########
  end

end


