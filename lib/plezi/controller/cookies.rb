module Plezi
  module Controller
    class Cookies < Hash
      attr_reader :request, :response
      def initialize(request, response)
        @request = request
        @response = response
      end

      def[](key)
        if key.is_a? Symbol
          super(key) || super(key.to_s) || @request.cookies[key] || @request.cookies[key.to_s]
        elsif key.is_a? String
          super(key) || super(key.to_sym) || @request.cookies[key] || @request.cookies[key.to_sym]
        else
          super(key) || @request.cookies[key]
        end
      end

      def[]=(key, value)
        if value.nil?
          @response.delete_cookie key
          delete key
          if key.is_a? Symbol
            delete key.to_s
          elsif key.is_a? String
            delete key.to_sym
          end
          return nil
        end
        @response.set_cookie key, value
        value = value[:value] if value.is_a? Hash
        super
      end
    end
  end
end
