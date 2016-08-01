require 'route'
require 'rack'

module Plezi
  module Base
    module Router
      @routes = []
      def self.call(env)
        request = Rack::Request.new(env)
        response = Rack::Response.new
        ret = nil
        @routes.each do |route|
          ret = route.call(request, response)
          break if ret
        end
        if !ret
          return [404, {}, []]
        elsif ret.is_a?(String)
          response.write ret
        end
        return response.finish
      rescue
        return [500, {}, []]
      end
    end
  end
end
