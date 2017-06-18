require 'plezi/websockets/message_dispatch' unless defined?(::Plezi::Base::MessageDispatch)
require 'uri'
module Plezi
   protected

  @plezi_finalize = nil
  def plezi_finalize
     if @plezi_finalize.nil?
        @plezi_finalize = true
        @plezi_finalize = 1
     end
  end
  @plezi_initialize = nil
  def self.plezi_initialize
     if @plezi_initialize.nil?
        @plezi_initialize = true
        self.hash_proc_4symstr # crerate the Proc object used for request params
        @plezi_autostart = true if @plezi_autostart.nil?
        if((ENV['PL_REDIS_URL'.freeze] ||= ENV["REDIS_URL"]))
          uri = URI(ENV['PL_REDIS_URL'.freeze])
          Iodine::Websocket.default_pubsub = Iodine::PubSub::RedisEngine.new(uri.host, uri.port, 0, uri.password)
        end
        at_exit do
           next if @plezi_autostart == false
           ::Iodine::Rack.app = ::Plezi.app
           ::Iodine.start
        end
     end
     true
  end
end

# ::Iodine.processes ||= (ENV['PL_REDIS_URL'.freeze] ? 4 : 1)
::Iodine.run { ::Plezi::Base::MessageDispatch._init }
