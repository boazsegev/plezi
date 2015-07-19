###############
# # OAuth2 Config File
# # ==================
# # 
# # Here you can sets the OAuth2 variables and require the OAuth2 Plezi controller.
# # (if the variables aren't set BEFORE the inclution, automatic setup will NOT take place)
# #
# # First set the variables:
# #
# ENV["FB_APP_ID"] ||= "app id"
# ENV["FB_APP_SECRET"] ||= "secret"
# ENV['GOOGLE_APP_ID'] = "app id"
# ENV['GOOGLE_APP_SECRET'] = "secret"
# #
# # Then, require the actual OAuth2 controller class (Plezi::OAuth2Ctrl).
# #
# require 'plezi/oauth'
# #
# # Last, but not least, remember to add the authentication route in the 'routes.rb' (remember path priority placement):
# create_auth_shared_route do |service_name, auth_token, remote_user_id, remote_user_email, remote_response|
#         # ...callback for authentication.
#         # This callback should return the app user object or false
#         # This callback has access to the magic controller methods (request, cookies, etc')
# end
