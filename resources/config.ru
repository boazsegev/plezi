########################
# RackServer rack interface
#
# this file is okay for web apps that have only one servive running
# (called `listen` only once)
#
# otherwise:
#
# this WILL limit your controll over the app.
# this WILL limit anorexic features (no multiple services)
#
# This file is used by Rack-based servers to start the application.
#
# the rack servers will start only one process when using this file!
#
# since Anorexic is a multi-service framework, only the first service will start.
#
# also, all server specific configuration will be ignored (you'll need to move specification up stream, some to this file).
#
# move this file to the root folder of the app, in order to enable loding through rack.

working_dir = ::File.expand_path(Dir.pwd)
app_path = ::File.expand_path(File.join(".."),  __FILE__)
app_file_name = app_path.split(/[\\/]/).last + ".rb"

# make sure anorexic doesn't auto-start on end of script, as it normally would
NO_ANOREXIC_AUTO_START = true

Dir.chdir app_path
require File.join(app_path, app_file_name)

Dir.chdir working_dir

first_server = Anorexic::Application.instance.servers[0]

run first_server.make_server_paramaters[:app]
