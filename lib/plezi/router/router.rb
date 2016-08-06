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
      @app = nil

      module_function

      def new(app)
        puts 'Plezi as Middleware'
        @app = ((app == Plezi.app) ? nil : app)
        Plezi.app
      end

      def call(env)
        request = Rack::Request.new(env)
        response = Rack::Response.new
        ret = nil
        @routes.each { |route| ret = route.call(request, response); break if ret }
        unless ret
          return @app.call(env) if @app
          ret = ::Plezi::Base::Err404Ctrl.new._pl_respond(request, response, @empty_hashes.clear)
        end
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
        url = '/'.dup
        @routes.each do |tmp|
          case tmp.controller
          when Class
            next if tmp.controller != controller
            r = tmp
            break
          when Regexp
            nm = nil
            nm = tmp.param_names[0] if params[tmp.param_names[0]]
            nm ||= tmp.param_names[0].to_sym
            url << "#{params.delete nm}/" if params[nm] && params[nm].to_s =~ tmp.controller
          else
            next
          end
        end
        return nil if r.nil?
        case method_sym.to_sym
        when :new
          params.delete :id
          params.delete :_method
          params.delete '_method'.freeze
          params['id'.freeze] = :new
        when :create
          params['id'.freeze] = :new
          params.delete :id
          params['_method'.freeze] = :post
          params.delete :_method
        when :update
          params.delete :_method
          params['_method'.freeze] = :put
        when :delete
          params.delete :_method
          params['_method'.freeze] = :delete
        when :index
          params.delete 'id'.freeze
          params.delete '_method'.freeze
          params.delete :id
          params.delete :_method
        when :show
          raise "The URL for ':show' MUST contain a valid 'id' parameter for the object's index to display." unless params['id'.freeze].nil? && params[:id].nil?
          params.delete '_method'.freeze
          params.delete :_method
        else
          params.delete :id
          params['id'.freeze] = method_sym
        end
        names = r.param_names
        url.chomp! '/'.freeze
        url << r.prefix
        url.clear if url == '/'.freeze
        while names.any? && params[name[0]]
          url << "/#{Rack::Utils.escape params[names.shift]}"
        end
        url = '/'.dup if url.empty?
        (url << '?') << Rack::Utils.build_nested_query(params) if params.any?
        url
      end
    end
  end
end
