module Plezi

	module Base

		module WSObject

			# Used to emulate the Redis connection when the Identoty API
			# is used on a single process with no Redis support.
			module RedisEmultaion
				public
				def lrange key, first, last = -1
					sync do
						return [] unless @cache[key]
						@cache[key][first..last] || []
					end
				end
				def llen key
					sync do
						return 0 unless @cache[key]
						@cache[key].count
					end
				end
				def ltrim key, first, last = -1
					sync do
						return "OK".freeze unless @cache[key]
						@cache[key] = @cache[key][first..last]
						"OK".freeze
					end
				end
				def del *keys
					sync do
						ret = 0
						keys.each {|k| ret += 1 if @cache.delete k }
						ret
					end
				end
				def lpush key, value
					sync do
						@cache[key] ||= []
						@cache[key].unshift value
						@cache[key].count
					end
				end
				def lpop key
					sync do
						@cache[key] ||= []
						@cache[key].shift
					end
				end
				def lrem key, count, value
					sync do
						@cache[key] ||= []
						@cache[key].delete(value)
					end
				end
				def rpush key, value
					sync do
						@cache[key] ||= []
						@cache[key].push value
						@cache[key].count
					end
				end
				def expire key, seconds
					@warning_sent ||= Iodine.warn "Identity API requires Redis - no persistent storage!".freeze
					sync do
						return 0 unless @cache[key]
						if @timers[key]
							@timers[key].stop!
						end
						@timers[key] = (Iodine.run_after(seconds) { self.del key })
					end
				end
				def multi
					sync do
						@results = []
						yield(self)
						ret = @results
						@results = nil
						ret
					end
				end
				alias :pipelined :multi
				protected
				@locker = Mutex.new
				@cache = Hash.new
				@timers = Hash.new

				def sync &block
					if @locker.locked? && @locker.owned?
						ret = yield
						@results << ret if @results
						ret
					else
						@locker.synchronize { sync(&block) }
					end
				end

				public
				extend self
			end

			# the following are additions to the WebSocket Object module,
			# to establish identity to websocket realtionships, allowing for a
			# websocket message bank.

			module InstanceMethods
				protected

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
					redis = Plezi.redis || ::Plezi::Base::WSObject::RedisEmultaion
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
			end
			module ClassMethods
			end
			module SuperInstanceMethods
				protected

				# this is the identity event and ittells the connection to "read" the messages in the "mailbox",
				# and forward the messages to the rest of the connections.
				def ___review_identity identity
					redis = Plezi.redis || ::Plezi::Base::WSObject::RedisEmultaion
					identity = identity.to_s.freeze
					return Iodine.warn("Identity message reached wrong target (ignored).").clear unless @___identity[identity]
					messages = redis.multi do
						redis.lrange identity, 1, -1
						redis.ltrim identity, 0, 0
						redis.expire identity,  @___identity[identity][:lifetime]
						redis.expire "#{identity}_uuid".freeze,  @___identity[identity][:lifetime]
					end[0]
					targets = redis.lrange "#{identity}_uuid", 0, -1
					targets.delete(uuid)
					while msg = messages.shift
						msg = ::Plezi::Base::WSObject.translate_message(msg)
						next unless msg
						Iodine.error("Notification recieved but no method can handle it - dump:\r\n #{msg.to_s}") && next unless self.class.has_super_method?(msg[:method])
						Iodine.run do
							targets.each {|target| unicast(target, msg[:method], *msg[:data]) }
						end
						self.method(msg[:method]).call(*msg[:data])
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
			end

			module SuperClassMethods
				public

				# sends a notification to an Identity. Returns false if the Identity never registered or it's registration expired.
				def notify identity, event_name, *args
					redis = Plezi.redis || ::Plezi::Base::WSObject::RedisEmultaion
					identity = identity.to_s.freeze
					return false unless redis.llen(identity).to_i > 0
					redis.rpush identity, ({method: event_name, data: args}).to_yaml
					redis.lrange("#{identity}_uuid".freeze, 0, -1).each {|target| unicast target, :___review_identity, identity }
					# puts "pushed notification #{event_name}"
					true
				end

				# returns true if the Identity in question is registered to receive notifications.
				def registered? identity
					redis = Plezi.redis || ::Plezi::Base::WSObject::RedisEmultaion
					identity = identity.to_s.freeze
					redis.llen(identity).to_i > 0
				end
			end
		end
	end
end
