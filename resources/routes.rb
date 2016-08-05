################
# # Place your application routes here.
# #
# # Add your routes and controllers by order of priority.

# # I18n re-write, i.e.: `/en/home` will be rewriten as `/home`, while setting params['locale'] to "en"
# Plezi.route "/:locale" , /^(#{I18n.available_locales.join "|"})$/ if defined? I18n

# # Response format re-write, i.e.: `/xml/home` will use .xml templates automatically
# # with :locale a request might look like `/en/json/...`
# Plezi.route "/:format" , /^(html|json|xml)$/

# The root Controller
Plezi.route '/', RootController
