require 'plezi/render/render'
require 'plezi/controller/controller_class'
require 'plezi/websockets/message_dispatch'

module Plezi
  module Controller
    def self.included(base)
      base.extend ::Plezi::Controller::ClassMethods
    end

    attr_reader :request, :response, :params, :uuid

    # @private
    # This function is used internally by Plezi, do not call.
    def _pl_respond(request, response, params)
      @request = request
      @response = response
      @params = params
      m = requested_method
      # puts "m == #{m.nil? ? 'nil' : m.to_s}"
      return __send__(m) if m
      false
    end

    # Returns the method that was called by the HTTP request. For Websocket connections this method is most likely to return :preform_upgrade
    def requested_method
      params['_method'.freeze] = (params['_method'.freeze] || request.request_method.downcase).to_sym
      self.class._pl_params2method(params, request.env)
    end

    # Renders the requested template (should be a string, subfolders are fine).
    #
    # Template name shouldn't include the template's extension or format - this allows for dynamic format template resolution, so that `json` and `html` requests can share the same code. i.e.
    #
    #       Plezi.templates = "views/"
    #       render "users/index"
    #
    # Using layouts (nested templates) is easy by using a block (a little different then other frameworks):
    #
    #       render("users/layout") { render "users/index" }
    #
    def render(template, &block)
      return ::Plezi::Renderer.render "#{File.join(::Plezi.templates, template.to_s)}.#{params['format'.freeze]}", binding, &block if params['format'.freeze]
      ::Plezi::Renderer.render "#{File.join(::Plezi.templates, template.to_s)}.html", binding, &block
    end

    # A connection's Plezi ID uniquely identifies the connection across application instances, allowing it to receieve and send messages using {#unicast}.
    def id
      @_pl_id ||= (uuid && "#{::Plezi::Base::MessageDispatch.pid}-#{uuid.to_s(16)}")
    end

    # @private
    # This is the process specific Websocket's UUID. This function is here to protect you from yourself. Don't call it.
    def uuid
      defined?(super) && super
    end

    # Override this method to read / write cookies, perform authentication or perform validation before establishing a Websocket connecion.
    #
    # Return `false` or `nil` to refuse the websocket connection.
    def pre_connect
      true
    end

    # Experimental: Adopts a module to be used for Websocket callbacks events (listenning, not sending).
    #
    # This function can only be called **after** a websocket connection was established (i.e., within the `on_open` callback).
    #
    # This allows a module "library" to be used similar to the way "rooms" are used in node.js, so that a number of different Controllers can listen to shared events.
    #
    # By adopting a module into this instance, dynamically, Websocket broadcasts will invoke the module's functions.
    def adopt(mod)
      raise TypeError, '`mod` should be a module' unless mod.class == Module
      class << self
        mod.extend ::Plezi::Base::Controller::ClassMethods
        extend mod
      end unless is_a? mod
      _pl_ws_map.update mod._pl_ws_map
      _pl_ad_map.update mod._pl_ad_map
    end

    # Invokes a method with another Websocket connection instance. i.e.
    #
    #       def perform_poke(target)
    #         unicast target, :poke, self.id
    #       end
    #       def poke(from)
    #         unicast from, :poke_back, self.id
    #       end
    #       def poke_back(from)
    #         puts "#{self.id} is available"
    #       end
    #
    def unicast(target, event_method, *args)
      ::Plezi::Base::MessageDispatch.unicast(id ? self : self.class, target, event_method, args)
    end

    def broadcast(event_method, *args)
      ::Plezi::Base::MessageDispatch.broadcast(id ? self : self.class, event_method, args)
    end

    def multicast(event_method, *args)
      ::Plezi::Base::MessageDispatch.multicast(id ? self : self.class, event_method, args)
    end

    # @private
    # This function is used internally by Plezi, do not call.
    def _pl_ws_map
      @_pl_ws_map ||= {}
    end

    # @private
    # This function is used internally by Plezi, do not call.
    def _pl_ad_map
      @_pl_ad_map ||= {}
    end

    private

    # @private
    # This function is used internally by Plezi, do not call.
    def preform_upgrade
      return false unless pre_connect
      request.env['iodine.websocket'.freeze] = self
      @_pl_ws_map = self.class._pl_ws_map.dup
      @_pl_ad_map = self.class._pl_ad_map.dup
      true
    end
  end
end
