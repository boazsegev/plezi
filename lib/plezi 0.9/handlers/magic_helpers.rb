module Plezi

	# set magic cookies
	#
	# magic cookies keep track of both incoming and outgoing cookies, setting the response's cookies as well as the combined cookie respetory (held by the request object).
	#
	# use only the []= for magic cookies. merge and update might not set the response cookies.
	class Cookies < ::Hash
		# sets the Magic Cookie's controller object (which holds the response object and it's `set_cookie` method).
		def set_controller controller
			@controller = controller
		end
		# overrides the []= method to set the cookie for the response (by encoding it and preparing it to be sent), as well as to save the cookie in the combined cookie jar (unencoded and available).
		def []= key, val
			if key.is_a?(Symbol) && self.has_key?( key.to_s)
				key = key.to_s
			elsif self.has_key?( key.to_s.to_sym)
				key = key.to_s.to_sym
			end
			@controller.response.set_cookie key, (val ? val.to_s.dup : nil) if @controller
			super
		end
	end

	module Helpers
		# a proc that allows Hashes to search for key-value pairs while also converting keys from objects to symbols and from symbols to strings.
		#
		# (key type agnostic search Hash proc)
		 HASH_SYM_PROC = Proc.new {|h,k| k = (Symbol === k ? k.to_s : k.to_s.to_sym); h[k] if h.has_key?(k) }
	end

end
