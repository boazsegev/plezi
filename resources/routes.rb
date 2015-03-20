#!/usr/bin/env ruby
# encoding: UTF-8

#########
##
## This file holds the routes for your application
##
## use the `host`, `route` and `shared_route` functions
##


# This is an optional re-write route for I18n.
# i.e.: `/en/home` will be rewriten as `/home`, while setting params[:locale] to "en"
route "/:locale{#{I18n.available_locales.join "|"}}/*" , false if defined? I18n

###
# add your routes here:


# remove this demo route and the SampleController once you want to feed Plezi your code.
route '/', SampleController


# this is a catch all route with a stub controller.
# un comment the following line and replace the controller if you want a catch-all route.
# route '*',  Plezi::StubRESTCtrl
