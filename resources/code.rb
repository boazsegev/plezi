#!/usr/bin/env ruby
# encoding: UTF-8

# load all framework and gems
require ::File.expand_path(File.join("..", "environment.rb"),  __FILE__)

# start a web service to listen on the first default port (3000 or the port set by the command-line).
listen root: Root.join('public').to_s, assets: Root.join('assets').to_s, assets_public: '/assets' #, debug: (ENV['RACK_ENV'] != 'production')


# This is an optional re-write route for I18n - Set it up in the ./config/i18n_config.rb file
route "*" , I18nReWrite if defined? I18n

# remove this demo route and add your routes here:
# this route accepts any /:id and the :id is mapped to: params["id"] (available as params[:id] as well.)
shared_route '/', SampleController


# this is a catch all route
# route('*') { |req, res| res.body << "Hello World!" }
