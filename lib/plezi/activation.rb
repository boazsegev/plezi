require 'plezi/websockets/message_dispatch' unless defined?(::Plezi::Base::MessageDispatch)

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
        puts "WARNNING: auto-scaling with redis is set using ENV['PL_REDIS_URL'.freeze]\r\n           but the Redis gem isn't included! - SCALING IS IGNORED!" if ENV['PL_REDIS_URL'.freeze] && !defined?(::Redis)
        at_exit do
           next if @plezi_autostart == false
           ::Iodine::Rack.app = ::Plezi.app
           ::Iodine.start
        end
     end
     true
  end
end

::Iodine.threads ||= 16
::Iodine.processes ||= 1 unless ENV['PL_REDIS_URL'.freeze]
::Iodine.run { ::Plezi::Base::MessageDispatch._init }
