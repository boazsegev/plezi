module Plezi

	module Base
		# some helper methods used internally.
		module Helpers
			# a proc that allows Hashes to search for key-value pairs while also converting keys from objects to symbols and from symbols to strings.
			#
			# (key type agnostic search Hash proc)
			 HASH_SYM_PROC = Proc.new {|h,k| k = (Symbol === k ? k.to_s : k.to_s.to_sym); h[k] if h.has_key?(k) }

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

			# encodes URL data
			def self.encode_url str
				(str.to_s.gsub(/[^a-z0-9\*\.\_\-]/i) {|m| '%%%02x'.freeze % m.ord }).force_encoding(::Encoding::ASCII_8BIT)
			end

			# Adds paramaters to a Hash object, according to the Iodine's server conventions.
			def self.add_param_to_hash name, value, target
				begin
					c = target
					val = rubyfy! value
					a = name.chomp('[]'.freeze).split('['.freeze)

					a[0...-1].inject(target) do |h, n|
						n.chomp!(']'.freeze);
						n.strip!;
						raise "malformed parameter name for #{name}" if n.empty?
						n = (n.to_i.to_s == n) ?  n.to_i : n.to_sym            
						c = (h[n] ||= {})
					end
					n = a.last
					n.chomp!(']'); n.strip!;
					n = n.empty? ? nil : ( (n.to_i.to_s == n) ?  n.to_i : n.to_sym )
					if n
						if c[n]
							c[n].is_a?(Array) ? (c[n] << val) : (c[n] = [c[n], val])
						else
							c[n] = val
						end
					else
						if c[n]
							c[n].is_a?(Array) ? (c[n] << val) : (c[n] = [c[n], val])
						else
							c[n] = [val]
						end
					end
					val
				rescue => e
					Iodine.error e
					Iodine.error "(Silent): parameters parse error for #{name} ... maybe conflicts with a different set?"
					target[name] = val
				end
			end
			# Changes String to a Ruby Object, if it's a special string...
			def self.rubyfy!(string)
				return string unless string.is_a?(String)
				try_utf8! string
				if string == 'true'.freeze
					string = true
				elsif string == 'false'.freeze
					string = false
				elsif string.to_i.to_s == string
					string = string.to_i
				end
				string
			end

			# re-encodes a string into UTF-8 unly when the encoding will remail valid.
			def self.try_utf8!(string, encoding= ::Encoding::UTF_8)
				return false unless string
				string.force_encoding(::Encoding::ASCII_8BIT) unless string.force_encoding(encoding).valid_encoding?
				string
			end


		end
	end

end
