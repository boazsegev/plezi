########################
# RackServer rack interface
#
# using Rack with Anorexic poses some limitations...:
#
# 1. only the first service (and all it's virtual hosts) will be running.
#    (only the first `listen` call and all it's related `host` calls)
#
# 2. there is NO WebSockets support for Rack apps.
#
# 3. this WILL BREAKE any streaming / asynchronous methods calls that use the Anorexic events engine.
#
# 4. Anorexic parameters and file uploads are different then Rack - HTML Form code might be incompatible!
#    This MIGHT BREAKE YOUR CODE! (changing this requires Anorexic to re-parse the HTML, and costs in performance).
#
# also, all Anorexic server specific configuration will be ignored.
#
# on the other hand, there is an upside:
#
# 1. you can choose a well tested server written in C that might (or might not) bring a performance boost.
#
# 2. you have better control over Middleware then you could have with Anorexic.
# ("wait", you might say, "there is no Middleware in Anorexic!"... "Ahhh", I will answer, "so much to discover...")


working_dir = ::File.expand_path(Dir.pwd)
app_path = ::File.expand_path(File.join(".."),  __FILE__)
app_file_name = app_path.split(/[\\\/]/).last + ".rb"

# # make sure anorexic doesn't set up sockets nor starts the event cycle.
ANOREXIC_ON_RACK = true

#load the Anorexic application file
Dir.chdir app_path
require File.join(app_path, app_file_name)

Dir.chdir working_dir

run Anorexic
