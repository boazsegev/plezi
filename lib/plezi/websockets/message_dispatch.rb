require 'set'
require 'securerandom'
require 'yaml'
module Plezi
  module Base
    module MessageDispatch
      class << self
        # Allows pub/sub drivers to attach to the message dispatch using `MessageDispatch.drivers << driver`
        attr_reader :drivers
      end
      @drivers = [].to_set

      module_function

      def pid
        @uuid ||= SecureRandom.hex
      end

      def push(message)
        message[:type] = message[:type].name if message[:type].is_a?(Class)
        message[:origin] = pid
        yml = message.to_yaml
        @drivers.each { |d| d.push(yml, message[:host] || Plezi.app_name) }
      end

      def <<(msg)
        @safe_types ||= [Symbol, Date, Time, Encoding, Struct, Regexp, Range, Set].freeze
        YAML.safe_load(msg, @safe_types)
      rescue => e
        puts 'The following could be a security breach attempt:', e.message, e.backtrace
        nil
      end

      def unicast(sender, target, data)
        sender
        target
        data
      end

      def broadcast(sender, data)
        sender
        data
      end

      def multicast(sender, data)
        sender
        data
      end
    end
  end
end
# connect default drivers
require '/plezi/websockets/redis'
