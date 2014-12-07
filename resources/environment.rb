# encoding: UTF-8

# this file sets up the basic framework.

# Using pathname extentions for setting public folder
require 'pathname'
#set up root object, it might be used by the environment and\or the anorexic extension gems.
Root ||= Pathname.new(File.dirname(__FILE__)).expand_path

# make sure all file access and file loading is relative to the application's root folder
Dir.chdir Root.to_s

# ensure development mode? (comment before production, environment dependent)
ENV["RACK_ENV"] ||= "development"

# save the process id (pid) to file - notice Heroku doesn't allow to write files.
(IO.write File.expand_path(File.join 'tmp','pid'), Process.pid unless ENV["DYNO"]) rescue true

# using bundler to load gems (including the anorexic gem)
require 'bundler'
Bundler.require

# set up Anorexic logs - Heroku logs to STDOUT, this machine logs to log file
Anorexic.create_logger File.expand_path(File.join 'logs','server.log'), ENV["RACK_ENV"]=="development" unless ENV['DYNO']

# load all config files
Dir[File.join "{config}", "**" , "*.rb"].each {|file| load File.expand_path(file)}

# load all library files
Dir[File.join "{lib}", "**" , "*.rb"].each {|file| load File.expand_path(file)}

# load all application files
Dir[File.join "{app}", "**" , "*.rb"].each {|file| load File.expand_path(file)}

# start a web service to listen on the first default port (3000 or the port set by the command-line).
# you can change some of the default settings here.
listen 	root: Root.join('public').to_s,
		assets: Root.join('assets').to_s,
		assets_public: '/assets',
		templates: Root.join('app','views').to_s,
		ssl: false
