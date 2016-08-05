require 'plezi/router/route'
require 'plezi/router/errors'
require 'plezi/router/assets'
require 'plezi/router/adclient'
require 'rack'

module Plezi
  module Base
    module Router
      @routes = []
      @empty_hashes = {}

      module_function

      def call(env)
        request = Rack::Request.new(env)
        response = Rack::Response.new
        ret = nil
        @routes.each { |route| ret = route.call(request, response); break if ret }
        ret ||= ::Plezi::Base::Err404Ctrl.new._pl_respond(request, response, @empty_hashes.clear)
        response.write(ret) if ret.is_a?(String)
        return response.finish
      rescue => e
        puts e.message, e.backtrace
        response = Rack::Response.new
        response.write ::Plezi::Base::Err500Ctrl.new._pl_respond(request, response, @empty_hashes.clear)
        return response.finish
      end

      def route(path, controller)
        case controller
        when :client
          controller = ::Plezi::Base::Router::ADClient
        when :assets
          controller = ::Plezi::Base::Assets
          path << '/*'.freeze unless path[-1] == '*'.freeze
        when Regexp
          path << '/*'.freeze unless path[-1] == '*'.freeze
        end
        @routes << Route.new(path, controller)
      end

      def list
        @routes
      end

      def url_for(controller, method_sym, params = {})
        # GET,PUT,POST,DELETE
        r = nil
        prefix = '/'.dup
        @routes.each do |tmp|
          case tmp.controller
          when Class
            next if tmp.controller != controller
            r = tmp
            break
          when Regexp
            prefix << "#{params.delete tmp.param_names[0]}/" if params[tmp.param_names[0]]
          else
            next
          end
        end
        return nil if r.nil?
        case method_sym.to_sym
        when :new
          params['id'.freeze] = :new
          params.delete '_method'.freeze
        when :create
          params['id'.freeze] = :new
          params['_method'.freeze] = :post
        when :update
          params['_method'.freeze] = :put
        when :delete
          params['_method'.freeze] = :delete
        when :index
          params.delete 'id'.freeze
          params.delete '_method'.freeze
        when :show
          raise "The URL for ':show' MUST contain a valid 'id' parameter for the object's index to display." unless params['id'.freeze].nil? && params[:id].nil?
          params['_method'.freeze] = :get
        else
          params['id'.freeze] = method_sym
        end
        names = r.param_names
        tmp = r.prefix.dup
        tmp.clear if tmp == '/'.freeze
        while names.any? && params[name[0]]
          tmp << "/#{Rack::Utils.escape params[names.shift]}"
        end
        tmp = '/'.freeze if tmp.empty?
        tmp + Rack::Utils.build_nested_query(params)
      end
    end
  end
end
