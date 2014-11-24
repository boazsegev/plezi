#!/usr/bin/env ruby
# encoding: UTF-8

# load all framework and gems
require ::File.expand_path(File.join("..", "environment.rb"),  __FILE__)

# start a web service to listen on the first default port (3000 or the port set by the command-line).
listen root: Root.join('public').to_s, assets: Root.join('assets').to_s, assets_public: '/assets', templates: Root.join('views').to_s


# This is an optional re-write route for I18n.
# i.e.: `/en/home` will be rewriten as `/home`, while setting params[:locale] to "en"
route "/(:locale){#{I18n.available_locales.join "|"}}/*" , false if defined? I18n

# add your routes here:


# remove this demo route:
# this route accepts any /:id and the :id is mapped to: params[:id]
route '/', SampleController


# this is a catch all route with a stub controller
# route '*',  Anorexic::StubRESTCtrl
