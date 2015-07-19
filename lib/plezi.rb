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

# GRHttp servet
require 'grhttp'


## erb templating
begin
	require 'erb'
rescue => e

end

### version

require "plezi/version"

### common

require 'plezi/common/defer.rb'
require 'plezi/common/cache.rb'
require 'plezi/common/dsl.rb'
require 'plezi/common/settings.rb'

### helpers

require 'plezi/helpers/http_sender.rb'
require 'plezi/helpers/magic_helpers.rb'
require 'plezi/helpers/mime_types.rb'


### HTTP and WebSocket Handlers
require 'plezi/handlers/http_router.rb'
require 'plezi/handlers/route.rb'
require 'plezi/handlers/controller_magic.rb'
require 'plezi/handlers/controller_core.rb'
require 'plezi/handlers/stubs.rb'


##############################################################################
#
# Plezi is an easy to use Ruby Websocket Framework, with full RESTful routing support and HTTP streaming support. It's name comes from the word "fun" in Haitian, since Plezi is really fun to work with and it keeps our code clean and streamlined.
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
#    listen
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
#    listen
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
#    listen
#    route(/[.]*/) {|request, response| response << "Your request, master: #{request.path}."}
#
# As you may have noticed before, the catch-all route (/[.]*/) has a shortcut: '*'.
#
# class routes that have a specific path (including root, but not a catch-all or Regexp path)
# accept an implied `params[:id]` variable. the following path ('/'):
#
#    require 'plezi'
#    listen
#    route "/", Plezi::StubWSCtrl
#    # go to: http://localhost:3000/1
#    # =>  Plezi::StubRESTCtrl.new.show() # where params[:id] == 1
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
#    # an asynchronous method call with an optional callback block
#    PL.callback(Kernel, :puts, "Plezi will start eating our code once we exit terminal.") {puts 'first output finished'}
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
