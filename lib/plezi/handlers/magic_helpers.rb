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
			elsif key.is_a?(String) && self.has_key?( key.to_sym)
				key = key.to_sym
			end
			@controller.response.set_cookie key, (val ? val.dup : nil) if @controller
			super
		end
	end

	# tweeks a hash object to read both :symbols and strings (similar to Rails but without).
	def self.make_hash_accept_symbols hash
		@magic_hash_proc ||= Proc.new do |hs,k|
			if k.is_a?(Symbol) && hs.has_key?( k.to_s)
				hs[k.to_s]
			elsif k.is_a?(String) && hs.has_key?( k.to_sym)
				hs[k.to_sym]
			elsif k.is_a?(Numeric) && hs.has_key?(k.to_s.to_sym)
				hs[k.to_s.to_sym]
			end
		end
		hash.default_proc = @magic_hash_proc
		hash.values.each do |v|
			if v.is_a?(Hash)
				make_hash_accept_symbols v
			end
		end
	end


end
