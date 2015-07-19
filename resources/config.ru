########################
# RackServer rack interface
#
# using Rack with Plezi poses some limitations...:
#
# 1. only the first service (and all it's virtual hosts) will be running.
#    (only the first `listen` call and all it's related `host` calls)
#
# 2. there is NO WebSockets support for Rack apps.
#
# 3. this WILL BREAKE any streaming / asynchronous methods calls that use the Plezi events engine.
#
# 4. Plezi parameters and file uploads are different then Rack - HTML Form code might be incompatible!
#    This MIGHT BREAKE YOUR CODE! (changing this requires Plezi to re-parse the HTML, and costs in performance).
#
# also, all Plezi server specific configuration will be ignored.
#
# on the other hand, there is an upside:
#
# 1. you can choose a well tested server written in C that might (or might not) bring a performance boost.
#
# 2. you have better control over Middleware then you could have with Plezi.
# ("wait", you might say, "there is no Middleware in Plezi!"... "Ahhh", I will answer, "so much to discover...")

NO_PLEZI_AUTO_START = true

# load all framework and gems
load ::File.expand_path(File.join("..", "environment.rb"),  __FILE__)

# set up the routes
load ::File.expand_path(File.join("..", "routes.rb"),  __FILE__)

# start the plezi EM, to make sure that the plezi async code doesn't break.
GReactor.clear_listeners
GReactor.start Plezi::Settings.max_threads

# run the Rack app - not yet supported
# run Plezi::Base::Rack

# # exit rack to start the plezi server
# Process.kill 'TERM'
