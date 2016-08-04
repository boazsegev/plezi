require 'json'
module Plezi
  module Controller
    module ClassMethods
      def self.extended(base)
        base._pl_init_class_data
      end

      def url_for(func, params = {})
        ::Plezi::Base::Router.url_for self, func, params
      end

      def unicast(target, event_method, *args)
        ::Plezi::Base::MessageDispatch.unicast(self, target, event_method, args)
      end

      def broadcast(event_method, *args)
        ::Plezi::Base::MessageDispatch.broadcast(self, event_method, args)
      end

      def multicast(event_method, *args)
        ::Plezi::Base::MessageDispatch.multicast(self, event_method, args)
      end

      # @private
      # This is used internally by Plezi, do not use.
      RESERVED_METHODS = [:delete, :create, :update, :show, :pre_connect, :on_open, :on_close, :on_shutdown, :on_message].freeze
      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_get_map
        return @_pl_get_map if @_pl_get_map

        @_pl_get_map = {}
        mths = public_instance_methods false
        mths.delete_if { |m| m.to_s[0] == '_' || !(-1..0).cover?(instance_method(m).arity) }
        @_pl_get_map[nil] = :index if mths.include?(:index)
        RESERVED_METHODS.each { |m| mths.delete m }
        mths.each { |m| @_pl_get_map[m.to_s.freeze] = m }

        @_pl_get_map
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_has_delete
        @_pl_has_delete
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_has_update
        @_pl_has_update
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_has_create
        @_pl_has_create
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_has_show
        @_pl_has_show
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_is_websocket?
        @_pl_is_websocket
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_ws_map
        return @_pl_ws_map if @_pl_ws_map

        @_pl_ws_map = {}
        mths = instance_methods false
        mths.delete :new
        mths.delete :index
        RESERVED_METHODS.each { |m| mths.delete m }
        mths.each { |m| @_pl_ws_map[m.to_s.freeze] = m; @_pl_ws_map[m] = m }

        @_pl_ws_map
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_ad_map
        return @_pl_ad_map if @_pl_ad_map

        @_pl_ad_map = {}
        mths = public_instance_methods false
        mths.delete_if { |m| m.to_s[0] == '_' || ![-2, -1, 1].freeze.include?(instance_method(m).arity) }
        mths.delete :new
        mths.delete :index
        RESERVED_METHODS.each { |m| mths.delete m }
        mths.each { |m| @_pl_ad_map[m.to_s.freeze] = m; @_pl_ad_map[m] = m }

        @_pl_ad_map
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_params2method(params, env)
        # puts "matching against #{params}"
        case params['_method'.freeze]
        when :get # since this is common, it's pushed upwards.
          return :preform_upgrade if env['HTTP_UPGRADE'] && _pl_is_websocket? && env['HTTP_UPGRADE'].downcase.start_with?('websocket'.freeze)
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

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_init_class_data
        @_pl_get_map = nil
        @_pl_ad_map = nil
        @_pl_ws_map = nil
        @_pl_has_show = public_instance_methods(false).include?(:show)
        @_pl_has_create = public_instance_methods(false).include?(:create)
        @_pl_has_update = public_instance_methods(false).include?(:update)
        @_pl_has_delete = public_instance_methods(false).include?(:delete)
        @_pl_is_websocket = (instance_variable_defined?(:@auto_dispatch) && instance_variable_get(:@auto_dispatch)) || instance_methods(false).include?(:on_message)
        _pl_get_map
        _pl_ad_map
        _pl_ws_map
      end
    end
  end
end
