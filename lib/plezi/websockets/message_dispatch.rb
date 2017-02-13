module Plezi
   module Base
      # Websocket Message Dispatching Service, including the autoscaling driver control (at the moment Redis is the only builtin driver).
      module MessageDispatch
         # add class attribute accessors.
         class << self
           # Allows pub/sub drivers to attach to the message dispatch using `MessageDispatch.drivers << driver`
           attr_reader :drivers
         end
         @drivers = [].to_set

         module_function

         # The YAML safe types used by Plezi
         SAFE_TYPES = [Symbol, Date, Time, Encoding, Struct, Regexp, Range, Set].freeze
         # a single use empty array (prevents the use of temporary objects where possible)
         EMPTY_ARGS = [].freeze
         # keeps track of the current process ID
         @ppid = ::Process.pid
         # returns a Plezi flavored pid UUID, used to set the pub/sub channel when scaling
         def pid
            process_pid = ::Process.pid
            if @ppid != process_pid
               @pid = nil
               @ppid = process_pid
            end
            @pid ||= SecureRandom.urlsafe_base64.tap { |str| @prefix_len = str.length }
         end

         # initializes the drivers when possible.
         def _init
            @drivers.each(&:connect)
         end

         # Pushes a message to the Pub/Sub drivers
         def push(message)
            # message[:type] = message[:type].name if message[:type].is_a?(Class)
            message[:origin] = pid
            hst = message.delete(:host) || Plezi.app_name
            yml = message.to_yaml
            @drivers.each { |drv| drv.push(hst, yml) }
         end

         # Parses a text message received through a Pub/Sub service.
         def <<(msg)
            msg = YAML.safe_load(msg, SAFE_TYPES)
            return if msg[:origin] == pid
            target_type = msg[:type] || :all
            event = msg[:event]
            if (target = msg[:target])
               Iodine::Websocket.defer(target2uuid(target)) { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[event], *(msg[:args]))) if ws._pl_ws_map[event] }
               return
            end
            if target_type == :all
               Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[event], *(msg[:args]))) if ws._pl_ws_map[event] }
               return
            end
            target_type = Object.const_get target_type
            if target_type._pl_ws_map[event]
               Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[event], *(msg[:args]))) if ws.is_a?(target_type) }
            end

         rescue => e
            puts '*** The following could be a security breach attempt:', e.message, e.backtrace
            nil
         end

         # Sends a message to a specific target, if it's on this machine, otherwise forwards the message to the Pub/Sub.
         def unicast(_sender, target, meth, args)
            return false if target.nil?
            if (tuuid = target2uuid(target))
               Iodine::Websocket.defer(tuuid) { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws._pl_ws_map[meth] }
               return true
            end
            push target: target, args: args, host: target2pid(target)
         end

         # Sends a message to a all targets of a speific **type**, as well as pushing the message to the Pub/Sub drivers.
         def broadcast(sender, meth, args)
            target_type = nil
            if sender.is_a?(Class)
               target_type = sender
               sender = Iodine::Websocket
            else
               target_type = sender.class
            end
            sender.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws.is_a?(target_type) && ws._pl_ws_map[meth] }
            push type: target_type.name, args: args, event: meth
         end

         # Sends a message to a all existing websocket connections, as well as pushing the message to the Pub/Sub drivers.
         def multicast(sender, meth, args)
            sender = Iodine::Websocket if sender.is_a?(Class)
            Iodine::Websocket.each { |ws| ws._pl_ad_review(ws.__send__(ws._pl_ws_map[meth], *args)) if ws._pl_ws_map[meth] }
            push type: :all, args: args, event: meth
         end

         # Converts a target Global UUID to a localized UUID
         def target2uuid(target)
            return nil unless target.start_with? pid
            target[@prefix_len..-1].to_i
         end

         # Extracts the machine part from a target's Global UUID
         def target2pid(target)
            target ? target[0..(@prefix_len - 1)] : Plezi.app_name
         end
      end
   end
end
# connect default drivers
require 'plezi/websockets/redis'
