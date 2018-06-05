require 'plezi/render/render'
require 'plezi/controller/identification'
require 'plezi/controller/cookies'
require 'plezi/controller/controller_class'
require 'plezi/controller/bridge'

module Plezi
   # This module contains the functionality provided to any Controller class.
   #
   # This module will be included within every Class that is asigned to a route, providing the functionality without forcing an inheritance model.
   #
   # Any Controller can suppoert WebSocket connections by either implementing an `on_message(data)` callback or setting the `@auto_dispatch` class instance variable to `true`.
   #
   module Controller
      def self.included(base)
         base.extend ::Plezi::Controller::ClassMethods
      end

      # A Rack::Request object for the current request.
      attr_reader :request
      # A Rack::Response object used for the current request.
      attr_reader :response
      # A union between the `request.params` and the route's inline parameters. This is different then `request.params`
      attr_reader :params
      # A cookie jar for both accessing and setting cookies. Unifies `request.set_cookie`, `request.delete_cookie` and `request.cookies` with a single Hash like inteface.
      #
      # Read a cookie:
      #
      #         cookies["name"]
      #
      # Set a cookie:
      #
      #         cookies["name"] = "value"
      #         cookies["name"] = {value: "value", secure: true}
      #
      # Delete a cookie:
      #
      #         cookies["name"] = nil
      #
      attr_reader :cookies

      # @private
      # Used internally to access the Iodine::Connection client data (if available).
      attr_reader :_pl__client

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_respond(request, response, params)
         @request = request
         @response = response
         @params = params
         @cookies = Cookies.new(request, response)
         mthd = requested_method
         # puts "m == #{m.nil? ? 'nil' : m.to_s}"
         return _pl_ad_httpreview(__send__(mthd)) if mthd
         false
      end

      # Returns the method that was called by the HTTP request.
      #
      # It's possible to override this method to change the default Controller behavior.
      #
      # For Websocket connections this method is most likely to return :preform_upgrade
      def requested_method
         params['_method'.freeze] = (params['_method'.freeze] || request.request_method.downcase).to_sym
         self.class._pl_params2method(params, request.env)
      end

      # Renders the requested template (should be a string, subfolders are fine).
      #
      # Template name shouldn't include the template's extension or format - this allows for dynamic format template resolution, so that `json` and `html` requests can share the same code. i.e.
      #
      #       Plezi.templates = "views/"
      #       render "users/index"
      #
      # Using layouts (nested templates) is easy by using a block (a little different then other frameworks):
      #
      #       render("users/layout") { render "users/index" }
      #
      def render(template, &block)
         frmt = params['format'.freeze] || 'html'.freeze
         mime = nil
         ret = ::Plezi::Renderer.render "#{File.join(::Plezi.templates, template.to_s)}.#{frmt}", binding, &block
         response[Rack::CONTENT_TYPE] = mime if ret && !response.content_type && (mime = Rack::Mime.mime_type(".#{frmt}".freeze, nil))
         ret
      end

      # Sends a block of data, setting a file name, mime type and content disposition headers when possible. This should also be a good choice when sending large amounts of data.
      #
      # By default, `send_data` sends the data as an attachment, unless `inline: true` was set.
      #
      # If a mime type is provided, it will be used to set the Content-Type header. i.e. `mime: "text/plain"`
      #
      # If a file name was provided, Rack will be used to find the correct mime type (unless provided). i.e. `filename: "sample.pdf"` will set the mime type to `application/pdf`
      #
      # Available options: `:inline` (`true` / `false`), `:filename`, `:mime`.
      def send_data(data, options = {})
         response.write data if data
         filename = options[:filename]
         # set headers
         content_disposition = options[:inline] ? 'inline'.dup : 'attachment'.dup
         content_disposition << "; filename=#{::File.basename(options[:filename])}" if filename
         cont_type = (options[:mime] ||= filename && Rack::Mime.mime_type(::File.extname(filename)))
         response['content-type'.freeze] = cont_type if cont_type
         response['content-disposition'.freeze] = content_disposition
         true
      end

      # Same as {#send_data}, but accepts a file name (to be opened and sent) rather then a String.
      #
      # See {#send_data} for available options.
      def send_file(filename, options = {})
         response['X-Sendfile'.freeze] = filename
         options[:filename] ||= File.basename(filename)
         filename = File.open(filename, 'rb'.freeze) # unless Iodine::Rack.public
         send_data filename, options
      end

      # A shortcut for Rack's `response.redirect`.
      def redirect_to(target, status = 302)
         response.redirect target, status
         true
      end

      # Returns a relative URL for the controller, placing the requested parameters in the URL (inline, where possible and as query data when not possible).
      def url_for(func, params = {})
         ::Plezi::Base::Router.url_for self.class, func, params
      end

      # Override this method to read / write cookies, perform authentication or perform validation before establishing a Websocket or SSE connecion.
      #
      # Return `false` or `nil` to refuse the websocket connection.
      def pre_connect
         true
      end

      # Writes to an SSE / WebSocket connection (raises an error unless the connection was already established).
      def write data
         _pl__client.write data
      end

      # Closes an SSE / WebSocket connection (raises an error unless the connection was already established).
      def close
         _pl__client.close
      end
      # Tests the known state for an SSE / WebSocket connection (the known state might not be the same as the actual state).
      def open?
         _pl__client && _pl__client.open?
      end
      # Returns the number of pending `write` operations that need to complete before the next `on_drained` callback is called.
      def pending
         return 0 unless _pl__client
         _pl__client.pending
      end

      # Subscribes to a Pub/Sub stream / channel or replaces an existing subscription to the same stream / channel (raises an error unless an SSE / WebSocket connection was established).
      def subscribe *args, &block
         raise "WebSocket / SSE connection missing" unless _pl__client
         if(block)
            _pl__client.subscribe *args, &block
         else
            _pl__client.subscribe *args
         end
      end

      # Publishes to a Pub/Sub stream / channel (routes to Iodine.publish).
      def publish *args
         ::Iodine.publish *args
      end


      # Experimental: takes a module to be used for Websocket callbacks events.
      #
      # This function can only be called **after** a websocket connection was established (i.e., within the `on_open` callback).
      #
      # This allows a module "library" to be used similar to the way "rooms" are used in node.js, so that a number of different Controllers can listen to shared events.
      #
      # By dynamically extending a Controller instance using a module, Auto Dispatch events can be routed to the newly available methods.
      #
      # Notice: It is impossible to `unextend` an extended module at this time.
      def extend(mod)
         raise TypeError, '`mod` should be a module' unless mod.class == Module
         unless is_a?(mod)
           mod.extend ::Plezi::Controller::ClassMethods
           super(mod)
         end
         _pl_ws_map.update mod._pl_ws_map
         _pl_ad_map.update mod._pl_ad_map
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_ws_map
         @_pl_ws_map ||= self.class._pl_ws_map.dup
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_ad_map
         @_pl_ad_map ||= self.class._pl_ad_map.dup
      end

      # @private
      # Overload this method to handle event.
      def on_open
      end
      # @private
      # Overload this method to handle event.
      def on_close
      end
      # @private
      # Overload this method to handle event.
      def on_drained
      end
      # @private
      # Overload this method to handle event.
      def on_shutdown
      end
      
      # @private
      # This function is used internally by Plezi, for Auto-Dispatch support do not call.
      def on_message(data)
         json = nil
         begin
            json = JSON.parse(data, symbolize_names: true)
            # json.default_proc = Plezi.hash_proc_4symstr
         rescue
            puts 'AutoDispatch Warnnig: Received non-JSON message. Closing Connection.'
            close
            return
         end
         envt = _pl_ad_map[json[:event]] || _pl_ad_map[:unknown]
         if json[:event].nil? || envt.nil?
            puts _pl_ad_map
            puts "AutoDispatch Warnnig: JSON missing/invalid `event` name '#{json[:event]}' for class #{self.class.name}. Closing Connection."
            close
         end
         _pl__client.write("{\"event\":\"_ack_\",\"_EID_\":#{json[:_EID_].to_json}}") if json[:_EID_]
         _pl_ad_review __send__(envt, json)
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_ad_review(data)
        return data unless self.class._pl_is_ad?
        case data
        when Hash
           _pl__client.write data.to_json
        when String
           _pl__client.write data
           # when Array
           #   write data.to_json
        end
      end

      # @private
      # This function is used internally by Plezi, do not call.
      def _pl_ad_httpreview(data)
         return data.to_json if self.class._pl_is_ad? && data.is_a?(Hash)
         data
      end

      private

      # @private
      # This function is used internally by Plezi, do not call.
      def preform_upgrade
         return false unless pre_connect
         request.env[::Plezi::Base::Bridge::CONTROLLER_NAME] = self
         request.env['rack.upgrade'.freeze] = ::Plezi::Base::Bridge
         @params = @params.dup # disable memory saving (used a single object per thread)
         @_pl_ws_map = self.class._pl_ws_map.dup
         @_pl_ad_map = self.class._pl_ad_map.dup
         true
      end
   end
end
