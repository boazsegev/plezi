# Default Rack interface

# load the application
load ::File.expand_path(File.join('..', 'appname.rb'), __FILE__)

Iodine::Rack.public ||= './public'

run Plezi.app
