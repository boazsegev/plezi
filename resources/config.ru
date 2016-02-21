# prevent auto-start in case we're running the application with a different server (no websockets)
NO_PLEZI_AUTOSTART = true
# set the working directory
Dir.chdir ::File.expand_path(File.join(__FILE__, ".."))
# load the website-app
load ::File.expand_path(File.join("..", "appname.rb"),  __FILE__)
# load Rack application
run Plezi.app
