#!/usr/bin/env ruby
# encoding: UTF-8

# Using pathname extentions for setting public folder
require 'pathname'

#set up root object, it will be used by the environment and\or the anorexic extension gems.
Root ||= Pathname.new(File.dirname(__FILE__)).expand_path

# load all framework and gems
require ::File.expand_path(File.join("..", "environment.rb"),  __FILE__)

# start first service - defaults to 3000 or the port set by command-line
listen port


# remove this demo route and add your routes here:
# this route accepts any /:id and the :id is mapped to: params["id"] (available at params[:id] as well.)
shared_route '/', SampleController


# this is the static file route
shared_route "/", file_root: Root.join('public').to_s, allow_indexing: false


# this is a catch all route
# route('*') { |req, res| res.body << "Hello World!" }
