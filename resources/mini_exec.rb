#!/usr/bin/env ruby
# encoding: UTF-8

# set the working directory
Dir.chdir ::File.expand_path(File.join(__FILE__, '..'))
# load the website-app
load ::File.expand_path(File.join('..', 'appname.rb'), __FILE__)
# Iodine options
Iodine::Rack.public ||= Root.join('public').to_s
Iodine.threads ||= 16
Iodine.processes ||= 1
