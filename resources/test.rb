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


# removie this demo route and add your routes here:
shared_route '/', SampleController


# this is the static file route
shared_route "/", file_root: Root.join('public').to_s, allow_indexing: false


# Thin server MVC controller path
# the SampleController is just waiting to be inherited...
#
# perfomance note: it's better to place MVC routes BEFORE the file serving route.
#
# this route accepts any /mvc/:id and the :id is mapped to: params["id"]
#
# a SampleController instance will be created and called (supports REST).
# 
# if the :id is the name of an SampleController instance method, it will be called.
# try: http://localhost:3000/demo
#
shared_route '/users', UserController

