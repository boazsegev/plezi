
module Plezi

  module Base
    module WSHelpers
      def self.translate_message msg
				begin
					@safe_types ||= [Symbol, Date, Time, Encoding, Struct, Regexp, Range, Set]
					YAML.safe_load(msg, @safe_types)
				rescue => e
					::Plezi.error "The following could be a security breach attempt:"
					::Plezi.error e
					nil
				end
			end
			def self.forward_message data
				begin
					return false if data[:server] == Plezi::Settings.uuid
					data[:type] = Object.const_get(data[:type]) unless data[:type].nil? || data[:type] == :all
					if data[:target]
						data[:type].___faild_unicast( data ) unless Iodine::Http::Websockets.unicast data[:target], data
					else
						Iodine::Http::Websockets.broadcast data
					end
				rescue => e
					::Plezi.error "The following could be a security breach attempt:"
					::Plezi.error e
					nil
				end
			end
    end
  end
  # this module and all it's methods and properties will be mixed into any
  # Controller class.
  #
  # The Websocket helper methods, such as {#broadcast} are described here.
  module ControllerWebsockets


    # @!parse include InstanceMethods
		# @!parse extend ClassMethods

		module InstanceMethods
			public


      # handles broadcasts / unicasts
      def on_broadcast data
        unless data.is_a?(Hash) && (data[:type] || data[:target]) && data[:method] && data[:data]
          ::Plezi.warn "Broadcast message unknown... falling back on base broadcasting"
          return super(data) if defined? super
          return false
        end
        return false if data[:type] && data[:type] != :all && !self.is_a?(data[:type])
        # return (data[:data].each {|e| emit(e)}) if data[:method] == :emit
        return ((data[:type] == :all) ? false : (raise "Broadcasting recieved but no method can handle it - dump:\r\n #{data.to_s}") ) unless self.class.has_super_method?(data[:method])
        self.__send__(data[:method], *data[:data])
      end

      # Get's the websocket's unique identifier for unicast transmissions.
      #
      # This UUID is also used to make sure Radis broadcasts don't triger the
      # boadcasting object's event.
      def uuid
        return @uuid if @uuid
        if __get_io
          return (@uuid ||=  Plezi::Settings.uuid + self.object_id.to_s(16))
        end
        nil
      end
      alias :unicast_id :uuid


      protected

      # @!visibility public
      # Performs a websocket unicast to the specified target.
      def unicast target_uuid, method_name, *args
        self.class.unicast target_uuid, method_name, *args
      end

      # @!visibility public
      # Use this to brodcast an event to all 'sibling' objects (websockets that have been created using the same Controller class).
      #
      # Accepts:
      # method_name:: a Symbol with the method's name that should respond to the broadcast.
      # args*:: The method's argumenst - It MUST be possible to stringify the arguments into a YAML string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
      #
      # The method will be called asynchrnously for each sibling instance of this Controller class.
      #
      def broadcast method_name, *args
        return false unless self.class.has_method? method_name
        self.class._inner_broadcast({ method: method_name, data: args, type: self.class}, __get_io )
      end

      # @!visibility public
      # Use this to multicast an event to ALL websocket connections on EVERY controller, including Placebo controllers.
      #
      # Accepts:
      # method_name:: a Symbol with the method's name that should respond to the broadcast.
      # args*:: The method's argumenst - It MUST be possible to stringify the arguments into a YAML string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
      #
      # The method will be called asynchrnously for ALL websocket connections.
      #
      def multicast method_name, *args
        self.class._inner_broadcast({ method: method_name, data: args, type: :all}, __get_io )
      end

      # @!visibility public
      # The following method registers the connections as a unique global identity.
      #
      # The Identity API works best when a Redis server is used. See {Plezi#redis} for more information.
      #
      # By default, only one connection at a time can respond to identity events. If the same identity
      # connects more than once, only the last connection will receive the notifications.
      # This default may be controlled by setting the `:max_connections` option to a number greater than 1.
      #
      # The method accepts:
      # identity:: a global application wide unique identifier that will persist throughout all of the identity's connections.
      # options:: an option's hash that sets the properties of the identity.
      #
      # The option's Hash, at the moment, accepts only the following (optional) options:
      # lifetime:: sets how long the identity can survive. defaults to `604_800` seconds (7 days).
      # max_connections:: sets the amount of concurrent connections an identity can have (akin to open browser tabs receiving notifications). defaults to 1 (a single connection).
      #
      # Lifetimes are renewed with each registration and when a connected Identoty receives a notification.
      # Identities should have a reasonable lifetime. For example, a 10 minutes long lifetime (60*10)
      # may prove ineffective. When using such short lifetimes, consider the possibility that `unicast` might provide be a better alternative.
      #
      # A lifetime cannot (by design) be shorter than 10 minutes.
      #
      # Calling this method will also initiate any events waiting in the identity's queue.
      # make sure that the method is only called once all other initialization is complete.
      #
      # i.e.
      #
      #       register_as session.id, lifetime: 60*60*24, max_connections: 4
      #
      # Do NOT call this method asynchronously unless Plezi is set to run as in a single threaded mode - doing so
      # will execute any pending events outside the scope of the IO's mutex lock, thus introducing race conditions.
      def register_as identity, options = {}
        redis = Plezi.redis || ::Plezi::Base::RedisEmultaion
        options[:max_connections] ||= 1
        options[:max_connections] = 1 if options[:max_connections].to_i < 1
        options[:lifetime] ||= 604_800
        options[:lifetime] = 600 if options[:lifetime].to_i < 600
        identity = identity.to_s.freeze
        @___identity ||= {}
        @___identity[identity] = options
        redis.multi do
          redis.lpop(identity)
          redis.lpush(identity, ''.freeze)
          redis.lrem "#{identity}_uuid".freeze, 0, uuid
          redis.lpush "#{identity}_uuid".freeze, uuid
          redis.ltrim "#{identity}_uuid".freeze, 0, (options[:max_connections]-1)
          redis.expire identity, options[:lifetime]
          redis.expire "#{identity}_uuid".freeze, options[:lifetime]
        end
        ___review_identity identity
        identity
      end

      # @!visibility public
      # sends a notification to an Identity. Returns false if the Identity never registered or it's registration expired.
      def notify identity, event_name, *args
        self.class.notify identity, event_name, *args
      end
      # @!visibility public
      # returns true if the Identity in question is registered to receive notifications.
      def registered? identity
        self.class.registered? identity
      end

      # this is the identity event and ittells the connection to "read" the messages in the "mailbox",
      # and forward the messages to the rest of the connections.
      def ___review_identity identity
        redis = Plezi.redis || ::Plezi::Base::RedisEmultaion
        identity = identity.to_s.freeze
        return ::Plezi.warn("Identity message reached wrong target (ignored).").clear unless @___identity[identity]
        messages = redis.multi do
          redis.lrange identity, 1, -1
          redis.ltrim identity, 0, 0
          redis.expire identity,  @___identity[identity][:lifetime]
          redis.expire "#{identity}_uuid".freeze,  @___identity[identity][:lifetime]
        end[0]
        targets = redis.lrange "#{identity}_uuid", 0, -1
        targets.delete(uuid)
        while msg = messages.shift
          msg = ::Plezi::Base::WSHelpers.translate_message(msg)
          next unless msg
          ::Plezi.error("Notification recieved but no method can handle it - dump:\r\n #{msg.to_s}") && next unless self.class.has_super_method?(msg[:method])
          ::Plezi.run do
            targets.each {|target| unicast(target, msg[:method], *msg[:data]) }
          end
          self.__send__(msg[:method], *msg[:data])
        end
        # ___extend_lifetime identity
      end

      # # re-registers the Identity, extending it's lifetime
      # # and making sure it's still valid.
      # def ___extend_lifetime identity
      # 	return unless @___identity
      # 	redis = Plezi.redis || ::Plezi::Base::WSObject::RedisEmultaion
      # 	options = @___identity[identity]
      # 	return unless options
      # 	redis.multi do
      # 		# redis.lpop(identity)
      # 		# redis.lpush(identity, ''.freeze)
      # 		# redis.lrem "#{identity}_uuid".freeze, 0, uuid
      # 		# redis.lpush "#{identity}_uuid".freeze, uuid
      # 		# redis.ltrim "#{identity}_uuid".freeze, 0, (options[:max_connections]-1)
      # 		redis.expire identity, options[:lifetime]
      # 		redis.expire "#{identity}_uuid".freeze, options[:lifetime]
      # 	end
      # end

      # # handles websocket being closed.
      # def on_close
      # 	super if defined? super
      # 	redis = Plezi.redis || ::Plezi::Base::WSObject::RedisEmultaion
      # 	@___identity.each { |identity| redis.lrem "#{identity}_uuid".freeze, 0, uuid }
      # end
		end

		module ClassMethods

      public

      # answers the question if this is a placebo object.
      def placebo?; false end

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
      def broadcast method_name, *args
        return false unless has_method? method_name
        _inner_broadcast method: method_name, data: args, type: self
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
        raise 'No target specified for unicasting!' unless target_uuid
        @uuid_cutoff ||= Plezi::Settings.uuid.length
        _inner_broadcast method: method_name, data: args, target: target_uuid[@uuid_cutoff..-1], to_server: target_uuid[0...@uuid_cutoff], type: :all
      end

      # Use this to multicast an event to ALL websocket connections on EVERY controller, including Placebo controllers.
      #
      # Accepts:
      # method_name:: a Symbol with the method's name that should respond to the broadcast.
      # args*:: The method's argumenst - It MUST be possible to stringify the arguments into a YAML string, or broadcasting and unicasting will fail when scaling beyond one process / one machine.
      #
      # The method will be called asynchrnously for ALL websocket connections.
      #
      def multicast method_name, *args
        _inner_broadcast method: method_name, data: args, type: :all
      end

      # WebSockets

      # sends the broadcast
      def _inner_broadcast data, ignore_io = nil
        if data[:target]
          if data[:to_server] == Plezi::Settings.uuid
            return ( ::Iodine::Http::Websockets.unicast( data[:target], data ) || ___faild_unicast( data ) )
          end
          return ( data[:to_server].nil? && ::Iodine::Http::Websockets.unicast(data[:target], data) ) || ( Plezi::Base::AutoRedis.away?(data[:to_server]) && ___faild_unicast( data ) ) || __inner_redis_broadcast(data)
        else
          ::Iodine::Http::Websockets.broadcast data, ignore_io
          __inner_redis_broadcast data
        end
        true
      end

      def __inner_redis_broadcast data
        return unless conn = Plezi.redis
        data = data.dup
        data[:type] = data[:type].name if data[:type].is_a?(Class)
        data[:server] = Plezi::Settings.uuid
        return conn.publish( ( data[:to_server] || Plezi::Settings.redis_channel_name ), data.to_yaml ) if conn
        false
      end

      def ___faild_unicast data
        has_class_method?(:failed_unicast) && failed_unicast( data[:to_server].to_s + data[:target], data[:method], data[:data] )
        true
      end



			public





      # sends a notification to an Identity. Returns false if the Identity never registered or it's registration expired.
      def notify identity, event_name, *args
        redis = Plezi.redis || ::Plezi::Base::RedisEmultaion
        identity = identity.to_s.freeze
        return false unless redis.llen(identity).to_i > 0
        redis.rpush identity, ({method: event_name, data: args}).to_yaml
        redis.lrange("#{identity}_uuid".freeze, 0, -1).each {|target| unicast target, :___review_identity, identity }
        # puts "pushed notification #{event_name}"
        true
      end

      # returns true if the Identity in question is registered to receive notifications.
      def registered? identity
        redis = Plezi.redis || ::Plezi::Base::RedisEmultaion
        identity = identity.to_s.freeze
        redis.llen(identity).to_i > 0
      end
    end

  end
end
