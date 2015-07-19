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
		end
	end

end
