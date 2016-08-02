require 'plezi/router/route'
require 'rack'

module Plezi
  module Base
    module Router
      @routes = []

      module_function

      def call(env)
        request = Rack::Request.new(env)
        response = Rack::Response.new
        ret = nil
        @routes.each { |route| ret = route.call(request, response); break if ret }
        return [404, {}, []] unless ret
        response.write(ret) if ret.is_a?(String)
        return response.finish
      rescue
        return [500, {}, []]
      end

      def route(path, controller)
        @routes << Route.new(path, controller)
      end

      def list
        @routes
      end

      def url_for(controller, method_sym, params = {})
        # GET,PUT,POST,DELETE
        r = nil
        @routes.each { |tmp| next if tmp.controller != controller; r = tmp; break; }
        case method_sym.to_sym
        when :new
          params['id'.freeze] = :new
          params['_method'.freeze] = :post
        when :update
          params['_method'.freeze] = :put
        when :delete
          params['_method'.freeze] = :delete
        when :index
          params['id'.freeze] = nil
          params['_method'.freeze] = :get
        when :show
          raise "The URL for ':show' MUST contain a valid 'id' parameter for the object's index to display." unless params['id'.freeze].nil? && params[:id].nil?
          params['_method'.freeze] = :get
        else
          params['id'.freeze] = method_sym
        end
        r.prefix + Rack::Utils.build_nested_query(params)
      end
    end
  end
end
