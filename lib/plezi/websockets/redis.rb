module Plezi
   module Base
      module MessageDispatch
         module RedisDriver
            @redis_locker ||= Mutex.new
            @redis = @redis_sub_thread = nil

            module_function

            def connect
               return false unless ENV['PL_REDIS_URL'] && defined?(::Redis)
               return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis
               @redis_locker.synchronize do
                  return @redis if (@redis_sub_thread && @redis_sub_thread.alive?) && @redis # repeat the test inside syncing, things change.
                  @redis.quit if @redis
                  @redis = ::Redis.new(url: ENV['PL_REDIS_URL'])
                  raise "Redis connction failed for: #{ENV['PL_REDIS_URL']}" unless @redis
                  @redis_sub_thread = Thread.new do
                     begin
                        ::Redis.new(url: ENV['PL_REDIS_URL']).subscribe(::Plezi.app_name, ::Plezi::Base::MessageDispatch.pid) do |on|
                           on.message do |_channel, msg|
                              ::Plezi::Base::MessageDispatch << msg
                           end
                        end
                     rescue => e
                        puts e.message, e.backtrace
                        retry
                     end
                  end
                  @redis
               end
            end

            # Get the current redis connection.
            def redis
               @redis || connect
            end

            def push(channel, message)
               return unless connect
               return if away?(channel)
               redis.publish(channel, message)
            end

            def away?(server)
               return true unless connect
               @redis.pubsub('CHANNELS', server).empty?
            end
         end
      end
   end
end

::Plezi::Base::MessageDispatch.drivers << ::Plezi::Base::MessageDispatch::RedisDriver
