module Plezi

	# use GRHttp's helpers for escaping data etc'.
	HTTP = GRHttp::HTTP

	module Base
		# some helper methods used internally.
		module Helpers
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
	end

end
