### Ruby core extentions

require 'singleton'
require 'pathname'
require 'base64'
require 'digest/sha1'
require 'securerandom'
require 'time'
require 'json'
require 'yaml'
require 'uri'
require 'set'

# Iodine server
require 'rack'
require 'iodine'
### version
require "plezi/version"

####### Plezi 0.13.x Core requirements
# constants and core support
require 'plezi/core/constants.rb'
require 'plezi/core/logging.rb'
require 'plezi/core/cache.rb'
# redis and websockets support
require 'plezi/core/redis.rb'
require 'plezi/core/redis_emulation.rb'
require 'plezi/core/websockets.rb'
# controller methods and helpers
require 'plezi/core/controller_core.rb'
require 'plezi/core/controller_magic.rb'
require 'plezi/core/helpers.rb'
require 'plezi/core/renderer.rb'
# routing
require 'plezi/core/route.rb'
require 'plezi/core/router.rb'
require 'plezi/core/mime_types.rb'
# public facing API
require 'plezi/core/api.rb'
require 'plezi/core/dsl.rb'
# core management
require 'plezi/core/settings.rb'

# ####### Plezi 0.12.x
#
# ### common
# require 'plezi/common/defer.rb'
# require 'plezi/common/cache.rb'
# require 'plezi/common/api.rb'
# require 'plezi/common/dsl.rb'
# require 'plezi/common/redis.rb'
# require 'plezi/common/settings.rb'
# require 'plezi/common/renderer.rb'
#
# ### helpers
# require 'plezi/helpers/magic_helpers.rb'
# require 'plezi/helpers/mime_types.rb'
#
# ### HTTP and WebSocket Handlers
# require 'plezi/handlers/http_router.rb'
# require 'plezi/handlers/route.rb'
# require 'plezi/handlers/ws_object.rb'
# require 'plezi/handlers/ws_identity.rb'
# require 'plezi/handlers/controller_magic.rb'
# require 'plezi/handlers/controller_core.rb'
# require 'plezi/handlers/placebo.rb'
# require 'plezi/handlers/stubs.rb'
# require 'plezi/handlers/session.rb'
#
# # error and last resort handling
# require 'plezi/helpers/http_sender.rb'

## erb templating
begin
	require 'erb'
rescue

end

##############################################################################
#
# Plezi is an easy to use Ruby Websocket Framework, with full RESTful routing support. It's name comes from the word "fun" in Haitian, since Plezi is really fun to work with and it keeps our code clean and streamlined.
#
# Plezi is a wonderful alternative to Socket.io which makes writing the server using Ruby a breeze.
#
# Plezi is multi-threaded by default (you can change this) and supports asynchronous callbacks,
# so it will keep going even if some requests take a while to compute.
#
# Plezi routes accept controller classes, which makes RESTful and WebSocket applications easy to write.
# For example, open your Ruby terminal (the `irb` command) and type:
#
#    require 'plezi'
#    route "*", Plezi::StubRESTCtrl
#    exit # will start the service.
#
# Controller classes don't need to inherit anything :-)
#
# Plezi's routing systems inherits the Controller class, allowing you more freedom in your code.
#
#    require 'plezi'
#    class MyController
#       def index
#          "Hello World!"
#       end
#    end
#    route "*", MyController
#
#    exit # I'll stop writing this line every time.
#
# Amazing(!), right? - You can read more in the documentation for Plezi::StubWSCtrl and Plezi::StubRESTCtrl, which are stub classes used for testing routes.
#
# Plezi routes accept Regexp's (regular exceptions) for route paths.
# Plezi also accepts an optional block instead of the conrtoller Class object for example:
#
#    require 'plezi'
#    route(/[.]*/) {|request, response| response << "Your request, master: #{request.path}."}
#
# As you may have noticed before, the catch-all route (/[.]*/) has a shortcut: '*'.
#
# class routes that have a specific path (including root, but not a catch-all or Regexp path)
# accept an implied `params[:id]` variable. the following path ('/'):
#
#    require 'plezi'
#    route "/", Plezi::StubWSCtrl
#    # go to: http://localhost:3000/1
#    # =>  Plezi::StubRESTCtrl.new.show() # where params[:id] == 1
#
# it is possible to use "magic" routes (i.e. `/resource/:type/(:id)/(:date){/[0-9]{8}}/:foo`) and it is also possible to set the appropriate parameters within the `before` method of the Conltroller.
#
# Routes are handled in the order they are created. If overlapping routes exist, the first will execute first:
#
#    require 'plezi'
#    route('*') do |request, response|
#       response << "Your request, master: #{request.path}." unless request.path.match /cats/
#    end
#    route('*') {|request, response| response.body << "Ahhh... I love cats!"}
#
# The Plezi module (also `PL`) also has methods to help with asynchronous tasking, callbacks, timers and customized shutdown cleanup.
#
# Heres a short demo fir asynchronous callbacks (works only while services are active and running):
#
#    require 'plezi'
#
#    def my_shutdown_proc time_start
#        puts "Services were running for #{Time.now - time_start} ms."
#    end
#
#    # shutdown callbacks
#    PL.on_shutdown(Kernel, :my_shutdown_proc, Time.now) { puts "this will run after shutdown." }
#    PL.on_shutdown() { puts "this will run too." }
#
#    # a timer
#    PL.run_after 2, -> {puts "this will wait 2 seconds to run... too late. for this example"}
#
#    # remember to exit to make it all start
#    exit
#
# all the examples above shoold be good to run from irb. updated examples can be found at the Readme file in the Github project: https://github.com/boazsegev/plezi
#
# thanks to Russ Olsen for his ideas for a DSL and his blog post at:
# http://www.jroller.com/rolsen/entry/building_a_dsl_in_ruby1
#
# ...he doesn't know it, but he inspired a revolution.
##############################################################################
module Plezi
end

Iodine::Rack.on_http = Plezi.app
Iodine::Rack.on_websocket = Plezi::Base::Router.method :ws_call
Iodine::Rack.threads ||= 30
Iodine::Rack.on_start { puts "Plezi is feeling optimistic running version #{::Plezi::VERSION} using Iodine #{::Iodine::VERSION}.\n\n"}
Iodine::Rack.on_start { ::NO_PLEZI_AUTOSTART = true unless defined?(::NO_PLEZI_AUTOSTART) }
# PL is a shortcut for the Plezi module, so that `PL == Plezi`.
PL = Plezi

at_exit do
	Iodine::Rack.start unless defined?(::NO_PLEZI_AUTOSTART) || ::Plezi::Base::Router.instance_variable_get(:@hosts).empty?
end
