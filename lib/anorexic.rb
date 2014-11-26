require 'singleton'
require 'pathname'
require 'logger'
require 'socket'
require 'openssl'
require 'strscan'
require 'base64'
require 'digest/sha1'
require 'time'
require 'json'

### version

require "anorexic/version"


### Server requirements

require "anorexic/server/services/basic_service"
require "anorexic/server/services/ssl_service"

require "anorexic/server/protocols/http"
require 'anorexic/server/protocols/http_request'
require 'anorexic/server/protocols/http_response'

require "anorexic/server/handlers/http_echo"
require "anorexic/server/handlers/http_host"
require "anorexic/server/handlers/http_router"

require "anorexic/server/helpers/http"
require "anorexic/server/helpers/mime_types"

require "anorexic/server/protocols/websocket"
require 'anorexic/server/protocols/ws_response'

## Server-Framework Bridges
require "anorexic/framework/controller_magic"
require "anorexic/framework/magic_helpers"
require "anorexic/framework/route"


### Framework requirements
require "anorexic/framework/stubs"
require "anorexic/framework/cache"
require "anorexic/framework/anorexic_methods"

### DSL requirements
require "anorexic/framework/dsl"


### optional Rack
require "anorexic/framework/rack_app"

## erb templating
begin
	require 'erb'
rescue Exception => e
	
end



##############################################################################
# To make something new, we leap to the unknown.
##############################################################################
# Anorexic is a stand alone web services app, which supports RESTful HTTP and WebSockets.
#
# Anorexic routes accept Regexp's (regular exceptions) for route paths. for example:
#
#    require 'anorexic'
#    listen
#    route(/[.]*/) {|request, response| response << "Your request, master: #{request.path}."}
#
# The catch-all route (/[.]*/) has a shortcut '*', so it's possible to write:
#
#    require 'anorexic'
#    listen
#    route('*') {|request, response| response << "Your request, master: #{request.path}."}
#
#
# Anorexic accepts an optional class object that can be passed using the `route` command. Passing a class object is especially useful for RESTful and WebSocket applications.
# read more at the Anorexic::StubWSCtrl and Anorexic::StubRESTCtrl documentation, which are stub classes used for testing routes.
#
#    require 'anorexic'
#    listen
#    route "*", Anorexic::StubRESTCtrl
#
# class routes that have a specific path (including root, but not a catch-all or Regexp path)
# accept an implied `params[:id]` variable. the following path ('/'):
#
#    require 'anorexic'
#    listen
#    route "/", Anorexic::StubRESTCtrl
#    # client requests: /1
#    #  =>  Anorexic::StubRESTCtrl.new.show() # where params[:id] == 1
#
# it is possible to use "magic" routes (i.e. `/resource/:type/(:id)/(:date){/[0-9]{8}}/:foo`) and it is also possible to set the appropriate paramaters within the `before` method of the Conltroller.
#
# Routes are handled in the order they are created. If overlapping routes exist, the first will execute first:
#
#    require 'anorexic'
#    listen
#    route('*') do |request, response|
#       response << "Your request, master: #{request.path}." unless request.path.match /cats/
#    end
#    route('*') {|request, response| response.body << "Ahhh... I love cats!"}
#
# all the examples above shuold be good to run from irb. updated examples can be found at the Readme file in the Github project: https://github.com/boazsegev/anorexic
#
# thanks to Russ Olsen for his ideas for a DSL and his blog post at:
# http://www.jroller.com/rolsen/entry/building_a_dsl_in_ruby1 
##############################################################################
module Anorexic
end
