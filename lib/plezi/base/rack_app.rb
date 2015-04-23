
module Plezi

	# Rack application model support
	module_function

	# todo: move falsh into the special cookie class...?
	

	# Plezi dresses up for Rack - this is a watered down version missing some features (such as flash and WebSockets).
	# a full featured Plezi app, with WebSockets, requires the use of the Plezi server
	# (the built-in server)
	def call env
		raise "No Plezi Services" unless Plezi::SERVICES[0]
		Object.const_set('PLEZI_ON_RACK', true) unless defined? PLEZI_ON_RACK

		# re-encode to utf-8, as it's all BINARY encoding at first
		env['rack.input'].rewind
		env['rack.input'] = StringIO.new env['rack.input'].read.encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '')		 	
		env.each do |k, v|
			if k.to_s.match /^[A-Z]/
				if v.is_a?(String) && !v.frozen?
					v.force_encoding('binary').encode!('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless v.force_encoding('utf-8').valid_encoding?
				end
			end
		end
		# re-key params
		# new_params = {}
		# env[:params].each {|k,v| HTTP.add_param_to_hash k, v, new_params}
		# env[:params] = new_params

		# make hashes magical
		make_hash_accept_symbols(env)

		# use Plezi Cookies
		env['rack.request.cookie_string'] = env['HTTP_COOKIE']
		env['rack.request.cookie_hash'] = Plezi::Cookies.new.update(env['rack.request.cookie_hash'] || {})

		# chomp path
		env['PATH_INFO'].chomp! '/'

		# get response
		response = Plezi::SERVICES[0][1][:handler].call env

		return response if response.is_a?(Array)

		response.finish
		response.fix_headers
		headers = response.headers
		# set cookie headers
		headers.delete 'transfer-encoding'
		headers.delete 'connection'
		unless response.cookies.empty?
			headers['Set-Cookie'] = []
			response.cookies.each {|k,v| headers['Set-Cookie'] << ("#{k.to_s}=#{v.to_s}")}
		end
		[response.status, headers, response.body]
	end
end

# # rack code to set cookie headers
# # File actionpack/lib/action_controller/vendor/rack-1.0/rack/response.rb, line 56
#     def set_cookie(key, value)
#       case value
#       when Hash
#         domain  = "; domain="  + value[:domain]    if value[:domain]
#         path    = "; path="    + value[:path]      if value[:path]
#         # According to RFC 2109, we need dashes here.
#         # N.B.: cgi.rb uses spaces...
#         expires = "; expires=" + value[:expires].clone.gmtime.
#           strftime("%a, %d-%b-%Y %H:%M:%S GMT")    if value[:expires]
#         secure = "; secure"  if value[:secure]
#         httponly = "; HttpOnly" if value[:httponly]
#         value = value[:value]
#       end
#       value = [value]  unless Array === value
#       cookie = Utils.escape(key) + "=" +
#         value.map { |v| Utils.escape v }.join("&") +
#         "#{domain}#{path}#{expires}#{secure}#{httponly}"

#       case self["Set-Cookie"]
#       when Array
#         self["Set-Cookie"] << cookie
#       when String
#         self["Set-Cookie"] = [self["Set-Cookie"], cookie]
#       when nil
#         self["Set-Cookie"] = cookie
#       end
#     end