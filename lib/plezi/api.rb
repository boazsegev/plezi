require 'plezi/autostart'
require 'plezi/router/router'

module Plezi
  module_function

  # Disables the autostart feature
  def no_autostart
    @plezi_autostart = false
  end

  # Returns the Plezi Rack application
  def app
    no_autostart
    puts "Plezi version: #{::Plezi::VERSION}"
    Plezi::Base::Router.method :call
  end

  # Will add a route to the Plezi application
  def route(path, controller)
    set_autostart
    Plezi::Base::Router.route path, controller
  end

  # Will make a weak attempt to retrive a string representing a valid URL for the requested Controller's function.
  # False positives (invalid URL strings) are possible (i.e., when requesting a URL of a method that doesn't exist).
  def url_for(controller, method_sym, params = {})
    Plezi::Base::Router.url_for controller, method_sym, params
  end
end
