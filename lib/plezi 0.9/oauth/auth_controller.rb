



module Plezi

	#########################################
	# This is a social Authentication Controller for OAuth2 services.
	# This controller allows you to easily deploy Facebook Login, Google Login and any other OAuth2 complient login service.
	#
	# To include this controller in your application, you need to require it using:
	#
	#       require 'plezi/oauth'
	#
	# It is possible to manualy register any OAuth 2.0 authentication service using the `register_service` method:
	# 
	#           	register_service(:foo,
	#           			app_id: 'registered app id / client id',
	#           			app_secret: 'registered app secret / client secret',
	#           			auth_url: "https://foo.bar.com/o/oauth2/auth",
	#           			token_url: "https://foo.bar.com/oauth2/v3/token",
	#           			profile_url: "https://foo.bar/oauth2/v1/userinfo",
	#           			scope: "profile email")
	#
	# The `.register_service` method will be automatically called for the following login services:
	#
	# - Facebook authentication using the Graph API, v. 2.3 - [see Facebook documentation](https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/v2.3).
	# - Google authentication using the OAuth 2.0 API - [see Google documentation](https://developers.google.com/identity/protocols/OAuth2WebServer).
	#
	# To enjoy autorgistration for Facebook or Google, make sure the following environment variables are set:
	#       ENV['FB_APP_ID'] = {facebook_app_id}
	#       ENV['FB_APP_SECRET'] = {facebook_app_secret}
	#       ENV['GOOGLE_APP_ID'] = {google_app_id}
	#       ENV['GOOGLE_APP_SECRET'] = {google_app_secret}
	#
	# To add the OAuth routes to the routes, use the following short-cut method (add it to the `routes.rb`) file:
	#
	#       create_auth_shared_route do |service, remote_user_id, email, full_remote_response|	
	#          # perform any specific app authentication logic such as saving the info.
	#          # return the current user or false if the callback is called with an authentication failure.
	#       end
	#
	# \* Notice that, as always, route placement order effects behavior, so that routes are checked according to order of creation.
	#
	# The `create_auth_shared_route` method is a shortcut taht calls the `#shared_route` method with the relevant arguments and sets the OAuth2Ctrl callback.
	#
	# Use the following links for social authentication:
	#
	# - Facebook: "/auth/facebook"
	# - Google: "/auth/google"
	# - foo_service: "/auth/foo_service"
	#
	# You can control the page to which the user will return once authentication is complete
	# (even when authentication fails) by setting the "redirect_after" parameter into the GET request in the url. for example:
	# 
	# - Google: "/auth/google?redirect_after=/foo/bar"
	class OAuth2Ctrl

		# Sets (or gets) the global callback to be called after authentication is attempeted.
		#
		# Accepts a block that will be called with the following parameters:
		# service_name:: the name of the service. i.e. :facebook, :google, etc'.
		# service_token:: the authentication token returned by the service. This token should be stored for future access
		# remote_user_id:: service's user id.
		# remote_user_email:: user's primamry email, as (and if) registed with the service.
		# remote_response:: a Hash with the complete user data response (including email and id).
		#
		# If the authentication fails for the service, the block will be called with the following values `auth_callback.call(nil, ni, {server: :responce, might_be: :empty})`
		#
		# The block will be run in the context of the controller and all the controller's methods will be available to it.
		#
		# i.e.:
		#       OAuth2Ctrl.auth_callback |service, service_token, id, email, full_res|  PL.info "OAuth got: #{full_res.to_s}"; cookies["#{service}_pl_auth_token".to_sym], cookies["#{service}_user_id".to_sym], cookies["#{service}_user_email".to_sym] = service_token, id, email }
		#
		# defaults to the example above, which isn't a very sercure behavior, but allows for easy testing.
		def self.auth_callback &block
			block_given? ? (@@auth_callback = block) : ( @@auth_callback ||= (Proc.new {|service, service_token, id, email, res| Plezi.info "deafult callback called for #{service}, with response: #{res.to_s}";  cookies["#{service}_pl_auth_token".to_sym], cookies["#{service}_user_id".to_sym], cookies["#{service}_user_email".to_sym] = service_token, id, email}) )
		end


		# Stores the registered services library
		SERVICES = {}

		# This method registers a social login service that conforms to the OAuth2 model.
		#
		# Accepts the following required parameters:
		# service_name:: a Symbol naming the service. i.e. :facebook or :google .
		# options:: a Hash of options, some of which are required.
		#
		# The options are:
		# app_id:: Required. The aplication's unique ID registered with the service. i.e. ENV [FB_APP_ID] (storing these in environment variables is safer then hardcoding them)
		# app_secret:: Required. The aplication's unique secret registered with the service.
		# auth_url:: Required. The authentication URL. This is the url to which the user is redirected. i.e.: "https://www.facebook.com/dialog/oauth"
		# token_url:: Required. The token request URL. This is the url used to switch the single-use code into a persistant authentication token. i.e.: "https://www.googleapis.com/oauth2/v3/token"
		# profile_url:: Required. The URL used to ask the service for the user's profile (the service's API url). i.e.: "https://graph.facebook.com/v2.3/me"
		# scope:: a String representing the scope requested. i.e. 'email profile'.
		#
		# There will be an attempt to automatically register Facebook and Google login services under these conditions:
		#
		# * For Facebook: Both ENV ['FB_APP_ID'] && ENV ['FB_APP_SECRET'] have been defined.
		# * For Google: Both ENV ['GOOGLE_APP_ID'] && ENV ['GOOGLE_APP_SECRET'] have been defined.
		#
		#
		# The auto registration uses the following urls (updated to June 5, 2015):
		#
		# * facebook auth_url: "https://www.facebook.com/dialog/oauth"
		# * facebook token_url: "https://graph.facebook.com/v2.3/oauth/access_token"
		# * facebook profile_url: "https://graph.facebook.com/v2.3/me"
		# * google auth_url: "https://accounts.google.com/o/oauth2/auth"
		# * google token_url: "https://www.googleapis.com/oauth2/v3/token"
		# * google profile_url: "https://www.googleapis.com/plus/v1/people/me"
		#
		# to change the default url's for Facebook or Google, simpley re-register the service using this method.
		#
		def self.register_service service_name, options
			raise "Cannot register service, missing required information." unless service_name && options[:auth_url] && options[:token_url] && options[:profile_url] && options[:app_id] && options[:app_secret]
			# for google, scope is space delimited. for facebook it's comma delimited
			options[:scope] ||= 'profile, email'
			SERVICES[service_name] = options
		end

		# Called to manually run through the authentication logic for the requested service,
		# without performing any redirections.
		#
		# Use this method to attempt and re-login a user using an existing login token:
		#
		#             token = 'google_token_could_be_recieved_also_from_javascript_sdk'
		#             OAuth2Ctrl.auth :google, token, self
		#
		# The method will return false if re-login fails and it will otherwise return the callback's return value.
		#
		# Call this method from within a controller, passing the controller (self) to the method, like so:
		#
		#             OAuth2Ctrl.auth :facebook, token, self
		#
		# This is especially effective if `auth_callback` returns the user object, as it would allow to chain
		# different login methods, i.e.:
		#
		#             @user ||= app_login || OAuth2Ctrl.auth(:facebook, fb_token, self) || OAuth2Ctrl.auth(:google, google_token, self) || ....
		def self.auth service_name, service_token, controller
			service = SERVICES[service_name]
			retrun false unless service
			# auth_res = controller.cookies[c_name] ? (JSON.parse URI.parse("#{service[:profile_url]}?access_token=#{controller.cookies[c_name]}").read rescue ({}) ) : {}
			# controller.cookies[c_name] = nil unless auth_res['id']
			# auth_res['id'] ? controller.instance_exec( service_name, auth_res['id'], auth_res['email'], auth_res, &auth_callback) : ( controller.instance_exec( service_name, nil, nil, auth_res, &auth_callback) && false)
			auth_res = {}
			uri = URI.parse("#{service[:profile_url]}?access_token=#{service_token}")
			Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https"), verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
				req =  Net::HTTP::Get.new(uri)
				res = http.request(req).body
				auth_res = (JSON.parse res) rescue ({})
			end if service_token
			auth_res['id'] ? controller.instance_exec( service_name, service_token, auth_res['id'], auth_res['email'], auth_res, &auth_callback) : ( controller.instance_exec( service_name, nil, nil, nil, auth_res, &auth_callback) && false)
		end

		def update
			service_name = params[:id].to_s.to_sym
			service = SERVICES[service_name]
			retrun false unless service
			if params[:error]
				instance_exec( service_name, nil, nil, nil, {}, &self.class.auth_callback)
				return redirect_to(flash[:redirect_after])
			end
			unless params[:code]
				flash[:redirect_after] = params[:redirect_after] || '/'
				return redirect_to _auth_url_for(service_name)
			end
			uri = URI.parse service[:token_url]
			service_token = nil
			Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https"), verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
				req =  Net::HTTP::Post.new(uri)
				req.form_data = {"client_id" => service[:app_id],
								"client_secret" => service[:app_secret], "code" => params[:code] ,
								"grant_type" => "authorization_code","redirect_uri" => "#{request.base_url}/auth/#{service_name.to_s}"}
				res = http.request(req).body
				service_token = ((JSON.parse res)['access_token'] rescue nil)
			end

			self.class.auth service_name, service_token, self
			redirect_to(flash[:redirect_after])
		end
		alias :show :update

		protected

		# returns a url for the requested service's social login.
		#
		# this is used internally. Normal behavior would be to set a link to '/auth/{service_name}', where correct redirection will be automatic.
		#
		def _auth_url_for service_name
			service = SERVICES[service_name]
			return nil unless service
			redirect_uri = HTTP::encode "#{request.base_url}/auth/#{service_name.to_s}", :url #response_type
			return "#{service[:auth_url]}?client_id=#{service[:app_id]}&redirect_uri=#{redirect_uri}&scope=#{service[:scope]}&response_type=code"
		end

		register_service(:facebook, app_id: ENV['FB_APP_ID'],
									app_secret: ENV['FB_APP_SECRET'],
									auth_url: "https://www.facebook.com/dialog/oauth",
									token_url: "https://graph.facebook.com/v2.3/oauth/access_token",
									profile_url: "https://graph.facebook.com/v2.3/me",
									scope: "public_profile,email") if ENV['FB_APP_ID'] && ENV['FB_APP_SECRET']
		register_service(:google, app_id: ENV['GOOGLE_APP_ID'],
									app_secret: ENV['GOOGLE_APP_SECRET'],
									auth_url: "https://accounts.google.com/o/oauth2/auth",
									token_url: "https://www.googleapis.com/oauth2/v3/token",
									profile_url: "https://www.googleapis.com/oauth2/v1/userinfo",
									scope: "profile email") if ENV['GOOGLE_APP_ID'] && ENV['GOOGLE_APP_SECRET']

	end
end

# This method creates the OAuth2Ctrl route.
# This is actually a short-cut for:
#
#       shared_route "auth/(:id)/(:code)" , Plezi::OAuth2Ctrl
#       Plezi::OAuth2Ctrl.auth_callback = Proc.new {|service, user_id, user_email, service_response| ... }
#
# the `:id` parameter is used to identify the service (facebook, google. etc').
#
# The method accepts a block that will be used to set the authentication callback. See the Plezi::OAuth2Ctrl documentation for details.
#
# The method can be called only once and will self-destruct.
def create_auth_shared_route options = {}, &block
	shared_route "auth/(:id)" , Plezi::OAuth2Ctrl
	undef create_auth_shared_route
	Plezi::OAuth2Ctrl.auth_callback &block if block
	Plezi::OAuth2Ctrl
end
