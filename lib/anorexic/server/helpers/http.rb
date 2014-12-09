# encoding: UTF-8



module Anorexic

	# includes general helper methods for HTTP protocol and related (url encoding etc')
	module HTTP
		module_function
		# decode html form data stream
		# def decode_form_data encoded
		# 	scanner = StringScanner.new encoded.gsub('+', '%20')
		# 	decoded = ''
		# 	until scanner.eos? do
		# 		decoded << scanner.scan(/[^%]+/)
		# 		if scanner.scan(/\%[0-9a-fA-F][0-9a-fA-F]/)
		# 			decoded << scanner.matched[1,2].to_i(16).chr
		# 		elsif !scanner.eos?
		# 			decoded << scanner.scan(/./)
		# 		end
		# 	end
		# 	decoded
		# end
		# # encode html form data stream
		# def encode_form_data exposed
		# 	scanner = StringScanner.new exposed
		# 	encoded = ''

		# 	# HTML form encoding
		# 	until scanner.eos? do
		# 		encoded << scanner.scan(/[a-zA-Z0-9\*\.\_\-]+/)				
		# 		encoded << "%#{scanner.matched.ord <= 16 ? "0" : ""} #{ scanner.matched.ord.to_s(16) }" if scanner.scan(/./)
		# 	end

		# 	# HTTP encoding
		# 	# until scanner.eos? do
		# 	# 	encoded << scanner.scan(/[^\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=]+/)
		# 	# 	encoded << "%#{scanner.matched.ord <= 16 ? "0" : ""} #{ scanner.matched.ord.to_s(16) }" if scanner.scan(/./)
		# 	# end
		# 	encoded
		# end
		# # decode HTTP URI data stream
		# def decode_uri encoded
		# 	scanner = StringScanner.new encoded.gsub('+', '%20') #? is this true here?
		# 	decoded = ''
		# 	until scanner.eos? do
		# 		decoded << scanner.scan(/[^%]+/)
		# 		if scanner.scan(/\%[0-9a-fA-F][0-9a-fA-F]/)
		# 			decoded << scanner.matched[1,2].to_i(16).chr
		# 		elsif !scanner.eos?
		# 			decoded << scanner.scan(/./)
		# 		end
		# 	end
		# 	decoded
		# end
		# # encode HTTP URI data stream
		# def encode_uri_data exposed
		# 	scanner = StringScanner.new exposed
		# 	encoded = ''
		# 	until scanner.eos? do
		# 		encoded << scanner.scan(/[^\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=]+/)
		# 		encoded << "%#{scanner.matched.ord <= 16 ? "0" : ""} #{ scanner.matched.ord.to_s(16) }" if scanner.scan(/.|[\s]/)
		# 	end
		# 	encoded
		# end

		# Based on the WEBRick source code, escapes &, ", > and < in a String object
		def escape(string)
			string.gsub(/&/n, '&amp;')
			.gsub(/\"/n, '&quot;')
			.gsub(/>/n, '&gt;')
			.gsub(/</n, '&lt;')
		end
		def add_param_to_hash param_name, param_value, target_hash
			begin
				a = target_hash
				p = param_name.gsub(']',' ').split(/\[/)
				p.each_index { |i| n = p[i].strip.to_sym; p[i+1] ? [ ( a[n] ||= ( p[i+1] == ' ' ? [] : {} ) ), ( a = a[n]) ] : (a.is_a?(Hash) ? [(a[n]? (a[n].is_a?(String)? (a[n] = [a[n]]) : true) : a[n]=''), (a=a[n])] : [(a << ''), (a = a.last)]) }
				a << param_value
			rescue Exception => e
				Anorexic.error e
				Anorexic.error "(Silent): paramaters parse error for #{param_name} ... maybe conflicts with a different set?"
				target_hash[param_name] = make_utf8! param_value
			end
		end

		def decode object, decode_method = :form
			if object.is_a?(Hash)
				object.values.each {|v| decode v, decode_method}
			elsif object.is_a?(Array)
				object.each {|v| decode v, decode_method}
			elsif object.is_a?(String)
				case decode_method
				when :form
					object.gsub!('+', '%20')
					object.gsub!(/\%[0-9a-fA-F][0-9a-fA-F]/) {|m| m[1..2].to_i(16).chr}					
				when :uri, :url
					object.gsub!(/\%[0-9a-fA-F][0-9a-fA-F]/) {|m| m[1..2].to_i(16).chr}
				when :html
					object.gsub!(/&amp;/i, '&')
					object.gsub!(/&quot;/i, '"')
					object.gsub!(/&gt;/i, ">")
					object.gsub!(/&lt;/i, "<")
				when :utf8

				else

				end
				object.gsub!(/&#([0-9a-fA-F]{2});/) {|m| m.match(/[0-9a-fA-F]{2}/)[0].hex.chr}
				object.gsub!(/&#([0-9]{4});/) {|m| [m.match(/[0-9]+/)[0].to_i].pack 'U'}
				make_utf8! object
				return object
			elsif object.is_a?(Symbol)
				str = object.to_str
				decode str, decode_method
				return str.to_sym
			else
				raise "Anorexic Raising Hell (don't misuse us)!"
			end
		end
		def encode object, decode_method = :form
			if object.is_a?(Hash)
				object.values.each {|v| encode v, decode_method}
			elsif object.is_a?(Array)
				object.each {|v| encode v, decode_method}
			elsif object.is_a?(String)
				case decode_method
				when :uri, :url, :form
					object.gsub!(/[^a-zA-Z0-9\*\.\_\-]/) {|m| m.ord <= 16 ? "%0#{m.ord.to_s(16)}" : "%#{m.ord.to_s(16)}"}
				when :html
					object.gsub!('&', "&amp;")
					object.gsub!('"', "&quot;")
					object.gsub!(">", "&gt;")
					object.gsub!("<", "&lt;")
					object.gsub!(/[^\sa-zA-Z\d\&\;]/) {|m| "&#%04d;" % m.unpack('U')[0] }
					# object.gsub!(/[^\s]/) {|m| "&#%04d;" % m.unpack('U')[0] }
				when :utf8
					object.gsub!(/[^\sa-zA-Z\d]/) {|m| "&#%04d;" % m.unpack('U')[0] }
				else

				end
				return object
			elsif object.is_a?(Symbol)
				str = object.to_str
				encode str, decode_method
				return str.to_sym
			else
				raise "Anorexic Raising Hell (don't misuse us)!"
			end
		end
		# extracts parameters from the query
		def extract_data data, target_hash, decode = :form
			data.each do |set|
				list = set.split('=')
				list.each {|s| HTTP.decode s, decode if s}
				add_param_to_hash list.shift, list.join('='), target_hash
			end
		end

		# re-encodes a string into UTF-8
		def make_utf8!(string, encoding= 'utf-8')
			return false unless string
			string.force_encoding("binary").encode!(encoding, "binary", invalid: :replace, undef: :replace, replace: '') unless string.force_encoding(encoding).valid_encoding?
			string
		end


	end
end
