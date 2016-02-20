
module Plezi
  # this module and all it's methods and properties will be mixed into any
  # Controller class.
  #
  # Important helper methods, such as {#render} are described here.
  module ControllerMagic


    # @!parse include InstanceMethods
		# @!parse extend ClassMethods

		def self.included base
			base.__send__ :include, InstanceMethods
			base.extend ClassMethods
		end

		module InstanceMethods

			public

			# the request object, type HTTPRequest.
			attr_reader :request

			# the :params variable contains all the parameters set by the request (/path?locale=he  => params ["locale"] == "he").
			attr_reader :params

			# A cookie-jar to get and set cookies (set: `cookie [:name] = data` or get: `cookie [ :name ]`).
			#
			# Cookies and some other data must be set BEFORE the response's headers are sent.
			attr_reader :cookies

			# Session data can be stored here (session data will be stored on the Redis server, if Redis is available).
			#
			# The first time this method is called, the `n object will be created. The session object must be created BEFORE the headers are set , if it is to be used.
			#
			# Sessions are not automatically created, because they require more resources. The one exception is the Websocket connection that will force a session object into existence, as it's very common to use session data in Websocket connections and the extra connection time is less relevant for a long term connection.
			def session
				@session ||= request.session
			end

			# the HTTPResponse **OR** the WSResponse object that formats the response and sends it. use `response << data`. This object can be used to send partial data (such as headers, or partial html content) in blocking mode as well as sending data in the default non-blocking mode.
			attr_reader :response

			# the :flash is a little bit of a magic hash that sets and reads temporary cookies.
			# these cookies will live for one successful request to a Controller and will then be removed.
			attr_reader :flash

			# the parameters used to create the host (the parameters passed to the `Plezi.host`).
			attr_reader :host_params

			# this method does two things.
			#
			# 1. sets redirection headers for the response.
			# 2. sets the `flash` object (short-time cookies) with all the values passed except the :permanent value.
			#
			# use:
			#      redirect_to 'http://google.com', notice: "foo", permanent: true
			#      # => redirects to 'http://google.com' with status 301 (permanent redirection) and adds notice: "foo" to the flash
			# or, a simple temporary redirect:
			#      redirect_to 'http://google.com'
			#      # => redirects to 'http://google.com' with status 302 (default temporary redirection)
			#
			# if the url is a symbol or a hash, the method will try to format it into a url Srting, using the `url_for` method.
			#
			# if the url is a String, it will be passed along as is.
			#
			# An empty String or `nil` will be replaced with the root path for the request's specific host (i.e. `http://localhost:3000/`).
			#
			def redirect_to url, options = {}
				return super() if defined? super
				url = full_url_for(url, params) unless url.is_a?(String) || url.nil?
				# redirect
				response.redirect_to url, options
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
			# * The route's host will be ignored. Even when using {#full_url_for}, the same host as the current request will be assumed. To change hosts, add the new host's address manualy, i.e.: `request.base_url.gsub('//www.', '//admin.') + UserController.url_for(user.id, params)
			#
			# * Not all controllers support this method. Regexp controller paths and multi-path options will throw an exception.
			def url_for dest = nil
				self.class.url_for dest, params
			end
			# same as #url_for, but returns the full URL (protocol:port:://host/path?params=foo)
			def full_url_for dest
				"#{request.base_url}#{self.class.url_for(dest, params)}"
			end

			# Send raw data to be saved as a file or viewed as an attachment. Browser should believe it had recieved a file.
			#
			# this is useful for sending 'attachments' (data to be downloaded) rather then
			# a regular response.
			#
			# this is also useful for offering a file name for the browser to "save as".
			#
			# it accepts:
			# data:: the data to be sent - this could be a String or an open File handle.
			# options:: a hash of any of the options listed furtheron.
			#
			# the :symbol=>value options are:
			# type:: the mime-type of the data to be sent. defaults to empty. if :filename is supplied, an attempt to guess will be made.
			# inline:: sets the data to be sent an an inline object (to be viewed rather then downloaded). defaults to false.
			# filename:: sets a filename for the browser to "save as". defaults to empty.
			#
			def send_data data, options = {}
				# raise 'Cannot use "send_data" after headers were sent' if response.headers_sent?
				if (response.length.to_i > 0) || (response.body && response.body.any?)
					Plezi.warn 'existing response body was cleared by `#send_data`!'
					response.body.close if response.body.respond_to? :close
          response.body = []
          response.instance_variable_set :@length, 0
				end
				response.write data

				# set headers
				content_disposition = String.new
        content_disposition << options[:inline] ? 'inline'.freeze : 'attachment'.freeze
				content_disposition << "; filename=#{::File.basename(options[:filename])}" if options[:filename]

				response[Rack::CONTENT_TYPE] = (options[:type] ||= options[:filename] && MimeTypeHelper::MIME_DICTIONARY[::File.extname(options[:filename])])
				response['Content-Disposition'.freeze] = content_disposition
				true
			end

			# Renders a template file (.slim/.erb/.haml) to a String and attempts to set the response's 'content-type' header (if it's still empty).
			#
			# For example, to render the file `body.html.slim` with the layout `main_layout.html.haml`:
			#   render :body, layout: :main_layout
			#
			# or, for example, to render the file `json.js.slim`
			#   render :json, format: 'js'
			#
			# or, for example, to render the file `template.haml`
			#   render :template, format: ''
			#
			# template:: a Symbol for the template to be used.
			# options:: a Hash for any options such as `:layout` or `locale`.
			# block:: an optional block, in case the template has `yield`, the block will be passed on to the template and it's value will be used inplace of the yield statement.
			#
			# options aceept the following keys:
			# format:: the format for the `:layout' and 'template'. can be any format (the file's sub-extention), such as `"json"`. defaults to `"html"`.
			# layout:: a layout template that has at least one `yield` statement where the template will be rendered.
			# locale:: the I18n locale for the render. (defaults to params\[:locale]) - only if the I18n gem namespace is defined (`require 'i18n'`).
			#
			# if template is a string, it will assume the string is an
			# absolute path to a template file. it will NOT search for the template but might raise exceptions.
			#
			# if the template is a symbol, the '_' characters will be used to destinguish sub-folders (NOT a partial template).
			#
			# returns false if the template or layout files cannot be found.
			def render template, options = {}, &block
				# make sure templates are enabled
				return false if host_params[:templates].nil?
				# set up defaults
				@warned_type ||= (Iodine.warn("Deprecation warning! `#render` method called with optional `:type`. Use `:format` instead!") && true) if options[:type]
				options[:format] ||= (options[:type] || params[:format] || 'html'.freeze).to_s
				options[:locale] ||= params[:locale].to_sym if params[:locale]
				# render layout using recursion, if exists
				if options[:layout]
					layout = options.delete(:layout)
					inner = render(template, options, &block)
					return false unless inner
					return render(layout, options) { inner }
				end
				#update content-type header
				case options[:format]
				when HTML, JS, TXT
					response[Rack::CONTENT_TYPE] ||= "#{MimeTypeHelper::MIME_DICTIONARY[".#{options[:format]}".freeze]}; charset=utf-8".freeze
				else
					response[Rack::CONTENT_TYPE] ||= "#{MimeTypeHelper::MIME_DICTIONARY[".#{options[:format]}".freeze]}".freeze
				end
				# Circumvents I18n persistance issues (live updating and thread data storage).
				I18n.locale = options[:locale] || I18n.default_locale if defined?(I18n) # sets the locale to nil for default behavior even if the locale was set by a previous action - removed: # && options[:locale]
				# find template and create template object
				template = [template] if template.is_a?(String)
				filename = ( template.is_a?(Array) ? File.join( host_params[:templates].to_s, *template) : File.join( host_params[:templates].to_s, *template.to_s.split('_'.freeze) ) ) + (options[:format].empty? ? ''.freeze : ".#{options[:format]}".freeze)
				::Plezi::Renderer.render filename, binding, &block
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
				return :pre_connect if request[UPGRADE] && /websocket/i.freeze =~ request[UPGRADE]
				# respond to save 'new' special case
				return (self.class.has_method?(:save) ? :save : false) if (request.request_method =~ /POST|PUT|PATCH/i.freeze) && (params[ID].nil? || params[ID] == NEW)
				# set DELETE method if simulated
				request.request_method = 'DELETE'.freeze if params[:_method] && params[:_method].to_s.downcase == 'delete'.freeze
				# respond to special 'id'.freeze routing
				params[ID].to_s.downcase.to_sym.tap { |met| return met if self.class.has_exposed_method?(met) } if params[ID]
				#review general cases
				case request.request_method
				when 'GET'.freeze, 'HEAD'.freeze
					return (self.class.has_method?(:index) ? :index : false) unless params[ID]
					return (self.class.has_method?(:show) ? :show : false)
				when 'POST'.freeze, 'PUT'.freeze, 'PATCH'.freeze
					return (self.class.has_method?(:update) ? :update : false)
				when 'DELETE'.freeze
					return (self.class.has_method?(:delete) ? :delete : false)
				end
				false
			end
		end

		module ClassMethods
			public

			# This class method behaves the same way as the instance method #url_for, but accepts an added `params` Hash
			# that will be used to infer any persistent re-write parameters (i.e. `:locale` or `:format`).
			# See the instance method's documentation for more details.
			def url_for dest, params={}
				case dest
				when :index, nil, false
					dest = {}
				when String
					dest = {id: dest}
				when Numeric, Symbol
					dest = {id: dest}
				when Hash
					true
				else
					# convert dest.id and dest[:id] to their actual :id value.
					dest = {id: (dest.id rescue false) || (raise TypeError, "Expecting a Symbol, Hash, String, Numeric or an object that answers to obj['id'] or obj.id") }
				end
				::Plezi::Base::HTTPRouter.url_for self, dest, params
			end

			# resets the routing cache
      def reset_routing_cache
        @methods_list = nil
        @exposed_methods_list = nil
        @auto_dispatch_list = nil
        has_method? nil
        has_exposed_method? nil
        has_auto_dispatch_method? nil
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
      # # a callback that monitors inheritance
			# def inherited sub
			# 	(@inheritance ||= [].to_set) << sub
			# end
      # returns true if the class has a matching method (public, protected or private)
      def has_method? method_name
        @methods_list ||= self.instance_methods.to_set
        @methods_list.include? method_name
      end
      def has_exposed_method? method_name
        @exposed_methods_list ||= ( (self.public_instance_methods - _reserverd_methods_list_ ).delete_if {|m| m.to_s[0] == '_'} ).to_set
        @exposed_methods_list.include? method_name
      end
      def has_auto_dispatch_method? method_name
        @auto_dispatch_list ||= (( self.instance_methods.to_set - _reserverd_methods_list_ ).delete_if {|m| m.to_s[0] == '_' || instance_method(m).arity == 0 }).to_set
        @auto_dispatch_list.include? method_name
      end
      def _reserverd_methods_list_
        @_reserverd_methods_list_ ||= (Class.new.public_instance_methods +
          # Plezi::Base::WSObject::InstanceMethods.public_instance_methods +
          # Plezi::Base::WSObject::SuperInstanceMethods.public_instance_methods +
          Plezi::ControllerMagic::InstanceMethods.public_instance_methods +
          Plezi::Base::ControllerCore::InstanceMethods.public_instance_methods +
          [:before, :after, :save, :show, :update, :delete, :initialize])
      end
		end




  end
end
