module Plezi
   module Controller
      # this module extends the controller class with Plezi functions
      module ClassMethods
         # A Ruby callback used to initialize class data for new Controllers.
         def self.extended(base)
            base._pl_init_class_data
         end

         # Returns a relative URL for the controller, placing the requested parameters in the URL (inline, where possible and as query data when not possible).
         def url_for(func, params = {})
            ::Plezi::Base::Router.url_for self, func, params
         end

         # Invokes a method on the `target` websocket connection. When using Iodine, the method is invoked asynchronously.
         #
         #        self.unicast target, :my_method, "argument 1"
         #
         # Methods invoked using {unicast}, {broadcast} or {multicast} will quitely fail if the connection was lost, the requested method is undefined or the 'target' was invalid.
         def unicast(target, event_method, *args)
            ::Plezi::Base::MessageDispatch.unicast(self, target, event_method, args)
         end

         # Invokes a method on every websocket connection that belongs to this Controller / Type. When using Iodine, the method is invoked asynchronously.
         #
         #        self.broadcast :my_method, "argument 1", "argument 2", 3
         #
         # Methods invoked using {unicast}, {broadcast} or {multicast} will quitely fail if the connection was lost, the requested method is undefined or the 'target' was invalid.
         def broadcast(event_method, *args)
            ::Plezi::Base::MessageDispatch.broadcast(self, event_method, args)
         end

         # Invokes a method on every websocket connection in the application.
         #
         #        self.multicast :my_method, "argument 1", "argument 2", 3
         #
         # Methods invoked using {unicast}, {broadcast} or {multicast} will quitely fail if the connection was lost, the requested method is undefined or the 'target' was invalid.
         def multicast(event_method, *args)
            ::Plezi::Base::MessageDispatch.multicast(self, event_method, args)
         end

         # @private
         # This is used internally by Plezi, do not use.
         RESERVED_METHODS = [:delete, :create, :update, :new, :show, :pre_connect, :on_open, :on_close, :on_shutdown, :on_message].freeze
         # @private
         # This function is used internally by Plezi, do not call.
         def _pl_get_map
            return @_pl_get_map if @_pl_get_map

            @_pl_get_map = {}
            mths = public_instance_methods false
            mths.delete_if { |mthd| mthd.to_s[0] == '_' || !(-1..0).cover?(instance_method(mthd).arity) }
            @_pl_get_map[nil] = :index if mths.include?(:index)
            RESERVED_METHODS.each { |mthd| mths.delete mthd }
            mths.each { |mthd| @_pl_get_map[mthd.to_s.freeze] = mthd }

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
         def _pl_has_new
            @_pl_has_new
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
         def _pl_is_ad?
            @auto_dispatch
         end

         # @private
         # This function is used internally by Plezi, do not call.
         def _pl_ws_map
            return @_pl_ws_map if @_pl_ws_map

            @_pl_ws_map = {}
            mths = instance_methods false
            mths.delete :index
            RESERVED_METHODS.each { |mthd| mths.delete mthd }
            mths.each { |mthd| @_pl_ws_map[mthd.to_s.freeze] = mthd; @_pl_ws_map[mthd] = mthd }

            @_pl_ws_map
         end

         # @private
         # This function is used internally by Plezi, do not call.
         def _pl_ad_map
            return @_pl_ad_map if @_pl_ad_map

            @_pl_ad_map = {}
            mths = public_instance_methods false
            mths.delete_if { |m| m.to_s[0] == '_' || ![-2, -1, 1].freeze.include?(instance_method(m).arity) }
            mths.delete :index
            RESERVED_METHODS.each { |m| mths.delete m }
            mths.each { |m| @_pl_ad_map[m.to_s.freeze] = m; @_pl_ad_map[m] = m }

            @_pl_ad_map
         end

         # @private
         # This function is used internally by Plezi, do not call.
         def _pl_params2method(params, env)
            par_id = params['id'.freeze]
            meth_id = _pl_get_map[par_id]
            return meth_id if par_id && meth_id
            # puts "matching against #{params}"
            case params['_method'.freeze]
            when :get # since this is common, it's pushed upwards.
               if env['HTTP_UPGRADE'.freeze] && _pl_is_websocket? && env['HTTP_UPGRADE'.freeze].downcase.start_with?('websocket'.freeze)
                  @_pl_init_global_data ||= ::Plezi.plezi_initialize # wake up pub/sub drivers in case of `fork`
                  return :preform_upgrade
               end
               return :new if _pl_has_new && par_id == 'new'.freeze
               return meth_id || (_pl_has_show && :show) || nil
            when :put, :patch
               return :create if _pl_has_create && (par_id.nil? || par_id == 'new'.freeze)
               return :update if _pl_has_update
            when :post
               return :create if _pl_has_create
            when :delete
               return :delete if _pl_has_delete
            end
            meth_id || (_pl_has_show && :show) || nil
         end

         # @private
         # This function is used internally by Plezi, do not call.
         def _pl_init_class_data
            @auto_dispatch ||= nil
            @_pl_get_map = @_pl_ad_map = @_pl_ws_map = nil
            @_pl_has_show = public_instance_methods(false).include?(:show)
            @_pl_has_new = public_instance_methods(false).include?(:new)
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
