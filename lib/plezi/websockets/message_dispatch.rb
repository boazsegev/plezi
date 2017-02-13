module Plezi
   module Base
      module MessageDispatch
         class << self
           # Allows pub/sub drivers to attach to the message dispatch using `MessageDispatch.drivers << driver`
           attr_reader :drivers
         end
         @drivers = [].to_set

         module_function

         SAFE_TYPES = [Symbol, Date, Time, Encoding, Struct, Regexp, Range, Set].freeze
         EMPTY_ARGS = [].freeze

         @ppid = ::Process.pid

         def pid
            if @ppid != ::Process.pid
               @pid = nil
               @ppid = ::Process.pid
            end
            @pid ||= SecureRandom.urlsafe_base64.tap { |str| @prefix_len = str.length }
         end

         def _init
            @drivers.each(&:connect)
         end

         def push(message)
            # message[:type] = message[:type].name if message[:type].is_a?(Class)
            message[:origin] = pid
            hst = message.delete(:host) || Plezi.app_name
            yml = message.to_yaml
            @drivers.each { |d| d.push(hst, yml) }
         end

         def <<(msg)
            msg = YAML.safe_load(msg, SAFE_TYPES)
            return if msg[:origin] == pid
            # handle string vs. symbol issues
            msg[:type] ||= msg['type'.freeze] || :all
            msg[:event] ||= msg['event'.freeze]
            msg[:target] ||= msg['target'.freeze]
            msg[:args] ||= msg['args'.freeze] || EMPTY_ARGS
            msg[:type] = Object.const_get msg[:type] if msg[:type] != :all
            if msg[:target]
               Iodine::Websocket.defer(target2uuid(msg[:target])) { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[msg[:event]], *(msg[:args]))) if ws._pl_ws_map[msg[:event]] }
            elsif (msg[:type]) == :all
               Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[msg[:event]], *(msg[:args]))) if ws._pl_ws_map[msg[:event]] }
            elsif msg[:type]._pl_ws_map[msg[:event]]
               Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[msg[:event]], *(msg[:args]))) if ws.is_a?(msg[:type]) }
            end

         rescue => e
            puts '*** The following could be a security breach attempt:', e.message, e.backtrace
            nil
         end

         def unicast(_sender, target, meth, args)
            return false if target.nil?
            if (tuuid = target2uuid)
               Iodine::Websocket.defer(tuuid) { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws._pl_ws_map[meth] }
               return true
            end
            push target: target, args: args, host: target2pid(target)
         end

         def broadcast(sender, meth, args)
            if sender.is_a?(Class)
               Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws.is_a?(sender) && ws._pl_ws_map[meth] }
               push type: sender.name, args: args, event: meth
            else
               sender.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws.is_a?(sender.class) && ws._pl_ws_map[meth] }
               push type: sender.class.name, args: args, event: meth
            end
         end

         def multicast(sender, meth, args)
            if sender.is_a?(Class)
               Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws._pl_ws_map[meth] }
               push type: :all, args: args, event: meth
            else
               sender.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws._pl_ws_map[meth] }
               push type: :all, args: args, event: meth
            end
         end

         def target2uuid(target)
            return nil unless target.start_with? pid
            target[@prefix_len..-1].to_i
         end

         def target2pid(target)
            target ? target[0..(@prefix_len - 1)] : Plezi.app_name
         end
      end
   end
end
# connect default drivers
require 'plezi/websockets/redis'
