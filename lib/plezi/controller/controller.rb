module Plezi
  module Base
    module Controller
      def self.included(base)
        base.extend ::Plezi::Base::Controller::ClassMethods
        base._pl_init_class_data
      end

      attr_reader :request, :response, :params

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

      module ClassMethods
        REST_METHODS = [:delete, :create, :update, :show].freeze
        def _pl_get_map
          return @_pl_get_map if @_pl_get_map

          @_pl_get_map = {}
          mths = public_instance_methods false
          mths.delete_if { |m| instance_method(m).arity.abs > 0 }
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
      end
    end
  end
end
