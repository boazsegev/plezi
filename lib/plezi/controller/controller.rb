require 'plezi/render/render'

module Plezi
  module Base
    module Controller
      def self.included(base)
        base.extend ::Plezi::Base::Controller::ClassMethods
        base._pl_init_class_data
      end

      attr_reader :request, :response, :params, :uuid

      def _pl_respond(request, response, params)
        @request = request
        @response = response
        @params = params
        m = requested_method
        # puts "m == #{m.nil? ? 'nil' : m.to_s}"
        return __send__(m) if m
        false
      end

      def requested_method
        params['_method'.freeze] = (params['_method'.freeze] || request.request_method.downcase).to_sym
        self.class._pl_params2method params
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
        ret = nil
        if params['format'.freeze]
          ret = ::Plezi::Renderer.render "#{File.join(::Plezi.templates, template.to_s)}.#{params['format'.freeze]}", binding, &block
          return ret if ret
        end
        ::Plezi::Renderer.render "#{File.join(::Plezi.templates, template.to_s)}.html", binding, &block if params['format'.freeze] != 'html'.freeze
      end

      # A connection's Plezi ID uniquely identifies the connection across application instances, allowing it to receieve and send messages using {#unicast}.
      def id
        @_pl_id ||= "#{::Plezi::Base::MessageDispatch.uuid}-#{uuid.to_s(16)}"
      end

      def unicast(target, method, *args)
        target
        method
        args
      end

      def broadcast(method, *args)
        method
        args
      end

      def multicast(method, *args)
        method
        args
      end

      module ClassMethods
        REST_METHODS = [:delete, :create, :update, :show].freeze
        def _pl_get_map
          return @_pl_get_map if @_pl_get_map

          @_pl_get_map = {}
          mths = public_instance_methods false
          mths.delete_if { |m| m.to_s[0] == '_' || instance_method(m).arity.abs > 0 }
          @_pl_get_map[nil] = :index if mths.include?(:index)
          REST_METHODS.each { |m| mths.delete m }
          mths.each { |m| @_pl_get_map[m.to_s.freeze] = m }

          @_pl_get_map
        end

        def _pl_has_delete
          @_pl_has_delete
        end

        def _pl_has_update
          @_pl_has_update
        end

        def _pl_has_create
          @_pl_has_create
        end

        def _pl_has_show
          @_pl_has_show
        end

        def _pl_ws_map
          return @_pl_ws_map if @_pl_ws_map

          @_pl_ws_map = {}
          mths = instance_methods false
          mths.delete :new
          mths.delete :index
          REST_METHODS.each { |m| mths.delete m }
          mths.each { |m| @_pl_ws_map[m.to_s.freeze] = m; _pl_ws_map[m] = m }

          @_pl_ws_map
        end

        def _pl_ad_map
          return @_pl_ad_map if @_pl_ad_map

          @_pl_ad_map = {}
          mths = public_instance_methods false
          mths.delete_if { |m| m.to_s[0] == '_' || instance_method(m).arity.abs < 1 }
          REST_METHODS.each { |m| mths.delete m }
          mths.each { |m| @_pl_ws_map[m.to_s.freeze] = m; _pl_ws_map[m] = m }

          @_pl_ad_map
        end

        def _pl_params2method(params)
          # puts "matching against #{params}"
          case params['_method'.freeze]
          when :get # since this is common, it's pushed upwards.
            return (_pl_get_map[params['id'.freeze]] || (_pl_has_show && :show) || nil)
          when :put, :patch
            return :create if _pl_has_create && (params['id'.freeze].nil? || params['id'.freeze] == 'new')
            return :update if _pl_has_update
          when :post
            return :create if _pl_has_create
          when :delete
            return :delete if _pl_has_delete
          end
          (_pl_get_map[params['id'.freeze]] || (_pl_has_show && :show) || nil)
        end

        def _pl_init_class_data
          @_pl_get_map = nil
          @_pl_has_show = public_instance_methods.include?(:show)
          @_pl_has_create = public_instance_methods.include?(:create)
          @_pl_has_update = public_instance_methods.include?(:update)
          @_pl_has_delete = public_instance_methods.include?(:delete)
          _pl_get_map
          _pl_has_delete
          _pl_has_update
          _pl_has_create
          _pl_has_show
        end

        def url_for(func, params = {})
          ::Plezi::Base::Router.url_for self, func, params
        end
      end
    end
  end
end
