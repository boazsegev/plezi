module Plezi
  module Base
    module Autostart
      @state = nil

      module_function

      def turn_on
        return if @performed
        @performed = true
        at_exit do
          if @state.nil?
            Iodine::Rack.app = Plezi.app
            Iodine.threads ||= 16
            Iodine.start
          end
        end
      end

      def turn_off
        @state = true
      end
    end
  end
end
