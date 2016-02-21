
module Plezi
  module Base
    # a collection of global helper methods used as part of Plezi's core functionality.
    module Helpers
      # the Flash class handles flash cookies
      class Flash < ::Hash
        def initialize cookies, response
          super()
          @response = response
          cookies.each {|k, v|
            self[k] = v if k.to_s.start_with? 'magic_flash_'.freeze
            response.delete_cookie k
          }
        end
        # overrides the []= method to set the cookie for the response (by encoding it and preparing it to be sent), as well as to save the cookie in the combined cookie jar (unencoded and available).
				def []= key, val
					if key.is_a?(Symbol) && self.has_key?( key.to_s)
						key = key.to_s
            set_cookie key, val
					else
            @response.set_cookie "magic_flash_#{key.to_s}".freeze, val
						key = key.to_s.to_sym if self.has_key?( key.to_s.to_sym)
					end
					super

				end
				# overrides th [] method to allow Symbols and Strings to mix and match
				def [] key
					if key.is_a?(Symbol) && self.has_key?( key.to_s)
						key = key.to_s
					elsif self.has_key?( key.to_s.to_sym)
						key = key.to_s.to_sym
					elsif self.has_key? "magic_flash_#{key.to_s}".freeze
						key = "magic_flash_#{key.to_s}".freeze
					end
					super
				end
      end
      # Sets magic cookies - NOT part of the API.
			#
			# magic cookies keep track of both incoming and outgoing cookies, setting the response's cookies as well as the combined cookie respetory (held by the request object).
			#
			# use only the []= for magic cookies. merge and update might not set the response cookies.
			class Cookies
        def initialize cookies, response
          @response = response
          @data = cookies
        end
				# overrides the []= method to set the cookie for the response (by encoding it and preparing it to be sent), as well as to save the cookie in the combined cookie jar (unencoded and available).
				def []= key, val
					@response.set_cookie key, val
          @data[key] = val
				end
				# overrides th [] method to allow Symbols and Strings to mix and match
				def [] key
					@data[key] || request.cookies[key]
				end
        def each
          return @data.each {|k, v| yield(k,v) } if block_given?
          @data.each
        end
        def to_h
          @data
        end
			end

      # re-encodes a string into UTF-8 unly when the encoding will remail valid.
			def try_utf8!(string, encoding= ::Encoding::UTF_8)
				return string unless string.is_a?(String)
				string.force_encoding(::Encoding::ASCII_8BIT) unless string.force_encoding(encoding).valid_encoding?
				string
			end

      # encodes URL data
			def encode_url str
        ::URI.decode_www_form_component
				# (str.to_s.gsub(/[^a-z0-9\*\.\_\-]/i) {|m| '%%%02x'.freeze % m.ord }).force_encoding(::Encoding::ASCII_8BIT)
			end



      # a proc that allows Hashes to search for key-value pairs while also converting keys from objects to symbols and from symbols to strings.
			#
			# (key type agnostic search Hash proc)
			HASH_SYM_PROC = Proc.new {|h,k| k = (Symbol === k ? k.to_s : k.to_s.to_sym); h[k] if h.has_key?(k) }

			# tweeks a hash object to read both :symbols and strings (similar to Rails but without).
			def make_hash_accept_symbols hash
				@magic_hash_proc ||= Proc.new do |hs,k|
					if k.is_a?(Symbol) && hs.has_key?( k.to_s)
						hs[k.to_s]
					elsif k.is_a?(String) && hs.has_key?( k.to_sym)
						hs[k.to_sym]
          elsif k.is_a?(Numeric) && hs.has_key?(k.to_s)
						hs[k.to_s]
          elsif k.is_a?(Numeric) && hs.has_key?(k.to_s.to_sym)
						hs[k.to_s.to_sym]
          else
            nil
					end
				end
				hash.default_proc = @magic_hash_proc
				hash.values.each do |v|
					if v.is_a?(Hash)
						make_hash_accept_symbols v
					end
				end
			end

      extend self
    end
  end
end
