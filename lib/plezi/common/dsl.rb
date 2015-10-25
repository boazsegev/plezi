unless defined? PLEZI_NON_DSL

	# shortcut for Plezi.listen. Deprecated.
	#
	def listen(params = {})
		Plezi.listen params
	end

	# adds a virtul host or switches to an existing host, for routes setup or parameters update.
	#
	# accepts:
	# host_name: a String with the full host name (i.e. "www.google.com" / "mail.google.com")
	# params:: any of the parameters accepted by the {Plezi.host} command.
	#
	# If no host is specified or host name is `false`, the default host would be set as the active host and returned.
	def host(host_name = false, params = {})
		Plezi.host host_name, params
	end

	# adds a route to the last (or default) host
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
	# JSON serving apps are advised to use required parameters and empty sections indicating missing required parameters (i.e. /path///foo/bar///).
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
		obj.instance_exec { define_method name.to_s.to_sym, &block }
	end


	# sets information to be used when restarting
	$PL_SCRIPT = $0
	$PL_ARGV = $*.dup

	# restarts the Plezi app with the same arguments as when it was started.
	#
	# EXPERIMENTAL
	def restart_plezi_app
		exec "/usr/bin/env ruby #{$PL_SCRIPT} #{$PL_ARGV.join ' '}"
	end

	# sets to start the services once dsl script is finished loading.
	at_exit do
		undef listen
		undef host
		undef route
		undef shared_route
	end
end
