### Ruby core extentions

require 'singleton'
require 'pathname'
require 'logger'
require 'socket'
require 'openssl'
require 'strscan'
require 'base64'
require 'digest/sha1'
require 'securerandom'
require 'time'
require 'json'
require 'uri'
### version

require "plezi/version"


### Server requirements

require "plezi/server/services/basic_service"
require "plezi/server/services/ssl_service"
require "plezi/server/services/no_service"

require "plezi/server/protocols/http_protocol"
require 'plezi/server/protocols/http_request'
require 'plezi/server/protocols/http_response'

require "plezi/server/helpers/http"
require "plezi/server/helpers/mime_types"

require "plezi/server/protocols/websocket"
require 'plezi/server/protocols/ws_response'

## Server-Framework Bridges
require "plezi/handlers/http_echo"
require "plezi/handlers/http_host"
require "plezi/handlers/http_router"

require "plezi/handlers/controller_magic"
require "plezi/handlers/magic_helpers"
require "plezi/handlers/route"

require "plezi/handlers/stubs"

### Framework requirements
require "plezi/base/events"
require "plezi/base/timers"
require "plezi/base/services"
require "plezi/base/connections"
require "plezi/base/logging"
require "plezi/base/io_reactor"
require "plezi/base/cache"
require "plezi/base/engine"

### DSL requirements
require "plezi/base/dsl"

### optional Rack
require "plezi/base/rack_app"

## erb templating
begin
	require 'erb'
rescue Exception => e
	
end



##############################################################################
# To make something new, we leap to the unknown.
##############################################################################
# Plezi is a stand alone web services app, which supports RESTful HTTP, HTTP Streaming and WebSockets.
#
# Plezi is a wonderful alternative to Socket.io which makes writing the server using Ruby a breeze. 
#
# Plezi routes accept Regexp's (regular exceptions) for route paths. for example:
#
#    require 'plezi'
#    listen
#    route(/[.]*/) {|request, response| response << "Your request, master: #{request.path}."}
#
# The catch-all route (/[.]*/) has a shortcut '*', so it's possible to write:
#
#    require 'plezi'
#    listen
#    route('*') {|request, response| response << "Your request, master: #{request.path}."}
#
#
# Plezi accepts an optional class object that can be passed using the `route` command. Passing a class object is especially useful for RESTful and WebSocket applications.
# read more at the Plezi::StubWSCtrl and Plezi::StubRESTCtrl documentation, which are stub classes used for testing routes.
#
#    require 'plezi'
#    listen
#    route "*", Plezi::StubRESTCtrl
#
# class routes that have a specific path (including root, but not a catch-all or Regexp path)
# accept an implied `params[:id]` variable. the following path ('/'):
#
#    require 'plezi'
#    listen
#    route "/", Plezi::StubRESTCtrl
#    # client requests: /1
#    #  =>  Plezi::StubRESTCtrl.new.show() # where params[:id] == 1
#
# it is possible to use "magic" routes (i.e. `/resource/:type/(:id)/(:date){/[0-9]{8}}/:foo`) and it is also possible to set the appropriate parameters within the `before` method of the Conltroller.
#
# Routes are handled in the order they are created. If overlapping routes exist, the first will execute first:
#
#    require 'plezi'
#    listen
#    route('*') do |request, response|
#       response << "Your request, master: #{request.path}." unless request.path.match /cats/
#    end
#    route('*') {|request, response| response.body << "Ahhh... I love cats!"}
#
# all the examples above shuold be good to run from irb. updated examples can be found at the Readme file in the Github project: https://github.com/boazsegev/plezi
#
# thanks to Russ Olsen for his ideas for a DSL and his blog post at:
# http://www.jroller.com/rolsen/entry/building_a_dsl_in_ruby1 
#
# ...he doesn't know it, but he inspired a revolution.
##############################################################################
module Plezi
end
