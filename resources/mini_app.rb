# encoding: UTF-8

## Set environment, working directory, load gems and create logs
ENV['ENV'] ||= ENV['RACK_ENV'] # production ENV will render SASS as compressed.
## Using pathname extentions for setting public folder
require 'pathname'
## Set up root object, it might be used by the environment and\or the plezi extension gems.
Root ||= Pathname.new(File.dirname(__FILE__)).expand_path
## If this app is independant, use bundler to load gems (including the plezi gem).
## otherwise, use the original app's Gemfile and Plezi will automatically switch to Rack mode.
require 'bundler'
Bundler.require(:default, ENV['ENV'].to_s.to_sym)

# # Optional code auto-loading and logging:

# # Load all the code from a subfolder called 'app'
Dir[File.join '{app}', '**', '*.rb'].each { |file| load File.expand_path(file) }

## Log to a file?
# Iodine.logger = Logger.new Root.join('server.log').to_s

# # Optional Scaling (across processes or machines):
ENV['PL_REDIS_URL'] ||= ENV['REDIS_URL'] ||
                        ENV['REDISCLOUD_URL'] ||
                        ENV['REDISTOGO_URL'] ||
                        nil # "redis://:password@my.host:6389/0"
# # redis channel name should be changed IF using the same Plezi code within
# # more then one application (i.e., using both Rails and Plezi together).
# Plezi.app_name = 'appsecret'

# Map the views folder to the template root (for the {#render} function).
Plezi.templates = Root.join('views').to_s

# load routes.
load Root.join('routes.rb').to_s
