module Plezi
   module Controller
      # The cookie jar class. Controllers have an instance of this class named `cookies`.
      class Cookies < Hash
         attr_reader :request, :response
         def initialize(request, response)
            @request = request
            @response = response
         end

         # Reads a cookie from either the request cookie Hash or the new cookies Hash.
         def[](key)
            if key.is_a? Symbol
               super(key) || super(key.to_s) || @request.cookies[key] || @request.cookies[key.to_s]
            elsif key.is_a? String
               super(key) || super(key.to_sym) || @request.cookies[key] || @request.cookies[key.to_sym]
            else
               super(key) || @request.cookies[key]
            end
         end

         # Sets (or deletes) a cookie. New cookies are placed in the new cookie Hash and are accessible only to the controller that created them.
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
      # Writes a line dlimited string of all the existing and the new cookies. i.e.:
      #      name1=value1
      #      name2=value2
      def to_s
         (@request ? (to_a + request.cookies.to_a) : to_a).map! { |pair| pair.join('=') } .join "\n"
      end

      # Returns an array with all the keys of any available cookies (both existing and new cookies).
      def keys
         (@request ? (super + request.cookies.keys) : super)
      end

      # Returns an array with all the values of any available cookies (both existing and new cookies).
      def values
         (@request ? (super + request.cookies.values) : super)
      end
   end
end
