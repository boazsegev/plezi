module Plezi

	# the methods defined in this module will be injected into the Controller class passed to
	# Plezi (using the `route` or `shared_route` commands), and will be available
	# for the controller to use within it's methods.
	#
	# for some reason, the documentation ignores the following additional attributes, which are listed here:
	#
	# request:: the HTTPRequest object containing all the data from the HTTP request. If a WebSocket connection was established, the `request` object will continue to contain the HTTP request establishing the connection (cookies, parameters sent and other information).
	# params:: any parameters sent with the request (short-cut for `request.params`), will contain any GET or POST form data sent (including file upload and JSON format support).
	# cookies:: a cookie-jar to get and set cookies (set: `cookie\[:name] = data` or get: `cookie\[:name]`). Cookies and some other data must be set BEFORE the response's headers are sent.
	# flash:: a temporary cookie-jar, good for one request. this is a short-cut for the `response.flash` which handles this magical cookie style.
	# response:: the HTTPResponse **OR** the WSResponse object that formats the response and sends it. use `response << data`. This object can be used to send partial data (such as headers, or partial html content) in blocking mode as well as sending data in the default non-blocking mode.
	# host_params:: a copy of the parameters used to create the host and service which accepted the request and created this instance of the controller class.
	#
	module ControllerMagic
		def self.included base
			base.send :include, InstanceMethods
			base.extend ClassMethods
		end

		module InstanceMethods
			module_function
			public

			# the request object, class: HTTPRequest.
			attr_reader :request

			# the ::params variable contains all the parameters set by the request (/path?locale=he  => params["locale"] == "he").
			attr_reader :params

			# a cookie-jar to get and set cookies (set: `cookie\[:name] = data` or get: `cookie\[:name]`).
			#
			# Cookies and some other data must be set BEFORE the response's headers are sent.
			attr_reader :cookies

			# the HTTPResponse **OR** the WSResponse object that formats the response and sends it. use `response << data`. This object can be used to send partial data (such as headers, or partial html content) in blocking mode as well as sending data in the default non-blocking mode.
			attr_reader :response

			# the ::flash is a little bit of a magic hash that sets and reads temporary cookies.
			# these cookies will live for one successful request to a Controller and will then be removed.
			attr_reader :flash

			# the parameters used to create the host (the parameters passed to the `listen` / `add_service` call).
			attr_reader :host_params

			# this method does two things.
			#
			# 1. sets redirection headers for the response.
			# 2. sets the `flash` object (short-time cookies) with all the values passed except the :status value.
			#
			# use:
			#      redirect_to 'http://google.com', notice: "foo", status: 302
			#      # => redirects to 'http://google.com' with status 302 and adds notice: "foo" to the flash
			# or simply:
			#      redirect_to 'http://google.com'
			#      # => redirects to 'http://google.com' with status 302 (default status)
			#
			# if the url is a symbol, the method will try to format it into a correct url, replacing any
			# underscores ('_') with a backslash ('/').
			#
			# if the url is an empty string, the method will try to format it into a correct url
			# representing the index of the application (http://server/)
			#
			def redirect_to url, options = {}
				return super *[] if defined? super
				raise 'Cannot redirect after headers were sent' if response.headers_sent?
				url = "#{request.base_url}/#{url.to_s.gsub('_', '/')}" if url.is_a?(Symbol) || ( url.is_a?(String) && url.empty? ) || url.nil?
				# redirect
				response.status = options.delete(:status) || 302
				response['Location'] = url
				response['content-length'] ||= 0
				flash.update options
				response.finish
				true
			end

			# Returns the RELATIVE url for methods in THIS controller (i.e.: "/path_to_controller/restful/params?non=restful&params=foo")
			#
			# accepts one parameter:
			# dest:: a destination object, either a Hash, a Symbol, a Numerical or a String.
			#
			# If :dest is a Numerical, a Symbol or a String, it should signify the id of an object or the name of the method this controller should respond to.
			#
			# If :dest is a Hash, it should contain all the relevant parameters the url should set (i.e. `url_for id: :new, name: "Jhon Doe"`)
			#
			# If :dest is false (or nil), the String returned will be the url to the index.
			#
			# * If you use the same controller in different routes, the first route will dictate the returned url's structure (cause by route priority).
			#
			# * Not all controllers support this method. Regexp controller paths and multi-path options will throw an exception.
			def url_for dest = nil
				self.class.url_for dest
			end
			# same as #url_for, but returns the full URL (protocol:port:://host/path?params=foo)
			def full_url_for dest
				request.base_url + url_for(dest)
			end

			# this method adds data to be sent.
			#
			# this is usful for sending 'attachments' (data to be downloaded) rather then
			# a regular response.
			#
			# this is also usful for offering a file name for the browser to "save as".
			#
			# it accepts:
			# data:: the data to be sent
			# options:: a hash of any of the options listed furtheron.
			#
			# the :symbol=>value options are:
			# type:: the type of the data to be sent. defaults to empty. if :filename is supplied, an attempt to guess will be made.
			# inline:: sets the data to be sent an an inline object (to be viewed rather then downloaded). defaults to false.
			# filename:: sets a filename for the browser to "save as". defaults to empty.
			#
			def send_data data, options = {}
				raise 'Cannot use "send_data" after headers were sent' if response.headers_sent?
				Plezi.warn 'HTTP response buffer is cleared by `#send_data`' if response.body && response.body.any? && response.body.clear
				response << data

				# set headers
				content_disposition = options[:inline] ? 'inline' : 'attachment'
				content_disposition << "; filename=#{options[:filename]}" if options[:filename]

				response['content-type'] = options[:type] ||= MimeTypeHelper::MIME_DICTIONARY[::File.extname(options[:filename])] if options[:filename]
				response['content-length'] = data.bytesize rescue true
				response['content-disposition'] = content_disposition
				response.finish
				true
			end

			# renders a template file (.slim/.erb/.haml) or an html file (.html) to text
			# for example, to render the file `body.html.slim` with the layout `main_layout.html.haml`:
			#   render :body, layout: :main_layout
			#
			# or, for example, to render the file `json.js.slim`
			#   render :json, type: 'js'
			#
			# or, for example, to render the file `template.haml`
			#   render :template, type: ''
			#
			# template:: a Symbol for the template to be used.
			# options:: a Hash for any options such as `:layout` or `locale`.
			# block:: an optional block, in case the template has `yield`, the block will be passed on to the template and it's value will be used inplace of the yield statement.
			#
			# options aceept the following keys:
			# type:: the types for the `:layout' and 'template'. can be any extention, such as `"json"`. defaults to `"html"`.
			# layout:: a layout template that has at least one `yield` statement where the template will be rendered.
			# locale:: the I18n locale for the render. (defaults to params\[:locale]) - only if the I18n gem namespace is defined (`require 'i18n'`).
			#
			# if template is a string, it will assume the string is an
			# absolute path to a template file. it will NOT search for the template but might raise exceptions.
			#
			# if the template is a symbol, the '_' caracters will be used to destinguish sub-folders (NOT a partial template).
			#
			# returns false if the template or layout files cannot be found.
			def render template, options = {}, &block
				# make sure templates are enabled
				return false if host_params[:templates].nil?
				# render layout by recursion, if exists
				(return render(options.delete(:layout), options) { render template, options, &block }) if options[:layout]
				# set up defaults
				options[:type] ||= 'html'
				options[:locale] ||= params[:locale].to_sym if params[:locale]
				# options[:locals] ||= {}
				I18n.locale = options[:locale] || I18n.default_locale if defined?(I18n) # sets the locale to nil for default behavior even if the locale was set by a previous action - removed: # && options[:locale]
				# find template and create template object
				filename = template.is_a?(String) ? File.join( host_params[:templates].to_s, template) : (File.join( host_params[:templates].to_s, *template.to_s.split('_')) + (options[:type].empty? ? '': ".#{options[:type]}") + '.slim')
				return ( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( Slim::Template.new() { IO.read filename } ) )  : (Plezi.get_cached filename) ).render(self, &block) if defined?(::Slim) && Plezi.file_exists?(filename)
				filename.gsub! /\.slim$/, '.haml'
				return ( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( Haml::Engine.new( IO.read(filename) ) ) )  : (Plezi.get_cached filename) ).render(self, &block) if defined?(::Haml) && Plezi.file_exists?(filename)
				filename.gsub! /\.haml$/, '.erb'
				return ( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( ERB.new( IO.read(filename) ) ) )  : (Plezi.get_cached filename) ).result(binding, &block) if defined?(::ERB) && Plezi.file_exists?(filename)
				return false
			end

			# returns the initial method called (or about to be called) by the router for the HTTP request.
			#
			# this can be very useful within the before / after filters:
			#   def before
			#     return false unless "check credentials" && [:save, :update, :delete].include?(requested_method)
			#
			# if the controller responds to a WebSockets request (a controller that defines the `on_message` method),
			# the value returned is invalid and will remain 'stuck' on :pre_connect
			# (which is the last method called before the protocol is switched from HTTP to WebSockets).
			def requested_method
				# respond to websocket special case
				return :pre_connect if request.upgrade?
				# respond to save 'new' special case
				return :save if request.request_method.match(/POST|PUT|PATCH/) && (params[:id].nil? || params[:id] == 'new')
				# set DELETE method if simulated
				request.request_method = 'DELETE' if params[:_method].to_s.downcase == 'delete'
				# respond to special :id routing
				return params[:id].to_s.to_sym if params[:id] && self.class.available_public_methods.include?(params[:id].to_s.to_sym)
				#review general cases
				case request.request_method
				when 'GET', 'HEAD'
					return :index unless params[:id]
					return :show
				when 'POST', 'PUT', 'PATCH'
					return :update
				when 'DELETE'
					return :delete
				end
				false
			end

			## WebSockets Magic

			# Get's the websocket's unique identifier for unicast transmissions.
			#
			# This UUID is also used to make sure Radis broadcasts don't triger the
			# boadcasting object's event.
			def uuid
				return @response.uuid if @response.is_a?(GRHttp::WSEvent)
				nil
			end
			alias :unicast_id :uuid

			# WebSockets.
			#
			# Use this to brodcast an event to all 'sibling' websockets (websockets that have been created using the same Controller class).
			#
			# Accepts:
			# method_name:: a Symbol with the method's name that should respond to the broadcast.
			# args*:: The method's argumenst - It MUST be possible to stringify the arguments into a JSON string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
			#
			# The method will be called asynchrnously for each sibling instance of this Controller class.
			#
			def broadcast method_name, *args
				
				return false unless @response.is_a?(GRHttp::WSEvent) && self.class.public_instance_methods.include?(method_name)
				@response.broadcast data
				self.class.__inner_redis_broadcast(uuid, nil, method_name, args, &block) || self.class.__inner_process_broadcast(uuid, nil, method_name.to_sym, args, &block)
			end

			# {include:ControllerMagic::ClassMethods#unicast}
			def unicast target_uuid, method_name, *args
				self.class.unicast target_uuid, method_name, *args
			end


			# # will (probably NOT), in the future, require authentication or, alternatively, return an Array [user_name, password]
			# #
			# #
			# def request_http_auth realm = false, auth = 'Digest'
			# 	return request.service.handler.hosts[request[:host] || :default].send_by_code request, 401, "WWW-Authenticate" => "#{auth}#{realm ? "realm=\"#{realm}\"" : ''}" unless request['authorization']
			# 	request['authorization']
			# end
		end

		module ClassMethods
			protected

			# Sets the HTTP route that is the owner of this controller.
			#
			# This is used by the Plezi framework internally and is supplied only for advanced purposes. It is better to avoid using this method. 
			def set_pl_route route
				@pl_http_route = route
			end

			# Gets the HTTP route that is the owner of this controller.
			#
			# This is used to utilize the `url_for` method.
			def get_pl_route
				@pl_http_route
			end

			public

			# This class method behaves the same way as the instance method #url_for. See the instance method's documentation for more details.
			def url_for dest
				get_pl_route.url_for dest				
			end

			# lists the available methods that will be exposed to HTTP requests
			def available_public_methods
				# set class global to improve performance while checking for supported methods
				@available_public_methods ||= (available_routing_methods - [:before, :after, :save, :show, :update, :delete, :initialize, :on_message, :pre_connect, :on_open, :on_close]).to_set
			end

			# lists the available methods that will be exposed to the HTTP router
			def available_routing_methods
				@available_routing_methods ||= ( ( (public_instance_methods - Class.new.public_instance_methods) - Plezi::ControllerMagic::InstanceMethods.instance_methods).delete_if {|m| m.to_s[0] == '_'}).to_set
			end

			# resets this controller's router, to allow for dynamic changes
			def reset_routing_cache
				@available_routing_methods = false
				@available_public_methods = false
				available_routing_methods
				available_public_methods
			end

			# a callback that resets the class router whenever a method (a potential route) is added
			def method_added(id)
				reset_routing_cache
			end
			# a callback that resets the class router whenever a method (a potential route) is removed
			def method_removed(id)
				reset_routing_cache
			end
			# a callback that resets the class router whenever a method (a potential route) is undefined (using #undef_method).
			def method_undefined(id)
				reset_routing_cache
			end
			# # lists the available methods that will be exposed to HTTP requests
			# def available_public_methods
			# 	# set class global to improve performance while checking for supported methods
			# 	Plezi.cached?(self.superclass.name + '_p&rt') ? Plezi.get_cached(self.superclass.name + "_p&rt") : Plezi.cache_data(self.superclass.name + "_p&rt", (available_routing_methods - [:before, :after, :save, :show, :update, :delete, :initialize, :on_message, :pre_connect, :on_connect, :on_disconnect]).to_set )
			# end

			# # lists the available methods that will be exposed to the HTTP router
			# def available_routing_methods
			# 	# set class global to improve performance while checking for supported methods
			# 	Plezi.cached?(self.superclass.name + '_r&rt') ? Plezi.get_cached(self.superclass.name + "_r&rt") : Plezi.cache_data(self.superclass.name + "_r&rt",  (((public_instance_methods - Object.public_instance_methods) - Plezi::ControllerMagic::InstanceMethods.instance_methods).delete_if {|m| m.to_s[0] == '_'}).to_set  )
			# end

			# # resets this controller's router, to allow for dynamic changes
			# def reset_routing_cache
			# 	Plezi.clear_cached(self.superclass.name + '_p&rt')
			# 	Plezi.clear_cached(self.superclass.name + '_r&rt')
			# 	available_routing_methods
			# 	available_public_methods
			# end

			
			# Reviews the Redis connection, sets it up if it's missing and returns the Redis connection.
			#
			# A Redis connection will be automatically created if the `ENV['PL_REDIS_URL']` is set.
			# for example:
			#      ENV['PL_REDIS_URL'] = ENV['REDISCLOUD_URL']`
			# or
			#      ENV['PL_REDIS_URL'] = "redis://username:password@my.host:6379"
			def redis_connection
				# return false unless defined?(Redis) && ENV['PL_REDIS_URL']
				# return @redis if defined?(@redis_sub_thread) && @redis
				# @@redis_uri ||= URI.parse(ENV['PL_REDIS_URL'])
				# @redis ||= Redis.new(host: @@redis_uri.host, port: @@redis_uri.port, password: @@redis_uri.password)
				# @redis_sub_thread = Thread.new do
				# 	begin
				# 		Redis.new(host: @@redis_uri.host, port: @@redis_uri.port, password: @@redis_uri.password).subscribe(redis_channel_name) do |on|
				# 			on.message do |channel, msg|
				# 				args = JSON.parse(msg)
				# 				params = args.shift
				# 				__inner_process_broadcast params['_pl_ignore_object'], params['_pl_method_broadcasted'].to_sym, args
				# 			end
				# 		end						
				# 	rescue Exception => e
				# 		Plezi.error e
				# 		retry
				# 	end
				# end
				# raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless @redis
				# @redis
				return false unless defined?(Redis) && ENV['PL_REDIS_URL']
				return Plezi.get_cached(self.superclass.name + '_b') if Plezi.cached?(self.superclass.name + '_b')
				@@redis_uri ||= URI.parse(ENV['PL_REDIS_URL'])
				b = nil
				Plezi.cache_data self.superclass.name + '_b', (b = Redis.new(host: @@redis_uri.host, port: @@redis_uri.port, password: @@redis_uri.password) )
				raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless b
				t = Thread.new do
					begin
						Redis.new(host: @@redis_uri.host, port: @@redis_uri.port, password: @@redis_uri.password).subscribe(redis_channel_name) do |on|
							on.message do |channel, msg|
								args = JSON.parse(msg)
								params = args.shift
								__inner_process_broadcast params['_pl_ignore_object'], params['_pl_target_object'], params['_pl_method_broadcasted'].to_sym, args
							end
						end						
					rescue Exception => e
						Plezi.error e
						retry
					end
				end
				Plezi.cache_data self.superclass.name + '_t', t
				b
			end

			# returns a Redis channel name for this controller.
			def redis_channel_name
				self.superclass.name.to_s
			end

			# broadcasts messages (methods) for this process
			def __inner_process_broadcast ignore, target, method_name, args, &block
				ObjectSpace.each_object(self) { |controller| Plezi.callback controller, method_name, *args, &block if controller.accepts_broadcast? && (!ignore || (controller.uuid != ignore)) && (!target || (controller.uuid == target)) }
			end

			# broadcasts messages (methods) between all processes (using Redis).
			def __inner_redis_broadcast ignore, target, method_name, args, &block
				return false unless redis_connection
				raise "Radis broadcasts cannot accept blocks (no inter-process callbacks of memory sharing)!" if block
				# raise "Radis broadcasts accept only one paramater, which is an optional Hash (no inter-process memory sharing)" if args.length > 1 || (args[0] && !args[0].is_a?(Hash))
				args.unshift ({_pl_method_broadcasted: method_name, _pl_ignore_object: ignore, _pl_target_object: target})
				redis_connection.publish(redis_channel_name, args.to_json )
				true
			end

			# WebSockets: fires an event on all of this controller's active websocket connections.
			#
			# Class method.
			#
			# Use this to brodcast an event to all connections.
			#
			# accepts:
			# method_name:: a Symbol with the method's name that should respond to the broadcast.
			# *args:: any arguments that should be passed to the method (IF REDIS IS USED, LIMITATIONS APPLY).
			#
			# this method accepts and optional block (NON-REDIS ONLY) to be used as a callback for each sibling's event.
			#
			# the method will be called asynchrnously for each sibling instance of this Controller class.
			def broadcast method_name, *args, &block
				return false unless public_instance_methods.include?(method_name)
				__inner_redis_broadcast(nil, nil, method_name, args, &block) || __inner_process_broadcast(nil, nil, method_name.to_sym, args, &block)
			end

			# WebSockets: fires an event on a specific websocket connection using it's UUID.
			#
			# Use this to unidcast an event to specific websocket connection using it's UUID.
			#
			# accepts:
			# target_uuid:: the target's unique UUID.
			# method_name:: a Symbol with the method's name that should respond to the broadcast.
			# *args:: any arguments that should be passed to the method (IF REDIS IS USED, LIMITATIONS APPLY).
			def unicast target_uuid, method_name, *args
				return false unless public_instance_methods.include?(method_name.to_sym)
				__inner_redis_broadcast(nil, target_uuid, method_name, args) || __inner_process_broadcast(nil, target_uuid, method_name.to_sym, args)
			end

			# WebSockets.
			#
			# Class method.
			#
			# Use this to collect data from all websockets for the calling class (websockets that have been created using the same Controller class).
			#
			# This method will call the requested method on all instance and return an Array of the returned values (including nil values).
			#
			# This method will block the excecution unless a block is passed to the method - in which case
			#  the block will used as a callback and recieve the Array as a parameter.
			#
			# i.e.
			#
			# this will block: `collect :_get_id`
			#
			# this will not block: `collect(:_get_id) {|a| puts "got #{a.length} responses."; a.each { |id| puts "#{id}"} }
			#
			# accepts:
			# method_name:: a Symbol with the method's name that should respond to the broadcast.
			# *args:: any arguments that should be passed to the method.
			# &block:: an optional block to be used as a callback.
			#
			# the method will be called asynchrnously for each instance of this Controller class.
			def collect method_name, *args, &block				
				return Plezi.push_event(self.method(:collect), *args, &block) if block

				r = []
				ObjectSpace.each_object(self) { |controller|  r << controller.method(method_name).call(*args) if controller.accepts_broadcast? }
				return r
			end
		end

		module_function


	end
end
