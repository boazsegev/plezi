require 'securerandom'
module Plezi
  module Base
    module MessageDispatch
      module Redis
        @redis_locker ||= Mutex.new
        @redis = @redis_sub_thread = nil

        module_function

        def connected
          return false unless ENV['PL_REDIS_URL'] && defined?(::Redis)
          @redis_locker.synchronize do
            return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis # repeat the test once syncing is done.
            @redis.quit if @redis
            @redis = ::Redis.new(url: ENV['PL_REDIS_URL'])
            raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless @redis
            @redis_sub_thread = Thread.new do
              begin
                ::Redis.new(url: ENV['PL_REDIS_URL']).subscribe(::Plezi.app_name, ::Plezi::Base::MessageDispatch.uuid) do |on|
                  on.message do |_channel, msg|
                    ::Plezi::Base::MessageDispatch << msg
                  end
                end
              rescue => e
                Iodine.error e
                retry
              end
            end
            @redis
          end
        end

        # Get the current redis connection.
        def redis
          @redis || connected
        end

        def push(message, to = nil)
          return unless connected
          return if to && away?(to)
          redis.publish((to || Plezi.app_name), message)
        end

        def get_redis
          return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis
          inner_init_redis
        end

        def away?(server)
          return true unless connected
          @redis.pubsub('CHANNELS', server).empty?
        end
      end
    end
  end
end

::Plezi::Base::MessageDispatch.drivers << ::Plezi::Base::MessageDispatch::Redis
