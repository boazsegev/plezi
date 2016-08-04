require 'plezi/activation'
require 'plezi/helpers'
require 'plezi/router/router'

module Plezi
  class << self
    # Get / set the template folder for the {Controller#render} function.
    attr_accessor :templates
    # Get / set the assets folder for the `:assets` route (the root for `Plezi.route '/assets/path'`, :assets).
    attr_accessor :assets
    # Get / set the application name, which is also used to identify the global pub/sub channel.
    attr_accessor :app_name
  end
  @app_name = "#{File.basename($PROGRAM_NAME, '.*')}_app"
  @templates = File.expand_path(File.join(File.dirname($PROGRAM_NAME), 'views'.freeze))
  @assets = File.expand_path(File.join(File.dirname($PROGRAM_NAME), 'assets'.freeze))
  @plezi_autostart = nil

  module_function

  # Disables the autostart feature
  def no_autostart
    @plezi_autostart = false
  end

  # Returns the Plezi Rack application
  def app
    no_autostart
    puts "Running Plezi version: #{::Plezi::VERSION}"
    Plezi::Base::Router.method :call
  end

  # Will add a route to the Plezi application.
  #
  # path:: the HTTP path for the route. Inline parameters and optional parameters are supported. i.e.
  #
  #                Plezi.route '/fixed/path', controller
  #                Plezi.route '/fixed/path/:required_param/(:optional_param)', controller
  #                Plezi.route '*', controller # catch all
  #
  #
  # controller:: A Controller class or one of the included controllers: `false` for rewrite routes; `:client` for the Javascript Auto Dispatch client; `:assets` for a missing asset baker controller (bakes any unbaked assets into the public folder file).
  def route(path, controller)
    plezi_initialize
    Plezi::Base::Router.route path, controller
  end

  # Will make a weak attempt to retrive a string representing a valid URL for the requested Controller's function.
  # False positives (invalid URL strings) are possible (i.e., when requesting a URL of a method that doesn't exist).
  def url_for(controller, method_sym, params = {})
    Plezi::Base::Router.url_for controller, method_sym, params
  end
end
