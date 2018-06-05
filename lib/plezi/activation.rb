require 'uri' unless defined?(::URI)
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
        self.hash_proc_4symstr # creates the Proc object used for request params
        @plezi_autostart = true if @plezi_autostart.nil?
        Iodine.patch_rack
        if((ENV['PL_REDIS_URL'.freeze] ||= ENV['REDIS_URL'.freeze]))
          ping = ENV['PL_REDIS_TIMEOUT'.freeze] || ENV['REDIS_TIMEOUT'.freeze]
          ping = ping.to_i if ping
          Iodine::PubSub.default = Iodine::PubSub::RedisEngine.new(ENV['PL_REDIS_URL'.freeze], ping: ping)
          Iodine::PubSub.default = Iodine::PubSub::CLUSTER unless Iodine::PubSub.default
        end
        at_exit do
           next if @plezi_autostart == false
           ::Iodine.listen2http app: ::Plezi.app
           ::Iodine.start
        end
     end
     true
  end
end
