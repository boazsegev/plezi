########################
# RackServer rack interface
#
# using Rack with Plezi poses some limitations...:
#
# 1. there is NO WebSockets support for Rack apps.
#
# 2. this might break any streaming / asynchronous methods calls, such as Iodine's Http streaming.
#
# 3. Plezi parameters and file uploads are different then Rack - HTML Form code might be incompatible!
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
#
#
##############
#
# For now, Rack mode is NOT supported unless using the Iodine Http server,
# even than you're 404 not found pages will break unless using a catch-all route.

# load all framework and gems
load ::File.expand_path(File.join("..", "environment.rb"),  __FILE__)

# set up the routes
load ::File.expand_path(File.join("..", "routes.rb"),  __FILE__)

# start the plezi EM, to make sure that the plezi async code doesn't break.
if Rack::Handler.default == Iodine::Http::Rack
	run(Proc.new { [404, {}, ["not found"]] })
else
	raise "Unsupported Server - Plezi only runs using Iodine."
end
