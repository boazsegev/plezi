
module Plezi

	module_function

	# this module contains the methods that are used as a DSL and sets up easy access to the Plezi framework.
	#
	# use the`listen`, `host` and `route` functions rather then accessing this object.
	#
	@servers = {}
	@active_router = nil

	# adds a route to the last server created
	def route(path, controller = nil, &block)
		@active_router.add_route path, controller, &block
	end


	# adds a shared route to all existing services and hosts.
	def shared_route(path, controller = nil, &block)
		@listeners.values.each {|p| p.params[:handler].add_shared_route path, controller, &block }
	end

	# adds a host to the last server created
	#
	# accepts the same parameter(s) as the `listen` command (see Plezi.add_service), except :protocol and :handler are ignored:
	# alias:: a String or an Array of Strings which represent alternative host names (i.e. `alias: ["admin.google.com", "admin.gmail.com"]`).
	def host(host_name, params)
		@active_router.add_host host_name, params
	end
end

Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'

# Set a shortcut for the Plezi module.
PL = Plezi

# shortcut for Plezi.listen.
#
def listen(params = {})
	Plezi.listen params
end

# adds a virtul host to the current service (the last `listen` call) or switches to an existing host within the active service.
#
# accepts:
# host_name: a String with the full host name (i.e. "www.google.com" / "mail.google.com")
# params:: any of the parameters accepted by the `listen` command, except `protocol`, `handler`, and `ssl` parameters.
def host(host_name = false, params = {})
	Plezi.host host_name, params
end

# adds a route to the last server object
#
# path:: the path for the route
# controller:: The controller class which will accept the route.
#
# `path` parameters has a few options:
#
# * `path` can be a Regexp object, forcing the all the logic into controller (typically using the before method).
#
# * simple String paths are assumed to be basic RESTful paths:
#
#     route "/users", Controller => route "/users/(:id)", Controller
#
# * routes can define their own parameters, for their own logic:
#
#     route "/path/:required_paramater/:required_paramater{with_format}/(:optional_paramater)/(:optional){with_format}"
#
# * routes can define optional or required routes with regular expressions in them:
#
#     route "(:locale){en|ru}/path"
#
# * routes which use the special '/' charecter within a parameter's format, must escape this charecter using the '\' charecter. **Notice the single quotes** in the following example:
#
#     route '(:math){[\d\+\-\*\^\%\.\/]}'
#
#   * or, with double quotes:
#
#     route "(:math){[\\d\\+\\-\\*\\^\\%\\.\\/]}"
#
# magic routes make for difficult debugging - the smarter the routes, the more difficult the debugging.
# use with care and avoid complex routes when possible. RESTful routes are recommended when possible.
# json serving apps are advised to use required parameters, empty sections indicating missing required parameters (i.e. /path///foo/bar///).
#
def route(path, controller = nil, &block)
	Plezi.route(path, controller, &block)
end

# adds a route to the all the existing servers and hosts.
#
# accepts same options as route.
def shared_route(path, controller = nil, &block)
	Plezi.shared_route(path, controller, &block)
end

# defines a method with a special name, such as "humens.txt".
#
# this could be used in controller classes, to define special routes which might defy
# normal Ruby naming conventions, such as "/welcome-home", "/play!", etc'
#
# could also be used to define methods with special formatting, such as "humans.txt",
# until a more refined way to deal with formatting will be implemented.
def def_special_method name, obj=self, &block
	obj.instance_eval { define_method name.to_s.to_sym, &block }
end



# finishes setup of the servers and starts them up. This will hange the proceess.
#
# this method is called automatically by the Plezi framework.
#
# it is recommended that you DO NOT CALL this method.
# if any post shut-down actions need to be performed, use Plezi.on_shutdown instead.
def start_services
	return 0 if ( defined?(NO_PLEZI_AUTO_START) || defined?(BUILDING_PLEZI_TEMPLATE) || defined?(PLEZI_ON_RACK) )
	Object.const_set "NO_PLEZI_AUTO_START", true
	undef listen
	undef host
	undef route
	undef shared_route
	undef start_services
	Plezi.start_services
end

# restarts the Plezi app with the same arguments as when it was started.
#
# EXPERIMENTAL
def restart_plezi_app
	exec "/usr/bin/env ruby #{$PL_SCRIPT} #{$PL_ARGV.join ' '}"
end

# sets to start the services once dsl script is finished loading.
at_exit { start_services } unless ( defined?(NO_PLEZI_AUTO_START) || defined?(BUILDING_PLEZI_TEMPLATE) || defined?(PLEZI_ON_RACK) )

# sets a name for the process (on some systems).
$PL_SCRIPT = $0
$PL_ARGV = $*.dup
$0="Plezi (Ruby)"
